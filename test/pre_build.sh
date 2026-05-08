#!/bin/bash
# IMAGE: The name of the Docker image to be built.
# IMAGE_TAG: The tag to be applied to the Docker image.
# BASE_IMAGE_NAME: The base Docker image to be used for building the new image.
# # If not provided, the default image will be used.
IMAGE="$1"
IMAGE_TAG="$2"
BASE_IMAGE_NAME="$3"
set -e
export DOCKER_BUILDKIT=1

# Install devcontainer cli if not already installed
# Thats the case when running on GitHub Actions Runner
if ! command -v devcontainer &> /dev/null; then
    if command -v npm &> /dev/null; then
        if ! command -v node &> /dev/null; then
            echo "🚫 node is required to install @devcontainers/cli"
            exit 1
        fi

        node_major=$(node -p 'process.versions.node.split(".")[0]')
        if (( node_major < 20 )); then
            echo "🚫 Node.js 20 or newer is required to install @devcontainers/cli"
            echo "   Current version: $(node --version)"
            exit 1
        fi

        echo "(*) Installing @devcontainer/cli"
        if ! npm install -g @devcontainers/cli; then
            if command -v sudo &> /dev/null; then
                sudo npm install -g @devcontainers/cli
            else
                echo "🚫 Unable to install @devcontainers/cli globally"
                echo "   Retry with a user that can write global npm packages or preinstall the CLI"
                exit 1
            fi
        fi
    else
        echo "🚫 devcontainer cli not found and npm is not available to install it"
        echo "   Install Node.js/npm or preinstall @devcontainers/cli before running local builds"
        exit 1
    fi
else
    echo "(*) @devcontainer/cli already installed"
fi

if [[ -z "${BASE_IMAGE_NAME}" ]]; then
    echo "⚠️  No base image provided, using default"
else
    export BASE_IMAGE="${BASE_IMAGE_NAME}"
    echo "(*) Using base image - ${BASE_IMAGE}"
fi

if [[ -z "${IMAGE_TAG}" ]]; then
    echo "⚠️  No image tag provided"
    echo "⚠️  Using default image tag - local"
    TAG="local"
else
    export TAG="${IMAGE_TAG}"
    echo "(*) Using image tag - ${TAG}"
fi

image_name="${IMAGE}:${TAG}"
id_label=" dev.containers.name=${IMAGE}"

echo "(*) Building image - ${image_name}"

devcontainer build --workspace-folder "src/${IMAGE}/" --image-name "${image_name}"
image_id=$(docker images --format "{{.Repository}}:{{.Tag}} {{.ID}}" | grep ${image_name} | awk '{print $2}')
image_size=$(docker images --format "{{.Repository}}:{{.Tag}} {{.Size}}" | grep ${image_name} | awk '{print $2}')
echo "(*) Image size - ${image_size}"
echo "(*) Image id - ${image_id}"
