@echo off
REM Windows entry for Merit-Hub.ps1 (keep this file next to the .ps1).
REM Direct ".\Merit-Hub.ps1" fails on default RemoteSigned when the file
REM has Mark of the Web (browser download) and is not Authenticode-signed.
REM This launcher clears MOTW and uses -ExecutionPolicy Bypass for this
REM process only. It does not change User/Machine policy or disable SmartScreen.
setlocal EnableExtensions
set "HUB=%~dp0Merit-Hub.ps1"

if not exist "%HUB%" (
  echo Merit-Hub: Merit-Hub.ps1 not found next to this launcher:
  echo   %HUB%
  exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Unblock-File -LiteralPath '%HUB%'" >nul 2>&1

set "PWSH="
if exist "%~dp0pwsh\pwsh.exe" set "PWSH=%~dp0pwsh\pwsh.exe"
if not defined PWSH if defined MYMERITTOOLS if exist "%MYMERITTOOLS%\pwsh\pwsh.exe" set "PWSH=%MYMERITTOOLS%\pwsh\pwsh.exe"

if not defined PWSH (
  where pwsh >nul 2>&1
  if %ERRORLEVEL%==0 set "PWSH=pwsh"
)
if not defined PWSH (
  where powershell >nul 2>&1
  if %ERRORLEVEL%==0 set "PWSH=powershell"
)
if not defined PWSH (
  echo Merit-Hub: need pwsh or Windows PowerShell on PATH.
  echo Install PowerShell 7:  winget install Microsoft.PowerShell
  exit /b 1
)

"%PWSH%" -NoProfile -ExecutionPolicy Bypass -File "%HUB%" %*
exit /b %ERRORLEVEL%
