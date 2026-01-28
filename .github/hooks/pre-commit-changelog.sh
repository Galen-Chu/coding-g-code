#!/usr/bin/env bash
################################################################################
# CI/CD Toolkit - Pre-commit Changelog Check Hook
# =============================================================================
# Validates that CHANGELOG.md has been updated when required.
#
# This hook should be installed as .git/hooks/pre-commit
# It checks if the commit requires a CHANGELOG update and prompts if missing.
#
# Installation:
#   cp .github/hooks/pre-commit-changelog.sh .git/hooks/pre-commit
#   chmod +x .git/hooks/pre-commit
################################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Get the project root
PROJECT_ROOT="$(git rev-parse --show-toplevel)"

# CHANGELOG file
CHANGELOG_FILE="${PROJECT_ROOT}/CHANGELOG.md"

# Check if CHANGELOG exists
if [[ ! -f "${CHANGELOG_FILE}" ]]; then
    echo -e "${YELLOW}⚠ CHANGELOG.md not found. Consider adding it.${NC}"
    exit 0
fi

# Get staged files (excluding merges)
STAGED_FILES="$(git diff --cached --name-only --diff-filter=ACM | grep -v '^CHANGELOG.md$' || true)"

# If no files staged (except CHANGELOG), skip check
if [[ -z "${STAGED_FILES}" ]]; then
    exit 0
fi

# Check if CHANGELOG is staged
CHANGELOG_STAGED="$(git diff --cached --name-only | grep '^CHANGELOG.md$' || true)"

# Get commit message (if available)
COMMIT_MSG_FILE="$(git rev-parse --git-dir)/COMMIT_EDITMSG"
if [[ -f "${COMMIT_MSG_FILE}" ]]; then
    COMMIT_MSG="$(cat "${COMMIT_MSG_FILE}")"
else
    COMMIT_MSG=""
fi

# Determine if CHANGELOG update is required
requires_changelog() {
    local commit_type="$1"

    # Check commit type
    case "${commit_type}" in
        feat*|fix*|perf*|revert*)
            return 0  # Requires CHANGELOG
            ;;
        docs*|style*|test*|refactor*|chore*|ci*)
            return 1  # Doesn't require CHANGELOG
            ;;
        *)
            # Unknown type - check staged files
            return 0  # Conservative: require CHANGELOG
            ;;
    esac
}

# Extract commit type from message
if [[ "${COMMIT_MSG}" =~ ^([a-z]+)(\(.+\))?: ]]; then
    COMMIT_TYPE="${BASH_REMATCH[1]}"
else
    COMMIT_TYPE=""
fi

# Check if CHANGELOG update is required
if requires_changelog "${COMMIT_TYPE}"; then
    if [[ -z "${CHANGELOG_STAGED}" ]]; then
        echo ""
        echo -e "${YELLOW}⚠️  CHANGELOG.md not updated${NC}"
        echo ""
        echo "This commit appears to add user-facing changes."
        echo "Please update CHANGELOG.md to document these changes."
        echo ""
        echo "Quick update:"
        echo "  bash scripts/utils/update-changelog.sh"
        echo ""
        echo "Then stage the CHANGELOG:"
        echo "  git add CHANGELOG.md"
        echo ""
        echo "Or bypass with: git commit --no-verify"
        echo ""

        # Optional: Auto-run the changelog updater
        read -rp "Would you like to update CHANGELOG now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if bash "${PROJECT_ROOT}/scripts/utils/update-changelog.sh"; then
                git add "${CHANGELOG_FILE}"
                echo -e "${GREEN}✓ CHANGELOG.md updated and staged${NC}"
                exit 0
            fi
        fi

        exit 1
    fi
fi

exit 0
