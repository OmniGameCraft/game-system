@echo off
setlocal EnableExtensions
title Game Server
cd /d "%~dp0"

echo ==================================================
echo    GAME SERVER - setup and start
echo ==================================================
echo.

rem ---- 1. Node.js -------------------------------------------------------
where node >nul 2>nul
if errorlevel 1 goto :nonode
node -e "const [a,b]=process.versions.node.split('.').map(Number);process.exit(a>22||a===22&&b>=13?0:1)"
if errorlevel 1 goto :oldnode
for /f "delims=" %%v in ('node -v') do echo [ok] Node.js %%v found
goto :unpack

:nonode
echo [!] Node.js is not installed on this computer.
goto :installnode
:oldnode
echo [!] Your Node.js is too old. Version 22.13 or newer is needed.
:installnode
where winget >nul 2>nul
if errorlevel 1 (
  echo     Install "Node.js LTS" from https://nodejs.org and run this file again.
  goto :stop
)
choice /m "    Install Node.js LTS now? Needs internet"
if errorlevel 2 goto :stop
winget install -e --id OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
echo.
echo [ok] Node.js installed. CLOSE this window and double-click this file again.
goto :stop

rem ---- 2. Unpack a new version if a zip is here -------------------------
:unpack
rem Stop here if a server is already running: updating files it is using
rem would fail, and two servers can't share port 3000.
netstat -ano | findstr /r /c:":3000 .*LISTENING" >nul
if not errorlevel 1 (
  echo.
  echo [!] The game server is ALREADY RUNNING in another window.
  echo     Close that other black window first, then run this file again.
  goto :stop
)
set "NEWZIP="
for %%z in (game-app-*.zip) do set "NEWZIP=%%z"
if not defined NEWZIP goto :checkinstall
echo [..] Unpacking %NEWZIP% - your saved data is kept
powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '%NEWZIP%' -DestinationPath '.' -Force"
if errorlevel 1 (
  echo [!] Could not unpack %NEWZIP%.
  goto :stop
)
if not exist "installed-zips" mkdir "installed-zips"
move /y "%NEWZIP%" "installed-zips\" >nul
set "NEEDBUILD=1"

:checkinstall
if not exist "game-app\package.json" (
  echo [!] The game-app folder is missing. Put the game-app zip next to this file.
  goto :stop
)
cd game-app
if not exist "node_modules" set "NEEDBUILD=1"
if not exist "client\dist\index.html" set "NEEDBUILD=1"
if not defined NEEDBUILD goto :network

rem ---- 3. Install and build, needs internet the first time --------------
echo [..] Installing packages. First time needs internet, takes 1-3 minutes...
call npm install --no-audit --no-fund
if errorlevel 1 (
  echo [!] npm install failed. Check your internet connection and try again.
  goto :stop
)
echo [..] Building the app...
call npm run build
if errorlevel 1 (
  echo [!] Build failed.
  goto :stop
)
echo [ok] Installed and built.

rem ---- 4. Network checks ------------------------------------------------
:network
echo.
powershell -NoProfile -Command "if (Get-NetConnectionProfile | Where-Object { $_.NetworkCategory -eq 'Public' }) { exit 1 } else { exit 0 }" >nul 2>nul
if errorlevel 1 (
  echo [!] WARNING: Windows has your Wi-Fi set as a PUBLIC network.
  echo     Phones may be blocked. Fix: Settings - Network and Internet - Wi-Fi -
  echo     your network - Network profile type - choose PRIVATE.
  echo.
)
net session >nul 2>nul
if not errorlevel 1 (
  netsh advfirewall firewall show rule name="Game Server 3000-3443" >nul 2>nul
  if errorlevel 1 (
    netsh advfirewall firewall add rule name="Game Server 3000-3443" dir=in action=allow protocol=TCP localport=3000,3443 profile=private >nul
    echo [ok] Firewall rule added for ports 3000 and 3443 on private networks.
  )
) else (
  echo [i] If Windows asks to allow Node.js through the firewall,
  echo     tick PRIVATE networks and click Allow.
)

rem ---- 5. Start ---------------------------------------------------------
echo.
echo ==================================================
echo  Starting... give players the LAN address below.
echo  Keep this window OPEN while you play.
echo  To stop the server: close this window or press Ctrl+C.
echo ==================================================
call npm start
echo.
echo [!] The server stopped.

:stop
echo.
pause
