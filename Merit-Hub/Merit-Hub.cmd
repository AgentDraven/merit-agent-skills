@echo off
setlocal
REM Merit-Hub — laptop cleanup, jumpstart, prereqs (C:\Tools\Merit-Hub).
REM   Merit-Hub.cmd
REM   Merit-Hub.cmd -Pristine -Force
REM   Merit-Hub.cmd -Jumpstart Oss
REM   Merit-Hub.cmd -Jumpstart Vault
REM   Merit-Hub.cmd -Prereqs
REM   Merit-Hub.cmd -Help

set "PS1=%~dp0Merit-Hub.ps1"
if not exist "%PS1%" (
  echo Missing %PS1%
  exit /b 1
)

where pwsh >nul 2>&1 && (
  pwsh -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %*
  exit /b %ERRORLEVEL%
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %*
exit /b %ERRORLEVEL%
