![](music-tag.png)

# 🚀 Music Tag Web | 音乐标签编辑器

[简体中文](README.md) | [English](readme_en.md)

> 基于 [xhongc/music-tag-web](https://github.com/xhongc/music-tag-web) (GPL v3.0) 二次开发，新增拆分合作艺人、重复文件检测等功能。

## 项目简介

Music Tag Web 是一款自托管 Docker 音乐标签编辑器，专为 NAS、远程影音服务器打造，可在线编辑歌曲标题、专辑、艺术家、歌词、专辑封面等完整音频元数据，完美作为 Navidrome 配套边车工具。

支持 FLAC, APE, WAV, AIFF, WV, TTA, MP3, M4A, OGG, MPC, OPUS, WMA, DSF, DFF 全格式音频 ID3 标签批量编辑、刮削、修复整理。

## 🎉 核心功能

- 全格式音频文件元数据查看、单条/批量编辑、修复 ID3 标签
- 批量自动刮削音乐标签，自动匹配专辑信息、艺术家、歌词、封面
- 内置音乐指纹识别（AcoustID），无标签歌曲自动识别匹配元数据
- 智能整理本地音乐文件，按艺术家、专辑自动分组
- 多维度文件排序：文件名、文件大小、文件更新时间
- 批量繁简转换，一键转换歌曲标签简体/繁体
- 文件名拆分解包，自动从文件名提取歌曲信息
- 批量文本替换，清理曲库脏标签、乱码
- 内嵌歌词翻译，批量双语歌词写入音频文件
- 批量导出/自定义上传替换专辑封面
- 全响应式移动端 UI，手机浏览器远程访问

### ✂️ 自定义新增功能

- **拆分合作艺人** — 自动将 `"王力宏/毛不易"` 或 `"王力宏&毛不易"` 拆分为多个独立艺术家
- **重复文件检测** — 按标题+艺术家分组检测重复歌曲，显示冗余文件大小和完整路径

## 💯 使用部署指南

### 前提条件

- 已安装 Docker（版本 20.10+）
- 已安装 Docker Compose（Docker 自带）

### 方式一：Docker Compose 部署（推荐）

创建 `docker-compose.yml` 文件：

```yaml
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

> **重要**：将 `/path/to/your/music` 替换为你的 NAS/服务器本地音乐文件夹路径！
> 将 `/path/to/your/config` 替换为配置持久化目录！

启动：

```bash
docker compose up -d
```

查看日志：

```bash
docker compose logs -f
```

等待出现 `Listening at: http://0.0.0.0:8002` 表示启动成功。

### 方式二：Docker 命令行部署

```bash
docker run -d \
  -p 8002:8002 \
  -v /path/to/your/music:/app/media:rw \
  -v /path/to/your/config:/app/data \
  --restart=always \
  --name music-tag-web \
  ghcr.io/yueyoue/music-tag-web:latest
```

### 方式三：本地构建部署

```bash
git clone -b dev_1.0 https://github.com/yueyoue/music-tag-web.git
cd music-tag-web
docker build -t music-tag-web:latest .
docker compose up -d
```

### 访问

启动后访问 `http://你的IP:8002` 即可使用。

管理后台：`http://你的IP:8002/admin/`，默认账号 `admin`，默认密码 `admin`。

**首次登录务必修改默认密码！**

## 🔄 更新版本

### 使用预构建镜像（推荐）

```bash
# 拉取最新镜像
docker compose pull

# 重启容器
docker compose up -d
```

### 本地构建更新

```bash
# 拉取最新代码
git pull origin dev_1.0

# 重新构建并启动
docker compose up -d --build
```

## ❓ 常见问题

**Q: 默认账号密码是什么？**
A: 管理后台默认 `admin` / `admin`，首次登录请修改密码。

**Q: 端口被占用了怎么办？**
A: 编辑 `docker-compose.yml`，将 `8002:8002` 改为 `其他端口:8002`，例如 `8080:8002`。

**Q: 如何修改音乐目录？**
A: 编辑 `docker-compose.yml`，修改 `volumes` 中的路径，然后 `docker compose up -d` 重启。

**Q: 支持哪些音频格式？**
A: FLAC, APE, WAV, AIFF, WV, TTA, MP3, M4A, OGG, MPC, OPUS, WMA, DSF, DFF。

## 📷 界面截图

![](img.png)
![img_3.png](img_3.png)
![img_2.png](img_2.png)

## 📝 开发文档

详见 [DEV.md](DEV.md)，包含项目结构、API 接口、数据模型、新增功能实现细节等。

## 💬 反馈

欢迎提交 [Issues](https://github.com/yueyoue/music-tag-web/issues)。

## 免责声明

禁止任何形式的商业用途，包括但不仅限于售卖/打赏/获利，不得使用本代码进行任何形式的牟利/贩卖/传播，仅供个人私下研究学习使用。

本项目基于 GPL V3.0 许可证发行。数据来源是从各官方音乐平台的公开服务器中拉取，本项目不对数据的准确性负责。使用者务必在24小时内清除使用本项目过程中所产生的版权数据。

音乐平台不易，请尊重版权，支持正版。
