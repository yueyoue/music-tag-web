FROM python:3.9.12-slim-bullseye as python-build

# 构建阶段：安装依赖
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

# 安装运行时依赖
RUN apt-get update && apt-get install --no-install-recommends -y \
    libpq-dev \
    gettext \
    default-libmysqlclient-dev \
    nodejs \
    ffmpeg \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /var/lib/apt/lists/*

# 安装 Python 依赖
COPY --from=python-build /usr/src/app/wheels /wheels/
RUN pip install --no-cache-dir --no-index --find-links=/wheels/ /wheels/* \
    && rm -rf /wheels/

# 复制应用代码
COPY . ${APP_HOME}

# 构建前端静态文件
RUN cd web && npm install && npm run build && cd ..

# 数据库迁移 & 收集静态文件
RUN python manage.py migrate --run-syncdb || true
RUN python manage.py collectstatic --noinput || true

# 启动脚本
RUN echo '#!/bin/bash\n\
python manage.py migrate --run-syncdb\n\
gunicorn -w 2 -b 0.0.0.0:8002 django_vue_cli.wsgi:application --timeout 120 --worker-class=gevent\n\
' > /start && chmod +x /start

EXPOSE 8002

CMD ["/start"]
