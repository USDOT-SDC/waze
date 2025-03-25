import sys
sys.path.append("./site-packages")
import os
import json
import boto3
import datetime
import requests
from botocore.exceptions import BotoCoreError, NoCredentialsError
from typing import Dict, List, Union
from pathlib import Path


def get_partner_id() -> str:
    """
    Retrieves the partner ID from environment variables or AWS SSM Parameter Store.

    :return: Partner ID as a string.
    :raises ValueError: If the parameter is not found in SSM Parameter Store.
    :raises RuntimeError: If an error occurs while retrieving the parameter.
    """
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


def get_raw_bucket() -> str:
    """Returns the raw data S3 bucket name from environment variables or a default value."""
    return os.environ.get("RAW_BUCKET", "gov.dot.sdc.dev.waze.raw")


def get_type_map() -> Dict[str, str]:
    """Returns a mapping of Waze data types to their singular forms."""
    return {
        "alerts": "alert",
        "jams": "jam",
        "irregularities": "irregularity",
    }


def get_endpoint(
    partner_id: str,
    unique_token: str,
    return_format: str = "1",
    types: str = "alerts,traffic,irregularities",
    revision: str = "3.0",
    ) -> str:
    """
    Constructs the Waze API endpoint URL.

    :param partner_id: Partner ID for authentication.
    :param unique_token: Unique token identifying each polygon.
    :param return_format: Format of the response ("1" for JSON, "2" for XML).
    :param types: Data types to request (comma-separated string).
    :param revision: Waze API revision.
    :return: Formatted API URL.
    """
    if revision == "3.0":
        return f"https://www.waze.com/partnerhub-api/partners/{partner_id}/waze-feeds/{unique_token}?format={return_format}&types={types}&acotu=true"
    else:
        return ""


def get_states() -> Dict[str, str]:
    """
    Loads state mapping from a JSON file.

    :return: Dictionary mapping state abbreviations to unique tokens.
    """
    parent_path = Path(__file__).resolve().parent
    with open(parent_path / "states.json") as f:
        return json.load(f)


def get_formatted_datetime_string(event_time: str) -> str:
    """
    Converts an event timestamp into a structured datetime path format.

    :param event_time: Timestamp in ISO 8601 format.
    :return: Formatted datetime string for file paths.
    """
    utc_datetime = datetime.datetime.strptime(event_time, "%Y-%m-%dT%H:%M:%SZ")
    fdt = utc_datetime.strftime("year=%Y/month=%m/day=%d/hour=%H/minute=%M")
    return fdt


def get_persist_key(state: str, type_name: str, event_time: str, request_id: str) -> str:
    """
    Generates a structured S3 object key for data persistence.

    :param state: US state abbreviation.
    :param type_name: Data type (e.g., "alert", "jam").
    :param event_time: Event timestamp.
    :param request_id: Unique request identifier.
    :return: Formatted S3 object key.
    """
    fdt = get_formatted_datetime_string(event_time)
    return f"state={state}/type={type_name}/{fdt}/{request_id}.json"


def get_data(endpoint: str) -> Dict[str, List]:
    """
    Fetches data from a given API endpoint.

    :param endpoint: API endpoint URL.
    :return: Parsed JSON response as a dictionary.
    """
    response = requests.get(endpoint)
    try:
        return response.json()
    except json.JSONDecodeError:
        print(f"JSON Decode Error on API call: {endpoint}")
        print(f"Response: {response.text}")
        return {}


def s3_put_object(data: dict, object_key: str, bucket_name: str = get_raw_bucket()) -> Union[str, bool]:
    """
    Uploads a dictionary as a JSON file to an S3 bucket.

    :param data: Dictionary to upload.
    :param object_key: S3 object key (filename in S3).
    :param bucket_name: Name of the S3 bucket.
    :return: ETag if successful, False otherwise.
    """
    s3_client = boto3.client("s3")
    try:
        json_data = json.dumps(data)
        result = s3_client.put_object(
            Bucket=bucket_name,
            Key=object_key,
            Body=json_data,
            ContentType="application/json",
            Metadata={"current": "true"},
        )
        return result.get("ETag", "ETagNotFound")
    except (BotoCoreError, NoCredentialsError) as e:
        print(f"Failed to upload to S3: {e}")
        return False


def persist_data(state: str, data: Dict[str, Union[str, List]], data_type: str, type_name: str, event_time: str, request_id: str) -> None:
    """
    Processes and persists data to an S3 bucket.

    :param state: US state abbreviation.
    :param data: Data dictionary.
    :param data_type: Type of data (e.g., "alerts").
    :param type_name: Singular form of data type (e.g., "alert").
    :param event_time: Event timestamp.
    :param request_id: Unique request identifier.
    """
    persist_data = {
        "startTime": data.get("startTime", "NotFound"),
        "endTime": data.get("endTime", "NotFound"),
        "startTimeMillis": data.get("startTimeMillis", "NotFound"),
        "endTimeMillis": data.get("endTimeMillis", "NotFound"),
        data_type: data.get(data_type, []),
    }
    persist_key = get_persist_key(state, type_name, event_time, request_id)
    if s3_put_object(persist_data, persist_key):
        print(f"Data persisted to: {persist_key}")
    else:
        print(f"Data persistence failed for state: {state}, type: {type_name}")


def lambda_handler(event: Dict, context) -> None:
    """
    AWS Lambda handler for processing event data.

    :param event: AWS Lambda event payload.
    :param context: AWS Lambda context object.
    """
    event_time = event["time"]
    request_id = context.aws_request_id
    partner_id = get_partner_id()
    states = get_states()

    for state, unique_token in states.items():
        endpoint = get_endpoint(partner_id, unique_token)
        data = get_data(endpoint)
        for data_type, type_name in get_type_map().items():
            persist_data(state, data, data_type, type_name, event_time, request_id)
