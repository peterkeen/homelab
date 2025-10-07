FROM ghcr.io/astral-sh/uv:bookworm

ENV DATA_PATH=/data

WORKDIR /app

ADD uv.lock /app
ADD pyproject.toml /app
ADD .python-version /app

RUN uv sync --frozen

ADD . /app

CMD ["uv", "run", "fastapi", "run", "agent/server.py"]