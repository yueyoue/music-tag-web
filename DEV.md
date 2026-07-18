# Music Tag Web 开发文档

> 基于 [xhongc/music-tag-web](https://github.com/xhongc/music-tag-web) fork 修改

## 项目信息

| 项目 | 说明 |
|------|------|
| 仓库地址 | https://github.com/yueyoue/music-tag-web |
| 默认分支 | dev_1.0 |
| 技术栈 | Django 2.2 + Vue.js + Celery + SQLite |
| 镜像地址 | ghcr.io/yueyoue/music-tag-web:latest |

## Fork 新增功能

### 1. 批量拆分合作艺人

**功能描述**：批量将合作艺人标签拆分为多个独立艺术家。

例如：`"王力宏/毛不易"` → `"王力宏"` + `"毛不易"`

**支持的分隔符**：
- `/` — 最常见，如 `王力宏/毛不易`
- `&` — 如 `王力宏&毛不易`
- `、` — 中文顿号
- `feat.` / `feat` — 如 `王力宏 feat. 毛不易`
- `ft.` / `ft` — 如 `王力宏 ft. 毛不易`
- `x` — 如 `王力宏 x 毛不易`

**使用方法**：
1. 在文件列表中选中需要处理的文件（支持多选或选中整个文件夹）
2. 点击「拆分合作艺人」按钮
3. 确认后自动处理，显示成功/失败统计

**后端实现**：
- 接口：`POST /api/split_artist/`
- 入参：`file_full_path`（当前路径）、`select_data`（选中的文件/文件夹列表）、`separator`（分隔符，默认 `/`）
- 返回：`results`（处理结果列表）、`success_count`、`fail_count`、`total`
- 核心逻辑：`applications/task/services/split_utils.py` → `split_artists()`

**前端实现**：
- 按钮位置：选中文件后的操作区，「自动修改」和「整理文件夹」下方
- 文件：`web/src/views/home/home.vue` → `handleSplitArtist()` 方法
- API：`web/src/api/apiUrl/task/task.js` → `splitArtist`

---

### 2. 重复文件检测

**功能描述**：扫描选中的文件，按 标题+艺术家 检测重复歌曲，显示完整文件路径方便手动删除。

**使用方法**：
1. 在文件列表中选中要检测的文件或文件夹
2. 点击「重复文件检测」按钮
3. 弹窗显示检测结果：
   - 重复组数
   - 重复文件总数
   - 估算冗余空间
   - 每组重复文件的完整路径

**后端实现**：
- 接口：`POST /api/check_duplicate/`
- 入参：`file_full_path`（当前路径）、`select_data`（选中的文件/文件夹列表）
- 返回：`duplicates`（重复组列表）、`total_groups`、`total_dup_files`、`wasted_size`
- 核心逻辑：`applications/task/services/split_utils.py` → `find_duplicate_songs()`
- 匹配规则：标题和艺术家都相同（忽略大小写和首尾空格）视为重复

**前端实现**：
- 按钮位置：选中文件后的操作区，与「拆分合作艺人」并排
- 文件：`web/src/views/home/home.vue` → `handleCheckDuplicate()` 方法
- API：`web/src/api/apiUrl/task/task.js` → `checkDuplicate`

---

## 新增文件清单

| 文件路径 | 说明 |
|----------|------|
| `applications/task/services/split_utils.py` | 拆分艺人 + 重复检测的核心逻辑 |
| `Dockerfile` | 根目录 Docker 构建文件 |
| `.github/workflows/build.yml` | GitHub Actions 自动构建镜像 |

## 修改文件清单

| 文件路径 | 修改内容 |
|----------|----------|
| `applications/task/views.py` | 新增 `split_artist` 和 `check_duplicate` 接口 |
| `applications/task/serialziers.py` | 新增 `SplitArtistSerializer` 和 `DuplicateCheckSerializer` |
| `web/src/api/apiUrl/task/task.js` | 新增 `splitArtist` 和 `checkDuplicate` API 方法 |
| `web/src/views/home/home.vue` | 新增两个按钮和对应的处理方法 |
| `README.md` | 更新为本项目信息 |

## 部署

### Docker Compose

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

### 本地构建

```bash
git clone https://github.com/yueyoue/music-tag-web.git
cd music-tag-web
docker build -t music-tag-web:latest .
docker compose up -d
```

## CI/CD

推送到 `dev_1.0` 分支后，GitHub Actions 自动：
1. 构建 Docker 镜像
2. 推送到 GitHub Container Registry (ghcr.io)
3. 镜像标签：`latest` + commit SHA

## 原项目参考

- 原项目：https://github.com/xhongc/music-tag-web
- 许可证：GPL v3.0
- 使用手册：https://xiers-organization.gitbook.io/music-tag-web-v2/
