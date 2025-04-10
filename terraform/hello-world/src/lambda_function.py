import sys
sys.path.append("./site-packages")
from typing import Literal


def lambda_handler(event, context) -> Literal["Hello World!"]:
    msg = "Hello World!"
    return msg
