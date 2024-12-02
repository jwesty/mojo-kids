#!/bin/bash
set -e  # Exit on error

# sync_frontend.sh
echo "🚀 Preparing frontend files for deployment..."

# Create temporary directory for organizing files
TEMP_DIR="website_files"
rm -rf $TEMP_DIR
mkdir -p $TEMP_DIR/static

# Get values from terraform output
API_URL=$(terraform output -raw api_endpoint)
BUCKET_NAME=$(terraform output -raw website_bucket_name)
WEBSITE_URL=$(terraform output -raw website_url)

if [ -z "$BUCKET_NAME" ]; then
    echo "❌ Error: Could not get bucket name from terraform output"
    exit 1
fi

echo "📦 Using bucket: ${BUCKET_NAME}"

# Create static files (CSS and JS same as before)
# ... (keep your existing CSS and JS file content)

# Update HTML files with correct paths
cat > $TEMP_DIR/index.html << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mojo Kids - Fun Learning Platform</title>
    <link rel="stylesheet" href="static/styles.css">
</head>
<body>
    <nav class="navbar">
        <div class="container">
            <a href="index.html" class="navbar-brand">Mojo Kids</a>
            <div class="nav-links">
                <a href="login.html" class="btn btn-secondary">Login</a>
                <a href="register.html" class="btn btn-primary">Register</a>
            </div>
        </div>
    </nav>

    <main class="container">
        <section class="hero">
            <h1>Welcome to Mojo Kids!</h1>
            <p>A fun and safe place to learn and play</p>
        </section>
    </main>

    <script src="static/config.js"></script>
    <script src="static/app.js"></script>
    <script>
        const app = new MojoApp();
    </script>
</body>
</html>
EOF

# Similar updates for login.html, register.html, and dashboard.html
# (Update the paths in the same way: remove leading slash, use relative paths)

# Upload all files to S3
echo "📦 Uploading files to S3..."

# Clean the bucket first (optional)
echo "🧹 Cleaning existing files..."
aws s3 rm "s3://${BUCKET_NAME}" --recursive

# Upload HTML files
aws s3 cp $TEMP_DIR/ "s3://${BUCKET_NAME}/" \
    --recursive \
    --exclude "*" \
    --include "*.html" \
    --content-type "text/html" \
    --cache-control "no-cache"

# Upload CSS files
aws s3 cp $TEMP_DIR/static/ "s3://${BUCKET_NAME}/static/" \
    --recursive \
    --exclude "*" \
    --include "*.css" \
    --content-type "text/css" \
    --cache-control "max-age=31536000"

# Upload JavaScript files
aws s3 cp $TEMP_DIR/static/ "s3://${BUCKET_NAME}/static/" \
    --recursive \
    --exclude "*" \
    --include "*.js" \
    --content-type "application/javascript" \
    --cache-control "max-age=31536000"

# Verify deployment
echo "🔍 Verifying deployment..."
aws s3 ls "s3://${BUCKET_NAME}" --recursive

echo "✅ Frontend deployed successfully!"
echo "🌎 Website URL: $WEBSITE_URL"

# Test file accessibility
echo "🔍 Testing file accessibility..."
for file in index.html static/styles.css static/app.js static/config.js; do
    url="${WEBSITE_URL}/${file}"
    echo "Testing: $url"
    curl -I "$url"
done