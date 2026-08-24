@echo off
REM Legacy launcher name. Real entry is Merit-Hub.ps1 PHASE 2.
setlocal
if defined MYMERITTOOLS (set "HUB=%MYMERITTOOLS%\Merit-Hub.ps1") else (set "HUB=C:\Tools\Merit-Hub.ps1")
if not exist "%HUB%" set "HUB=C:\Tools\Merit-Hub.ps1"
if exist "%HUB%" (
  where pwsh >nul 2>&1 && (pwsh -NoProfile -ExecutionPolicy Bypass -File "%HUB%" -OssPhase %* & exit /b %ERRORLEVEL%)
  powershell -NoProfile -ExecutionPolicy Bypass -File "%HUB%" -OssPhase %*
  exit /b %ERRORLEVEL%
)
set "OSS=%~dp0_oss.ps1"
if not exist "%OSS%" (echo Merit-Hub.ps1 not found. Save Hub to C:\Tools\Merit-Hub.ps1 & exit /b 1)
where pwsh >nul 2>&1 && (pwsh -NoProfile -File "%~dp0MERIT_BootStrap.ps1" %* & exit /b %ERRORLEVEL%)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0MERIT_BootStrap.ps1" %*
exit /b %ERRORLEVEL%
