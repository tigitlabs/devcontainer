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
   Builds and tests the base image in CI, and publishes it to GitHub Container Registry on branch or tag pushes.
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
   act push \
   --workflows .github/workflows/publish.yml \
   --eventpath .github/workflows/act/event-push-commit.json \
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

Current focus is a single published base image. Additional project-specific images will be added later on top of this foundation.

## Build and publish flow

- Pull requests to `dev` or `main` build and test `base-ubuntu` but do not publish.
- Pushes to `dev` and `main` build, test, and publish branch tags plus a `sha-<commit>` tag.
- Pushes to `main` also publish `latest`.
- Semver tags like `v1.2.3` publish `v1.2.3`, `v1.2`, `v1`, `latest`, and `sha-<commit>`.

## Local build and test

Local builds require either a preinstalled `devcontainer` CLI or Node.js 20+
with `npm` so the helper script can install `@devcontainers/cli`.

```bash
make build-base-ubuntu
make test-base-ubuntu
```

## Pre-commit

The development container already installs the `pre-commit` tool. The repository
now also includes a pinned `.pre-commit-config.yaml` for the file types that are
actually maintained here: shell scripts, Dockerfiles, GitHub Actions workflows,
YAML/JSON, and Markdown.

If you are not using the devcontainer, install `pre-commit` locally and then run:

```bash
pre-commit install --install-hooks
pre-commit run --all-files
```

When you open the repo in the devcontainer, `.devcontainer/postCreateCommand.sh`
installs the git hook automatically.

## Using the published image

Example `.devcontainer/devcontainer.json` using the published image directly:

```json
{
   "image": "ghcr.io/tigitlabs/devcontainer/base-ubuntu:main",
   "features": {
      "ghcr.io/devcontainers/features/common-utils:2": {
         "installZsh": "false",
         "username": "vscode"
      }
   }
}
```
