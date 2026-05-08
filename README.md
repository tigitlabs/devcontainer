# devcontainer

Repo to maintain and pre-build devcontainer images.
The images can be used locally or on Github via Codespaces.

## Tools

### Github Actions

Best starting point to adapt the repository to your needs is by understanding the Workflow files.

#### Workflows

- act.yml
  - act/event-**  
    Event json files for local testing with act
  - act/act-tests.sh  
      Test script to help during the development of Workflows/Jobs
- debug.yml  
   Prints debug information of the event that triggered the Workflow run. Also dumbs the the github.event object as a json.
   This outputs can be used to debug Workflows locally by adding this outputs as event files.
- docs.yml  
   Markdown linting
- makefile-ci.yml
- publish.yml  
   Publishes the devcontainer images to the Github Container Registry
- smoke-***
   Smoke tests for the devcontainer images

### ACT

Used to run Github Actions locally.
github.com/nectos/act

#### Event files

The event files are used to simulate a Github event.
The event files are located in the `.github/workflows/act` folder.
Example usage:

```bash
   act create \
   --workflows .github/workflows/publish.yml \
   --eventpath .github/workflows/act/event-create-tag.json \
   --dryrun
```

> ⚠️ **TODO**
>
> You have to run the act commands in the vscode terminal. When a shell is opened via SSH the act commands will fail.  
> This is due to the fact that the environment variables are not set.
> [Shell integration](https://code.visualstudio.com/docs/terminal/shell-integration)

### tmate

This enables SSH access to a Github Actions runner.
<https://dev.to/github/debug-your-github-actions-via-ssh-by-using-tmate-1hd6>

## Images

### base-ubuntu

Used as the base image for all other devcontainers.

## base-nrf

Build on top of base-ubuntu.
Only used as a base for nrf-ci and nrf-devcontainer builds
Only tools to build nrf connect SDK examples based on Zephyr are installed.

<https://devzone.nordicsemi.com/guides/nrf-connect-sdk-guides/b/getting-started/posts/build-ncs-application-firmware-images-using-docker>

## nrf-codespace

Based on this [repo from Nordic](https://github.com/NordicPlayground/nrf-docker)

## Setup for Host Machine

Requirements are that you have the Github CLI installed and the client is authenticated.
If you are using SSH Keys to perform git actions, check the SSH Agent sections.

### SSH Agent

(Documentation)<https://code.visualstudio.com/remote/advancedcontainers/sharing-git-credentials>

This is only required if you want to use SSH to authenticate with Github.
If you are using HTTPS, then you can skip this section.

When creating the devcontainer, and you want to use the ssh agent forwarding,
for Github, you need to add the following to your `~/.ssh/config` file:

```bash
# Github
Host github.com
  HostName github.com
  PreferredAuthentications publickey
  User git
  AddKeysToAgent yes
  IdentityFile ~/.ssh/id_rsa
  ForwardAgent yes
```

In your `~/.bashrc` file add the following:

```bash
# SSH Agent
# https://code.visualstudio.com/remote/advancedcontainers/sharing-git-credentials
if [ -z "$SSH_AUTH_SOCK" ]; then
   # Check for a currently running instance of the agent
   RUNNING_AGENT="`ps -ax | grep 'ssh-agent -s' | grep -v grep | wc -l | tr -d '[:space:]'`"
   if [ "$RUNNING_AGENT" = "0" ]; then
        # Launch a new instance of the agent
        ssh-agent -s &> $HOME/.ssh/ssh-agent
   fi
   eval `cat $HOME/.ssh/ssh-agent`
fi
```
