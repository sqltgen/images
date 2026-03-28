FROM python:3.13-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends make libpq5 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Pre-install the union of all example dependencies into the system Python.
# This populates the pip wheel cache (~/.cache/pip) so per-project venv installs
# resolve packages locally instead of downloading them.
COPY requirements.txt .
RUN pip install --upgrade pip --quiet && \
    pip install -r requirements.txt --quiet
