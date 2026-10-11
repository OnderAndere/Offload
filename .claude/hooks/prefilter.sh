#!/usr/bin/env bash
# Cheap pre-filter for the PowerShell hooks: only start powershell.exe when the
# hook input matches a glob, so ordinary tool calls stay fast.
# Usage: prefilter.sh '<glob>' <script.ps1>   (hook JSON on stdin)
input=$(cat)
# shellcheck disable=SC2254  # $1 is intentionally a glob pattern
case "$input" in
  $1) printf '%s' "$input" |
        powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(dirname "$0")/$2" ;;
esac
