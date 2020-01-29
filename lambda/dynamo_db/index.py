import boto3
import json

eks_ver = '1.14'
db_table = 'ssm-eks-selinux-build'

def get_LatestEKSAMI_lastModified(eksver):
    ssm_client = boto3.client('ssm')
    ssm = ("/aws/service/eks/optimized-ami/" + eksver + "/amazon-linux-2/recommended/image_id")
    
    response = ssm_client.get_parameter(
        Name=ssm
    )

    item = response['Parameter']
    date = item['LastModifiedDate']
    
    return date

def get_LatestEKSAMI_id(eksver):
    ssm_client = boto3.client('ssm')
    ssm = ("/aws/service/eks/optimized-ami/" + eksver + "/amazon-linux-2/recommended/image_id")
    
    response = ssm_client.get_parameter(
        Name=ssm
    )

    item = response['Parameter']
    amiID = item['Value']
    
    return amiID


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

latest_amiID = (get_LatestEKSAMI_id(eks_ver))
print('latest ami id = '+ latest_amiID)
#print(check_sourceAMIid(db_table,'ami-223456'))
if (check_sourceAMIid(db_table,latest_amiID)) is True:
    print('We have built an ami from the latest eks build')
else:
    print('We HAVE NOT built an ami from the latest eks build')

#TODO: Trigger SSM build from checkAMI
#TODO: Add write to dynmoDB on build
#TODO: Fill DynamoDB with test data