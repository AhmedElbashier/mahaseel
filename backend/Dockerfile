# backend/Dockerfile

FROM python:3.11-slim AS base
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates libpq5 libjpeg62-turbo libpng16-16 \
  && rm -rf /var/lib/apt/lists/*

FROM base AS builder
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
WORKDIR /app

# was: COPY backend/requirements.txt ./requirements.txt
COPY requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

FROM base AS runtime
ENV PATH="/opt/venv/bin:$PATH"
WORKDIR /app

# app code & alembic files (no backend/ prefix)
COPY --from=builder /opt/venv /opt/venv
COPY app ./app
COPY alembic ./alembic
COPY alembic.ini ./alembic.ini

EXPOSE 8000
CMD bash -lc "alembic upgrade head && exec uvicorn app.main:app --host 0.0.0.0 --port 8000"
