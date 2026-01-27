#!/usr/bin/env bash
################################################################################
# CI/CD Toolkit - Build Script
# =============================================================================
# Build project artifacts with version injection and multi-format support.
#
# Usage:
#   ./scripts/cd/build.sh [options]
#
# Options:
#   --version VER    Set build version
#   --docker         Build Docker image
#   --platform PLAT  Target platform (e.g., linux/amd64,linux/arm64)
#   --output DIR     Output directory for artifacts
#   --metadata FILE  Generate build metadata file
#   --cache          Use build cache
#   --dry-run        Show what would be built without building
#   --help, -h       Show help message
#
# Environment Variables:
#   BUILD_VERSION    Version to tag artifacts with
#   BUILD_TOOL       Force specific build tool
#   DOCKER_REGISTRY  Docker registry for pushing images
#   DOCKER_ORG       Docker organization/username
################################################################################

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source dependencies
source "${SCRIPT_DIR}/../utils/common.sh"
source "${SCRIPT_DIR}/../utils/logger.sh"
source "${SCRIPT_DIR}/../utils/validators.sh"

# =============================================================================
# Script Configuration
# =============================================================================
BUILD_VERSION="${BUILD_VERSION:-}"
BUILD_TOOL="${BUILD_TOOL:-auto}"
DOCKER_REGISTRY="${DOCKER_REGISTRY:-}"
DOCKER_ORG="${DOCKER_ORG:-}"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-dist}"
GENERATE_METADATA="${GENERATE_METADATA:-true}"
USE_CACHE="${USE_CACHE:-true}"

# Metadata file
METADATA_FILE="${METADATA_FILE:-build-metadata.json}"

# =============================================================================
# Build Functions
# =============================================================================

# Build Node.js project
# Usage: build_nodejs
build_nodejs() {
    log_info "Building Node.js project..."

    local pkg_manager="npm"

    # Detect package manager
    if [[ -f "${PROJECT_ROOT}/yarn.lock" ]]; then
        pkg_manager="yarn"
    elif [[ -f "${PROJECT_ROOT}/pnpm-lock.yaml" ]]; then
        pkg_manager="pnpm"
    fi

    log_info "Using package manager: ${pkg_manager}"

    # Install dependencies
    log_info "Installing dependencies..."
    case "${pkg_manager}" in
        npm)
            if [[ "${USE_CACHE}" != "true" ]]; then
                run_cmd npm ci --prefer-offline || npm install
            else
                run_cmd npm ci
            fi
            ;;
        yarn)
            run_cmd yarn install --frozen-lockfile
            ;;
        pnpm)
            run_cmd pnpm install --frozen-lockfile
            ;;
    esac

    # Build project
    log_info "Building project..."
    if grep -q '"build"' "${PROJECT_ROOT}/package.json"; then
        run_cmd ${pkg_manager} run build
    else
        log_warn "No build script found in package.json"
    fi

    # Create output directory
    ensure_dir "${ARTIFACTS_DIR}"

    # Copy build artifacts
    if [[ -d "${PROJECT_ROOT}/dist" ]]; then
        log_info "Copying build artifacts to ${ARTIFACTS_DIR}..."
        cp -r "${PROJECT_ROOT}/dist/"* "${ARTIFACTS_DIR}/"
    fi

    # Inject version if provided
    if [[ -n "${BUILD_VERSION}" ]]; then
        log_info "Injecting version: ${BUILD_VERSION}"
        echo "${BUILD_VERSION}" > "${ARTIFACTS_DIR}/version.txt"
    fi

    log_success "Node.js build complete"
    return 0
}

