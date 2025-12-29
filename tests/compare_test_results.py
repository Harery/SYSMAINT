#!/usr/bin/env python3
#
# compare_test_results.py
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2025 Harery
#
# DESCRIPTION:
#   Compare test results from local Docker and GitHub Actions
#   Identify discrepancies and analyze accuracy differences
#
# USAGE:
#   python3 tests/compare_test_results.py [OPTIONS]
#
# OPTIONS:
#   --local FILE      Local Docker test results JSON
#   --github FILE     GitHub Actions test results JSON
#   --results DIR     Directory containing both result files
#   --output FILE     Output comparison report (default: stdout)
#   --format FORMAT   Output format: text, json, html
#   --verbose         Show detailed comparison

import argparse
import json
import sys
from pathlib import Path
from typing import Any, Dict, List, Tuple
from datetime import datetime


class TestResultComparator:
    """Compare test results from different environments."""

    def __init__(self, local_results: Dict[str, Any], github_results: Dict[str, Any]):
        self.local = local_results
        self.github = github_results
        self.discrepancies = []
        self.metrics = {}

    def compare_environments(self) -> Dict[str, Any]:
        """Compare environment information."""
        local_env = self.local.get("environment", {})
        github_env = self.github.get("environment", {})

        return {
            "local_type": local_env.get("type"),
            "github_type": github_env.get("type"),
            "os_match": local_env.get("os_name") == github_env.get("os_name"),
            "version_match": local_env.get("os_version") == github_env.get("os_version"),
            "arch_match": local_env.get("architecture") == github_env.get("architecture"),
        }

    def compare_summaries(self) -> Dict[str, Any]:
        """Compare test summaries."""
        local_summary = self.local.get("summary", {})
        github_summary = self.github.get("summary", {})

        local_total = local_summary.get("total", 0)
        github_total = github_summary.get("total", 0)
        local_passed = local_summary.get("passed", 0)
        github_passed = github_summary.get("passed", 0)
        local_failed = local_summary.get("failed", 0)
        github_failed = github_summary.get("failed", 0)

        return {
            "local_total": local_total,
            "github_total": github_total,
            "local_passed": local_passed,
            "github_passed": github_passed,
            "local_failed": local_failed,
            "github_failed": github_failed,
            "pass_rate_diff": local_summary.get("pass_rate", 0) - github_summary.get("pass_rate", 0),
            "total_diff": local_total - github_total,
        }

    def find_suite_discrepancies(self) -> List[Dict[str, Any]]:
        """Find discrepancies in individual test suites."""
        discrepancies = []
        local_results = self.local.get("results", {})
        github_results = self.github.get("results", {})

        # Get all suite names from both results
        all_suites = set(local_results.keys()) | set(github_results.keys())

        for suite in all_suites:
            local_suite = local_results.get(suite, {})
            github_suite = github_results.get(suite, {})

            local_passed = local_suite.get("passed", 0)
            github_passed = github_suite.get("passed", 0)
            local_failed = local_suite.get("failed", 0)
            github_failed = github_suite.get("failed", 0)

            # Check for discrepancies
            if local_passed != github_passed or local_failed != github_failed:
                discrepancies.append({
                    "suite": suite,
                    "local_passed": local_passed,
                    "github_passed": github_passed,
                    "local_failed": local_failed,
                    "github_failed": github_failed,
                    "pass_diff": local_passed - github_passed,
                    "fail_diff": local_failed - github_failed,
                })

        return discrepancies

    def calculate_accuracy_metrics(self) -> Dict[str, Any]:
        """Calculate accuracy metrics between environments."""
        local_summary = self.local.get("summary", {})
        github_summary = self.github.get("summary", {})

        local_total = local_summary.get("total", 0)
        github_total = github_summary.get("total", 0)
        local_passed = local_summary.get("passed", 0)
        github_passed = github_summary.get("passed", 0)

        # Avoid division by zero
        if local_total == 0 or github_total == 0:
            return {
                "local_pass_rate": 0,
                "github_pass_rate": 0,
                "accuracy_score": 0,
                "congruence": 0,
            }

        local_pass_rate = (local_passed / local_total) * 100
        github_pass_rate = (github_passed / github_total) * 100

        # Congruence measures how similar the pass rates are
        # 100% means identical pass rates
        max_rate = max(local_pass_rate, github_pass_rate)
        min_rate = min(local_pass_rate, github_pass_rate)
        congruence = (min_rate / max_rate * 100) if max_rate > 0 else 100

        # Accuracy score: weighted average of congruence and test count similarity
        count_diff_pct = abs(local_total - github_total) / max(local_total, github_total) * 100
        accuracy_score = (congruence + (100 - count_diff_pct)) / 2

        return {
            "local_pass_rate": round(local_pass_rate, 2),
            "github_pass_rate": round(github_pass_rate, 2),
            "congruence": round(congruence, 2),
            "accuracy_score": round(accuracy_score, 2),
            "count_difference": abs(local_total - github_total),
            "pass_rate_difference": round(abs(local_pass_rate - github_pass_rate), 2),
        }

    def generate_report(self) -> Dict[str, Any]:
        """Generate comprehensive comparison report."""
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "local_run_id": self.local.get("run_id"),
            "github_run_id": self.github.get("run_id"),
            "environment_comparison": self.compare_environments(),
            "summary_comparison": self.compare_summaries(),
            "discrepancies": self.find_suite_discrepancies(),
            "accuracy_metrics": self.calculate_accuracy_metrics(),
        }

    def format_text_report(self, report: Dict[str, Any]) -> str:
        """Format report as human-readable text."""
        lines = []
        lines.append("=" * 60)
        lines.append("SYSMAINT Test Results Comparison Report")
        lines.append("=" * 60)
        lines.append("")

        # Environment comparison
        lines.append("ENVIRONMENT COMPARISON")
        lines.append("-" * 60)
        env = report["environment_comparison"]
        lines.append(f"Local Environment:    {env['local_type']}")
        lines.append(f"GitHub Environment:   {env['github_type']}")
        lines.append(f"OS Match:              {'YES' if env['os_match'] else 'NO'}")
        lines.append(f"Version Match:         {'YES' if env['version_match'] else 'NO'}")
        lines.append(f"Architecture Match:    {'YES' if env['arch_match'] else 'NO'}")
        lines.append("")

        # Summary comparison
        lines.append("TEST SUMMARY COMPARISON")
        lines.append("-" * 60)
        summary = report["summary_comparison"]
        lines.append(f"Local Total Tests:     {summary['local_total']}")
        lines.append(f"GitHub Total Tests:    {summary['github_total']}")
        lines.append(f"Test Count Difference: {summary['total_diff']:+d}")
        lines.append("")
        lines.append(f"Local Passed:          {summary['local_passed']}")
        lines.append(f"GitHub Passed:         {summary['github_passed']}")
        lines.append(f"Local Failed:          {summary['local_failed']}")
        lines.append(f"GitHub Failed:         {summary['github_failed']}")
        lines.append(f"Pass Rate Difference:  {summary['pass_rate_diff']:+.2f}%")
        lines.append("")

        # Accuracy metrics
        lines.append("ACCURACY METRICS")
        lines.append("-" * 60)
        metrics = report["accuracy_metrics"]
        lines.append(f"Local Pass Rate:       {metrics['local_pass_rate']}%")
        lines.append(f"GitHub Pass Rate:      {metrics['github_pass_rate']}%")
        lines.append(f"Congruence:            {metrics['congruence']}%")
        lines.append(f"Accuracy Score:        {metrics['accuracy_score']}%")
        lines.append(f"Pass Rate Difference:  {metrics['pass_rate_difference']}%")
        lines.append("")

        # Discrepancies
        lines.append("DISCREPANCIES")
        lines.append("-" * 60)
        discrepancies = report["discrepancies"]
        if discrepancies:
            lines.append(f"Found {len(discrepancies)} suite(s) with discrepancies:")
            lines.append("")
            for d in discrepancies:
                lines.append(f"  Suite: {d['suite']}")
                lines.append(f"    Local:  {d['local_passed']} passed, {d['local_failed']} failed")
                lines.append(f"    GitHub: {d['github_passed']} passed, {d['github_failed']} failed")
                lines.append(f"    Diff:   {d['pass_diff']:+d} passed, {d['fail_diff']:+d} failed")
                lines.append("")
        else:
            lines.append("No discrepancies found - results are consistent!")
            lines.append("")

        # Overall assessment
        lines.append("OVERALL ASSESSMENT")
        lines.append("-" * 60)
        accuracy = metrics["accuracy_score"]
        if accuracy >= 95:
            assessment = "EXCELLENT - Results are highly consistent"
        elif accuracy >= 85:
            assessment = "GOOD - Minor discrepancies detected"
        elif accuracy >= 70:
            assessment = "FAIR - Moderate discrepancies detected"
        else:
            assessment = "POOR - Significant discrepancies detected"
        lines.append(assessment)
        lines.append("")

        return "\n".join(lines)

    def format_json_report(self, report: Dict[str, Any]) -> str:
        """Format report as JSON."""
        return json.dumps(report, indent=2)

    def format_html_report(self, report: Dict[str, Any]) -> str:
        """Format report as HTML."""
        env = report["environment_comparison"]
        summary = report["summary_comparison"]
        metrics = report["accuracy_metrics"]
        discrepancies = report["discrepancies"]

        # Determine assessment color
        accuracy = metrics["accuracy_score"]
        if accuracy >= 95:
            color = "#28a745"
            assessment = "EXCELLENT"
        elif accuracy >= 85:
            color = "#ffc107"
            assessment = "GOOD"
        elif accuracy >= 70:
            color = "#fd7e14"
            assessment = "FAIR"
        else:
            color = "#dc3545"
            assessment = "POOR"

        html = f"""
<!DOCTYPE html>
<html>
<head>
    <title>SYSMAINT Test Results Comparison</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }}
        .container {{ max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }}
        h1 {{ color: #333; border-bottom: 3px solid #007bff; padding-bottom: 10px; }}
        h2 {{ color: #555; margin-top: 30px; border-bottom: 1px solid #ddd; padding-bottom: 5px; }}
        .metric {{ display: inline-block; margin: 10px 20px; padding: 15px; background: #f8f9fa; border-radius: 5px; min-width: 150px; }}
        .metric-label {{ font-size: 12px; color: #666; text-transform: uppercase; }}
        .metric-value {{ font-size: 24px; font-weight: bold; color: #007bff; }}
        .assessment {{ padding: 20px; background: {color}; color: white; border-radius: 5px; text-align: center; font-size: 24px; font-weight: bold; margin: 20px 0; }}
        table {{ width: 100%; border-collapse: collapse; margin: 20px 0; }}
        th {{ background: #007bff; color: white; padding: 12px; text-align: left; }}
        td {{ padding: 10px; border-bottom: 1px solid #ddd; }}
        tr:hover {{ background: #f8f9fa; }}
        .pass {{ color: #28a745; font-weight: bold; }}
        .fail {{ color: #dc3545; font-weight: bold; }}
        .match {{ color: #28a745; }}
        .nomatch {{ color: #dc3545; }}
    </style>
</head>
<body>
    <div class="container">
        <h1>SYSMAINT Test Results Comparison</h1>
        <p>Generated: {report['timestamp']}</p>

        <div class="assessment">{assessment}</div>

        <h2>Environment Comparison</h2>
        <table>
            <tr><th>Aspect</th><th>Local Docker</th><th>GitHub Actions</th><th>Status</th></tr>
            <tr>
                <td>Environment Type</td>
                <td>{env['local_type']}</td>
                <td>{env['github_type']}</td>
                <td>-</td>
            </tr>
            <tr>
                <td>OS Match</td>
                <td>-</td>
                <td>-</td>
                <td class="{'match' if env['os_match'] else 'nomatch'}">{'YES' if env['os_match'] else 'NO'}</td>
            </tr>
            <tr>
                <td>Version Match</td>
                <td>-</td>
                <td>-</td>
                <td class="{'match' if env['version_match'] else 'nomatch'}">{'YES' if env['version_match'] else 'NO'}</td>
            </tr>
            <tr>
                <td>Architecture Match</td>
                <td>-</td>
                <td>-</td>
                <td class="{'match' if env['arch_match'] else 'nomatch'}">{'YES' if env['arch_match'] else 'NO'}</td>
            </tr>
        </table>

        <h2>Test Summary</h2>
        <div class="metric">
            <div class="metric-label">Local Total</div>
            <div class="metric-value">{summary['local_total']}</div>
        </div>
        <div class="metric">
            <div class="metric-label">Local Passed</div>
            <div class="metric-value pass">{summary['local_passed']}</div>
        </div>
        <div class="metric">
            <div class="metric-label">Local Failed</div>
            <div class="metric-value fail">{summary['local_failed']}</div>
        </div>
        <div class="metric">
            <div class="metric-label">GitHub Total</div>
            <div class="metric-value">{summary['github_total']}</div>
        </div>
        <div class="metric">
            <div class="metric-label">GitHub Passed</div>
            <div class="metric-value pass">{summary['github_passed']}</div>
        </div>
        <div class="metric">
            <div class="metric-label">GitHub Failed</div>
            <div class="metric-value fail">{summary['github_failed']}</div>
        </div>

        <h2>Accuracy Metrics</h2>
        <div class="metric">
            <div class="metric-label">Local Pass Rate</div>
            <div class="metric-value">{metrics['local_pass_rate']}%</div>
        </div>
        <div class="metric">
            <div class="metric-label">GitHub Pass Rate</div>
            <div class="metric-value">{metrics['github_pass_rate']}%</div>
        </div>
        <div class="metric">
            <div class="metric-label">Congruence</div>
            <div class="metric-value">{metrics['congruence']}%</div>
        </div>
        <div class="metric">
            <div class="metric-label">Accuracy Score</div>
            <div class="metric-value">{metrics['accuracy_score']}%</div>
        </div>

        <h2>Discrepancies</h2>
        """

        if discrepancies:
            html += """
        <table>
            <tr><th>Test Suite</th><th>Local</th><th>GitHub</th><th>Difference</th></tr>
            """
            for d in discrepancies:
                html += f"""
            <tr>
                <td>{d['suite']}</td>
                <td>{d['local_passed']} pass, {d['local_failed']} fail</td>
                <td>{d['github_passed']} pass, {d['github_failed']} fail</td>
                <td>{d['pass_diff']:+d} pass, {d['fail_diff']:+d} fail</td>
            </tr>
            """
            html += "</table>"
        else:
            html += "<p>No discrepancies found - results are consistent!</p>"

        html += """
    </div>
</body>
</html>
"""
        return html


