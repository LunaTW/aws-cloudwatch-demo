import json

def vip_lottery_recommendation_monitor(event, context):

    message = event['Records'][0]['Sns']['Message']
    print("From SNS: " + message)

    lottery_suggest = json.loads(message)
    print(lottery_suggest)

    plusNumber = lottery_suggest["lottery_suggest"].split(", ")[-1]
    print("plusNumber is {}".format(plusNumber))

    if plusNumber == '10':
        raise Exception("Warning! Warning! Warning! VIP system may be under attack!")

    return message