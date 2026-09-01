@echo off
setlocal

where /q winget.exe
if errorlevel 1 (
  echo [ERROR] winget was not found.
  echo Install or update "App Installer" from Microsoft Store, then run this file again.
  exit /b 1
)

set "PWSH_EXE="
if exist "%ProgramFiles%\PowerShell\7\pwsh.exe" set "PWSH_EXE=%ProgramFiles%\PowerShell\7\pwsh.exe"
if not defined PWSH_EXE where /q pwsh.exe && set "PWSH_EXE=pwsh.exe"

if not defined PWSH_EXE (
  echo [SETUP] Installing PowerShell 7...
  winget install --id Microsoft.PowerShell --exact --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity
  if errorlevel 1 exit /b 1
)

if not defined PWSH_EXE if exist "%ProgramFiles%\PowerShell\7\pwsh.exe" set "PWSH_EXE=%ProgramFiles%\PowerShell\7\pwsh.exe"
if not defined PWSH_EXE where /q pwsh.exe && set "PWSH_EXE=pwsh.exe"
if not defined PWSH_EXE set "PWSH_EXE=%LOCALAPPDATA%\Microsoft\WindowsApps\pwsh.exe"

if exist "%PWSH_EXE%" goto run_setup
where /q "%PWSH_EXE%"
if errorlevel 1 (
  echo [ERROR] PowerShell 7 was installed but pwsh.exe was not found.
  exit /b 1
)

:run_setup
"%PWSH_EXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.windows.ps1" %*
set "SETUP_EXIT=%errorlevel%"

if not "%SETUP_EXIT%"=="0" (
  echo [ERROR] Setup failed with exit code %SETUP_EXIT%.
)

exit /b %SETUP_EXIT%
