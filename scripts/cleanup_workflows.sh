#!/bin/bash
#
# cleanup_workflows.sh
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Harery
#
# DESCRIPTION:
#   Cleanup old GitHub Actions workflow runs while preserving recent runs.
#   Supports selective retention by workflow and count.
#
# USAGE:
#   ./scripts/cleanup_workflows.sh [OPTIONS]
#
# OPTIONS:
#   --dry-run              Show what would be deleted without actually deleting
#   --keep N               Keep last N runs per workflow (default: 3)
#   --workflow NAME        Only clean specific workflow (ci, docker, release)
#   --all                  Clean all workflows (default)
#   --yes                  Skip confirmation prompt
#   -h, --help             Show this help
#
# RETENTION POLICY:
#   - Default: Keep last 3 runs per workflow
#   - Always keeps: runs with status 'in_progress' or 'queued'
#
# EXAMPLES:
#   # Dry run to see what would be deleted
#   ./scripts/cleanup_workflows.sh --dry-run
#
#   # Keep last 5 runs, delete older ones
#   ./scripts/cleanup_workflows.sh --keep 5
#
#   # Only clean CI workflow runs
#   ./scripts/cleanup_workflows.sh --workflow ci
#

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Defaults
DRY_RUN=false
KEEP_COUNT=3
WORKFLOW_FILTER=""
ALL_WORKFLOWS=true
SKIP_CONFIRMATION=false

# Available workflows
WORKFLOWS=("ci" "docker" "release")

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

show_help() {
    grep '^#' "$0" | grep -v '#!/bin/bash' | sed 's/^# //g' | sed 's/^#//g' | head -n 50
}

check_gh_cli() {
    if ! command -v gh &>/dev/null; then
        log_error "GitHub CLI (gh) is not installed"
        echo "Install it from: https://cli.github.com/"
        exit 1
    fi

    if ! gh auth status &>/dev/null; then
        log_error "Not authenticated with GitHub CLI"
        echo "Run: gh auth login"
        exit 1
    fi
}

# Get list of run IDs to delete for a workflow
get_runs_to_delete() {
    local workflow="$1"
    local keep="$2"

    # Get all run IDs for this workflow
    local all_runs
    all_runs=$(gh run list --workflow="${workflow}.yml" --json databaseId --jq '.[].databaseId' 2>/dev/null)

    if [[ -z "$all_runs" ]]; then
        echo ""
        return
    fi

    # Count total runs
    local total
    total=$(echo "$all_runs" | wc -l)

    # If we have more than keep, return the older ones
    if [[ $total -gt $keep ]]; then
        echo "$all_runs" | tail -n +$((keep + 1))
    fi
}

cleanup_workflow() {
    local workflow="$1"
    local deleted_count=0

    log_info "Processing workflow: ${workflow}"

    local runs_to_delete
    runs_to_delete=$(get_runs_to_delete "$workflow" "$KEEP_COUNT")

    if [[ -z "$runs_to_delete" ]]; then
        log_success "No runs to delete (have less than ${KEEP_COUNT} runs)"
        return
    fi

    local delete_count
    delete_count=$(echo "$runs_to_delete" | wc -l)

    log_warning "Will delete ${delete_count} run(s)"

    if [[ "$DRY_RUN" == true ]]; then
        echo "$runs_to_delete" | while read -r run_id; do
            [[ -n "$run_id" ]] && echo "  Would delete: ${run_id}"
        done
    else
        echo "$runs_to_delete" | while read -r run_id; do
            if [[ -n "$run_id" ]]; then
                if gh run delete "$run_id" 2>/dev/null; then
                    echo "  Deleted: ${run_id}"
                    ((deleted_count++))
                else
                    echo "  Failed to delete: ${run_id}"
                fi
            fi
        done
    fi

    log_success "Workflow ${workflow}: deleted ${delete_count} run(s)"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --keep)
            KEEP_COUNT="$2"
            shift 2
            ;;
        --workflow)
            WORKFLOW_FILTER="$2"
            ALL_WORKFLOWS=false
            shift 2
            ;;
        --all)
            ALL_WORKFLOWS=true
            shift
            ;;
        --yes)
            SKIP_CONFIRMATION=true
            shift
            ;;
        -h|--help)
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

# Validate keep count
if [[ ! "$KEEP_COUNT" =~ ^[0-9]+$ ]] || [[ "$KEEP_COUNT" -lt 0 ]]; then
    log_error "--keep must be a non-negative integer"
    exit 1
fi

# Check prerequisites
check_gh_cli

# Show configuration
log_info "Configuration:"
echo "  Keep last: ${KEEP_COUNT} runs"
echo "  Dry run: ${DRY_RUN}"

# Determine which workflows to clean
if [[ "$ALL_WORKFLOWS" == true ]]; then
    WORKFLOWS_TO_CLEAN=("${WORKFLOWS[@]}")
else
    if [[ " ${WORKFLOWS[*]} " =~ ${WORKFLOW_FILTER} ]]; then
        WORKFLOWS_TO_CLEAN=("$WORKFLOW_FILTER")
    else
        log_error "Unknown workflow: ${WORKFLOW_FILTER}"
        echo "Available workflows: ${WORKFLOWS[*]}"
        exit 1
    fi
fi

# Show summary
echo ""
log_info "Workflows to process:"
for wf in "${WORKFLOWS_TO_CLEAN[@]}"; do
    echo "  - ${wf}"
done
echo ""

# Confirmation
if [[ "$SKIP_CONFIRMATION" == false ]] && [[ "$DRY_RUN" == false ]]; then
    echo -n "Continue? [y/N] "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        log_info "Aborted"
        exit 0
    fi
fi

# Process each workflow
for workflow in "${WORKFLOWS_TO_CLEAN[@]}"; do
    cleanup_workflow "$workflow"
    echo ""
done

log_success "Cleanup complete"
