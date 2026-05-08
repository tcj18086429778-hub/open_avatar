@echo off
setlocal

set REMOTE=jack@10.10.2.250
set PROJECT=/home/jack/OpenAvatarChat
set URL=https://10.10.2.250:8282
set OVERRIDE=docker-compose.runtime-musetalk.yml

echo Starting OpenAvatarChat with MuseTalk on %REMOTE% ...
echo.

ssh %REMOTE% "cd %PROJECT% && printf '%%s\n' 'services:' '  open-avatar-chat:' '    volumes:' '      - ./src/handlers/client/rtc_client/client_handler_rtc.py:/root/open-avatar-chat/src/handlers/client/rtc_client/client_handler_rtc.py:ro' '    entrypoint:' '      - /bin/bash' '      - -lc' '      - cd /root/open-avatar-chat && uv run install.py --config config/chat_with_openai_compatible_bailian_cosyvoice_musetalk.yaml && uv run scripts/download_models.py --handler musetalk --source modelscope && exec uv run --no-sync src/demo.py --config=/root/open-avatar-chat/config/chat_with_openai_compatible_bailian_cosyvoice_musetalk.yaml' '    command: []' > %OVERRIDE% && docker compose up -d coturn && { docker rm -f open-avatar-chat >/dev/null 2>&1 || true; } && docker compose -f docker-compose.yml -f %OVERRIDE% up -d --force-recreate open-avatar-chat && docker compose -f docker-compose.yml -f %OVERRIDE% ps"

if errorlevel 1 (
    echo.
    echo Failed to start MuseTalk. Check SSH connectivity and Docker status on the server.
    pause
    exit /b 1
)

echo.
echo Waiting for service readiness ...
ssh %REMOTE% "for i in $(seq 1 60); do if curl -ks --max-time 3 https://127.0.0.1:8282/readiness; then echo; exit 0; fi; sleep 5; done; echo 'Service did not become ready in time.'; docker logs --tail 80 open-avatar-chat 2>&1; exit 1"

if errorlevel 1 (
    echo.
    echo MuseTalk container started, but readiness check failed.
    pause
    exit /b 1
)

echo.
echo MuseTalk is ready.
echo Frontend: %URL%
echo.
pause