# Build Python project
# Usage: build_python
build_python() {
    log_info "Building Python project..."

    # Create output directory
    ensure_dir "${ARTIFACTS_DIR}"

    # Check build system
    if [[ -f "${PROJECT_ROOT}/pyproject.toml" ]]; then
        # Modern Python packaging (PEP 517)
        if check_command build; then
            log_info "Building with python -m build..."
            run_cmd python -m build --outdir "${ARTIFACTS_DIR}"
        else
            log_warn "python-build not found. Install with: pip install build"
            return "${EXIT_ERROR_MISSING_DEPS}"
        fi
    elif [[ -f "${PROJECT_ROOT}/setup.py" ]]; then
        # Legacy setup.py
        log_info "Building with setup.py..."
        run_cmd python setup.py sdist bdist_wheel -d "${ARTIFACTS_DIR}"
    else
        log_warn "No build configuration found (no pyproject.toml or setup.py)"
        log_info "Creating source distribution..."

        # Create a simple source archive
        local archive_name="${PROJECT_NAME:-project}-${BUILD_VERSION:-dev}.tar.gz"

        run_cmd tar -czf "${ARTIFACTS_DIR}/${archive_name}" \
            --exclude='.git' \
            --exclude='__pycache__' \
            --exclude='*.pyc' \
            --exclude='.venv' \
            --exclude='venv' \
            --exclude="${ARTIFACTS_DIR}" \
            .
    fi

    # Inject version
    if [[ -n "${BUILD_VERSION}" ]]; then
        log_info "Injecting version: ${BUILD_VERSION}"
        echo "${BUILD_VERSION}" > "${ARTIFACTS_DIR}/version.txt"
    fi

    log_success "Python build complete"
    return 0
}

# Build Go project
# Usage: build_go
build_go() {
    log_info "Building Go project..."

    local go_cmd="go"
    local build_args=()

    if ! check_command "${go_cmd}"; then
        log_error "Go not found"
        return "${EXIT_ERROR_MISSING_DEPS}"
    fi

    # Create output directory
    ensure_dir "${ARTIFACTS_DIR}"

    # Get project name
    local project_name="${PROJECT_NAME:-$(basename "${PROJECT_ROOT}")}"
    local output_path="${ARTIFACTS_DIR}/${project_name}"

    # Determine target OS and architecture
    local goos="${GOOS:-$(detect_os)}"
    local goarch="${GOARCH:-amd64}"

    # Handle OS naming
    case "${goos}" in
        macos) goos="darwin" ;;
        windows) goos="windows" ;;
        linux) goos="linux" ;;
    esac

    log_info "Building for ${goos}/${goarch}"

    # Build arguments
    build_args+=("-o")
    build_args+=("${output_path}")
    build_args+=("-ldflags=-s -w")

    # Inject version via ldflags
    if [[ -n "${BUILD_VERSION}" ]]; then
        log_info "Injecting version: ${BUILD_VERSION}"
        build_args+=("-ldflags=-X main.version=${BUILD_VERSION}")
    fi

    log_cmd "${go_cmd} build" "${build_args[@]}"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY-RUN] Would build: ${go_cmd} build ${build_args[*]}"
        return 0
    fi

    # Set GOOS and GOARCH for cross-compilation
    GOOS="${goos}" GOARCH="${goarch}" ${go_cmd} build "${build_args[@]}"

    # Generate version file
    if [[ -n "${BUILD_VERSION}" ]]; then
        echo "${BUILD_VERSION}" > "${ARTIFACTS_DIR}/version.txt"
    fi

    log_success "Go build complete: ${output_path}"
    return 0
}

