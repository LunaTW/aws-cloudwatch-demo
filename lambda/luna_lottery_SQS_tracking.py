import json

def sqs_tracking_log(event, context):
    for record in event['Records']:
        print("From SQS")
        payload = record["body"]
        print(str(payload))