import boto3
import json
import os
import uuid


class DatabaseAdapter:

    # boto3 communicates numbers as strings to/from DynamoDB
    # make sure that something actually is a number before implicit conversion
    # and convert back before returning database scans

    def __init__(self):
        self.db_client = boto3.client("dynamodb")
        self.db_name = os.getenv("table_name")

    def scan_database(self):
        response = self.db_client.scan(TableName=self.db_name)

        items = [
            {
                "id": item["id"]["S"],
                "name": item["name"]["S"],
                "priority": float(item["priority"]["N"]),
                "check": item["check"]["BOOL"],
                "timestamp": item["timestamp"]["S"],
                "modified": item["modified"]["S"]
            }
            for item in response["Items"]
        ]

        return items

    def put_item(self, item_id: str, item_name: str, item_priority: float, item_timestamp: str, item_modified: str):
        assert type(item_priority) == int or type(item_priority) == float
        item_priority = str(item_priority)

        self.db_client.put_item(
            TableName=self.db_name,
            Item={
                "id": {"S": item_id},
                "name": {"S": item_name},
                "priority": {"N": item_priority},
                "check": {"BOOL": False},
                "timestamp": {"S": item_timestamp},
                "modified": {"S": item_modified}
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

    def update_item(self, item_id: str, item_name: str, item_priority: float, item_check: str, item_modified: str):
        assert type(item_priority) == int or type(item_priority) == float
        item_priority = str(item_priority)

        self.db_client.update_item(
            TableName=self.db_name,
            Key={
                "id": {
                    "S": item_id
                }
            },
            UpdateExpression="SET #n = :new_name, #p = :new_priority, #c = :new_check, #m = :new_modified",
            ExpressionAttributeNames={
                "#n": "name",
                "#p": "priority",
                "#c": "check",
                "#m": "modified"
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
                },
                ":new_modified": {
                    "S": item_modified
                }
            }
        )


def lambda_handler(event, context):
    print(event)

    database_adapter = DatabaseAdapter()

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
                item_check=request["check"],
                item_modified=request["modified"]
            )
        else:
            new_id = str(uuid.uuid4())

            database_adapter.put_item(
                item_id=new_id,
                item_name=request["name"],
                item_priority=request["priority"],
                item_timestamp=request["timestamp"],
                item_modified=request["modified"]
            )

    database_scan = database_adapter.scan_database()

    response = {
        "statusCode": 200,
        "headers": {
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps(database_scan)
    }

    return response