# Build Maven project
# Usage: build_maven
build_maven() {
    log_info "Building Maven project..."

    local mvn_cmd="mvn"

    if ! check_command "${mvn_cmd}"; then
        log_error "Maven not found"
        return "${EXIT_ERROR_MISSING_DEPS}"
    fi

    # Inject version if provided
    if [[ -n "${BUILD_VERSION}" ]]; then
        log_info "Setting version: ${BUILD_VERSION}"
        run_cmd ${mvn_cmd} versions:set -DnewVersion="${BUILD_VERSION}"
    fi

    log_info "Running Maven build..."
    log_cmd "${mvn_cmd} clean package"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY-RUN] Would run: ${mvn_cmd} clean package"
        return 0
    fi

    if ! ${mvn_cmd} clean package; then
        log_error "Maven build failed"
        return "${EXIT_ERROR_BUILD}"
    fi

    # Create output directory and copy artifacts
    ensure_dir "${ARTIFACTS_DIR}"
    find target -name "*.jar" -not -name "*-sources.jar" -exec cp {} "${ARTIFACTS_DIR}/" \;

    # Generate version file
    if [[ -n "${BUILD_VERSION}" ]]; then
        echo "${BUILD_VERSION}" > "${ARTIFACTS_DIR}/version.txt"
    fi

    log_success "Maven build complete"
    return 0
}

# Build Gradle project
# Usage: build_gradle
build_gradle() {
    log_info "Building Gradle project..."

    local gradle_cmd="./gradlew"

    if [[ ! -f "${gradle_cmd}" ]] && check_command gradle; then
        gradle_cmd="gradle"
    fi

    log_info "Running Gradle build..."
    log_cmd "${gradle_cmd} clean build"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY-RUN] Would run: ${gradle_cmd} clean build"
        return 0
    fi

    if ! ${gradle_cmd} clean build; then
        log_error "Gradle build failed"
        return "${EXIT_ERROR_BUILD}"
    fi

    # Create output directory and copy artifacts
    ensure_dir "${ARTIFACTS_DIR}"
    find build -name "*.jar" -not -name "*-sources.jar" -exec cp {} "${ARTIFACTS_DIR}/" \;

    # Generate version file
    if [[ -n "${BUILD_VERSION}" ]]; then
        echo "${BUILD_VERSION}" > "${ARTIFACTS_DIR}/version.txt"
    fi

    log_success "Gradle build complete"
    return 0
}

# Build Docker image
# Usage: build_docker [platform]
build_docker() {
    local platform="${1:-}"

    log_info "Building Docker image..."

    if ! check_docker; then
        return "${EXIT_ERROR_MISSING_DEPS}"
    fi

    local dockerfile="${DOCKERFILE:-Dockerfile}"
    local context="${DOCKER_CONTEXT:-.}"
    local target_stage="${TARGET_STAGE:-}"
    local build_args=()

    # Check for Dockerfile
    if [[ ! -f "${dockerfile}" ]]; then
        log_error "Dockerfile not found: ${dockerfile}"
        return "${EXIT_ERROR_CONFIG}"
    fi

    # Get image name
    local image_name="${IMAGE_NAME:-${PROJECT_NAME:-app}}"
    local version_tag="${BUILD_VERSION:-latest}"
    local full_image="${image_name}:${version_tag}"

    # Add registry if specified
    if [[ -n "${DOCKER_REGISTRY}" ]]; then
        full_image="${DOCKER_REGISTRY}/${full_image}"
    fi

    # Add organization if specified
    if [[ -n "${DOCKER_ORG}" ]]; then
        full_image="${DOCKER_ORG}/${image_name}:${version_tag}"
        if [[ -n "${DOCKER_REGISTRY}" ]]; then
            full_image="${DOCKER_REGISTRY}/${full_image}"
        fi
    fi

    log_info "Building image: ${full_image}"

    # Build Docker arguments
    build_args+=("-f")
    build_args+=("${dockerfile}")
    build_args+=("-t")
    build_args+=("${full_image}")

    # Multi-platform build
    if [[ -n "${platform}" ]]; then
        build_args+=("--platform=${platform}")
    fi

    # Build cache
    if [[ "${USE_CACHE}" == "true" ]]; then
        build_args+=("--cache-from")
        build_args+=("${full_image}")
    fi

    # Target stage
    if [[ -n "${target_stage}" ]]; then
        build_args+=("--target")
        build_args+=("${target_stage}")
    fi

    # Build args from environment
    if [[ -n "${BUILD_ARGS:-}" ]]; then
        IFS=',' read -ra args <<< "${BUILD_ARGS}"
        for arg in "${args[@]}"; do
            build_args+=("--build-arg")
            build_args+=("${arg}")
        done
    fi

    # Version build arg
    if [[ -n "${BUILD_VERSION}" ]]; then
        build_args+=("--build-arg")
        build_args+=("VERSION=${BUILD_VERSION}")
    fi

    build_args+=("${context}")

    log_cmd "docker build" "${build_args[@]}"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY-RUN] Would build: docker build ${build_args[*]}"
        return 0
    fi

    # Build image
    if ! docker build "${build_args[@]}"; then
        log_error "Docker build failed"
        return "${EXIT_ERROR_BUILD}"
    fi

    # Tag with 'latest' if this is a versioned build
    if [[ "${version_tag}" != "latest" ]]; then
        local latest_image
        latest_image="${full_image/:${version_tag}/:latest}"
        docker tag "${full_image}" "${latest_image}"
        log_info "Tagged as: ${latest_image}"
    fi

    # Save image info
    echo "${full_image}" > "${ARTIFACTS_DIR}/docker-image.txt"
    echo "${BUILD_VERSION:-latest}" > "${ARTIFACTS_DIR}/version.txt"

    log_success "Docker build complete: ${full_image}"
    return 0
}

