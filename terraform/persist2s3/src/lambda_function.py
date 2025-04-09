import sys
sys.path.append("./site-packages")
from typing import Dict, List, Tuple, Any
import json
import os
import io
import time
from datetime import datetime
from decimal import Decimal
import boto3
from botocore.exceptions import BotoCoreError
from boto3.dynamodb.conditions import Key
import h3
import pyarrow as pa
import pyarrow.parquet as pq

# Initialize clients
dynamodb = boto3.resource("dynamodb")
s3_client = boto3.client("s3")
sqs = boto3.client("sqs")


def get_data_lake_bucket() -> str:
    """Returns the raw data S3 bucket name from environment variables or a default value."""
    return os.environ.get("DATA_LAKE_BUCKET", "gov.dot.sdc.dev.waze.data-lake")


def get_delete_queue_url() -> str:
    """Returns the raw data S3 bucket name from environment variables or a default value."""
    return os.environ.get("DELETE_QUEUE_URL", "https://sqs.us-east-1.amazonaws.com/505135622787/waze-ddb-deletion-queue")


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
    """Fetch items from DynamoDB that are older than a specific epoch."""
    table = dynamodb.Table(table_name)

    # Query the GSI on utc_partition_index to get items older than the specified utc_partition
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

    return convert_decimals_to_numbers(items)


def generate_h3_prefix(lat, lon, resolution=2) -> str:
    """Generate the H3 prefix based on latitude, longitude, and resolution."""
    h3_index = h3.latlng_to_cell(lat, lon, resolution)
    return h3_index[:6]  # Prefix for resolution 2 (first 6 characters)
    # return h3_index


def write_parquet_to_s3(data: List[Dict[str, Any]], s3_key: str):
    """Convert list of dicts to Parquet using PyArrow and upload to S3."""
    if not data:
        print(f"No data to write for {s3_key}")
        return

    table = pa.Table.from_pylist(data)
    parquet_buffer = io.BytesIO()
    pq.write_table(table, parquet_buffer)

    s3_client.put_object(
        Bucket=get_data_lake_bucket(),
        Key=s3_key,
        Body=parquet_buffer.getvalue(),
        ContentType="application/vnd.apache.parquet",
    )


def get_line_average(line: List[Dict[str, float]]) -> Tuple[float, float]:
    """Calculate the average of x and y values."""
    total_x = 0
    total_y = 0
    count = len(line)

    for point in line:
        total_x += point["x"]
        total_y += point["y"]

    avg_lon = total_x / count if count > 0 else 0
    avg_lat = total_y / count if count > 0 else 0

    return avg_lat, avg_lon


def queue_deletes(table_name: str, items: List[Dict], key_field: str = "uuid_hash"):
    """Send delete requests to SQS queue."""
    for item in items:
        key_value = item.get(key_field)
        if key_value:
            sqs.send_message(
                QueueUrl=get_delete_queue_url(),
                MessageBody=json.dumps({
                    "table_name": table_name,
                    "key_field": key_field,
                    "key_value": key_value
                })
            )


def lambda_handler(event: Dict, context) -> None:
    """Lambda handler to process data and persist to S3 in Parquet format."""
    partition_size_seconds = 3600
    start_partition, end_partition = get_partitions(
        start_hours_ago=96,
        end_hours_ago=84,
        partition_size_seconds=partition_size_seconds,
    )
    data_type = event.get("data_type")
    if not data_type:
        raise ValueError("Missing required parameter: 'data_type'")

    current_partition = start_partition
    table_name = f"waze_ingest_{data_type}"
    
    while current_partition <= end_partition:
        items = get_items_from_ddb(
            utc_partition=current_partition,
            table_name=table_name
        )
        current_epoch = current_partition * partition_size_seconds
        year, month, day, hour = extract_date_parts(utc_epoch=current_epoch)

        if not items:
            print(f"No {data_type} data found for partition: {current_partition}, {year}-{month}-{day} {hour}:00")
            current_partition += 1
            continue

        print(f"Found {data_type} data for partition: {current_partition}, {year}-{month}-{day} {hour}:00")
        grouped_data = {}

        for item in items:
            location = item["data"].get("location")
            line = item["data"].get("line")
            if location is not None:
                lat = location.get("y")
                lon = location.get("x")
                h3_prefix = generate_h3_prefix(lat, lon)
            elif line is not None:
                avg_lat, avg_lon = get_line_average(line=line)
                h3_prefix = generate_h3_prefix(avg_lat, avg_lon)
            else:
                continue

            if h3_prefix not in grouped_data:
                grouped_data[h3_prefix] = []

            grouped_data[h3_prefix].append(item)

        for h3_prefix, item_group in grouped_data.items():
            data_to_persist = [i["data"] for i in item_group]
            s3_key = f"y={year}/m={month}/d={day}/h={hour}/h3={h3_prefix}/{data_type}.parquet"
            
            write_parquet_to_s3(data_to_persist, s3_key)
            print(f"Data written to S3 at {s3_key}")

            # Queue deletes for just the items written to this parquet file
            queue_deletes(table_name=table_name, items=item_group)
            print(f"Queued {len(item_group)} {data_type} items for deletion from {table_name}.")

        print(f"Completed processing {data_type} for partition: {current_partition}, {year}-{month}-{day} {hour}:00")
        current_partition += 1

    print(f"Completed processing {data_type}.")
