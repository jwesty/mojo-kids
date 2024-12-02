#!/bin/bash

echo "🔍 Verifying Lambda package contents..."

# Extract the ZIP file to a temporary directory
TEMP_DIR="lambda_verify"
rm -rf $TEMP_DIR
mkdir $TEMP_DIR
unzip lambda.zip -d $TEMP_DIR

echo "📁 Static directory contents:"
ls -la $TEMP_DIR/static/

echo "📄 Checking specific files:"
for file in styles.css app.js; do
    if [ -f "$TEMP_DIR/static/$file" ]; then
        echo "✅ $file exists"
        echo "Content type: $(file -b --mime-type $TEMP_DIR/static/$file)"
        echo "File size: $(stat -f%z $TEMP_DIR/static/$file) bytes"
    else
        echo "❌ $file is missing"
    fi
done

# Clean up
rm -rf $TEMP_DIR

echo "🌐 Testing API endpoint..."
API_URL=$(terraform output -raw api_endpoint)

echo "Testing CSS file..."
curl -I "${API_URL}/static/styles.css"

echo "Testing JS file..."
curl -I "${API_URL}/static/app.js"
