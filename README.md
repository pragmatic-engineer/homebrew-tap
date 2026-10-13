# homebrew-tap

Homebrew tap for the [pragmatic-engineer/playbook](https://github.com/pragmatic-engineer/playbook) toolkit. It carries three tools:

- `playbook`, the Claude Code plugin toolkit and its binary.
- `playbook-telemetry`, the standalone token and cost dashboard, with the short alias `pbtop`.
- `playbook-code`, the standalone code index and search, with the short alias `pbcode`. It has no formula until its first release.

## Install

```bash
brew install pragmatic-engineer/tap/playbook
```

The tap is `pragmatic-engineer/tap`, so `brew tap pragmatic-engineer/tap` works too. Upgrade with `brew upgrade playbook`.

## Moving from the old tap

This repo used to be named `homebrew-playbook`, and the install command was `brew install pragmatic-engineer/playbook/playbook`. If you installed that way, switch taps once:

```bash
brew untap pragmatic-engineer/playbook
brew tap pragmatic-engineer/tap
```

GitHub redirects the old repo URL, so existing links keep working. If `brew untap` refuses because `playbook` is installed from the old tap, uninstall it first and install it again from the new tap.

## What this does

The formula downloads the prebuilt binary which `pragmatic-engineer/playbook`'s own release workflow builds, attests and checksums for each tagged release. It doesn't build from source and doesn't run a separate release pipeline. It wraps the same `SHA256SUMS` verified binary `install.sh` fetches.

Covers macOS (Apple Silicon and Intel) and Linux (x86_64 and arm64, static musl builds). Windows isn't a Homebrew target. Windows users should use `install.sh` directly, or WSL with the Linux binary.

## Formulas

| Formula | Install | Commands |
|---|---|---|
| `playbook` | `brew install pragmatic-engineer/tap/playbook` | `playbook` |
| `playbook-telemetry` | `brew install pragmatic-engineer/tap/playbook-telemetry` | `pbtop` (short alias) and `playbook-telemetry` (long name for scripts) |
| `playbook-code` | Not available until its first release. Use `playbook code` today. | `pbcode` (short alias) and `playbook-code` |

Type the short alias, for example `pbtop` after installing `playbook-telemetry`. You do not need the standalone tools if you have `playbook`: `playbook usage` runs the same code as `pbtop`, and `playbook code` is what `pbcode` will be.

## Keeping the formula current

The `release` workflow checks every 30 minutes, and merges the bump once the `tests` workflow passes. It can also be started by hand with `workflow_dispatch` (the `bump` workflow is the same job and shares its concurrency group), or by a `tool-released` `repository_dispatch` event, which needs a sender with its own token. The schedule alone needs no secret. A bump pull request that is still open is left alone by later runs. Every trigger runs the same job for each formula. It reads the latest release of that tool and compares it with the formula. If the release is newer, it rewrites the URLs and checksums from that release's own `SHA256SUMS` (`.github/scripts/bump-formula.sh`, which refuses to write a formula when a checksum is missing) and commits the change to a `bump/<formula>-v<version>` branch through the GitHub API and opens a pull request. It uses only the built-in `GITHUB_TOKEN`, so no secret is stored. GitHub signs the commit, so it shows as verified. A pull request opened with `GITHUB_TOKEN` gets its `pull_request` run held for approval, so the bump approves that run, waits for the `tests` workflow (audit, install and test on four platforms) to pass, and then squash merges the pull request through the API, which `protect-main` allows because the required checks passed on the branch head. Don't edit the formula's URLs or checksums by hand.

The `tests` workflow in this repo runs `brew audit --strict`, `brew install` and `brew test` on Linux and macOS (arm64 and x86_64) for every push, pull request and weekly. Bottles are not built, because the formula installs prebuilt binaries.

A formula that does not exist yet, such as `playbook-code`, is created from a template at the tool's first release. If a formula is behind the latest release, check the latest `release` run in this repo.
