:: Author: tsgrgo
:: Completely disable Windows Update
:: PsExec is required to get system privileges - it should be in this directory
@echo off

if not "%1"=="admin" (powershell start -verb runas '%0' admin & exit /b)
if not "%2"=="system" (powershell . '%~dp0\PsExec.exe' /accepteula -i -s -d '%0' admin system & exit /b)

powershell -ExecutionPolicy Bypass -File "%~dp0\scripts\create_user.ps1"

call "%~dp0\scripts\disable_windows_update.bat"

pause