import sys
# Append the site-packages directory for external dependencies like pandas
sys.path.append("./site-packages")
import sys
import json
import boto3
from typing import Any, Dict, List, Tuple
from decimal import Decimal
import os
from boto3.dynamodb.conditions import Key
import time
from datetime import datetime


# Initialize DynamoDB and S3 clients
dynamodb = boto3.resource("dynamodb")
s3 = boto3.client("s3")

def get_temp_bucket() -> str:
    """Returns the raw data S3 bucket name from environment variables or a default value."""
    return os.environ.get("TEMP_BUCKET", "gov.dot.sdc.dev.waze.temp")

def convert_decimals_to_numbers(data: Any) -> Any:
    """Recursively convert Decimal objects to int or float."""
    if isinstance(data, list):
        return [convert_decimals_to_numbers(i) for i in data]
    elif isinstance(data, dict):
        return {k: convert_decimals_to_numbers(v) for k, v in data.items()}
    elif isinstance(data, Decimal):
        # Check if the Decimal value is an integer or float and convert accordingly
        if data % 1 == 0:
            return int(data)  # Convert to int if it's a whole number
        else:
            return float(data)  # Convert to float if it has a decimal part
    return data


def get_items_from_ddb(utc_partition: int, table_name: str) -> List[Dict]:
    """Fetch items from DynamoDB that are in a specific utc_partition."""
    table = dynamodb.Table(table_name)
    items = []

    try:
        # Query the GSI on utc_partition_index to get items in the specified utc_partition
        response = table.query(
            IndexName="utc_partition_index",
            KeyConditionExpression=Key("utc_partition").eq(Decimal(utc_partition)),
        )
        items = response.get("Items", [])

        # Handle pagination if the response is paginated
        while "LastEvaluatedKey" in response:
            response = table.query(
                IndexName="utc_partition_index",
                KeyConditionExpression=Key("utc_partition").eq(Decimal(utc_partition)),
                ExclusiveStartKey=response["LastEvaluatedKey"],
            )
            items.extend(response.get("Items", []))

    except ClientError as e:
        # Handle specific DynamoDB errors
        print(f"ClientError occurred while querying DynamoDB: {e}")
        raise  # Reraise the exception to propagate the error

    except Exception as e:
        # Catch any other exceptions
        print(f"Unexpected error occurred while querying DynamoDB: {e}")
        raise  # Reraise the exception to propagate the error

    # Return the items after converting decimals to numbers
    return convert_decimals_to_numbers(items)


def get_partitions(start_hours_ago: int, end_hours_ago: int, partition_size_seconds: int = 3600) -> Tuple[int, int]:
    """Get both start and end partitions based on the time offsets 'start_hours_ago' and 'end_hours_ago'."""
    # Get the current UTC time in seconds
    current_time = int(time.time())

    # Calculate the start partition (subtracting start_hours_ago from current time)
    start_partition = round((current_time - (start_hours_ago * 3600)) / partition_size_seconds)

    # Calculate the end partition (subtracting end_hours_ago from current time)
    end_partition = round((current_time - (end_hours_ago * 3600)) / partition_size_seconds)

    return start_partition, end_partition


def extract_date_parts(utc_epoch: int) -> Tuple[int, int, int]:
    """Extract year, month, day and hour from utc_epoch."""
    dt = datetime.utcfromtimestamp(utc_epoch)
    return dt.year, dt.month, dt.day, dt.hour


def lambda_handler(event: Dict, context: Any) -> None:
    """Lambda function to fetch DynamoDB items and store them as JSON in S3."""

    data_type = event.get("data_type")
    if not data_type:
        raise ValueError("Missing required parameter: 'data_type'")

    partition_size_seconds = 3600
    start_partition = event.get("utc_partition")
    end_partition = event.get("end_partition")

    # If no utc_partition is provided, assume CW trigger and define full range
    if start_partition is None:
        start_partition, end_partition = get_partitions(
            start_hours_ago=96, # 4 days (allows any Lambda outage to catch up to the 3.5 days)
            end_hours_ago=84, # 3.5 days (offsets heavy ingest during the day from the heavy persistence at night)
            partition_size_seconds=partition_size_seconds,
        )

    current_partition = int(start_partition)
    end_partition = int(end_partition)

    while current_partition <= end_partition:
        items = get_items_from_ddb(
            utc_partition=current_partition,
            table_name=f"waze_ingest_{data_type}"
        )

        current_epoch = current_partition * partition_size_seconds
        year, month, day, hour = extract_date_parts(utc_epoch=current_epoch)

        if not items:
            print(f"No {data_type} data found for partition: {current_partition}, {year}-{month}-{day} {hour}:00")
            current_partition += 1
            continue

        print(f"Found {data_type} data for partition: {current_partition}, {year}-{month}-{day} {hour}:00")

        # Convert items to JSON and store in S3
        temp_bucket = get_temp_bucket()
        s3_key = f"{data_type}/{current_partition}.json"
        try:
            s3.put_object(
                Bucket=temp_bucket,
                Key=s3_key,
                Body=json.dumps(items),
                ContentType="application/json"
            )
            print(f"Stored {len(items)} items to S3 at s3://{temp_bucket}/{s3_key}")
        except Exception as e:
            print(f"Error storing items to S3: {e}")
            raise e

        # If we’re not at the end, invoke ourselves for the next partition
        next_partition = current_partition + 1
        if next_partition <= end_partition:
            print(f"Invoking {context.function_name} with data_type:{data_type}, utc_partition:{next_partition}")
            lambda_client = boto3.client('lambda')
            lambda_client.invoke(
                FunctionName=context.function_name,
                InvocationType='Event',
                Payload=json.dumps({
                    "data_type": data_type,
                    "utc_partition": next_partition,
                    "end_partition": end_partition
                })
            )

        break  # Only process one partition per invocation
