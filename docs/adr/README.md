# Architecture Decision Records

| ADR | Decision | Status |
|---|---|---|
| [0001](0001-window-and-materialization.md) | Source-relative window and full-refresh staging table | Accepted |
| [0002](0002-balance-semantics-and-multisig.md) | Three-month net movement and multisig attribution | Accepted |
| [0003](0003-protocol-coinbase-interpretation.md) | Protocol-coinbase interpretation | Accepted |
| [0004](0004-testing-ci-and-cost-gates.md) | Split parse/build CI, explicit dbt phases, retention, and cost evidence | Accepted |
| [0005](0005-repository-split.md) | Separate infrastructure and analytics repositories | Accepted |

The infrastructure repository contains its own decision index for project isolation, bootstrap state, WIF, BigQuery IAM, and reviewed delivery.
