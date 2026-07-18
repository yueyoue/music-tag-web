![](img_6.jpg)

# 🚀 Music Tag Web | 音乐标签编辑器

[简体中文](README.md) | [English](readme_en.md)

> 基于 [xhongc/music-tag-web](https://github.com/xhongc/music-tag-web) (GPL v3.0) 修改，用于 LeChenMusic 项目的歌曲刮削和标签管理。

## 项目简介

Music Tag Web 是一款自托管 Docker 音乐标签编辑器，可在线编辑歌曲标题、专辑、艺术家、歌词、专辑封面等音频元数据，作为 Navidrome 配套边车工具使用。

支持 FLAC, APE, WAV, AIFF, WV, TTA, MP3, M4A, OGG, MPC, OPUS, WMA, DSF, MP4 全格式音频 ID3 标签批量编辑、刮削。

## 🆕 本 Fork 新增功能

- **批量拆分合作艺人**：自动将 `"王力宏/毛不易"` 拆分为多个独立艺术家
- **重复文件检测**：按标题+艺术家检测重复歌曲，显示完整文件路径

## 🎯 核心功能

- 全格式音频文件元数据查看、单条/批量编辑
- 批量自动刮削音乐标签（网易云/QQ音乐/酷狗/酷我/咪咕）
- 内置音乐指纹识别（AcoustID）
- 智能整理本地音乐文件，按艺术家/专辑自动分组
- 批量繁简转换
- 文件名拆分解包，自动提取歌曲信息
- 批量文本替换，清理脏标签
- 内嵌歌词翻译，批量双语歌词写入
- 批量导出/上传替换专辑封面
- 响应式 UI，手机浏览器可访问

## 📦 部署方式

### Docker Compose 部署（推荐）

1. 创建 `docker-compose.yml`：

```yaml
version: '3'

services:
  music-tag:
    image: ghcr.io/yueyoue/music-tag-web:latest
    container_name: music-tag-web
    ports:
      - "8002:8002"
    volumes:
      - /path/to/your/music:/app/media:rw
      - /path/to/your/config:/app/data
    restart: unless-stopped
```

2. 修改路径：
   - `/path/to/your/music` → 你的 NAS/服务器音乐文件夹路径
   - `/path/to/your/config` → 配置持久化目录

3. 拉取镜像并启动：
```bash
docker compose pull
docker compose up -d
```

4. 访问：`http://你的IP:8002/admin`
   - 默认账号：`admin`
   - 默认密码：`admin`
   - **首次登录务必修改密码！**

### Docker 命令行部署

```bash
docker run -d \
  -p 8002:8002 \
  -v /path/to/your/music:/app/media:rw \
  -v /path/to/your/config:/app/data \
  --restart=always \
  ghcr.io/yueyoue/music-tag-web:latest
```

## 📷 界面预览

![img_13.png](img_13.png)
![img_15.png](img_15.png)
![img_16.png](img_16.png)
![img_17.png](img_17.png)

## 📝 说明

- 本项目仅供个人研究学习使用
- 原项目基于 GPL v3.0 许可证
- 原项目地址：https://github.com/xhongc/music-tag-web
