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

## CHANGELOG Workflow

### Why Update CHANGELOG?

Keeping CHANGELOG.md updated helps users:
- Track what changed between versions
- Identify breaking changes before updating
- Understand new features and fixes
- Follow project development progress

### When to Update CHANGELOG

**Required:**
- ✅ Before committing new features
- ✅ Before committing bug fixes
- ✅ Before committing breaking changes
- ✅ During release preparation

**Not Required:**
- ❌ Typos/grammar fixes
- ❌ Code formatting/style changes
- ❌ Internal refactoring (no user-facing changes)
- ❌ Documentation updates (unless adding features)

### How to Update CHANGELOG

#### Option 1: Interactive Mode (Recommended)

```bash
# Interactive prompt with recent commits shown
bash scripts/utils/update-changelog.sh
```

This will:
1. Show recent commits for reference
2. Prompt you to select change type
3. Prompt for changelog message
4. Prompt for issue/PR number (optional)
5. Insert entry in CHANGELOG.md

#### Option 2: Quick Command Line

```bash
# Add entry directly
bash scripts/utils/update-changelog.sh \
  --type added \
  --message "Add new feature X" \
  --issue 123
```

Available types:
- `added` - New features
- `changed` - Changes to existing functionality
- `deprecated` - Soon-to-be removed features
- `removed` - Removed features
- `fixed` - Bug fixes
- `security` - Security vulnerability fixes

#### Option 3: Auto-Generate from Commits

```bash
# Analyze recent commits and create entry
bash scripts/utils/update-changelog.sh --auto
```

### CHANGELOG Format

Follow [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format:

```markdown
## [Unreleased]

### Added
- New feature X (#123)

### Changed
- Updated behavior of Y (#124)

### Fixed
- Fixed bug in Z (#125)

## [1.0.0] - 2025-01-27

### Added
- Initial release features
```

### Release Process

When preparing a release:

1. Review [Unreleased] entries
2. Create new version section:
   ```markdown
   ## [1.1.0] - 2025-01-28
   ```
3. Move items from [Unreleased] to new version
4. Update version numbers in relevant files
5. Commit and tag the release:
   ```bash
   git add CHANGELOG.md
   git commit -m "chore: release v1.1.0"
   git tag v1.1.0
   git push origin v1.1.0
   ```

### Validation

Validate your CHANGELOG.md format:

```bash
# Check format
bash scripts/utils/update-changelog.sh --validate

# View unreleased entries
bash scripts/utils/update-changelog.sh --show-unreleased
```

### Automation Tools

The toolkit provides:
- `scripts/utils/update-changelog.sh` - Interactive changelog updater
- Pre-commit hooks (optional) - Remind to update CHANGELOG
- CI checks (optional) - Validate CHANGELOG in PRs

### Examples

**Adding a new feature:**
```bash
# Make code changes
git add .
bash scripts/utils/update-changelog.sh --type added --message "Add user authentication"
git commit -m "feat(auth): add user authentication"
```

**Fixing a bug:**
```bash
# Fix the bug
bash scripts/utils/update-changelog.sh --type fixed --message "Fix login timeout"
git commit -m "fix(auth): resolve login timeout issue"
```

**Preparing a release:**
```bash
# Move unreleased items to version section
# Update CHANGELOG.md manually
git add CHANGELOG.md
git commit -m "chore: release v1.1.0"
git tag v1.1.0
git push && git push --tags
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
