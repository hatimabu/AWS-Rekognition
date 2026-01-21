import boto3
from botocore.exceptions import ClientError

s3 = boto3.client('s3', region_name='us-east-2')
bucket_name = 'rekognition-upload-bucket1'

def destroy_bucket():
    try:
        # First, delete all objects in the bucket
        try:
            # List and delete all objects
            response = s3.list_objects_v2(Bucket=bucket_name)
            if 'Contents' in response:
                objects_to_delete = [{'Key': obj['Key']} for obj in response['Contents']]
                s3.delete_objects(
                    Bucket=bucket_name,
                    Delete={'Objects': objects_to_delete}
                )
                print(f"Deleted {len(objects_to_delete)} objects from bucket '{bucket_name}'.")

                # Continue deleting if there are more objects
                while response.get('IsTruncated'):
                    response = s3.list_objects_v2(
                        Bucket=bucket_name,
                        ContinuationToken=response['NextContinuationToken']
                    )
                    if 'Contents' in response:
                        objects_to_delete = [{'Key': obj['Key']} for obj in response['Contents']]
                        s3.delete_objects(
                            Bucket=bucket_name,
                            Delete={'Objects': objects_to_delete}
                        )
                        print(f"Deleted additional {len(objects_to_delete)} objects from bucket '{bucket_name}'.")
        except ClientError as e:
            if e.response['Error']['Code'] != 'NoSuchBucket':
                print(f"Error deleting objects from bucket: {e}")

        # Delete all object versions (for versioned buckets)
        try:
            response = s3.list_object_versions(Bucket=bucket_name)
            versions_to_delete = []
            if 'Versions' in response:
                versions_to_delete.extend([{'Key': v['Key'], 'VersionId': v['VersionId']} for v in response['Versions']])
            if 'DeleteMarkers' in response:
                versions_to_delete.extend([{'Key': dm['Key'], 'VersionId': dm['VersionId']} for dm in response['DeleteMarkers']])

            if versions_to_delete:
                s3.delete_objects(
                    Bucket=bucket_name,
                    Delete={'Objects': versions_to_delete}
                )
                print(f"Deleted {len(versions_to_delete)} object versions from bucket '{bucket_name}'.")

                # Continue deleting versions if there are more
                while response.get('IsTruncated'):
                    response = s3.list_object_versions(
                        Bucket=bucket_name,
                        KeyMarker=response.get('KeyMarker', ''),
                        VersionIdMarker=response.get('VersionIdMarker', '')
                    )
                    versions_to_delete = []
                    if 'Versions' in response:
                        versions_to_delete.extend([{'Key': v['Key'], 'VersionId': v['VersionId']} for v in response['Versions']])
                    if 'DeleteMarkers' in response:
                        versions_to_delete.extend([{'Key': dm['Key'], 'VersionId': dm['VersionId']} for dm in response['DeleteMarkers']])

                    if versions_to_delete:
                        s3.delete_objects(
                            Bucket=bucket_name,
                            Delete={'Objects': versions_to_delete}
                        )
                        print(f"Deleted additional {len(versions_to_delete)} object versions from bucket '{bucket_name}'.")
        except ClientError as e:
            if e.response['Error']['Code'] != 'NoSuchBucket':
                print(f"Error deleting object versions from bucket: {e}")

        # Finally, delete the bucket
        try:
            s3.delete_bucket(Bucket=bucket_name)
            print(f"S3 bucket '{bucket_name}' deleted successfully.")
            return True
        except s3.exceptions.NoSuchBucket:
            print(f"S3 bucket '{bucket_name}' does not exist (already deleted).")
            return True
        except ClientError as e:
            error_code = e.response['Error']['Code']
            if error_code == 'BucketNotEmpty':
                print(f"Error: S3 bucket '{bucket_name}' is not empty. Please ensure all objects are deleted before deleting the bucket.")
                return False
            else:
                print(f"Error deleting S3 bucket: {e}")
                return False
    except Exception as e:
        print(f"Unexpected error deleting S3 bucket: {e}")
        return False

if __name__ == "__main__":
    destroy_bucket()