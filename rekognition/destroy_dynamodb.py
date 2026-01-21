import boto3
from botocore.exceptions import ClientError

dynamodb = boto3.client('dynamodb', region_name='us-east-2')
table_name = 'FaceMetadata'

def destroy_table():
    try:
        # Delete the DynamoDB table
        try:
            dynamodb.delete_table(TableName=table_name)
            print(f"DynamoDB table '{table_name}' deletion initiated.")

            # Wait for table to be deleted
            waiter = dynamodb.get_waiter('table_not_exists')
            waiter.wait(TableName=table_name)
            print(f"DynamoDB table '{table_name}' deleted successfully.")
            return True
        except dynamodb.exceptions.ResourceNotFoundException:
            print(f"DynamoDB table '{table_name}' does not exist (already deleted).")
            return True
        except ClientError as e:
            print(f"Error deleting DynamoDB table: {e}")
            return False
    except Exception as e:
        print(f"Unexpected error deleting DynamoDB table: {e}")
        return False

if __name__ == "__main__":
    destroy_table()