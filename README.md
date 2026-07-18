![](music-tag.png)

# 🎵 Music Tag Web V2

音乐标签 Web 版 —— 可在浏览器中编辑歌曲的标题、专辑、艺术家、歌词、封面等元数据信息。

支持 FLAC、APE、WAV、AIFF、WV、TTA、MP3、MP4、M4A、OGG、MPC、OPUS、WMA、DSF、DFF 等音频格式。

基于 [xhongc/music-tag-web](https://github.com/xhongc/music-tag-web) 二次开发。

## ✨ 功能特性

### 核心功能
- 📝 批量编辑音乐标签（标题、艺术家、专辑、风格、年份、歌词、封面）
- 🔍 从网易云音乐、QQ音乐、咪咕音乐自动获取标签信息
- 📂 文件浏览器，支持文件夹导航
- 🎨 自动/手动修改标签
- 📁 整理文件夹（按艺术家/专辑归类）

### V2 新增功能
- 🎵 Subsonic API（可对接 Subsonic 兼容播放器）
- 📋 歌单管理
- 🔎 搜索功能
- 🎤 QQ 音乐元数据来源
- 🖥️ SimpleUI 管理后台
- 🕐 最近播放记录
- 📦 gzip 压缩传输

### 自定义功能
- ✂️ **拆分合作艺人** — 自动将 "王力宏/毛不易" 或 "王力宏&毛不易" 拆分为多个独立艺术家
- 🔁 **重复文件检测** — 按标题+艺术家分组检测重复歌曲，显示冗余文件大小

## 🚀 安装部署

### 前提条件

- 已安装 [Docker](https://docs.docker.com/get-docker/)（版本 20.10+）
- 已安装 [Docker Compose](https://docs.docker.com/compose/install/)（Docker 自带）
- 已安装 [Git](https://git-scm.com/downloads)

### 方式一：Docker Compose（推荐）

适合 NAS（飞牛、群晖等）和 Linux 服务器。

```bash
# 1. 克隆项目
git clone -b dev_1.0 https://github.com/yueyoue/music-tag-web.git
cd music-tag-web

# 2. 修改配置（必须改两项）
#    a) docker-compose.yml 中 volumes 的音乐目录
#       将 /path/to/your/music 改为你的实际音乐文件夹路径
#    b) MYSQL_ROOT_PASSWORD 和 db 的 MYSQL_ROOT_PASSWORD
#       改为你自己的密码（两个地方要保持一致）

# 3. 启动（首次会自动构建镜像，约 3-5 分钟）
docker compose up -d

# 4. 查看日志，等待出现 "Listening at: http://0.0.0.0:8002" 表示启动成功
docker compose logs -f django
```

启动后访问 `http://你的IP:8002` 即可使用。

> **飞牛 NAS 用户**可直接使用 `docker-compose.feiniu.yml`：
> ```bash
> docker compose -f docker-compose.feiniu.yml up -d --build
> ```

### 方式二：Docker 单容器

需要先准备好 MySQL 和 Redis，或使用已有的。

```bash
# 构建镜像
docker build -t music-tag-web .

# 运行
docker run -d \
  -p 8002:8002 \
  -v /path/to/your/music:/app/media \
  -e MYSQL_HOST=你的MySQL地址 \
  -e MYSQL_PORT=3306 \
  -e MYSQL_DATABASE=music3 \
  -e MYSQL_USER=root \
  -e MYSQL_PASSWORD=你的密码 \
  -e REDIS_URL=redis://你的Redis地址:6379/0 \
  --name music-tag-web \
  music-tag-web
```

### 方式三：本地开发

```bash
# 安装后端依赖
pip install -r requirements.txt

# 安装前端依赖
cd web
npm install --registry https://registry.npmmirror.com
npx webpack --config build/webpack.prod.conf.js
cd ..

# 启动服务
python manage.py migrate
python manage.py runserver 0.0.0.0:8002
```

## ❓ 常见问题

**Q: 默认登录账号密码是什么？**
A: 首次启动会自动创建数据库，访问 `http://你的IP:8002` 直接使用，无需登录。
如需管理后台，访问 `http://你的IP:8002/admin/`，默认账号 `admin`，密码 `admin`。

**Q: 如何修改 MySQL 密码？**
A: 编辑 `docker-compose.yml`，修改两处 `MYSQL_ROOT_PASSWORD`（django 和 db 服务都要改），然后：
```bash
docker compose down -v   # 删除旧数据
docker compose up -d     # 重新启动
```
> ⚠️ `down -v` 会删除数据库数据，首次部署前改密码最方便。

**Q: 如何更新到最新版本？**
```bash
git pull origin dev_1.0
docker compose up -d --build
```

**Q: 端口被占用了怎么办？**
A: 编辑 `docker-compose.yml`，将 `ports` 中的 `8002:8002` 改为 `其他端口:8002`，例如 `8080:8002`。

---

## ⚙️ 配置说明

| 环境变量 | 默认值 | 说明 |
|---------|--------|------|
| MYSQL_HOST | db | MySQL 主机地址 |
| MYSQL_PORT | 3306 | MySQL 端口 |
| MYSQL_DATABASE | music3 | 数据库名 |
| MYSQL_USER | root | MySQL 用户名 |
| MYSQL_PASSWORD | - | MySQL 密码 |
| REDIS_URL | redis://redis:6379/0 | Redis 连接地址 |

音乐目录通过 Docker volume 映射到容器内的 `/app/media`。

## 📷 界面截图

![](img.png)
![img_3.png](img_3.png)
![img_2.png](img_2.png)

## 📌 前端开发

修改前端代码后，需要重新编译：

```bash
cd web
npm install --registry https://registry.npmmirror.com
npx webpack --config build/webpack.prod.conf.js
```

也可以在 GitHub 上手动触发 Actions 自动编译：进入 Actions → Build Frontend → Run workflow。

## 💬 反馈

欢迎提出 Issues，我会尽量满足需求。

## 免责声明

禁止任何形式的商业用途，包括但不仅限于售卖/打赏/获利，不得使用本代码进行任何形式的牟利/贩卖/传播，再次强调仅供个人私下研究学习技术使用，有条件者请支持正版音乐！

本项目基于 GPL V3.0 许可证发行。数据来源是从各官方音乐平台的公开服务器中拉取，本项目不对数据的准确性负责。使用者务必在24小时内清除使用本项目过程中所产生的版权数据。

音乐平台不易，请尊重版权，支持正版。
