"""
Tests for Flask API
"""

import pytest
from app import app


@pytest.fixture
def client():
    """Create a test client"""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


def test_health_endpoint(client):
    """Test health check endpoint"""
    response = client.get('/health')
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'OK'
    assert 'timestamp' in data
    assert data['status_code'] == 200


def test_info_endpoint(client):
    """Test API info endpoint"""
    response = client.get('/api/info')
    assert response.status_code == 200
    data = response.get_json()
    assert data['name'] == 'Simple Python Example'
    assert data['version'] == '1.0.0'
    assert 'description' in data


def test_hello_endpoint_default(client):
    """Test hello endpoint with default name"""
    response = client.get('/api/hello')
    assert response.status_code == 200
    data = response.get_json()
    assert data['message'] == 'Hello, World!'


def test_hello_endpoint_custom(client):
    """Test hello endpoint with custom name"""
    response = client.get('/api/hello?name=CI/CD')
    assert response.status_code == 200
    data = response.get_json()
    assert data['message'] == 'Hello, CI/CD!'


def test_404_handler(client):
    """Test 404 error handler"""
    response = client.get('/unknown')
    assert response.status_code == 404
    data = response.get_json()
    assert 'error' in data
    assert data['error'] == 'Not Found'
