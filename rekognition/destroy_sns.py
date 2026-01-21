import boto3
from botocore.exceptions import ClientError

sns = boto3.client('sns', region_name='us-east-2')
topic_name = 'FaceDetectedTopic'

def destroy_topic():
    try:
        # First, get the topic ARN
        try:
            response = sns.list_topics()
            topic_arn = None
            for topic in response['Topics']:
                if topic['TopicArn'].endswith(f':{topic_name}'):
                    topic_arn = topic['TopicArn']
                    break

            if not topic_arn:
                print(f"SNS topic '{topic_name}' does not exist (already deleted).")
                return True
        except ClientError as e:
            print(f"Error listing SNS topics: {e}")
            return False

        # Delete all subscriptions for the topic
        try:
            subscriptions = sns.list_subscriptions_by_topic(TopicArn=topic_arn)
            for subscription in subscriptions['Subscriptions']:
                if subscription['SubscriptionArn'] != 'PendingConfirmation':
                    sns.unsubscribe(SubscriptionArn=subscription['SubscriptionArn'])
                    print(f"Unsubscribed from topic: {subscription['Endpoint']}")
        except ClientError as e:
            print(f"Error unsubscribing from topic: {e}")

        # Delete the SNS topic
        try:
            sns.delete_topic(TopicArn=topic_arn)
            print(f"SNS topic '{topic_name}' deleted successfully.")
            return True
        except sns.exceptions.NotFoundException:
            print(f"SNS topic '{topic_name}' does not exist (already deleted).")
            return True
        except ClientError as e:
            print(f"Error deleting SNS topic: {e}")
            return False
    except Exception as e:
        print(f"Unexpected error deleting SNS topic: {e}")
        return False

if __name__ == "__main__":
    destroy_topic()