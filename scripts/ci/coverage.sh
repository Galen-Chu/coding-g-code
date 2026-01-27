#!/usr/bin/env bash
################################################################################
# CI/CD Toolkit - Coverage Script
# =============================================================================
# Generates code coverage reports for various project types.
#
# Usage:
#   ./scripts/ci/coverage.sh [options]
#
# Options:
#   --format FORMAT Output format (lcov, cobertura, html, json)
#   --threshold N   Minimum coverage threshold percentage (0-100)
#   --output DIR    Output directory for reports
#   --merge         Merge multiple coverage sources
#   --fail-on-low   Exit with error if below threshold
#   --dry-run       Show what would be done without running
#   --help, -h      Show help message
#
# Environment Variables:
#   COVERAGE_ENABLED  Enable coverage reporting (default: true)
#   COVERAGE_THRESHOLD Minimum coverage percentage (default: 80)
#   COVERAGE_DIR      Output directory (default: coverage)
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
COVERAGE_ENABLED="${COVERAGE_ENABLED:-true}"
COVERAGE_THRESHOLD="${COVERAGE_THRESHOLD:-80}"
COVERAGE_DIR="${COVERAGE_DIR:-coverage}"
FAIL_ON_LOW="${FAIL_ON_LOW:-true}"
COVERAGE_FORMAT="${COVERAGE_FORMAT:-lcov}"

# Exit codes
EXIT_BELOW_THRESHOLD=10

# =============================================================================
# Coverage Report Generation
# =============================================================================

# Generate coverage for Node.js projects
# Usage: coverage_nodejs
coverage_nodejs() {
    log_info "Generating coverage for Node.js project..."

    # Check if Jest is being used
    if grep -q '"jest"' "${PROJECT_ROOT}/package.json" 2>/dev/null || \
       [[ -f "${PROJECT_ROOT}/jest.config.js" ]] || \
       [[ -f "${PROJECT_ROOT}/jest.config.ts" ]]; then
        coverage_jest
    elif grep -q '"c8"' "${PROJECT_ROOT}/package.json" 2>/dev/null; then
        coverage_c8
    elif grep -q '"nyc"' "${PROJECT_ROOT}/package.json" 2>/dev/null; then
        coverage_nyc
    else
        log_warn "No coverage tool detected for Node.js"
        log_warn "Supported tools: Jest, c8, nyc"
        return "${EXIT_ERROR_MISSING_DEPS}"
    fi
}

# Generate Jest coverage
# Usage: coverage_jest
coverage_jest() {
    local jest_cmd="jest"
    local args=()

    if ! check_command "${jest_cmd}"; then
        if check_command npx; then
            jest_cmd="npx jest"
        else
            log_error "Jest not found"
            return "${EXIT_ERROR_MISSING_DEPS}"
        fi
    fi

    # Build format arguments
    case "${COVERAGE_FORMAT}" in
        lcov)
            args+=("--coverage")
            args+=("--coverageProvider=v8")
            ;;
        html)
            args+=("--coverage")
            args+=("--coverageReporters=html")
            ;;
        json)
            args+=("--coverage")
            args+=("--coverageReporters=json")
            ;;
        *)
            args+=("--coverage")
            ;;
    esac

    log_cmd "${jest_cmd}" "${args[@]}"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY-RUN] Would run: ${jest_cmd} ${args[*]}"
        return 0
    fi

    ensure_dir "${COVERAGE_DIR}"

    if ! ${jest_cmd} "${args[@]}"; then
        log_error "Jest coverage generation failed"
        return "${EXIT_ERROR_GENERAL}"
    fi

    log_success "Jest coverage generated"
    return 0
}

# Generate c8 coverage
# Usage: coverage_c8
coverage_c8() {
    local c8_cmd="c8"

    if ! check_command "${c8_cmd}"; then
        log_error "c8 not found. Install with: npm install -D c8"
        return "${EXIT_ERROR_MISSING_DEPS}"
    fi

    log_cmd "${c8_cmd}"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY-RUN] Would run: ${c8_cmd}"
        return 0
    fi

    if ! ${c8_cmd} report --reporter="${COVERAGE_FORMAT}" --output-dir="${COVERAGE_DIR}"; then
        log_error "c8 coverage generation failed"
        return "${EXIT_ERROR_GENERAL}"
    fi

    log_success "c8 coverage generated"
    return 0
}

