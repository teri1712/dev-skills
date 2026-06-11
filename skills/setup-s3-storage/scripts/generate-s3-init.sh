#!/bin/bash

# Usage: ./generate-s3-init.sh <bucket-name>

BUCKET_NAME=${1:-decade-bucket}

cat <<EOF
#!/bin/bash
set -e

echo "Creating public S3 bucket: $BUCKET_NAME..."

awslocal s3 mb s3://$BUCKET_NAME

awslocal s3api put-bucket-policy \\
  --bucket $BUCKET_NAME \\
  --policy '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": "*",
        "Action": "s3:GetObject",
        "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
      }
    ]
  }'

awslocal s3api put-bucket-cors \\
  --bucket $BUCKET_NAME \\
  --cors-configuration '{
    "CORSRules": [
      {
        "AllowedOrigins": ["*"],
        "AllowedMethods": ["GET","PUT","POST","DELETE","HEAD"],
        "AllowedHeaders": ["*"],
        "ExposeHeaders": ["ETag"]
      }
    ]
  }'

echo "S3 bucket $BUCKET_NAME initialized"
EOF
