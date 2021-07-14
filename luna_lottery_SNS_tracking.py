import json

def sns_tracking_log(event, context):
    message = event['Records'][0]['Sns']['Message']
    print("From SNS: " + message)
    return message