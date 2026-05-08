# Open Avatar 数字人项目

这是一个基于 OpenAvatarChat 改造的实时交互数字人项目，当前主要用于在局域网环境中部署数字人问答、语音交互和大屏展示。

## 主要功能

- 实时数字人对话：浏览器通过 WebRTC 连接后端，实现语音输入、模型回复、语音合成和数字人画面输出。
- 多数字人模式：当前保留并适配了 MuseTalk、FlashHead、LiteAvatar 等数字人后端。
- MuseTalk 视频数字人：使用人物视频作为数字人基底，适合追求画面稳定性和清晰度的展示场景。
- FlashHead 图片数字人：使用单张人物图片生成说话数字人，支持快速更换形象。
- LiteAvatar 轻量数字人：保留轻量模式，适合后续低资源或快速验证场景。
- 阿里百炼接入：当前配置使用阿里百炼兼容 OpenAI 的大模型接口，并配合 CosyVoice 进行语音合成。
- WebRTC 跨设备访问：已配置 TURN，用于解决其他电脑能打开页面但数字人音视频不显示的问题。
- 音画同步调优：FlashHead 模式中加入了帧率一致性、视频延迟和视频速度补偿参数。
- 容器化部署：服务通过 Docker / Docker Compose 运行，便于在 Linux GPU 服务器上迁移和部署。
- Windows 启动脚本：提供 MuseTalk、FlashHead、LiteAvatar 的 Windows 远程启动脚本，方便从本机控制 Ubuntu 服务。

## 当前支持模式

| 模式 | 输入素材 | 适合场景 |
| --- | --- | --- |
| MuseTalk | 人物视频 | 清晰度、稳定性要求较高的数字人展示 |
| FlashHead | 人物图片 | 快速更换形象、单图生成数字人 |
| LiteAvatar | 模型权重和预设资源 | 轻量运行和兼容测试 |

## 核心目录

```text
config/                 运行配置
src/                    后端源码和各类 handler
resource/avatar/        数字人图片、视频素材，本仓库默认不上传自定义素材
models/                 模型权重，本仓库不上传
windows_scripts/        Windows 远程启动脚本
docker-compose.yml      Docker Compose 主配置
MIGRATION.md            迁移说明
.env.example            环境变量示例
```

## 没有上传到 Git 的内容

本仓库不包含大模型文件、真实 API Key、自定义头像素材、SSL 私钥、Python wheel 缓存和运行缓存。

这些内容不适合放进 Git。恢复方式见：

```text
MIGRATION.md
```

## 部署说明

新机器部署时，先准备 NVIDIA GPU、Docker、Docker Compose 和 NVIDIA Container Toolkit，然后按 `MIGRATION.md` 恢复模型、头像素材、`.env` 和证书。

启动 MuseTalk：

```bash
docker compose up -d coturn
docker compose -f docker-compose.yml -f docker-compose.runtime-musetalk.yml up -d --force-recreate open-avatar-chat
```

启动 FlashHead：

```bash
docker compose up -d coturn
docker compose -f docker-compose.yml -f docker-compose.runtime-flashhead.yml up -d --force-recreate open-avatar-chat
```

服务默认访问地址：

```text
https://服务器IP:8282/
```

## 网络要求

如果需要让其他电脑或数字大屏访问，需要保证以下端口可达：

```text
8282 TCP
3478 TCP/UDP
49152-65535 UDP
```

页面能打开但没有数字人画面时，优先检查 WebRTC/TURN 网络连通性。

## 许可证

本项目基于 OpenAvatarChat 改造，保留原项目 Apache-2.0 许可证。
