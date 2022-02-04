import boto3
import uuid

client = boto3.client('s3')


def lambda_handler(event, context):
    print(event)

    name_id = str(uuid.uuid4())

    url = client.generate_presigned_post(
        # Templated by Terraform
        Bucket='${bucket_name}',
        Key=f'{name_id}.jpg',
        Conditions=[["content-length-range", 1000, 10000000]],
        ExpiresIn=60
    )

    return url
