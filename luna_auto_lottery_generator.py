import boto3
import random

def lottery_generator():
    lottery_suggest = ', '.join(str(e) for e in [random.randint(0,9) for i in range(0,6)] + [random.randint(0,14)])

    client = boto3.client('sns')
    client.publish(
        TargetArn="arn:aws:sns:ap-southeast-2:x:luna_lottery_recommendation_topic",
        Message=lottery_suggest,
        MessageStructure='string'
    )

    return lottery_suggest
