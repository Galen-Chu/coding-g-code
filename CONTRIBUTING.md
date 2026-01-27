# Contributing to CI/CD Toolkit

Thank you for your interest in contributing to the CI/CD Toolkit! This document provides guidelines and instructions for contributing.

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Workflow](#development-workflow)
4. [Coding Standards](#coding-standards)
5. [Testing Guidelines](#testing-guidelines)
6. [Commit Messages](#commit-messages)
7. [Pull Request Process](#pull-request-process)
8. [Adding Features](#adding-features)

## Code of Conduct

Please be respectful and constructive in all interactions. We aim to maintain a welcoming and inclusive community.

## Getting Started

### Prerequisites

- Bash/shell scripting knowledge
- Familiarity with CI/CD concepts
- Git and GitHub knowledge
- Basic understanding of the target language (Node.js, Python, Go, etc.)

### Initial Setup

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/ci-cd-toolkit.git
   cd ci-cd-toolkit
   ```
3. Add upstream remote:
   ```bash
   git remote add upstream https://github.com/Galen-Chu/coding-g-code.git
   ```
4. Install dependencies:
   ```bash
   bash scripts/setup/install-deps.sh
   ```

## Development Workflow

### 1. Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

Branch naming conventions:
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring
- `test/` - Adding or updating tests
- `chore/` - Maintenance tasks

### 2. Make Your Changes

- Edit scripts in `scripts/`
- Add documentation
- Update tests
- Follow coding standards (see below)

### 3. Test Your Changes

```bash
# Check script syntax
bash -n scripts/**/*.sh

# Test individual scripts
bash scripts/ci/lint.sh --help
bash scripts/ci/test.sh --dry-run

# Test on example projects
cd examples/simple-nodejs
../../scripts/ci/lint.sh
../../scripts/ci/test.sh
```

### 4. Commit Your Changes

See [Commit Messages](#commit-messages) for guidelines.

### 5. Push to Your Fork

```bash
git push origin feature/your-feature-name
```

### 6. Create a Pull Request

Go to the original repository and create a pull request from your branch.

## Coding Standards

### Shell Script Best Practices

1. **Shebang**: Always use `#!/usr/bin/env bash`
   ```bash
   #!/usr/bin/env bash
   ```

2. **Strict Mode**: Enable strict error handling
   ```bash
   set -euo pipefail
   ```

3. **Quote Variables**: Always quote variables
   ```bash
   "${VAR}"  # Good
   $VAR      # Bad
   ```

4. **Functions**: Define functions before main code
   ```bash
   my_function() {
       local var="$1"
       echo "${var}"
   }
   ```

5. **Comments**: Document complex logic
   ```bash
   # Validate URL format
   validate_url() {
       local url="$1"
       # ... implementation
   }
   ```

### Code Organization

#### Script Structure
```bash
#!/usr/bin/env bash
set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source dependencies
source "${SCRIPT_DIR}/../utils/common.sh"
source "${SCRIPT_DIR}/../utils/logger.sh"

# Script constants
MY_CONSTANT="value"

# Helper functions
helper_function() {
    # implementation
}

# Main function
main() {
    # implementation
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

#### Naming Conventions

- **Functions**: `snake_case`
  ```bash
  my_function_name()
  ```

- **Constants**: `UPPER_SNAKE_CASE`
  ```bash
  MAX_RETRIES=30
  ```

- **Local Variables**: `snake_case`
  ```bash
  local my_var="$1"
  ```

### Error Handling

```bash
# Use error_exit for errors
error_exit "Something went wrong" ${EXIT_ERROR_GENERAL}

# Check command exists
require_command "docker"

# Validate inputs
validate_url "${url}" || return $?
```

### Logging

```bash
# Use appropriate log levels
log_info "Starting operation..."
log_success "Operation completed"
log_warn "Warning message"
log_error "Error occurred"
log_debug "Debug info"
```

## Testing Guidelines

### Test Categories

1. **Syntax Testing**: Verify scripts have valid syntax
   ```bash
   bash -n scripts/**/*.sh
   shellcheck scripts/**/*.sh  # if available
   ```

2. **Unit Testing**: Test individual functions
   ```bash
   # Source the script and test functions
   source scripts/utils/common.sh
   get_project_type
   ```

3. **Integration Testing**: Test complete workflows
   ```bash
   bash scripts/ci/lint.sh
   bash scripts/ci/test.sh
   bash scripts/cd/build.sh
   ```

### Test Coverage

When adding new features:
1. Update existing tests if needed
2. Add tests for new functionality
3. Test on multiple platforms (Linux, macOS, Windows)
4. Test with example projects

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/) specification:

### Format

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks
- `perf`: Performance improvements
- `ci`: CI/CD changes

### Examples

```
feat(lint): add support for RLS linter

Add RLS (Ruby Style Guide) linter support for Ruby projects.
Include auto-detection based on Gemfile presence.

Closes #123
```

```
fix(deploy): resolve health check timeout issue

Increase default timeout to 5 minutes to accommodate slow deployments.
Fixes #456
```

```
docs: update getting started guide

Add section on environment configuration and fix typos.
```

## Pull Request Process

### PR Title

Use the same format as commit messages:
```
feat(scope): brief description
```

### PR Description

Include:
- **What**: What changes were made
- **Why**: Why these changes are needed
- **How**: How the changes work
- **Testing**: How the changes were tested
- **Screenshots**: If applicable (UI changes, etc.)

### Checklist

- [ ] Code follows coding standards
- [ ] Scripts have been tested
- [ ] Documentation has been updated
- [ ] Examples still work
- [ ] No new warnings generated
- [ ] Commit messages follow conventions

### Review Process

1. Automated checks (CI) must pass
2. At least one maintainer approval required
3. Address review feedback
4. Squash and merge on approval

## Adding Features

### Adding Language Support

1. **Update Detection** (`scripts/utils/common.sh`):
   ```bash
   get_project_type() {
       if [[ -f "${PROJECT_ROOT}/your-file" ]]; then
           echo "yourlanguage"
       fi
   }
   ```

2. **Add Linter** (`scripts/ci/lint.sh`):
   ```bash
   lint_yourlanguage() {
       # Implementation
   }
   ```

3. **Add Test Runner** (`scripts/ci/test.sh`):
   ```bash
   test_yourlanguage() {
       # Implementation
   }
   ```

4. **Add Documentation**:
   - Update `docs/configuration.md`
   - Update `docs/scripts-reference.md`
   - Add example in `examples/`

5. **Test**: Create example project and verify all scripts work

### Adding Notification Channel

1. **Add to** `scripts/utils/notifiers.sh`:
   ```bash
   notify_yourplatform() {
       local message="$1"
       # Implementation
   }
   ```

2. **Update Configuration** (`config/ci-cd.conf`):
   ```ini
   [notifications]
   yourplatform_webhook=
   ```

3. **Update Documentation**:
   - Document in `docs/configuration.md`
   - Add usage examples

### Adding CI/CD Platform

1. **Create workflow template**:
   - `templates/<platform>/ci.yml`
   - `templates/<platform>/cd.yml`

2. **Update Documentation**:
   - Add to `docs/pipelines.md`
   - Update `README.md`

3. **Test**: Verify workflows work correctly

## Questions or Need Help?

- Check existing [documentation](docs/)
- Review [example projects](examples/)
- [Open an issue](https://github.com/Galen-Chu/coding-g-code/issues)
- Start a [discussion](https://github.com/Galen-Chu/coding-g-code/discussions)

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (MIT License).