# Generate nyc coverage
# Usage: coverage_nyc
coverage_nyc() {
    local nyc_cmd="nyc"

    if ! check_command "${nyc_cmd}"; then
        log_error "nyc not found. Install with: npm install -D nyc"
        return "${EXIT_ERROR_MISSING_DEPS}"
    fi

    log_cmd "${nyc_cmd} report"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY-RUN] Would run: ${nyc_cmd} report"
        return 0
    fi

    if ! ${nyc_cmd} report --reporter="${COVERAGE_FORMAT}" --report-dir="${COVERAGE_DIR}"; then
        log_error "nyc coverage generation failed"
        return "${EXIT_ERROR_GENERAL}"
    fi

    log_success "nyc coverage generated"
    return 0
}

# Generate coverage for Python projects
# Usage: coverage_python
coverage_python() {
    log_info "Generating coverage for Python project..."

    local pytest_cmd="pytest"

    if ! check_command "${pytest_cmd}"; then
        log_error "pytest not found. Install with: pip install pytest pytest-cov"
        return "${EXIT_ERROR_MISSING_DEPS}"
    fi

    ensure_dir "${COVERAGE_DIR}"

    local args=()
    args+=("--cov=.")
    args+=("--cov-report=term")

    # Add format-specific reports
    case "${COVERAGE_FORMAT}" in
        lcov)
            args+=("--cov-report=lcov")
            ;;
        xml|cobertura)
            args+=("--cov-report=xml:${COVERAGE_DIR}/coverage.xml")
            ;;
        html)
            args+=("--cov-report=html:${COVERAGE_DIR}")
            ;;
        json)
            args+=("--cov-report=json:${COVERAGE_DIR}/coverage.json")
            ;;
        *)
            # Generate multiple formats by default
            args+=("--cov-report=xml:${COVERAGE_DIR}/coverage.xml")
            args+=("--cov-report=html:${COVERAGE_DIR}")
            ;;
    esac

    log_cmd "${pytest_cmd}" "${args[@]}"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY-RUN] Would run: ${pytest_cmd} ${args[*]}"
        return 0
    fi

    if ! ${pytest_cmd} "${args[@]}"; then
        log_error "pytest coverage generation failed"
        return "${EXIT_ERROR_GENERAL}"
    fi

    log_success "Python coverage generated"
    return 0
}

# Generate coverage for Go projects
# Usage: coverage_go
coverage_go() {
    log_info "Generating coverage for Go project..."

    local go_cmd="go"

    if ! check_command "${go_cmd}"; then
        log_error "Go not found"
        return "${EXIT_ERROR_MISSING_DEPS}"
    fi

    ensure_dir "${COVERAGE_DIR}"

    local coverage_file="${COVERAGE_DIR}/coverage.out"

    log_cmd "${go_cmd} test -coverprofile=${coverage_file} -covermode=atomic ./..."

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY-RUN] Would run: ${go_cmd} test -coverprofile=${coverage_file} ./..."
        return 0
    fi

    if ! ${go_cmd} test -coverprofile="${coverage_file}" -covermode=atomic ./...; then
        log_error "Go coverage generation failed"
        return "${EXIT_ERROR_GENERAL}"
    fi

    # Generate HTML report
    if ${go_cmd} tool cover -html="${coverage_file}" -o="${COVERAGE_DIR}/coverage.html"; then
        log_success "Go HTML coverage: ${COVERAGE_DIR}/coverage.html"
    fi

    # Convert to lcov if needed
    if [[ "${COVERAGE_FORMAT}" == "lcov" ]] && check_command gocover-cobertura; then
        gocover-cobertura < "${coverage_file}" > "${COVERAGE_DIR}/coverage.xml"
        log_info "Cobertura coverage: ${COVERAGE_DIR}/coverage.xml"
    fi

    log_success "Go coverage generated"
    return 0
}

