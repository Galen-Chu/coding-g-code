#!/usr/bin/env bash
################################################################################
# CI/CD Toolkit - Validation Utilities
# =============================================================================
# Provides input validation and environment checking functions.
# Source this script after common.sh and logger.sh
################################################################################

set -euo pipefail

# Ensure dependencies are loaded
if [[ -z "${SCRIPT_DIR:-}" ]] || [[ -z "${LOG_LEVEL:-}" ]]; then
    echo "ERROR: validators.sh must be sourced after common.sh and logger.sh" >&2
    exit 1
fi

# =============================================================================
# Environment Variable Validation
# =============================================================================

# Validate that required environment variables are set
# Usage: validate_env_vars "VAR1" "VAR2" ...
# Returns: 0 if all set, 1 if any missing
validate_env_vars() {
    local missing_vars=()
    local all_valid=true

    for var in "$@"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("${var}")
            all_valid=false
        fi
    done

    if [[ "${all_valid}" == "false" ]]; then
        log_error "Missing required environment variables:"
        for var in "${missing_vars[@]}"; do
            log_error "  - ${var}"
        done
        return 1
    fi

    return 0
}

# Check if environment variable matches expected value
# Usage: validate_env_value "VAR_NAME" "expected_value"
# Returns: 0 if matches, 1 if not
validate_env_value() {
    local var_name="$1"
    local expected="$2"
    local actual="${!var_name:-}"

    if [[ "${actual}" != "${expected}" ]]; then
        log_error "Environment variable ${var_name} has unexpected value: ${actual} (expected: ${expected})"
        return 1
    fi

    return 0
}

# Validate numeric environment variable
# Usage: validate_env_number "VAR_NAME" [min] [max]
# Returns: 0 if valid number, 1 if not
validate_env_number() {
    local var_name="$1"
    local min="${2:-}"
    local max="${3:-}"
    local value="${!var_name:-}"

    # Check if it's a number
    if ! [[ "${value}" =~ ^[0-9]+$ ]]; then
        log_error "Environment variable ${var_name} is not a valid number: ${value}"
        return 1
    fi

    # Check min/max
    if [[ -n "${min}" ]] && [[ "${value}" -lt "${min}" ]]; then
        log_error "Environment variable ${var_name} is below minimum: ${value} < ${min}"
        return 1
    fi

    if [[ -n "${max}" ]] && [[ "${value}" -gt "${max}" ]]; then
        log_error "Environment variable ${var_name} exceeds maximum: ${value} > ${max}"
        return 1
    fi

    return 0
}

# =============================================================================
# URL Validation
# =============================================================================

