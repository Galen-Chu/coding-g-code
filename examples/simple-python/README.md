# Simple Python Example

A simple Flask API demonstrating the CI/CD Toolkit.

## Features

- Flask REST API
- pytest for testing
- flake8 for linting
- Coverage reporting
- Health check endpoint

## Quick Start

```bash
# Install dependencies
pip install -r requirements.txt

# Run tests
pytest

# Run tests with coverage
pytest --cov=app

# Start server
python app/__init__.py

# Lint code
flake8 .

# Format code
black .
```

## API Endpoints

- `GET /health` - Health check
- `GET /api/info` - API information
- `GET /api/hello?name=World` - Greeting endpoint

## Testing with CI/CD Toolkit

```bash
# From the project root
bash scripts/ci/lint.sh
bash scripts/ci/test.sh
bash scripts/cd/build.sh
bash scripts/cd/deploy.sh dev
```

## Configuration

Edit `pytest.ini` for test configuration.
Edit `.flake8` for linting rules.
