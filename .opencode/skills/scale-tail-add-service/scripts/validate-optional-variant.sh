#!/usr/bin/env bash
# Validate that a ScaleTail service's commented-out optional blocks parse as
# valid Compose YAML once uncommented.
#
# The repo's convention writes optional services (databases, daemons) as
# commented blocks whose lines start with "#key:" or "#  <two spaces>child".
# Users enable them by deleting only the leading "#". This script reproduces
# that in a throwaway copy outside the repository and runs
# `docker compose config` on the result, so a broken optional block cannot
# ship unnoticed.
#
# Usage:
#   validate-optional-variant.sh <service-dir> <key> [<key>...]
#
#   <service-dir>  Path to the service directory, e.g. services/bytestash
#   <key>          Compose service key inside the commented block, without the
#                  trailing colon, e.g. "db" or "guacd". Repeat for each
#                  optional service; uncommenting one variant at a time keeps
#                  the test focused.
#
# The copy lands in a temp dir, is validated there, and is removed again, so
# no runtime files (config/, ts/state, data) appear in the repository.
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <service-dir> <key> [<key>...]" >&2
  exit 2
fi

service_dir=$1
shift
keys=$*

if [ ! -f "$service_dir/compose.yaml" ]; then
  echo "error: $service_dir/compose.yaml not found" >&2
  exit 2
fi

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT
cp "$service_dir/compose.yaml" "$service_dir/.env" "$tmp_dir/"

KEYS="$keys" python3 - "$tmp_dir/compose.yaml" <<'PY'
import os
import re
import sys

path = sys.argv[1]
keys = "|".join(re.escape(k) for k in os.environ["KEYS"].split())
# A block starts at a commented key line ("#db:") and runs through the
# following commented lines. Instruction lines ("# # ...") inside it stay
# commented; everything else loses exactly one leading "#".
start = re.compile(r"^(\s*)#(" + keys + r"):")
in_block = False
out = []
for line in open(path):
    m = start.match(line)
    if m:
        in_block = True
        out.append(line[: line.index("#")] + line[line.index("#") + 1:])
        continue
    if in_block:
        stripped = line.lstrip(" ")
        if not stripped.startswith("#"):
            in_block = False
        elif stripped.startswith("# "):
            # "# # ..." instruction lines and full-sentence comments stay
            # commented; real block content ("# key:", "#  key:", "# - item")
            # loses exactly one leading "#" and keeps its indentation.
            content = stripped[1:].lstrip()
            if re.match(r"[a-z0-9_.-]+:|-\s", content):
                idx = line.index("#")
                out.append(line[:idx] + line[idx + 1:])
            else:
                out.append(line)
            continue
    out.append(line)
open(path, "w").write("".join(out))
PY

cd "$tmp_dir"
# Give required variables a dummy value instead of editing .env, as CI does.
required=$(grep -ohE '\$\{[A-Za-z0-9_]+:\?' compose.yaml .env 2>/dev/null |
  sed -E 's/^\$\{//; s/:\?$/=dummy/' | sort -u || true)
# The uncommented variant may reference variables that .env leaves commented
# out (the user sets them when enabling the feature). Give those a dummy value
# too, so the validation reports real errors instead of "not set" warnings.
missing=$(comm -13 \
  <(grep -ohE '^[A-Za-z0-9_]+' .env 2>/dev/null | sort -u) \
  <(grep -ohE '\$\{[A-Za-z0-9_]+' compose.yaml | sed 's/^\${//' | sort -u))
for var in $missing; do
  [ -n "$required" ] && required="$required $var=dummy" || required="$var=dummy"
done
env $required docker compose config --quiet
echo "OK: uncommented variant(s) for key(s): $keys validate"
