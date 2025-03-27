import sys

sys.path.append("./site-packages")
import os
import json
import hashlib
import boto3
import datetime
import requests
from botocore.exceptions import BotoCoreError, NoCredentialsError
from typing import Dict, List, Union
import decimal


def get_partner_id() -> str:
    """Retrieves the partner ID from environment variables or AWS SSM Parameter Store."""
    partner_id = os.environ.get("PARTNER_ID")
    if partner_id:
        return partner_id

    ssm_client = boto3.client("ssm")
    try:
        response = ssm_client.get_parameter(Name="/waze/partner_id", WithDecryption=True)
        return response["Parameter"]["Value"]
    except ssm_client.exceptions.ParameterNotFound:
        raise ValueError("Parameter '/waze/partner_id' not found in SSM Parameter Store.")
    except Exception as e:
        raise RuntimeError(f"Error retrieving parameter '/waze/partner_id': {e}")


def get_types() -> Dict[str, str]:
    """Returns a list of Waze data types."""
    return [
        "alerts",
        "jams",
        "irregularities",
    ]


def get_endpoint(partner_id: str, unique_token: str) -> str:
    """Constructs the Waze API endpoint URL."""
    return f"https://www.waze.com/partnerhub-api/partners/{partner_id}/waze-feeds/{unique_token}?format=1&types=alerts,traffic,irregularities&acotu=true"


def get_data(endpoint: str) -> Dict[str, List]:
    """Fetches data from the Waze API."""
    response = requests.get(endpoint)
    try:
        return response.json()
    except json.JSONDecodeError:
        print(f"JSON Decode Error on API call: {endpoint}")
        print(f"Response: {response.text}")
        return {}


def get_data_hash(data: dict) -> Dict[str, Union[str, dict]]:
    """Generates a SHA256 hash for deduplication."""
    json_str = json.dumps(data, sort_keys=True, separators=(",", ":"))
    return {
        "uuid": str(data.get("uuid", data.get("id"))),
        "hash": hashlib.sha256(json_str.encode("utf-8")).hexdigest(),
        "data": data,
    }


def convert_floats_to_decimal(data):
    """Recursively converts float values to Decimal for DynamoDB."""
    if isinstance(data, float):
        return decimal.Decimal(str(data))
    elif isinstance(data, dict):
        return {k: convert_floats_to_decimal(v) for k, v in data.items()}
    elif isinstance(data, list):
        return [convert_floats_to_decimal(i) for i in data]
    return data


def persist_data_to_ddb(data_hash: dict) -> None:
    """Persists data to DynamoDB if it's not a duplicate."""
    data_type = data_hash.get("type", "unknown")
    table_name = f"waze_ingest_{data_type}"

    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table(table_name)

    try:
        data_hash = convert_floats_to_decimal(data_hash)

        response = table.get_item(Key={"uuid": data_hash["uuid"], "hash": data_hash["hash"]})
        if "Item" in response:
            print(f"Duplicate detected: UUID {data_hash['uuid']}, skipping.")
            return

        table.put_item(
            Item={
                "uuid": data_hash["uuid"],
                "hash": data_hash["hash"],
                "utc_epoch": data_hash.get("utc_epoch", 0),
                "data": data_hash.get("data", {}),
            }
        )
        print(f"Data persisted for UUID {data_hash['uuid']} in {table_name}")

    except BotoCoreError as e:
        print(f"Failed to persist data to {table_name}: {e}")
    except Exception as e:
        print(f"Unexpected error persisting data to {table_name}: {e}")


def lambda_handler(event: Dict, context) -> None:
    """AWS Lambda handler for processing a single state."""
    state_name = event.get("state_name")
    unique_token = event.get("unique_token")

    if not state_name or not unique_token:
        raise ValueError("Missing 'state_name' or 'unique_token' in event payload.")

    partner_id = get_partner_id()
    endpoint = get_endpoint(partner_id, unique_token)
    data = get_data(endpoint)
    utc_epoch = data.get("endTimeMillis", 0) // 1000  # Convert milliseconds to seconds

    for data_type in get_types():
        print(f"Processing {state_name}: {data_type} for UTC Epoch: {utc_epoch}")

        this_data_type = data.get(data_type, [])
        for datum in this_data_type:
            data_hash = get_data_hash(datum)
            data_hash["type"] = data_type
            data_hash["utc_epoch"] = utc_epoch

            persist_data_to_ddb(data_hash)

    print(f"Completed processing for {state_name}")
