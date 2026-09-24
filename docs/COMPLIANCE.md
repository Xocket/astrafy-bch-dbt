# Compliance and Live Evidence

Every row names its evidence: a repository file or a public run URL.
Statuses: **Verified** (recorded evidence), **Implemented** (source
exists), **Open** (a live or human gate remains). Captured on
2026-09-24. Values are non-secret identifiers and measured results.

## Design Challenge

| ID | Status | Evidence |
|---|---|---|
| `DC-1`–`DC-7` | Verified | `docs/report/report.pdf` sections 2–8: platform design, Google Cloud, open-source licensing, GitOps/DataOps, all six sources, BI, ML |
| `DC-8` | Verified | `docs/report/report.pdf`: 14 pages, compiled twice with MiKTeX `pdflatex`, no errors, no undefined references |

## Coding Challenge

| ID | Status | Evidence |
|---|---|---|
| `CC-1` | Verified | Applied dev project `astrafy-thc-006-xocket`; `google_project` in the infra `main.tf`; outputs inspected |
| `CC-2` | Verified | Live US `staging`/`marts` datasets; the source-access view is an access boundary, not a third dataset |
| `CC-3` | Verified | dbt service account: project `jobUser`, custom dataset-create/get role, dataset-scoped `dataEditor`; policy inspected |
| `CC-4` | Verified | Bootstrap and primary stacks applied; state project `astrafy-thc-006-state-xocket`, bucket `astrafy-thc-006-state-xocket-tfstate` (EU), APIs, WIF, IAM, EUR 2 budget outputs inspected |
| `CC-5` | Verified | `stg_analysis_window` and partitioned `stg_transactions` over the Terraform-managed source view; live build created 6,495,376 rows |
| `CC-6` | Verified | `stg_address_ledger`: 35,686,444 rows; `address_balances`: 5,774,930 rows; 45/45 tests passed |
| `CC-7` | Verified | Protocol-coinbase exclusion: 4,544 addresses; `tests/assert_protocol_coinbase_*.sql` passed |
| `CC-8` | Verified | Pull-request and main triggers: parse, WIF authentication, cost-capped `dbt run`, 45 tests, docs — [run 36054350409](https://github.com/Xocket/astrafy-bch-dbt/actions/runs/36054350409) |
| `CC-9` | Verified | WIF owner/repository/ref/event/actor conditions and principal-set bindings are live; CI authenticated through them in [run 36054350409](https://github.com/Xocket/astrafy-bch-dbt/actions/runs/36054350409) |
| `CC-10` | Verified | Pinned toolchain; separate `dbt run --select address_balances`, `dbt test`, and docs steps passed with byte caps |
| `CC-11` | Verified | https://github.com/Xocket/astrafy-bch-infra is public |
| `CC-12` | Verified | https://github.com/Xocket/astrafy-bch-dbt is public |

## Generic, submission, and non-functional

| ID | Status | Evidence |
|---|---|---|
| `GEN-1` | Verified | READMEs, requirements, ADRs, evidence page, report |
| `GEN-2` | Verified | Terraform, dbt, GitHub Actions, lockfile, pinned actions |
| `GEN-3` | Verified | Infra plan [run 36054422871](https://github.com/Xocket/astrafy-bch-infra/actions/runs/36054422871); dbt [run 36054350409](https://github.com/Xocket/astrafy-bch-dbt/actions/runs/36054350409) |
| `SUB-1` | Verified | `docs/report/report.pdf` ready for attachment |
| `SUB-2` | Verified | Both public URLs above |
| `SUB-3` | Open | Human action: reply to the challenge email with the PDF and both links |
| `NFR-1` | Implemented | Measured ~958 GiB full DAG (945.6 GiB `stg_transactions`); 100/50 GiB caps; EUR 2 alert budget. Guardrail, not a guarantee |
| `NFR-2` | Verified | Dataset-scoped IAM; no key resource; WIF runs above |
| `NFR-3` | Verified | `uv.lock`, pinned actions and providers; parse/compile/validate pass |
| `NFR-4` | Verified | Git ignores; pre-commit private-key check; history scan clean |
| `NFR-5` | Verified | 45/45 tests passed against the live tables |

## Live run (2026-09-24)

Command: `uv run dbt run --target dev` against `astrafy-thc-006-xocket`.

- Window: 2024-02-13T00:00:00+00:00 to 2024-05-13T23:57:05+00:00 (three
  calendar months, source-relative; both ends inclusive).
- 5 of 5 models created: `stg_transactions` 6,495,376 rows (4,656,887,340
  logical bytes); `stg_protocol_coinbase_addresses` 4,544 rows;
  `stg_address_ledger` 35,686,444 rows (7,799,076,081 bytes);
  `address_balances` 5,774,930 rows (1,011,781,050 bytes).
- Storage: 12.54 GiB logical across the generated tables; seven-day
  expiration and workload labels verified.
- Tests: 45 passed, 0 failed, 0 warned. Docs catalog generated.

## Cost evidence

- `stg_transactions` scan: 945.6 GiB; full DAG: about 958 GiB.
- Estimates before the run: 2.91 GiB (3,127,792,896 bytes) for the
  latest-timestamp query; 6.19 GiB (6,646,559,904 bytes) for the
  three-month profile.
- Budget: EUR 2, alerts at 50/90/100% of current spend. It alerts; it
  does not stop spending.
- Caps: 100 GiB per job locally, 50 GiB in CI. CI rebuilds only
  `address_balances`.

## Public CI runs

- dbt CI (credential-free parse + authenticated build): [run 36054350409](https://github.com/Xocket/astrafy-bch-dbt/actions/runs/36054350409)
- Infra CI (format/validate + read-only plan with WIF, "No changes"): [run 36054422871](https://github.com/Xocket/astrafy-bch-infra/actions/runs/36054422871)

No credentials, access tokens, or secret values are stored in either
repository.

## Final verification (2026-09-24, this pass)

| Check | Result |
|---|---|
| `terraform fmt -check -recursive` (infra) | Passed |
| `terraform validate -backend=false` (infra primary) | The configuration is valid |
| `terraform validate -backend=false` (infra bootstrap) | The configuration is valid |
| `uv run dbt parse --no-partial-parse` | Passed: dbt 1.12.5, 5 models, 45 data tests, 1 source |
| `uv run dbt compile --no-introspect` (target dev) | Passed |
| `uv run dbt debug --target dev` | All checks passed; connection ok |
| `uv run dbt run --select address_balances` (50 GiB cap) | Created: 5.8M rows, 5.1 GiB processed |
| `uv run dbt test --target dev` | 45 passed, 0 failed, 0 warned |
| `uv run dbt docs generate --target dev` | Catalog written |
| `pre-commit run --all-files` (both repos) | Passed, including the Docker terraform-fmt hook |
| Report compile (2 passes, `pdflatex -interaction=nonstopmode -halt-on-error`) | 14 pages, 436,900 bytes; 0 overfull; 0 undefined references; 0 fatal errors; 13 underfull (cosmetic spacing) |

## Open gates

1. Reconcile the BigQuery billing export after the ~958 GiB run. Do not
   claim a free-tier guarantee.
2. Review the PDF, attach it, and send the reply email (recipient name
   pending).
