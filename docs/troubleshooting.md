# Troubleshooting

Common issues and solutions for the CI/CD Toolkit.

## Table of Contents

1. [Installation Issues](#installation-issues)
2. [Script Execution Issues](#script-execution-issues)
3. [CI/CD Pipeline Issues](#cicd-pipeline-issues)
4. [Build Issues](#build-issues)
5. [Deployment Issues](#deployment-issues)
6. [Configuration Issues](#configuration-issues)

## Installation Issues

### Permission Denied

**Error:**
```
bash: scripts/ci/lint.sh: Permission denied
```

**Solution:**
```bash
# Make scripts executable
chmod +x scripts/**/*.sh

# Or run with bash explicitly
bash scripts/ci/lint.sh
```

### Command Not Found

**Error:**
```
scripts/ci/lint.sh: command not found
```

**Solution:**
```bash
# Check script exists
ls -la scripts/ci/lint.sh

# Use absolute path
bash /path/to/project/scripts/ci/lint.sh

# Add to PATH
export PATH="/path/to/project/scripts:$PATH"
```

### Missing Dependencies

**Error:**
```
Error: Required command 'eslint' not found
```

**Solution:**
```bash
# Install dependencies for your project
npm install

# Or install CI/CD tools
bash scripts/setup/install-deps.sh --tools node,eslint

# Check what's installed
bash scripts/setup/install-deps.sh --check
```

## Script Execution Issues

### Script Hangs

**Symptoms:**
- Script appears to do nothing
- No output for long time

**Solutions:**
```bash
# Enable debug logging
LOG_LEVEL=debug bash scripts/ci/test.sh

# Check for infinite loops
# Review script for while loops without breaks

# Run with timeout
timeout 300 bash scripts/ci/test.sh
```

### Unexpected Exit

**Error:**
Script exits without clear error message

**Solutions:**
```bash
# Check exit code
bash scripts/ci/test.sh
echo $?

# Enable verbose mode
bash -x scripts/ci/test.sh

# Check for set -e causing early exit
# Review script for error handling
```

### Path Issues

**Error:**
```
No such file or directory: scripts/utils/common.sh
```

**Solution:**
```bash
# Run from project root
cd /path/to/project
bash scripts/ci/lint.sh

# Or specify full paths
SCRIPT_DIR="/path/to/project/scripts"
source "${SCRIPT_DIR}/utils/common.sh"
```

## CI/CD Pipeline Issues

### GitHub Actions Workflow Not Triggering

**Symptoms:**
- Push to branch doesn't trigger workflow
- Workflow doesn't appear in Actions tab

**Solutions:**
1. Check workflow file location: `.github/workflows/` (not `.github/workflow/`)
2. Verify YAML syntax
3. Check branch names in workflow
4. Verify workflow is not disabled
5. Check repository settings → Actions → Actions permissions

### GitLab CI Pipeline Not Running

**Symptoms:**
- Push doesn't trigger pipeline
- Pipeline stuck in pending

**Solutions:**
1. Check file is named `.gitlab-ci.yml` (not `.gitlab-ci.yaml`)
2. Verify YAML syntax
3. Check if runners are available
4. Check project → Settings → CI/CD → Pipeline permissions

### Pipeline Fails with Exit Code 127

**Error:**
```
/bin/bash: script/command: not found
```

**Solutions:**
1. Check command exists in runner environment
2. Use absolute paths for commands
3. Install missing dependencies in workflow
4. Check PATH environment variable

### Timeout Errors

**Error:**
```
Error: The operation was timed out
```

**Solutions:**
```yaml
# GitHub Actions - increase timeout
jobs:
  test:
    timeout-minutes: 30

# GitLab CI - increase timeout
test:
  script:
    - bash scripts/ci/test.sh
  timeout: 30m
```

## Build Issues

### Docker Build Fails

**Error:**
```
Error: Docker build failed
```

**Solutions:**
```bash
# Check Docker is running
docker ps

# Verify Dockerfile syntax
docker build --check .

# Build without cache
docker build --no-cache .

# Check Docker daemon logs
docker logs
```

### Build Artifacts Not Found

**Error:**
```
Error: No build artifacts found
```

**Solutions:**
```bash
# Verify artifacts directory
ls -la dist/

# Check build output
bash scripts/cd/build.sh --dry-run

# Specify output directory
bash scripts/cd/build.sh --output ./dist
```

### Version Conflicts

**Error:**
```
Error: Version mismatch
```

**Solutions:**
```bash
# Set explicit version
BUILD_VERSION=1.0.0 bash scripts/cd/build.sh

# Check current version
git describe --tags

# Use version from git tag
export BUILD_VERSION=$(git describe --tags --abbrev=0)
```

## Deployment Issues

### Health Check Fails

**Error:**
```
Error: Health check failed after N attempts
```

**Solutions:**
```bash
# Check if service is running
curl https://app.example.com/health

# Increase timeout
HEALTH_CHECK_TIMEOUT=600 bash scripts/cd/deploy.sh staging

# Skip health check
bash scripts/cd/deploy.sh dev --skip-health-check

# Test health check manually
bash scripts/utils/health-check.sh https://app.example.com/health --retry 60
```

### Permission Denied During Deployment

**Error:**
```
Error: Permission denied (publickey)
```

**Solutions:**
```bash
# Check SSH keys
ssh-add -l

# Add SSH key
ssh-add ~/.ssh/id_rsa

# Test SSH connection
ssh user@host

# Configure SSH in workflow
- name: Configure SSH
  run: |
    mkdir -p ~/.ssh
    echo "${{ secrets.SSH_PRIVATE_KEY }}" > ~/.ssh/id_rsa
    chmod 600 ~/.ssh/id_rsa
```

### Rollback Fails

**Error:**
```
Error: Rollback failed
```

**Solutions:**
```bash
# List available versions
bash scripts/cd/rollback.sh prod --list

# Rollback to specific version
bash scripts/cd/rollback.sh prod --version 1.0.1

# Check version directory exists
ls -la .versions/prod/

# Manual rollback steps
# 1. Restore previous artifacts
# 2. Restart service
# 3. Run health checks
```

## Configuration Issues

### Configuration File Not Found

**Error:**
```
Error: Configuration file not found
```

**Solutions:**
```bash
# Create default config
bash scripts/setup/init-project.sh

# Specify config file
bash scripts/ci/test.sh --config /path/to/config.conf

# Check config file locations
ls -la .ci-cd.conf
ls -la config/ci-cd.conf
```

### Invalid Configuration

**Error:**
```
Error: Invalid configuration value
```

**Solutions:**
```bash
# Validate configuration
bash scripts/utils/validators.sh --config

# Check for syntax errors
# INI format: key=value (no spaces around =)

# Reset to default
cp config/ci-cd.conf .ci-cd.conf
```

### Environment Variables Not Set

**Error:**
```
Error: Missing required environment variables
```

**Solutions:**
```bash
# Set environment variable
export LOG_LEVEL=debug

# Source .env file
source .env.prod

# Pass to script
LOG_LEVEL=debug bash scripts/ci/test.sh

# Check if variable is set
echo "${LOG_LEVEL:-not set}"
```

## Debugging Tips

### Enable Debug Logging

```bash
# Method 1: Environment variable
export LOG_LEVEL=debug
bash scripts/ci/test.sh

# Method 2: Command-line flag
bash scripts/ci/test.sh --log-level debug

# Method 3: Bash verbose mode
bash -x scripts/ci/test.sh
```

### Dry Run Mode

```bash
# See what would happen without making changes
DRY_RUN=true bash scripts/cd/deploy.sh staging

# Or use flag
bash scripts/cd/deploy.sh staging --dry-run
```

### Check Script Syntax

```bash
# Check bash syntax
bash -n scripts/ci/lint.sh

# Use shellcheck if available
shellcheck scripts/**/*.sh
```

### Test Components Individually

```bash
# Test common.sh
source scripts/utils/common.sh
get_project_type

# Test logger.sh
source scripts/utils/logger.sh
log_info "Test message"

# Test validators.sh
source scripts/utils/validators.sh
check_command docker
```

## Getting Help

### Collect Diagnostic Information

```bash
# Create diagnostics script
cat > diagnose.sh << 'EOF'
#!/usr/bin/env bash
echo "=== System Info ==="
uname -a

echo -e "\n=== Environment ==="
env | sort

echo -e "\n=== Scripts ==="
ls -la scripts/**/*.sh

echo -e "\n=== Config ==="
cat .ci-cd.conf 2>/dev/null || echo "No config found"

echo -e "\n=== Git ==="
git status
git log --oneline -5

echo -e "\n=== Dependencies ==="
which node npm python3 go docker
node --version 2>/dev/null || true
npm --version 2>/dev/null || true
python3 --version 2>/dev/null || true
go version 2>/dev/null || true
docker --version 2>/dev/null || true
EOF

chmod +x diagnose.sh
./diagnose.sh > diagnostics.txt
```

### Useful Resources

- **Documentation**: [docs/](../docs/)
- **Examples**: [examples/](../examples/)
- **Issues**: Report on GitHub

### Common Error Messages

| Error | Solution |
|-------|----------|
| `command not found` | Install missing dependencies |
| `Permission denied` | Make scripts executable (`chmod +x`) |
| `Configuration not found` | Run `init-project.sh` |
| `Build failed` | Check build logs, verify dependencies |
| `Health check failed` | Check service status, increase timeout |
| `Rollback failed` | Verify version exists, check rollback logs |
| `Pipeline not triggering` | Check workflow syntax, branch names |

## Still Having Issues?

1. **Check logs:**
   - Script logs: Check console output
   - CI logs: Check GitHub Actions / GitLab CI logs
   - Service logs: Check application logs

2. **Verify configuration:**
   - Config file syntax
   - Environment variables
   - Secrets and credentials

3. **Test components:**
   - Run scripts locally
   - Test with dry-run mode
   - Test health checks manually

4. **Get help:**
   - Read documentation
   - Check examples
   - Search existing issues
   - Create new issue with diagnostics
