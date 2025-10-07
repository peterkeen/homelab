FROM ghcr.io/astral-sh/uv:bookworm
ADD . /app
WORKDIR /app
RUN uv sync --frozen

ENV DATA_PATH=/data

CMD ["uv", "run", "fastapi", "run", "agent/server.py"]