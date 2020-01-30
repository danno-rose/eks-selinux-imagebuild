import boto3
import json
from datetime import datetime, timedelta, timezone, tzinfo

eks_ver = ['1.14','1.13']
db_table = 'ssm-eks-selinux-build'
ssm_trigger_function = "ssm-eks-trigger-automation"
temp_version = "1"
today = datetime.now(timezone.utc)

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
    from boto3.dynamodb.conditions import Key, Attr

    table = dynamodb.Table(tablename)
    filtering_exp = Key('sourceAMI.imageID').eq(idToCompare)
    response = table.scan(
        FilterExpression=filtering_exp
    )
    if response['Items']:
        return True
    else:
        return False

def count_eksSELinux_Builds(tablename,eksver):
    dynamodb = boto3.resource('dynamodb')
    from boto3.dynamodb.conditions import Key, Attr

    table = dynamodb.Table(tablename)
    filtering_exp = Key('kubeVersion').eq(eksver)
    response = table.scan(
        FilterExpression=filtering_exp
    )
    if response['Items']:
        return len(response['Items'])
    else:
        return False

# latest_amiID = (get_LatestEKSAMI(eks_ver))
# print('latest ami id = '+ latest_amiID)
# #print(check_sourceAMIid(db_table,'ami-223456'))
# if (check_sourceAMIid(db_table,latest_amiID)) is True:
#     print('We have built an ami from the latest eks build')
# else:
#     print('We HAVE NOT built an ami from the latest eks build')

#TODO: Trigger SSM build from checkAMI
#TODO: Add write to dynmoDB on build
#TODO: Fill DynamoDB with test data

def lambda_handler(event,context):
    for version in eks_ver:
        latest = (get_LatestEKSAMI(version))
        latest_amiID = latest['id']
        build_date = latest['date']
        print('latest ' + version + ' ami id = '+ latest_amiID)
        if (check_sourceAMIid(db_table,latest_amiID)) is False:
            print('We HAVE NOT built an ami from the latest eks ' + version + ' build')
            # ## Invoke the lambda function if we don't have one built from the latest
            # invokelamda = boto3.client('lambda')
            # payload = {"amid": latest_amiID, "build_version":temp_version}
            # response = invokelamda.invoke(ssm_trigger_function, InvocationType = "Event", Payload = json.dumps(payload))
        elif abs((build_date - today).days) > 21:
            print('invoke new build')
        else:
            print('We have built an ami from the latest eks ' + version + ' build')
            


lambda_handler("","")