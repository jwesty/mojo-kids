from flask import Flask, request, jsonify, send_from_directory
import boto3
import hashlib
import uuid
from datetime import datetime, timedelta
import awsgi
import os
import logging
import json
import jwt
from functools import wraps

# Set up logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__, static_folder='static')

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
users_table = dynamodb.Table('mojo-kids-users-dev')

JWT_SECRET = 'your-secret-key'  # Change this to a secure secret key


def admin_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        if 'Authorization' in request.headers:
            token = request.headers['Authorization'].split(' ')[1]

        if not token:
            return jsonify({'message': 'Token is missing'}), 401

        try:
            data = jwt.decode(token, JWT_SECRET, algorithms=['HS256'])
            current_user = users_table.get_item(Key={'email': data['email']})

            if 'Item' not in current_user or not current_user['Item'].get('isAdmin', False):
                return jsonify({'message': 'Admin privileges required'}), 403

        except:
            return jsonify({'message': 'Invalid token'}), 401

        return f(*args, **kwargs)

    return decorated


def hash_password(password):
    """Hash password using SHA-256."""
    return hashlib.sha256(password.encode()).hexdigest()


# Serve index.html for root and any unmatched routes (for SPA support)
@app.route('/')
@app.route('/<path:path>')
def serve_root(path=None):
    if path and os.path.exists(os.path.join('static', path)):
        return send_from_directory('static', path)
    return send_from_directory('static', 'index.html')


@app.route('/admin')
def admin_page():
    return send_from_directory('static', 'admin.html')


@app.route('/admin.css')
def admin_styles():
    return send_from_directory('static', 'admin.css')


@app.route('/login')
def login_page():
    return send_from_directory('static', 'login.html')


@app.route('/register')
def register_page():
    return send_from_directory('static', 'register.html')


@app.route('/learning')
def learning_page():
    return send_from_directory('static', 'learning.html')


@app.route('/safety')
def safety_page():
    return send_from_directory('static', 'safety.html')


@app.route('/styles.css')
def styles():
    return send_from_directory('static', 'styles.css')


@app.route('/config.js')
def config_js():
    return send_from_directory('static', 'config.js')


@app.route('/app.js')
def app_js():
    return send_from_directory('static', 'app.js')


@app.route('/api/admin/verify')
@admin_required
def verify_admin():
    token = request.headers['Authorization'].split(' ')[1]
    data = jwt.decode(token, JWT_SECRET, algorithms=['HS256'])
    return jsonify({'message': 'Valid admin', 'user': {'email': data['email']}})


@app.route('/api/admin/users')
@admin_required
def get_users():
    try:
        response = users_table.scan()
        users = response.get('Items', [])
        return jsonify({'users': users})
    except Exception as e:
        return jsonify({'message': str(e)}), 500


@app.route('/api/admin/users', methods=['DELETE'])
@admin_required
def delete_user():
    try:
        data = request.get_json()
        email = data['email']

        # Don't allow deleting yourself
        token = request.headers['Authorization'].split(' ')[1]
        admin_data = jwt.decode(token, JWT_SECRET, algorithms=['HS256'])
        if email == admin_data['email']:
            return jsonify({'message': 'Cannot delete yourself'}), 400

        users_table.delete_item(Key={'email': email})
        return jsonify({'message': 'User deleted successfully'})
    except Exception as e:
        return jsonify({'message': str(e)}), 500


@app.route('/api/admin/promote', methods=['POST'])
@admin_required
def promote_to_admin():
    try:
        data = request.get_json()
        email = data['email']

        # Update user to admin
        users_table.update_item(
            Key={'email': email},
            UpdateExpression='SET isAdmin = :val',
            ExpressionAttributeValues={':val': True}
        )
        return jsonify({'message': 'User promoted to admin successfully'})
    except Exception as e:
        return jsonify({'message': str(e)}), 500


import jwt
from datetime import datetime, timedelta
import logging

logger = logging.getLogger(__name__)


