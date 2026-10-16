#!/usr/bin/env python3
"""Create MobileSheets import CSVs with unique titles per voice.

The original scan CSV intentionally stores several voices for one piece with
the same title. That is useful as a page index, but MobileSheets library sync
cannot reliably identify repeated title/file pairs. This converter keeps the
source files and metadata intact while making each imported song title unique.
"""

from __future__ import annotations

import argparse
import csv
from pathlib import Path


def qualify_csv(source: Path, target: Path) -> None:
    with source.open("r", encoding="utf-8-sig", newline="") as handle:
        rows = list(csv.reader(handle, delimiter=";"))

    if not rows:
        return

    header = rows[0]
    normalized = [column.strip().lower() for column in header]
    try:
        title_index = normalized.index("title")
        source_index = next(
            index
            for index, column in enumerate(normalized)
            if column in {"source types", "sourcetypes", "source_types"}
        )
    except StopIteration as error:
        raise ValueError(f"{source}: source types column missing") from error
    except ValueError as error:
        raise ValueError(f"{source}: title column missing") from error

    used_titles: dict[str, int] = {}
    qualified_rows = [header]
    for row_number, row in enumerate(rows[1:], start=1):
        if not row or not any(cell.strip() for cell in row):
            continue
        if len(row) <= title_index or len(row) <= source_index:
            raise ValueError(f"{source}: row {row_number} has too few columns")

        base_title = row[title_index].strip()
        voice = row[source_index].strip() or f"Stimme {row_number}"
        candidate = f"{base_title} [{voice}]"
        occurrence = used_titles.get(candidate, 0) + 1
        used_titles[candidate] = occurrence
        if occurrence > 1:
            candidate = f"{candidate} #{occurrence}"
        row[title_index] = candidate
        qualified_rows.append(row)

    target.parent.mkdir(parents=True, exist_ok=True)
    with target.open("w", encoding="utf-8", newline="") as handle:
        csv.writer(handle, delimiter=";", lineterminator="\n").writerows(
            qualified_rows
        )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source_root", type=Path)
    parser.add_argument("target_root", type=Path)
    args = parser.parse_args()

    files = sorted(args.source_root.rglob("import.csv"))
    if not files:
        raise SystemExit(f"Keine import.csv unter {args.source_root} gefunden")

    for source in files:
        relative = source.relative_to(args.source_root)
        qualify_csv(source, args.target_root / relative)

    print(f"{len(files)} CSV-Dateien verarbeitet")


if __name__ == "__main__":
    main()
