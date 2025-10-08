#!/usr/bin/env bash
# Re-exec with bash if script was invoked with sh to avoid subtle POSIX differences
if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi

set -euo pipefail
IFS=$'\n\t'

# create-remote.sh
# Creates an S3 bucket with Object Lock enabled and turns on versioning.
# Note: Terraform state locking (concurrency protection) for the S3 backend requires DynamoDB.

# Configuration (edit as needed)
BUCKET_NAME="personal-project-s3"
AWS_REGION="eu-west-2"
AWS_PROFILE="personal-project"

echo "🚀 Creating Terraform state bucket: $BUCKET_NAME in region: $AWS_REGION (profile: $AWS_PROFILE)"

# Check if bucket exists
if aws --profile "$AWS_PROFILE" --region "$AWS_REGION" s3api head-bucket --bucket "$BUCKET_NAME" >/dev/null 2>&1; then
  echo "✅ Bucket $BUCKET_NAME already exists, skipping creation"
else
  echo "🚀 Creating bucket $BUCKET_NAME with Object Lock enabled..."

  if [ "$AWS_REGION" = "us-east-1" ]; then
    # us-east-1 doesn't accept a LocationConstraint
    if aws --profile "$AWS_PROFILE" --region "$AWS_REGION" s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --object-lock-enabled-for-bucket >/dev/null 2>&1; then
      echo "✅ Bucket created (us-east-1) with Object Lock enabled"
    else
      echo "⚠️ create-bucket returned non-zero (it may already exist or you lack permissions). Continuing..."
    fi
  else
    # Use JSON for the create-bucket-configuration to avoid shell/CLI parsing issues
    # Place --region and --profile as global options to ensure aws CLI builds the correct endpoint
    if aws --profile "$AWS_PROFILE" --region "$AWS_REGION" s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --create-bucket-configuration LocationConstraint=$AWS_REGION \
        --object-lock-enabled-for-bucket >/dev/null 2>&1; then
      echo "✅ Bucket created with Object Lock enabled"
    else
      echo "⚠️ create-bucket returned non-zero (it may already exist or you lack permissions). Continuing..."
    fi
  fi

  # Wait for bucket to exist and be reachable
  echo "⏳ Waiting for bucket to be available..."
  aws --profile "$AWS_PROFILE" --region "$AWS_REGION" s3api wait bucket-exists --bucket "$BUCKET_NAME"
  echo "✅ Bucket is available"
fi

# Enable versioning
echo "🚀 Enabling versioning on bucket $BUCKET_NAME..."
aws --profile "$AWS_PROFILE" --region "$AWS_REGION" s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled

echo "✅ Versioning enabled"
echo "🎉 S3 bucket is ready with versioning and object lock enabled"
echo "⚠️ Reminder: Terraform state locking requires a DynamoDB table; S3 Object Lock is not a substitute for Terraform locking."
