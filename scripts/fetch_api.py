import os
import sys
import json
import datetime
import requests
import boto3
import pytz

def main():
    print("Fetching Cricket API...")
    
    # Validate environment variables
    api_key = os.environ.get("CRICKET_API_KEY")
    if not api_key:
        print("Error: CRICKET_API_KEY environment variable is not set.", file=sys.stderr)
        sys.exit(1)
        
    aws_access_key = os.environ.get("AWS_ACCESS_KEY_ID")
    aws_secret_key = os.environ.get("AWS_SECRET_ACCESS_KEY")
    aws_region = os.environ.get("AWS_REGION", "us-east-1")
    bucket_name = os.environ.get("S3_BUCKET")
    
    if not all([aws_access_key, aws_secret_key, bucket_name]):
        print("Error: AWS credentials (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY) or S3_BUCKET is not set.", file=sys.stderr)
        sys.exit(1)

    # Fetch live cricket data
    url = f"https://api.cricapi.com/v1/currentMatches?apikey={api_key}&offset=0"
    try:
        response = requests.get(url, timeout=30)
        response.raise_for_status()
        data = response.json()
    except Exception as e:
        print(f"Error fetching CricAPI: {e}", file=sys.stderr)
        sys.exit(1)
        
    # Check CricAPI internal status
    if data.get("status") == "failure" or "error" in data:
        error_msg = data.get("error", "Unknown CricAPI error")
        print(f"CricAPI returned an error: {error_msg}", file=sys.stderr)
        sys.exit(1)

    # Get date in India Timezone (Asia/Kolkata)
    tz = pytz.timezone("Asia/Kolkata")
    india_date = datetime.datetime.now(tz).strftime("%Y-%m-%d")
    s3_key = f"cricket/raw/{india_date}/matches.json"

    print("Uploading to S3...")
    try:
        s3 = boto3.client(
            "s3",
            aws_access_key_id=aws_access_key,
            aws_secret_access_key=aws_secret_key,
            region_name=aws_region
        )
        s3.put_object(
            Bucket=bucket_name,
            Key=s3_key,
            Body=json.dumps(data, indent=2)
        )
        print(f"Raw data successfully uploaded to s3://{bucket_name}/{s3_key}")
    except Exception as e:
        print(f"S3 upload failed: {e}", file=sys.stderr)
        sys.exit(1)

    print("Verifying file uploaded successfully...")
    try:
        s3.head_object(Bucket=bucket_name, Key=s3_key)
        print("Verification success: File exists in S3 bucket.")
    except Exception as e:
        print(f"Verification failed: Uploaded file could not be verified on S3: {e}", file=sys.stderr)
        sys.exit(1)
        
    print("Fetch and upload step completed successfully.")

if __name__ == "__main__":
    main()
