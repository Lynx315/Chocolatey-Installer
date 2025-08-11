@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0choco_install_internal.ps1"
timeout /t 5 /nobreak >nul



