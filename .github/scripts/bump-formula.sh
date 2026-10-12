#!/usr/bin/env bash
# Update a formula to a release of the repo it installs from.
# Usage: bump-formula.sh <version-without-v> [formula-path]
# The formula name picks the source repo and the release assets it pins:
#   playbook        pragmatic-engineer/playbook        playbook
#   playbook-usage  pragmatic-engineer/playbook-usage  playbook-usage, pbtop
# URLs and checksums come from the release's own SHA256SUMS. Nothing is hand-edited.
set -euo pipefail

version="${1:?usage: bump-formula.sh <version> [formula-path]}"
formula="${2:-Formula/playbook.rb}"
name="$(basename "$formula" .rb)"

case "$name" in
  playbook) repo="playbook"; assets=(playbook) ;;
  playbook-usage) repo="playbook-usage"; assets=(playbook-usage pbtop) ;;
  *)
    echo "::error::no release mapping for formula '${name}'" >&2
    exit 1
    ;;
esac

base="https://github.com/pragmatic-engineer/${repo}/releases/download/v${version}"
targets=(aarch64-apple-darwin x86_64-apple-darwin aarch64-unknown-linux-musl x86_64-unknown-linux-musl)

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "::error::refusing unexpected version '${version}'" >&2
  exit 1
fi

sums="$(curl -fsSL "${base}/SHA256SUMS")"

tmp="$(mktemp)"
trap 'rm -f "$tmp" "${tmp}.new"' EXIT
cp "$formula" "$tmp"

for asset in "${assets[@]}"; do
  for target in "${targets[@]}"; do
    file="${asset}-${version}-${target}"
    sha="$(awk -v f="$file" '$2 == f { print $1 }' <<<"$sums")"
    if [[ ! "$sha" =~ ^[0-9a-f]{64}$ ]]; then
      echo "::error::missing or malformed checksum for ${file} in v${version} SHA256SUMS. Refusing to write a partial formula." >&2
      exit 1
    fi
    # Rewrite the url line for this asset and target, and the sha256 line that
    # follows it, keeping the line's own indentation.
    awk -v asset="$asset" -v target="$target" -v url="${base}/${file}" -v sha="$sha" '
      function indent(s) { match(s, /^ */); return substr(s, 1, RLENGTH) }
      $1 == "url" && index($0, "/" asset "-") && index($0, "-" target "\"") {
        print indent($0) "url \"" url "\""; fix = 1; next
      }
      fix && $1 == "sha256" { print indent($0) "sha256 \"" sha "\""; fix = 0; next }
      { print }
    ' "$tmp" >"${tmp}.new"
    mv "${tmp}.new" "$tmp"
  done
done

want=$(( ${#targets[@]} * ${#assets[@]} ))
rewritten="$(grep -c "/download/v${version}/.*-${version}-" "$tmp" || true)"
if [[ "$rewritten" -ne "$want" ]]; then
  echo "::error::expected ${want} url lines for v${version} after the rewrite, found ${rewritten}. The formula layout changed. Refusing to write." >&2
  exit 1
fi

cp "$tmp" "$formula"
