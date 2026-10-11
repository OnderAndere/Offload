# Called by the architecture-reviewer ONLY after a PASS verdict, with the tree
# hash it reviewed (taken with `git write-tree` at the start of the review).
# Refuses if the staged content changed since. Trust assumption: nothing
# technically stops the main agent from running this; CLAUDE.md forbids it.
param([Parameter(Mandatory = $true)][string]$Tree)
. "$PSScriptRoot\common.ps1"
Enter-ProjectRoot
$current = Get-StagedTreeHash
if (-not $current) { Write-Error 'No staged tree to approve.'; exit 1 }
if ($current -ne $Tree.Trim()) {
    Write-Error "Staged tree changed during the review (reviewed $Tree, now $current). Review again."
    exit 1
}
Set-Content -Path $ReviewMarker -Value $current -Encoding Ascii
"Review approval recorded for staged tree $current"
