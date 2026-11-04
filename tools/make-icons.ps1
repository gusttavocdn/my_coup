<#
.SYNOPSIS
  Generates the PWA icons in web/icons/ from the game's card art.
.DESCRIPTION
  Draws the Duque card (assets/arte/duque@2x.png) on a lavender background:
  icon-144/192/512.png, icon-maskable-512.png (card kept inside the 80% safe
  zone so any mask shape keeps it) and apple-touch-icon-180.png (opaque, as iOS
  wants). Uses System.Drawing, so it needs no extra install on Windows.
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tools/make-icons.ps1
#>
param()

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$CardPath = Join-Path $ProjectRoot "assets\arte\duque@2x.png"
$OutDir = Join-Path $ProjectRoot "web\icons"
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

# Lavender family of src/client/ui_kit.gd (BACKGROUND f7f5fb, BORDER d8d4e0).
$BackgroundTop = [System.Drawing.ColorTranslator]::FromHtml("#efeafa")
$BackgroundBottom = [System.Drawing.ColorTranslator]::FromHtml("#cfc6e6")

$Card = [System.Drawing.Image]::FromFile($CardPath)
try {
	# name, pixel size, card height as a fraction of the icon.
	$Icons = @(
		@("icon-144.png", 144, 0.74),
		@("icon-192.png", 192, 0.74),
		@("icon-512.png", 512, 0.74),
		@("icon-maskable-512.png", 512, 0.56),
		@("apple-touch-icon-180.png", 180, 0.74)
	)
	foreach ($Icon in $Icons) {
		$Size = [int]$Icon[1]
		$Bitmap = New-Object System.Drawing.Bitmap($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
		$Graphics = [System.Drawing.Graphics]::FromImage($Bitmap)
		try {
			$Graphics.SmoothingMode = "HighQuality"
			$Graphics.InterpolationMode = "HighQualityBicubic"
			$Graphics.PixelOffsetMode = "HighQuality"
			$Rect = New-Object System.Drawing.Rectangle(0, 0, $Size, $Size)
			$Brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($Rect, $BackgroundTop, $BackgroundBottom, 90.0)
			$Graphics.FillRectangle($Brush, $Rect)
			$Brush.Dispose()
			$Height = $Size * [double]$Icon[2]
			$Width = $Height * $Card.Width / $Card.Height
			$Graphics.DrawImage($Card, [single](($Size - $Width) / 2), [single](($Size - $Height) / 2), [single]$Width, [single]$Height)
		}
		finally {
			$Graphics.Dispose()
		}
		$Target = Join-Path $OutDir $Icon[0]
		$Bitmap.Save($Target, [System.Drawing.Imaging.ImageFormat]::Png)
		$Bitmap.Dispose()
		Write-Host "wrote $Target"
	}
}
finally {
	$Card.Dispose()
}
