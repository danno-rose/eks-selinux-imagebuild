import json
import boto3
import botocore
import os
from operator import itemgetter
from datetime import datetime, timedelta, timezone, tzinfo
from decimal import Decimal 
from boto3.dynamodb.conditions import Key, Attr
from botocore.exceptions import ClientError
from dynamodb_json import json_util as json

# # Helper class to convert a DynamoDB item to JSON.
# class DecimalEncoder(json.JSONEncoder):
#     def default(self, o):
#         if isinstance(o, decimal.Decimal):
#             if o % 1 > 0:
#                 return float(o)
#             else:
#                 return int(o)
#         return super(DecimalEncoder, self).default(o)



# eks_ver = ['1.14','1.13']
# db_table = 'ssm-eks-selinux-build'
# ssm_trigger_function = "ssm-eks-trigger-automation"
# temp_version = "1"
# today = datetime.now(timezone.utc)
# dynamodb = boto3.resource('dynamodb')
# table = dynamodb.Table(db_table)
# response = table.put_item(
#    Item={
#        'imageID': "ami-03984204823048302",
#        'hsbcVersion' : 4,
#         'year': datetime.utcnow().isoformat(),
#         'title': "title",
#         'info': {
#             'plot':"Nothing happens at all.",
#             'rating': 1
#         }
#     }
# )

test=os.environ.get("LIST_ITEMS").split(",")

for i in test:
    print(i)