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
    cloudwatch.put_metric_data(
        MetricData = [
            {
                'MetricName': 'luna_ApproximateNumberOfMessagesVisible',
                'Dimensions': [
                    {
                        'Name': 'QueueName',
                        'Value': 'luna_lottery_recommendation_SQS'
                    }
                ],
                'Unit': 'None',
                'Value': 1
            }
        ],
        Namespace='Luna'
    )
    cloudwatch.put_metric_data(
        MetricData = [
            {
                'MetricName': 'luna_fraud_check_metric',
                'Dimensions': [
                    {
                        'Name': 'fraud_choice',
                        'Value': 'value_is_ten'
                    }
                ],
                'Unit': 'None',
                'Value': 1
            },
        ],
        Namespace='Luna'
    )

    return "~ Adding custom metric to cloudwatch successful ~ "



