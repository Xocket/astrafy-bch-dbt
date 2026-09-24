# Requirements and Traceability

## Purpose

This document translates the challenge brief into stable identifiers, records the material ambiguities, and links each requirement to its evidence. Update the status and evidence whenever a requirement changes.

The challenge brief is authoritative. It is not reproduced here; requirements are paraphrased.

## Identifier scheme

| Prefix | Area |
|---|---|
| `DC` | Design Challenge |
| `CC` | Coding Challenge |
| `GEN` | Generic engineering guidance |
| `SUB` | Submission requirements |
| `NFR` | Non-functional requirements |
| `AMB` | Ambiguity and chosen interpretation |

Status values:

- **Planned** — accepted and assigned an implementation path, not yet verified.
- **Implemented** — code or documentation exists, execution not yet evidenced.
- **Verified** — recorded evidence shows the requirement works on the intended environment.

## Design Challenge requirements

| ID | Requirement | Evidence | Status |
|---|---|---|---|
| `DC-1` | Design an end-to-end customer analytical platform. | `docs/report/report.pdf`, Part 1 | Verified |
| `DC-2` | Host the platform on Google Cloud. | Architecture and component sections of the report | Verified |
| `DC-3` | Prefer open source where reasonably practical. | Licensing section of the report | Verified |
| `DC-4` | Make GitOps and DataOps first-class operating principles. | Delivery section of the report | Verified |
| `DC-5` | Cover PostgreSQL, MySQL, MongoDB, SAP, Salesforce, and SurveyMonkey. | Ingestion section of the report | Verified |
| `DC-6` | Support reusable BI dashboards for multiple departments. | BI section of the report | Verified |
| `DC-7` | Enable recommendation and prediction ML. | ML section of the report | Verified |
| `DC-8` | Deliver the architecture as a PDF; no code required for Part 1. | `docs/report/report.pdf` | Verified |

## Coding Challenge requirements

| ID | Requirement | Evidence | Status |
|---|---|---|---|
| `CC-1` | Use Terraform to create a new Google Cloud project. | `google_project` in the infra repo; applied dev project `astrafy-thc-006-xocket` | Verified |
| `CC-2` | Use Terraform to create BigQuery datasets for staging and the data mart. | `google_bigquery_dataset` resources; live US `staging`/`marts` datasets | Verified |
| `CC-3` | Provision a service account with the BigQuery permissions dbt needs. | Service account, custom dataset-create role, scoped `dataEditor` bindings; live run used it | Verified |
| `CC-4` | Create supporting resources through Terraform, not by hand. | Bootstrap and primary stacks applied; outputs inspected | Verified |
| `CC-5` | Materialize staging data from the public `transactions` table, last three months only. | `stg_analysis_window`, `stg_transactions`; live build created 6,495,376 rows | Verified |
| `CC-6` | Materialize a data mart with the current balance per address. | `stg_address_ledger`, `address_balances`; 35,686,444 and 5,774,930 rows | Verified |
| `CC-7` | Exclude addresses that had at least one transaction on Coinbase. | `stg_protocol_coinbase_addresses`; 4,544 excluded; ADR 0003 | Verified |
| `CC-8` | Run the dbt workflow when a pull request opens and on pushes to it. | Workflow triggers; authenticated CI run 36054350409 | Verified |
| `CC-9` | Authenticate CI with the Terraform-provisioned service account. | WIF binding; authenticated PR and main runs | Verified |
| `CC-10` | Install dbt in CI and run `dbt run` to execute the models. | Pinned toolchain; separate run/test/docs steps in run 36054350409 | Verified |
| `CC-11` | Deliver the Terraform code in one repository. | https://github.com/Xocket/astrafy-bch-infra | Verified |
| `CC-12` | Deliver the dbt project and GitHub Actions workflow in a second repository. | https://github.com/Xocket/astrafy-bch-dbt | Verified |

## Generic, submission, and non-functional requirements

