# Builds windows/runner/resources/app_icon.ico from branding/icon_app_512.png (DD-019).
#
# Usage: powershell -File tool/gen_windows_icon.ps1
#
# The .ico holds PNG-compressed images at the sizes Windows asks for (title bar, taskbar,
# Explorer, system tray). Scaling uses System.Drawing from .NET: no extra tool or package.
# Small sizes are only downscaled; a hand-pixelled 16 px variant is open point SPEC Q25.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$source = Join-Path $root 'branding\icon_app_512.png'
$target = Join-Path $root 'windows\runner\resources\app_icon.ico'
$sizes = 16, 20, 24, 32, 40, 48, 64, 256

$original = [System.Drawing.Image]::FromFile($source)
try {
    $images = foreach ($size in $sizes) {
        $bitmap = New-Object System.Drawing.Bitmap $size, $size
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.DrawImage($original, 0, 0, $size, $size)
        $graphics.Dispose()
        $stream = New-Object System.IO.MemoryStream
        $bitmap.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
        $bitmap.Dispose()
        , $stream.ToArray()
        $stream.Dispose()
    }
} finally {
    $original.Dispose()
}

# ICO layout: header, one 16-byte directory entry per image, then the PNG data.
$out = New-Object System.IO.MemoryStream
$writer = New-Object System.IO.BinaryWriter $out
$writer.Write([UInt16]0)                # reserved
$writer.Write([UInt16]1)                # type: icon
$writer.Write([UInt16]$sizes.Count)
$offset = 6 + 16 * $sizes.Count
for ($i = 0; $i -lt $sizes.Count; $i++) {
    $side = if ($sizes[$i] -ge 256) { 0 } else { $sizes[$i] }  # 0 means 256
    $writer.Write([Byte]$side)          # width
    $writer.Write([Byte]$side)          # height
    $writer.Write([Byte]0)              # no palette
    $writer.Write([Byte]0)              # reserved
    $writer.Write([UInt16]1)            # colour planes
    $writer.Write([UInt16]32)           # bits per pixel
    $writer.Write([UInt32]$images[$i].Length)
    $writer.Write([UInt32]$offset)
    $offset += $images[$i].Length
}
foreach ($image in $images) { $writer.Write($image) }
$writer.Flush()
[System.IO.File]::WriteAllBytes($target, $out.ToArray())
Write-Output "wrote $target ($($sizes -join ', ') px)"
