#!/bin/bash
# .devcontainer/postStartCommand.sh
echo "🏗️ Post create command"
# Check if the script is running on GitHub Codespaces
if [[ -n "${CODESPACES}" || -n "${GITHUB_CODESPACE_TOKEN}" ]]; then
    printf "Running in GitHub Codespaces.\nNo need to run any commands."
    exit 0
else
    echo "Running on local host"
    env_file=".devcontainer/.env"
    if [[ ! -f "${env_file}" ]]; then
        echo "${env_file} does not exist."
        exit 1
    fi
    set -o allexport
    # shellcheck disable=SC1091
    source .devcontainer/.env
    set +o allexport
    echo "🧪 Login status for github cli"
    gh auth status
    echo "🧪 Login docker to ghcr.io for: ${GITHUB_USER}"
    printf '%s\n' "${GITHUB_TOKEN}" | docker login ghcr.io -u "${GITHUB_USER}" --password-stdin
    echo "🧪 Check github access via SSH"
    # Add github.com to known_hosts
    ssh-keyscan github.com >>~/.ssh/known_hosts
    ssh -T git@github.com
fi
