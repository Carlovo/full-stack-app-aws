import boto3
import json
import os
import uuid


class DatabaseAdapter:

    def __init__(self):
        self.db_client = boto3.client("dynamodb")
        self.db_name = os.getenv("table_name")

    def scan_database(self):
        return self.db_client.scan(TableName=self.db_name)

    def put_item(self, item_id: str, item_name: str, item_priority: float, item_timestamp: str):
        # boto3 communicates numbers as string to DynamoDB
        # make sure that it actually is a number before implicit conversion
        assert type(item_priority) == int or type(item_priority) == float
        item_priority = str(item_priority)

        self.db_client.put_item(
            TableName=self.db_name,
            Item={
                "id": {"S": item_id},
                "name": {"S": item_name},
                "priority": {"N": item_priority},
                "check": {"BOOL": False},
                "timestamp": {"S": item_timestamp}
            }
        )

    def delete_item(self, item_id: str):
        self.db_client.delete_item(
            TableName=self.db_name,
            Key={
                "id": {
                    "S": item_id
                }
            }
        )

    def update_item(self, item_id: str, item_name: str, item_priority: float, item_check: str):
        # boto3 communicates numbers as string to DynamoDB
        # make sure that it actually is a number before implicit conversion
        assert type(item_priority) == int or type(item_priority) == float
        item_priority = str(item_priority)

        self.db_client.update_item(
            TableName=self.db_name,
            Key={
                "id": {
                    "S": item_id
                }
            },
            UpdateExpression="SET #n = :new_name, #p = :new_priority, #c = :new_check",
            ExpressionAttributeNames={
                "#n": "name",
                "#p": "priority",
                "#c": "check"
            },
            ExpressionAttributeValues={
                ":new_name": {
                    "S": item_name
                },
                ":new_priority": {
                    "N": item_priority
                },
                ":new_check": {
                    "BOOL": item_check
                }
            }
        )


def lambda_handler(event, context):
    database_adapter = DatabaseAdapter()
    database_scan = database_adapter.scan_database()

    # check for POST, otherwise default to GET
    if event["httpMethod"] == "POST":

        request = json.loads(event["body"])

        # check operation type, default to PUT/CREATE
        if request["operation"] == "Delete":
            database_adapter.delete_item(item_id=request["id"])
        # there are multiple actions in the front end that can update the table
        elif request["operation"] == "Save":
            database_adapter.update_item(
                item_id=request["id"],
                item_name=request["name"],
                item_priority=request["priority"],
                item_check=request["check"]
            )
        else:
            new_id = str(uuid.uuid4())

            database_adapter.put_item(
                item_id=new_id,
                item_name=request["name"],
                item_priority=request["priority"],
                item_timestamp=request["timestamp"]
            )

        database_scan = database_adapter.scan_database()

    items = [
        {
            "id": item["id"]["S"],
            "name": item["name"]["S"],
            "priority": float(item["priority"]["N"]),
            "check": item["check"]["BOOL"],
            "timestamp": item["timestamp"]["S"]
        }
        for item in database_scan["Items"]
    ]

    response = {
        "statusCode": 200,
        "headers": {
            'Access-Control-Allow-Origin': '*',
        },
        "body": json.dumps(items)
    }

    return response
