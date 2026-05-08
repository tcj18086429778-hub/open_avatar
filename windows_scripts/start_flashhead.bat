@echo off
setlocal

set REMOTE=jack@10.10.2.250
set PROJECT=/home/jack/OpenAvatarChat
set URL=https://10.10.2.250:8282
set OVERRIDE=docker-compose.runtime-flashhead.yml

echo Starting OpenAvatarChat with FlashHead on %REMOTE% ...
echo.

ssh %REMOTE% "cd %PROJECT% && printf '%%s\n' 'services:' '  open-avatar-chat:' '    environment:' '      - NVIDIA_VISIBLE_DEVICES=all' '      - NVIDIA_DRIVER_CAPABILITIES=compute,utility,video' '      - XFORMERS_IGNORE_FLASH_VERSION_CHECK=1' '      - UV_LINK_MODE=copy' '    volumes:' '      - ./uv-cache:/root/.cache/uv' '      - ./src/handlers/client/rtc_client/client_handler_rtc.py:/root/open-avatar-chat/src/handlers/client/rtc_client/client_handler_rtc.py:ro' '      - ./src/handlers/avatar/flashhead/flashhead_config.py:/root/open-avatar-chat/src/handlers/avatar/flashhead/flashhead_config.py:ro' '      - ./src/handlers/avatar/flashhead/flashhead_processor.py:/root/open-avatar-chat/src/handlers/avatar/flashhead/flashhead_processor.py:ro' '      - ./src/handlers/avatar/flashhead/avatar_handler_flashhead.py:/root/open-avatar-chat/src/handlers/avatar/flashhead/avatar_handler_flashhead.py:ro' '    entrypoint:' '      - /bin/bash' '      - -lc' '      - cd /root/open-avatar-chat && uv pip install --index-url https://download.pytorch.org/whl/cu128 xformers==0.0.32.post2 torch==2.8.0 torchvision==0.23.0 torchaudio==2.8.0 && uv pip install -i https://mirrors.aliyun.com/pypi/simple/ diffusers==0.34.0 transformers==4.44.2 xfuser\>=0.4.3 easydict ftfy scikit-image pyloudnorm decord mediapipe\>=0.10.14 flask && if [ ! -d models/wav2vec2-base-960h ]; then git clone --depth 1 https://www.modelscope.cn/AI-ModelScope/wav2vec2-base-960h.git models/wav2vec2-base-960h; fi && if [ ! -f models/SoulX-FlashHead-1_3B/Model_Lite/diffusion_pytorch_model.safetensors ] || [ ! -f models/SoulX-FlashHead-1_3B/VAE_LTX/diffusion_pytorch_model.safetensors ]; then HF_ENDPOINT=https://hf-mirror.com uv run huggingface-cli download Soul-AILab/SoulX-FlashHead-1_3B --include Model_Lite/\* VAE_LTX/\* --local-dir models/SoulX-FlashHead-1_3B; fi && exec uv run --no-sync src/demo.py --config=/root/open-avatar-chat/config/chat_with_openai_compatible_bailian_cosyvoice_flashhead.yaml' '    command: []' > %OVERRIDE% && docker compose up -d coturn && { docker rm -f open-avatar-chat >/dev/null 2>&1 || true; } && docker compose -f docker-compose.yml -f %OVERRIDE% up -d --force-recreate open-avatar-chat && docker compose -f docker-compose.yml -f %OVERRIDE% ps"

if errorlevel 1 (
    echo.
    echo Failed to start FlashHead. Check SSH connectivity and Docker status on the server.
    pause
    exit /b 1
)

echo.
echo Waiting for service readiness ...
ssh %REMOTE% "for i in $(seq 1 90); do if curl -ks --max-time 3 https://127.0.0.1:8282/readiness; then echo; exit 0; fi; sleep 5; done; echo 'Service did not become ready in time.'; docker logs --tail 120 open-avatar-chat 2>&1; exit 1"

if errorlevel 1 (
    echo.
    echo FlashHead container started, but readiness check failed.
    pause
    exit /b 1
)

echo.
echo FlashHead is ready.
echo Frontend: %URL%
echo.
pause
