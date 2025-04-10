import sys
sys.path.append("./site-packages")
import boto3
import os
import json
import time
from typing import Dict, List, Any
from botocore.exceptions import BotoCoreError, ClientError

dynamodb = boto3.resource("dynamodb")


def batch_delete(table_name: str, keys: List[Dict[str, str]], chunk_size: int = 25):
    table = dynamodb.Table(table_name)
    for i in range(0, len(keys), chunk_size):
        retries = 0
        max_retries = 5
        while retries <= max_retries:
            try:
                with table.batch_writer() as batch:
                    for key in keys[i:i + chunk_size]:
                        batch.delete_item(Key=key)
                print(f"Deleted batch of {len(keys)} items from {table_name}")
                break  # Success, break retry loop
            except ClientError as e:
                if e.response['Error']['Code'] == 'ProvisionedThroughputExceededException':
                    delay = 2 ** retries
                    print(f"Throughput exceeded, retrying in {delay} seconds...")
                    time.sleep(delay)
                    retries += 1
                else:
                    raise e  # Other errors shouldn't be swallowed


def lambda_handler(event: Dict[str, Any], context) -> None:
    table_keys: Dict[str, List[Dict[str, str]]] = {}

    for record in event.get("Records", []):
        try:
            body = record["body"]
            message = json.loads(body)

            table_name = message.get("table_name")
            key_field = message.get("key_field", "uuid_hash")
            key_value = message.get("key_value")

            if not table_name or not key_value:
                print(f"[WARN] Missing required fields: table_name={table_name}, key_value={key_value}")
                continue

            if table_name not in table_keys:
                table_keys[table_name] = []

            table_keys[table_name].append({key_field: key_value})

        except json.JSONDecodeError as e:
            print(f"[ERROR] Failed to decode message body: {record.get('body')}, error: {e}")
        except Exception as e:
            print(f"[ERROR] Unexpected error processing record: {record}, error: {e}")

    for table_name, keys in table_keys.items():
        try:
            batch_delete(table_name, keys)
        except Exception as e:
            print(f"[ERROR] Deletion failed for table {table_name}, will be retried by Lambda: {e}")
            raise  # Triggers retry behavior
