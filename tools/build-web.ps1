param()

$ErrorActionPreference = "Stop"
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$PresetPath = Join-Path $ProjectRoot "export_presets.cfg"
$OutputDir = Join-Path $ProjectRoot "build\web"
$OutputHtml = Join-Path $OutputDir "index.html"

if (-not (Test-Path -LiteralPath $PresetPath)) {
	throw "Missing export_presets.cfg. Restore the committed Web preset before building."
}
$PresetContents = Get-Content -LiteralPath $PresetPath -Raw
if ($PresetContents -notmatch '(?m)^name="Web"\s*$' -or $PresetContents -notmatch '(?m)^platform="Web"\s*$') {
	throw "export_presets.cfg does not contain a Web export preset."
}

$GodotCommand = $env:GODOT_BIN
if (-not $GodotCommand -and (Get-Command "godot" -ErrorAction SilentlyContinue)) {
	$GodotCommand = "godot"
}
if (-not $GodotCommand) {
	$InEngineSection = $false
	foreach ($Line in Get-Content -LiteralPath (Join-Path $ProjectRoot "project.yaml")) {
		if ($Line -match '^engine:\s*$') {
			$InEngineSection = $true
			continue
		}
		if ($InEngineSection -and $Line -match '^\S') { break }
		if ($InEngineSection -and $Line -match '^\s+path:\s*"?(.+?)"?\s*$') {
			$GodotCommand = $Matches[1]
			break
		}
	}
}
if (-not $GodotCommand -or -not (Test-Path -LiteralPath $GodotCommand)) {
	throw "Godot 4.7.2 was not found on PATH or at engine.path in project.yaml. Set GODOT_BIN to the pinned Godot 4.7.2 editor executable."
}
if ($GodotCommand -match '_win64\.exe$') {
	$ConsoleCommand = $GodotCommand -replace '_win64\.exe$', '_win64_console.exe'
	if (Test-Path -LiteralPath $ConsoleCommand) { $GodotCommand = $ConsoleCommand }
}
$VersionOutput = (& $GodotCommand --version 2>&1 | Out-String).Trim()
if ($VersionOutput -notmatch '^4\.7\.2') {
	throw "Expected Godot 4.7.2 to match the installed Web export templates; found '$VersionOutput'. Set GODOT_BIN to the pinned editor."
}

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
Push-Location $ProjectRoot
try {
	$ExportOutput = & $GodotCommand --headless --path $ProjectRoot --export-release Web $OutputHtml 2>&1
	$ExportCode = $LASTEXITCODE
	$ExportOutput | ForEach-Object { Write-Host $_ }
	if ($ExportCode -ne 0) {
		throw "Godot Web export failed with exit code $ExportCode. Install the 4.7.2 export templates in Godot's Editor > Manage Export Templates > Download and Install, then retry."
	}
	$RequiredFiles = @("index.html", "index.wasm", "index.pck", "index.js")
	$MissingFiles = @($RequiredFiles | Where-Object { -not (Test-Path -LiteralPath (Join-Path $OutputDir $_)) })
	if ($MissingFiles.Count -gt 0) {
		throw "Web export did not produce: $($MissingFiles -join ', '). Install the 4.7.2 export templates in Godot's Editor > Manage Export Templates > Download and Install, then retry."
	}
	Write-Host "Web export ready: $OutputDir"
}
finally {
	Pop-Location
}