# Generate build metadata
# Usage: generate_metadata
generate_metadata() {
    if [[ "${GENERATE_METADATA}" != "true" ]]; then
        return 0
    fi

    log_info "Generating build metadata..."

    local metadata="{"
    metadata+="\"version\":\"${BUILD_VERSION:-unknown}\","
    metadata+="\"timestamp\":\"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\","
    metadata+="\"project_type\":\"$(get_project_type)\","
    metadata+="\"project_root\":\"${PROJECT_ROOT}\","
    metadata+="\"git_commit\":\"$(git -C "${PROJECT_ROOT}" rev-parse HEAD 2>/dev/null || echo "unknown")\","
    metadata+="\"git_branch\":\"$(git -C "${PROJECT_ROOT}" branch --show-current 2>/dev/null || echo "unknown")\","
    metadata+="\"build_os\":\"$(detect_os)\","
    metadata+="\"artifacts_dir\":\"${ARTIFACTS_DIR}\""

    # Add Docker image info if exists
    if [[ -f "${ARTIFACTS_DIR}/docker-image.txt" ]]; then
        metadata+=",\"docker_image\":\"$(cat "${ARTIFACTS_DIR}/docker-image.txt")\""
    fi

    metadata+="}"

    echo "${metadata}" | jq '.' 2>/dev/null || echo "${metadata}" > "${ARTIFACTS_DIR}/${METADATA_FILE}"

    log_success "Metadata generated: ${ARTIFACTS_DIR}/${METADATA_FILE}"
    return 0
}

# =============================================================================
# Main Build Function
# =============================================================================

