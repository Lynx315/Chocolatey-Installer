# Chocolatey installer / upgrader (fixed version)

# TLS 1.2 is required by chocolatey.org. Set it first so the internet check
# below doesn't fail on older Windows PowerShell setups.
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072
} catch {
    Write-Warning 'Could not enable TLS 1.2. Downloads from chocolatey.org may fail.'
}

# Admin check and restart as admin if needed
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
if (-not $isAdmin) {
    Write-Warning 'This script requires Administrator rights. Restarting as Administrator...'
    try {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    } catch {
        Write-Host 'Could not restart as Administrator (UAC prompt declined?).' -ForegroundColor Red
        Start-Sleep -Seconds 5
    }
    exit
}

function PauseForExit {
    Write-Host ''
    Write-Host 'Press any key to exit...' -ForegroundColor Cyan
    try {
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    } catch {
        Start-Sleep -Seconds 10
    }
}

function Test-Yes([string]$answer) {
    return ($answer -match '^\s*y\s*$')
}

# Check internet connection / reachability of the Chocolatey install script
function Test-InternetConnection {
    try {
        $null = Invoke-WebRequest -Uri 'https://community.chocolatey.org/install.ps1' -UseBasicParsing -TimeoutSec 10
        return $true
    } catch {
        return $false
    }
}

# Find choco.exe (on PATH, or in the default install location)
function Get-ChocoExe {
    $cmd = Get-Command choco.exe -CommandType Application -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    $root = if ($env:ChocolateyInstall) { $env:ChocolateyInstall } else { Join-Path $env:ProgramData 'chocolatey' }
    $exe = Join-Path $root 'bin\choco.exe'
    if (Test-Path $exe) { return $exe }
    return $null
}

# Get installed Chocolatey version (if installed)
function Get-ChocoVersion {
    $exe = Get-ChocoExe
    if (-not $exe) { return $null }
    try {
        $v = & $exe --version 2>$null | Select-Object -First 1
        if ($v) { return "$v".Trim() }
    } catch { }
    return $null
}

function Update-SessionPath {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = (@($machine, $user) | Where-Object { $_ }) -join ';'
}

function Test-ChocoExitOk([int]$code) {
    # 0 = success, 1641/3010 = success but reboot required
    return ($code -in 0, 1641, 3010)
}

# Chocolatey GUI is installed if its package folder exists in the lib folder
function Test-ChocoGuiInstalled {
    $root = if ($env:ChocolateyInstall) { $env:ChocolateyInstall } else { Join-Path $env:ProgramData 'chocolatey' }
    return (Test-Path (Join-Path $root 'lib\chocolateygui'))
}

Clear-Host

# ASCII Art
Write-Host ' ____     __  __  _____   ____     _____  ' -ForegroundColor Cyan
Write-Host '/\  _`\  /\ \/\ \/\  __`\/\  _`\  /\  __`\  ' -ForegroundColor Cyan
Write-Host '\ \ \/\_\\ \ \_\ \ \ \/\ \ \ \/\_\\ \ \/\ \  ' -ForegroundColor Cyan
Write-Host ' \ \ \/_/_\ \  _  \ \ \ \ \ \ \/_/_\ \ \ \ \  ' -ForegroundColor Cyan
Write-Host '  \ \ \L\ \\ \ \ \ \ \ \_\ \ \ \L\ \\ \ \_\ \ ' -ForegroundColor Cyan
Write-Host '   \ \____/ \ \_\ \_\ \_____\ \____/ \ \_____\' -ForegroundColor Cyan
Write-Host '    \/___/   \/_/\/_/\/_____/\/___/ \/_____/' -ForegroundColor Cyan
Write-Host ''

$installedVersion = Get-ChocoVersion
if ($installedVersion) {
    Write-Host "Detected Chocolatey version: $installedVersion" -ForegroundColor Yellow
} else {
    Write-Host 'Chocolatey not installed.' -ForegroundColor Yellow
}

Write-Host 'Do you want to install or upgrade Chocolatey to the latest version? (Y/N)' -ForegroundColor Yellow
if (-not (Test-Yes (Read-Host))) {
    Write-Host 'Installation cancelled.' -ForegroundColor Red
    PauseForExit
    exit
}

