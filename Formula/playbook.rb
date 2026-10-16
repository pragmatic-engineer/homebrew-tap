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
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.34.0/playbook-0.34.0-aarch64-apple-darwin"
      sha256 "d8f4a1ba48581c003fe6706b017942a1333a5ab796084d5a39728ea321404667"
    else
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.34.0/playbook-0.34.0-x86_64-apple-darwin"
      sha256 "13e952483b31d4ad910cab228e6f68cff9382bd3622704896a49efef3397527a"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.34.0/playbook-0.34.0-aarch64-unknown-linux-musl"
      sha256 "2f64cf63f765def22f5d91527dd7dc2a212673fbee3d9695f05f3505dae884f2"
    else
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.34.0/playbook-0.34.0-x86_64-unknown-linux-musl"
      sha256 "3c5123bd61cfd5b45ad021b456df2e34b4898a7e72fbdddd855dd0e059f94ec5"
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
