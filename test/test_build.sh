#!/bin/bash
## Run tests on pre-built devcontainer images
IMAGE="$1"
IMAGE_TAG="$2"

set -e

# Check if devcontainer cli is available
# This should not happen as the container is built with devcontainer cli
if ! command -v devcontainer &>/dev/null; then
    echo "🚫 devcontainer cli not found"
    exit 1
fi

script_dir="$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1
absolute_root_dir="$(cd "${script_dir}/.." && pwd)"
echo "absolute_root_dir: ${absolute_root_dir}"
echo "script_dir: ${script_dir}"
image_name="${IMAGE}:${IMAGE_TAG}"
id_label="dev.containers.name=${IMAGE}"

# Run and test container
echo "(*) Run and Test container - ${image_name}:${IMAGE_TAG}"

docker rm --force "${IMAGE}" || true
docker run \
    --sig-proxy=false \
    --name "${IMAGE}" \
    --detach \
    --mount type=bind,source="${absolute_root_dir}",target=/workspaces/devcontainer \
    --label "${id_label}" \
    --entrypoint /bin/sh "${image_name}" -c 'trap "exit 0" 15; exec "$@"; while sleep 1 & wait $!; do :; done'

container_id=$(docker ps -aqf "name=${IMAGE}")
echo "container_id: ${container_id}"

echo "(*) Set-up devcontainer - ${IMAGE}"
devcontainer set-up --container-id "${container_id}" --config "src/${IMAGE}/.devcontainer/devcontainer.json"
echo "(*) Run devcontainer up - ${IMAGE}"
devcontainer up --id-label "${id_label}" --workspace-folder "src/${IMAGE}/" --expect-existing-container

# # Run actual test
echo "(*) Running test..."
# shellcheck disable=SC2016
devcontainer exec \
    --workspace-folder "src/${IMAGE}/" \
    --id-label "${id_label}" \
    /bin/sh -c 'set -e && if [ -f "test-project/test.sh" ]; then cd test-project && if [ "$(id -u)" = "0" ]; then chmod +x test.sh; else sudo chmod +x test.sh; fi && ./test.sh; else ls -a; fi'

# # Clean up
mapfile -t container_ids < <(docker container ls -f "label=${id_label}" -q)
if ((${#container_ids[@]} > 0)); then
    docker rm -f "${container_ids[@]}"
fi
