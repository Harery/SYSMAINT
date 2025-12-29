#!/bin/bash
#
# generate_test_report.sh
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Harery
#
# DESCRIPTION:
#   Generates HTML test reports from JSON results
#
# USAGE:
#   bash tests/generate_test_report.sh --results tests/results --output report.html

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Defaults
RESULTS_DIR="tests/results"
OUTPUT_FILE="test-report.html"
TITLE="SYSMAINT Test Report"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --results)
            RESULTS_DIR="$2"
            shift 2
            ;;
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --title)
            TITLE="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "OPTIONS:"
            echo "  --results DIR    Results directory (default: tests/results)"
            echo "  --output FILE    Output HTML file (default: test-report.html)"
            echo "  --title TITLE    Report title (default: SYSMAINT Test Report)"
            echo "  --help, -h       Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}[INFO]${NC} Generating test report..."
echo "Results: $RESULTS_DIR"
echo "Output:  $OUTPUT_FILE"

# Find all JSON result files
mapfile -t result_files < <(find "$RESULTS_DIR" -name "*.json" -type f 2>/dev/null)

if [[ ${#result_files[@]} -eq 0 ]]; then
    echo -e "${YELLOW}[WARNING]${NC} No result files found in $RESULTS_DIR"
    # Generate empty report
    result_files=()
fi

# Start HTML generation
cat > "$OUTPUT_FILE" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SYSMAINT Test Report</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        
        .header {
            background: white;
            border-radius: 10px;
            padding: 30px;
            margin-bottom: 20px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
        }
        
        .header h1 {
            color: #333;
            margin-bottom: 10px;
        }
        
        .header .timestamp {
            color: #666;
            font-size: 14px;
        }
        
        .summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }
        
        .summary-card {
            background: white;
            border-radius: 10px;
            padding: 20px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
            text-align: center;
        }
        
        .summary-card h3 {
            color: #666;
            font-size: 14px;
            margin-bottom: 10px;
        }
        
        .summary-card .value {
            font-size: 36px;
            font-weight: bold;
        }
        
        .summary-card.total .value { color: #667eea; }
        .summary-card.passed .value { color: #10b981; }
        .summary-card.failed .value { color: #ef4444; }
        .summary-card.rate .value { color: #f59e0b; }
        
        .test-results {
            background: white;
            border-radius: 10px;
            padding: 20px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
        }
        
        .test-results h2 {
            color: #333;
            margin-bottom: 20px;
        }
        
        .suite {
            margin-bottom: 30px;
            border: 1px solid #e5e7eb;
            border-radius: 8px;
            overflow: hidden;
        }
        
        .suite-header {
            background: #f9fafb;
            padding: 15px 20px;
            border-bottom: 1px solid #e5e7eb;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .suite-header h3 {
            color: #333;
            font-size: 18px;
        }
        
        .suite-stats {
            display: flex;
            gap: 20px;
            font-size: 14px;
            color: #666;
        }
        
        .test {
            padding: 10px 20px;
            border-bottom: 1px solid #f3f4f6;
            display: flex;
            align-items: center;
        }
        
        .test:last-child {
            border-bottom: none;
        }
        
        .test-name {
            flex: 1;
            color: #333;
        }
        
        .test-status {
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 500;
        }
        
        .test-status.pass {
            background: #d1fae5;
            color: #065f46;
        }
        
        .test-status.fail {
            background: #fee2e2;
            color: #991b1b;
        }
        
        .progress-bar {
            width: 100%;
            height: 8px;
            background: #e5e7eb;
            border-radius: 4px;
            overflow: hidden;
            margin-top: 10px;
        }
        
        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #10b981, #34d399);
            transition: width 0.3s ease;
        }
        
        .footer {
            text-align: center;
            margin-top: 20px;
            color: white;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🧪 SYSMAINT Test Report</h1>
            <p class="timestamp">Generated on: $(date -u +"%Y-%m-%d %H:%M:%S UTC")</p>
        </div>
        
        <div class="summary">
            <div class="summary-card total">
                <h3>Total Tests</h3>
                <div class="value" id="total-tests">0</div>
            </div>
            <div class="summary-card passed">
                <h3>Passed</h3>
                <div class="value" id="passed-tests">0</div>
            </div>
            <div class="summary-card failed">
                <h3>Failed</h3>
                <div class="value" id="failed-tests">0</div>
            </div>
            <div class="summary-card rate">
                <h3>Pass Rate</h3>
                <div class="value" id="pass-rate">0%</div>
            </div>
        </div>
        
        <div class="progress-bar">
            <div class="progress-fill" id="progress-fill" style="width: 0%"></div>
        </div>
        
        <div class="test-results">
            <h2>Test Results</h2>
            <div id="test-suites">
HTMLEOF

# Parse JSON files and add to report
total_tests=0
total_passed=0
total_failed=0

if [[ ${#result_files[@]} -gt 0 ]]; then
    for result_file in "${result_files[@]}"; do
        if command -v jq &>/dev/null; then
            # Extract data from JSON
            run_id=$(jq -r '.run_id // "unknown"' "$result_file" 2>/dev/null)
            env_type=$(jq -r '.environment.type // "unknown"' "$result_file" 2>/dev/null)
            os_name=$(jq -r '.environment.os_name // "unknown"' "$result_file" 2>/dev/null)
            os_version=$(jq -r '.environment.os_version // "unknown"' "$result_file" 2>/dev/null)
            
            # Get summary
            file_total=$(jq -r '.summary.total // 0' "$result_file" 2>/dev/null)
            file_passed=$(jq -r '.summary.passed // 0' "$result_file" 2>/dev/null)
            file_failed=$(jq -r '.summary.failed // 0' "$result_file" 2>/dev/null)
            
            # Accumulate totals
            total_tests=$((total_tests + file_total))
            total_passed=$((total_passed + file_passed))
            total_failed=$((total_failed + file_failed))
            
            # Generate suite HTML
            cat >> "$OUTPUT_FILE" << SUITEEOF
                <div class="suite">
                    <div class="suite-header">
                        <h3>$env_type - $os_name $os_version</h3>
                        <div class="suite-stats">
                            <span>Total: $file_total</span>
                            <span style="color: #10b981;">Passed: $file_passed</span>
                            <span style="color: #ef4444;">Failed: $file_failed</span>
                        </div>
                    </div>
SUITEEOF
            
            # Add individual test results if available
            if jq -e '.results' "$result_file" &>/dev/null; then
                # List suite names
                mapfile -t suites < <(jq -r '.results | keys[]' "$result_file" 2>/dev/null)
                
                for suite_name in "${suites[@]}"; do
                    suite_total=$(jq -r ".results.\"$suite_name\".total // 0" "$result_file" 2>/dev/null)
                    suite_passed=$(jq -r ".results.\"$suite_name\".passed // 0" "$result_file" 2>/dev/null)
                    suite_failed=$(jq -r ".results.\"$suite_name\".failed // 0" "$result_file" 2>/dev/null)
                    
                    cat >> "$OUTPUT_FILE" << SUITEEOF
                    <div class="test">
                        <div class="test-name">$suite_name</div>
                        <div class="test-status pass">PASSED: $suite_passed</div>
                    </div>
SUITEEOF
                done
            fi
            
            cat >> "$OUTPUT_FILE" << SUITEEOF
                </div>
SUITEEOF
        fi
    done
fi

# Calculate pass rate
if [[ $total_tests -gt 0 ]]; then
    pass_rate=$((total_passed * 100 / total_tests))
else
    pass_rate=0
fi

# Add closing HTML
cat >> "$OUTPUT_FILE" << HTMLEOF
            </div>
        </div>
        
        <div class="footer">
            <p>Generated by SYSMAINT Test Infrastructure</p>
            <p>© 2025 Harery | MIT License</p>
        </div>
    </div>
    
    <script>
        // Update summary numbers
        document.getElementById('total-tests').textContent = '$total_tests';
        document.getElementById('passed-tests').textContent = '$total_passed';
        document.getElementById('failed-tests').textContent = '$total_failed';
        document.getElementById('pass-rate').textContent = '$pass_rate%';
        
        // Update progress bar
        document.getElementById('progress-fill').style.width = '$pass_rate%';
    </script>
</body>
</html>
HTMLEOF

echo -e "${GREEN}[SUCCESS]${NC} Report generated: $OUTPUT_FILE"
echo ""
echo "Summary:"
echo "  Total Tests: $total_tests"
echo "  Passed:      $total_passed"
echo "  Failed:      $total_failed"
echo "  Pass Rate:   ${pass_rate}%"
echo ""
echo "Open report: file://$(pwd)/$OUTPUT_FILE"
