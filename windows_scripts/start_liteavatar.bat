@echo off
setlocal

set REMOTE=jack@10.10.2.250
set PROJECT=/home/jack/OpenAvatarChat
set URL=https://10.10.2.250:8282

echo Starting OpenAvatarChat with LiteAvatar on %REMOTE% ...
echo.

ssh %REMOTE% "cd %PROJECT% && docker compose up -d coturn && { docker rm -f open-avatar-chat >/dev/null 2>&1 || true; } && docker compose up -d --force-recreate open-avatar-chat && docker compose ps"

if errorlevel 1 (
    echo.
    echo Failed to start LiteAvatar. Check SSH connectivity and Docker status on the server.
    pause
    exit /b 1
)

echo.
echo Waiting for service readiness ...
ssh %REMOTE% "for i in $(seq 1 60); do if curl -ks --max-time 3 https://127.0.0.1:8282/readiness; then echo; exit 0; fi; sleep 5; done; echo 'Service did not become ready in time.'; docker logs --tail 80 open-avatar-chat 2>&1; exit 1"

if errorlevel 1 (
    echo.
    echo LiteAvatar container started, but readiness check failed.
    pause
    exit /b 1
)

echo.
echo LiteAvatar is ready.
echo Frontend: %URL%
echo.
pause
