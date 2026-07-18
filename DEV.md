# Music Tag Web 开发文档

> 基于 [xhongc/music-tag-web](https://github.com/xhongc/music-tag-web) (GPL v3.0) fork 修改

---

## 1. 项目信息

| 项目 | 说明 |
|------|------|
| 仓库地址 | https://github.com/yueyoue/music-tag-web |
| 默认分支 | dev_1.0 |
| 技术栈 | Django 2.2 + Vue.js 2 + Celery + SQLite |
| Docker 镜像 | ghcr.io/yueyoue/music-tag-web:latest |
| 端口 | 8002 |
| 默认账号 | admin / admin |

---

## 2. 项目结构

```
music-tag-web/
├── applications/                    # Django 应用
│   ├── music/                       # 音乐数据模型（专辑、歌曲、艺术家、风格等）
│   │   ├── models.py                # Album, Track, Artist, Genre, Folder, Attachment 等
│   │   ├── views.py                 # 音乐相关 API
│   │   └── utils.py                 # 工具函数
│   ├── task/                        # 核心业务：文件管理、ID3编辑、刮削、任务
│   │   ├── models.py                # Task（刮削任务记录）, TaskRecord（批量任务记录）
│   │   ├── views.py                 # 主要 API 入口（见下方 API 列表）
│   │   ├── serialziers.py           # DRF 序列化器
│   │   ├── constants.py             # ALLOW_TYPE 支持的音频格式列表
│   │   ├── tasks.py                 # Celery 异步任务（扫描、刮削、整理）
│   │   ├── utils.py                 # 匹配算法、繁简转换
│   │   └── services/                # 业务服务层
│   │       ├── music_ids.py         # MusicIDS 类：读取/解析音频文件 ID3 标签
│   │       ├── music_resource.py    # MusicResource：多平台刮削源调度（网易云/QQ/酷狗/酷我/咪咕/AcoustID）
│   │       ├── update_ids.py        # save_music()：将刮削结果写入音频文件 ID3 标签
│   │       ├── scan_utils.py        # 扫描音乐文件并入库
│   │       ├── split_utils.py       # 【Fork新增】拆分合作艺人 + 重复文件检测
│   │       ├── acoust.py            # AcoustID 音频指纹识别
│   │       ├── kugou.py             # 酷狗音乐刮削
│   │       ├── kuwo.py              # 酷我音乐刮削
│   │       ├── qm.py                # QQ音乐刮削
│   │       └── smart_tag_resource.py # 智能标签匹配
│   ├── subsonic/                    # Subsonic API 兼容层
│   └── user/                        # 用户认证
├── component/                       # 公共组件
│   ├── music_tag/                   # 音频标签读写库（基于 mutagen，支持 flac/mp3/ape/wav/m4a 等）
│   ├── zhconv/                      # 繁简转换
│   ├── mz/                          # 音频指纹（chromaprint/fpcalc）
│   └── drf/                         # DRF 扩展（认证、分页、渲染器等）
├── django_vue_cli/                  # Django 项目配置
│   ├── settings.py                  # 数据库、中间件、CORS 等配置
│   ├── urls.py                      # 路由总入口
│   ├── celery_app.py                # Celery 配置
│   └── wsgi.py                      # WSGI 入口
├── web/                             # Vue.js 前端源码
│   └── src/
│       ├── views/home/home.vue      # 主页面（文件列表、ID3编辑、批量操作、刮削）
│       ├── api/apiUrl/task/task.js  # API 接口定义
│       └── ...
├── static/dist/                     # 前端构建产物（已包含在仓库中）
├── requirements/                    # Python 依赖
│   ├── base.txt                     # 生产依赖
│   └── local.txt                    # 开发依赖（引用 base.txt）
├── compose/                         # Docker 构建配置（原始）
│   ├── local/django/Dockerfile      # 本地开发 Dockerfile
│   └── prod/django/Dockerfile       # 生产 Dockerfile
├── Dockerfile                       # 【Fork新增】根目录 Dockerfile（简化版，端口 8002）
├── .github/workflows/build.yml      # 【Fork新增】GitHub Actions 自动构建
├── manage.py                        # Django 管理入口
└── DEV.md                           # 本文档
```

---

## 3. 核心数据模型

### 3.1 音乐相关（applications/music/models.py）

| 模型 | 说明 | 关键字段 |
|------|------|----------|
| `Folder` | 文件/文件夹 | `path`, `file_type`(folder/music/image), `uid`, `parent_id`, `state` |
| `Track` | 歌曲 | `path`, `title`, `artist`(FK), `album`(FK), `duration`, `size`, `suffix`, `lyrics` |
| `Album` | 专辑 | `name`, `artist`(FK), `genre`(FK), `song_count`, `duration` |
| `Artist` | 艺术家 | `name`, `album_count`, `song_count` |
| `Genre` | 风格 | `name` |
| `Attachment` | 附件（封面图） | `file`(ImageField), `url`, `size`, `mimetype` |

### 3.2 任务相关（applications/task/models.py）

| 模型 | 说明 | 关键字段 |
|------|------|----------|
| `Task` | 刮削任务记录 | `song_name`, `full_path`, `state`(wait/success/failed), `parent_path`, `filename` |
| `TaskRecord` | 批量任务记录 | `song_name`, `full_path`, `batch`(批次号), `icon`, `state` |

### 3.3 支持的音频格式（applications/task/constants.py）

```python
ALLOW_TYPE = ["flac", "mp3", "ape", "wav", "aiff", "wv", "tta", "m4a", "ogg", "mpc",
              "opus", "wma", "dsf", "dff", "wmv"]
```

---

## 4. API 接口列表

所有接口前缀：`/api/`（定义在 `applications/task/views.py` → `TaskViewSets`）

### 4.1 文件管理

| 接口 | 方法 | 说明 | 入参 |
|------|------|------|------|
| `/api/file_list/` | POST | 获取文件列表 | `file_path`, `sorted_fields` |

### 4.2 ID3 标签

| 接口 | 方法 | 说明 | 入参 |
|------|------|------|------|
| `/api/music_id3/` | POST | 获取单个文件的 ID3 信息 | `file_path`, `file_name` |
| `/api/update_id3/` | POST | 更新单个/多个文件的 ID3 信息 | `music_id3_info`(数组) |
| `/api/batch_update_id3/` | POST | 批量手动修改 ID3 | `file_full_path`, `select_data`, `music_info` |
| `/api/batch_auto_update_id3/` | POST | 批量自动刮削 | `file_full_path`, `select_data`, `music_info`(含 source_list, select_mode) |

### 4.3 刮削相关

| 接口 | 方法 | 说明 | 入参 |
|------|------|------|------|
| `/api/fetch_id3_by_title/` | POST | 按标题搜索歌曲元数据 | `resource`(netease/qmusic/kugou/kuwo/migu/acoustid/smart_tag), `title`, `full_path` |
| `/api/fetch_lyric/` | POST | 获取歌词 | `resource`, `song_id` |

### 4.4 文件整理

| 接口 | 方法 | 说明 | 入参 |
|------|------|------|------|
| `/api/tidy_folder/` | POST | 整理文件夹（按艺术家/专辑分组） | `root_path`, `first_dir`, `second_dir`, `file_full_path`, `select_data` |

### 4.5 【Fork新增】拆分与检测

| 接口 | 方法 | 说明 | 入参 |
|------|------|------|------|
| `/api/split_artist/` | POST | 批量拆分合作艺人 | `file_full_path`, `select_data`, `separator`(默认`/`) |
| `/api/check_duplicate/` | POST | 重复文件检测 | `file_full_path`, `select_data` |

### 4.6 其他

| 接口 | 方法 | 说明 |
|------|------|------|
| `/api/upload_image/` | POST | 上传图片（返回 base64） |
| `/api/translation_lyc/` | POST | 歌词翻译（简体→繁体或其他语言） |
| `/api/task1/` | GET | 触发扫描任务（Celery） |
| `/api/task2/` | GET | 清空所有数据 |
| `/api/full_scan_folder/` | GET | 全量扫描文件夹 |
| `/api/clear_celery/` | GET | 清理 Celery 任务 |
| `/api/active_queue/` | GET | 查看活跃任务 |
| `/api/record/` | GET | 刮削任务记录列表 |

### 4.7 认证

| 接口 | 方法 | 说明 |
|------|------|------|
| `/api/token/` | POST | JWT 登录（返回 token） |
| `/user/info/` | GET | 当前用户信息 |

---

## 5. 刮削源（applications/task/services/music_resource.py）

通过 `MusicResource(source)` 统一调度：

| 源名称 | source 参数 | 说明 |
|--------|-------------|------|
| 网易云音乐 | `netease` | 国内最全，歌词质量高 |
| QQ音乐 | `qmusic` | 覆盖广，部分独家 |
| 酷狗音乐 | `kugou` | 补充源 |
| 酷我音乐 | `kuwo` | 补充源 |
| 咪咕音乐 | `migu` | 补充源 |
| AcoustID | `acoustid` | 音频指纹识别，适合无标签文件 |
| 智能匹配 | `smart_tag` | 综合多源匹配 |

每个源实现两个方法：
- `fetch_id3_by_title(title)` → 搜索歌曲，返回元数据列表
- `fetch_lyric(song_id)` → 获取 LRC 歌词

---

## 6. 核心业务流程

### 6.1 刮削流程

```
用户选中文件 → 点击「自动修改」→ 选择刮削源
  → 批量创建 TaskRecord（batch 批次号）
  → 遍历每个文件：
    → 读取文件 ID3（标题/艺术家/专辑）
    → 调用 MusicResource.fetch_id3_by_title() 搜索
    → match_score() 匹配评分（标题2分 + 艺术家 + 专辑）
    → 匹配成功（≥3分）→ fetch_lyric() 获取歌词
    → save_music() 写入 ID3 标签
    → 更新 Task 状态
```

### 6.2 匹配算法（applications/task/utils.py → match_score()）

```
标题完全匹配 → 2分
标题包含关系 → 1分
艺术家匹配 → 2分（精确）/ 1分（包含）
专辑匹配 → 2分（精确）/ 1分（包含）
总分 ≥ 3 → 匹配成功
```

支持繁简转换匹配（`component/zhconv/`）。

### 6.3 ID3 写入（applications/task/services/update_ids.py → save_music()）

写入字段：`title`, `artist`(支持多值), `album`, `albumartist`, `discnumber`, `tracknumber`, `genre`, `year`, `lyrics`, `comment`, `artwork`(封面), `filename`(重命名)

封面处理：
- HTTP URL → 下载图片 → 写入 artwork
- Base64 → 解码 → 写入 artwork
- 超过 5MB → 自动压缩到 2048x2048
- 可选保存封面文件到同目录

---

## 7. Fork 新增功能

### 7.1 批量拆分合作艺人

**功能**：批量将合作艺人标签拆分为多个独立艺术家。

例如：`"王力宏/毛不易"` → `"王力宏"` + `"毛不易"`

**支持的分隔符**：`/` `&` `、` `feat.` `feat` `ft.` `ft` `x`

**使用**：选中文件 → 点击「拆分合作艺人」→ 确认

**实现**：
- 后端：`applications/task/services/split_utils.py` → `split_artists()`, `batch_split_artists()`
- 接口：`POST /api/split_artist/`
- 入参：`file_full_path`, `select_data`, `separator`(默认`/`)
- 返回：`results`(每项含 path/success/original/artists/error), `success_count`, `fail_count`, `total`
- 前端：`web/src/views/home/home.vue` → `handleSplitArtist()`
- API：`web/src/api/apiUrl/task/task.js` → `splitArtist`

**核心逻辑**：
1. 遍历选中文件
2. 读取 artist 标签
3. 按分隔符拆分
4. 调用 `music_tag.set("artist", [artist1, artist2, ...])` 写入多值
5. `f.save()` 保存

---

### 7.2 重复文件检测

**功能**：按 标题+艺术家 检测重复歌曲，显示完整文件路径。

**使用**：选中文件/文件夹 → 点击「重复文件检测」

**实现**：
- 后端：`applications/task/services/split_utils.py` → `find_duplicate_songs()`
- 接口：`POST /api/check_duplicate/`
- 入参：`file_full_path`, `select_data`
- 返回：`duplicates`(每组含 title/artist/count/files), `total_groups`, `total_dup_files`, `wasted_size`
- 前端：`web/src/views/home/home.vue` → `handleCheckDuplicate()`
- API：`web/src/api/apiUrl/task/task.js` → `checkDuplicate`

**匹配规则**：标题和艺术家都相同（忽略大小写、首尾空格）视为重复。

---

## 8. 文件变更清单

### 8.1 Fork 新增文件

| 文件 | 说明 |
|------|------|
| `applications/task/services/split_utils.py` | 拆分艺人 + 重复检测核心逻辑 |
| `Dockerfile` | 根目录 Docker 构建文件（端口 8002） |
| `.github/workflows/build.yml` | GitHub Actions 自动构建推送到 ghcr.io |
| `DEV.md` | 本开发文档 |

### 8.2 Fork 修改文件

| 文件 | 修改内容 |
|------|----------|
| `applications/task/views.py` | 新增 `split_artist` 和 `check_duplicate` 接口，导入 split_utils |
| `applications/task/serialziers.py` | 新增 `SplitArtistSerializer` 和 `DuplicateCheckSerializer` |
| `web/src/api/apiUrl/task/task.js` | 新增 `splitArtist` 和 `checkDuplicate` API 方法 |
| `web/src/views/home/home.vue` | 新增「拆分合作艺人」「重复文件检测」按钮和处理方法 |
| `README.md` | 更新为本项目信息 |

---

## 9. 部署

### Docker Compose（推荐）

```yaml
version: '3'

services:
  music-tag:
    image: ghcr.io/yueyoue/music-tag-web:latest
    container_name: music-tag-web
    ports:
      - "8002:8002"
    volumes:
      - /path/to/your/music:/app/media:rw    # 音乐目录
      - /path/to/your/config:/app/data        # 配置/数据库目录
    restart: unless-stopped
```

- 音乐目录挂载到容器内 `/app/media`
- 数据库（SQLite）和配置保存在 `/app/data`
- 访问：`http://IP:8002/admin`，默认 admin/admin

### 本地构建

```bash
git clone https://github.com/yueyoue/music-tag-web.git
cd music-tag-web
docker build -t music-tag-web:latest .
docker compose up -d
```

---

## 10. CI/CD

推送到 `dev_1.0` 分支后，GitHub Actions 自动：

1. 检出代码
2. 登录 ghcr.io（使用 `GITHUB_TOKEN`，无需额外配置）
3. 构建 Docker 镜像
4. 推送到 `ghcr.io/yueyoue/music-tag-web:latest`

工作流文件：`.github/workflows/build.yml`

---

## 11. 开发注意事项

### 11.1 前端

- 前端源码在 `web/src/`，构建产物在 `static/dist/`
- 修改前端后需要重新构建：`cd web && npm install && npm run build`
- 主页面逻辑集中在 `web/src/views/home/home.vue`（约 1400 行）
- API 定义在 `web/src/api/apiUrl/task/task.js`

### 11.2 后端

- Django 版本较旧（2.2），注意兼容性
- 数据库默认 SQLite，生产可切换 MySQL（settings.py 中有注释的 MySQL 配置）
- 异步任务用 Celery + Redis
- 音频标签读写用 `component/music_tag/`（基于 mutagen 的封装）
- 文件路径使用 UTF-8 编码，注意中文路径兼容

### 11.3 添加新功能的标准流程

1. **后端**：`applications/task/` 下添加
   - `services/` 新建服务文件（业务逻辑）
   - `serialziers.py` 添加序列化器
   - `views.py` 添加接口（`@action` 装饰器）
2. **前端**：
   - `web/src/api/apiUrl/task/task.js` 添加 API 方法
   - `web/src/views/home/home.vue` 添加按钮和处理方法
3. **测试**：本地 `python manage.py runserver` 验证
4. **部署**：push 到 `dev_1.0`，自动构建镜像

---

## 12. 原项目参考

| 资源 | 链接 |
|------|------|
| 原项目 | https://github.com/xhongc/music-tag-web |
| 许可证 | GPL v3.0 |
| 使用手册 V2 | https://xiers-organization.gitbook.io/music-tag-web-v2/ |
| 原项目 Star | 5800+ |
