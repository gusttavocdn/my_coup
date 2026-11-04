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
	# Story 015: Godot's PWA output lacks short_name, theme_color, the 192 and
	# maskable icons, and its service worker only caches wasm/pck lazily.
	foreach ($Icon in @("icon-192.png", "icon-maskable-512.png")) {
		Copy-Item -LiteralPath (Join-Path $ProjectRoot "web\icons\$Icon") -Destination (Join-Path $OutputDir $Icon) -Force
	}
	$Utf8 = New-Object System.Text.UTF8Encoding($false)
	$ManifestPath = Join-Path $OutputDir "index.manifest.json"
	$Manifest = [System.IO.File]::ReadAllText($ManifestPath) | ConvertFrom-Json
	$Manifest | Add-Member -NotePropertyName short_name -NotePropertyValue "Coup" -Force
	$Manifest | Add-Member -NotePropertyName theme_color -NotePropertyValue "#f7f5fb" -Force
	$Manifest | Add-Member -NotePropertyName lang -NotePropertyValue "pt-BR" -Force
	$Manifest | Add-Member -NotePropertyName scope -NotePropertyValue "./" -Force
	$Manifest | Add-Member -NotePropertyName id -NotePropertyValue "./index.html" -Force
	$Manifest.icons = @(
		@{ src = "index.144x144.png"; sizes = "144x144"; type = "image/png"; purpose = "any" },
		@{ src = "icon-192.png"; sizes = "192x192"; type = "image/png"; purpose = "any" },
		@{ src = "index.512x512.png"; sizes = "512x512"; type = "image/png"; purpose = "any" },
		@{ src = "icon-maskable-512.png"; sizes = "512x512"; type = "image/png"; purpose = "maskable" }
	)
	[System.IO.File]::WriteAllText($ManifestPath, ($Manifest | ConvertTo-Json -Depth 5), $Utf8)

	$WorkerPath = Join-Path $OutputDir "index.service.worker.js"
	$Worker = [System.IO.File]::ReadAllText($WorkerPath)
	$CachedPattern = '(?m)^const CACHED_FILES = \[(.*)\];\r?$'
	$CacheablePattern = '(?m)^const CACHEABLE_FILES = \["index\.wasm","index\.pck"\];\r?$'
	if ($Worker -notmatch $CachedPattern -or $Worker -notmatch $CacheablePattern) {
		throw "index.service.worker.js has an unexpected layout; update the patch in tools/build-web.ps1."
	}
	# Install fetches the whole shell (page, js, wasm, pck, icons) into the build-id
	# cache together: a build is cached completely or not at all, never mixed.
	$Worker = [regex]::Replace($Worker, $CachedPattern, 'const CACHED_FILES = [$1,"index.wasm","index.pck","icon-192.png","icon-maskable-512.png","index.144x144.png","index.512x512.png","index.manifest.json"];')
	$Worker = [regex]::Replace($Worker, $CacheablePattern, 'const CACHEABLE_FILES = [];')

	# Install bypasses the HTTP cache so a long max-age on index.html or index.js can never
	# store an old shell next to the new wasm and pck.
	$InstallOld = 'cache.addAll(CACHED_FILES)'
	$InstallNew = 'cache.addAll(CACHED_FILES.map((name) => new Request(name, { cache: ''reload'' })))'
	# Offline navigation to a URL that is not in the cache (for example index.html?x=1) gets the
	# Portuguese offline page instead of the browser error page.
	$FallbackOld = "`t`t`t`t// Try network if don't have it in cache.`r`n`t`t`t`tconst response = await fetchAndCache(event, cache, isCacheable);`r`n`t`t`t`treturn response;"
	$FallbackNew = "`t`t`t`t// Try network if don't have it in cache; offline navigations get the offline page.`r`n`t`t`t`ttry {`r`n`t`t`t`t`treturn await fetchAndCache(event, cache, isCacheable);`r`n`t`t`t`t} catch (e) {`r`n`t`t`t`t`tif (isNavigate) {`r`n`t`t`t`t`t`treturn caches.match(OFFLINE_URL);`r`n`t`t`t`t`t}`r`n`t`t`t`t`tthrow e;`r`n`t`t`t`t}"
	$Eol = if ($Worker.Contains("`r`n")) { "`r`n" } else { "`n" }
	$FallbackOld = $FallbackOld.Replace("`r`n", $Eol)
	$FallbackNew = $FallbackNew.Replace("`r`n", $Eol)
	if (-not $Worker.Contains($InstallOld) -or -not $Worker.Contains($FallbackOld)) {
		throw "index.service.worker.js has an unexpected install or fetch handler; update the patch in tools/build-web.ps1."
	}
	$Worker = $Worker.Replace($InstallOld, $InstallNew).Replace($FallbackOld, $FallbackNew)
	[System.IO.File]::WriteAllText($WorkerPath, $Worker, $Utf8)

	Write-Host "Web export ready: $OutputDir"
}
finally {
	Pop-Location
}
