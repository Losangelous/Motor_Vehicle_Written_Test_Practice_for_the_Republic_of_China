@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "ROOT=%~dp0"
set "APP_DIR=%ROOT%webapp"
set "APP_URL=http://localhost:5173/"
set "PORT=5173"

echo ========================================
echo   Driving Test - Launcher
echo ========================================
echo.

echo [1/6] Checking Node.js...
where node >nul 2>&1
if errorlevel 1 (
    echo [FAIL] Node.js not found
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)
for /f "tokens=*" %%i in ('node -v 2^>nul') do set "NODE_VER=%%i"
echo [OK] Node.js %NODE_VER%

echo [2/6] Checking npm...
where npm >nul 2>&1
if errorlevel 1 (
    echo [FAIL] npm not found
    pause
    exit /b 1
)
echo [OK] npm found

echo [3/6] Checking webapp directory...
if not exist "%APP_DIR%\package.json" (
    echo [FAIL] Cannot find webapp\package.json
    pause
    exit /b 1
)
echo [OK] webapp found

echo [4/6] Checking dependencies...
if not exist "%APP_DIR%\node_modules" (
    echo [INFO] First run - installing dependencies...
    cd /d "%APP_DIR%"
    call npm install
    if errorlevel 1 (
        echo [FAIL] npm install failed
        pause
        exit /b 1
    )
    cd /d "%ROOT%"
    echo [OK] Dependencies installed
) else (
    echo [OK] Dependencies exist
)

echo [5/6] Checking server on port %PORT%...
set "SERVER_RUNNING=0"
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":%PORT%" ^| findstr "LISTENING" 2^>nul') do (
    set "SERVER_RUNNING=1"
    set "SERVER_PID=%%p"
)

if "!SERVER_RUNNING!"=="1" (
    echo [OK] Server already running (PID: !SERVER_PID!)
) else (
    echo [INFO] Starting server...
    cd /d "%APP_DIR%"
    start "Driving Test Server" cmd /k "npm run dev"
    cd /d "%ROOT%"

    echo [INFO] Waiting for server to be ready...
    set "WAIT_COUNT=0"
    :WAIT_LOOP
    if !WAIT_COUNT! GEQ 60 (
        echo [WARN] Server not ready after 60 seconds
        echo [WARN] Opening browser anyway - please refresh if blank
        goto :OPEN_BROWSER
    )
    powershell -Command "try { $r = (New-Object System.Net.WebClient).DownloadString('http://localhost:%PORT%/'); exit 0 } catch { exit 1 }" >nul 2>&1
    if errorlevel 1 (
        set /a WAIT_COUNT+=1
        ping 127.0.0.1 -n 2 >nul
        goto :WAIT_LOOP
    )
    echo [OK] Server ready
)

:OPEN_BROWSER
echo [6/6] Opening browser...
start "" "%APP_URL%"

echo.
echo ========================================
echo   Done! Opened: %APP_URL%
echo   If page is blank, wait a moment and refresh
echo   Press any key to close...
echo ========================================
pause >nul
