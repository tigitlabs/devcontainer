#!/bin/bash
# .devcontainer/initializeCommand.sh
echo "🏗️ Initialize command"
# Check if the script is running on GitHub Codespaces
if [[ -n "${CODESPACES}" || -n "${GITHUB_CODESPACE_TOKEN}" ]]; then
    printf "Running in GitHub Codespaces.\nNo need to export any keys."
    exit 0
else
    echo "Running on local host"
    echo "Check if gh is installed"
    if ! command -v gh &>/dev/null; then
        echo "gh could not be found"
        exit 1
    else
        echo "gh is installed"
        gh --version
    fi

    echo "Check if gh is logged in"
    if ! gh auth status | grep -q "Logged in to github.com"; then
        echo "gh is not logged in"
        exit 1
    else
        echo "gh is logged in"
        gh auth status
    fi

    echo "Write environment variables to .devcontainer/.env file"
    echo "GITHUB_TOKEN=$(gh config get oauth_token --host github.com)" >.devcontainer/.env
    echo "GITHUB_USER=$(gh api user | jq -r '.login')" >>.devcontainer/.env

    if [ -z "$SSH_AUTH_SOCK" ]; then
        echo "SSH_AUTH_SOCK is not set"
        echo "⚠️ SSH authentication to github.com will not work"
        echo "https://code.visualstudio.com/remote/advancedcontainers/sharing-git-credentials#_using-ssh-keys"
    fi
fi
