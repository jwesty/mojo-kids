#!/bin/bash

# deploy_frontend.sh
echo "🚀 Deploying frontend to S3..."

# Get the API Gateway URL from Terraform output
API_URL=$(terraform output -raw api_endpoint)
BUCKET_NAME="mojo-kids-content-dev"  # Construct bucket name directly

# Create config.js with the API URL
echo "📝 Creating config.js..."
cat > static/config.js << EOF
const config = {
    apiBaseUrl: '${API_URL}'
};
EOF

# Upload all static files to S3
echo "📦 Uploading files to S3..."

# Upload HTML files
aws s3 cp templates/index.html "s3://${BUCKET_NAME}/index.html" \
    --content-type "text/html" \
    --cache-control "no-cache"

aws s3 cp templates/login.html "s3://${BUCKET_NAME}/login.html" \
    --content-type "text/html" \
    --cache-control "no-cache"

aws s3 cp templates/register.html "s3://${BUCKET_NAME}/register.html" \
    --content-type "text/html" \
    --cache-control "no-cache"

aws s3 cp templates/dashboard.html "s3://${BUCKET_NAME}/dashboard.html" \
    --content-type "text/html" \
    --cache-control "no-cache"

# Upload static assets
aws s3 cp static/ "s3://${BUCKET_NAME}/static/" \
    --recursive \
    --cache-control "max-age=31536000"

echo "✅ Frontend deployed successfully!"
echo "🌎 Website URL: $(terraform output -raw website_url)"