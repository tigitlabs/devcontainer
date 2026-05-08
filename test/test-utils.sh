#!/bin/bash
SCRIPT_FOLDER="$(cd "$(dirname "$0")" && pwd)"
USERNAME=${1:-vscode}

if [[ -z "$HOME" ]]; then
    HOME="/root"
fi

FAILED=()

echoStderr() {
    echo "$@" 1>&2
}

check() {
    LABEL=$1
    shift
    echo -e "\n🧪 Testing $LABEL"
    if "$@"; then
        echo "✅  Passed!"
        return 0
    else
        echoStderr "❌ $LABEL check failed."
        FAILED+=("$LABEL")
        return 1
    fi
}

check_file_exists() {
    LABEL=$1
    FILE_PATH=$2
    echo -e "\n🧪 Checking if file $LABEL exists at $FILE_PATH"
    if [ -f "$FILE_PATH" ]; then
        echo "✅  File exists!"
        return 0
    else
        echoStderr "❌ File $LABEL does not exist at $FILE_PATH."
        FAILED+=("$LABEL")
        return 1
    fi
}

check-version-ge() {
    LABEL=$1
    CURRENT_VERSION=$2
    REQUIRED_VERSION=$3
    local greater_version
    echo -e "\n🧪 Testing $LABEL: '$CURRENT_VERSION' is >= '$REQUIRED_VERSION'"
    greater_version="$(printf '%s\n%s\n' "${CURRENT_VERSION}" "${REQUIRED_VERSION}" | sort -V | tail -1)"
    if [[ "${CURRENT_VERSION}" == "${greater_version}" ]]; then
        echo "✅  Passed!"
        return 0
    else
        echoStderr "❌ $LABEL check failed."
        FAILED+=("$LABEL")
        return 1
    fi
}

checkMultiple() {
    PASSED=0
    LABEL="$1"
    echo -e "\n🧪 Testing $LABEL."
    shift
    MINIMUMPASSED=$1
    shift
    EXPRESSION="$1"
    while [ "$EXPRESSION" != "" ]; do
        if $EXPRESSION; then ((PASSED++)); fi
        shift
        EXPRESSION=$1
    done
    if [[ $PASSED -ge "$MINIMUMPASSED" ]]; then
        echo "✅ Passed!"
        return 0
    else
        echoStderr "❌ $LABEL check failed."
        FAILED+=("$LABEL")
        return 1
    fi
}

checkOSPackages() {
    LABEL=$1
    shift
    echo -e "\n🧪 Testing $LABEL"
    if dpkg-query --show -f='${Package}: ${Version}\n' "$@"; then
        echo "✅  Passed!"
        return 0
    else
        echoStderr "❌ $LABEL check failed."
        FAILED+=("$LABEL")
        return 1
    fi
}

checkExtension() {
    # Happens asynchronusly, so keep retrying 10 times with an increasing delay
    EXTN_ID="$1"
    TIMEOUT_SECONDS="${2:-10}"
    RETRY_COUNT=0
    echo -e -n "\n🧪 Looking for extension $1 for maximum of ${TIMEOUT_SECONDS}s"
    until [[ "${RETRY_COUNT}" -eq "${TIMEOUT_SECONDS}" ]]; do
        if compgen -G "$HOME/.vscode-server/extensions/${EXTN_ID}*" >/dev/null ||
            compgen -G "$HOME/.vscode-server-insiders/extensions/${EXTN_ID}*" >/dev/null ||
            compgen -G "$HOME/.vscode-test-server/extensions/${EXTN_ID}*" >/dev/null ||
            compgen -G "$HOME/.vscode-remote/extensions/${EXTN_ID}*" >/dev/null; then
            echo -e "\n✅ Passed!"
            return 0
        fi
        sleep 1s
        ((RETRY_COUNT++))
        echo -n "."
    done

    echoStderr -e "\n❌ Extension $EXTN_ID not found."
    FAILED+=("$EXTN_ID")
    return 1
}

runNrfCommand() {
    echo -e "\n🏃 Running in nrf toolchain: $*"
    nrfutil toolchain-manager launch -- /usr/local/bin/entry.sh "$@"
}