# Generate coverage for Java/Maven projects
# Usage: coverage_maven
coverage_maven() {
    log_info "Generating coverage for Maven project..."

    local mvn_cmd="mvn"

    if ! check_command "${mvn_cmd}"; then
        log_error "Maven not found"
        return "${EXIT_ERROR_MISSING_DEPS}"
    fi

    log_cmd "${mvn_cmd} jacoco:report"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY-RUN] Would run: ${mvn_cmd} jacoco:report"
        return 0
    fi

    if ! ${mvn_cmd} jacoco:report; then
        log_error "Maven coverage generation failed"
        return "${EXIT_ERROR_GENERAL}"
    fi

    log_success "Maven coverage generated"
    return 0
}

# Generate coverage for Java/Gradle projects
# Usage: coverage_gradle
coverage_gradle() {
    log_info "Generating coverage for Gradle project..."

    local gradle_cmd="./gradlew"

    if [[ ! -f "${gradle_cmd}" ]] && check_command gradle; then
        gradle_cmd="gradle"
    fi

    log_cmd "${gradle_cmd} jacocoTestReport"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY-RUN] Would run: ${gradle_cmd} jacocoTestReport"
        return 0
    fi

    if ! ${gradle_cmd} jacocoTestReport; then
        log_error "Gradle coverage generation failed"
        return "${EXIT_ERROR_GENERAL}"
    fi

    log_success "Gradle coverage generated"
    return 0
}

# =============================================================================
# Coverage Parsing and Threshold Checking
# =============================================================================

# Parse coverage percentage from coverage file
# Usage: get_coverage_percentage
# Outputs: coverage percentage (e.g., "85.5")
get_coverage_percentage() {
    local project_type
    project_type="$(get_project_type)"
    local coverage=0

    case "${project_type}" in
        nodejs)
            if [[ -f "${COVERAGE_DIR}/coverage-summary.json" ]]; then
                coverage=$(jq '.total.lines.pct' "${COVERAGE_DIR}/coverage-summary.json" 2>/dev/null || echo "0")
            fi
            ;;

        python)
            if [[ -f "${COVERAGE_DIR}/coverage.xml" ]]; then
                coverage=$(grep 'line-rate=' "${COVERAGE_DIR}/coverage.xml" | head -1 | sed 's/.*line-rate="\([0-9.]*\)".*/\1/')
                coverage=$(awk "BEGIN {printf \"%.2f\", ${coverage} * 100}")
            fi
            ;;

        go)
            if [[ -f "${COVERAGE_DIR}/coverage.out" ]]; then
                coverage=$(go tool cover -func="${COVERAGE_DIR}/coverage.out" | tail -1 | awk '{print $3}' | sed 's/%//')
            fi
            ;;

        maven|gradle)
            if [[ -f "target/site/jacoco/jacoco.xml" ]] || [[ -f "build/reports/jacoco/test/jacocoTestReport.xml" ]]; then
                local jacoco_xml
                jacoco_xml=$(find "${PROJECT_ROOT}" -name "jacoco.xml" 2>/dev/null | head -1)
                if [[ -n "${jacoco_xml}" ]]; then
                    coverage=$(grep 'type="LINE"' "${jacoco_xml}" | sed 's/.*covered="\([^"]*\)".*missed="\([^"]*\)".*/\1 \2/' | awk '{sum1+=$1; sum2+=$2} END {printf "%.2f", (sum1/(sum1+sum2))*100}')
                fi
            fi
            ;;
    esac

    echo "${coverage}"
}

# Check if coverage meets threshold
# Usage: check_coverage_threshold
# Returns: 0 if meets threshold, 1 if below
check_coverage_threshold() {
    local coverage
    coverage="$(get_coverage_percentage)"

    log_info "Coverage: ${coverage}%"
    log_info "Threshold: ${COVERAGE_THRESHOLD}%"

    # Use awk for floating point comparison
    local result
    result=$(awk "BEGIN {print (${coverage} >= ${COVERAGE_THRESHOLD}) ? 0 : 1}")

    if [[ ${result} -eq 1 ]]; then
        log_warn "Coverage (${coverage}%) is below threshold (${COVERAGE_THRESHOLD}%)"
        if [[ "${FAIL_ON_LOW}" == "true" ]]; then
            return "${EXIT_BELOW_THRESHOLD}"
        fi
    else
        log_success "Coverage (${coverage}%) meets threshold (${COVERAGE_THRESHOLD}%)"
    fi

    return 0
}

