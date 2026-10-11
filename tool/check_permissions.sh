#!/usr/bin/env bash
# Fails when the release APK requests any permission that is not in
# tool/allowed_permissions.txt (REQ-003, REQ-015, DD-005, DD-008).
#
# Usage: tool/check_permissions.sh [path/to/app-release.apk]
# Build first: flutter build apk --release
set -euo pipefail
cd "$(dirname "$0")/.."
. tool/lib/common.sh
warn_overrides ALLOWED_PERMISSIONS

apk="${1:-build/app/outputs/flutter-apk/app-release.apk}"
allowlist="${ALLOWED_PERMISSIONS:-tool/allowed_permissions.txt}"
# Hard rules from CLAUDE.md: these may never be allow-listed.
forbidden='android.permission.INTERNET android.permission.SCHEDULE_EXACT_ALARM android.permission.USE_EXACT_ALARM'

[ -f "$apk" ] || { echo "APK not found: $apk (run: flutter build apk --release)" >&2; exit 2; }
aapt2="$(find_aapt2)"
allowed="$(read_allowlist "$allowlist")"

for p in $forbidden; do
  if grep -qxF "$p" <<<"$allowed"; then
    echo "FAIL: $p is in $allowlist, but it is forbidden (CLAUDE.md hard rules)" >&2
    exit 1
  fi
done

dump="$("$aapt2" dump permissions "$apk")"
# Fail closed if the output format is not the one this parser understands.
if ! grep -q "^package: " <<<"$dump"; then
  echo "FAIL: unexpected aapt2 output (no 'package:' line); cannot verify permissions" >&2
  exit 2
fi
requested="$(sed -n "s/^uses-permission[a-z0-9-]*: name='\([^']*\)'.*/\1/p" <<<"$dump" | sort -u)"

status=0
while IFS= read -r p; do
  [ -z "$p" ] && continue
  if grep -qxF "$p" <<<"$allowed"; then
    echo "ok       $p"
    continue
  fi
  case "$p" in
    android.permission.INTERNET)
      echo "FAIL     $p: network access is forbidden (REQ-003, DD-008)" ;;
    android.permission.SCHEDULE_EXACT_ALARM | android.permission.USE_EXACT_ALARM)
      echo "FAIL     $p: exact alarms are forbidden (DD-005)" ;;
    *)
      echo "FAIL     $p: not in $allowlist (new permissions need product-owner approval)" ;;
  esac
  status=1
done <<<"$requested"

if [ "$status" -eq 0 ]; then
  echo "PASS: $(basename "$apk") requests only allow-listed permissions"
else
  echo "FAIL: $(basename "$apk") requests permissions that are not allowed" >&2
fi
exit "$status"
