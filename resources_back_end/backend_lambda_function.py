import boto3
import json
import os


class DatabaseAdapter:

    def __init__(self):
        self.db_client = boto3.client("dynamodb")
        self.db_name = os.getenv("table_name")

    def scan_database(self):
        return self.db_client.scan(TableName=self.db_name)

    def put_item_with_attribute(self, item_id: str, attribute_name: str, value: str):
        self.db_client.put_item(
            TableName=self.db_name,
            Item={
                "id": {"N": item_id},
                attribute_name: {"S": value}
            }
        )

    def delete_item(self, item_id: str):
        self.db_client.delete_item(
            TableName=self.db_name,
            Key={
                "id": {
                    "N": item_id
                }
            }
        )

    def update_item_attribute(self, item_id: str, attribute_name: str, new_value: str):
        self.db_client.update_item(
            TableName=self.db_name,
            Key={
                "id": {
                    "N": item_id
                }
            },
            UpdateExpression="SET #n = :new_value",
            ExpressionAttributeNames={"#n": attribute_name},
            ExpressionAttributeValues={
                ":new_value": {
                    "S": new_value
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
        # the terms Save and Update are intermixed in the front end
        elif request["operation"] == "Save":
            database_adapter.update_item_attribute(
                item_id=request["id"],
                attribute_name="name",
                new_value=request["name"]
            )
        else:
            table_item_ids = [
                int(item["id"]["N"])
                for item in database_scan["Items"]
            ]
            table_item_ids.append(0)

            new_id = str(max(table_item_ids) + 1)

            database_adapter.put_item_with_attribute(
                item_id=new_id,
                attribute_name="name",
                value=request["name"]
            )

        database_scan = database_adapter.scan_database()

    items = [
        {"id": item["id"]["N"], "name": item["name"]["S"]}
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
