FROM python:3.12-slim AS deps

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
      gcc \
      libpq-dev \
    && rm -rf /var/lib/apt/lists/*

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"


RUN pip install --no-cache-dir --upgrade pip \
 && pip install --no-cache-dir \
      fastapi==0.115.8 \
      uvicorn==0.34.0 \
      sqlalchemy==2.0.37 \
      psycopg-binary==3.2.4 \
      psycopg==3.2.4

FROM deps AS test

RUN pip install --no-cache-dir \
      pytest>=6.2.5 \
      pytest-asyncio==0.25.3 \
      httpx==0.28.1

WORKDIR /app
ENV PYTHONPATH=/app
COPY src ./src
COPY tests ./tests

CMD ["pytest", "-q", "tests"]

FROM python:3.12-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
      libpq5 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=deps /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY src ./src

EXPOSE 8000

CMD ["sh", "-c", "uvicorn src.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
