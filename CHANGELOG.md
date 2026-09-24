# Changelog

All notable changes to this project are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses semantic versioning.

## [Unreleased]

### Added

- Initial repository scaffold and credential-safe dbt defaults.
- Reproducible Python 3.12 and dbt BigQuery 1.12 toolchain with a committed `uv.lock`.
- Credential-free dbt parsing and keyless Google Cloud CI workflow scaffolds.
- Source-relative three-month window capture, partitioned transaction staging,
  protocol-coinbase exclusion set, normalized address ledger, and the
  `address_balances` three-month net-movement mart.
- Generic and singular dbt tests for window bounds, deduplication, address
  uniqueness, protocol-coinbase exclusion, and per-transaction fee accounting.
- Three focused ADRs covering window/materialization, balance semantics and
  multisig attribution, and protocol-coinbase interpretation.
- CI now runs `dbt run`, `dbt test`, and `dbt docs generate` as separate
  authenticated steps while retaining WIF and run-result artifacts, aligns
  project/location variables with the infrastructure stack, and pins every
  action to an immutable commit.
- Final evaluator report at `docs/report/report.pdf`, with LaTeX source,
  one native TikZ diagram, first-party citations, licensing
  distinctions, and a separately scoped Part 2 evidence appendix.
- Seven-day automatic expiration and BigQuery workload labels on generated
  tables to bound abandoned storage and improve cost attribution.

### Changed

- All Terraform applies, the five-model BigQuery build, the 45 dbt tests,
  documentation generation, and the authenticated pull-request run are
  verified and recorded in `docs/COMPLIANCE.md`.
- The report was rewritten in a plain engineering style and cut from 41
  to 14 pages; all measured numbers and run links are kept.
- Requirement statuses, the README status, and the evidence page now
  match the recorded runs.
- Repository documentation was condensed: one evidence page, trimmed
  ADRs, short READMEs, and a final review record at `docs/ANALYSIS.md`.
- Submission-process scaffolding (email draft, submission checklist) was
  removed from the worktree and from Git history.
