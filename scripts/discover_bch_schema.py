#!/usr/bin/env python3
"""Capture the live BigQuery schema and three-month scan profile for BCH sources."""

from __future__ import annotations

import argparse
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

from google.cloud import bigquery
from google.cloud.bigquery import QueryJobConfig


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", required=True, help="Google Cloud quota/billing project")
    parser.add_argument("--source-project", default="bigquery-public-data")
    parser.add_argument("--dataset", default="crypto_bitcoin_cash")
    parser.add_argument("--location", default="US")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument(
        "--max-execution-bytes",
        type=int,
        default=10 * 1024**3,
        help="Do not execute a profiling query whose dry run exceeds this limit",
    )
    return parser.parse_args()


def bytes_label(value: int | None) -> str:
    if value is None:
        return "unknown"
    units = ("B", "KiB", "MiB", "GiB", "TiB")
    size = float(value)
    for unit in units:
        if size < 1024 or unit == units[-1]:
            return f"{size:.2f} {unit} ({value:,} bytes)"
        size /= 1024
    return f"{value:,} bytes"


def quote_identifier(value: str) -> str:
    return f"`{value.replace('`', '``')}`"


def run_query(
    client: bigquery.Client,
    sql: str,
    location: str,
    max_execution_bytes: int,
) -> tuple[list[list[Any]], int | None, bool]:
    dry_run = client.query(
        sql,
        location=location,
        job_config=QueryJobConfig(dry_run=True, use_query_cache=False),
    )
    estimated_bytes = dry_run.total_bytes_processed
    if estimated_bytes is not None and estimated_bytes > max_execution_bytes:
        return [], estimated_bytes, False

    executed = client.query(
        sql,
        location=location,
        job_config=QueryJobConfig(use_query_cache=False),
    )
    return [list(row) for row in executed.result()], estimated_bytes, True


def schema_rows(
    client: bigquery.Client,
    source_project: str,
    dataset: str,
    location: str,
) -> list[list[Any]]:
    information_schema = f"{source_project}.{dataset}.INFORMATION_SCHEMA.COLUMNS"
    sql = f"""
        select
          table_name,
          ordinal_position,
          column_name,
          data_type,
          is_nullable
        from {quote_identifier(information_schema)}
        order by table_name, ordinal_position
    """
    return [list(row) for row in client.query(sql, location=location).result()]


def main() -> None:
    args = parse_args()
    client = bigquery.Client(project=args.project)
    generated_at = datetime.now(UTC).replace(microsecond=0).isoformat()

    tables: dict[str, dict[str, Any]] = {}
    for table_name, position, column_name, data_type, nullable in schema_rows(
        client, args.source_project, args.dataset, args.location
    ):
        table = tables.setdefault(
            table_name,
            {"columns": [], "metadata": None},
        )
        table["columns"].append(
            {
                "position": int(position),
                "name": column_name,
                "type": data_type,
                "nullable": nullable,
            }
        )

    for table_name in sorted(tables):
        tables[table_name]["metadata"] = client.get_table(
            f"{args.source_project}.{args.dataset}.{table_name}"
        )

    transactions = f"`{args.source_project}.{args.dataset}.transactions`"
    bounds_sql = f"select max(block_timestamp) from {transactions}"
    bounds, bounds_estimated, bounds_executed = run_query(
        client, bounds_sql, args.location, args.max_execution_bytes
    )
    max_timestamp = bounds[0][0] if bounds_executed and bounds else None

    profile_sql = f"""
        with bounds as (
          select max(block_timestamp) as max_block_timestamp
          from {transactions}
        ),
        source_rows as (
          select
            transaction.block_timestamp_month,
            transaction.block_timestamp,
            transaction.is_coinbase
          from {transactions} as transaction
          cross join bounds
          where transaction.block_timestamp_month >=
                date_trunc(
                  date_sub(date(bounds.max_block_timestamp), interval 3 month),
                  month
                )
            and transaction.block_timestamp >=
                timestamp(date_sub(date(bounds.max_block_timestamp), interval 3 month))
            and transaction.block_timestamp <= bounds.max_block_timestamp
        )
        select
          count(*) as transaction_count,
          min(block_timestamp) as first_block_timestamp,
          max(block_timestamp) as last_block_timestamp,
          countif(is_coinbase) as protocol_coinbase_count
        from source_rows
    """
    profile, profile_estimated, profile_executed = run_query(
        client, profile_sql, args.location, args.max_execution_bytes
    )

    lines = [
        "# Bitcoin Cash BigQuery Dataset Schema",
        "",
        f"Generated at: `{generated_at}`",
        "",
        f"Dataset: `{args.source_project}.{args.dataset}`",
        "",
        "This file is generated by `scripts/discover_bch_schema.py`; it records facts observed from the live source rather than assumptions from the roadmap.",
        "",
        "## Source observations",
        "",
        f"- Latest source timestamp query: **{'executed' if bounds_executed else 'dry-run only'}**; estimated scan: `{bytes_label(bounds_estimated)}`.",
        f"- Three-month profile query: **{'executed' if profile_executed else 'dry-run only'}**; estimated scan: `{bytes_label(profile_estimated)}`.",
    ]
    if max_timestamp is not None:
        lines.append(f"- Latest source block timestamp: `{max_timestamp.isoformat()}`.")
    if profile_executed and profile:
        count, first_timestamp, last_timestamp, coinbase_count = profile[0]
        lines.extend(
            [
                f"- Transactions in the latest source-relative three-month window: `{count:,}`.",
                f"- Window first timestamp: `{first_timestamp.isoformat() if first_timestamp else 'none'}`.",
                f"- Window last timestamp: `{last_timestamp.isoformat() if last_timestamp else 'none'}`.",
                f"- Protocol coinbase transactions in the window: `{coinbase_count:,}`.",
            ]
        )
    else:
        lines.append("- Profile rows were not executed because the configured safety limit was exceeded.")
    lines.extend(["", "## Tables and columns", ""])

    for table_name in sorted(tables):
        table = tables[table_name]
        metadata = table["metadata"]
        lines.extend([f"### `{table_name}`", ""])
        if metadata.time_partitioning is not None:
            partition = metadata.time_partitioning
            lines.append(
                f"- Time partitioning: `{partition.field or 'ingestion-time'}`, type `{partition.type_}`."
            )
        elif metadata.range_partitioning is not None:
            lines.append("- Range partitioning is configured.")
        else:
            lines.append("- Partitioning: not configured.")
        lines.append(
            f"- Clustering fields: `{', '.join(metadata.clustering_fields or ['none'])}`."
        )
        lines.extend(
            [
                "",
                "| # | Column | Type | Nullable |",
                "|---:|---|---|:---:|",
            ]
        )
        for column in table["columns"]:
            lines.append(
                f"| {column['position']} | `{column['name']}` | `{column['type']}` | "
                f"{'yes' if column['nullable'] == 'YES' else 'no'} |"
            )
        lines.append("")

    lines.extend(
        [
            "## Interpretation notes",
            "",
            "- The rolling window is anchored to the latest timestamp available in the public source so a delayed source does not silently produce an empty model.",
            "- Source profiling never executes when its dry-run estimate exceeds the configured safety limit.",
            "- Model logic must use the observed schema and address arrays; this generated document is the source of truth for the current environment.",
            "",
        ]
    )

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {args.output}")
    print(f"Bounds dry-run bytes: {bounds_estimated}")
    print(f"Profile dry-run bytes: {profile_estimated}")


if __name__ == "__main__":
    main()