# Main build logic
# Usage: main_build [--docker] [--platform PLATFORM]
main_build() {
    local build_docker_image=false
    local docker_platform=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --docker)
                build_docker_image=true
                shift
                ;;
            --platform)
                docker_platform="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    log_section "Starting Build"

    # Get version
    if [[ -z "${BUILD_VERSION}" ]]; then
        BUILD_VERSION="$(get_version)"
        log_info "Detected version: ${BUILD_VERSION}"
    fi

    # Detect project type
    local project_type
    project_type="$(get_project_type)"

    log_info "Project type: ${project_type}"
    log_info "Version: ${BUILD_VERSION}"
    log_info "Artifacts directory: ${ARTIFACTS_DIR}"

    # Create artifacts directory
    ensure_dir "${ARTIFACTS_DIR}"

    # Build based on project type or Docker flag
    local exit_code=0

    if [[ "${build_docker_image}" == "true" ]]; then
        build_docker "${docker_platform}" || exit_code=$?
    else
        case "${project_type}" in
            nodejs)
                build_nodejs || exit_code=$?
                ;;

            python)
                build_python || exit_code=$?
                ;;

            go)
                build_go || exit_code=$?
                ;;

            maven)
                build_maven || exit_code=$?
                ;;

            gradle)
                build_gradle || exit_code=$?
                ;;

            docker)
                build_docker "${docker_platform}" || exit_code=$?
                ;;

            unknown)
                log_warn "Could not detect project type"
                log_warn "Creating generic source archive..."
                run_cmd tar -czf "${ARTIFACTS_DIR}/project-${BUILD_VERSION:-dev}.tar.gz" \
                    --exclude='.git' \
                    --exclude="${ARTIFACTS_DIR}" \
                    .
                ;;

            *)
                log_error "Unsupported project type: ${project_type}"
                return "${EXIT_ERROR_CONFIG}"
                ;;
        esac
    fi

    if [[ ${exit_code} -ne 0 ]]; then
        return ${exit_code}
    fi

    # Generate metadata
    generate_metadata

    log_section "Build Complete"
    log_info "Artifacts in: ${ARTIFACTS_DIR}/"

    # List artifacts
    if [[ "${DRY_RUN}" != "true" ]]; then
        ls -lh "${ARTIFACTS_DIR}" || true
    fi

    return 0
}

# =============================================================================
# Help and Usage
# =============================================================================

show_help() {
    cat << EOF
Usage: $0 [options]

Build project artifacts with version injection.

Options:
  --version VER       Set build version
  --docker            Build Docker image
  --platform PLAT     Target platform (e.g., linux/amd64,linux/arm64)
  --output DIR        Output directory for artifacts
  --metadata FILE     Generate build metadata file
  --cache             Use build cache
  --dry-run           Show what would be built without building
  --help, -h          Show this help message

Supported Languages:
  - Node.js: npm, yarn, pnpm
  - Python: setuptools, hatch, poetry
  - Go: go build
  - Java: Maven, Gradle
  - Docker: docker build (multi-stage, multi-platform)

Environment Variables:
  BUILD_VERSION       Version to tag artifacts with
  BUILD_TOOL          Force specific build tool
  DOCKER_REGISTRY     Docker registry for pushing images
  DOCKER_ORG          Docker organization/username
  ARTIFACTS_DIR       Output directory (default: dist)
  GENERATE_METADATA   Generate metadata file (default: true)
  USE_CACHE           Use build cache (default: true)

Examples:
  # Build with auto-detection
  $0

  # Build with specific version
  $0 --version 1.0.0

  # Build Docker image
  $0 --docker

  # Build for multiple platforms
  $0 --docker --platform linux/amd64,linux/arm64

EOF
}

# =============================================================================
# Main Script Entry Point
# =============================================================================

main() {
    local show_help=false

    # Parse command-line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                show_help=true
                shift
                ;;
            --version)
                export BUILD_VERSION="$2"
                shift 2
                ;;
            --docker)
                # Pass to main_build
                set -- "$@" --docker
                shift
                ;;
            --platform)
                # Pass to main_build
                set -- "$@" --platform "$2"
                shift 2
                ;;
            --output)
                export ARTIFACTS_DIR="$2"
                shift 2
                ;;
            --metadata)
                export METADATA_FILE="$2"
                shift 2
                ;;
            --cache)
                export USE_CACHE="true"
                shift
                ;;
            --dry-run)
                export DRY_RUN="true"
                shift
                ;;
            --config)
                export CONFIG_FILE="$2"
                shift 2
                ;;
            --log-level)
                export LOG_LEVEL="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                exit "${EXIT_ERROR_GENERAL}"
                ;;
        esac
    done

    if [[ "${show_help}" == "true" ]]; then
        show_help
        exit "${EXIT_SUCCESS}"
    fi

    # Change to project root
    cd "${PROJECT_ROOT}"

    # Run main build function
    main_build "$@"
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
