import json
import os
import uuid
import boto3

def _client(service: str):
    host = os.getenv("LOCALSTACK_HOSTNAME") or os.getenv("LOCALSTACK_HOST") or "localhost"
    return boto3.client(service, endpoint_url=f"http://{host}:4566")

def lambda_handler(event, context):
    body = event.get("body") if isinstance(event, dict) else None
    if not body:
        body = json.dumps({"message": "empty payload"})
    s3 = _client("s3")
    raw_bucket = os.environ["RAW_BUCKET"]
    key = f"ingest/{uuid.uuid4()}.json"
    s3.put_object(Bucket=raw_bucket, Key=key, Body=body.encode("utf-8"))
    return {"statusCode": 200, "body": json.dumps({"stored": key, "bucket": raw_bucket})}
