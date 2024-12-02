#!/bin/bash

# verify_deployment.sh
echo "🔍 Verifying deployment..."

# Get bucket names and website URL
WEBSITE_BUCKET=$(terraform output -raw website_bucket_name)
CONTENT_BUCKET=$(terraform output -raw content_bucket_name)
WEBSITE_URL=$(terraform output -raw website_url)

echo "Website Bucket: $WEBSITE_BUCKET"
echo "Content Bucket: $CONTENT_BUCKET"
echo "Website URL: $WEBSITE_URL"

echo "📂 Files in website bucket:"
aws s3 ls "s3://${WEBSITE_BUCKET}" --recursive

echo "🌐 Testing file accessibility:"
FILES_TO_TEST=(
    "index.html"
    "static/styles.css"
    "static/app.js"
    "static/config.js"
)

for file in "${FILES_TO_TEST[@]}"; do
    echo "Testing: ${WEBSITE_URL}/${file}"
    curl -I "${WEBSITE_URL}/${file}"
    echo "---"
done

# Test actual content
echo "📄 Fetching index.html content:"
curl -L "${WEBSITE_URL}/index.html" | head -n 10