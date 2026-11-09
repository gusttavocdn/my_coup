param(
	[ValidateSet("start", "stop", "status", "internet", "funnel-on", "funnel-off")]
	[string]$Action = "status",
	# This PC's address on the local network; detected when omitted.
	[string]$Address = "",
	[int]$HelpPort = 8000
)
# Serves the game to other devices on the same network (Wi-Fi/LAN) from this PC, over HTTPS:
#   tools/lan-serve.ps1 start     Docker stack (Caddy + match server) at https://<this PC's IP>/
#                                 plus a help page with the CA certificate at http://<IP>:8000/
#   tools/lan-serve.ps1 stop
#   tools/lan-serve.ps1 status
#   tools/lan-serve.ps1 internet    Funnel only: the game on the internet and NOTHING open on the
#                                   local network (also reachable from the LAN through the link)
#   tools/lan-serve.ps1 funnel-on   publish the game on the internet with Tailscale Funnel
#                                   (https://<this PC>.<tailnet>.ts.net, valid certificate, no
#                                   warning; anyone with the link can play). Needs Funnel enabled
#                                   once on the tailnet; the command prints the page for that.
#   tools/lan-serve.ps1 funnel-off  stop publishing (the local network keeps working)
# Why HTTPS: Godot's Web export refuses to run on a page that is not a "secure context", and
# plain http:// to a LAN address is not one. Caddy issues a certificate for the IP from its own
# local certificate authority; a phone either trusts that CA once (the help page explains how,
# and the "Install app" button then works) or taps through the browser's certificate warning.
# Needs Docker Desktop, the image coup-server:latest (docker build -t coup-server:latest .) and
# build\web (tools\build-web.ps1).

$ErrorActionPreference = "Stop"
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$WebBuild = Join-Path $ProjectRoot "build\web"
$StackDir = Join-Path $ProjectRoot "build\lan-stack"
$CertDir = Join-Path $StackDir "help"
$PidFile = Join-Path $StackDir "help.pid"
$Project = "coup-lan"

function Get-LanAddress {
	if ($Address) { return $Address }
	$candidate = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
		Where-Object { $_.IPAddress -match '^(192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[01])\.)' -and $_.InterfaceAlias -notmatch 'WSL|vEthernet|Loopback|Docker|Tailscale|OpenVPN' } |
		Select-Object -First 1
	if (-not $candidate) { throw "No local network address found. Pass -Address 192.168.x.y." }
	return $candidate.IPAddress
}

function Test-Listening([int]$Port) {
	[bool](Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue)
}

function Stop-HelpServer {
	if (Test-Path -LiteralPath $PidFile) {
		Stop-Process -Id ([int](Get-Content -LiteralPath $PidFile)) -Force -ErrorAction SilentlyContinue
		Remove-Item -LiteralPath $PidFile -Force
	}
}

function Show-Status {
	$ip = Get-LanAddress
	$stack = docker compose -p $Project ps --format "{{.Name}} {{.Status}}" 2>$null
	if ($stack) { $stack | ForEach-Object { Write-Host "container: $_" } } else { Write-Host "containers: not running" }
	Write-Host ("help page :{0} {1}" -f $HelpPort, $(if (Test-Listening $HelpPort) { "listening" } else { "NOT listening" }))
	Write-Host ""
	Write-Host "Game (HTTPS)  : https://$ip/"
	Write-Host "Help + CA cert: http://${ip}:$HelpPort/"
	Write-Host "Other devices must be on the same network. Windows normally allows Docker Desktop and python;"
	Write-Host "if a device still cannot connect, run in an administrator PowerShell:"
	Write-Host "  New-NetFirewallRule -DisplayName 'Coup Online LAN' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 80,443,$HelpPort -RemoteAddress LocalSubnet -Profile Any"
}

# Copies the compose files and the web build into the stack directory. With -InternetOnly the
# stack publishes nothing but 127.0.0.1:8081 (the Funnel backend): no port is open on the
# local network, so https://<LAN IP>/ and the help page are gone.
function Sync-Stack([string]$Ip, [switch]$InternetOnly) {
	if (-not (Test-Path -LiteralPath (Join-Path $WebBuild "index.html"))) { throw "build\web is missing. Run tools\build-web.ps1 first." }
	New-Item -ItemType Directory -Force -Path (Join-Path $StackDir "site\current"), $CertDir | Out-Null
	Copy-Item -LiteralPath (Join-Path $ProjectRoot "deploy\docker-compose.yml"), (Join-Path $ProjectRoot "deploy\Caddyfile") -Destination $StackDir -Force
	Get-ChildItem -LiteralPath (Join-Path $StackDir "site\current") | Remove-Item -Recurse -Force
	Copy-Item -Path (Join-Path $WebBuild "*") -Destination (Join-Path $StackDir "site\current") -Recurse -Force
	Set-Content -LiteralPath (Join-Path $StackDir ".env") -Value "COUP_DOMAIN=$Ip"
	$override = Join-Path $StackDir "docker-compose.override.yml"
	if ($InternetOnly) {
		Set-Content -LiteralPath $override -Value "services:`n  caddy:`n    ports: !override`n      - `"127.0.0.1:8081:8081`"`n"
	} elseif (Test-Path -LiteralPath $override) {
		Remove-Item -LiteralPath $override -Force
	}
}

