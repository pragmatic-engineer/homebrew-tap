#!/usr/bin/env bash
# Tests bump-formula.sh against release folders built here and read through
# DOWNLOAD_BASE, so nothing touches the network. It checks the release notes
# line in the caveats, the pbtop template, the refusal of the retired
# playbook-telemetry formula and latest-release.sh against a stub gh.
# Usage: test-bump-formula.sh [--keep]
# With --keep, Formula/pbtop.rb is left as a release writes it, so a style and
# audit run can check it.
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
script="$root/.github/scripts/bump-formula.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
failures=0

pass() { printf 'PASS %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; failures=$((failures + 1)); }

notes='      Release notes: https://github.com/pragmatic-engineer/playbook/releases/tag/v#{version}'

# release VERSION: builds a release folder with the playbook binaries.
release() {
  local dir="$work/rel-$1" t
  rm -rf "$dir"
  mkdir -p "$dir"
  for t in aarch64-apple-darwin x86_64-apple-darwin aarch64-unknown-linux-musl x86_64-unknown-linux-musl; do
    printf 'bin %s\n' "$t" >"$dir/playbook-$1-$t"
  done
  (cd "$dir" && shasum -a 256 playbook-* >SHA256SUMS)
  printf '%s' "$dir"
}

mkdir -p "$work/f"
cp "$root/Formula/playbook.rb" "$work/f/playbook.rb"
dir="$(release 9.0.0)"
if DOWNLOAD_BASE="file://$dir" bash "$script" 9.0.0 "$work/f/playbook.rb" >/dev/null 2>"$work/err" \
  && [[ "$(grep -c '/download/v9.0.0/playbook-9.0.0-' "$work/f/playbook.rb")" -eq 4 ]] \
  && [[ "$(grep -cxF "$notes" "$work/f/playbook.rb")" -eq 1 ]] \
  && ! grep -qi 'breaking' "$work/f/playbook.rb" \
  && ruby -c "$work/f/playbook.rb" >/dev/null; then
  pass "a bump keeps the release notes line and writes no breaking block"
else
  fail "a bump keeps the release notes line and writes no breaking block"
fi

# tool_release NAME VERSION: a release folder with the archives of one tool.
tool_release() {
  local dir="$work/tool-$1-$2" t
  rm -rf "$dir"
  mkdir -p "$dir"
  for t in aarch64-apple-darwin x86_64-apple-darwin aarch64-unknown-linux-musl x86_64-unknown-linux-musl; do
    printf 'archive %s\n' "$t" >"$dir/$1-$2-$t.tar.gz"
  done
  (cd "$dir" && shasum -a 256 -- *.tar.gz >SHA256SUMS)
  printf '%s' "$dir"
}

mkdir -p "$work/p"
pbtop="$work/p/pbtop.rb"
dir="$(tool_release pbtop 9.7.0)"
if DOWNLOAD_BASE="file://$dir" bash "$script" 9.7.0 "$pbtop" >/dev/null 2>"$work/err" \
  && grep -qx '    bin.install "pbtop"' "$pbtop" \
  && [[ "$(grep -c '/download/v9.7.0/pbtop-9.7.0-' "$pbtop")" -eq 4 ]] \
  && ! grep -q '0\{64\}' "$pbtop" \
  && ruby -c "$pbtop" >/dev/null; then
  pass "the pbtop formula is written from its template"
else
  fail "the pbtop formula is written from its template"
fi
if ! grep -q 'conflicts_with' "$pbtop" \
  && [[ "$(grep -cxF "$notes" "$pbtop")" -eq 1 ]] \
  && [[ "$(grep -A1 -xF "$notes" "$pbtop" | tail -n1)" = '    EOS' ]]; then
  pass "the pbtop template has no conflicts_with and ends its caveats with the release notes line"
else
  fail "the pbtop template has no conflicts_with and ends its caveats with the release notes line"
fi

mkdir -p "$work/t"
cp "$root/Formula/playbook-telemetry.rb" "$work/t/playbook-telemetry.rb"
dir="$(tool_release playbook-telemetry 9.7.0)"
if ! DOWNLOAD_BASE="file://$dir" bash "$script" 9.7.0 "$work/t/playbook-telemetry.rb" >/dev/null 2>"$work/err" \
  && grep -qxF '::error::playbook-telemetry is retired; use pbtop' "$work/err" \
  && cmp -s "$root/Formula/playbook-telemetry.rb" "$work/t/playbook-telemetry.rb"; then
  pass "bump-formula.sh refuses playbook-telemetry and leaves it unchanged"
else
  fail "bump-formula.sh refuses playbook-telemetry and leaves it unchanged"
fi

# latest-release.sh against a stub gh. GH_RELEASES is the release list as
# JSON, and GH_ASSETS_<version with _> the asset names of a release.
latest="$root/.github/scripts/latest-release.sh"
mkdir -p "$work/bin"
cat >"$work/bin/gh" <<'STUB'
#!/usr/bin/env bash
repo=""; jq_filter=""; tag=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo) repo="$2"; shift ;;
    --jq) jq_filter="$2"; shift ;;
    release|list|view|--json|--limit) ;;
    tagName,isDraft,isPrerelease|assets|100) ;;
    *) tag="$1" ;;
  esac
  shift
done
if [ "$repo" != pragmatic-engineer/playbook ]; then
  echo "GraphQL: Could not resolve to a Repository with the name '${repo}'." >&2
  exit 1
fi
if [ -z "$tag" ]; then
  jq -r "$jq_filter" <<<"$GH_RELEASES"
else
  var="GH_ASSETS_${tag//./_}"
  printf '%s\n' ${!var:-}
fi
STUB
chmod +x "$work/bin/gh"
releases='[{"tagName":"v9.1.0","isDraft":false,"isPrerelease":false},
  {"tagName":"v9.0.0","isDraft":false,"isPrerelease":false},
  {"tagName":"telemetry-v0.2.0","isDraft":false,"isPrerelease":false}]'
lookup() { PATH="$work/bin:$PATH" GH_RELEASES="$releases" bash "$latest" "$1" 2>"$work/err"; }

if [[ "$(GH_ASSETS_v9_1_0="playbook-9.1.0-x86_64-unknown-linux-musl" \
  GH_ASSETS_v9_0_0="pbtop-9.0.0-x86_64-unknown-linux-musl.tar.gz" lookup pbtop)" = "playbook v 9.0.0" ]]; then
  pass "pbtop skips a v release without its archive"
else
  fail "pbtop skips a v release without its archive"
fi
if ! lookup playbook-telemetry >/dev/null \
  && grep -qxF '::error::playbook-telemetry is retired; use pbtop' "$work/err"; then
  pass "latest-release.sh refuses playbook-telemetry"
else
  fail "latest-release.sh refuses playbook-telemetry"
fi
if [[ "$(lookup playbook)" = "playbook v 9.1.0" ]] && [[ -z "$(lookup playbook-code)" ]]; then
  pass "playbook takes the newest v release, and playbook-code without a release prints nothing"
else
  fail "playbook takes the newest v release, and playbook-code without a release prints nothing"
fi

if [[ "${1:-}" = "--keep" ]]; then
  cp "$pbtop" "$root/Formula/pbtop.rb"
  printf 'Left Formula/pbtop.rb as a release writes it, for the style check.\n'
fi

if [[ "$failures" -ne 0 ]]; then
  printf '%d failed\n' "$failures"
  exit 1
fi
printf 'all passed\n'
