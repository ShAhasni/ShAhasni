@echo off
REM Double-click launcher for setup-windows.ps1
set /p GITNAME="Your name for Git commits: "
set /p GITEMAIL="Your email for Git commits: "
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-windows.ps1" -GitName "%GITNAME%" -GitEmail "%GITEMAIL%"
pause
