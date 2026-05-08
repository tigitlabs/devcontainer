#!/bin/bash
cd $(dirname "$0")

source ../../../test/test-utils.sh  vscode

# Run common tests
checkCommon

check "Oh My Zsh! theme" test -e $HOME/.oh-my-zsh/custom/themes/devcontainers.zsh-theme
check "zsh theme symlink" test -e $HOME/.oh-my-zsh/custom/themes/codespaces.zsh-theme

check "git" git --version

git_version=$(git --version)
check-version-ge "git-requirement" "${git_version}" "git version 2.40.1"

check "set-git-config-user-name" sh -c "sudo git config --system user.name devcontainers"
check "gitconfig-file-location" sh -c "ls /etc/gitconfig"
check "gitconfig-contains-name" sh -c "cat /etc/gitconfig | grep 'name = devcontainers'"

check "usr-local-etc-config-does-not-exist" test ! -f "/usr/local/etc/gitconfig"

check "mise" mise --version
check "mise-install-location" test -x "$HOME/.local/bin/mise"
check "mise-on-path" sh -c '[ "$(command -v mise)" = "$HOME/.local/bin/mise" ]'
check "mise-data-dir" test -d "$HOME/.local/share/mise"
check "mise-config-dir" test -d "$HOME/.config/mise"
check "mise-cache-dir" test -d "$HOME/.cache/mise"

checkPythonExtension

# Report result
reportResults
