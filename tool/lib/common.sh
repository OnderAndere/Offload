#!/usr/bin/env bash
# Shared helpers for the release checks in tool/.

# Reads an allowlist file: one entry per line, '#' starts a comment.
read_allowlist() {
  sed -e 's/#.*$//' -e 's/[[:space:]]*$//' -e '/^$/d' "$1" | sort -u
}

# Prints the Android SDK root (ANDROID_HOME, ANDROID_SDK_ROOT or the default
# Windows location), or fails.
android_sdk() {
  local sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
  if [ -z "$sdk" ] && [ -n "${LOCALAPPDATA:-}" ]; then
    sdk="$(cygpath "$LOCALAPPDATA" 2>/dev/null || echo "$LOCALAPPDATA")/Android/Sdk"
  fi
  [ -d "$sdk" ] || { echo "Android SDK not found; set ANDROID_HOME" >&2; return 1; }
  echo "$sdk"
}

# Warns on stderr when an environment override of a check is active, so a
# PASS obtained with a test override is never mistaken for a real one.
warn_overrides() {
  local name
  for name in "$@"; do
    [ -n "${!name:-}" ] && echo "NOTICE: override active: $name=${!name}" >&2
  done
  return 0
}

# Prints the path of aapt2 from the newest installed build-tools.
find_aapt2() {
  local sdk dir exe
  sdk="$(android_sdk)" || return 1
  dir="$(ls -d "$sdk"/build-tools/*/ 2>/dev/null | sort -V | tail -n 1)"
  for exe in "${dir}aapt2" "${dir}aapt2.exe"; do
    [ -x "$exe" ] && { echo "$exe"; return 0; }
  done
  echo "aapt2 not found in $sdk/build-tools" >&2
  return 1
}
