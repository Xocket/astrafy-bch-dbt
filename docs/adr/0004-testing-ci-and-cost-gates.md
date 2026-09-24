# ADR 0004: Testing, CI, and cost gates

- **Status:** Accepted
- **Date:** 2026-09-24
- **Requirements:** CC-8, CC-9, CC-10, NFR-1, NFR-2, NFR-5

## Context

The challenge requires dbt execution on pull requests through the Terraform-provisioned identity. The BigQuery adapter still needs authentication even when compile introspection is disabled, so a credential-free parse job cannot also perform the authenticated compile. The first live full refresh processed 945.6 GiB for `stg_transactions` (with the remaining models bringing the DAG to roughly 958 GiB), so a repeated PR refresh would consume most of the monthly free-tier query allowance. Abandoned tables must also not create unnecessary storage cost.

## Decision

Use two CI jobs:

1. A credential-free job installs the locked toolchain and runs `dbt parse --no-partial-parse`.
2. An authenticated job uses Workload Identity Federation, runs `dbt compile --no-introspect`, then visibly runs `dbt run --select address_balances`, `dbt test`, and `dbt docs generate`. The selected model is a cost-capped downstream smoke build against the provisioned snapshot; the complete source refresh is run manually and recorded as evidence.

The profile uses the provisioned `staging` dataset as its default schema; model configs explicitly select `staging` and `marts`, while Terraform grants the dbt identity a custom `bigquery.datasets.create/get` role so dbt can ensure schemas exist without project-wide data editing. The local profile defaults to a 100 GiB per-job cap and CI to 50 GiB; the one-time full refresh was run with the measured 945.6 GiB source scan. The local profile may set `DBT_IMPERSONATE_SERVICE_ACCOUNT` to the Terraform-provisioned dbt identity while retaining user ADC locally; CI omits that setting because `google-github-actions/auth` already supplies the short-lived service-account credential. Every generated table receives application/layer labels and a seven-day expiration timestamp.

## Rationale

This preserves a fast public validation path, uses no long-lived CI credential, mirrors the brief's explicit `dbt run` wording, retains content tests, and makes cost/storage behavior visible.

## Alternatives rejected

- Credential-free BigQuery compile: the adapter attempts authentication even with `--no-introspect`.
- Only `dbt build`: correct technically, but less explicit against the brief's named command.
- Service-account JSON key: simpler debugging, but introduces a durable credential and rotation burden.
- Unlimited table lifetime: simpler local use, but creates avoidable storage risk for a submission project.

## Consequences

An initial push can receive a green parse result before cloud variables exist. Once the target project and WIF values are configured, the same workflow performs the full authenticated build. Seven-day expiration means a later run recreates expired tables; this is acceptable because every model is a full-refresh table.
