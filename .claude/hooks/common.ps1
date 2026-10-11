# Shared helpers for the Offload Claude Code hooks (Windows PowerShell 5.1).
# Keep this file ASCII-only: PowerShell 5.1 reads BOM-less files as ANSI.

function Enter-ProjectRoot {
    $root = $env:CLAUDE_PROJECT_DIR
    if (-not $root) { $root = (git rev-parse --show-toplevel 2>$null) }
    if ($root) { Set-Location $root }
}

function Read-HookInput {
    [Console]::InputEncoding = [Text.Encoding]::UTF8
    $raw = [Console]::In.ReadToEnd()
    $script:HookRawInput = $raw
    if (-not $raw) { return $null }
    return $raw | ConvertFrom-Json
}

function Write-HookJson($object) {
    [Console]::OutputEncoding = [Text.Encoding]::UTF8
    [Console]::Out.Write(($object | ConvertTo-Json -Depth 5 -Compress))
}

# Splits a shell command into simple commands (token arrays). Line
# continuations are joined, here-strings/heredocs and quoted strings are
# replaced by a placeholder token, so text inside commit messages or echo
# arguments is never mistaken for a command or an option.
function Get-SimpleCommands([string]$text) {
    $t = $text -replace '\\\r?\n', ' ' -replace '`\r?\n', ' '
    $t = [regex]::Replace($t, "(?s)@'.*?'@|@`".*?`"@", ' _Q_ ')
    $t = [regex]::Replace($t, "(?s)<<-?\s*['`"]?(\w+)['`"]?.*?\n\s*\1\b", ' _Q_ ')
    $t = [regex]::Replace($t, "'[^']*'|`"(?:[^`"\\]|\\.)*`"", ' _Q_ ')
    $result = @()
    foreach ($segment in ($t -split '[;&|\r\n(){}]')) {
        $raw = @($segment.Trim() -split '\s+' | Where-Object { $_ })
        # Drop redirections (2>$null, >out.txt, "> file") so they are not
        # mistaken for arguments.
        $tokens = @()
        for ($r = 0; $r -lt $raw.Count; $r++) {
            if ($raw[$r] -match '^\d*[<>]+$') { $r++; continue }
            if ($raw[$r] -match '^\d*[<>]') { continue }
            $tokens += $raw[$r]
        }
        if ($tokens.Count -gt 0) { $result += , $tokens }
    }
    return , $result
}

# Returns @{ Sub = <git subcommand>; Args = <tokens after it> } for every git
# invocation in the command, skipping git's global options (-C <dir> etc.).
function Get-GitInvocations([string]$text) {
    $found = @()
    foreach ($tokens in (Get-SimpleCommands $text)) {
        for ($i = 0; $i -lt $tokens.Count; $i++) {
            if ($tokens[$i] -notmatch '(?i)^(.*[\\/])?git(\.exe)?$') { continue }
            $j = $i + 1
            while ($j -lt $tokens.Count -and $tokens[$j].StartsWith('-')) {
                if ($tokens[$j] -in @('-C', '-c', '--git-dir', '--work-tree', '--namespace')) { $j += 2 } else { $j += 1 }
            }
            if ($j -lt $tokens.Count) {
                $rest = if ($j + 1 -lt $tokens.Count) { $tokens[($j + 1)..($tokens.Count - 1)] } else { @() }
                $found += , @{ Sub = $tokens[$j].ToLower(); Args = @($rest) }
            }
            break
        }
    }
    return , $found
}

# Identity of exactly what is staged: the tree hash of the index.
function Get-StagedTreeHash {
    return (git write-tree 2>$null | Select-Object -Last 1)
}

# Content-based identity of the code the docs-writer last covered: the tree of
# the working copy (tracked + untracked, respecting .gitignore) without the
# docs-writer's own output, built in a throw-away index.
function Get-DocsState {
    $tmp = Join-Path $env:TEMP ('offload-docs-index-' + [guid]::NewGuid().ToString('N'))
    $env:GIT_INDEX_FILE = $tmp
    try {
        git add -A -- . ':!docs/user-manual' ':!docs/features.md' ':!CHANGELOG.md' 2>$null | Out-Null
        return (git write-tree 2>$null | Select-Object -Last 1)
    } finally {
        Remove-Item Env:GIT_INDEX_FILE -ErrorAction SilentlyContinue
        Remove-Item $tmp -Force -ErrorAction SilentlyContinue
    }
}

$ReviewMarker = '.claude/.qa-review-marker'
$DocsMarker = '.claude/.docs-marker'
