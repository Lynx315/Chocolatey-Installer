# Admin check and restart as admin if needed
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script requires Administrator rights. Restarting as Administrator..."
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

function PauseForExit {
    Write-Host ''
    Write-Host 'Press any key to exit...' -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}

# Check internet connection
function Test-InternetConnection {
    try {
        $request = Invoke-WebRequest -Uri 'https://community.chocolatey.org/install.ps1' -TimeoutSec 10
        return $true
    } catch {
        return $false
    }
}

# Get installed Chocolatey version (if installed)
function Get-ChocoVersion {
    $chocoPath = Get-Command choco -ErrorAction SilentlyContinue
    if ($chocoPath) {
        try {
            $version = (& choco --version) -replace '\r|\n',''
            return $version
        } catch {
            return $null
        }
    }
    return $null
}

Clear-Host

# ASCII Art
Write-Host ' ____     __  __  _____   ____     _____      ' -ForegroundColor Cyan
Write-Host '/\  _`\  /\ \/\ \/\  __`\/\  _`\  /\  __`\    ' -ForegroundColor Cyan
Write-Host '\ \ \/\_\\ \ \_\ \ \ \/\ \ \ \/\_\\ \ \/\ \   ' -ForegroundColor Cyan
Write-Host ' \ \ \/_/_\ \  _  \ \ \ \ \ \ \/_/_\ \ \ \ \  ' -ForegroundColor Cyan
Write-Host '  \ \ \L\ \\ \ \ \ \ \ \_\ \ \ \L\ \\ \ \_\ \ ' -ForegroundColor Cyan
Write-Host '   \ \____/ \ \_\ \_\ \_____\ \____/ \ \_____\' -ForegroundColor Cyan
Write-Host '    \/___/   \/_/\/_/\/_____/\/___/   \/_____/' -ForegroundColor Cyan
Write-Host ''

$installedVersion = Get-ChocoVersion
if ($installedVersion) {
    Write-Host "Detected Chocolatey version: $installedVersion" -ForegroundColor Yellow
} else {
    Write-Host "Chocolatey not installed." -ForegroundColor Yellow
}

Write-Host "Do you want to install or upgrade Chocolatey to the latest version? (Y/N)" -ForegroundColor Yellow
$response = Read-Host
if (-not $response -or $response.ToUpper() -ne 'Y') {
    Write-Host 'Installation cancelled.' -ForegroundColor Red
    PauseForExit
    exit
}

if (-not (Test-InternetConnection)) {
    Write-Host 'Error: No internet connection or unable to reach Chocolatey URL.' -ForegroundColor Red
    PauseForExit
    exit
}

Write-Host ''
Write-Host 'Do you want to install the Chocolatey GUI as well? (Y/N)' -ForegroundColor Yellow
$installGui = Read-Host

Set-ExecutionPolicy Bypass -Scope Process -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$oldVersion = $installedVersion

try {
    Write-Host ''
    Write-Host 'Installing or upgrading Chocolatey...' -ForegroundColor Yellow
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
} catch [System.Net.WebException] {
    Write-Host 'Error: No internet connection or URL unreachable.' -ForegroundColor Red
    PauseForExit
    exit
} catch {
    Write-Host 'Installation failed due to unexpected error.' -ForegroundColor Red
    PauseForExit
    exit
}

$newVersion = Get-ChocoVersion

if ($newVersion -eq $oldVersion -or [string]::IsNullOrEmpty($newVersion)) {
    Write-Host 'Chocolatey is already up-to-date or installation failed.' -ForegroundColor Red
    PauseForExit
    exit
} else {
    Write-Host "Chocolatey successfully installed/upgraded to version $newVersion." -ForegroundColor Green
}

if ($installGui.ToUpper() -eq 'Y') {
    try {
        Write-Host ''
        Write-Host 'Installing Chocolatey GUI...' -ForegroundColor Yellow
        choco install chocolateygui -y

        Write-Host 'Chocolatey GUI installed. Launching GUI now...' -ForegroundColor Green
        Start-Process 'choco' -ArgumentList 'gui'

        Start-Sleep -Seconds 5
        Write-Host 'Installation successful. Closing this window...' -ForegroundColor Cyan
        exit
    } catch {
        Write-Host 'Error installing or starting Chocolatey GUI: ' + $_.Exception.Message -ForegroundColor Red
        PauseForExit
        exit
    }
} else {
    Write-Host ''
    Write-Host 'Chocolatey installation completed.' -ForegroundColor Green
    Write-Host 'Use "choco" command in PowerShell to interact with Chocolatey.' -ForegroundColor Cyan
    # Kein exit, kein pause - PowerShell bleibt offen
}
