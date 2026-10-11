#!/usr/bin/env bash
# Fails when UI code contains a string literal with letters in it: every
# user-visible text must come from the ARB files (CLAUDE.md rule 3, DD-009).
#
# Checks lib/presentation/ (screens, widgets, state). Deliberately broad: any
# quoted literal containing a letter is reported, not only those inside
# Text(...). Skipped:
#   - import, export, part and library directives;
#   - comment lines (//, ///, /* and * continuation lines);
#   - lines marked with `// l10n-ignore: <reason>` for a literal that is not
#     shown to the user (e.g. a Key or a route name).
#
# Usage: tool/check_hardcoded_strings.sh [dir ...]
set -euo pipefail
cd "$(dirname "$0")/.."

dirs=("$@")
[ "${#dirs[@]}" -gt 0 ] || dirs=(lib/presentation)
for d in "${dirs[@]}"; do
  [ -d "$d" ] || { echo "FAIL: directory not found: $d" >&2; exit 2; }
done

# A single- or double-quoted literal (optionally raw) containing a letter.
literal="(^|[^A-Za-z0-9_])r?('[^']*[A-Za-z][^']*'|\"[^\"]*[A-Za-z][^\"]*\")"

hits="$(grep -rnE --include='*.dart' "$literal" "${dirs[@]}" |
  grep -vE '^[^:]+:[0-9]+:[[:space:]]*(import|export|part|library)[[:space:]]' |
  grep -vE '^[^:]+:[0-9]+:[[:space:]]*(//|/\*|\*)' |
  grep -vE '// l10n-ignore: [^[:space:]]' || true)"

if [ -n "$hits" ]; then
  echo "$hits"
  echo "FAIL: string literals in UI code; move them to lib/l10n/app_nl.arb and app_en.arb" >&2
  exit 1
fi
echo "PASS: no hardcoded strings in ${dirs[*]}"
