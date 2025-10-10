#!/bin/bash
set -e

# Variables
BUCKET_NAME="auto-discovery-s3-bucket"
AWS_REGION="eu-west-3"
AWS_PROFILE="personal-project"

echo "🚀 Creating Terraform state bucket: $BUCKET_NAME in region: $AWS_REGION (profile: $AWS_PROFILE)"

# =========================
# Create S3 bucket
# =========================
aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --region "$AWS_REGION" \
  --profile "$AWS_PROFILE" \
  --create-bucket-configuration LocationConstraint="$AWS_REGION"

# =========================
# Enable versioning
# =========================
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --region "$AWS_REGION" \
  --profile "$AWS_PROFILE" \
  --versioning-configuration Status=Enabled

echo "✅ Versioning enabled"

# =========================
# Run Terraform workflow
# =========================
cd jenkins-vault 

terraform init 

terraform fmt --recursive
terraform apply -auto-approve

echo "🎉 Terraform state bucket configured and Terraform applied successfully!"
