# Scripts Reference

Complete reference for all CI/CD Toolkit scripts.

## Table of Contents

1. [CI Scripts](#ci-scripts)
2. [CD Scripts](#cd-scripts)
3. [Setup Scripts](#setup-scripts)
4. [Utility Scripts](#utility-scripts)
5. [Core Library Scripts](#core-library-scripts)

## CI Scripts

### lint.sh

Auto-detects and runs language-specific linters.

**Usage:**
```bash
bash scripts/ci/lint.sh [options] [files...]
```

**Options:**
- `--fix` - Auto-fix linting issues when possible
- `--dry-run` - Show what would be linted without running
- `--config FILE` - Use custom configuration file
- `--help, -h` - Show help message

**Environment Variables:**
- `LINT_ENABLED` - Enable/disable linting (default: `true`)
- `AUTO_FIX` - Auto-fix issues (default: `false`)
- `PROJECT_TYPE` - Force project type

**Supported Languages:**
| Language | Linters |
|----------|----------|
| Node.js | ESLint |
| Python | flake8, pylint |
| Go | golangci-lint, gofmt |
| Java (Maven) | Maven checkstyle |
| Java (Gradle) | Gradle checkstyle |
| Docker | hadolint |

**Examples:**
```bash
# Lint all files
bash scripts/ci/lint.sh

# Lint specific directory
bash scripts/ci/lint.sh src/

# Auto-fix issues
bash scripts/ci/lint.sh --fix
```

**Exit Codes:**
- `0` - Success
- `1` - General error
- `10` - Linting failed
- `11` - Too many issues

---

### test.sh

Runs tests with configurable runners.

**Usage:**
```bash
bash scripts/ci/test.sh [options] [test_files...]
```

**Options:**
- `--coverage` - Generate coverage report
- `--parallel` - Run tests in parallel
- `--filter PATTERN` - Run tests matching pattern
- `--timeout SECONDS` - Test timeout
- `--dry-run` - Show what would be tested
- `--help, -h` - Show help message

**Environment Variables:**
- `TEST_ENABLED` - Enable/disable testing (default: `true`)
- `PARALLEL_TESTS` - Run in parallel (default: `true`)
- `TEST_TIMEOUT` - Timeout in seconds (default: `300`)
- `COVERAGE_ENABLED` - Generate coverage (default: `true`)

**Supported Test Runners:**
| Language | Runners |
|----------|---------|
| Node.js | Jest, Mocha, Jasmine, Vitest |
| Python | pytest, unittest |
| Go | go test |
| Java (Maven) | mvn test |
| Java (Gradle) | gradle test |

**Examples:**
```bash
# Run all tests
bash scripts/ci/test.sh

# Run with coverage
bash scripts/ci/test.sh --coverage

# Run specific file
bash scripts/ci/test.sh tests/test_api.py

# Run tests matching pattern
bash scripts/ci/test.sh --filter "user"
```

**Output:**
- JUnit XML: `test-results/junit.xml`
- Coverage: `coverage/`

**Exit Codes:**
- `0` - Success
- `1` - General error
- `10` - Tests failed

---

### coverage.sh

Generates code coverage reports.

**Usage:**
```bash
bash scripts/ci/coverage.sh [options]
```

**Options:**
- `--format FORMAT` - Output format (`lcov`, `cobertura`, `html`, `json`)
- `--threshold N` - Minimum coverage percentage (0-100)
- `--output DIR` - Output directory
- `--fail-on-low` - Exit with error if below threshold
- `--dry-run` - Show what would be done
- `--help, -h` - Show help message

**Environment Variables:**
- `COVERAGE_ENABLED` - Enable coverage (default: `true`)
- `COVERAGE_THRESHOLD` - Minimum percentage (default: `80`)
- `COVERAGE_DIR` - Output directory (default: `coverage`)

**Examples:**
```bash
# Generate coverage
bash scripts/ci/coverage.sh

# Generate HTML report
bash scripts/ci/coverage.sh --format html

# Set custom threshold
bash scripts/ci/coverage.sh --threshold 90
```

**Exit Codes:**
- `0` - Success
- `10` - Coverage below threshold

## CD Scripts

### build.sh

Builds project artifacts.

**Usage:**
```bash
bash scripts/cd/build.sh [options]
```

**Options:**
- `--version VER` - Set build version
- `--docker` - Build Docker image
- `--platform PLAT` - Target platform (e.g., `linux/amd64,linux/arm64`)
- `--output DIR` - Output directory
- `--metadata FILE` - Generate metadata file
- `--cache` - Use build cache
- `--dry-run` - Show what would be built
- `--help, -h` - Show help message

**Environment Variables:**
- `BUILD_VERSION` - Version to tag artifacts
- `BUILD_TOOL` - Force specific build tool
- `DOCKER_REGISTRY` - Docker registry
- `DOCKER_ORG` - Docker organization
- `ARTIFACTS_DIR` - Output directory (default: `dist`)

**Examples:**
```bash
# Build with auto-detection
bash scripts/cd/build.sh

# Build with version
bash scripts/cd/build.sh --version 1.0.0

# Build Docker image
bash scripts/cd/build.sh --docker

# Multi-platform build
bash scripts/cd/build.sh --docker --platform linux/amd64,linux/arm64
```

**Output:**
- Artifacts: `dist/`
- Metadata: `dist/build-metadata.json`

**Exit Codes:**
- `0` - Success
- `5` - Build failed

---

### deploy.sh

Deploys to environments.

**Usage:**
```bash
bash scripts/cd/deploy.sh <environment> [options]
```

**Arguments:**
- `environment` - Target environment (`dev`, `staging`, `prod`)

**Options:**
- `--skip-build` - Skip build step
- `--skip-health` - Skip health check
- `--force` - Force deployment even if checks fail
- `--dry-run` - Show what would be deployed
- `--help, -h` - Show help message

**Environment Variables:**
- `DEPLOY_ENVIRONMENT` - Target environment
- `DEPLOY_STRATEGY` - Deployment strategy (`rolling`, `blue-green`, `recreate`)
- `AUTO_ROLLBACK` - Auto-rollback on failure (default: `true`)
- `ENV_URL` - Environment URL for health checks

**Examples:**
```bash
# Deploy to staging
bash scripts/cd/deploy.sh staging

# Deploy to production
bash scripts/cd/deploy.sh prod

# Skip health check
bash scripts/cd/deploy.sh dev --skip-health-check

# Force deployment
bash scripts/cd/deploy.sh prod --force
```

**Exit Codes:**
- `0` - Success
- `6` - Deployment failed

---

### rollback.sh

Rolls back deployments.

**Usage:**
```bash
bash scripts/cd/rollback.sh <environment> [options]
```

**Arguments:**
- `environment` - Target environment

**Options:**
- `--version VER` - Rollback to specific version
- `--list` - List available versions
- `--dry-run` - Show what would be rolled back
- `--help, -h` - Show help message

**Environment Variables:**
- `ROLLBACK_VERSION` - Version to rollback to
- `KEEP_VERSIONS` - Number of versions to keep (default: `5`)

**Examples:**
```bash
# Rollback to previous version
bash scripts/cd/rollback.sh prod

# Rollback to specific version
bash scripts/cd/rollback.sh prod --version 1.0.1

# List available versions
bash scripts/cd/rollback.sh staging --list
```

**Exit Codes:**
- `0` - Success
- `6` - Rollback failed

## Setup Scripts

### install-deps.sh

Installs CI/CD dependencies.

**Usage:**
```bash
bash scripts/setup/install-deps.sh [options]
```

**Options:**
- `--check` - Check if dependencies are installed (don't install)
- `--tools LIST` - Comma-separated list of tools
- `--platform PLAT` - Force platform
- `--help, -h` - Show help message

**Environment Variables:**
- `SKIP_PROMPT` - Skip confirmation prompts
- `INSTALL_DIR` - Installation directory

**Supported Tools:**
| Category | Tools |
|----------|-------|
| General | jq, shellcheck, curl, wget |
| Git | git, gh |
| Node.js | node, npm, yarn, pnpm |
| Python | python3, pip, pytest, flake8 |
| Go | go, golangci-lint |
| Docker | docker, docker-compose |

**Examples:**
```bash
# Check what's installed
bash scripts/setup/install-deps.sh --check

# Install all dependencies
bash scripts/setup/install-deps.sh

# Install specific tools
bash scripts/setup/install-deps.sh --tools node,go,docker

# Non-interactive
SKIP_PROMPT=true bash scripts/setup/install-deps.sh
```

---

### init-project.sh

Initializes project with CI/CD configuration.

**Usage:**
```bash
bash scripts/setup/init-project.sh [options]
```

**Options:**
- `--config FILE` - Use existing config as template
- `--skip-prompts` - Use defaults without prompting
- `--ci-only` - Only set up CI
- `--cd-only` - Only set up CD
- `--help, -h` - Show help message

**Environment Variables:**
- `PROJECT_NAME` - Project name
- `PROJECT_TYPE` - Project type

**Examples:**
```bash
# Interactive initialization
bash scripts/setup/init-project.sh

# Use defaults
bash scripts/setup/init-project.sh --skip-prompts

# CI only
bash scripts/setup/init-project.sh --ci-only
```

**Creates:**
- `.ci-cd.conf` - Configuration file
- `.github/workflows/` - GitHub Actions workflows
- `.gitlab-ci.yml` - GitLab CI configuration
- `.env.*.example` - Environment file templates
- `docs/CI-CD.md` - Documentation

## Utility Scripts

### health-check.sh

Performs health checks on services.

**Usage:**
```bash
bash scripts/utils/health-check.sh <url|host:port> [options]
```

**Options:**
- `--tcp` - Use TCP check instead of HTTP
- `--retry N` - Number of retries (default: `30`)
- `--interval N` - Interval between retries (default: `10`)
- `--timeout N` - Timeout per check (default: `5`)
- `--expected-code N` - Expected HTTP status (default: `200`)
- `--expected-text TEXT` - Expected text in response
- `--headers FILE` - Request headers file
- `--container NAME` - Check Docker container
- `--k8s-pod NAME` - Check Kubernetes pod
- `--config FILE` - Run checks from config file
- `--help, -h` - Show help message

**Environment Variables:**
- `HEALTH_CHECK_TIMEOUT` - Overall timeout (default: `300`)
- `HEALTH_CHECK_INTERVAL` - Default interval (default: `10`)
- `HEALTH_CHECK_RETRIES` - Default retries (default: `30`)

**Examples:**
```bash
# HTTP health check
bash scripts/utils/health-check.sh https://api.example.com/health

# TCP port check
bash scripts/utils/health-check.sh localhost:8080 --tcp

# Custom retry settings
bash scripts/utils/health-check.sh https://api.example.com/health --retry 10 --interval 5

# Check for expected text
bash scripts/utils/health-check.sh https://api.example.com/health --expected-text "OK"

# Check Docker container
bash scripts/utils/health-check.sh --container myapp
```

---

### notifiers.sh

Sends notifications to various platforms.

**Usage:**
```bash
bash scripts/utils/notifiers.sh <platform> "message" [options]
```

**Platforms:**
- `slack` - Slack notification
- `email` - Email notification
- `webhook` - Generic webhook
- `teams` - Microsoft Teams
- `discord` - Discord

**Environment Variables:**
- `SLACK_WEBHOOK` - Slack webhook URL
- `SLACK_CHANNEL` - Slack channel
- `EMAIL_SENDER` - Email sender
- `EMAIL_RECIPIENTS` - Email recipients
- `SMTP_SERVER` - SMTP server
- `WEBHOOK_URL` - Webhook URL

**Examples:**
```bash
# Slack notification
SLACK_WEBHOOK=https://hooks.slack.com/... \
  bash scripts/utils/notifiers.sh slack "Deployment successful"

# Email notification
bash scripts/utils/notifiers.sh email "Build failed"

# Webhook notification
bash scripts/utils/notifiers.sh webhook '{"status": "success"}'
```

## Core Library Scripts

These scripts are sourced by other scripts and provide core functionality.

### common.sh

Core utilities and functions.

**Key Functions:**
- `error_exit()` - Error handling with exit codes
- `check_command()` - Verify command exists
- `detect_os()` - Detect operating system
- `get_project_type()` - Detect project type
- `load_config()` - Load configuration file
- `get_version()` - Get version from git tag
- `check_git_repo()` - Verify git repository

**Exit Codes:**
- `0` - Success
- `1` - General error
- `2` - Configuration error
- `3` - Missing dependency
- `4` - Validation error

---

### logger.sh

Structured logging functions.

**Functions:**
- `log_info()` - Info messages (blue)
- `log_success()` - Success messages (green)
- `log_warn()` - Warnings (yellow)
- `log_error()` - Errors (red)
- `log_debug()` - Debug messages (gray)
- `log_section()` - Section headers
- `log_group_start()` - Start log group (CI)
- `log_group_end()` - End log group (CI)

**Environment Variables:**
- `LOG_LEVEL` - Log level (`debug`, `info`, `warn`, `error`)
- `LOG_TIMESTAMP` - Enable timestamps
- `LOG_FILE` - Log file path

---

### validators.sh

Input validation and environment checks.

**Functions:**
- `validate_env_vars()` - Check required environment variables
- `validate_url()` - Validate URL format
- `validate_semver()` - Validate semantic version
- `check_commands()` - Check multiple commands
- `check_git_repo()` - Verify git repository
- `check_docker()` - Verify Docker installed

**Examples:**
```bash
# Validate environment variables
validate_env_vars "API_KEY" "DATABASE_URL"

# Validate URL
validate_url "https://api.example.com"

# Validate semantic version
validate_semver "1.0.0"
```

## Common Script Patterns

### Sourcing Dependencies

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"
source "${SCRIPT_DIR}/../utils/logger.sh"
source "${SCRIPT_DIR}/../utils/validators.sh"
```

### Main Function Pattern

```bash
main() {
    log_section "Starting Script"
    # Your logic here
    log_success "Complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

### Error Handling

```bash
# Exit with error
error_exit "Something went wrong" ${EXIT_ERROR_GENERAL}

# Require command
require_command "docker"

# Validate environment
validate_env_vars "API_KEY" "SECRET_KEY"
```

For troubleshooting script issues, see [Troubleshooting](./troubleshooting.md).