@app.route('/api/login', methods=['POST'])
def login():
    try:
        # Log incoming request
        logger.debug("Login attempt received")
        data = request.get_json()
        email = data.get('email')

        if not email:
            logger.error("No email provided")
            return jsonify({'message': 'Email is required'}), 400

        logger.debug(f"Looking up user: {email}")

        # Query DynamoDB
        response = users_table.get_item(
            Key={'email': email}
        )

        if 'Item' not in response:
            logger.debug("User not found")
            return jsonify({'message': 'Invalid credentials'}), 401

        user = response['Item']
        input_password = hash_password(data.get('password', ''))

        if user['password'] != input_password:
            logger.debug("Password mismatch")
            return jsonify({'message': 'Invalid credentials'}), 401

        # Create JWT token with proper string formatting
        payload = {
            'email': str(user['email']),  # Ensure string
            'isAdmin': bool(user.get('isAdmin', False)),  # Ensure boolean
            'exp': int((datetime.utcnow() + timedelta(days=1)).timestamp())  # Use integer timestamp
        }

        # Make sure JWT_SECRET is properly set and is a string
        jwt_secret = str(app.config.get('JWT_SECRET', 'your-secret-key'))

        # Generate token with explicit encoding
        try:
            token = jwt.encode(
                payload,
                jwt_secret,
                algorithm='HS256'
            )
            logger.debug("JWT token generated successfully")
        except Exception as jwt_error:
            logger.error(f"JWT generation failed: {str(jwt_error)}")
            raise

        # Return success response
        return jsonify({
            'message': 'Login successful',
            'token': token,
            'user': {
                'email': user['email'],
                'isAdmin': user.get('isAdmin', False)
            }
        })

    except Exception as e:
        logger.error(f"Login error: {str(e)}")
        return jsonify({'message': 'Login failed', 'error': str(e)}), 500


@app.route('/api/verify', methods=['GET'])
def verify_token():
    token = request.headers.get('Authorization', '').replace('Bearer ', '')

    try:
        decoded = jwt.decode(token, app.config['JWT_SECRET'], algorithms=['HS256'])
        return jsonify({'valid': True}), 200
    except:
        return jsonify({'valid': False}), 401


@app.route('/api/register', methods=['POST'])
def register():
    try:
        data = request.get_json()
        email = data['email']
        password = hash_password(data['password'])

        # Check if user exists
        try:
            response = users_table.get_item(
                Key={'email': email}
            )

            if 'Item' in response:
                return jsonify({'message': 'User already exists'}), 409

            # Create new user
            user = {
                'email': email,
                'password': password,
                'created_at': datetime.now().isoformat(),
                'isAdmin': False  # Default to non-admin
            }

            # Add to DynamoDB
            users_table.put_item(Item=user)

            # Return success without sensitive data
            return jsonify({
                'message': 'Registration successful',
                'user': {
                    'email': email,
                    'created_at': user['created_at']
                }
            }), 201

        except Exception as e:
            print(f"DynamoDB error: {str(e)}")  # Add logging
            return jsonify({'message': 'Database error'}), 500

    except Exception as e:
        print(f"Registration error: {str(e)}")  # Add logging
        return jsonify({'message': 'Registration failed'}), 500


def lambda_handler(event, context):
    """Convert Lambda v2 event to v1 format for awsgi."""
    logger.debug(f"Received event: {json.dumps(event)}")  # Log incoming event

    if 'requestContext' in event and 'http' in event['requestContext']:
        # Convert v2 format to v1
        v1_event = {
            'httpMethod': event['requestContext']['http']['method'],
            'path': event['rawPath'],
            'headers': event['headers'],
            'queryStringParameters': event.get('queryStringParameters', {}),
            'body': event.get('body', ''),
            'isBase64Encoded': event.get('isBase64Encoded', False)
        }

        # Add these for proper AWSGI handling
        if 'cookies' in event:
            v1_event['headers']['Cookie'] = '; '.join(event['cookies'])

        logger.debug(f"Converted to v1 event: {json.dumps(v1_event)}")  # Log converted event
        return awsgi.response(app, v1_event, context)

    # If it's already v1 format, use as is
    return awsgi.response(app, event, context)