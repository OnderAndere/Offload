#!/usr/bin/env bash
# Fails when the app ships a Dart package or a native library that is not
# allow-listed (DD-008: every dependency is reviewed for permissions and
# network use; native code often arrives transitively).
#
# Checks:
#   1. Dart packages that end up in the app (direct and transitive, no dev
#      dependencies) against tool/allowed_packages.txt;
#   2. native code in the release APK (lib/<abi>/*.so) and in the Windows
#      release bundle (every *.dll and *.exe, also in subdirectories) against
#      tool/allowed_native_libs.txt;
#   3. that this native code, apart from Flutter's engine (dart:io has
#      sockets) and the runner, imports no network functions or libraries
#      (DD-008, DD-021): socket calls and name lookups on Android, Winsock,
#      WinHTTP, WinINet and the like on Windows. Needs an NDK for its
#      llvm-nm and llvm-readobj.
#
# Usage: tool/check_dependencies.sh [path/to/app-release.apk]
#   SKIP_WINDOWS=1  skip the Windows bundle explicitly (e.g. on a Linux CI
#                   job); otherwise a missing bundle is a failure.
# Rebuild first: the check only means something for fresh release builds.
set -euo pipefail
cd "$(dirname "$0")/.."
. tool/lib/common.sh
warn_overrides ALLOWED_PACKAGES ALLOWED_NATIVE_LIBS WINDOWS_BUNDLE SKIP_WINDOWS

apk="${1:-build/app/outputs/flutter-apk/app-release.apk}"
windows_bundle="${WINDOWS_BUNDLE:-build/windows/x64/runner/Release}"
allowed_packages="$(read_allowlist "${ALLOWED_PACKAGES:-tool/allowed_packages.txt}")"
allowed_native="$(read_allowlist "${ALLOWED_NATIVE_LIBS:-tool/allowed_native_libs.txt}")"
status=0

check() { # kind name allowed-list
  if grep -qxF "$2" <<<"$3"; then
    echo "ok       $1 $2"
  else
    echo "FAIL     $1 $2: not allow-listed (review it for permissions, network use and native code; product-owner approval needed)"
    status=1
  fi
}

# 1. Dart packages (top-level entries of the dependency sections, root excluded).
# Overridden transitive packages are listed under "dependency overrides:", so
# that section is included too (a dev-only override then needs an allowlist
# line as well; failing closed is intended).
packages="$(dart pub deps --no-dev --style=list |
  awk '/^(dependencies|dependency overrides|transitive dependencies):/ {s=1; next} /^[^- ]/ {s=0} s && /^- / {print $2}' |
  sort -u)"
[ -n "$packages" ] || { echo "FAIL: could not list Dart packages" >&2; exit 2; }
while IFS= read -r p; do check package "$p" "$allowed_packages"; done <<<"$packages"

# 2a. Native libraries in the APK.
if [ -f "$apk" ]; then
  so_files="$(unzip -Z1 "$apk" | sed -n 's#^lib/[^/]*/\([^/]*\.so\)$#\1#p' | sort -u)"
  while IFS= read -r f; do [ -n "$f" ] && check native "$f" "$allowed_native"; done <<<"$so_files"
else
  echo "FAIL: APK not found: $apk (run: flutter build apk --release)" >&2
  status=1
fi

# 2b. Native code in the Windows release bundle, including subdirectories such
#     as native_assets/ that build hooks install.
if [ "${SKIP_WINDOWS:-}" = "1" ]; then
  echo "skip     Windows bundle (SKIP_WINDOWS=1)"
elif [ -d "$windows_bundle" ]; then
  binaries="$(find "$windows_bundle" -type f \( -iname '*.dll' -o -iname '*.exe' \) -printf '%f\n' | sort -u)"
  while IFS= read -r f; do [ -n "$f" ] && check native "$f" "$allowed_native"; done <<<"$binaries"
else
  echo "FAIL: Windows bundle not found: $windows_bundle (run: flutter build windows --release, or set SKIP_WINDOWS=1)" >&2
  status=1
fi

# 3. No network imports in the native code that is not Flutter's own.
engine_files='libflutter.so flutter_windows.dll offload.exe'
elf_network='^(socket|socketpair|connect|bind|listen|accept|accept4|send|sendto|sendmsg|recv|recvfrom|recvmsg|getaddrinfo|getnameinfo|gethostbyname|gethostbyname2|gethostbyname_r|gethostbyaddr|res_query|res_search)$'
pe_network='^(ws2_32|wsock32|mswsock|winhttp|wininet|urlmon|dnsapi|iphlpapi|websocket|winhttpcom)\.dll$'
nm="$(find_llvm_tool llvm-nm)" || { echo "FAIL: no llvm-nm for the network check" >&2; exit 2; }
readobj="$(find_llvm_tool llvm-readobj)" || { echo "FAIL: no llvm-readobj for the network check" >&2; exit 2; }
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
check_network() { # label file
  local raw imports pattern found
  # A file the tool cannot read fails: when in doubt, fail (DD-008).
  case "$2" in
    *.so)
      # libapp.so (Dart AOT data) may import nothing, so empty is fine.
      if ! raw="$("$nm" -D --undefined-only "$2")"; then
        echo "FAIL     network $1: llvm-nm cannot read it"
        status=1
        return
      fi
      imports="$(awk '{print $NF}' <<<"$raw" | sed 's/@.*//')"
      pattern="$elf_network" ;;
    *)
      if ! raw="$("$readobj" --coff-imports "$2")"; then
        echo "FAIL     network $1: llvm-readobj cannot read it"
        status=1
        return
      fi
      imports="$(sed -n 's/^ *Name: //p' <<<"$raw" | tr 'A-Z' 'a-z')"
      # Every real DLL imports something (KERNEL32.dll at least).
      if [ -z "$imports" ]; then
        echo "FAIL     network $1: no imports found, not a readable DLL"
        status=1
        return
      fi
      pattern="$pe_network" ;;
  esac
  found="$(grep -E "$pattern" <<<"$imports" || true)"
  if [ -n "$found" ]; then
    echo "FAIL     network $1: imports $(echo $found)"
    status=1
  else
    echo "ok       network $1"
  fi
}
if [ -f "$apk" ]; then
  while IFS= read -r entry; do
    name="${entry##*/}"
    case " $engine_files " in *" $name "*) continue ;; esac
    unzip -p "$apk" "$entry" >"$work/$name"
    check_network "${entry#lib/}" "$work/$name"
  done < <(unzip -Z1 "$apk" | grep -E '^lib/[^/]+/[^/]+\.so$')
fi
if [ "${SKIP_WINDOWS:-}" != "1" ] && [ -d "$windows_bundle" ]; then
  while IFS= read -r f; do
    name="${f##*/}"
    case " $engine_files " in *" $name "*) continue ;; esac
    check_network "windows/$name" "$f"
  done < <(find "$windows_bundle" -type f -iname '*.dll')
fi

if [ "$status" -eq 0 ]; then
  echo "PASS: all shipped packages and native libraries are allow-listed; no network imports"
else
  echo "FAIL: unlisted packages, native libraries or network imports found" >&2
fi
exit "$status"
