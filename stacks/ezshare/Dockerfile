FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim

# Install the project into `/app`
WORKDIR /app

COPY . .

RUN uv sync --frozen --no-dev

CMD ["uv", "run", "python", "hello.py"]