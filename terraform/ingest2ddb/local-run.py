from src.lambda_function import lambda_handler
import json
from datetime import datetime, timezone
import time
import os
import uuid


class MockContext:
    def __init__(self):
        function_name = os.path.basename(os.path.dirname(__file__))
        now = datetime.now()
        self.function_name = function_name
        self.function_version = "$LATEST"
        self.invoked_function_arn = f"arn:aws:lambda:us-east-1:123456789012:function:{function_name}"
        self.memory_limit_in_mb = 128
        self.aws_request_id = str(uuid.uuid4())
        self.log_group_name = f"/aws/lambda/{function_name}"
        self.log_stream_name = f"{now.year}/{now.month}/{now.day}/[LATEST]abcdef1234567890"
        self.identity = None  # Normally provided in Cognito/auth scenarios
        self.client_context = None  # Only used for mobile apps

    def get_remaining_time_in_millis(self):
        return int((time.time() + 3) * 1000)  # Simulates 3 seconds remaining


def load_event_from_file(filename):
    with open(filename, "r") as f:
        return json.load(f)


def clear_console():
    os.system("cls" if os.name == "nt" else "clear")


if __name__ == "__main__":
    clear_console()
    
    # Load the event JSON file and instantiate the context
    event = load_event_from_file("local-event-lg.json")
    event["time"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    context = MockContext()

    # Start Timer
    start_time = time.perf_counter()

    # Invoke the Lambda function
    response = lambda_handler(event, context)

    # End Timer
    end_time = time.perf_counter()
    execution_time = end_time - start_time

    # Print the response and execution time
    print(json.dumps(response, indent=3))
    print(f"\nExecution Time: {execution_time:.4f} seconds")
