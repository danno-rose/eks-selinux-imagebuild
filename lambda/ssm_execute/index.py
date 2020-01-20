import json
import boto3
import botocore
import datetime
import os
from operator import itemgetter


SSMDocument = os.environ['ssm_doc']
#SearchString = os.environ['amiSearchString']


def lambda_handler(event, context):
    #yeardaymonthtime =datetime.datetime.now().strftime("%Y%m%d%H%M%S")
    #val = str(yeardaymonthtime)
    client = boto3.client('ec2')
#   response = client.describe_images(
#     Filters=[{
#         'Name': 'name',
#         'Values': [(SearchString)]
#     },
#     {
#         'Name': 'architecture',
#         'Values': ['x86_64']
#     }

#     ],
#     Owners=[
#         'amazon'
#     ]
#   )
    # Sort on Creation date Desc
    #image_details = sorted(response['Images'], key=itemgetter('CreationDate'), reverse=True)
    ami_id = "ami-03772b2e67db0c87b"
    # Send Parameters to SSM to start job
    client = boto3.client('ssm')
    response = client.start_automation_execution(
        DocumentName=(SSMDocument),
        Parameters={
            # "AMIVersion":[val],
            "amiId": [ami_id]
        }
    )
