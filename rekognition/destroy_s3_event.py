import boto3
from botocore.exceptions import ClientError

s3 = boto3.client('s3', region_name='us-east-2')
bucket_name = 'rekognition-upload-bucket1'
lambda_function_name = 'FaceProcessor'

def destroy_s3_lambda_trigger():
    try:
        # Remove the Lambda function permission for S3
        try:
            lambda_client = boto3.client('lambda', region_name='us-east-2')
            lambda_client.remove_permission(
                FunctionName=lambda_function_name,
                StatementId='AllowS3Invoke'
            )
            print(f"Removed Lambda permission for S3 bucket '{bucket_name}'.")
        except ClientError as e:
            if e.response['Error']['Code'] == 'ResourceNotFoundException':
                print(f"Lambda permission for S3 bucket '{bucket_name}' not found (already removed).")
            else:
                print(f"Error removing Lambda permission: {e}")

        # Remove S3 event notification configuration
        try:
            s3.put_bucket_notification_configuration(
                Bucket=bucket_name,
                NotificationConfiguration={}
            )
            print(f"Removed S3 event notification configuration from bucket '{bucket_name}'.")
            return True
        except ClientError as e:
            error_code = e.response['Error']['Code']
            if error_code == 'NoSuchBucket':
                print(f"S3 bucket '{bucket_name}' does not exist (already deleted).")
                return True
            else:
                print(f"Error removing S3 event notification: {e}")
                return False
    except Exception as e:
        print(f"Unexpected error removing S3 event configuration: {e}")
        return False

if __name__ == "__main__":
    destroy_s3_lambda_trigger()