import boto3
from botocore.exceptions import ClientError

lambda_client = boto3.client('lambda', region_name='us-east-2')
function_name = 'FaceProcessor'

def destroy_lambda():
    try:
        # Delete the Lambda function
        try:
            lambda_client.delete_function(FunctionName=function_name)
            print(f"Lambda function '{function_name}' deleted successfully.")
            return True
        except lambda_client.exceptions.ResourceNotFoundException:
            print(f"Lambda function '{function_name}' does not exist (already deleted).")
            return True
        except ClientError as e:
            print(f"Error deleting Lambda function: {e}")
            return False
    except Exception as e:
        print(f"Unexpected error deleting Lambda function: {e}")
        return False

if __name__ == "__main__":
    destroy_lambda()