import boto3
import random

def custom_metric(event, lambda_context):
    cloudwatch = boto3.client('cloudwatch')

    cloudwatch.put_metric_data(
        MetricData = [
            {
                'MetricName': 'luna_test_metric',
                'Dimensions': [
                    {
                        'Name': 'PURCHASES_SERVICE',
                        'Value': 'CoolService'
                    },
                    {
                        'Name': 'APP_VERSION',
                        'Value': '1.0'
                    },
                ],
                'Unit': 'None',
                'Value': random.randint(1, 500)
            },
        ],
        Namespace='Luna'
    )

    return "~ Adding custom metric to cloudwatch successful ~ "



