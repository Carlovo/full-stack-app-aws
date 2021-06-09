import json
import boto3


def lambda_handler(event, context):
    print(event)

    event_body = json.loads(event['body'])

    client = boto3.client('textract')

    response = client.detect_document_text(
        Document={'S3Object': {
            'Bucket': '${bucket_name}',
            'Name': event_body['name']
        }}
    )

    line_blocks = [block for block in response['Blocks']
                   if block['BlockType'] == 'LINE']

    line_child_ids = []

    for block in line_blocks:
        for relationship in block['Relationships']:
            if relationship['Type'] == 'CHILD':
                line_child_ids += relationship['Ids']

    result = [block['Text'] for block in line_blocks] + \
        [block['Text'] for block in response['Blocks']
         if block['BlockType'] == 'WORD' and block['Id'] not in line_child_ids]

    print(result)

    return result
