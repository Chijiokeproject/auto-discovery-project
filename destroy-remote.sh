#!/usr/bin/env bash

# Simple destroy script: try the fast path first, with clear guidance if it fails.
set -euo pipefail

BUCKET_NAME="personal-project-s3"
AWS_REGION="eu-west-2"
AWS_PROFILE="personal-project"

echo "⚠️ Deleting Terraform remote state bucket: $BUCKET_NAME in region: $AWS_REGION (profile: $AWS_PROFILE)"

# If invoked with sh, re-exec under bash for better behavior
if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi

echo "🚀 Attempting fast empty (non-versioned) delete..."
# Fast attempt: delete all current objects (won't remove versions)
if aws --profile "$AWS_PROFILE" --region "$AWS_REGION" s3 rm "s3://$BUCKET_NAME" --recursive; then
  echo "✅ Objects deleted (non-versioned)."
else
  echo "⚠️ Fast delete failed. The bucket may be versioned or unreachable."
fi

echo "🚀 Attempting to remove bucket (force)..."
if aws --profile "$AWS_PROFILE" --region "$AWS_REGION" s3 rb "s3://$BUCKET_NAME" --force; then
  echo "✅ Bucket removed"
  exit 0
fi

cat <<EOF
❗ Could not remove bucket automatically. Common reasons:
  - The bucket is versioned (has object versions/delete markers).
  - Bucket is in a different region/profile.
  - Network/permission issues.

Next steps (simplest):
  1) If the bucket is versioned, ask me and I'll create a detailed remover that deletes all versions.
  2) Or inspect contents manually:
       aws --profile $AWS_PROFILE --region $AWS_REGION s3api list-object-versions --bucket $BUCKET_NAME

If you'd like, I can provide a safe detailed remover that deletes all versions and markers (it requires more permissions).
EOF

exit 1
    if [ -z "${BASH_VERSION:-}" ]; then
