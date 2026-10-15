#!/usr/bin/env bash
# Print the latest published release for a formula as "<repo> <tag-prefix> <version>".
# Releases come from pragmatic-engineer/playbook:
#   playbook            v            the raw binary
#   playbook-telemetry  v            from the first v release that carries its archive,
#                                    else telemetry-v (releases before playbook 0.34.1)
#   pbtop               v            from the first v release that carries its archive
#   playbook-code       code-v
# Since playbook 0.34.0 one v release ships every tool (ADR 0038 in
# pragmatic-engineer/playbook), so a v release counts for a tool only when it
# has the tool's asset. Until a prefixed release exists in playbook, a formula
# keeps following the legacy repo it shipped from. Prints nothing when there
# is no release at all.
# Usage: latest-release.sh <formula-name>
set -euo pipefail

formula="${1:?usage: latest-release.sh <formula>}"
case "$formula" in
  playbook) candidates=("playbook v -") ;;
  playbook-telemetry) candidates=("playbook v asset" "playbook telemetry-v -" "playbook-telemetry v -") ;;
  pbtop) candidates=("playbook v asset") ;;
  playbook-code) candidates=("playbook code-v -" "playbook-code v -") ;;
  *)
    echo "::error::no release mapping for formula '${formula}'" >&2
    exit 1
    ;;
esac

for candidate in "${candidates[@]}"; do
  read -r repo prefix need <<<"$candidate"
  tags="$(gh release list --repo "pragmatic-engineer/${repo}" --limit 100 --json tagName,isDraft,isPrerelease \
    --jq "[.[] | select(.isDraft == false and .isPrerelease == false) | .tagName | select(test(\"^${prefix}[0-9]+\\\\.[0-9]+\\\\.[0-9]+\$\"))] | .[]")" || tags=""
  # Only the five newest releases are checked for an asset, which bounds the
  # API calls of a scheduled run.
  checked=0
  while IFS= read -r tag; do
    [ -n "$tag" ] || continue
    version="${tag#"$prefix"}"
    if [ "$need" = asset ]; then
      checked=$((checked + 1))
      [ "$checked" -le 5 ] || break
      gh release view "$tag" --repo "pragmatic-engineer/${repo}" --json assets --jq '.assets[].name' \
        | grep -qx "${formula}-${version}-x86_64-unknown-linux-musl.tar.gz" || continue
    fi
    printf '%s %s %s\n' "$repo" "$prefix" "$version"
    exit 0
  done <<<"$tags"
done
