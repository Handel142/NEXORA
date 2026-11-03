@echo off
cd /d "%~dp0"
start "NEXORA The Mind Trap" http://localhost:8000
py -m http.server 8000
pause