if (-not (Test-InternetConnection)) {
    Write-Host 'Error: No internet connection or unable to reach Chocolatey URL.' -ForegroundColor Red
    PauseForExit
    exit
}

$guiInstalled = Test-ChocoGuiInstalled
if ($guiInstalled) {
    Write-Host 'Chocolatey GUI is installed. Upgrade it as well? (Y/N)' -ForegroundColor Yellow
} else {
    Write-Host 'Do you want to install the Chocolatey GUI as well? (Y/N)' -ForegroundColor Yellow
}
$installGui = Test-Yes (Read-Host)

try { Set-ExecutionPolicy Bypass -Scope Process -Force -ErrorAction Stop } catch { }

$existingExe = Get-ChocoExe

if ($existingExe) {
    # The official install.ps1 refuses to touch an existing installation,
    # so upgrades have to go through "choco upgrade chocolatey".
    Write-Host ''
    Write-Host 'Upgrading Chocolatey...' -ForegroundColor Yellow
    try {
        & $existingExe upgrade chocolatey -y
        if (-not (Test-ChocoExitOk $LASTEXITCODE)) { throw "choco exited with code $LASTEXITCODE" }
    } catch {
        Write-Host "Upgrade failed: $($_.Exception.Message)" -ForegroundColor Red
        PauseForExit
        exit
    }
} else {
    Write-Host ''
    Write-Host 'Installing Chocolatey...' -ForegroundColor Yellow
    try {
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    } catch [System.Net.WebException] {
        Write-Host 'Error: No internet connection or URL unreachable.' -ForegroundColor Red
        PauseForExit
        exit
    } catch {
        Write-Host "Installation failed due to unexpected error: $($_.Exception.Message)" -ForegroundColor Red
        PauseForExit
        exit
    }
}

Update-SessionPath
$newVersion = Get-ChocoVersion

if ([string]::IsNullOrEmpty($newVersion)) {
    Write-Host 'Chocolatey installation failed (choco not found afterwards).' -ForegroundColor Red
    PauseForExit
    exit
} elseif ($newVersion -eq $installedVersion) {
    Write-Host "Chocolatey is already up-to-date (version $newVersion)." -ForegroundColor Green
} else {
    Write-Host "Chocolatey successfully installed/upgraded to version $newVersion." -ForegroundColor Green
}

if ($installGui) {
    try {
        $verb = if ($guiInstalled) { 'Upgrading' } else { 'Installing' }
        Write-Host ''
        $done = if ($guiInstalled) { 'upgraded' } else { 'installed' }

        # A running GUI can lock its files and make the upgrade fail
        if ($guiInstalled -and (Get-Process -Name ChocolateyGui -ErrorAction SilentlyContinue)) {
            Write-Host 'Please close Chocolatey GUI first, then press any key to continue...' -ForegroundColor Yellow
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        }

        Write-Host "$verb Chocolatey GUI..." -ForegroundColor Yellow
        choco upgrade chocolateygui -y
        if (-not (Test-ChocoExitOk $LASTEXITCODE)) { throw "choco exited with code $LASTEXITCODE" }

        Update-SessionPath
        $gui = Get-Command chocolateygui -CommandType Application -ErrorAction SilentlyContinue
        if ($gui) {
            Write-Host "Chocolatey GUI $done. Launching GUI now..." -ForegroundColor Green
            Start-Process $gui.Source
            Start-Sleep -Seconds 5
            Write-Host 'Installation successful. Closing this window...' -ForegroundColor Cyan
            exit
        } else {
            Write-Host "Chocolatey GUI $done, but could not be launched automatically. Start it from the Start menu." -ForegroundColor Yellow
            PauseForExit
            exit
        }
    } catch {
        Write-Host "Error installing or starting Chocolatey GUI: $($_.Exception.Message)" -ForegroundColor Red
        PauseForExit
        exit
    }
}

Write-Host ''
Write-Host 'Chocolatey installation completed.' -ForegroundColor Green
Write-Host 'Use "choco" in a NEW PowerShell window to interact with Chocolatey.' -ForegroundColor Cyan
PauseForExit