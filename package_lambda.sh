#!/bin/bash
set -e

# Create package directory
PACKAGE_DIR="lambda_package"
rm -rf $PACKAGE_DIR
mkdir -p $PACKAGE_DIR/static

echo "🚀 Creating Lambda package..."

# Copy application code
cp lambda/app.py $PACKAGE_DIR/

# Copy static files
echo "📦 Copying static files..."
cp -r static/* $PACKAGE_DIR/static/

# Create requirements.txt
echo "📝 Creating requirements.txt..."
cat > $PACKAGE_DIR/requirements.txt << EOF
Flask==3.0.0
Werkzeug==3.0.1
boto3==1.34.34
botocore==1.34.34
aws-wsgi==0.2.7
blinker==1.7.0
click==8.1.7
itsdangerous==2.1.2
Jinja2==3.1.3
MarkupSafe==2.1.5
PyJWT==2.8.0
EOF

# Install dependencies
echo "📦 Installing dependencies..."
pip install -r $PACKAGE_DIR/requirements.txt --target $PACKAGE_DIR

# Clean up unnecessary files
echo "🧹 Cleaning up..."
find $PACKAGE_DIR -type d -name "__pycache__" -exec rm -rf {} +
find $PACKAGE_DIR -type f -name "*.pyc" -delete
find $PACKAGE_DIR -type d -name "*.dist-info" -exec rm -rf {} +
find $PACKAGE_DIR -type d -name "*.egg-info" -exec rm -rf {} +

# Debug information
echo "📂 Package contents:"
ls -R $PACKAGE_DIR/static/

# Create ZIP file
echo "🗜️ Creating ZIP file..."
cd $PACKAGE_DIR
zip -r ../lambda.zip .

echo "✅ Lambda package created successfully!"
ls -lh ../lambda.zip

# Verify static files in the ZIP
echo "🔍 Verifying static files in ZIP..."
unzip -l ../lambda.zip | grep static/