#!/bin/bash
#
# upload_test_results.sh
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Harery
#
# DESCRIPTION:
#   Upload local Docker test results to GitHub for comparison with CI results
#   Pushes results as workflow artifacts or to a results branch
#
# USAGE:
#   ./tests/upload_test_results.sh [OPTIONS]
#
# OPTIONS:
#   --results FILE     Test results JSON file to upload
#   --branch NAME      Branch to push results to (default: test-results)
#   --message MSG      Commit message (default: auto-generated)
#   --dry-run          Show what would be uploaded without executing

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Defaults
RESULTS_FILE=""
RESULTS_BRANCH="test-results"
COMMIT_MESSAGE=""
DRY_RUN=false

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

show_help() {
    cat << 'EOF'
Usage: upload_test_results.sh [OPTIONS]

Upload local Docker test results to GitHub for comparison.

OPTIONS:
    --results FILE     Test results JSON file to upload
    --branch NAME      Branch to push results to (default: test-results)
    --message MSG      Commit message (default: auto-generated)
    --dry-run          Show what would be uploaded without executing
    --help            Show this help

EXAMPLES:
    # Upload latest results
    ./upload_test_results.sh --results tests/results/local-docker-ubuntu-24.04-20231228.json

    # Upload with custom branch
    ./upload_test_results.sh --results results.json --branch my-test-results

EOF
}

# Check if gh CLI is available
check_gh_cli() {
    if ! command -v gh &>/dev/null; then
        log_error "GitHub CLI (gh) is not installed"
        log_info "Install from: https://cli.github.com/"
        exit 1
    fi

    # Check if authenticated
    if ! gh auth status &>/dev/null; then
        log_error "Not authenticated with GitHub CLI"
        log_info "Run: gh auth login"
        exit 1
    fi
}

# Get repository info
get_repo_info() {
    local remote_url
    remote_url=$(git -C "$PROJECT_DIR" config --get remote.origin.url 2>/dev/null || echo "")

    if [[ -z "$remote_url" ]]; then
        log_error "No git remote found"
        exit 1
    fi

    # Extract owner/repo from URL
    if [[ "$remote_url" =~ git@github.com:([^/]+)/(.+\.git) ]]; then
        echo "${BASH_REMATCH[1]}/${BASH_REMATCH[2]%.git}"
    elif [[ "$remote_url" =~ https://github.com/([^/]+)/(.+\.git) ]]; then
        echo "${BASH_REMATCH[1]}/${BASH_REMATCH[2]%.git}"
    else
        log_error "Could not parse repository URL: $remote_url"
        exit 1
    fi
}

# Upload results to branch
upload_to_branch() {
    local results_file="$1"
    local branch="$2"
    local message="$3"

    local repo
    repo=$(get_repo_info)

    log_info "Repository: $repo"
    log_info "Branch: $branch"

    if [[ "$DRY_RUN" == true ]]; then
        log_info "Would upload: $results_file"
        log_info "To branch: $branch"
        log_info "With message: $message"
        return 0
    fi

    # Create temporary directory for the branch
    local temp_dir
    temp_dir=$(mktemp -d)

    # Clone or fetch the results branch
    if git ls-remote --heads origin "$branch" | grep -q "$branch"; then
        log_info "Fetching existing results branch..."
        git clone --depth 1 --branch "$branch" "origin" "$temp_dir" 2>/dev/null || {
            cd "$temp_dir"
            git init
            git remote add origin "https://github.com/$repo"
            git fetch origin "$branch"
            git checkout "$branch"
            cd - > /dev/null
        }
    else
        log_info "Creating new results branch..."
        git clone --depth 1 "https://github.com/$repo" "$temp_dir"
        cd "$temp_dir"
        git checkout --orphan "$branch"
        cd - > /dev/null
    fi

    # Copy results file
    local dest_file="$temp_dir/$(basename "$results_file")"
    cp "$results_file" "$dest_file"

    # Commit and push
    cd "$temp_dir"
    git add "$(basename "$results_file")"

    # Check if there are changes to commit
    if git diff --staged --quiet; then
        log_warning "No changes to commit (file already exists with same content)"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 0
    fi

    git config user.name "SYSMAINT Test Bot"
    git config user.email "sysmaint-bot@harery.com"

    git commit -m "$message"
    git push origin "$branch" || {
        log_error "Failed to push to branch $branch"
        cd - > /dev/null
        rm -rf "$temp_dir"
        exit 1
    }

    cd - > /dev/null
    rm -rf "$temp_dir"

    log_success "Results uploaded successfully"
}

# Upload as GitHub artifact (for workflow use)
upload_as_artifact() {
    local results_file="$1"

    if [[ -z "$GITHUB_RUN_ID" ]]; then
        log_warning "Not running in GitHub Actions - artifact upload skipped"
        return 0
    fi

    log_info "Uploading as GitHub Actions artifact..."

    if [[ "$DRY_RUN" == true ]]; then
        log_info "Would upload artifact: $results_file"
        return 0
    fi

    # Use gh to upload artifact
    local artifact_name="test-results-$(date +%Y%m%d-%H%M%S)"
    gh run upload "$GITHUB_RUN_ID" \
        --name "$artifact_name" \
        --"$results_file" || {
        log_warning "Failed to upload as artifact (may not be supported)"
    }
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --results)
            RESULTS_FILE="$2"
            shift 2
            ;;
        --branch)
            RESULTS_BRANCH="$2"
            shift 2
            ;;
        --message)
            COMMIT_MESSAGE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validate inputs
if [[ -z "$RESULTS_FILE" ]]; then
    # Try to find latest results file
    RESULTS_FILE=$(find "$PROJECT_DIR/tests/results" -name "*.json" -type f 2>/dev/null | sort -r | head -n1)

    if [[ -z "$RESULTS_FILE" ]]; then
        log_error "No results file specified and none found in tests/results/"
        show_help
        exit 1
    fi

    log_info "Auto-detected results file: $RESULTS_FILE"
fi

if [[ ! -f "$RESULTS_FILE" ]]; then
    log_error "Results file not found: $RESULTS_FILE"
    exit 1
fi

# Generate commit message if not provided
if [[ -z "$COMMIT_MESSAGE" ]]; then
    local os_name os_version timestamp
    os_name=$(jq -r '.environment.os_name // "unknown"' "$RESULTS_FILE")
    os_version=$(jq -r '.environment.os_version // "unknown"' "$RESULTS_FILE")
    timestamp=$(jq -r '.timestamp // "unknown"' "$RESULTS_FILE")

    COMMIT_MESSAGE="Test results: $os_name $os_version ($timestamp)"
fi

# Check prerequisites
check_gh_cli

# Upload
log_info "Uploading test results..."
log_info "Source: $RESULTS_FILE"

# Upload to branch
upload_to_branch "$RESULTS_FILE" "$RESULTS_BRANCH" "$COMMIT_MESSAGE"

# Also try artifact upload if in GitHub Actions
upload_as_artifact "$RESULTS_FILE"

# Summary
echo ""
echo "========================================"
echo "Upload Summary"
echo "========================================"
echo "Source:   $RESULTS_FILE"
echo "Branch:   $RESULTS_BRANCH"
echo "Message:  $COMMIT_MESSAGE"
echo ""