checkNrfCommand() {
    LABEL=$1
    shift
    echo -e "\n🧪 Testing nrf command $LABEL"
    if runNrfCommand "$@"; then
        echo "✅  Passed!"
        return 0
    else
        echoStderr "❌ $LABEL check failed."
        FAILED+=("$LABEL")
        return 1
    fi
}

checkCommon() {
    local -a package_list=(
        apt-utils
        openssh-client
        less
        iproute2
        procps
        curl
        wget
        unzip
        nano
        jq
        lsb-release
        ca-certificates
        apt-transport-https
        dialog
        gnupg2
        libc6
        libgcc1
        libgssapi-krb5-2
        liblttng-ust1
        libstdc++6
        zlib1g
        locales
        age
        ripgrep
        sudo
    )

    # Actual tests
    checkOSPackages "common-os-packages" "${package_list[@]}"
    check "non-root-user" id "${USERNAME}"
    check "locale" bash -lc 'locale -a | grep -q "^en_US\.utf8$"'
    check "sudo" sudo echo "sudo works."
    check "zsh" zsh --version
    check "oh-my-zsh" [ -d "$HOME/.oh-my-zsh" ]
    check "login-shell-path" [ -f "/etc/profile.d/00-restore-env.sh" ]
    check "code" which code
}

checkPythonExtension() {
    # Definition specific tests
    check "version" python --version
    check "pip is installed" pip --version
    check "pip is installed" pip3 --version

    # Check that tools can execute
    check "autopep8" autopep8 --version
    check "black" black --version
    check "yapf" yapf --version
    check "bandit" bandit --version
    check "flake8" flake8 --version
    check "mypy" mypy --version
    check "pycodestyle" pycodestyle --version
    check "pydocstyle" pydocstyle --version
    check "pylint" pylint --version
    check "pytest" pytest --version
}

checkNordicTools() {
    # check "nrfutil" nrfutil toolchain-manager launch /bin/bash
    checkNrfCommand "cmake" cmake --version
    checkNrfCommand "clang-format" clang-format --version
    checkNrfCommand "west" west --version
    check "nrfutil" nrfutil --version
    check "nrfutil toolchain" nrfutil toolchain-manager list
    nrf_toolchain_version=$(nrfutil toolchain-manager list | grep -oP 'v\d+\.\d+\.\d+' | awk '{print $1}')
    check-version-ge "nrf toolchain version" "${nrf_toolchain_version}" "v2.5.0"
}

runBuildTests() {
    nrf_toolchain_version=$(nrfutil toolchain-manager list | grep -oP 'v\d+\.\d+\.\d+' | awk '{print $1}')
    sdk_dir=$HOME/ncs/${nrf_toolchain_version}
    cd "${sdk_dir}" || exit
    echo -e "\n🧪 Testing west update"
    west update
    echo -e "\n🧪 Testing west build"
    cd ./nrf/applications/asset_tracker_v2 || exit
    nrfutil toolchain-manager launch /bin/bash -- -c 'west build -b nrf9160dk_nrf9160ns --build-dir ./build'
    # Check if the build was successful
    check_file_exists "merged.hex" build/zephyr/merged.hex
}

reportResults() {
    if [ ${#FAILED[@]} -ne 0 ]; then
        echoStderr -e "\n💥  Failed tests: ${FAILED[*]}"
        exit 1
    else
        echo -e "\n💯  All passed!"
        exit 0
    fi
}

fixTestProjectFolderPrivs() {
    if [ "${USERNAME}" != "root" ]; then
        TEST_PROJECT_FOLDER="${1:-$SCRIPT_FOLDER}"
        FOLDER_USER="$(stat -c '%U' "${TEST_PROJECT_FOLDER}")"
        if [ "${FOLDER_USER}" != "${USERNAME}" ]; then
            echoStderr "WARNING: Test project folder is owned by ${FOLDER_USER}. Updating to ${USERNAME}."
            sudo chown -R "${USERNAME}" "${TEST_PROJECT_FOLDER}"
        fi
    fi
}
