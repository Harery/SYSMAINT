# Documentation Index

Name: Documentation Index
Purpose: Single entrypoint to all docs with clear roles
Need: Reduce confusion and file sprawl; help users find the right doc fast
Function: Maps purpose → file; lists owner topics and quick links

---

## How to Navigate
- Start with `README.md` for overview and quick commands.
- Use the Purpose sections below to jump to the single doc that owns each topic.
- Files marked Archived are retained for history; prefer the primary doc listed here.

---

## Primary Docs (single purpose per file)

- Project Overview & Quickstart → `README.md`
  - Purpose: Onboarding, common commands, CI links, scanners, performance gate
  - Audience: New users, day-to-day operators
  - Note: Single-script distribution — `sysmaint` now includes `profiles` and `scanners` subcommands

- Testing & Coverage → `docs/TEST_COVERAGE.md`
  - Purpose: How to run tests, what’s covered, counts, suites
  - Also: JSON schema validation, combos/real-mode, specialized suites

- Security Hardening → `docs/SECURITY.md`
  - Purpose: Enable and interpret security audit; best practices; integrations (lynis, rkhunter)
  - Also: Permission expectations and remediation samples

- Performance & Baselines → `docs/PERFORMANCE.md`
  - Purpose: Benchmarks, CSV outputs, regression checks, CI gate (~20%)
  - Also: Baseline management and comparison workflow

 - CLI Flag Duplication Matrix → `docs/TEST_COVERAGE.md#flag-duplication-matrix`
  - Purpose: Normalized matrix of flags across suites to spot duplication and gaps
  - Note: Standalone `docs/FLAG_DUPLICATION.md` removed (embedded here)

  ---

  ## Project Log

  - Changelog → `CHANGELOG.md`
    - Purpose: Release notes (Keep a Changelog, SemVer)
    - Scope: Notable Added/Changed/Removed/Fixed entries per version

---

## Consolidations and Moves

- tests/README.md → Moved into: `docs/TEST_COVERAGE.md`
- benchmarks/README.md → Removed (content merged into `docs/PERFORMANCE.md`)
- benchmarks/BASELINE_UPDATES.md → Removed (baseline updates now in `docs/PERFORMANCE.md`)
- DOCUMENTATION.md → Archived. Superseded by focused docs above. See `README.md` + this index.

---

## Ownership by Topic

- Core usage, flags, examples → `README.md`
- Test suites, counts, execution → `docs/TEST_COVERAGE.md`
- Security audit details, file perms → `docs/SECURITY.md`
- Benchmarks, regression gate, CSV → `docs/PERFORMANCE.md`
- Flag duplication/matrix → `docs/TEST_COVERAGE.md#flag-duplication-matrix`

---

Maintainer: Mohamed Elharery <Mohamed@Harery.com>
Last updated: November 15, 2025 (post-consolidation cleanup)
