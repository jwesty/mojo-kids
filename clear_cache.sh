#!/bin/bash

# clear_cache.sh
echo "🧹 Clearing API Gateway cache..."

# Get the API ID and stage name from terraform output
API_ID=$(terraform output -raw api_id)
STAGE_NAME="$default"

# Flush the cache
aws apigatewayv2 update-stage \
    --api-id $API_ID \
    --stage-name $STAGE_NAME \
    --description "Cache cleared at $(date)"

echo "✅ Cache cleared successfully!"

# Test the endpoints
API_URL=$(terraform output -raw api_endpoint)

echo "🔍 Testing static files..."
echo "Testing app.js..."
curl -X GET "${API_URL}/static/app.js" -H "Cache-Control: no-cache" -i
echo "Testing styles.css..."
curl -X GET "${API_URL}/static/styles.css" -H "Cache-Control: no-cache" -i
