#!/usr/bin/env python3
"""
split_db_records.py
-------------------
Scan an EPICS IOC .db file, peel off all *ai*, *ao*, *bi*, and *bo* records into their
own files (ai.db, ao.db, bi.db, bo.db), and rewrite the original file so it only
contains the leftover record types (calc, longin, whatever).

Usage::

    python split_db_records.py Forno_Vertical_IOC.db

The script is intentionally simple (regex‑based) and assumes braces in records are
balanced and don’t appear in comments/strings.
"""

import re
import sys
from pathlib import Path

# Regex to catch the first line of a record definition, e.g.  record(ai, "PV") {
RECORD_START = re.compile(r"^\s*record\(\s*(\w+)\s*,", re.IGNORECASE)
# End of record is a lone closing brace at line start (allow spaces)
END_BRACE = re.compile(r"^\s*}\s*$")

BUCKETS = {"ai": "ai.db", "ao": "ao.db", "bi": "bi.db", "bo": "bo.db"}


def split_db(db_path: Path) -> None:
    """Process *db_path*, write bucket files, and rewrite the original."""

    lines = db_path.read_text().splitlines()

    # Collectors
    buckets: dict[str, list[str]] = {k: [] for k in BUCKETS}
    remainder: list[str] = []

    in_record = False
    record_type: str | None = None
    buffer: list[str] = []

    for line in lines:
        if not in_record:
            m = RECORD_START.match(line)
            if m:
                # Start of a record block
                in_record = True
                record_type = m.group(1).lower()
                buffer = [line]
            else:
                remainder.append(line)
        else:
            buffer.append(line)
            if END_BRACE.match(line):
                # Record ends; stash accordingly
                if record_type in buckets:
                    buckets[record_type].extend(buffer)
                else:
                    remainder.extend(buffer)
                in_record = False
                record_type = None
                buffer = []

    # Write bucket files if they received content
    for rtype, fname in BUCKETS.items():
        blk = buckets[rtype]
        if blk:
            out_path = db_path.with_name(fname)
            out_path.write_text("\n".join(blk) + "\n")
            print(f"Wrote {out_path} ({len(blk)} lines)")

    # Overwrite original with leftovers
    db_path.write_text("\n".join(remainder) + "\n")
    print(f"Updated {db_path} (now {len(remainder)} lines)")


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit("Usage: python split_db_records.py <Forno_Vertical_IOC.db>")

    path = Path(sys.argv[1])
    if not path.exists():
        sys.exit(f"File not found: {path}")

    split_db(path)


if __name__ == "__main__":
    main()
