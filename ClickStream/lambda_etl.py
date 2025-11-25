import datetime as dt
import json
import os
import boto3

def _client(service: str):
    host = os.getenv("LOCALSTACK_HOSTNAME") or os.getenv("LOCALSTACK_HOST") or "localhost"
    return boto3.client(service, endpoint_url=f"http://{host}:4566")

def lambda_handler(event, context):
    s3 = _client("s3")
    raw_bucket = os.environ["RAW_BUCKET"]
    processed_bucket = os.environ["PROCESSED_BUCKET"]
    resp = s3.list_objects_v2(Bucket=raw_bucket, Prefix="ingest/")
    objects = resp.get("Contents", [])
    summary = [{"key": o["Key"], "size": o.get("Size", 0)} for o in objects]
    key = f"processed/{dt.datetime.utcnow().isoformat()}Z.json"
    s3.put_object(Bucket=processed_bucket, Key=key, Body=json.dumps({"count": len(summary), "objects": summary}))
    return {"statusCode": 200, "body": json.dumps({"processed": len(summary), "output": key})}
