from typing import Dict
from pathlib import Path
import os
import boto3
import json
import time

lambda_client = boto3.client("lambda")


def get_states(states_file: str = "states.json") -> Dict[str, str]:
    """
    Loads state mapping from a JSON file.

    :return: Dictionary mapping state names to unique tokens.
    """

    parent_path = Path(__file__).resolve().parent
    with open(parent_path / states_file) as f:
        return json.load(f)


def get_ingest_lambda() -> str:
    """
    Returns the ingest Lambda's name.

    :return: string of ingest Lambda's name
    """
    return os.environ.get("INGEST_LAMBDA", "waze_ingest2ddb")


def lambda_handler(event, context):
    """
    Orchestration Lambda that invokes the ingest Lambda for each state.

    :param event: AWS Lambda event payload.
    :param context: AWS Lambda context object.
    """

    for state_name, unique_token in get_states().items():
        payload = {"state_name": state_name, "unique_token": unique_token}

        print(f"Invoking ingest Lambda for state: {state_name}")

        response = lambda_client.invoke(
            FunctionName=get_ingest_lambda(),
            InvocationType="Event",
            Payload=json.dumps(payload),  # Asynchronous execution
        )

        print(f"Invoked {get_ingest_lambda()} for {state_name}, response: {response}")
        time.sleep(1.6)

    return {"status": "Orchestration completed"}
