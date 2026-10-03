@echo off
cd /d "%~dp0"
> server-check.txt echo === This PC's network addresses ===
powershell -NoProfile -Command "Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '127.*' } | ForEach-Object { '{0,-40} {1}' -f $_.InterfaceAlias, $_.IPAddress }" >> server-check.txt
>> server-check.txt echo.
>> server-check.txt echo === Network profile ===
powershell -NoProfile -Command "Get-NetConnectionProfile | ForEach-Object { '{0,-30} {1}' -f $_.InterfaceAlias, $_.NetworkCategory }" >> server-check.txt
>> server-check.txt echo.
>> server-check.txt echo === Port 3000 listening ===
netstat -ano | findstr /r /c:":3000 .*LISTENING" >> server-check.txt
for /f "tokens=5" %%p in ('netstat -ano ^| findstr /r /c:":3000 .*LISTENING"') do tasklist /FI "PID eq %%p" /FO LIST >> server-check.txt
>> server-check.txt echo.
>> server-check.txt echo === Firewall rules for Node.js ===
netsh advfirewall firewall show rule name=all | findstr /i /c:"node" >> server-check.txt
