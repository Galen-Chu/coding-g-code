"""
Simple Flask API Application
Example project for CI/CD Toolkit
"""

from flask import Flask, jsonify, request
import os
from datetime import datetime

app = Flask(__name__)
PORT = int(os.environ.get('PORT', 3000))


@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'OK',
        'timestamp': datetime.utcnow().isoformat(),
        'status_code': 200
    }), 200


@app.route('/api/info', methods=['GET'])
def info():
    """API information endpoint"""
    return jsonify({
        'name': 'Simple Python Example',
        'version': '1.0.0',
        'description': 'Example project for CI/CD Toolkit',
        'language': 'Python'
    }), 200


@app.route('/api/hello', methods=['GET'])
def hello():
    """Hello endpoint"""
    name = request.args.get('name', 'World')
    return jsonify({
        'message': f'Hello, {name}!'
    }), 200


@app.errorhandler(404)
def not_found(error):
    """404 error handler"""
    return jsonify({
        'error': 'Not Found',
        'path': request.path
    }), 404


@app.errorhandler(500)
def internal_error(error):
    """500 error handler"""
    return jsonify({
        'error': 'Internal Server Error',
        'message': str(error) if os.environ.get('DEBUG') else 'An error occurred'
    }), 500


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=PORT, debug=True)
