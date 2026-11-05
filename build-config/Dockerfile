ARG RUNTIME_BASE=gcr.io/distroless/python3-debian12:latest

FROM python:3.11-slim AS builder
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libffi-dev \
    && rm -rf /var/lib/lists/*

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY build-config/requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

ARG RUNTIME_BASE
# Stage 2: Haredened Distorless Runtime
FROM ${RUNTIME_BASE} AS runtime
WORKDIR /app

COPY --from=builder /opt/venv /opt/venv
COPY ./app ./fhir-app

ENV PATH="/opt/venv/bin:$PATH"
ENV PYTHONPATH="/opt/venv/lib/python3.11/site-packages:/app"

EXPOSE 8000

ENTRYPOINT ["/opt/venv/bin/uvicorn", "fhir-app.main:app", "--host", "0.0.0.0", "--port", "8000"]