def load_json_file(filepath: str) -> Dict[str, Any]:
    """Load JSON from file."""
    try:
        with open(filepath, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"Error: File not found: {filepath}", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in {filepath}: {e}", file=sys.stderr)
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(
        description="Compare SYSMAINT test results from local Docker and GitHub Actions"
    )
    parser.add_argument("--local", help="Local Docker test results JSON file")
    parser.add_argument("--github", help="GitHub Actions test results JSON file")
    parser.add_argument("--results", help="Directory containing both result files")
    parser.add_argument("--output", help="Output file (default: stdout)")
    parser.add_argument("--format", choices=["text", "json", "html"], default="text",
                        help="Output format (default: text)")
    parser.add_argument("--verbose", action="store_true", help="Show detailed comparison")

    args = parser.parse_args()

    # Load results
    if args.results:
        results_dir = Path(args.results)
        local_files = list(results_dir.glob("*local*.json"))
        github_files = list(results_dir.glob("*github*.json"))

        if not local_files:
            print(f"Error: No local results found in {args.results}", file=sys.stderr)
            sys.exit(1)
        if not github_files:
            print(f"Error: No GitHub results found in {args.results}", file=sys.stderr)
            sys.exit(1)

        local_path = str(local_files[-1])  # Use latest
        github_path = str(github_files[-1])  # Use latest
    else:
        if not args.local or not args.github:
            parser.error("Must specify both --local and --github, or use --results")
        local_path = args.local
        github_path = args.github

    local_results = load_json_file(local_path)
    github_results = load_json_file(github_path)

    # Compare
    comparator = TestResultComparator(local_results, github_results)
    report = comparator.generate_report()

    # Format output
    if args.format == "text":
        output = comparator.format_text_report(report)
    elif args.format == "json":
        output = comparator.format_json_report(report)
    elif args.format == "html":
        output = comparator.format_html_report(report)

    # Write output
    if args.output:
        with open(args.output, 'w') as f:
            f.write(output)
        print(f"Report written to: {args.output}")
    else:
        print(output)


if __name__ == "__main__":
    main()
