@echo off
setlocal

echo Starting OpenAvatarChat on jack@10.10.2.250 ...
ssh jack@10.10.2.250 "cd /home/jack/OpenAvatarChat && docker compose up -d && docker compose ps"

if errorlevel 1 (
    echo.
    echo Failed to start OpenAvatarChat. Check SSH connectivity and Docker status on the server.
    pause
    exit /b 1
)

echo.
echo OpenAvatarChat is starting.
echo Frontend: https://10.10.2.250:8282
echo.
pause
