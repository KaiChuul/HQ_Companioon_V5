import boto3
import os

ec2 = boto3.client("ec2")
ID = os.environ["INSTANCE_ID"]


def handler(event, context):
    try:
        ec2.stop_instances(InstanceIds=[ID], Hibernate=True)
    except Exception as e:
        print(f"Hibernate-stop failed: {e}")
