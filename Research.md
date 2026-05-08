# Research

- `devcontainers/template-starter`
  - Repo: [https://github.com/devcontainers/template-starter](https://github.com/devcontainers/template-starter)
  - Local submodule: `external/template-starter`
  - Purpose: starter repository for authoring and publishing your own Dev Container Template collection.
  - What it is useful for:
    - Shows the expected repository shape for a template collection.
    - Demonstrates minimal, self-authored templates that are easy to understand end to end.
    - Includes example GitHub Actions for testing, release, and docs generation.
  - What to learn from it:
    - How to structure `src/<template>` with `devcontainer-template.json` and `.devcontainer/devcontainer.json`.
    - How template options are declared and exposed to tools.
    - How per-template tests are organized under `test/<template>/test.sh`.
    - How template versioning and GHCR publishing are wired for distribution.
    - How to keep generated docs and release automation tied to the template metadata.
  - Best-practice signals to reuse here:
    - Keep each template self-contained and predictable.
    - Mirror template folders with matching tests.
    - Treat publishing, smoke testing, and docs generation as part of the template lifecycle.

- `devcontainers/templates`
  - Repo: [https://github.com/devcontainers/templates](https://github.com/devcontainers/templates)
  - Local submodule: `external/templates`
  - Purpose: the main public collection of maintained Dev Container Templates used by tools like VS Code and GitHub Codespaces.
  - What it is useful for:
    - Reference implementation for production-grade template organization.
    - Broad catalog of real templates across languages, runtimes, and workflows.
    - Examples of how maintained templates balance reuse, customization, testing, and discoverability.
  - What to learn from it:
    - How a larger template catalog is organized under `src/` with matching tests under `test/`.
    - How templates are designed for use in both new and existing projects.
    - How template inputs, defaults, and optional features are presented to users.
    - How the templates align with the Dev Container spec and supporting tools.
    - How a mature repo handles contribution flow, CI, and compatibility expectations.
  - Best-practice signals to reuse here:
    - Maintain a clean one-template-per-folder layout.
    - Keep test coverage close to each template surface.
    - Prefer documented, composable defaults over one-off project-specific setup.
    - Design templates so they are easy to apply, inspect, and extend.

- `devcontainers/images`
  - Repo: [https://github.com/devcontainers/images](https://github.com/devcontainers/images)
  - Local submodule: `external/images`
  - Purpose: the maintained set of reusable base development container images
    that templates and devcontainer configurations can build on.
  - What it is useful for:
    - Reference implementation for base image design and maintenance.
    - Shows how reusable images differ from higher-level templates.
    - Demonstrates practical Dockerfile and layering conventions for dev containers.
  - What to learn from it:
    - How reusable dev container images are organized under `src/`.
    - How images are meant to be consumed by `devcontainer.json`, Dockerfiles, or derived setups.
    - How image authors optimize Dockerfile layers, cleanup, and package installation.
    - How images relate to Dev Container Features and the broader spec.
    - Where the boundary should sit between a reusable image, a feature, and a template.
  - Best-practice signals to reuse here:
    - Keep image responsibilities narrow and composable.
    - Use efficient Dockerfile layering and cleanup in the same `RUN` step where possible.
    - Separate reusable base environment concerns from project-specific template concerns.
    - Prefer extending shared images over duplicating common runtime setup.

## How to use these references in this repo

- Use `external/template-starter` when defining the baseline authoring pattern for new templates in this repository.
- Use `external/templates` when comparing our structure against a larger, production-maintained catalog.
- Use `external/images` when deciding what should become a reusable base image
  versus what should stay in a template or project config.
- Borrow structure and workflow ideas, but avoid copying unnecessary complexity until this repo needs it.
- Compare our `src/` and `test/` layout against the template references,
  and compare any shared runtime setup against the images reference.

## Decision rules

- Use a custom image when the goal is a reusable environment that many projects can pull directly.
- Use a template when the goal is to generate or apply `.devcontainer` configuration into a project repository.
- Use an image for stable toolchains and heavy shared dependencies that should not be rebuilt per project.
- Use a template for project bootstrapping, opinionated defaults, and wiring a
  project to an image, features, mounts, or editor settings.
- Use Features when a concern is modular and optional, and you may want to
  Compose it differently across projects.

## Recommended approach for this repo

- Primary path: build and publish a small hierarchy of custom base images.
- Suggested image stack:
  - `base`: your default shell, CLI tools, editors, git tooling, and other personal baseline utilities.
  - `python`: extends `base` with Python runtime, packaging tools, linters,
    and common data or app dependencies.
  - `fw-dev`: extends `base` with firmware and embedded toolchains, debug tools, and device-specific utilities.
- Optional next layer: add lightweight templates that reference those published images for fast project onboarding.
- Keep templates thin. Their job should be selecting the right image and adding
  project-specific `devcontainer.json` defaults, not rebuilding your whole
  environment.

## Practical recommendation

- If your main goal is "I want images I can pull for different kinds of
  projects", the image approach is the right foundation.
- The `devcontainers/images` repo is the better reference for structure, layering, Dockerfile discipline, and publishing patterns.
- The template repos are still useful, but as a second step after the image strategy is in place.
- Do not start by forcing everything into templates. Templates are not a replacement for a reusable published image catalog.

## What templates are for

- A template is a reusable starter package that writes dev container files into a project.
- It helps a user say "set this repo up as a Python dev container" or "apply this firmware dev environment scaffold".
- A template can reference a published image, a Dockerfile, or additional Features.
- Templates are best when multiple repositories need the same onboarding flow,
  not when the main asset is the built environment itself.

## Pipeline guidance

- Start with a simple custom image publishing pipeline in this repository.
- Reuse ideas from `external/images`, but do not copy the whole upstream
  maintenance model unless you actually need that scale.
- Keep the first pipeline narrow: build, smoke test, tag, and publish `base`, `python`, and `fw-dev`.
- After the images stabilize, add one or two templates only if you want easy project bootstrap for consumers.

## Overhaul focus

- Standardize template layout and naming.
- Clarify image-level responsibilities versus template-level responsibilities.
- Mirror every template with a predictable test location.
- Keep metadata, docs, and tests aligned.
- Add automation only where it supports repeatable validation or publishing.
