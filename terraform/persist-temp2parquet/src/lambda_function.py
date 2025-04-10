import sys

sys.path.append("./site-packages")
from typing import Dict, List, Tuple, Any
import os
import io
import json
import boto3
from decimal import Decimal
from datetime import datetime
import pyarrow as pa
import pyarrow.parquet as pq
import h3

# Initialize AWS clients
s3_client = boto3.client("s3")
lambda_client = boto3.client("lambda")


def get_data_lake_bucket() -> str:
    """
    Get the S3 bucket name for data lake output.

    Returns:
        str: The bucket name to write Parquet files to.
    """
    return os.environ.get("DATA_LAKE_BUCKET", "gov.dot.sdc.dev.waze.data-lake")


def get_delete_lambda_name() -> str:
    """
    Get the name of the Lambda function that deletes temp JSON files.

    Returns:
        str: The function name for persist-temp2delete.
    """
    return os.environ.get("DELETE_LAMBDA", "waze_persist_temp2delete")


def extract_date_parts(utc_epoch: int) -> Tuple[int, int, int, int]:
    """
    Convert epoch time to year, month, day, and hour.

    Args:
        utc_epoch (int): Unix timestamp in seconds.

    Returns:
        Tuple[int, int, int, int]: Year, month, day, hour.
    """
    dt = datetime.utcfromtimestamp(utc_epoch)
    return dt.year, dt.month, dt.day, dt.hour


def convert_decimals_to_numbers(data: Any) -> Any:
    """
    Recursively convert Decimal values to int or float in a nested structure.

    Args:
        data (Any): Arbitrary nested data structure.

    Returns:
        Any: Structure with Decimals converted to native numeric types.
    """
    if isinstance(data, list):
        return [convert_decimals_to_numbers(i) for i in data]
    elif isinstance(data, dict):
        return {k: convert_decimals_to_numbers(v) for k, v in data.items()}
    elif isinstance(data, Decimal):
        return int(data) if data % 1 == 0 else float(data)
    return data


def get_line_average(line: List[Dict[str, float]]) -> Tuple[float, float]:
    """
    Compute the average (latitude, longitude) from a list of points.

    Args:
        line (List[Dict[str, float]]): List of points with "x" and "y".

    Returns:
        Tuple[float, float]: Average latitude (y), longitude (x).
    """
    total_x = sum(point["x"] for point in line)
    total_y = sum(point["y"] for point in line)
    count = len(line)
    return (total_y / count, total_x / count) if count else (0.0, 0.0)


def generate_h3_prefix(lat: float, lon: float, resolution: int = 2) -> str:
    """
    Generate an H3 index prefix at the specified resolution.

    Args:
        lat (float): Latitude.
        lon (float): Longitude.
        resolution (int, optional): H3 resolution. Defaults to 2.

    Returns:
        str: First 6 characters of the H3 index (for resolution 2).
    """
    return h3.latlng_to_cell(lat, lon, resolution)[:6]


def write_parquet_to_s3(data: List[Dict[str, Any]], s3_key: str) -> None:
    """
    Convert a list of dictionaries to a Parquet file and upload to S3.

    Args:
        data (List[Dict[str, Any]]): List of records to persist.
        s3_key (str): Destination S3 key.
    """
    if not data:
        print(f"Skipping empty write: {s3_key}")
        return

    table = pa.Table.from_pylist(data)
    buffer = io.BytesIO()
    pq.write_table(table, buffer)

    s3_client.put_object(
        Bucket=get_data_lake_bucket(),
        Key=s3_key,
        Body=buffer.getvalue(),
        ContentType="application/vnd.apache.parquet",
    )
    print(f"Wrote {len(data)} records to {s3_key}")


def lambda_handler(event: Dict[str, Any], context: Any) -> None:
    """
    AWS Lambda entry point for processing a temp JSON file triggered by S3 PUT event.
    It reads the file, groups records by H3 index, writes Parquet files to the data lake,
    and invokes a Lambda function to delete the source JSON.

    Args:
        event (Dict[str, Any]): S3 event payload with bucket and object key.
        context (Any): Lambda context object (unused).
    """
    try:
        record = event["Records"][0]
        bucket = record["s3"]["bucket"]["name"]
        json_key = record["s3"]["object"]["key"]
        print(f"Processing s3://{bucket}/{json_key}")
    except (KeyError, IndexError) as e:
        print(f"Invalid event structure: {e}")
        raise

    data_type = json_key.split("/")[0]
    partition_str = json_key.split("/")[1].replace(".json", "")

    if not partition_str.isdigit():
        print(f"Invalid partition in key: {json_key}")
        raise ValueError(f"Expected integer partition in key, got: {partition_str}")

    partition = int(partition_str)

    try:
        obj = s3_client.get_object(Bucket=bucket, Key=json_key)
        raw_data: List[Dict[str, Any]] = json.loads(obj["Body"].read())
    except Exception as e:
        print(f"Failed to load JSON from {bucket}/{json_key}: {e}")
        raise

    items: List[Dict[str, Any]] = convert_decimals_to_numbers(raw_data)
    if not items:
        print(f"No items found in {json_key}, skipping.")
        return

    grouped: Dict[str, List[Dict[str, Any]]] = {}
    for item in items:
        data: Dict[str, Any] = item.get("data", {})
        location = data.get("location")
        line = data.get("line")

        if location:
            lat, lon = location.get("y"), location.get("x")
        elif line:
            lat, lon = get_line_average(line)
        else:
            continue

        h3_prefix: str = generate_h3_prefix(lat, lon)
        grouped.setdefault(h3_prefix, []).append(data)

    utc_epoch: int = partition * 3600
    year, month, day, hour = extract_date_parts(utc_epoch)

    for h3_prefix, group in grouped.items():
        s3_key: str = f"y={year}/m={month}/d={day}/h={hour}/h3={h3_prefix}/{data_type}.parquet"
        write_parquet_to_s3(group, s3_key)

    try:
        lambda_client.invoke(
            FunctionName=get_delete_lambda_name(),
            InvocationType="Event",
            Payload=json.dumps({"bucket": bucket, "key": json_key}).encode("utf-8"),
        )
        print(f"Invoked {get_delete_lambda_name()} for {json_key}")
    except Exception as e:
        print(f"Failed to invoke delete lambda: {e}")
        raise
