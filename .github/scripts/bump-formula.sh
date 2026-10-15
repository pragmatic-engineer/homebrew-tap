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
# The caveats start with the release's breaking changes, read from its
# breaking-changes.json asset after a check against SHA256SUMS. A release with
# no entries for the formula clears them, and so does an older release whose
# SHA256SUMS does not list the file (ADR 0035 in pragmatic-engineer/playbook).
set -euo pipefail

version="${1:?usage: bump-formula.sh <version> [formula-path]}"
formula="${2:-Formula/playbook.rb}"
name="$(basename "$formula" .rb)"
case "$name" in
  playbook) repo="playbook"; prefix="v"; suffix=""; component="playbook" ;;
  playbook-telemetry)
    repo="playbook"; prefix="telemetry-v"; suffix=".tar.gz"; component="telemetry"
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
# DOWNLOAD_BASE reads SHA256SUMS and breaking-changes.json from another place,
# such as a file:// folder in a local test. The formula URLs keep the real base.
fetch_base="${DOWNLOAD_BASE:-$base}"
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
    printf '  livecheck do\n    url :stable\n    strategy :github_releases\n    regex(/^%sv(\\d+(?:\\.\\d+)+)$/i)\n  end\n' "${prefix%v}"
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
    printf '\n  def caveats\n    # BEGIN breaking changes. bump-formula.sh writes this from breaking-changes.json.\n    breaking = ""\n    # END breaking changes\n    breaking + <<~EOS\n      `%s` is a short alias for `%s`. Both are installed.\n    EOS\n  end\n' "$alias_bin" "$name"
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

sums="$(curl -fsSL --retry 3 --retry-delay 5 "${fetch_base}/SHA256SUMS")"

tmp="$(mktemp)"
block="$(mktemp)"
json="$(mktemp)"
trap 'rm -f "$tmp" "$block" "$json"' EXIT
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

# The breaking changes block. The entry layout mirrors notes() in
# scripts/check-breaking.sh of pragmatic-engineer/playbook. The text goes into
# a plain squiggly heredoc, which Homebrew's style check prefers. So jq refuses
# a field that Ruby would read as code or that the audit rejects: a control
# character (a newline included, since it could end the heredoc early), a
# backslash, `#{`, `#@`, `#$` or the word setuid. Trailing spaces are trimmed.
# Only the playbook formula names `playbook breaking`, since that command lists
# playbook entries only.
breaking_block() {
  local want got lines
  if [[ -z "${component:-}" ]]; then
    echo "${name} has no breaking changes component, so its caveats have none." >&2
    return 0
  fi
  want="$(awk '$2 == "breaking-changes.json" { print $1 }' <<<"$sums")"
  if [[ -z "$want" ]]; then
    echo "${tag} SHA256SUMS does not list breaking-changes.json, so the caveats have no breaking changes." >&2
    return 0
  fi
  curl -fsSL --retry 3 --retry-delay 5 -o "$json" "${fetch_base}/breaking-changes.json" >/dev/null
  if command -v sha256sum >/dev/null; then
    got="$(sha256sum "$json" | awk '{ print $1 }')"
  else
    got="$(shasum -a 256 "$json" | awk '{ print $1 }')"
  fi
  if [[ "$got" != "$want" ]]; then
    echo "::error::breaking-changes.json does not match ${tag} SHA256SUMS. Refusing to write." >&2
    return 1
  fi
  if ! lines="$(jq -r --arg c "$component" --arg v "$version" '
      def clean:
        if type == "string" and (test("[\\x00-\\x1f\\x7f\\\\]|#[{@$]|setuid"; "i") | not)
        then sub("\\s+$"; "") else error("unsafe text in breaking-changes.json: \(.)") end;
      .entries[] | select(.component == $c and .version == $v)
      | "- \(.summary | clean)", "  Action: \(.action | clean)"
    ' "$json")"; then
    echo "::error::an entry in breaking-changes.json has text the caveats cannot hold. Refusing to write." >&2
    return 1
  fi
  if [[ -z "$lines" ]]; then
    return 0
  fi
  printf '    breaking = <<~BREAKING\n'
  printf '      Breaking changes in %s %s:\n' "$name" "$version"
  sed 's/^/      /' <<<"$lines"
  if [[ "$name" = playbook ]]; then
    printf '      To see breaking changes from earlier releases, run `playbook breaking --since <your previous version>`.\n'
  fi
  printf '\n    BREAKING\n'
}

breaking_block >"$block"
if [[ ! -s "$block" ]]; then
  printf '    breaking = ""\n' >"$block"
fi
begin_marker='^    # BEGIN breaking changes\.'
end_marker='^    # END breaking changes$'
if [[ "$(grep -c "$begin_marker" "$tmp")" -ne 1 || "$(grep -c "$end_marker" "$tmp")" -ne 1 ]]; then
  echo "::error::${formula} needs one BEGIN and one END breaking changes marker in its caveats. Refusing to write." >&2
  exit 1
fi
awk -v block="$block" -v begin="$begin_marker" -v end="$end_marker" '
  $0 ~ begin { print; while ((getline line < block) > 0) print line; skip = 1; next }
  $0 ~ end { skip = 0 }
  !skip { print }
' "$tmp" >"${tmp}.new"
mv "${tmp}.new" "$tmp"

cp "$tmp" "$formula"
