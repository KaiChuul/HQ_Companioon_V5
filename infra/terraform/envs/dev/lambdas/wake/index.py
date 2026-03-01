import boto3
import json
import os

ec2 = boto3.client("ec2")
ID = os.environ["INSTANCE_ID"]


def handler(event, context):
    method = event.get("requestContext", {}).get("http", {}).get("method", "GET")
    headers = {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
    }

    if method == "GET":
        r = ec2.describe_instances(InstanceIds=[ID])
        state = r["Reservations"][0]["Instances"][0]["State"]["Name"]
        return {
            "statusCode": 200,
            "headers": headers,
            "body": json.dumps({"status": state}),
        }

    if method == "POST":
        try:
            ec2.start_instances(InstanceIds=[ID])
        except Exception:
            pass  # already running/starting is fine
        return {
            "statusCode": 200,
            "headers": headers,
            "body": json.dumps({"started": True}),
        }

    return {"statusCode": 405, "body": "Method not allowed"}
