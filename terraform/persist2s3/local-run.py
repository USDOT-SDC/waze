import psutil
import json
import datetime
import time
import os
import uuid
from src.lambda_function import lambda_handler
from src.lambda_function import get_items_from_ddb
from src.lambda_function import get_partitions


class MockContext:
    def __init__(self):
        function_name = os.path.basename(os.path.dirname(__file__))
        now = datetime.datetime.now()
        self.function_name = function_name
        self.function_version = "$LATEST"
        self.invoked_function_arn = f"arn:aws:lambda:us-east-1:123456789012:function:{function_name}"
        self.memory_limit_in_mb = 128
        self.aws_request_id = str(uuid.uuid4())
        self.log_group_name = f"/aws/lambda/{function_name}"
        self.log_stream_name = f"{now.year}/{now.month}/{now.day}/[LATEST]abcdef1234567890"
        self.identity = None
        self.client_context = None

    def get_remaining_time_in_millis(self):
        return int((time.time() + 3) * 1000)  # Simulates 3 seconds remaining


def load_event_from_file(filename):
    with open(filename, "r") as f:
        return json.load(f)


if __name__ == "__main__":
    # Load the event JSON file and instantiate the context
    event = load_event_from_file("local-event.json")
    context = MockContext()

    # Start timing execution
    start_time = time.time()

    # Start tracking memory usage
    process = psutil.Process(os.getpid())

    # Invoke the Lambda function
    response = lambda_handler(event, context)
    # response = get_items_from_ddb(utc_partition=484388, data_type="alerts")
    # response = get_partitions(240, 72, 3600)

    # End timing execution
    end_time = time.time()
    execution_time = end_time - start_time

    # Track max memory usage (in MB)
    max_memory_used = process.memory_info().rss / (1024 * 1024)  # in MB

    # Print the response
    print(json.dumps(response, indent=3))

    # Print the execution time
    print(f"Execution time: {execution_time:.4f} seconds")

    # Print the max memory used
    print(f"Max memory used: {max_memory_used:.2f} MB")
