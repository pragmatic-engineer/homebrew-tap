#!/usr/bin/env bash
# Print the latest published release for a formula as "<repo> <tag-prefix> <version>".
# Releases come from tag prefixes in pragmatic-engineer/playbook:
#   playbook            v
#   playbook-telemetry  telemetry-v
#   playbook-code       code-v
# Until a prefixed release exists in playbook, the formula keeps following the
# legacy repo it shipped from (playbook-telemetry, playbook-code), so moving the
# source changes nothing until the first new tag. Prints nothing when there is no
# release at all.
# Usage: latest-release.sh <formula-name>
set -euo pipefail

formula="${1:?usage: latest-release.sh <formula>}"
case "$formula" in
  playbook) candidates=("playbook v") ;;
  playbook-telemetry) candidates=("playbook telemetry-v" "playbook-telemetry v") ;;
  playbook-code) candidates=("playbook code-v" "playbook-code v") ;;
  *)
    echo "::error::no release mapping for formula '${formula}'" >&2
    exit 1
    ;;
esac

for candidate in "${candidates[@]}"; do
  read -r repo prefix <<<"$candidate"
  tag="$(gh release list --repo "pragmatic-engineer/${repo}" --limit 100 --json tagName,isDraft,isPrerelease \
    --jq "[.[] | select(.isDraft == false and .isPrerelease == false) | .tagName | select(test(\"^${prefix}[0-9]+\\\\.[0-9]+\\\\.[0-9]+\$\"))] | first // empty" 2>/dev/null || true)"
  if [ -n "$tag" ]; then
    printf '%s %s %s\n' "$repo" "$prefix" "${tag#"$prefix"}"
    exit 0
  fi
done
