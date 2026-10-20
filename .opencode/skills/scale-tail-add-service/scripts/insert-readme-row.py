#!/usr/bin/env python3
"""Insert a service row into the ScaleTail root README catalog.

The catalog tables are fixed-width Markdown tables, and rows go in
alphabetical order of the bold name (case-insensitive). Doing that by hand is
error-prone: the padding rarely matches on the first try and the row lands in
the wrong position. This script finds the category table, computes the column
widths from the existing rows, builds the new row with matching padding, and
inserts it at the alphabetical position.

Usage:
    insert-readme-row.py "<category heading>" "<Name>" "<Description>" "<directory>"

Example:
    python3 .opencode/skills/scale-tail-add-service/scripts/insert-readme-row.py \
        "Development tools" "Termix" \
        "Server management platform with SSH terminals and more." "termix"

Run from the repository root. The script edits README.md in place and prints
the inserted row. It refuses to insert a duplicate link.
"""

import re
import sys
from pathlib import Path

README = Path("README.md")


def main() -> int:
    if len(sys.argv) != 5:
        print(__doc__.strip(), file=sys.stderr)
        return 2
    category, name, description, directory = sys.argv[1:]

    lines = README.read_text().splitlines(keepends=True)

    # Locate the category heading, then its table (heading row, separator,
    # data rows until a non-table line).
    heading = next(
        (i for i, line in enumerate(lines) if line.startswith("### ") and category.lower() in line.lower()),
        None,
    )
    if heading is None:
        print(f"error: no category heading matching {category!r}", file=sys.stderr)
        return 1
    start = next((i for i in range(heading, len(lines)) if lines[i].startswith("| ")), None)
    if start is None:
        print("error: category has no table", file=sys.stderr)
        return 1
    end = next((i for i in range(start + 2, len(lines)) if not lines[i].startswith("|")), len(lines))

    link = f"[Details](services/{directory})"
    if any(link in line for line in lines):
        print(f"error: {directory!r} is already in the catalog", file=sys.stderr)
        return 1

    # Column widths come from the widest existing cells, so the new row always
    # aligns even if a few legacy rows are short.
    widths = [0, 0, 0]
    for line in lines[start + 2 : end]:
        cells = line.split("|")[1:-1]
        for i, cell in enumerate(cells[:3]):
            widths[i] = max(widths[i], len(cell))

    def row(name: str, desc: str, link: str) -> str:
        cells = [f" **{name}** ", f" {desc} ", f" {link} "]
        return "|" + "|".join(cell.ljust(widths[i]) for i, cell in enumerate(cells)) + "|\n"

    new_row = row(name, description, link)

    # Insertion point: before the first row whose bold name sorts after the
    # new one, ignoring case; append at the end when it sorts last.
    position = end
    for i in range(start + 2, end):
        m = re.match(r"\| \*\*(.+?)\*\*", lines[i])
        if m and m.group(1).lower() > name.lower():
            position = i
            break

    lines.insert(position, new_row)
    README.write_text("".join(lines))
    print(new_row, end="")
    return 0


if __name__ == "__main__":
    sys.exit(main())
