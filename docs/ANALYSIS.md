# Final Analysis

Date: 2026-09-24. This page records the final review of the submission
against the brief, and every weakness found and fixed during that
review. `docs/REQUIREMENTS.md` carries the full matrix; this page
summarizes it.

## Requirement status

**Verified** = recorded evidence. **Implemented** = source exists with
measured evidence. **Open** = a human gate remains. **Out of scope** =
not a brief requirement.

### Design Challenge (all in `docs/report/report.pdf`)

| ID | Status | Evidence |
|---|---|---|
| DC-1 – DC-7 | Verified | Report sections 2–8: platform design, Google Cloud, open-source licensing, GitOps/DataOps, all six sources, department BI, ML |
| DC-8 | Verified | 14-page PDF; compiled twice with MiKTeX `pdflatex`; no fatal errors; no undefined references |

### Coding Challenge

| ID | Status | Evidence |
|---|---|---|
| CC-1 – CC-4 | Verified | Applied bootstrap and dev stacks (`main.tf`, `bootstrap/`); outputs inspected |
| CC-5 | Verified | 6,495,376 staged rows; `models/staging/` |
| CC-6 | Verified | 35,686,444 ledger rows; 5,774,930 mart rows; `models/marts/address_balances.sql` |
| CC-7 | Verified | 4,544 excluded addresses; `tests/assert_protocol_coinbase_*.sql` |
| CC-8 – CC-10 | Verified | Run 36054350409 (parse and authenticated build) |
| CC-11 – CC-12 | Verified | Both public repositories |

### Generic, submission, non-functional

| ID | Status | Evidence |
|---|---|---|
| GEN-1 – GEN-3 | Verified | Docs, lockfile/pinned toolchain, green CI in both repos |
| SUB-1 – SUB-2 | Verified | `docs/report/report.pdf`; both public URLs |
| SUB-3 | Open | Human action: send the reply email |
| NFR-1 | Implemented | ~958 GiB measured full DAG; 100/50 GiB caps; EUR 2 alert budget. A guardrail, not a guarantee |
| NFR-2 – NFR-5 | Verified | WIF runs; no key resource; ignores + history scan; 45/45 tests |

### Out of scope

No brief requirement is out of scope. `environments/prod.tfvars` in the
infrastructure repository is a validated configuration that is
intentionally not applied: the brief requires one live environment, and
production promotion is a separate decision (ADR 0005 there).

## Weaknesses found in review, and their fixes

1. **Contradicted status.** The README said no model run, cloud apply, or
   authenticated pull request was claimed, while the recorded runs show
   all three passed. Fixed: the README and every status row now match the
   recorded evidence, with run links.
2. **Stale page count.** Two documents said the PDF has 39 pages; it had
   41 before the rewrite and 14 after. Fixed: the page count is stated
   once, in the README, and matches the compiled file.
3. **Stale test claims.** The report listed seven singular tests as "not
   claimed executed" although all 45 tests (37 generic + 8 singular)
   passed in the live run; `docs/REQUIREMENTS.md` kept "Planned"
   statuses and a verification map that said live runs were pending; the
   infrastructure evidence matrix said the WIF run was pending. Fixed:
   all three documents now state the verified results.
4. **Duplicated evidence.** The submission checklist repeated the
   compliance matrix almost row for row; the email draft was submission
   scaffolding; live evidence was split across pages. Fixed: one
   evidence page (`docs/COMPLIANCE.md`); both scaffolding files were
   deleted and purged from Git history; ADRs 0001 and 0002 were trimmed
   without changing any decision.
5. **Report bloat and hidden warnings.** The report was 41 pages with
   three diagrams, status boxes in every section, and meta sections such
   as "how to evaluate this report". The preamble set `\hfuzz` to
   100pt, which hid overfull lines from the log. Fixed: rewritten to 14
   pages in a plain style with one diagram and no boxes; the new
   preamble reports layout warnings honestly (0 overfull and 0 undefined
   references; 13 underfull line-spacing warnings remain, which are
   cosmetic).

## Number consistency check

Cross-checked and consistent across the README, the evidence page, and
the report: window bounds; 6,495,376 / 4,544 / 35,686,444 / 5,774,930
rows; 12.54 GiB storage; 945.6 GiB and ~958 GiB scans; 45/45 tests; run
IDs 36054350409 (dbt) and 36054422871 (infra).
