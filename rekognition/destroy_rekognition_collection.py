import boto3
from botocore.exceptions import ClientError

rekognition = boto3.client('rekognition', region_name='us-east-2')
collection_id = 'employeeFaces'

def destroy_collection():
    try:
        # Delete the Rekognition collection
        try:
            rekognition.delete_collection(CollectionId=collection_id)
            print(f"Rekognition collection '{collection_id}' deleted successfully.")
            return True
        except rekognition.exceptions.ResourceNotFoundException:
            print(f"Rekognition collection '{collection_id}' does not exist (already deleted).")
            return True
        except ClientError as e:
            print(f"Error deleting Rekognition collection: {e}")
            return False
    except Exception as e:
        print(f"Unexpected error deleting Rekognition collection: {e}")
        return False

if __name__ == "__main__":
    destroy_collection()