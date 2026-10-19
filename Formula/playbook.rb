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
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.38.0/playbook-0.38.0-aarch64-apple-darwin"
      sha256 "b45f54a638fe0fafd3313e9e59f5c4d99ac42c4a2a4e53bd3b948b21ee0b42d2"
    else
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.38.0/playbook-0.38.0-x86_64-apple-darwin"
      sha256 "efefea8a124de2d7b42af846cd08663ef8a2fcd3afa8a3998dfc295adc10dfb5"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.38.0/playbook-0.38.0-aarch64-unknown-linux-musl"
      sha256 "89ac2760f0fd763969f50893f607edec0725b523a8a273e22d6758a574c60dde"
    else
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.38.0/playbook-0.38.0-x86_64-unknown-linux-musl"
      sha256 "13a32843fdcfdad712f2854bc5cbe343930dcaa0ab37f73d30c972f6d94fb521"
    end
  end

  def install
    bin.install Dir["playbook-*"].first => "playbook"
    bin.install_symlink "playbook" => "pb"
  end

  def caveats
    <<~EOS
      Run `playbook setup` once (`playbook init` on 0.34 and earlier). In a
      terminal it asks before it adds the safety hooks to ~/.claude/settings.json,
      and it puts playbook on PATH for every shell, including the ones Claude
      Code starts for hooks.
      If you used the old playbook-hooks plugin, run
      `claude plugin uninstall playbook-hooks@pragmatic-engineer` first.
      Start sessions with `playbook cc` or `playbook ccd`. `pb` is a short alias,
      so `pb cc` and `pb ccd` work too.
      Installing never edits your Claude Code settings. Upgrade with `brew upgrade playbook`.
      Release notes: https://github.com/pragmatic-engineer/playbook/releases/tag/v#{version}
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/playbook --version")
    assert_match version.to_s, shell_output("#{bin}/pb --version")
  end
end
