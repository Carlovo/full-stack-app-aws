import boto3
import json


def lambda_handler(event, context):
    dynamodb = boto3.client("dynamodb")
    table_name = "minimal-backend-table"
    table_scan = dynamodb.scan(TableName=table_name)

    # check for POST, otherwise default to GET
    if event["httpMethod"] == "POST":

        request = json.loads(event["body"])

        if request["operation"] == "delete":
            dynamodb.delete_item(
                TableName=table_name,
                Key={
                    "id": {
                        "N": request["id"]
                    }
                }
            )
        elif request["operation"] == "update":
            dynamodb.update_item(
                TableName=table_name,
                Key={
                    "id": {
                        "N": request["id"]
                    }
                },
                UpdateExpression="SET #n = :new_name",
                ExpressionAttributeNames={"#n": "name"},
                ExpressionAttributeValues={
                    ":new_name": {
                        "S": request["name"]
                    }
                }
            )
        else:
            table_item_ids = [
                int(item["id"]["N"])
                for item in table_scan["Items"]
            ]
            table_item_ids.append(0)

            new_id = max(table_item_ids) + 1

            dynamodb.put_item(
                TableName=table_name,
                Item={
                    "id": {"N": str(new_id)},
                    "name": {"S": request["name"]}
                }
            )

        table_scan = dynamodb.scan(TableName=table_name)

    items = [
        {"id": item["id"]["N"], "name": item["name"]["S"]}
        for item in table_scan["Items"]
    ]

    response = {
        "statusCode": 200,
        "headers": {
            'Access-Control-Allow-Origin': '*',
        },
        "body": json.dumps(items)
    }

    return response
