# BCH Analytics dbt

[![dbt CI](https://github.com/Xocket/astrafy-bch-dbt/actions/workflows/dbt.yml/badge.svg)](https://github.com/Xocket/astrafy-bch-dbt/actions/workflows/dbt.yml)

A dbt project for the Astrafy take-home challenge. It reads the public
Bitcoin Cash transactions table on BigQuery and produces a tested
address-balance mart over a three-month window.

Status: verified. All five models ran against BigQuery, all 45 tests
passed, and the CI authenticated with the provisioned identity and
passed
([run 36054350409](https://github.com/Xocket/astrafy-bch-dbt/actions/runs/36054350409)).

- Report: [`docs/report/report.pdf`](docs/report/report.pdf) — 14 pages.
  Part 1 is the platform design; Part 2 is the engineering evidence.
- Requirements: [`docs/REQUIREMENTS.md`](docs/REQUIREMENTS.md)
- Evidence: [`docs/COMPLIANCE.md`](docs/COMPLIANCE.md)
- Decisions: [`docs/adr/`](docs/adr/)
- Final review: [`docs/ANALYSIS.md`](docs/ANALYSIS.md)
- Infrastructure: https://github.com/Xocket/astrafy-bch-infra

## Model graph

```text
bch_transactions_source (Terraform view over
bigquery-public-data.crypto_bitcoin_cash.transactions)
                              |
                    stg_analysis_window
                              |
                    stg_transactions (table)
                       /              \
stg_protocol_coinbase_addresses   stg_address_ledger
                       \              /
                        address_balances
```

The staging models live in the `staging` dataset; the mart in `marts`.

## Semantics

`address_balances` is the three-month net movement — outputs minus
inputs inside one captured window. It is not a lifetime balance, and
negative values are valid when the funding is older than the window.
"Coinbase" is the protocol `is_coinbase` flag, not the exchange.
Addresses are trimmed, not lower-cased. A multisig output credits each
listed address; this is attribution, not ownership. Fees stay on the
transaction. See `docs/adr/` for the reasoning.

## Prerequisites

- Python 3.12 and `uv`
- Google Cloud application-default credentials
- BigQuery access to the public dataset, plus the provisioned
  `staging` and `marts` datasets (the infrastructure repository creates
  them; the profile's default schema is `staging`, so dbt does not
  create an unrequested dataset)

## Run it

```powershell
uv sync --frozen
Copy-Item profiles.yml.example profiles.yml
$env:DBT_BIGQUERY_PROJECT = "your-gcp-project-id"
$env:DBT_BIGQUERY_LOCATION = "US"
$env:DBT_IMPERSONATE_SERVICE_ACCOUNT = "bch-dbt-runner@your-gcp-project-id.iam.gserviceaccount.com"

uv run dbt deps
uv run dbt debug --target dev
uv run dbt parse --no-partial-parse
uv run dbt compile --no-introspect
uv run dbt run --target dev --select address_balances
uv run dbt test --target dev
uv run dbt docs generate --target dev
```

## Cost warning

The one full refresh measured 945.6 GiB for `stg_transactions`; the
five-model DAG processed about 958 GiB. That is close to the 1 TiB
monthly free query allowance. The profile caps each job at 100 GiB
locally and 50 GiB in CI, and CI rebuilds only `address_balances`
against the existing snapshot. A full refresh is a deliberate, manual
decision; do not repeat it casually. The cap is a guardrail, not a
billing guarantee.

## CI

The parse job runs without cloud credentials on every pull request and
push to `main`. The build job runs when a BigQuery project variable is
configured: it authenticates through workload identity federation (no
service-account key), compiles, rebuilds `address_balances` under the
50 GiB cap, tests, and generates docs.

Repository **Actions variables** (identifiers, not secrets):

| Variable | Use |
|---|---|
| `GCP_PROJECT_ID` | Target project; the workflow maps it to `DBT_BIGQUERY_PROJECT`. |
| `GCP_BIGQUERY_LOCATION` | Job location; defaults to `US`, matching the public source. |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Provider name from the infrastructure `workload_identity.provider` output. |
| `GCP_SERVICE_ACCOUNT` | dbt service-account email from the infrastructure outputs. `GCP_DBT_SERVICE_ACCOUNT` also works. |
| `DBT_BIGQUERY_PROJECT` | Local/legacy fallback when `GCP_PROJECT_ID` is not set. |
| `DBT_MAXIMUM_BYTES_BILLED` | Optional per-job byte cap; profile defaults are 100 GiB local, 50 GiB CI. |
