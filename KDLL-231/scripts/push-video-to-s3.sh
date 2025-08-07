#!/bin/bash
# set -euo pipefail
# set -x 

# Test command
# scripts/slides-upload-to-s3.sh edu-revealjs-kdll-231 KDLL-231-slides KDLL-231

# cd $REVEALJS_DIR 
# source scripts/variables
source ~/.aws-creds

export BUCKET_NAME=$1
export SLIDES_DIR=$2
export COURSE_CODE=$3
export BUCKET_PREFIX="edu-camtasia-"
export REGION="eu-west-1"
export NOW=$(date "+%Y%m%d")

SOURCE_VIDEO_NAME=$(basename $(ls -1 ../video/*mp4)| tr '[:upper:]' '[:lower:]') # Assumes only 1 - need a better way

BUCKET_NAME="$BUCKET_PREFIX""$SOURCE_VIDEO_NAME"

# Check if AWS_ACCESS_KEY_ID is set and not empty, and exit gracefully if not
if [[ -n "$AWS_ACCESS_KEY_ID" ]]; then
  if aws s3 ls > /dev/null 2>&1; then
    echo "AWS credentials validated."
  else
    echo "AWS credentials are set, but invalid."
    exit 0
  fi
  else
  echo "AWS credentials are not set."
  exit 0
fi

echo uploading to S3 bucket "$BUCKET_NAME" in "$REGION"

# Create the S3 bucket
aws s3api create-bucket --bucket $BUCKET_NAME --region $REGION --create-bucket-configuration LocationConstraint=$REGION > /dev/null 2>&1
sleep 2

envsubst < scripts/artifacts/bucket-policy-template.json > bucket-policy.json

# Enable static website hosting
aws s3 website "s3://$BUCKET_NAME" --index-document index.html --error-document error.html

# Enable public access & bucket policy settings
aws s3api put-public-access-block --bucket "$BUCKET_NAME" --public-access-block-configuration file://scripts/artifacts/public-access.json 
aws s3api put-bucket-policy --bucket "$BUCKET_NAME" --policy file://bucket-policy.json
rm bucket-policy.json

# Copy slides to repo
aws s3 cp $OUTPUT_DIR/$SLIDES_DIR s3://$BUCKET_NAME --recursive

printf "\n${GREEN}The slide's static content are now available at: 

http://$BUCKET_NAME.s3-website-$REGION.amazonaws.com ${NC}\n\n"

printf "To remove this bucket use\n"

printf "${GREEN}
aws s3 rb s3://$BUCKET_NAME --force
${NC}\n\n"

touch ../video/video-bucket-details.yaml
yq -i '.vid-name."$SOURCE_VIDEO_NAME'
yq -i '.vid-bucket."$BUCKET_NAME'
yq -i '.vid-date."$NOW'

# exit 0

############################################
# Create CloudFront distribution for HTTPS #
############################################

S3_WEBSITE_ENDPOINT="$BUCKET_NAME.s3-website-$REGION.amazonaws.com"
DEFAULT_ROOT_OBJECT="index.html"


CLOUDF=$(aws cloudfront list-distributions)

# === Create CloudFront distribution if it doesnt already exit ===

c=$(echo $COURSE_CODE | tr '[:upper:]' '[:lower:]' )

EXISTS=$(echo "$CLOUDF" | jq -r --arg c "$c" '
    .DistributionList.Items[]
    | select(any(.Origins.Items[]; .DomainName | contains($c)))
    | .DomainName')

# if [[ "$EXISTS" = *None* ]]; then
if [[ -z "$EXISTS" ]]; then
  echo "No existing CloudFront distribution found for $S3_WEBSITE_ENDPOINT. Creating one..."
  AWS_PAGER="" aws cloudfront create-distribution \
    --origin-domain-name "$S3_WEBSITE_ENDPOINT" \
    --default-root-object "$DEFAULT_ROOT_OBJECT" \
    --query 'Distribution.{ID:Id, DomainName:DomainName, Status:Status}' \
    --output json

  CF_ARN=$(echo $CLOUDF  | jq -r '.DistributionList.Items[] | select(.Origins.Items[].DomainName | startswith("edu-revealjs-")) | .ARN')
else
  echo "A distribution already exists for $S3_WEBSITE_ENDPOINT with these IDs: 
  $EXISTS"
fi

echo 
CLOUDF=$(aws cloudfront list-distributions)
# echo $CLOUDF | jq -r '.DistributionList.Items[] 
#   | select(any(.Origins.Items[]; .DomainName | startswith("edu-revealjs-"))) 
#   | [.DomainName, (.Origins.Items[] | .DomainName), .LastModifiedTime] 
#   | @tsv'


# ###############
# # Add Tagging #
# ###############

for arn in $(echo "$CLOUDF" | jq -r '.DistributionList.Items[].ARN'); do
 aws cloudfront tag-resource \
  --resource "$arn" \
  --tags file://$TAG_FILE
done
