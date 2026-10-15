# homebrew-tap

Homebrew tap for the [pragmatic-engineer/playbook](https://github.com/pragmatic-engineer/playbook) toolkit. It carries these tools:

- `playbook`, the Claude Code plugin toolkit and its binary.
- `playbook-telemetry`, the standalone token and cost dashboard, with the short alias `pbtop`.
- `pbtop`, the same dashboard on its own. It has no formula until the first playbook release that ships it.
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
| `pbtop` | Not available until the first playbook release that ships it. Then `brew install pragmatic-engineer/tap/pbtop`. | `pbtop` |
| `playbook-code` | Not available until its first release. Use `playbook code` today. | `pbcode` (short alias) and `playbook-code` |

Type the short alias, for example `pbtop` after installing `playbook-telemetry`. Both `pbtop` and `playbook-telemetry` install the `pbtop` command, so install one of the two. You do not need the standalone tools if you have `playbook`: `playbook usage` runs the same code as `pbtop`, and `playbook code` is what `pbcode` will be.

## Keeping the formula current

Since playbook 0.34.0, one `v` release of `pragmatic-engineer/playbook` ships `playbook`, `playbook-telemetry` and `pbtop` with the same version. Its release workflow opens a `release/vX.Y.Z` pull request here that updates those formulas with `.github/scripts/bump-formula.sh`, and turns on auto-merge. When that pull request merges, the `release-tag` workflow tags the merge commit `vX.Y.Z` and publishes a release that lists the formula versions. It acts only on a merged pull request from the `igorjs[bot]` app on a `release/v*` branch, and it uses only `GITHUB_TOKEN`.

The `release` workflow is the fallback. It checks every 30 minutes, and merges the bump once the `tests` workflow passes. It can also be started by hand with `workflow_dispatch` (the `bump` workflow is the same job and shares its concurrency group), or by a `tool-released` `repository_dispatch` event, which needs a sender with its own token. The schedule alone needs no secret. A bump pull request that is still open is left alone by later runs. A run also leaves a `v` release alone while its `release/vX.Y.Z` pull request is open, and a run that was not started by hand does so for the first hour after the release, so it does not open a second pull request for the same change. Every trigger runs the same job for each formula. It reads the latest release of that tool and compares it with the formula. If the release is newer, it rewrites the URLs and checksums from that release's own `SHA256SUMS` (`.github/scripts/bump-formula.sh`, which refuses to write a formula when a checksum is missing) and commits the change to a `bump/<formula>-v<version>` branch through the GitHub API and opens a pull request. It uses only the built-in `GITHUB_TOKEN`, so no secret is stored. GitHub signs the commit, so it shows as verified. A pull request opened with `GITHUB_TOKEN` gets its `pull_request` run held for approval, so the bump approves that run, waits for the `tests` workflow (audit, install and test on four platforms) to pass, and then squash merges the pull request through the API, which `protect-main` allows because the required checks passed on the branch head. The bump also puts the release's breaking changes at the top of the formula's caveats, so `brew upgrade` and `brew info` show them. It reads them from the release's `breaking-changes.json` after it checks that file against `SHA256SUMS`. A release with no entries for the formula clears them, and so does an older release whose `SHA256SUMS` does not list the file. The `bump-script` job in `tests` runs `.github/scripts/test-bump-formula.sh` and a style check of a formula with a filled block. Don't edit the formula's URLs or checksums by hand. Leave the block between the `BEGIN breaking changes` and `END breaking changes` markers in `caveats` to the bump as well.

The `tests` workflow in this repo runs `brew audit --strict`, `brew install` and `brew test` on Linux and macOS (arm64 and x86_64) for every push, pull request and weekly. Bottles are not built, because the formula installs prebuilt binaries.

A formula that does not exist yet, such as `playbook-code`, is created from a template at the tool's first release. If a formula is behind the latest release, check the latest `release` run in this repo.
