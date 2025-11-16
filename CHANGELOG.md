# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project adheres to Semantic Versioning.

## [Unreleased]
- Planned improvements and minor refinements.

## [2.1.1] - 2025-11-15

### Added
- Embedded subcommands: `sysmaint profiles` and `sysmaint scanners`.
- Scanner integration test suite (`tests/test_suite_scanners.sh`).
- Consolidated JSON validation (`tests/test_json_validation.sh`).

### Changed
- Consolidated test files (23 → 15) while maintaining 100% coverage.
- Merged profile tests into smoke suite (60 → 65 tests).
- Updated CI workflows to use embedded subcommands and consolidated tests.
- Streamlined documentation: created `docs/INDEX.md`, reduced duplication, simplified root `README.md`.

### Removed
- Obsolete helper scripts: `sysmaint_profiles.sh`, `sysmaint_scanners.sh`.
- Deprecated tests: `test_suite_fullcycle.sh`, `test_suite_realmode.sh`, `test_profiles_tier1.sh`, `validate_json.sh`, `test_json_negative.sh`.
- Legacy root docs: `DOCUMENTATION.md`.

### Fixed
- CI YAML references to removed tests.
- Minor test stability issues (pipefail handling in JSON validation).

[Unreleased]: https://example.com/compare/v2.1.1...HEAD
[2.1.1]: https://example.com/releases/v2.1.1
