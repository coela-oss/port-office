FROM python:3.11.7-slim-bookworm

ENV PATH=/root/.local/bin:$PATH
RUN apt-get update \
  && apt-get install -y \
  nodejs \
  npm \
  python3-venv \
  pipx \
  && apt-get clean \
  && pipx ensurepath