function Get-Tailscale {
	$exe = Get-Command tailscale -ErrorAction SilentlyContinue
	if ($exe) { return $exe.Source }
	$default = "C:\Program Files\Tailscale\tailscale.exe"
	if (Test-Path -LiteralPath $default) { return $default }
	throw "Tailscale not found. Install it and sign in, or use the local network only."
}

function Get-FunnelUrl {
	$tailscale = Get-Tailscale
	$status = (& $tailscale funnel status 2>&1 | Out-String)
	if ($status -match '(https://[A-Za-z0-9.-]+\.ts\.net)') { return $Matches[1] }
	return $null
}

switch ($Action) {
	"status" {
		Show-Status
		try {
			$url = Get-FunnelUrl
			if ($url) { Write-Host "Internet (Funnel): $url" } else { Write-Host "Internet (Funnel): off" }
		} catch { Write-Host "Internet (Funnel): Tailscale not available" }
	}
	"funnel-on" {
		if (-not (Test-Listening 8081)) { throw "The stack is not running. Run: tools\lan-serve.ps1 start" }
		$tailscale = Get-Tailscale
		# Serves http://127.0.0.1:8081 (Caddy, plain HTTP, loopback only) as https://<node>.ts.net.
		$output = (& $tailscale funnel --bg 8081 2>&1 | Out-String)
		$url = Get-FunnelUrl
		if (-not $url) {
			Write-Host $output
			throw "Funnel is not on yet. If the text above shows an enable link, open it, approve Funnel, then run this again."
		}
		Write-Host "Game on the internet: $url"
	}
	"internet" {
		# Internet only: Funnel on, nothing open on the local network.
		Stop-HelpServer
		Sync-Stack -Ip (Get-LanAddress) -InternetOnly
		Push-Location $StackDir
		try { docker compose -p $Project up -d --force-recreate } finally { Pop-Location }
		Start-Sleep -Seconds 5
		$output = (& (Get-Tailscale) funnel --bg 8081 2>&1 | Out-String)
		$url = Get-FunnelUrl
		if (-not $url) { Write-Host $output; throw "Funnel is not on. Enable it on the tailnet (the output above has the link), then run this again." }
		Write-Host "Game on the internet: $url   (local network: closed)"
	}
	"funnel-off" {
		& (Get-Tailscale) funnel reset
		Write-Host "Funnel is off. The game still works on the local network."
	}
	"stop" {
		try { & (Get-Tailscale) funnel reset 2>$null | Out-Null } catch { }
		Stop-HelpServer
		if (Test-Path -LiteralPath (Join-Path $StackDir "docker-compose.yml")) {
			Push-Location $StackDir
			try { docker compose -p $Project down } finally { Pop-Location }
		}
	}
	"start" {
		if (-not (Test-Path -LiteralPath (Join-Path $WebBuild "index.html"))) { throw "build\web is missing. Run tools\build-web.ps1 first." }
		$ip = Get-LanAddress
		Sync-Stack -Ip $ip
		Stop-HelpServer
		Push-Location $StackDir
		try { docker compose -p $Project up -d --force-recreate } finally { Pop-Location }

		# Caddy creates its local CA on first start; wait for the root certificate, then export it.
		$exported = $false
		foreach ($i in 1..20) {
			docker cp "${Project}-caddy-1:/data/caddy/pki/authorities/local/root.crt" (Join-Path $CertDir "caddy-root.crt") 2>$null
			if ($LASTEXITCODE -eq 0) { $exported = $true; break }
			Start-Sleep -Seconds 1
		}
		if (-not $exported) { throw "Caddy did not create its root certificate. Check: docker logs ${Project}-caddy-1" }

		$help = @"
<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Coup Online na rede local</title>
<body style="font-family:sans-serif;max-width:34em;margin:1.5em auto;padding:0 1em;line-height:1.5">
<h1>Coup Online</h1>
<p><a href="https://$ip/" style="font-size:1.3em"><b>Abrir o jogo</b></a> (https://$ip/)</p>
<p>O navegador vai avisar que a conexao <b>nao e segura</b>: o certificado foi criado neste PC, na sua rede.
Toque em <b>Avancado</b> e depois em <b>Continuar</b> para jogar.</p>
<h2>Para sumir o aviso (uma vez)</h2>
<p><a href="caddy-root.crt"><b>Baixar o certificado</b></a> e instalar:</p>
<ul>
<li><b>Android:</b> Configuracoes &gt; Seguranca &gt; Criptografia e credenciais &gt; Instalar certificado &gt; Certificado de CA.</li>
<li><b>iPhone:</b> abra o arquivo, instale o perfil em Ajustes, depois Ajustes &gt; Geral &gt; Sobre &gt; Ajustes de Certificado e ative a confianca total.</li>
</ul>
<p>Depois disso o botao <b>Instalar o jogo</b> aparece no Android.</p>
</body></html>
"@
		Set-Content -LiteralPath (Join-Path $CertDir "index.html") -Value $help -Encoding UTF8
		if (Test-Listening $HelpPort) { throw "Port $HelpPort is already in use. Stop that program or pass -HelpPort." }
		$proc = Start-Process -FilePath "python" -ArgumentList @("-m", "http.server", "$HelpPort", "--bind", "0.0.0.0", "--directory", $CertDir) `
			-WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $StackDir "help.log") -RedirectStandardError (Join-Path $StackDir "help.err.log")
		Set-Content -LiteralPath $PidFile -Value $proc.Id
		Start-Sleep -Seconds 3
		Show-Status
	}
}
