class Playbook < Formula
  desc "Claude Code plugin toolkit: hooks, launcher, and installer in one binary"
  homepage "https://github.com/pragmatic-engineer/playbook"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_releases
    regex(/^v(\d+(?:\.\d+)+)$/i)
  end

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.25.0/playbook-0.25.0-aarch64-apple-darwin"
      sha256 "2a17ed3a6a922811c9f1632306071cc125b8bf5636c2d1933c66b8c520262be5"
    else
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.25.0/playbook-0.25.0-x86_64-apple-darwin"
      sha256 "f7ee19c0aa9fe0e4715192b8ce48376a64c3b16a5c57daf1798839fbf527f705"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.25.0/playbook-0.25.0-aarch64-unknown-linux-musl"
      sha256 "1eed636e88a3cfe8e8e24d78400464938893b2ebec3f9fe0d59bd0e53d19ceff"
    else
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.25.0/playbook-0.25.0-x86_64-unknown-linux-musl"
      sha256 "d3f11b0151a08de708c27c4273ef0141bd24e28bec0a6b47bd779b6073d48250"
    end
  end

  def install
    bin.install Dir["playbook-*"].first => "playbook"
    bin.install_symlink "playbook" => "pb"
  end

  def caveats
    <<~EOS
      Run `playbook init` once to wire the safety hooks and put playbook on PATH
      for every shell, including the ones Claude Code starts for hooks.
      Start sessions with `playbook cc` or `playbook ccd`. `pb` is a short alias,
      so `pb cc` and `pb ccd` work too.
      Installing never edits your Claude Code settings. Upgrade with `brew upgrade playbook`.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/playbook --version")
    assert_match version.to_s, shell_output("#{bin}/pb --version")
  end
end
