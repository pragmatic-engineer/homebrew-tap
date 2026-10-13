#!/usr/bin/env bash
# Update a formula to a release of the repo it installs from.
# The formula name picks the release asset suffix and the default source:
#   playbook            pragmatic-engineer/playbook, tags vX.Y.Z            raw binary
#   playbook-telemetry  pragmatic-engineer/playbook, tags telemetry-vX.Y.Z  .tar.gz holding playbook-telemetry and pbtop
#   playbook-code       pragmatic-engineer/playbook, tags code-vX.Y.Z       .tar.gz holding playbook-code and pbcode
# SOURCE_REPO and TAG_PREFIX override the source (latest-release.sh prints them),
# which lets a formula keep following a legacy repo until its first prefixed tag.
# A tool formula that does not exist yet is created from a template at its first release.
# Usage: bump-formula.sh <version-without-v> [formula-path]
# URLs and checksums come from the release's own SHA256SUMS. Nothing is hand-edited.
set -euo pipefail

version="${1:?usage: bump-formula.sh <version> [formula-path]}"
formula="${2:-Formula/playbook.rb}"
name="$(basename "$formula" .rb)"
case "$name" in
  playbook) repo="playbook"; prefix="v"; suffix="" ;;
  playbook-telemetry)
    repo="playbook"; prefix="telemetry-v"; suffix=".tar.gz"
    class_name="PlaybookTelemetry"; alias_bin="pbtop"
    desc="Usage and cost tracking for Claude Code in a terminal dashboard"
    ;;
  playbook-code)
    repo="playbook"; prefix="code-v"; suffix=".tar.gz"
    class_name="PlaybookCode"; alias_bin="pbcode"
    desc="Local code index and search for coding agents"
    ;;
  *)
    echo "::error::no release mapping for formula '${name}'" >&2
    exit 1
    ;;
esac
repo="${SOURCE_REPO:-$repo}"
prefix="${TAG_PREFIX:-$prefix}"
tag="${prefix}${version}"
base="https://github.com/pragmatic-engineer/${repo}/releases/download/${tag}"
targets=(aarch64-apple-darwin x86_64-apple-darwin aarch64-unknown-linux-musl x86_64-unknown-linux-musl)

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "::error::refusing unexpected version '${version}'" >&2
  exit 1
fi

write_template() {
  local zero
  zero="$(printf '0%.0s' $(seq 1 64))"
  {
    printf 'class %s < Formula\n' "$class_name"
    printf '  desc "%s"\n' "$desc"
    printf '  homepage "https://github.com/pragmatic-engineer/%s"\n' "$repo"
    printf '  license "Apache-2.0"\n\n'
    printf '  livecheck do\n    url :stable\n    strategy :github_latest\n  end\n'
    local os cpu_arm cpu_x t_arm t_x
    for os in macos linux; do
      if [[ "$os" = macos ]]; then t_arm=aarch64-apple-darwin; t_x=x86_64-apple-darwin
      else t_arm=aarch64-unknown-linux-musl; t_x=x86_64-unknown-linux-musl; fi
      printf '\n  on_%s do\n    if Hardware::CPU.arm?\n' "$os"
      printf '      url "%s/%s-%s-%s%s"\n      sha256 "%s"\n' "$base" "$name" "$version" "$t_arm" "$suffix" "$zero"
      printf '    else\n'
      printf '      url "%s/%s-%s-%s%s"\n      sha256 "%s"\n' "$base" "$name" "$version" "$t_x" "$suffix" "$zero"
      printf '    end\n  end\n'
    done
    printf '\n  def install\n    bin.install "%s", "%s"\n  end\n' "$name" "$alias_bin"
    printf '\n  def caveats\n    <<~EOS\n      `%s` is a short alias for `%s`. Both are installed.\n    EOS\n  end\n' "$alias_bin" "$name"
    printf '\n  test do\n    assert_match version.to_s, shell_output("#{bin}/%s --version")\n' "$name"
    printf '    assert_match version.to_s, shell_output("#{bin}/%s --version")\n  end\nend\n' "$alias_bin"
  } >"$formula"
}

if [[ ! -f "$formula" ]]; then
  if [[ -z "${class_name:-}" ]]; then
    echo "::error::${formula} does not exist and '${name}' has no template" >&2
    exit 1
  fi
  write_template
fi

sums="$(curl -fsSL --retry 3 --retry-delay 5 "${base}/SHA256SUMS")"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
cp "$formula" "$tmp"

for target in "${targets[@]}"; do
  sha="$(awk -v f="${name}-${version}-${target}${suffix}" '$2 == f { print $1 }' <<<"$sums")"
  if [[ ! "$sha" =~ ^[0-9a-f]{64}$ ]]; then
    echo "::error::missing or malformed checksum for ${target} in ${tag} SHA256SUMS. Refusing to write a partial formula." >&2
    exit 1
  fi
  # Rewrite the url line for this target, and the sha256 line that follows it.
  awk -v target="$target" -v suffix="$suffix" -v url="      url \"${base}/${name}-${version}-${target}${suffix}\"" -v sha="      sha256 \"${sha}\"" '
    $1 == "url" && index($0, "-" target suffix "\"") { print url; fix = 1; next }
    fix && $1 == "sha256" { print sha; fix = 0; next }
    { print }
  ' "$tmp" >"${tmp}.new"
  mv "${tmp}.new" "$tmp"
done

rewritten="$(grep -c "/download/${tag}/${name}-${version}-" "$tmp" || true)"
if [[ "$rewritten" -ne ${#targets[@]} ]]; then
  echo "::error::expected ${#targets[@]} url lines for ${tag} after the rewrite, found ${rewritten}. The formula layout changed. Refusing to write." >&2
  exit 1
fi

cp "$tmp" "$formula"