| ID | Requirement | Evidence | Status |
|---|---|---|---|
| `GEN-1` | Treat documentation as a first-class deliverable. | READMEs, ADRs, evidence page, report | Verified |
| `GEN-2` | Reuse established tools; do not reinvent the wheel. | Terraform, dbt, GitHub Actions, lockfile | Verified |
| `GEN-3` | Automate with CI/CD and IaC. | Both workflows; green runs in both repos | Verified |
| `SUB-1` | Provide the architecture deliverable as a PDF. | `docs/report/report.pdf` | Verified |
| `SUB-2` | Publish the repositories publicly. | Both public URLs | Verified |
| `SUB-3` | Reply to the challenge email with the PDF and repository links. | Human action; pending recipient name | Open |
| `NFR-1` | Keep the workload inside the intended GCP free-tier envelope. | Measured ~958 GiB full run; 100/50 GiB caps; EUR 2 budget | Implemented, not guaranteed |
| `NFR-2` | Apply least privilege; no long-lived CI credentials. | Dataset-scoped IAM; WIF; no key resource | Verified |
| `NFR-3` | Make local and CI execution reproducible. | `uv.lock`, pinned actions and providers | Verified |
| `NFR-4` | Keep state, credentials, and generated artifacts out of Git. | `.gitignore`; pre-commit private-key check; history scan | Verified |
| `NFR-5` | Produce meaningful data-quality evidence. | 45 generic and singular dbt tests, all passed | Verified |

## Ambiguity register

| ID | Ambiguity | Decision | Reason |
|---|---|---|---|
| `AMB-1` | Does "current balance" mean a lifetime balance or movement in the staged window? | A three-month net balance over the same UTC window as staging. | Staging is limited to three months by the brief. This is not a lifetime balance; the mart and ADR 0002 state the limit. |
| `AMB-2` | Does "Coinbase" mean the exchange or the protocol coinbase transaction? | The source `is_coinbase` flag identifies protocol coinbase transactions. | Deterministic and supported by the source. No authoritative exchange-address list exists. See ADR 0003. |
| `AMB-3` | Which addresses are excluded after a coinbase interaction? | The non-empty output addresses of `is_coinbase = true` transactions in the window. | Reproducible from source data. See ADR 0003. |
| `AMB-4` | Where are the three-month boundaries, and in what time zone? | `max(block_timestamp)` captured once; inclusive UTC bounds from that date minus three calendar months. | The public source ends in 2024; a wall-clock window would be empty. See ADR 0001. |
| `AMB-5` | How are multisig outputs represented? | Each address element becomes its own ledger row; addresses are never concatenated. | Every address receives its own movement. This is attribution, not ownership. See ADR 0002. |
| `AMB-6` | Would an incremental merge leave stale rows? | `stg_transactions` is a table; each run replaces the moving window. | A merge-only model cannot remove rows that age out. See ADR 0001. |
| `AMB-7` | What unit is the balance? | Exact satoshis in `balance_satoshis`; a named `balance_bch` conversion. | Two names prevent silent unit changes. See ADR 0002. |
| `AMB-8` | Must CI run `dbt run` or `dbt build`? | `dbt run`, then `dbt test`, then `dbt docs generate`. | Mirrors the brief literally and keeps the test gate. See ADR 0004. |
| `AMB-9` | One repository or two? | Two: infrastructure and dbt/CI. | Mirrors the two deliverables and separates permissions. See ADR 0005. |
| `AMB-10` | Do architecture and engineering evidence share one PDF? | One PDF: the architecture first, the engineering evidence as a separate appendix. | Satisfies the PDF deliverable and keeps the evidence traceable. |

## Verification map

| Group | Verification |
|---|---|
| `DC-*` | Report review against the requirement matrix. |
| `CC-1`–`CC-4` | `terraform fmt -check -recursive` and `validate` on both stacks; reviewed plan; applied stacks with recorded outputs. |
| `CC-5`–`CC-7` | Live dbt build (5 models), row counts, and 45/45 passing tests. |
| `CC-8`–`CC-10` | Green authenticated run on `main`: 36054350409 (parse, cost-capped run, 45 tests, docs). |
| `CC-11`–`CC-12` | Both public repository URLs. |
| `GEN-*`, `SUB-*` | Evidence page and this document. |
| `NFR-*` | Lockfile, pre-commit, byte caps, budget, IAM review, history scan, test results. |

## Maintenance rule

A requirement is not marked **Verified** until its evidence exists in the repository or in a linked, non-secret run record. The evidence page must point to a file or run URL for every identifier.
