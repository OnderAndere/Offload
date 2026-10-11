# PreToolUse (Bash|PowerShell): Claude may only commit exactly the staged
# changes that the architecture-reviewer approved. Fails closed.
#
# Rules for a commit tool call:
# - `git commit` is the only git command in the call (no add/rm/stage/... in
#   the same call: the gate checks the index before the call runs);
# - no pathspecs, `--`, -a/--all, -o/--only, -i/--include, -p/--patch, so git
#   commits the index and nothing else;
# - other commit-creating commands (merge, cherry-pick, revert, rebase, am,
#   pull) are denied; they need the product owner.
# Docs-only commits (*.md outside CLAUDE.md and .claude/) need no review.
. "$PSScriptRoot\common.ps1"

function Deny([string]$reason) {
    Write-HookJson @{
        hookSpecificOutput = @{
            hookEventName            = 'PreToolUse'
            permissionDecision       = 'deny'
            permissionDecisionReason = "Commit blocked: $reason (review gate, see CLAUDE.md)."
        }
    }
    exit 0
}

$cmd = ''
try {
    $hookInput = Read-HookInput
    if (-not $hookInput) { exit 0 }
    $cmd = [string]$hookInput.tool_input.command
    $git = Get-GitInvocations $cmd

    $commitLike = @('merge', 'cherry-pick', 'revert', 'rebase', 'am', 'pull')
    foreach ($g in $git) {
        if ($g.Sub -in $commitLike -and -not ($g.Args -contains '--abort')) {
            Deny "``git $($g.Sub)`` creates commits outside the review gate; ask the product owner"
        }
    }
    $commits = @($git | Where-Object { $_.Sub -eq 'commit' })
    if ($commits.Count -eq 0) {
        # Fail closed on commits the parser cannot attribute to git, e.g. git
        # called through a variable (`$G commit`) or an alias.
        foreach ($tokens in (Get-SimpleCommands $cmd)) {
            if ($tokens | Where-Object { $_ -match '(?i)^(.*[\\/])?git(\.exe)?$' }) { continue }
            if ($tokens | Where-Object { $_ -in @('commit', 'commit-tree') }) {
                Deny 'a commit was found that the gate cannot verify; call `git commit` directly'
            }
        }
        exit 0
    }
    if ($git.Count -gt 1) {
        Deny 'run `git commit` as the only git command in its tool call (stage and inspect in separate calls first)'
    }

    # Parse the commit options: anything that is not an option or an option
    # value is a pathspec, which would commit working-tree content.
    $valueLong = @('--message', '--file', '--reuse-message', '--reedit-message', '--author',
        '--date', '--template', '--cleanup', '--fixup', '--squash', '--trailer')
    $forbiddenLong = @('--all', '--only', '--include', '--patch', '--interactive', '--pathspec-from-file')
    $a = $commits[0].Args
    for ($k = 0; $k -lt $a.Count; $k++) {
        $tok = $a[$k]
        if ($tok -eq '--') { Deny 'pathspecs are not allowed; commit the staged index only' }
        if ($tok.StartsWith('--')) {
            $name = ($tok -split '=', 2)[0]
            if ($name -in $forbiddenLong) { Deny "``$name`` is not allowed; stage explicitly in a separate call" }
            if ($name -in $valueLong -and $tok -notmatch '=') { $k++ }
            continue
        }
        if ($tok.StartsWith('-') -and $tok.Length -gt 1) {
            $chars = $tok.Substring(1).ToCharArray()
            for ($c = 0; $c -lt $chars.Count; $c++) {
                $ch = [string]$chars[$c]
                if ($ch -cin @('a', 'o', 'i', 'p')) { Deny "``-$ch`` is not allowed; stage explicitly in a separate call" }
                if ($ch -cin @('m', 'F', 'C', 'c', 't')) {
                    if ($c -eq $chars.Count - 1) { $k++ }
                    break
                }
            }
            continue
        }
        Deny "pathspec ``$tok`` is not allowed; commit the staged index only"
    }

    Enter-ProjectRoot
    $staged = @(git diff --cached --name-only --no-renames)
    if ($staged.Count -eq 0) { exit 0 }  # nothing staged: git itself refuses
    $needsReview = @($staged | Where-Object {
            $_ -notmatch '\.md$' -or $_ -eq 'CLAUDE.md' -or $_ -like '.claude/*'
        })
    if ($needsReview.Count -eq 0) { exit 0 }  # docs-only

    $tree = Get-StagedTreeHash
    $approved = if (Test-Path $ReviewMarker) { (Get-Content $ReviewMarker -Raw).Trim() } else { '' }
    if ($tree -and $approved -eq $tree) { exit 0 }
    Deny ("the staged changes (tree $tree) have not been approved; run the architecture-reviewer " +
        'subagent on them. Any change after its review needs a new review')
} catch {
    if (-not $cmd) { $cmd = [string]$script:HookRawInput }
    if ($cmd -match '(?i)commit|merge|cherry-pick|revert|rebase') {
        Deny "the gate could not verify this command ($($_.Exception.Message))"
    }
    exit 0
}
