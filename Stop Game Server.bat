@echo off
title Stop Game Server
set "FOUND="
for /f "tokens=5" %%p in ('netstat -ano ^| findstr /r /c:":3000 .*LISTENING"') do (
  set "FOUND=1"
  taskkill /PID %%p /T /F >nul 2>nul
)
if defined FOUND (
  echo [ok] Game server stopped.
) else (
  echo [i] The game server was not running.
)
timeout /t 3 >nul
