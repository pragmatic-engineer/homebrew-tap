#!/usr/bin/env bash
# Tests the breaking changes block of bump-formula.sh against release folders
# built here and read through DOWNLOAD_BASE, so nothing touches the network.
# It also checks the pbtop template and the move of playbook-telemetry to v tags.
# Usage: test-bump-formula.sh [--keep]
# With --keep, Formula/playbook.rb is left with a filled block and
# Formula/pbtop.rb is written from the template, so a style and audit run can
# check what a real release would write.
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
script="$root/.github/scripts/bump-formula.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
failures=0

pass() { printf 'PASS %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; failures=$((failures + 1)); }

# release VERSION ENTRIES_JSON [unlisted|tampered]: builds a release folder.
release() {
  local dir="$work/rel-$1" t
  rm -rf "$dir"
  mkdir -p "$dir"
  for t in aarch64-apple-darwin x86_64-apple-darwin aarch64-unknown-linux-musl x86_64-unknown-linux-musl; do
    printf 'bin %s\n' "$t" >"$dir/playbook-$1-$t"
  done
  printf '{"entries":%s}\n' "$2" >"$dir/breaking-changes.json"
  (cd "$dir" && shasum -a 256 playbook-* breaking-changes.json >SHA256SUMS)
  case "${3:-}" in
    unlisted) grep -v breaking-changes.json "$dir/SHA256SUMS" >"$dir/S" && mv "$dir/S" "$dir/SHA256SUMS" ;;
    tampered) printf '{"entries":[]}\n' >"$dir/breaking-changes.json" ;;
  esac
  printf '%s' "$dir"
}

entry() {
  jq -cn --arg v "$1" --arg s "$2" --arg a "$3" \
    '[{version: $v, component: "playbook", summary: $s, action: $a, migration: null}]'
}

# bump VERSION DIR: runs the script on a copy of the formula, prints its path.
bump() {
  mkdir -p "$work/f"
  cp "$root/Formula/playbook.rb" "$work/f/playbook.rb"
  DOWNLOAD_BASE="file://$2" bash "$script" "$1" "$work/f/playbook.rb" >/dev/null 2>"$work/err"
}

dir="$(release 9.0.0 "$(entry 9.0.0 "The old flag is gone, so 'pb x' fails.   " "playbook init")")"
if bump 9.0.0 "$dir" \
  && grep -qx "      - The old flag is gone, so 'pb x' fails." "$work/f/playbook.rb" \
  && grep -qx '    breaking = <<~BREAKING' "$work/f/playbook.rb" \
  && ruby -c "$work/f/playbook.rb" >/dev/null; then
  pass "an entry is written, trimmed, into a heredoc"
else
  fail "an entry is written, trimmed, into a heredoc"
fi
filled="$work/f/playbook.rb.filled"
cp "$work/f/playbook.rb" "$filled"

dir="$(release 9.1.0 "[]")"
if bump 9.1.0 "$dir" && grep -qx '    breaking = ""' "$work/f/playbook.rb"; then
  pass "a release with no entries clears the block"
else
  fail "a release with no entries clears the block"
fi

dir="$(release 9.2.0 "$(entry 9.2.0 s x)" unlisted)"
if bump 9.2.0 "$dir" && grep -qx '    breaking = ""' "$work/f/playbook.rb"; then
  pass "a release that does not list the file clears the block"
else
  fail "a release that does not list the file clears the block"
fi

dir="$(release 9.3.0 "$(entry 9.3.0 s x)" tampered)"
if ! bump 9.3.0 "$dir" && grep -q "does not match" "$work/err"; then
  pass "a file that does not match SHA256SUMS stops the bump"
else
  fail "a file that does not match SHA256SUMS stops the bump"
fi

for bad in $'a\nBREAKING\nsystem("id")' 'a #{x}' 'a #@x' 'a #$x' 'a \ b' 'uses setuid'; do
  dir="$(release 9.4.0 "$(entry 9.4.0 "$bad" x)")"
  if ! bump 9.4.0 "$dir" && grep -q "cannot hold" "$work/err"; then
    pass "unsafe text stops the bump: ${bad//$'\n'/\\n}"
  else
    fail "unsafe text stops the bump: ${bad//$'\n'/\\n}"
  fi
done

dir="$(release 9.5.0 "$(entry 9.5.0 'x # END breaking changes' y)")"
if bump 9.5.0 "$dir"; then
  dir="$(release 9.6.0 "[]")"
  mkdir -p "$work/g" && cp "$work/f/playbook.rb" "$work/g/playbook.rb"
  if DOWNLOAD_BASE="file://$dir" bash "$script" 9.6.0 "$work/g/playbook.rb" >/dev/null 2>&1 \
    && grep -qx '    breaking = ""' "$work/g/playbook.rb"; then
    pass "marker text in an entry does not break the next bump"
  else
    fail "marker text in an entry does not break the next bump"
  fi
else
  fail "marker text in an entry does not break the next bump"
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
dir="$(tool_release pbtop 9.7.0)"
pbtop="$work/p/pbtop.rb"
if DOWNLOAD_BASE="file://$dir" bash "$script" 9.7.0 "$pbtop" >/dev/null 2>"$work/err" \
  && grep -qx '    bin.install "pbtop"' "$pbtop" \
  && grep -qx '  conflicts_with "playbook-telemetry", because: "both install `pbtop`"' "$pbtop" \
  && [[ "$(grep -c '/download/v9.7.0/pbtop-9.7.0-' "$pbtop")" -eq 4 ]] \
  && ! grep -q '0\{64\}' "$pbtop" \
  && ruby -c "$pbtop" >/dev/null; then
  pass "the pbtop formula is written from its template"
else
  fail "the pbtop formula is written from its template"
fi

dir="$(tool_release playbook-telemetry 9.8.0)"
telemetry="$work/p/playbook-telemetry.rb"
cp "$root/Formula/playbook-telemetry.rb" "$telemetry"
if DOWNLOAD_BASE="file://$dir" bash "$script" 9.8.0 "$telemetry" >/dev/null 2>"$work/err" \
  && grep -qxF '    regex(/^v(\d+(?:\.\d+)+)$/i)' "$telemetry" \
  && [[ "$(grep -c '/download/v9.8.0/playbook-telemetry-9.8.0-' "$telemetry")" -eq 4 ]] \
  && ruby -c "$telemetry" >/dev/null; then
  pass "playbook-telemetry moves to v tags, livecheck included"
else
  fail "playbook-telemetry moves to v tags, livecheck included"
fi

if [[ "${1:-}" = "--keep" ]]; then
  cp "$filled" "$root/Formula/playbook.rb"
  cp "$pbtop" "$root/Formula/pbtop.rb"
  printf 'Left Formula/playbook.rb with a filled block and Formula/pbtop.rb from the template for the style check.\n'
fi

if [[ "$failures" -ne 0 ]]; then
  printf '%d failed\n' "$failures"
  exit 1
fi
printf 'all passed\n'
