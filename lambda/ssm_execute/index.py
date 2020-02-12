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
# timedelta = 21
# ssm_trigger_function = "ssm-eks-trigger-automation"
# temp_version = "1"
# today = datetime.now(timezone.utc)

SSMDocument = os.environ['ssm_doc']
eks_ver = os.environ.get("eks_versions").split(",")
db_table = os.environ['dynamodb_table']
timedelta = os.environ['time_delta']
################################
#### FUNCTIONS             #####
################################
def get_LatestEKSAMI(eksver):
    ssm_client = boto3.client('ssm')
    ssm = ("/aws/service/eks/optimized-ami/" + eksver + "/amazon-linux-2/recommended/image_id")
    
    response = ssm_client.get_parameter(
        Name=ssm
    )

    item = response['Parameter']
    amiID = item['Value']
    date = item['LastModifiedDate']
    data = {"id": amiID, "date": date}
    
    return data


def check_sourceAMIid(tablename,idToCompare):
    dynamodb = boto3.resource('dynamodb')

    table = dynamodb.Table(tablename)
    filtering_exp = Key('sourceAMI.imageID').eq(idToCompare)
    response = table.scan(
        FilterExpression=filtering_exp
    )
    if response['Items']:
        return True
    else:
        return False

def return_hdsbcBuilds(tablename,key,valuetocompare):
    dynamodb = boto3.resource('dynamodb')

    table = dynamodb.Table(tablename)
    filtering_exp = Key(key).eq(valuetocompare)
    response = table.scan(
        FilterExpression=filtering_exp
    )
    if response['Items']:
        return response['Items']
    else:
        pass

def count_eksSELinux_Builds(tablename,eksver):
    dynamodb = boto3.resource('dynamodb')

    table = dynamodb.Table(tablename)
    filtering_exp = Key('kubeVersion').eq(eksver)
    response = table.scan(
        FilterExpression=filtering_exp
    )
    if response['Items']:
        return len(response['Items'])
    else:
        return False

def start_ssm(ami_id,version_number):
    client = boto3.client('ssm')
    response = client.start_automation_execution(
        DocumentName=(SSMDocument),
        Parameters={
            "amiId": ami_id,
            "version": version_number
        }
    )

### Lambda Tigger#
def lambda_handler(event, context):
        
        for version in eks_ver:
            latest_base_details = (get_LatestEKSAMI(str(version)))
            latest_base_amiID = latest_base_details['id']
            latest_base_build_date = latest_base_details['date']
       
            print('latest ' + str(version) + ' ami id = '+ latest_base_amiID)

            if (check_sourceAMIid(db_table,latest_base_amiID)) is True:
                current_builds = json.loads(return_hdsbcBuilds(db_table,'sourceAMI.imageID',latest_base_amiID))
                sorted_values = (sorted(current_builds, key = lambda i: i['hsbcVersion'], reverse = True))
                lastbuild_date = sorted_values[0]['dateCreated']
                delta_between_builddates = abs((datetime(latest_base_build_date.year, latest_base_build_date.month, latest_base_build_date.day) - datetime(lastbuild_date.year, lastbuild_date.month, lastbuild_date.day)).days)
                if int(delta_between_builddates) > int(timedelta):
                    print('Our build is more than '+ str(timedelta) + ' days old')
                    print('Starting Build')
                    versionNumber = (len(current_builds) + 1)
                    start_ssm([latest_base_amiID],[str(versionNumber)]) 
            elif (check_sourceAMIid(db_table,latest_base_amiID)) is False:
                print('We HAVE NOT built an ami from the latest eks ' + version + ' build')
                print('Starting Build')
                ## starting the build    
                #start_ssm(latest_base_amiID,ver)
            else:
                print('Nothing to do - current build is less that 21 days and is using latest eks ami')