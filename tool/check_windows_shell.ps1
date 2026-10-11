# Manual check of the Windows hotkey, system tray and close-to-tray
# (T1.7 step B, REQ-017, DD-010) on a fresh release build:
#   flutter build windows --release
#   powershell -File tool/check_windows_shell.ps1
# Needs an interactive desktop session (it sends real key presses) and no
# other running Offload. Runs in a temporary LOCALAPPDATA, so the real
# Offload data and key are never touched. Every line should end in True.
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type @'
using System; using System.Runtime.InteropServices;
public static class U {
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
  [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr FindWindow(string cls, string title);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  public struct RECT { public int Left, Top, Right, Bottom; }
}
'@
function Hotkey {
  [U]::keybd_event(0x5B, 0, 0, [UIntPtr]::Zero)   # Win down
  [U]::keybd_event(0x10, 0, 0, [UIntPtr]::Zero)   # Shift down
  [U]::keybd_event(0x42, 0, 0, [UIntPtr]::Zero)   # B down
  [U]::keybd_event(0x42, 0, 2, [UIntPtr]::Zero)
  [U]::keybd_event(0x10, 0, 2, [UIntPtr]::Zero)
  [U]::keybd_event(0x5B, 0, 2, [UIntPtr]::Zero)
}
function Shot($h, $name) {
  $r = New-Object U+RECT; [void][U]::GetWindowRect($h, [ref]$r)
  $bmp = New-Object System.Drawing.Bitmap ($r.Right - $r.Left), ($r.Bottom - $r.Top)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.CopyFromScreen($r.Left, $r.Top, 0, 0, $bmp.Size)
  $bmp.Save((Join-Path $sandboxShots "$name.png")); $g.Dispose(); $bmp.Dispose()
}

$sandbox = Join-Path $env:TEMP ("offload_sandbox_" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $sandbox | Out-Null
$sandboxShots = $env:TEMP
$env:LOCALAPPDATA = $sandbox
$exe = (Resolve-Path (Join-Path $PSScriptRoot '..\build\windows\x64\runner\Release\offload.exe')).Path
$p = Start-Process -FilePath $exe -PassThru
try {
  Start-Sleep -Seconds 8
  $h = [U]::FindWindow('eu.marandos.offload.MainWindow', [NullString]::Value)
  "window found: $($h -ne [IntPtr]::Zero)"

  # Minimized -> hotkey -> capture -> minimized again.
  [void][U]::ShowWindow($h, 6); Start-Sleep -Seconds 1
  Hotkey; Start-Sleep -Seconds 2
  "hotkey restores and activates: $((-not [U]::IsIconic($h)) -and ([U]::GetForegroundWindow() -eq $h))"
  [System.Windows.Forms.SendKeys]::SendWait('Via de sneltoets'); Start-Sleep -Milliseconds 500
  [System.Windows.Forms.SendKeys]::SendWait('{ENTER}'); Start-Sleep -Seconds 2
  "Enter saves and the window is minimized again: $([U]::IsIconic($h))"
  [void][U]::ShowWindow($h, 9); Start-Sleep -Seconds 1
  Shot $h 'offload_shell_inbox'

  # Behind another window -> hotkey -> capture -> that window in front again.
  # A helper window of our own (never the user's programs).
  $helperCode = 'Add-Type -AssemblyName System.Windows.Forms; ' +
    '$f = New-Object System.Windows.Forms.Form; $f.Text = ''offload-check''; ' +
    '$f.TopMost = $false; [void]$f.ShowDialog()'
  $other = Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden `
    -ArgumentList '-NoProfile', '-Command', $helperCode -PassThru
  Start-Sleep -Seconds 4
  $front = [U]::GetForegroundWindow()
  Hotkey; Start-Sleep -Seconds 2
  "hotkey from behind activates: $([U]::GetForegroundWindow() -eq $h)"
  [System.Windows.Forms.SendKeys]::SendWait('Achter een ander venster'); Start-Sleep -Milliseconds 500
  [System.Windows.Forms.SendKeys]::SendWait('{ENTER}'); Start-Sleep -Seconds 2
  "the other window is in front again: $([U]::GetForegroundWindow() -eq $front)"
  Stop-Process -Id $other.Id -ErrorAction SilentlyContinue

  # Closing hides to the tray; the hotkey still works.
  [void][U]::PostMessage($h, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero)   # WM_CLOSE
  Start-Sleep -Seconds 2
  "close hides to the tray and keeps running: $((-not [U]::IsWindowVisible($h)) -and (-not $p.HasExited))"
  Hotkey; Start-Sleep -Seconds 2
  "hotkey brings it back from the tray: $([U]::IsWindowVisible($h) -and ([U]::GetForegroundWindow() -eq $h))"

  # Tray menu with the keyboard (WM_CONTEXTMENU on WM_APP+1): last item = quit.
  [void][U]::PostMessage($h, 0x8001, [IntPtr]::Zero, [IntPtr](0x0001007B))
  Start-Sleep -Seconds 1
  [System.Windows.Forms.SendKeys]::SendWait('{UP}'); Start-Sleep -Milliseconds 300
  [System.Windows.Forms.SendKeys]::SendWait('{ENTER}')
  Start-Sleep -Seconds 4
  "tray Quit ends the app: $($p.HasExited)"
  "screenshot of the inbox: $(Join-Path $sandboxShots 'offload_shell_inbox.png')"
} finally {
  if (-not $p.HasExited) { Stop-Process -Id $p.Id }
  Start-Sleep -Seconds 1
  Remove-Item -Recurse -Force $sandbox
}

# A start-up error (data without its key): the tray has no menu yet, so
# closing must really quit instead of hiding to the tray.
$broken = Join-Path $env:TEMP ("offload_sandbox_" + [guid]::NewGuid().ToString('N'))
$brokenData = Join-Path $broken 'eu.marandos.offload'
New-Item -ItemType Directory -Path $brokenData | Out-Null
Set-Content -Path (Join-Path $brokenData 'offload.db') -Value 'not a database'
$env:LOCALAPPDATA = $broken
$q = Start-Process -FilePath $exe -PassThru
try {
  Start-Sleep -Seconds 6
  $hb = [U]::FindWindow('eu.marandos.offload.MainWindow', [NullString]::Value)
  [void][U]::PostMessage($hb, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero)   # WM_CLOSE
  Start-Sleep -Seconds 4
  "on a start-up error, closing really quits: $($q.HasExited)"
} finally {
  if (-not $q.HasExited) { Stop-Process -Id $q.Id }
  Start-Sleep -Seconds 1
  Remove-Item -Recurse -Force $broken
}
