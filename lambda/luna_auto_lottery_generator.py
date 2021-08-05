import boto3
import random
import json
import os
import secrets

def lottery_generator(event, lambda_context):

    customTable = ["normal", "vip"]
    customType = secrets.choice(customTable)

    lottery_suggest = ', '.join(str(e) for e in [random.randint(0,9) for i in range(0,6)] + [random.randint(0,14)])
    targetARN = os.environ['targetARN']
    message = {"lottery_suggest": lottery_suggest}

    client = boto3.client('sns')
    client.publish(
        TargetArn=targetARN,
        Message=json.dumps({'default': json.dumps(message)}),
        MessageStructure='json',
        MessageAttributes={
            'CustomType': {
                'DataType': 'String',
                'StringValue': customType
            }
        }
    )

    print("customType: {}, lottery_suggest: {}".format(customType, lottery_suggest))

    return lottery_suggest
