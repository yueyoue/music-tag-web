FROM python:3.9.12-slim-bullseye as python-build

# 构建阶段：编译 Python 依赖
RUN apt-get update && apt-get install --no-install-recommends -y \
    build-essential \
    libpq-dev \
    default-libmysqlclient-dev \
    libffi-dev \
    libjpeg-dev \
    libxml2 \
    libxslt1-dev

COPY ./requirements .
RUN pip wheel --wheel-dir /usr/src/app/wheels \
    -r base.txt -i https://pypi.tuna.tsinghua.edu.cn/simple

# 运行阶段
FROM python:3.9.12-slim-bullseye

LABEL title="Music Tag Web"
LABEL description="音乐标签编辑器 - 基于 xhongc/music-tag-web fork"
LABEL authors="yueyoue"

ARG APP_HOME=/app
ENV PYTHONUNBUFFERED 1
ENV PYTHONDONTWRITEBYTECODE 1

WORKDIR ${APP_HOME}

# 安装运行时依赖（与原项目一致）
RUN apt-get update && apt-get install --no-install-recommends -y \
    libpq-dev \
    gettext \
    default-libmysqlclient-dev \
    ffmpeg \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /var/lib/apt/lists/*

# 安装 Python 依赖
COPY --from=python-build /usr/src/app/wheels /wheels/
RUN pip install --no-cache-dir --no-index --find-links=/wheels/ /wheels/* \
    && rm -rf /wheels/

# 复制应用代码（前端静态文件已在 static/js/ 和 static/dist/ 中）
COPY . ${APP_HOME}

# 启动脚本（与原项目一致，端口改为 8002）
RUN printf '#!/bin/bash\nset -o errexit\nset -o pipefail\nset -o nounset\n\npython manage.py migrate --run-syncdb\ngunicorn -w 2 -b 0.0.0.0:8002 django_vue_cli.wsgi:application --timeout 120 --worker-class=gevent\n' > /start \
    && chmod +x /start

EXPOSE 8002

CMD ["/start"]
