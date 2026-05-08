# Note: You can use any Debian/Ubuntu based image you want.
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    bash-completion \
    pipx \
    # Clean up
    && apt-get autoremove -y && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

RUN pipx install pre-commit==4.6.0
