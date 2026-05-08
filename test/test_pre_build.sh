#!/bin/bash
# Running the pre_build.sh script with different parameters
# to make sure that the script is working as expected.

# DEFINES
BASE_IMAGE_FOR_BASE_UBUNTU="buildpack-deps:22.04-curl"

script_dir="$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1
absolute_root_dir="$(cd "${script_dir}/.." && pwd)"
build_script="${absolute_root_dir}/test/pre_build.sh"

function check_label() {
    local image="$1"
    local label="$2"
    local expected_value="$3"
    local actual_value
    echo "🧪 Checking label ${label} for image ${image}"
    actual_value=$(docker inspect "${image}" | jq -r ".[0].Config.Labels.\"${label}\"")
    if [[ "${actual_value}" != "${expected_value}" ]]; then
        echo "❌ Expected label ${label} to be ${expected_value}, but got ${actual_value}"
        exit 1
    else
        echo "✅ Label check passed"
    fi

}

function run_build() {
    local image="${1}"
    local tag="${2:-local}"
    local base_image="${3:-}"
    local result
    local image_size
    local image_size_tag='(*) Image size - '
    echo "🏃 Running build for image ${image}:${tag} and base image ${base_image}:${tag}"

    result=$("${build_script}" "${image}" "${tag}" "${base_image}" 2>&1)

    image_size=$(echo "${result}" | grep -F "${image_size_tag}")
    if [[ -z "${image_size}" ]]; then
        echo "❌ Build failed"
        echo "${result}"
        exit 1
    fi
}

echo "⚒️⚒️⚒️ Test build base-ubuntu"
echo "⚒️ Test build base-ubuntu with no arguments"
run_build "base-ubuntu"
check_label "base-ubuntu:local" "dev.containers.base_image" "${BASE_IMAGE_FOR_BASE_UBUNTU}"
# This is needed for the next tests
run_build "base-ubuntu" "test"
check_label "base-ubuntu:test" "dev.containers.base_image" "${BASE_IMAGE_FOR_BASE_UBUNTU}"
