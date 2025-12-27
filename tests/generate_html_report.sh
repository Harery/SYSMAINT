#!/usr/bin/env bash
# Generate HTML Test Report
# Author: Mohamed Elharery <Mohamed@Harery.com>
# (c) 2025 Mohamed Elharery

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
RESULTS_DIR="$PROJECT_ROOT/test_results"
REPORT_FILE="$RESULTS_DIR/report.html"

# Generate summary
summary=$(bash "$SCRIPT_DIR/generate_summary.sh")

# Create HTML report
cat > "$REPORT_FILE" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sysmaint Test Report</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 30px;
        }
        .header h1 {
            margin: 0;
            font-size: 2.5em;
        }
        .header .subtitle {
            margin-top: 10px;
            opacity: 0.9;
        }
        .summary {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            margin-bottom: 30px;
        }
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .stat-card {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            text-align: center;
        }
        .stat-card .value {
            font-size: 2.5em;
            font-weight: bold;
            color: #667eea;
        }
        .stat-card .label {
            color: #666;
            margin-top: 10px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            background: white;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        th, td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background: #667eea;
            color: white;
            font-weight: 600;
        }
        tr:hover {
            background: #f9f9f9;
        }
        .pass { color: #28a745; font-weight: bold; }
        .fail { color: #dc3545; font-weight: bold; }
        .footer {
            text-align: center;
            margin-top: 40px;
            color: #666;
            font-size: 0.9em;
        }
        pre {
            background: #f4f4f4;
            padding: 15px;
            border-radius: 5px;
            overflow-x: auto;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🧪 Sysmaint Test Report</h1>
        <div class="subtitle">Automated Linux System Maintenance</div>
    </div>

    <div class="stats">
        <div class="stat-card">
            <div class="value" id="total-tests">-</div>
            <div class="label">Total Tests</div>
        </div>
        <div class="stat-card">
            <div class="value pass" id="passed-tests">-</div>
            <div class="label">Passed</div>
        </div>
        <div class="stat-card">
            <div class="value fail" id="failed-tests">-</div>
            <div class="label">Failed</div>
        </div>
        <div class="stat-card">
            <div class="value" id="pass-rate">-</div>
            <div class="label">Pass Rate</div>
        </div>
    </div>

    <div class="summary">
        <h2>Test Summary</h2>
        <pre>$(echo "$summary" | sed 's/</\&lt;/g' | sed 's/>/\&gt;/g')</pre>
    </div>

    <div class="footer">
        <p>Generated on $(date -R) | sysmaint v$(grep '^VERSION=' "$PROJECT_ROOT/sysmaint" | cut -d= -f2 | tr -d '"')</p>
    </div>

    <script>
        // Extract stats from summary and update cards
        const summaryText = document.querySelector('pre').textContent;
        const totalMatch = summaryText.match(/Total Tests: (\d+)/);
        const passedMatch = summaryText.match(/Passed: (\d+)/);
        const failedMatch = summaryText.match(/Failed: (\d+)/);
        const rateMatch = summaryText.match(/Pass Rate: ([\d.]+)%/);

        if (totalMatch) document.getElementById('total-tests').textContent = totalMatch[1];
        if (passedMatch) document.getElementById('passed-tests').textContent = passedMatch[1];
        if (failedMatch) document.getElementById('failed-tests').textContent = failedMatch[1];
        if (rateMatch) document.getElementById('pass-rate').textContent = rateMatch[1] + '%';
    </script>
</body>
</html>
EOF

echo "HTML report generated: $REPORT_FILE"
echo "Open in browser: file://$REPORT_FILE"