# Validate URL format (basic check)
# Usage: validate_url "url"
# Returns: 0 if valid, 1 if not
validate_url() {
    local url="$1"

    # Basic URL regex
    if [[ "${url}" =~ ^https?:// ]]; then
        return 0
    else
        log_error "Invalid URL format: ${url}"
        return 1
    fi
}

# Validate HTTPS URL
# Usage: validate_https_url "url"
# Returns: 0 if HTTPS URL, 1 if not
validate_https_url() {
    local url="$1"

    if [[ "${url}" =~ ^https:// ]]; then
        return 0
    else
        log_error "URL must use HTTPS: ${url}"
        return 1
    fi
}

# =============================================================================
# Semantic Version Validation
# =============================================================================

# Validate semantic version string
# Usage: validate_semver "version"
# Returns: 0 if valid semver, 1 if not
validate_semver() {
    local version="$1"

    # Semver regex: major.minor.patch[-prerelease][+build]
    if [[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?(\+[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$ ]]; then
        return 0
    else
        log_error "Invalid semantic version: ${version}"
        return 1
    fi
}

# Compare two semantic versions
# Usage: compare_semver "version1" "version2"
# Returns: 0 if equal, 1 if v1 > v2, 2 if v1 < v2
compare_semver() {
    local v1="$1"
    local v2="$2"

    # Remove pre-release and build metadata for comparison
    v1="${v1%%+*}"
    v1="${v1%%-*}"
    v2="${v2%%+*}"
    v2="${v2%%-*}"

    # Split into arrays
    IFS='.' read -ra v1_parts <<< "${v1}"
    IFS='.' read -ra v2_parts <<< "${v2}"

    # Compare each part
    for i in {0..2}; do
        local p1="${v1_parts[$i]:-0}"
        local p2="${v2_parts[$i]:-0}"

        if ((p1 > p2)); then
            return 1
        elif ((p1 < p2)); then
            return 2
        fi
    done

    return 0
}

# =============================================================================
# File and Directory Validation
# =============================================================================

# Validate file exists and is readable
# Usage: validate_file "path/to/file" ["file_description"]
# Returns: 0 if valid, 1 if not
validate_file() {
    local file="$1"
    local description="${2:-file}"

    if [[ ! -f "${file}" ]]; then
        log_error "${description} not found: ${file}"
        return 1
    fi

    if [[ ! -r "${file}" ]]; then
        log_error "${description} is not readable: ${file}"
        return 1
    fi

    return 0
}

# Validate directory exists
# Usage: validate_dir "path/to/dir" ["dir_description"]
# Returns: 0 if valid, 1 if not
validate_dir() {
    local dir="$1"
    local description="${2:-directory}"

    if [[ ! -d "${dir}" ]]; then
        log_error "${description} not found: ${dir}"
        return 1
    fi

    return 0
}

# Validate file is executable
# Usage: validate_executable "path/to/file"
# Returns: 0 if executable, 1 if not
validate_executable() {
    local file="$1"

    if ! validate_file "${file}"; then
        return 1
    fi

    if [[ ! -x "${file}" ]]; then
        log_error "File is not executable: ${file}"
        return 1
    fi

    return 0
}

# Validate configuration file exists
# Usage: validate_config_file [config_path]
# Returns: 0 if valid, 1 if not
validate_config_file() {
    local config_path="${1:-${CONFIG_FILE}}"

    if [[ ! -f "${config_path}" ]]; then
        log_warn "Configuration file not found: ${config_path}"
        log_warn "Using default configuration"
        return 1
    fi

    log_debug "Using configuration: ${config_path}"
    return 0
}

# =============================================================================
# Command and Tool Validation
# =============================================================================

# Check if multiple commands exist
# Usage: check_commands "cmd1" "cmd2" ...
# Returns: 0 if all exist, 1 if any missing
check_commands() {
    local missing=()
    local all_exist=true

    for cmd in "$@"; do
        if ! check_command "${cmd}"; then
            missing+=("${cmd}")
            all_exist=false
        fi
    done

    if [[ "${all_exist}" == "false" ]]; then
        log_error "Missing required commands:"
        for cmd in "${missing[@]}"; do
            log_error "  - ${cmd}"
        done
        return 1
    fi

    return 0
}

# Check minimum version of a command
# Usage: check_command_version "command" "minimum_version"
# Returns: 0 if version >= minimum, 1 if not
check_command_version() {
    local cmd="$1"
    local min_version="$2"
    local current_version

    if ! check_command "${cmd}"; then
        log_error "Command not found: ${cmd}"
        return 1
    fi

    # Get version (command-specific)
    case "${cmd}" in
        git)
            current_version="$(git --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
            ;;
        docker)
            current_version="$(docker --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
            ;;
        node|nodejs)
            current_version="$(node --version 2>/dev/null | sed 's/^v//')"
            ;;
        python|python3)
            current_version="$(python3 --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
            ;;
        *)
            log_warn "Version check not implemented for: ${cmd}"
            return 0
            ;;
    esac

    if [[ -z "${current_version}" ]]; then
        log_warn "Could not determine version of: ${cmd}"
        return 0
    fi

    # Compare versions
    compare_semver "${current_version}" "${min_version}"
    local result=$?

    if [[ ${result} -eq 2 ]]; then
        log_error "${cmd} version ${current_version} is below minimum ${min_version}"
        return 1
    fi

    log_debug "${cmd} version ${current_version} meets requirement >= ${min_version}"
    return 0
}

# =============================================================================
# Git Repository Validation
# =============================================================================

# Check if current directory is a git repository
# Usage: check_git_repo
# Returns: 0 if in git repo, 1 if not
check_git_repo() {
    [[ -d "${PROJECT_ROOT}/.git" ]]
}

# Validate git branch name
# Usage: validate_git_branch "branch_name"
# Returns: 0 if valid, 1 if not
validate_git_branch() {
    local branch="$1"
    local current_branch

    if ! check_git_repo; then
        log_error "Not in a git repository"
        return 1
    fi

    # Get current branch
    current_branch="$(git -C "${PROJECT_ROOT}" branch --show-current 2>/dev/null || echo "")"

    if [[ "${current_branch}" != "${branch}" ]]; then
        log_error "Not on expected branch: ${branch} (current: ${current_branch})"
        return 1
    fi

    return 0
}

# Validate git working directory is clean
# Usage: validate_git_clean
# Returns: 0 if clean, 1 if has uncommitted changes
validate_git_clean() {
    if ! check_git_repo; then
        return 1
    fi

    if [[ -n "$(git -C "${PROJECT_ROOT}" status --porcelain 2>/dev/null)" ]]; then
        log_warn "Git working directory has uncommitted changes"
        return 1
    fi

    return 0
}

# =============================================================================
# Docker Validation
# =============================================================================

# Check if Docker is installed and running
# Usage: check_docker
# Returns: 0 if available, 1 if not
check_docker() {
    if ! check_command docker; then
        log_error "Docker is not installed"
        return 1
    fi

    # Check if Docker daemon is running
    if ! docker info &>/dev/null; then
        log_error "Docker daemon is not running"
        return 1
    fi

    return 0
}

# Validate Docker image name format
# Usage: validate_docker_image "image_name"
# Returns: 0 if valid, 1 if not
validate_docker_image() {
    local image="$1"

    # Basic Docker image name validation
    if [[ "${image}" =~ ^[a-z0-9]+([\.\-_][a-z0-9]+)*(\:[a-z0-9]+([\.\-_][a-z0-9]+)*)?(\/[a-z0-9]+([\.\-_][a-z0-9]+)*)*$ ]]; then
        return 0
    else
        log_error "Invalid Docker image name: ${image}"
        return 1
    fi
}

# =============================================================================
# Input Sanitization
# =============================================================================

# Sanitize input to prevent injection attacks
# Usage: sanitize_input "input_string"
# Outputs: sanitized string
sanitize_input() {
    local input="$1"

    # Remove dangerous characters
    input="${input//\$()/}"      # Remove $()
    input="${input//\`/}"        # Remove backticks
    input="${input//;/}"         # Remove semicolons
    input="${input//|/}"         # Remove pipes
    input="${input//&&/}"        # Remove &&
    input="${input//||/}"        # Remove ||

    echo "${input}"
}

# Validate alphanumeric string
# Usage: validate_alphanumeric "string" ["description"]
# Returns: 0 if alphanumeric, 1 if not
validate_alphanumeric() {
    local str="$1"
    local description="${2:-string}"

    if [[ "${str}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        return 0
    else
        log_error "Invalid ${description}: must contain only letters, numbers, hyphens, and underscores"
        return 1
    fi
}

# =============================================================================
# Port and Network Validation
# =============================================================================

# Validate port number
# Usage: validate_port "port_number"
# Returns: 0 if valid port, 1 if not
validate_port() {
    local port="$1"

    if ! [[ "${port}" =~ ^[0-9]+$ ]]; then
        log_error "Invalid port number: ${port}"
        return 1
    fi

    if [[ ${port} -lt 1 ]] || [[ ${port} -gt 65535 ]]; then
        log_error "Port number out of range (1-65535): ${port}"
        return 1
    fi

    return 0
}

# Check if port is in use
# Usage: check_port_in_use "port_number"
# Returns: 0 if port is in use, 1 if available
check_port_in_use() {
    local port="$1"

    if ! validate_port "${port}"; then
        return 1
    fi

    # Try to bind to the port
    if [[ "$(detect_os)" == "linux" ]]; then
        ss -tuln | grep -q ":${port} "
    elif [[ "$(detect_os)" == "macos" ]]; then
        netstat -an | grep -q "\.${port} "
    else
        # Generic check using timeout and nc
        timeout 1 bash -c "echo </dev/tcp/127.0.0.1/${port}" &>/dev/null
    fi
}

# =============================================================================
# Email Validation
# =============================================================================

# Validate email address format
# Usage: validate_email "email_address"
# Returns: 0 if valid email format, 1 if not
validate_email() {
    local email="$1"

    # Basic email regex
    if [[ "${email}" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        log_error "Invalid email address: ${email}"
        return 1
    fi
}

# =============================================================================
# Export Functions
# =============================================================================
export -f validate_env_vars
export -f validate_env_value
export -f validate_env_number
export -f validate_url
export -f validate_https_url
export -f validate_semver
export -f compare_semver
export -f validate_file
export -f validate_dir
export -f validate_executable
export -f validate_config_file
export -f check_commands
export -f check_command_version
export -f check_git_repo
export -f validate_git_branch
export -f validate_git_clean
export -f check_docker
export -f validate_docker_image
export -f sanitize_input
export -f validate_alphanumeric
export -f validate_port
export -f check_port_in_use
export -f validate_email
