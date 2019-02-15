# Load-Inventory Lambda function
#
# This function is triggered by an object being created in an Amazon S3 bucket.
# The file is downloaded and each line is inserted into a DynamoDB table.

import json
import os
import boto3
from botocore.exceptions import ClientError

# Connect to DynamoDB
dynamodb = boto3.resource('dynamodb')

table_name = os.environ['TABLE_NAME']

# Connect to the DynamoDB tables
metadata_dynamodb_table = dynamodb.Table(table_name); # add as env parameter...

# This handler is executed every time the Lambda function is triggered
def lambda_handler(event, context):

  # Show the incoming event in the debug log
  try:
    # Show the incoming event in the debug log
    print("Event received by Lambda function: " + json.dumps(event, indent=2))

    search = event['body']
  except Exception as e:
    return 'error '+str(event)

  item = {"dynamoDB": table_name}
  try:
    response = metadata_dynamodb_table.get_item(Key=search)
  except ClientError as e:
    print(e.response['Error']['Message'])
  else:
    item = response['Item']
    print("GetItem succeeded:")
    print(json.dumps(item, indent=4))

    # Finished!
    return item

