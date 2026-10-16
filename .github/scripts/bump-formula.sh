#!/usr/bin/env bash
# Update a formula to a release of the repo it installs from.
# The formula name picks the release asset suffix and the default source:
#   playbook            pragmatic-engineer/playbook, tags vX.Y.Z       raw binary
#   pbtop               pragmatic-engineer/playbook, tags vX.Y.Z       .tar.gz holding pbtop alone
# Since playbook 0.34.0 one v release ships every tool. playbook-telemetry is
# retired and replaced by pbtop, so it is no longer bumped.
# SOURCE_REPO and TAG_PREFIX override the source (latest-release.sh prints them),
# which lets a formula keep following a legacy repo until its first prefixed tag.
# A tool formula that does not exist yet is created from a template at its first release.
# Usage: bump-formula.sh <version-without-v> [formula-path]
# URLs and checksums come from the release's own SHA256SUMS. Nothing is hand-edited.
# The caveats of each formula end with one line that links the release notes of
# the installed version, built from #{version}, so the bump writes no caveats
# text (ADR 0037 in pragmatic-engineer/playbook).
set -euo pipefail

version="${1:?usage: bump-formula.sh <version> [formula-path]}"
formula="${2:-Formula/playbook.rb}"
name="$(basename "$formula" .rb)"
case "$name" in
  playbook) repo="playbook"; prefix="v"; suffix="" ;;
  playbook-telemetry)
    echo "::error::playbook-telemetry is retired; use pbtop" >&2
    exit 1
    ;;
  pbtop)
    repo="playbook"; prefix="v"; suffix=".tar.gz"
    class_name="Pbtop"; alias_bin=""
    desc="Terminal dashboard of Claude Code token use and cost"
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
# DOWNLOAD_BASE reads SHA256SUMS from another place,
# such as a file:// folder in a local test. The formula URLs keep the real base.
fetch_base="${DOWNLOAD_BASE:-$base}"
targets=(aarch64-apple-darwin x86_64-apple-darwin aarch64-unknown-linux-musl x86_64-unknown-linux-musl)

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "::error::refusing unexpected version '${version}'" >&2
  exit 1
fi

write_template() {
  local zero notes
  notes="Release notes: https://github.com/pragmatic-engineer/${repo}/releases/tag/${prefix}#{version}"
  zero="$(printf '0%.0s' $(seq 1 64))"
  {
    printf 'class %s < Formula\n' "$class_name"
    printf '  desc "%s"\n' "$desc"
    printf '  homepage "https://github.com/pragmatic-engineer/%s"\n' "$repo"
    printf '  license "Apache-2.0"\n\n'
    printf '  livecheck do\n    url :stable\n    strategy :github_releases\n    regex(/^%sv(\\d+(?:\\.\\d+)+)$/i)\n  end\n' "${prefix%v}"
    local os t_arm t_x
    for os in macos linux; do
      if [[ "$os" = macos ]]; then t_arm=aarch64-apple-darwin; t_x=x86_64-apple-darwin
      else t_arm=aarch64-unknown-linux-musl; t_x=x86_64-unknown-linux-musl; fi
      printf '\n  on_%s do\n    if Hardware::CPU.arm?\n' "$os"
      printf '      url "%s/%s-%s-%s%s"\n      sha256 "%s"\n' "$base" "$name" "$version" "$t_arm" "$suffix" "$zero"
      printf '    else\n'
      printf '      url "%s/%s-%s-%s%s"\n      sha256 "%s"\n' "$base" "$name" "$version" "$t_x" "$suffix" "$zero"
      printf '    end\n  end\n'
    done
    if [[ -n "$alias_bin" ]]; then
      printf '\n  def install\n    bin.install "%s", "%s"\n  end\n' "$name" "$alias_bin"
      # shellcheck disable=SC2016 # the backticks are literal caveats text
      printf '\n  def caveats\n    <<~EOS\n      `%s` is a short alias for `%s`. Both are installed.\n' "$alias_bin" "$name"
      printf '      %s\n    EOS\n  end\n' "$notes"
      printf '\n  test do\n    assert_match version.to_s, shell_output("#{bin}/%s --version")\n' "$name"
      printf '    assert_match version.to_s, shell_output("#{bin}/%s --version")\n  end\nend\n' "$alias_bin"
    else
      printf '\n  def install\n    bin.install "%s"\n  end\n' "$name"
      # shellcheck disable=SC2016 # the backticks are literal caveats text
      printf '\n  def caveats\n    <<~EOS\n      Run `%s` to start.\n' "$name"
      printf '      %s\n    EOS\n  end\n' "$notes"
      printf '\n  test do\n    assert_match version.to_s, shell_output("#{bin}/%s --version")\n  end\nend\n' "$name"
    fi
  } >"$formula"
}

if [[ ! -f "$formula" ]]; then
  if [[ -z "${class_name:-}" ]]; then
    echo "::error::${formula} does not exist and '${name}' has no template" >&2
    exit 1
  fi
  write_template
fi

sums="$(curl -fsSL --retry 3 --retry-delay 5 "${fetch_base}/SHA256SUMS")"

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

# The livecheck regex follows the tag prefix, so a formula that moves to a
# new tag prefix checks the right releases.
LIVECHECK_RE="    regex(/^${prefix}(\\d+(?:\\.\\d+)+)\$/i)" awk '
  $1 ~ /^regex\(\/\^/ { print ENVIRON["LIVECHECK_RE"]; next } { print }
' "$tmp" >"${tmp}.new"
mv "${tmp}.new" "$tmp"

# The release notes line in the caveats follows the repo and tag prefix too,
# so a formula that moves its source links the right release page.
NOTES_LINE="      Release notes: https://github.com/pragmatic-engineer/${repo}/releases/tag/${prefix}#{version}" awk '
  index($0, "      Release notes: https://github.com/") == 1 { print ENVIRON["NOTES_LINE"]; next } { print }
' "$tmp" >"${tmp}.new"
mv "${tmp}.new" "$tmp"

rewritten="$(grep -c "/download/${tag}/${name}-${version}-" "$tmp" || true)"
if [[ "$rewritten" -ne ${#targets[@]} ]]; then
  echo "::error::expected ${#targets[@]} url lines for ${tag} after the rewrite, found ${rewritten}. The formula layout changed. Refusing to write." >&2
  exit 1
fi

cp "$tmp" "$formula"
