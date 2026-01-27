# Configuration Reference

Complete reference for CI/CD Toolkit configuration.

## Table of Contents

1. [Configuration Files](#configuration-files)
2. [General Settings](#general-settings)
3. [CI Settings](#ci-settings)
4. [CD Settings](#cd-settings)
5. [Environment Configuration](#environment-configuration)
6. [Notification Settings](#notification-settings)
7. [Language-Specific Settings](#language-specific-settings)
8. [Environment Variables](#environment-variables)

## Configuration Files

### Configuration Locations

The toolkit looks for configuration files in this order:

1. `.ci-cd.conf` (project root)
2. `config/ci-cd.conf`
3. Environment variables
4. Command-line flags

### Configuration File Format

The configuration file uses INI format:

```ini
[section]
key=value
key2=value2
```

### Example Configuration File

```ini
[general]
project_type=auto
log_level=info
dry_run=false

[ci]
lint_enabled=true
test_enabled=true
coverage_threshold=80

[cd]
build_tool=auto
environments=dev,staging,prod
auto_rollback=true
```

## General Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `project_type` | string | `auto` | Project type: `auto`, `nodejs`, `python`, `go`, `maven`, `gradle`, `docker` |
| `log_level` | string | `info` | Log level: `debug`, `info`, `warn`, `error` |
| `log_timestamp` | boolean | `false` | Add timestamps to log output |
| `log_file` | string | (empty) | Write logs to file |
| `dry_run` | boolean | `false` | Simulate actions without making changes |

### Project Type

```ini
[general]
# Auto-detect project type
project_type=auto

# Force specific type
project_type=nodejs
```

Supported project types:
- `auto` - Auto-detect from files present
- `nodejs` - Node.js/JavaScript projects
- `python` - Python projects
- `go` - Go projects
- `maven` - Java Maven projects
- `gradle` - Java Gradle projects
- `docker` - Docker-based projects

## CI Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `lint_enabled` | boolean | `true` | Enable/disable linting |
| `test_enabled` | boolean | `true` | Enable/disable testing |
| `coverage_enabled` | boolean | `true` | Enable/disable coverage |
| `coverage_threshold` | number | `80` | Minimum coverage percentage (0-100) |
| `parallel_tests` | boolean | `true` | Run tests in parallel |
| `test_timeout` | number | `300` | Test timeout in seconds |
| `parallel_jobs` | number | `4` | Number of parallel test jobs |
| `test_results_dir` | string | `test-results` | Test results output directory |
| `coverage_dir` | string | `coverage` | Coverage output directory |

### Example CI Configuration

```ini
[ci]
# Enable/disable CI steps
lint_enabled=true
test_enabled=true
coverage_enabled=true

# Coverage requirements
coverage_threshold=80
parallel_tests=true
parallel_jobs=4

# Output directories
test_results_dir=test-results
coverage_dir=coverage
```

## CD Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `build_tool` | string | `auto` | Build tool: `auto`, `npm`, `yarn`, `python`, `go`, `docker` |
| `docker_registry` | string | (empty) | Docker registry URL |
| `docker_org` | string | (empty) | Docker organization |
| `environments` | string | `dev,staging,prod` | Comma-separated environment names |
| `health_check_path` | string | `/health` | Health check endpoint path |
| `health_check_timeout` | number | `300` | Health check timeout in seconds |
| `health_check_interval` | number | `10` | Health check interval in seconds |
| `health_check_retries` | number | `30` | Health check retry count |
| `auto_rollback` | boolean | `true` | Automatic rollback on failure |
| `keep_versions` | number | `5` | Number of versions to keep |
| `artifacts_dir` | string | `dist` | Build artifacts directory |
| `version_file` | string | `VERSION` | Version file path |

### Example CD Configuration

```ini
[cd]
# Build settings
build_tool=auto
docker_registry=registry.example.com
docker_org=myorg

# Environments
environments=dev,staging,prod

# Health checks
health_check_path=/health
health_check_timeout=300
health_check_interval=10
auto_rollback=true

# Artifacts
artifacts_dir=dist
keep_versions=5
```

## Environment Configuration

Configure per-environment settings using `[environment.<name>]` sections.

### Development Environment

```ini
[environment.dev]
auto_deploy=true
required_approvals=0
skip_health_check=true
url=https://dev.example.com
```

### Staging Environment

```ini
[environment.staging]
auto_deploy=true
required_approvals=1
skip_health_check=false
url=https://staging.example.com
```

### Production Environment

```ini
[environment.prod]
auto_deploy=false
required_approvals=2
skip_health_check=false
url=https://prod.example.com
maintenance_page=/maintenance.html
```

### Environment Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `auto_deploy` | boolean | `false` | Auto-deploy on push |
| `required_approvals` | number | `0` | Required approval count |
| `skip_health_check` | boolean | `false` | Skip health checks |
| `url` | string | (empty) | Environment URL |
| `maintenance_page` | string | (empty) | Maintenance page path |

## Notification Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `enabled` | boolean | `false` | Enable notifications |
| `enabled_events` | string | (varies) | Comma-separated events |
| `slack_webhook` | string | (empty) | Slack webhook URL |
| `slack_channel` | string | (empty) | Slack channel override |
| `email_recipients` | string | (empty) | Email recipients (comma-separated) |
| `email_sender` | string | (empty) | Email sender address |
| `smtp_server` | string | (empty) | SMTP server |
| `smtp_port` | number | `587` | SMTP port |
| `smtp_username` | string | (empty) | SMTP username |
| `webhook_url` | string | (empty) | Generic webhook URL |
| `webhook_method` | string | `POST` | Webhook HTTP method |
| `webhook_content_type` | string | `application/json` | Webhook content type |

### Notification Events

Supported events:
- `build_success`
- `build_failure`
- `test_success`
- `test_failure`
- `deploy_success`
- `deploy_failure`
- `rollback`

### Example Notification Configuration

```ini
[notifications]
# Enable notifications
enabled=true

# Events to notify on
enabled_events=deploy_success,deploy_failure,test_failure

# Slack
slack_webhook=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
slack_channel=#deployments

# Email
email_sender=ci-cd@example.com
email_recipients=team@example.com,devops@example.com
smtp_server=smtp.example.com
smtp_port=587
smtp_username=ci-cd@example.com

# Generic webhook
webhook_url=https://hooks.example.com/deploy
webhook_method=POST
webhook_content_type=application/json
```

## Language-Specific Settings

### Node.js

```ini
[nodejs]
node_version=20
package_manager=npm
frozen_lockfile=true
npm_audit=true
audit_level=moderate
```

**Settings:**

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `node_version` | string | `20` | Node.js version |
| `package_manager` | string | `npm` | Package manager: `npm`, `yarn`, `pnpm` |
| `frozen_lockfile` | boolean | `true` | Use frozen lockfile |
| `npm_audit` | boolean | `true` | Run npm audit |
| `audit_level` | string | `moderate` | Audit severity level |

### Python

```ini
[python]
python_version=3.11
venv_tool=venv
linter=flake8
test_runner=pytest
formatter=black
type_checker=mypy
install_dev_deps=true
```

**Settings:**

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `python_version` | string | `3.11` | Python version |
| `venv_tool` | string | `venv` | Virtual environment tool |
| `linter` | string | `flake8` | Linter: `flake8`, `pylint`, `black` |
| `test_runner` | string | `pytest` | Test runner |
| `formatter` | string | `black` | Code formatter |
| `type_checker` | string | `mypy` | Type checker |

### Go

```ini
[go]
go_version=1.21
use_modules=true
vendor=false
linter=golangci-lint
race_detector=true
coverage_mode=atomic
```

**Settings:**

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `go_version` | string | `1.21` | Go version |
| `use_modules` | boolean | `true` | Use Go modules |
| `vendor` | boolean | `false` | Vendor dependencies |
| `linter` | string | `golangci-lint` | Go linter |
| `race_detector` | boolean | `true` | Enable race detector |
| `coverage_mode` | string | `atomic` | Coverage mode |

### Docker

```ini
[docker]
build_args=
use_cache=true
dockerfile=Dockerfile
docker_context=.
target_stage=
platform=
tag_commit=true
tag_branch=false
push=false
```

**Settings:**

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `build_args` | string | (empty) | Build args (comma-separated) |
| `use_cache` | boolean | `true` | Use build cache |
| `dockerfile` | string | `Dockerfile` | Dockerfile path |
| `docker_context` | string | `.` | Docker context path |
| `target_stage` | string | (empty) | Target build stage |
| `platform` | string | (empty) | Target platform |
| `tag_commit` | boolean | `true` | Tag with commit SHA |
| `tag_branch` | boolean | `false` | Tag with branch name |
| `push` | boolean | `false` | Push to registry |

## Environment Variables

Environment variables override configuration file settings.

### General Environment Variables

| Variable | Description |
|----------|-------------|
| `PROJECT_TYPE` | Force project type |
| `LOG_LEVEL` | Set log level |
| `LOG_TIMESTAMP` | Enable log timestamps |
| `LOG_FILE` | Log file path |
| `DRY_RUN` | Enable dry-run mode |
| `BUILD_VERSION` | Set build version |

### CI Environment Variables

| Variable | Description |
|----------|-------------|
| `LINT_ENABLED` | Enable/disable linting |
| `TEST_ENABLED` | Enable/disable testing |
| `COVERAGE_ENABLED` | Enable/disable coverage |
| `COVERAGE_THRESHOLD` | Coverage threshold |
| `PARALLEL_TESTS` | Run tests in parallel |
| `TEST_TIMEOUT` | Test timeout |
| `PARALLEL_JOBS` | Parallel job count |

### CD Environment Variables

| Variable | Description |
|----------|-------------|
| `BUILD_TOOL` | Force build tool |
| `DOCKER_REGISTRY` | Docker registry URL |
| `DOCKER_ORG` | Docker organization |
| `DEPLOY_ENVIRONMENT` | Target environment |
| `AUTO_ROLLBACK` | Enable auto-rollback |
| `SKIP_BUILD` | Skip build step |
| `SKIP_HEALTH_CHECK` | Skip health checks |
| `FORCE_DEPLOY` | Force deployment |

### Notification Environment Variables

| Variable | Description |
|----------|-------------|
| `SLACK_WEBHOOK` | Slack webhook URL |
| `SLACK_CHANNEL` | Slack channel |
| `SMTP_SERVER` | SMTP server |
| `SMTP_USERNAME` | SMTP username |
| `SMTP_PASSWORD` | SMTP password |
| `EMAIL_RECIPIENTS` | Email recipients |
| `WEBHOOK_URL` | Webhook URL |

### Docker Environment Variables

| Variable | Description |
|----------|-------------|
| `DOCKERFILE` | Dockerfile path |
| `DOCKER_CONTEXT` | Docker context |
| `TARGET_STAGE` | Target build stage |
| `BUILD_ARGS` | Build arguments |
| `IMAGE_NAME` | Image name |
| `IMAGE_TAG` | Image tag |

## Configuration Priority

Configuration is applied in this order (later overrides earlier):

1. Default values (hardcoded)
2. `config/ci-cd.conf`
3. `.ci-cd.conf`
4. Environment variables
5. Command-line flags

### Example Override Chain

```ini
# config/ci-cd.conf
[ci]
coverage_threshold=80
```

```bash
# .ci-cd.conf
[ci]
coverage_threshold=90
```

```bash
# Environment variable
export COVERAGE_THRESHOLD=95
```

```bash
# Command-line flag (highest priority)
bash scripts/ci/coverage.sh --threshold 100
```

Result: Coverage threshold = 100

## Validation

The toolkit validates configuration on startup:

```bash
# Validate configuration
bash scripts/utils/validators.sh --config
```

Common validation errors:
- Invalid project type
- Missing required fields
- Invalid numeric values
- Invalid boolean values
- Missing environment variables

For troubleshooting, see [Troubleshooting](./troubleshooting.md).
