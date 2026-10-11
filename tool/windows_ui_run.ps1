# Runs the Windows release build in a sandbox, clicks, sends keys and takes a
# screenshot of the window: a check by hand of what widget tests cannot show
# (layout of the real window, keys through the real Windows input path).
#
#   powershell -File tool/windows_ui_run.ps1 -Out shot.png [-KeysFile keys.txt]
#       [-ClickX 48 -ClickY 67] [-Width 1280 -Height 800]
#
# Needs an interactive desktop session and no other running Offload (one
# instance). LOCALAPPDATA points to a temporary folder, so the database and
# the key are created there and removed afterwards; real data is never
# touched.
#
# The keys file has one step per line:
#   - text and SendKeys codes, e.g. `Bel Jan !vandaag`, `{ENTER}`, `{DOWN}`;
#   - `VK:11+32` for a combination as real key presses, hexadecimal virtual
#     key codes pressed in order and released in reverse (here Ctrl+2).
#     Use this for Ctrl combinations: they are sent with their scan code,
#     which Flutter needs (see CLAUDE.md, pitfalls);
#   - `CLICK:x,y` clicks at (x, y) from the window's top left corner;
#   - `SHOT:file.png` takes a screenshot of the window area now (a window on
#     top of it, such as a save window, is in it too);
#   - `WAIT:ms` waits longer than the usual pause between steps.
# Before the keys, the script clicks at (ClickX, ClickY) in the window (from
# its top left corner, title bar included): Windows does not let a background
# process bring a window to the front, so without a click the keys go to
# another window. ClickX -1 skips the click.
param(
  [Parameter(Mandatory = $true)][string]$Out,
  [string]$KeysFile = '',
  [int]$ClickX = 640,
  [int]$ClickY = 12,
  [int]$Width = 1280,
  [int]$Height = 800
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type @'
using System; using System.Runtime.InteropServices;
public static class UiRun {
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr h, int x, int y, int w, int hh, bool r);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint x, uint y, uint d, UIntPtr e);
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
  [DllImport("user32.dll")] public static extern uint MapVirtualKey(uint code, uint type);
  public struct RECT { public int Left, Top, Right, Bottom; }
}
'@

function Press([byte]$vk, [uint32]$flags) {
  [UiRun]::keybd_event($vk, [byte][UiRun]::MapVirtualKey($vk, 0), $flags, [UIntPtr]::Zero)
  Start-Sleep -Milliseconds 60
}

if (Get-Process offload -ErrorAction SilentlyContinue) {
  throw 'Another Offload is running; close it first (one instance).'
}
$exe = Join-Path (Get-Location) 'build\windows\x64\runner\Release\offload.exe'
if (-not (Test-Path $exe)) { throw "No release build at $exe" }
$keys = if ($KeysFile) { Get-Content -Encoding UTF8 $KeysFile } else { @() }

$sandbox = Join-Path $env:TEMP ('offload_ui_' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $sandbox | Out-Null
$realLocalAppData = $env:LOCALAPPDATA
$env:LOCALAPPDATA = $sandbox
$app = Start-Process -FilePath $exe -PassThru
$env:LOCALAPPDATA = $realLocalAppData
try {
  $h = [IntPtr]::Zero
  for ($i = 0; $i -lt 40 -and $h -eq [IntPtr]::Zero; $i++) {
    Start-Sleep -Milliseconds 500; $app.Refresh(); $h = $app.MainWindowHandle
  }
  if ($h -eq [IntPtr]::Zero) { throw 'The window did not appear.' }
  [void][UiRun]::MoveWindow($h, 40, 40, $Width, $Height, $true)
  Start-Sleep -Seconds 4
  $r = New-Object UiRun+RECT
  function Click([int]$x, [int]$y) {
    [void][UiRun]::GetWindowRect($h, [ref]$r)
    [void][UiRun]::SetCursorPos($r.Left + $x, $r.Top + $y)
    [UiRun]::mouse_event(2, 0, 0, 0, [UIntPtr]::Zero)
    [UiRun]::mouse_event(4, 0, 0, 0, [UIntPtr]::Zero)
    Start-Sleep -Milliseconds 700
  }
  function Shot([string]$file) {
    [void][UiRun]::GetWindowRect($h, [ref]$r)
    $bmp = New-Object System.Drawing.Bitmap ($r.Right - $r.Left), ($r.Bottom - $r.Top)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($r.Left, $r.Top, 0, 0, $bmp.Size)
    $bmp.Save($file)
    $g.Dispose(); $bmp.Dispose()
    "screenshot: $file"
  }
  if ($ClickX -ge 0) { Click $ClickX $ClickY }
  foreach ($step in $keys) {
    if ($step.StartsWith('CLICK:')) {
      $xy = $step.Substring(6).Split(',')
      Click ([int]$xy[0]) ([int]$xy[1])
    } elseif ($step.StartsWith('SHOT:')) {
      Shot $step.Substring(5)
    } elseif ($step.StartsWith('WAIT:')) {
      Start-Sleep -Milliseconds ([int]$step.Substring(5))
    } elseif ($step.StartsWith('VK:')) {
      $vks = @($step.Substring(3).Split('+') | ForEach-Object { [byte][Convert]::ToInt32($_, 16) })
      foreach ($v in $vks) { Press $v 0 }
      [array]::Reverse($vks)
      foreach ($v in $vks) { Press $v 2 }
    } else {
      [System.Windows.Forms.SendKeys]::SendWait($step)
    }
    Start-Sleep -Milliseconds 900
  }
  Start-Sleep -Seconds 1
  Shot $Out
} finally {
  Stop-Process -Id $app.Id -Force -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 1
  Remove-Item -Recurse -Force $sandbox -ErrorAction SilentlyContinue
}
