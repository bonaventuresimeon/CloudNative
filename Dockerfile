<<<<<<< HEAD
# Use the latest stable Python Alpine image (lightweight)
FROM python:3.13-alpine

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set working directory
WORKDIR /app

# Install system dependencies for building Python packages
RUN apk update && apk add --no-cache \
����build-base \
����gcc \
����libffi-dev \
����musl-dev \
����openssl-dev \
����&& pip install --upgrade pip

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Expose FastAPI port
EXPOSE 8000

# Start FastAPI app using uvicorn
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
=======
# syntax=docker/dockerfile:1
FROM python:3.11-slim AS build
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip setuptools wheel \
 && pip install -r requirements.txt
RUN ls -d /usr/local/lib/python3.11/site-packages

COPY app/ ./app
COPY templates/ ./templates

FROM python:3.11-slim AS runtime
WORKDIR /app
# install only runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends libpq5 && rm -rf /var/lib/apt/lists/*

COPY --from=build /usr/local/lib/python3.11/site-packages/ /usr/local/lib/python3.11/site-packages/
COPY --from=build /app /app

EXPOSE 8011
USER appuser:appgroup

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8011"]
>>>>>>> d2e5c83 (Initial push or update)
