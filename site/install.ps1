# Installs Paws Off (https://github.com/EnigmaticZee/PawsOff) on Windows and starts it.
#   irm https://enigmaticzee.github.io/PawsOff/install.ps1 | iex
# It downloads the latest release's installer from GitHub and runs it quietly. It installs just for
# you (no admin rights) and starts Paws Off when it's done. Uninstall any time from Settings > Apps.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$url = 'https://github.com/EnigmaticZee/PawsOff/releases/latest/download/PawsOff-Windows-Setup.exe'
$setup = Join-Path $env:TEMP 'PawsOff-Setup.exe'

Write-Host 'Downloading Paws Off...'
Invoke-WebRequest -Uri $url -OutFile $setup -UseBasicParsing
Write-Host 'Installing...'
# The installer closes a running Paws Off, installs, and starts the new one.
$p = Start-Process -FilePath $setup -ArgumentList '/SILENT', '/NORESTART', '/CLOSEAPPLICATIONS' -PassThru
$p.WaitForExit()
Remove-Item $setup -ErrorAction SilentlyContinue
if ($p.ExitCode -ne 0) { throw "The installer stopped with code $($p.ExitCode)." }
Write-Host 'Done. Paws Off is in your system tray, by the clock: click the paw.'
