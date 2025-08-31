# ---- Base ----
FROM python:3.11-slim AS base
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates libpq5 libjpeg62-turbo libpng16-16 \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /app

# ---- Builder ----
FROM base AS builder
RUN python -m venv /opt/venv
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY backend/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
# sanity-check critical imports at build time
RUN python - << 'PY'
from google.oauth2 import id_token
from google.auth.transport import requests
print('google-auth import OK during build')
PY

# ---- Runtime ----
FROM base AS runtime
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY --from=builder /opt/venv /opt/venv

# copy code
COPY backend/app /app/app
COPY backend/alembic /app/alembic
COPY backend/alembic.ini /app/alembic.ini

EXPOSE 8000
HEALTHCHECK --interval=15s --timeout=5s --retries=10 CMD curl -fsS http://localhost:8000/healthz || exit 1
# be explicit: use the venv uvicorn
CMD ["/opt/venv/bin/uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
