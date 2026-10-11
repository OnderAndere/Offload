# Called by the docs-writer when it has finished: records the current
# code state as documented. tool/build_release.dart --copy builds a release
# for use only when this marker holds the current state (DD-020).
. "$PSScriptRoot\common.ps1"
Enter-ProjectRoot
$state = Get-DocsState
Set-Content -Path $DocsMarker -Value $state -Encoding Ascii
"Documentation recorded as up to date for state $state"
