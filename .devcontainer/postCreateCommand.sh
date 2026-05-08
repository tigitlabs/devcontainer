#!/bin/bash
# .devcontainer/postCreateCommand.sh
echo "🏗️ Post start command"

if command -v pre-commit &>/dev/null; then
    echo "🔧 Install pre-commit hooks"
    pre-commit install --install-hooks
fi

# Check if the script is running on GitHub Codespaces
if [[ -n "${CODESPACES}" || -n "${GITHUB_CODESPACE_TOKEN}" ]]; then
    printf "Running in GitHub Codespaces.\nNo need to run any commands."
    exit 0
else
    ENV_FILE=".devcontainer/.env"
    echo "Running on local host"
    echo "Load environment variables from ${ENV_FILE}"
    if [ -f "$ENV_FILE" ]; then
        # Get absolute path of .env file
        ENV_FILE=$(realpath "${ENV_FILE}")
        # Add loading of variables to ~/.bashrc
        echo "Add env file ${ENV_FILE} to ~/.bashrc"
        {
            echo "### Load env variables"
            echo "# Added from postStartCommand.sh"
            echo "set -o allexport"
            echo "source ${ENV_FILE}"
            echo "set +o allexport"
            echo "### Load env variables"
        } >>~/.bashrc
    else
        echo "$ENV_FILE does not exist."
        exit 1
    fi
fi
