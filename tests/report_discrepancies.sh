#!/bin/bash
#
# report_discrepancies.sh
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Harery
#
# DESCRIPTION:
#   Identify and report discrepancies between local Docker and GitHub Actions tests
#   Generates detailed discrepancy reports for analysis
#
# USAGE:
#   ./tests/report_discrepancies.sh [OPTIONS]
#
# OPTIONS:
#   --local FILE      Local Docker test results JSON
#   --github FILE     GitHub Actions test results JSON
#   --results DIR     Directory containing both result files
#   --output DIR      Output directory for reports (default: tests/results/discrepancies)
#   --format FORMAT   Report format: text, html, json (default: all)

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Defaults
LOCAL_FILE=""
GITHUB_FILE=""
RESULTS_DIR=""
OUTPUT_DIR="$PROJECT_DIR/tests/results/discrepancies"
FORMAT="all"

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
Usage: report_discrepancies.sh [OPTIONS]

Identify and report discrepancies between test environments.

OPTIONS:
    --local FILE      Local Docker test results JSON
    --github FILE     GitHub Actions test results JSON
    --results DIR     Directory containing both result files
    --output DIR      Output directory for reports
    --format FORMAT   Report format: text, html, json (default: all)
    --help            Show this help

EXAMPLES:
    # Generate all reports from results directory
    ./report_discrepancies.sh --results tests/results

    # Generate HTML report only
    ./report_discrepancies.sh --results tests/results --format html

EOF
}

# Find latest result files
find_result_files() {
    local search_dir="$1"

    local latest_local
    local latest_github

    latest_local=$(find "$search_dir" -name "*local*.json" -type f 2>/dev/null | sort -r | head -n1)
    latest_github=$(find "$search_dir" -name "*github*.json" -type f 2>/dev/null | sort -r | head -n1)

    if [[ -z "$latest_local" ]]; then
        log_error "No local Docker result files found in $search_dir"
        exit 1
    fi

    if [[ -z "$latest_github" ]]; then
        log_error "No GitHub Actions result files found in $search_dir"
        exit 1
    fi

    echo "$latest_local"
    echo "$latest_github"
}

# Generate text report
generate_text_report() {
    local local_file="$1"
    local github_file="$2"
    local output_file="$3"

    log_info "Generating text report..."

    # Use Python comparison tool
    python3 "$SCRIPT_DIR/compare_test_results.py" \
        --local "$local_file" \
        --github "$github_file" \
        --output "$output_file" \
        --format text

    log_success "Text report: $output_file"
}

# Generate HTML report
generate_html_report() {
    local local_file="$1"
    local github_file="$2"
    local output_file="$3"

    log_info "Generating HTML report..."

    python3 "$SCRIPT_DIR/compare_test_results.py" \
        --local "$local_file" \
        --github "$github_file" \
        --output "$output_file" \
        --format html

    log_success "HTML report: $output_file"
}

# Generate JSON report
generate_json_report() {
    local local_file="$1"
    local github_file="$2"
    local output_file="$3"

    log_info "Generating JSON report..."

    python3 "$SCRIPT_DIR/compare_test_results.py" \
        --local "$local_file" \
        --github "$github_file" \
        --output "$output_file" \
        --format json

    log_success "JSON report: $output_file"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --local)
            LOCAL_FILE="$2"
            shift 2
            ;;
        --github)
            GITHUB_FILE="$2"
            shift 2
            ;;
        --results)
            RESULTS_DIR="$2"
            shift 2
            ;;
        --output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --format)
            FORMAT="$2"
            shift 2
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

# Find result files if directory specified
if [[ -n "$RESULTS_DIR" ]]; then
    readarray -t files < <(find_result_files "$RESULTS_DIR")
    LOCAL_FILE="${files[0]}"
    GITHUB_FILE="${files[1]}"
    log_info "Found local results: $LOCAL_FILE"
    log_info "Found GitHub results: $GITHUB_FILE"
fi

# Validate inputs
if [[ -z "$LOCAL_FILE" ]] || [[ -z "$GITHUB_FILE" ]]; then
    log_error "Must specify both --local and --github, or use --results"
    show_help
    exit 1
fi

if [[ ! -f "$LOCAL_FILE" ]]; then
    log_error "Local file not found: $LOCAL_FILE"
    exit 1
fi

if [[ ! -f "$GITHUB_FILE" ]]; then
    log_error "GitHub file not found: $GITHUB_FILE"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Generate timestamp for reports
timestamp=$(date +%Y%m%d-%H%M%S)

# Generate reports based on format
case "$FORMAT" in
    text)
        generate_text_report "$LOCAL_FILE" "$GITHUB_FILE" "$OUTPUT_DIR/discrepancies-${timestamp}.txt"
        ;;
    html)
        generate_html_report "$LOCAL_FILE" "$GITHUB_FILE" "$OUTPUT_DIR/discrepancies-${timestamp}.html"
        ;;
    json)
        generate_json_report "$LOCAL_FILE" "$GITHUB_FILE" "$OUTPUT_DIR/discrepancies-${timestamp}.json"
        ;;
    all)
        generate_text_report "$LOCAL_FILE" "$GITHUB_FILE" "$OUTPUT_DIR/discrepancies-${timestamp}.txt"
        generate_html_report "$LOCAL_FILE" "$GITHUB_FILE" "$OUTPUT_DIR/discrepancies-${timestamp}.html"
        generate_json_report "$LOCAL_FILE" "$GITHUB_FILE" "$OUTPUT_DIR/discrepancies-${timestamp}.json"
        ;;
    *)
        log_error "Unknown format: $FORMAT"
        exit 1
        ;;
esac

# Summary
echo ""
echo "========================================"
echo "Discrepancy Report Summary"
echo "========================================"
echo "Local file:   $LOCAL_FILE"
echo "GitHub file:  $GITHUB_FILE"
echo "Output dir:   $OUTPUT_DIR"
echo "Format:       $FORMAT"
echo ""