# Merge multiple coverage sources
# Usage: merge_coverage
merge_coverage() {
    log_info "Merging coverage sources..."

    # This is a placeholder for coverage merging logic
    # In practice, you would use tools like:
    # - Node.js: npx combine-coverage
    # - Python: coverage combine
    # - Multi-language: coveragepy (with plugins)

    log_warn "Coverage merging not implemented yet"
    return 0
}

# =============================================================================
# Main Coverage Function
# =============================================================================

# Main coverage generation logic
# Usage: main_coverage
main_coverage() {
    log_section "Generating Coverage Reports"

    # Check if coverage is enabled
    if [[ "${COVERAGE_ENABLED}" != "true" ]]; then
        log_info "Coverage reporting is disabled (COVERAGE_ENABLED=${COVERAGE_ENABLED})"
        return 0
    fi

    # Detect project type
    local project_type
    project_type="$(get_project_type)"

    log_info "Project type: ${project_type}"
    log_info "Output format: ${COVERAGE_FORMAT}"
    log_info "Output directory: ${COVERAGE_DIR}"

    # Create output directory
    ensure_dir "${COVERAGE_DIR}"

    # Generate coverage based on project type
    local exit_code=0

    case "${project_type}" in
        nodejs)
            coverage_nodejs || exit_code=$?
            ;;

        python)
            coverage_python || exit_code=$?
            ;;

        go)
            coverage_go || exit_code=$?
            ;;

        maven)
            coverage_maven || exit_code=$?
            ;;

        gradle)
            coverage_gradle || exit_code=$?
            ;;

        unknown)
            log_warn "Could not detect project type"
            log_warn "Please set PROJECT_TYPE environment variable"
            return "${EXIT_ERROR_CONFIG}"
            ;;

        *)
            log_error "Unsupported project type: ${project_type}"
            return "${EXIT_ERROR_CONFIG}"
            ;;
    esac

    if [[ ${exit_code} -ne 0 ]]; then
        return ${exit_code}
    fi

    # Check coverage threshold
    if [[ "${FAIL_ON_LOW}" == "true" ]] || [[ -n "${COVERAGE_THRESHOLD:-}" ]]; then
        check_coverage_threshold || exit_code=$?
    fi

    if [[ ${exit_code} -eq 0 ]]; then
        log_section "Coverage Generation Complete"
        log_info "Reports generated in: ${COVERAGE_DIR}/"
        return 0
    fi

    return ${exit_code}
}

# =============================================================================
# Help and Usage
# =============================================================================

show_help() {
    cat << EOF
Usage: $0 [options]

Generate code coverage reports for various project types.

Options:
  --format FORMAT     Output format (lcov, cobertura, html, json)
  --threshold N       Minimum coverage threshold percentage (0-100)
  --output DIR        Output directory for reports
  --merge             Merge multiple coverage sources
  --fail-on-low       Exit with error if below threshold
  --dry-run           Show what would be done without running
  --help, -h          Show this help message

Supported Languages:
  - Node.js: Jest, c8, nyc
  - Python: pytest-cov
  - Go: go test -cover
  - Java (Maven): JaCoCo
  - Java (Gradle): JaCoCo

Environment Variables:
  COVERAGE_ENABLED    Enable coverage reporting (default: true)
  COVERAGE_THRESHOLD  Minimum coverage percentage (default: 80)
  COVERAGE_DIR        Output directory (default: coverage)
  FAIL_ON_LOW         Exit with error if below threshold (default: true)

Examples:
  # Generate coverage with default settings
  $0

  # Generate HTML coverage
  $0 --format html

  # Set custom threshold
  $0 --threshold 90

  # Generate coverage without failing on low coverage
  $0 --fail-on-low=false

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
            --format)
                export COVERAGE_FORMAT="$2"
                shift 2
                ;;
            --threshold)
                export COVERAGE_THRESHOLD="$2"
                shift 2
                ;;
            --output)
                export COVERAGE_DIR="$2"
                shift 2
                ;;
            --merge)
                export MERGE_COVERAGE="true"
                shift
                ;;
            --fail-on-low)
                export FAIL_ON_LOW="$2"
                shift 2
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

    # Run main coverage function
    main_coverage
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
