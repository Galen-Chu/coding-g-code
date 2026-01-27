# Simple Node.js Example

A simple Express API demonstrating the CI/CD Toolkit.

## Features

- Express server with REST endpoints
- Jest testing framework
- ESLint for code quality
- Health check endpoint

## Quick Start

```bash
# Install dependencies
npm install

# Run tests
npm test

# Start server
npm start

# Development mode
npm run dev

# Lint code
npm run lint

# Fix linting issues
npm run lint:fix
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
