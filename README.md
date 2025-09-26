# github-runner-starter

<img width="1798" height="1612" alt="image" src="https://github.com/user-attachments/assets/63705306-b13c-4bfe-b5c3-91ab26a7b20a" />

A single Bash script to install, configure, optionally launch, and clean up GitHub self-hosted runners. It automates:
- Downloading the proper Actions Runner build for your OS/arch
- Getting a registration token via the GitHub API
- Configuring the runner with your repository, name, and labels
- Optionally launching `run.sh` and handling cleanup on exit

This project also includes a minimal Docker setup for local testing and examples.

## Features
- One-command setup for a self-hosted runner
- Works with environment variables or CLI flags (or a `.env` file)
- Automatically detects architecture (x64/arm64) and latest runner release
- Graceful stop/cancel handlers that can remove the runner and unregister it
- Optional Docker compose example for running/scaling multiple runners

## Requirements
- Bash, curl, tar
- jq (used to parse GitHub API responses)
- Network access to GitHub
- A GitHub Personal Access Token (classic) or PAT with appropriate scopes: needs `repo` access and "self-hosted runners" administration for the target repository. Practically, you’ll want a token that can create registration tokens on the repository (often described here as admin:write on the repo in this script’s messages).

## Installation
You can use the script directly, or install it via Composer so `github-runner-starter` is available on your PATH.

### Option A: Use the script directly
- Clone or download this repository.
- From the project root, run:
  - `./github-runner-starter --help`

### Option B: Composer
If Composer is available in your environment:
- Add as a dependency or install globally. The package exposes a bin named `github-runner-starter`.

composer.json excerpt:
```
"bin": [
  "github-runner-starter"
]
```

## Quick start
1) Ensure you have a suitable PAT and know the `owner/repo` you want to register the runner to.
2) In a working directory, create a `.env` file or pass flags (see below).
3) Run the script.

Example with flags, including launching the runner immediately:
```
export GITHUB_REPOSITORY=operations-project/github-runner-starter
export GITHUB_TOKEN=ghp_***
./github-runner-starter \
  --labels=my-runner,linux \
  --run
```

If you omit `--run`, the script will download and configure the runner, but not launch `run.sh`. You can start it later manually from the runner directory.

## CLI options and environment variables
All options can be provided either as CLI flags or via environment variables. A `.env` file in the current working directory will be sourced automatically.

- --runner-path (env: RUNNER_PATH)
  - The path where the runner files will be downloaded/extracted (default: `runner`).
- --cleanup-runner (env: RUNNER_CLEANUP)
  - When canceling with Ctrl+C, remove the downloaded runner directory. Set value to `yes` to enable.
- --token (env: GITHUB_TOKEN)
  - GitHub API token used to obtain the registration token for the runner. Required when configuring.
- --repo (env: GITHUB_REPOSITORY)
  - Target repository, e.g., `owner/repo`. Required when configuring.
- --name (env: RUNNER_CONFIG_NAME)
  - Runner name. Defaults to `$(whoami)@$(hostname -f)`.
- --labels (env: RUNNER_CONFIG_LABELS)
  - Comma-separated labels. Defaults to `$(whoami)@$(hostname -f)` and the runner name is also appended.
- --run (env: RUNNER_RUN)
  - If set, the script will launch `run.sh` after configuration completes.
- --config-sh-options (env: RUNNER_CONFIG_OPTIONS)
  - Extra options to append to the runner’s `config.sh` command.
- --no-config (env: RUNNER_CONFIG)
  - Skip the `config.sh` step. Useful if you only want to download/extract the runner.
- --help
  - Show inline help.

See `.env.example` for a full set of variables and inline documentation.

## How it works
At a high level the script does the following:
1) Verify inputs, source `.env` if present, and compute defaults.
2) Request a short-lived registration token from the GitHub API for the given repository.
3) Determine the latest runner version and your architecture.
4) Download the appropriate runner tarball if not already present and extract it.
5) Run the runner’s `config.sh` with your parameters and labels.
6) Optionally start `run.sh` and wait on it.

On SIGTERM (stop) the script attempts to stop the runner and unregister it using `config.sh remove` with the same registration token. On SIGINT (Ctrl+C/cancel) it can optionally delete the runner directory if `RUNNER_CLEANUP=yes` is set.

## Examples
- Configure only (no immediate run):
```
./github-runner-starter
```

- Configure and run:
```
./github-runner-starter --run
```

- Custom path and labels:
```
./github-runner-starter \
  --runner-path=/opt/gh-runner \
  --labels=linux,x64
```

- Pass extra options to config.sh:
```
./github-runner-starter \
  --config-sh-options="--ephemeral"
```

## Docker usage (optional)
This repository includes a Dockerfile and docker-compose.yml for testing/development.

- Build and run with docker compose:
```
docker compose up --build
```
The compose file passes through `GITHUB_TOKEN` and targets this repo by default. You can override env vars via your shell or a `.env` file.

- Scaling multiple runners:
The `whichami` helper in this repo, used by `docker-entrypoint`, creates a unique suffix for the runner name when scaling services:
```
docker compose up --build --scale runner=3
```
Each container will get a distinct `RUNNER_CONFIG_NAME` like `runner1@hostname`, `runner2@hostname`, etc.

Note: The provided Docker image is for development. It installs dependencies and runs as the `runner` user in `/github-runner-starter`.

## Troubleshooting
- "GITHUB_REPOSITORY is required": Provide `--repo=owner/repo` or set `GITHUB_REPOSITORY`.
- "GITHUB_TOKEN is required": Provide `--token=...` or set `GITHUB_TOKEN`. Ensure it has sufficient permissions to create a registration token for the repo.
- "Unable to get registration token": Often indicates insufficient token scope, wrong repo, or network issues. The script will echo the API response for details.
- "Unable to determine CLI version": Ensure your token can access the `actions/runner` releases API endpoint and network egress is available.
- Architecture errors: The script detects `uname -m` as `x86_64` (x64) or `arm64`. Other architectures are not handled.

## Security considerations
- Treat `GITHUB_TOKEN` as sensitive. Avoid committing it to source control or baking it into images.
- When using Docker, prefer passing the token via environment at runtime, not building it into the image.

## Notes

I wrote the shell script. JetBrains Junie AI wrote the README from that.

## License
MIT License. See LICENSE for details.

## Author
- Jon Pugh (@jonpugh)
- Junie AI in PHPStorm.
