import os
import json
import boto3
import threading
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from botocore.exceptions import ClientError
from botocore.config import Config

config = Config(
    retries={"max_attempts": 10, "mode": "standard"},
    max_pool_connections=50,  # Increase as needed
)


# AWS clients
s3_client = boto3.client("s3")
sqs_client = boto3.client("sqs", config=config)

# Config
DELETION_QUEUE_URL = os.environ.get("DELETE_QUEUE_URL", "https://sqs.us-east-1.amazonaws.com/505135622787/waze-ddb-deletion-queue")
BATCH_SIZE = 10
MAX_THREADS = 50

# Shared progress state
progress_lock = threading.Lock()
messages_sent = 0
total_messages = 0
start_time = time.time()


def log_progress():
    while True:
        time.sleep(30)
        with progress_lock:
            percent = (messages_sent / total_messages) * 100 if total_messages else 0
            elapsed = int(time.time() - start_time)
            print(f"[{elapsed}s] Sent {messages_sent}/{total_messages} messages ({percent:.1f}%)")


def read_json_from_s3(bucket: str, key: str) -> list:
    try:
        response = s3_client.get_object(Bucket=bucket, Key=key)
        return json.loads(response["Body"].read().decode("utf-8"))
    except ClientError as e:
        print(f"Error reading {key} from {bucket}: {e}")
        raise


def send_delete_batch_to_sqs(table_name: str, key_field: str, batch: list, batch_index: int) -> int:
    entries = []
    for i, item in enumerate(batch):
        key_value = item.get(key_field)
        if key_value:
            entries.append(
                {
                    "Id": f"{batch_index}-{i}",
                    "MessageBody": json.dumps({"table_name": table_name, "key_field": key_field, "key_value": key_value}),
                }
            )

    if not entries:
        return 0

    try:
        response = sqs_client.send_message_batch(QueueUrl=DELETION_QUEUE_URL, Entries=entries)
        success_count = len(response.get("Successful", []))
        with progress_lock:
            global messages_sent
            messages_sent += success_count
        return success_count
    except ClientError as e:
        print(f"Error sending batch {batch_index} to SQS: {e}")
        return 0


def delete_object_from_s3(bucket: str, key: str) -> None:
    try:
        s3_client.delete_object(Bucket=bucket, Key=key)
        print(f"Deleted {key} from {bucket}")
    except ClientError as e:
        print(f"Error deleting {key} from {bucket}: {e}")
        raise


def lambda_handler(event: dict, context) -> None:
    bucket = event.get("bucket")
    key = event.get("key")
    if not bucket or not key:
        raise ValueError("Missing bucket or key in event")

    data_type = key.split("/")[0]
    table_name = f"waze_ingest_{data_type}"
    key_field = "uuid_hash"

    print(f"Reading {key} from {bucket}...")
    data = read_json_from_s3(bucket, key)

    global total_messages, messages_sent, start_time
    messages_sent = 0
    total_messages = len(data)
    start_time = time.time()

    # Start logging thread
    log_thread = threading.Thread(target=log_progress, daemon=True)
    log_thread.start()

    futures = []
    with ThreadPoolExecutor(max_workers=MAX_THREADS) as executor:
        for i in range(0, total_messages, BATCH_SIZE):
            batch = data[i : i + BATCH_SIZE]
            batch_index = i // BATCH_SIZE
            futures.append(executor.submit(send_delete_batch_to_sqs, table_name, key_field, batch, batch_index))

        # Wait for all threads to finish
        for future in as_completed(futures):
            future.result()

    print(f"Sent total of {messages_sent} messages to SQS")

    delete_object_from_s3(bucket, key)
    print(f"Finished processing {key}")
