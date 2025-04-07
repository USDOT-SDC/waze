import sys

sys.path.append("./site-packages")
import os
import json
import hashlib
import boto3
import datetime
import time
import random
import requests
from botocore.exceptions import BotoCoreError, NoCredentialsError, ClientError
from typing import Dict, List, Union
import decimal
import itertools

MAX_RETRIES = 8
BASE_DELAY = 0.5  # seconds
PARTITION_SIZE = 1 * 60 * 60  # One hour


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
    try:
        response = requests.get(endpoint)
        response.raise_for_status()  # Raises an exception for 4XX/5XX status codes
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Request error: {e}")
        return {}
    except json.JSONDecodeError:
        print(f"JSON Decode Error on API call: {endpoint}")
        print(f"Response: {response.text}")
        return {}


def get_data_hash(data: dict) -> Dict[str, Union[str, dict]]:
    """Generates a SHA256 hash for deduplication."""
    json_str = json.dumps(data, sort_keys=True, separators=(",", ":"))
    return {
        "uuid_hash": str(data.get("uuid", data.get("id"))) + "_" + hashlib.sha256(json_str.encode("utf-8")).hexdigest(),
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


def chunk_list(iterable, chunk_size):
    """Yield successive chunks from a list."""
    for i in range(0, len(iterable), chunk_size):
        yield iterable[i : i + chunk_size]


def persist_data_to_ddb(data_list: list[dict], data_type: str) -> None:
    if not data_list:
        return

    table_name = f"waze_ingest_{data_type}"
    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table(table_name)
    client = boto3.client("dynamodb")

    data_list = [convert_floats_to_decimal(item) for item in data_list]
    keys = [{"uuid_hash": {"S": item["uuid_hash"]}} for item in data_list]

    existing_items = set()

    # Check for existing items
    for key_chunk in chunk_list(keys, 100):
        try:
            response = client.batch_get_item(RequestItems={table_name: {"Keys": key_chunk}})
            for item in response.get("Responses", {}).get(table_name, []):
                existing_items.add(item["uuid_hash"]["S"])
        except (BotoCoreError, ClientError) as e:
            print(f"Batch get failed: {e}")
            continue

    new_items = [item for item in data_list if item["uuid_hash"] not in existing_items]

    for item_chunk in chunk_list(new_items, 25):
        try:
            with table.batch_writer() as batch:
                for item in item_chunk:
                    batch.put_item(
                        Item={
                            "uuid_hash": item["uuid_hash"],
                            "utc_epoch": item.get("utc_epoch", 0),
                            "utc_partition": item.get("utc_partition", 0),
                            "data": item.get("data", {}),
                        }
                    )
            print(f"Batch write successful for {str(len(item_chunk))} items")
        except (BotoCoreError, ClientError) as e:
            print(f"Batch write failed after all retries for chunk: {e}")


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
    utc_partition = utc_epoch // PARTITION_SIZE

    for data_type in get_types():
        print(f"Processing {state_name}: {data_type} for UTC Epoch: {utc_epoch}")

        this_data_type = data.get(data_type, [])
        data_batch = []  # Collect items before persisting

        for datum in this_data_type:
            data_hash = get_data_hash(datum)
            data_hash["type"] = data_type
            data_hash["utc_epoch"] = utc_epoch
            data_hash["utc_partition"] = utc_partition
            data_batch.append(data_hash)

        # Call persist_data_to_ddb once per data_type, not per item
        persist_data_to_ddb(data_batch, data_type)

    print(f"Completed processing for {state_name}")
