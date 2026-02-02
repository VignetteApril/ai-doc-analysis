@echo off
setlocal EnableExtensions

rem ===== config =====
set "CONDA_HOME=E:\conda"
set "ENV_NAME=python3-11-13"
set "PORT=8000"
rem ==================

set "CONDA_BAT=%CONDA_HOME%\Scripts\activate.bat"
set "URL=http://localhost:%PORT%/"
set "LOGDIR=%~dp0logs"

rem Map UNC working dir to a drive if needed
pushd "%~dp0" >nul 2>&1

if not exist "%LOGDIR%" mkdir "%LOGDIR%"

if not exist "%CONDA_BAT%" (
  echo [ERROR] activate.bat not found: "%CONDA_BAT%"
  echo Please check CONDA_HOME in this script.
  pause
  exit /b 1
)

call "%CONDA_BAT%" "%ENV_NAME%"
if errorlevel 1 (
  echo [ERROR] conda activate %ENV_NAME% failed.
  pause
  exit /b 1
)

rem Start doccano task (background)
start "" /MIN "%ComSpec%" /C "doccano task 1>""%LOGDIR%\task.out.log"" 2>""%LOGDIR%\task.err.log"""

rem Start doccano webserver (background)
start "" /MIN "%ComSpec%" /C "doccano webserver --port %PORT% 1>""%LOGDIR%\web.out.log"" 2>""%LOGDIR%\web.err.log"""

rem Wait for port ready (up to 60s)
for /L %%I in (1,1,60) do (
  powershell -NoProfile -Command "try { $ok=(Test-NetConnection 127.0.0.1 -Port %PORT% -WarningAction SilentlyContinue).TcpTestSucceeded; if($ok){exit 0}else{exit 1} } catch { exit 1 }"
  if not errorlevel 1 goto :open_browser
  timeout /t 1 /nobreak >nul
)

echo [ERROR] Port %PORT% not ready. Check logs:
echo   %LOGDIR%\web.err.log
echo   %LOGDIR%\task.err.log
pause
exit /b 1

:open_browser
start "" "%URL%"
echo [OK] Opened: %URL%
echo Logs: %LOGDIR%
exit /b 0
