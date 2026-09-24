# ADR 0005: Separate infrastructure and analytics repositories

- **Status:** Accepted
- **Date:** 2026-09-24
- **Requirements:** CC-11, CC-12, GEN-3, NFR-2

## Context

The challenge identifies a Terraform deliverable and a dbt/GitHub Actions deliverable. Their permissions, review risks, and lifecycles differ: infrastructure can plan or apply cloud resources, while the dbt identity can create and replace only its two owned BigQuery datasets.

## Decision

Maintain two public repositories:

- `astrafy-bch-infra` for bootstrap/primary Terraform, remote state, WIF, and read-only infrastructure plan CI.
- `astrafy-bch-dbt` for dbt models, tests, dbt CI, report, and submission evidence.

They are linked through documentation and non-secret GitHub Actions variable names rather than shared credentials.

## Rationale

Separate repositories mirror the two requested deliverables, minimize credential scope, simplify public review, and allow infrastructure and data changes to evolve independently.

## Alternatives rejected

- Monorepo: simpler cross-repository change, but combines high-privilege infrastructure and data code under one trust boundary.
- One Terraform repository with an embedded dbt project: obscures the requested deliverable boundary.

## Consequences

A consistent variable contract and cross-links must be maintained. A change to WIF or dataset naming can require coordinated pull requests, but the resulting review and permission boundaries are intentional.
