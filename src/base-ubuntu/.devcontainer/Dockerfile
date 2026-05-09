# [Choice] Ubuntu version (use jammy on local arm64/Apple Silicon): jammy, focal
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

ARG VARIANT="${VARIANT}"
ARG BASE_IMAGE=mcr.microsoft.com/devcontainers/base:ubuntu-24.04
ENV BASE_IMAGE="${BASE_IMAGE}"

LABEL dev.containers.features="common"
LABEL dev.containers.base_image="${BASE_IMAGE}"

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    make \
    bash-completion \
    age \
    ripgrep \
    # Clean up
    && apt-get autoremove -y && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Install mise
USER vscode

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# ENV MISE_VERSION="..."
ENV MISE_BIN_DIR="/home/vscode/.local/bin"
ENV MISE_INSTALL_PATH="/home/vscode/.local/bin/mise"
ENV MISE_DATA_DIR="/home/vscode/.local/share/mise"
ENV MISE_CONFIG_DIR="/home/vscode/.config/mise"
ENV MISE_CACHE_DIR="/home/vscode/.cache/mise"

ENV PATH="${MISE_BIN_DIR}:${MISE_DATA_DIR}/shims:${PATH}"

RUN mkdir -p \
    "${MISE_BIN_DIR}" \
    "${MISE_DATA_DIR}" \
    "${MISE_CONFIG_DIR}" \
    "${MISE_CACHE_DIR}" \
    && curl https://mise.run | sh

# hadolint ignore=DL3002
USER root
