import boto3
from botocore.exceptions import ClientError

iam = boto3.client('iam', region_name='us-east-2')
role_name = 'lambda-role-FaceProcessor'
policy_name = 'lambda-policy-FaceProcessor'

def destroy_lambda_role():
    try:
        # First, detach all managed policies
        try:
            response = iam.list_attached_role_policies(RoleName=role_name)
            for policy in response['AttachedPolicies']:
                iam.detach_role_policy(
                    RoleName=role_name,
                    PolicyArn=policy['PolicyArn']
                )
                print(f"Detached managed policy: {policy['PolicyArn']}")
        except ClientError as e:
            if e.response['Error']['Code'] != 'NoSuchEntity':
                print(f"Error detaching managed policies: {e}")

        # Delete inline policies
        try:
            response = iam.list_role_policies(RoleName=role_name)
            for policy_name in response['PolicyNames']:
                iam.delete_role_policy(
                    RoleName=role_name,
                    PolicyName=policy_name
                )
                print(f"Deleted inline policy: {policy_name}")
        except ClientError as e:
            if e.response['Error']['Code'] != 'NoSuchEntity':
                print(f"Error deleting inline policies: {e}")

        # Delete the IAM role
        try:
            iam.delete_role(RoleName=role_name)
            print(f"IAM role '{role_name}' deleted successfully.")
            return True
        except iam.exceptions.NoSuchEntityException:
            print(f"IAM role '{role_name}' does not exist (already deleted).")
            return True
        except ClientError as e:
            print(f"Error deleting IAM role: {e}")
            return False
    except Exception as e:
        print(f"Unexpected error deleting IAM role: {e}")
        return False

if __name__ == "__main__":
    destroy_lambda_role()