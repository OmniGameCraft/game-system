@echo off
setlocal
title Reset ALL game data
cd /d "%~dp0"
echo ==================================================
echo    RESET ALL GAME DATA
echo ==================================================
echo  This clears the Admin account, all players, items,
echo  money, bags, the shop and all history. The app will
echo  start completely empty, like a fresh install.
echo.
echo  Nothing is deleted: the old data is MOVED into the
echo  "old-data" folder, so it can be brought back.
echo.
choice /c YN /t 15 /d Y /m "Resetting in 15 seconds. Press N to cancel, or Y to reset now"
if errorlevel 2 (
  echo.
  echo Cancelled. Nothing was changed.
  timeout /t 4 >nul
  exit /b 0
)

rem Stop the server first so no file is in use.
for /f "tokens=5" %%p in ('netstat -ano ^| findstr /r /c:":3000 .*LISTENING"') do taskkill /PID %%p /T /F >nul 2>nul
timeout /t 2 >nul

if not exist "game-app\server\data" (
  echo [i] There is no saved data yet. Nothing to reset.
  goto :done
)
for /f %%t in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmmss"') do set "STAMP=%%t"
if not exist "old-data" mkdir "old-data"
move "game-app\server\data" "old-data\data-%STAMP%" >nul
if errorlevel 1 (
  echo [!] Could not move the data. Close the black server window and try again.
  goto :done
)
echo.
echo [ok] Reset done. Old data saved in: old-data\data-%STAMP%
echo     Double-click "Start Game Server". The app opens with the
echo     first-time Admin setup.
:done
timeout /t 10 >nul
