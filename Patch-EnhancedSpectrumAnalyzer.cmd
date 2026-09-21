@echo off
setlocal

if "%~1"=="" goto interactive

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Patch-EnhancedSpectrumAnalyzer.ps1" -InputPath "%~1"
exit /b %ERRORLEVEL%

:interactive
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Patch-EnhancedSpectrumAnalyzer.ps1"
set "PATCH_EXIT=%ERRORLEVEL%"
echo.
pause
exit /b %PATCH_EXIT%
