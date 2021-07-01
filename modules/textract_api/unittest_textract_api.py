import boto3
from botocore import stub
import unittest
from unittest import mock
import json
import textract_api


# Run in the directory of this file as `python3 -m unittest unittest_textract_api.py`.


class TestTextractApi(unittest.TestCase):

    def setUp(self):

        filename_iterator = 0
        self.textract_api_responses = []
        self.expected_outputs = []

        while filename_iterator > -1:

            try:

                with open(f'__test_data__/api_responses/textract_output_{filename_iterator}.json', 'r') as file:
                    self.textract_api_responses.append(json.load(file))
                with open(f'__test_data__/expected_output/textract_processed_{filename_iterator}.json', 'r') as file:
                    self.expected_outputs.append(json.load(file))

                filename_iterator += 1

            except FileNotFoundError:

                print(f'Unit testing {filename_iterator} calls.')
                break

        try:
            assert filename_iterator > 0
        except AssertionError:
            print('No files to perform a unit test found.')
            exit()

        self.s3_filename = 'filename.jpg'

    def test_lambda_handler(self):

        textract_client = boto3.client('textract')
        textract_stub = stub.Stubber(textract_client)

        for response in self.textract_api_responses:
            textract_stub.add_response(
                method='detect_document_text',
                service_response=response,
                expected_params={
                    'Document': {
                        'S3Object': {
                            'Bucket': '${bucket_name}',
                            'Name': self.s3_filename
                        }
                    }
                }
            )

        textract_stub.activate()

        for expected_output in self.expected_outputs:

            with mock.patch('textract_api.boto3.client') as mock_client:

                mock_client.return_value = textract_client

                lambda_output = textract_api.lambda_handler(
                    event={
                        'body': json.dumps({'name': self.s3_filename})
                    },
                    context={}
                )

                mock_client.assert_called_once()

                assert len(expected_output) == len(lambda_output)

                for it, line in enumerate(expected_output):
                    assert line == lambda_output[it]

        textract_stub.assert_no_pending_responses()
