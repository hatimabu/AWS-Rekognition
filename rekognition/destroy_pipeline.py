import destroy_s3_event
import destroy_lambda
import destroy_iam_role
import destroy_sns
import destroy_dynamodb
import destroy_rekognition_collection
import destroy_s3

def run_destroy_pipeline():
    print("=" * 50)
    print("Starting AWS Infrastructure Destruction Pipeline")
    print("=" * 50)
    print("⚠️  WARNING: This will permanently delete all AWS resources!")
    print("   Make sure you have backed up any important data.")
    print("=" * 50)

    # Step 1: Remove S3 event notification (must be done before deleting Lambda)
    print("\n[1/7] Removing S3 event notification...")
    destroy_s3_event.destroy_s3_lambda_trigger()

    # Step 2: Delete Lambda function
    print("\n[2/7] Deleting Lambda function...")
    destroy_lambda.destroy_lambda()

    # Step 3: Delete IAM role
    print("\n[3/7] Deleting IAM role...")
    destroy_iam_role.destroy_lambda_role()

    # Step 4: Delete SNS topic
    print("\n[4/7] Deleting SNS topic...")
    destroy_sns.destroy_topic()

    # Step 5: Delete DynamoDB table
    print("\n[5/7] Deleting DynamoDB table...")
    destroy_dynamodb.destroy_table()

    # Step 6: Delete Rekognition collection
    print("\n[6/7] Deleting Rekognition collection...")
    destroy_rekognition_collection.destroy_collection()

    # Step 7: Delete S3 bucket (last, as other resources depend on it)
    print("\n[7/7] Deleting S3 bucket...")
    destroy_s3.destroy_bucket()

    print("\n" + "=" * 50)
    print("Infrastructure destruction complete!")
    print("=" * 50)
    print("\nAll AWS resources have been deleted.")
    print("Note: Some resources may take a few minutes to be fully removed from AWS.")

if __name__ == "__main__":
    run_destroy_pipeline()