@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "ROOT=%~dp0"
set "APP_DIR=%ROOT%webapp"
set "APP_URL=http://localhost:5173/"
set "PORT=5173"

cls
echo ========================================
echo   駕照考試題庫 - 安裝與啟動
echo ========================================
echo.

:: ========== 1. 檢查 Node.js ==========
echo [1/5] 檢查 Node.js...
where node >nul 2>&1
if errorlevel 1 (
    echo [訊息] 尚未安裝 Node.js，正在自動安裝...
    echo 請耐心等候，安裝過程可能需要數分鐘...
    echo.
    winget install OpenJS.NodeJS.LTS
    if errorlevel 1 (
        cls
        echo ========================================
        echo   安裝失敗
        echo ========================================
        echo.
        echo 請手動安裝 Node.js：
        echo   1. 前往 https://nodejs.org/
        echo   2. 下載並安裝 LTS 版本
        echo   3. 安裝完成後重新執行此檔案
        echo.
        pause
        exit /b 1
    )
    set "PATH=%PATH%;%ProgramFiles%\nodejs\;%ProgramFiles(x86)%\nodejs\"
)
for /f "tokens=*" %%i in ('node -v 2^>nul') do set "NODE_VER=%%i"
echo [OK] Node.js %NODE_VER%
echo.

:: ========== 2. 檢查 npm ==========
echo [2/5] 檢查 npm...
where npm >nul 2>&1
if errorlevel 1 (
    cls
    echo ========================================
    echo   npm 未找到
    echo ========================================
    echo.
    echo 請重新安裝 Node.js（包含 npm）
    echo.
    pause
    exit /b 1
)
echo [OK] npm 正常
echo.

:: ========== 3. 安裝 npm 套件 ==========
echo [3/5] 安裝前端套件...
cd /d "%APP_DIR%"
if not exist "node_modules" (
    call npm install
    if errorlevel 1 (
        cls
        echo ========================================
        echo   套件安裝失敗
        echo ========================================
        echo.
        echo 請確認網路連線正常後重試
        echo.
        pause
        exit /b 1
    )
    echo [OK] 套件安裝完成
) else (
    echo [OK] 套件已存在
)
echo.

:: ========== 4. 釋放連接埠 ==========
echo [4/5] 檢查連接埠 %PORT%...
set "PID="
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":%PORT%" ^| findstr "LISTENING" 2^>nul') do (
    set "PID=%%p"
)
if defined PID (
    echo [訊息] 連接埠 %PORT% 已被佔用，正在釋放...
    taskkill /f /pid !PID! >nul 2>&1
    if errorlevel 1 (
        cls
        echo ========================================
        echo   無法釋放連接埠 %PORT%
        echo ========================================
        echo.
        echo 請手動關閉佔用 %PORT% 連接埠的程式後重試
        echo.
        pause
        exit /b 1
    )
    ping 127.0.0.1 -n 3 >nul
    echo [OK] 連接埠已釋放
) else (
    echo [OK] 連接埠 %PORT% 可使用
)
echo.

:: ========== 5. 啟動伺服器 ==========
echo [5/5] 啟動伺服器...
echo.
cd /d "%APP_DIR%"
start "Driving Test Server" cmd /k "npm run dev"
cd /d "%ROOT%"

echo 等待伺服器就緒（最多 60 秒）...
echo.
set "WAIT_COUNT=0"
:WAIT_LOOP
if !WAIT_COUNT! GEQ 60 (
    echo [訊息] 伺服器啟動逾時，仍嘗試開啟瀏覽器
    goto :OPEN
)
powershell -Command "try { $r = (New-Object System.Net.WebClient).DownloadString('http://localhost:%PORT%/'); exit 0 } catch { exit 1 }" >nul 2>&1
if errorlevel 1 (
    set /a WAIT_COUNT+=1
    ping 127.0.0.1 -n 2 >nul
    goto :WAIT_LOOP
)

:OPEN
cls
echo ========================================
echo   全部完成！
echo ========================================
echo.
echo   Node.js:    %NODE_VER%
echo   套件狀態:  已安裝
echo   伺服器:     http://localhost:%PORT%/
echo   瀏覽器:    已開啟
echo.
echo   若頁面空白，請稍候重新整理
echo.
echo ========================================
start "" "%APP_URL%"
pause
