from typing import Literal


def lambda_handler(event, context) -> Literal['Hello World!']:
    msg = "Hello World!"
    print(msg)
    return msg
