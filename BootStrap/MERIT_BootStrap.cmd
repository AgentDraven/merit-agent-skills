@echo off
REM MERIT_BootStrap launcher (OSS). Does NOT replace repo-root merit.ps1 CLI.
REM From this folder:  MERIT_BootStrap.cmd
setlocal
set "BOOTSTRAP_ROOT=%~dp0"
set "BOOTSTRAP_PS1=%BOOTSTRAP_ROOT%MERIT_BootStrap.ps1"

if not exist "%BOOTSTRAP_PS1%" (
  echo MERIT_BootStrap: MERIT_BootStrap.ps1 not found at "%BOOTSTRAP_PS1%"
  exit /b 1
)

where pwsh >nul 2>&1
if %ERRORLEVEL%==0 (
  pwsh -NoProfile -File "%BOOTSTRAP_PS1%" %*
  exit /b %ERRORLEVEL%
)

where powershell >nul 2>&1
if %ERRORLEVEL%==0 (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%BOOTSTRAP_PS1%" %*
  exit /b %ERRORLEVEL%
)

echo MERIT_BootStrap: need pwsh or powershell on PATH
exit /b 1
