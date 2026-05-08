# OpenAvatarChat Migration Notes

This repository keeps the code, configuration, Docker compose files, and Windows startup scripts needed to reproduce the current OpenAvatarChat deployment. Large runtime files and private credentials are intentionally not committed.

## What is included

- Core OpenAvatarChat source code and upstream submodule references.
- Current MuseTalk and FlashHead configuration files under `config/`.
- TURN/WebRTC fixes for cross-machine browser display.
- FlashHead lip-sync tuning code and configuration.
- Docker Compose runtime overrides:
  - `docker-compose.runtime-musetalk.yml`
  - `docker-compose.runtime-flashhead.yml`
- Windows helper scripts under `windows_scripts/`.
- `.env.example` showing required environment variables without real secrets.

## What is not included

The following files are excluded from Git on purpose:

| Path | Why it is omitted | How to restore |
| --- | --- | --- |
| `.env` | Contains real API keys. | Copy `.env.example` to `.env`, then fill in your own `DASHSCOPE_API_KEY`. |
| `models/` | Large model weights and generated model cache. | Run the project download scripts, or copy `models/` from the original machine. |
| `resource/avatar/**` except `put_avatar_here.txt` | Custom avatar videos/images may be private and can grow large. | Copy your avatar assets from the original machine or place new assets under the same paths. |
| `resource/audio/` | Runtime/user audio assets. | Regenerate or copy only the audio files you need. |
| `ssl_certs/localhost.crt` and `ssl_certs/localhost.key` | Local certificate and private key. | Run `scripts/create_ssl_certs.sh` or provide your own certificate/key. |
| `wheelhouse/` | Large Python wheel cache, especially CUDA/PyTorch wheels. | Download the matching wheels again, or copy `wheelhouse/` from the original machine. |
| `uv-cache/`, `.venv/`, `exp/`, `logs/` | Runtime cache and generated output. | These are regenerated during install or service startup. |
| Docker images | Container images do not belong in Git. | Use `docker build`, `docker pull`, or `docker save`/`docker load` separately. |

## Current avatar assets to restore

The current configuration references local assets that are not committed:

```text
resource/avatar/musetalk/person01_16x9.mp4
resource/avatar/flashhead/custom_avatar_chatgpt_20260508_110155.png
```

To reproduce the current visual result, copy these files from the original machine into the same paths. If you do not have them, either provide new assets or change the config back to the built-in sample:

```yaml
cond_image_path: "resource/avatar/flashhead/girl.png"
```

## Fresh Linux deployment steps

1. Clone the repository:

   ```bash
   git clone <your-open_avatar-repo-url> OpenAvatarChat
   cd OpenAvatarChat
   git submodule update --init --recursive
   ```

2. Create `.env`:

   ```bash
   cp .env.example .env
   # edit .env and set DASHSCOPE_API_KEY
   ```

3. Restore large files:

   ```bash
   # fastest if migrating from the original machine
   rsync -av /home/jack/OpenAvatarChat/models/ ./models/
   rsync -av /home/jack/OpenAvatarChat/resource/avatar/ ./resource/avatar/
   ```

   Or download models again:

   ```bash
   uv run scripts/download_models.py --all --source modelscope
   # or download selected model groups:
   uv run scripts/download_models.py --handler musetalk --source modelscope
   uv run scripts/download_models.py --handler liteavatar --source modelscope
   uv run scripts/download_models.py --handler flashhead --source modelscope
   ```

4. Generate or restore SSL certificates:

   ```bash
   bash scripts/create_ssl_certs.sh
   ```

5. Replace machine-specific IPs.

   The current deployment uses `10.10.2.250`. On a new server, replace it with the new Linux host IP in:

   ```text
   config/chat_with_openai_compatible_bailian_cosyvoice.yaml
   config/chat_with_openai_compatible_bailian_cosyvoice_musetalk.yaml
   config/chat_with_openai_compatible_bailian_cosyvoice_flashhead.yaml
   windows_scripts/*.bat
   ```

6. Confirm GPU container support:

   ```bash
   docker run --rm --gpus all nvidia/cuda:12.1.1-base-ubuntu22.04 nvidia-smi
   ```

7. Start a mode:

   ```bash
   docker compose up -d coturn
   docker compose -f docker-compose.yml -f docker-compose.runtime-musetalk.yml up -d --force-recreate open-avatar-chat
   ```

   Or FlashHead:

   ```bash
   docker compose up -d coturn
   docker compose -f docker-compose.yml -f docker-compose.runtime-flashhead.yml up -d --force-recreate open-avatar-chat
   ```

8. Verify:

   ```bash
   curl -k https://127.0.0.1:8282/readiness
   ```

   Then open:

   ```text
   https://<new-server-ip>:8282/
   ```

## Network requirements

Open these ports between the browser/display machine and the Linux server:

```text
8282 TCP
3478 TCP/UDP
49152-65535 UDP
```

If the page opens but the digital human is blank, check TURN/WebRTC connectivity first.

## Docker image migration

For offline or slow-network migration, export the image on the original machine:

```bash
docker save -o openavatar-images.tar <image-name>:<tag>
```

Load it on the target machine:

```bash
docker load -i openavatar-images.tar
```

Still restore `models/`, `resource/avatar/`, `.env`, and certificates separately, because they are mounted from the host project directory.
