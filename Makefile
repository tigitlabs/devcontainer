.DEFAULT_GOAL:=help
SHELL:=/bin/bash

# --------------------------
.PHONY: help
help:       	## Show this help.
	@echo "Convinient make targets for development and testing"
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Github Actions - ACT

.PHONY: github-action-list
github-action-list:	## ✅List Workflows
	@echo "📋 List Push Workflows"
	@for workflow in .github/workflows/*.yml .github/workflows/*.yaml; do \
		if grep -Eq '^[[:space:]]*push:' "$$workflow"; then \
			echo "$$workflow"; \
		fi; \
	done
	@echo "📋 List Pull Request Workflows"
	@for workflow in .github/workflows/*.yml .github/workflows/*.yaml; do \
		if grep -Eq '^[[:space:]]*pull_request:' "$$workflow"; then \
			echo "$$workflow"; \
		fi; \
	done

.PHONY: github-action-act-test
github-action-act-test:	## ✅Run act-test
	GITHUB_TOKEN=${GITHUB_TOKEN} && ./.github/workflows/act/act-tests.sh

.PHONY: github-action-smoke-base-ubuntu
github-action-smoke-base-ubuntu:	## ✅Run smoke-test for base-ubuntu
	@act -W .github/workflows/smoke-base-ubuntu.yaml \
	--secret GITHUB_TOKEN=${GITHUB_TOKEN}

.PHONY: github-action-smoke-test
github-action-smoke-test:	## ✅Run smoke-test for the current image set
	make github-action-smoke-base-ubuntu

.PHONY: github-action-makefile-ci
github-action-makefile-ci:	## ✅Run makefile-ci
	act -W .github/workflows/makefile-ci.yml \
	--secret GITHUB_TOKEN=${GITHUB_TOKEN}

.PHONY: github-action-markdown-lint
github-action-markdown-lint:	## ✅Run markdown-lint
	act -W .github/workflows/docs.yml \
	--secret GITHUB_TOKEN=${GITHUB_TOKEN}

.PHONY: github-action-publish
github-action-publish:	## ✅Build and publish all images
	act -W .github/workflows/publish.yml \
	-s GITHUB_TOKEN="${GITHUB_TOKEN}" \
	--eventpath .github/workflows/act/event-publish-main.json


##@ 🐋 devcontainer Build & Test

.PHONY: build-base-ubuntu
build-base-ubuntu:	## 🏗️Build ubuntu-base image
	@echo "🏗️ Building base-ubuntu image"
	./test/pre_build.sh base-ubuntu local

.PHONY: test-base-ubuntu
test-base-ubuntu:	## 🧪Test base-ubuntu image
	@echo "🧪 Testing base-ubuntu image"
	./test/test_build.sh base-ubuntu local

.PHONY: build-all
build-all:	## 🏗️Build the current image set
	@echo "🏗️ Building all images"
	@make build-base-ubuntu

.PHONY: test-all
test-all:	## 🧪Test the current image set
	@echo "🧪 Testing all images"
	@make test-base-ubuntu

##@ 🐋 devcontainer attach

.PHONY: attach-base-ubuntu
attach-base-ubuntu:	## bring up base-ubuntu container and attach shell
	@echo "🐋 Bring-up base-ubuntu container"
	@export VARIANT=dev && \
	devcontainer up \
	--workspace-folder src/base-ubuntu \
	--remove-existing-container \
	--id-label debug-container=base-ubuntu
	devcontainer exec --id-label debug-container=base-ubuntu /bin/bash

.PHONY: makefile-ci
makefile-ci:	## 🧪 Run all makefile targets
	@make help
	@make github-action-list
	@make github-action-act-test
	@make github-action-smoke-test
	@make github-action-markdown-lint
	@make github-action-makefile-ci
	@make build-all
	@make test-all
	./test/test_pre_build.sh
