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
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.26.0/playbook-0.26.0-aarch64-apple-darwin"
      sha256 "3e546e0eb3488a83322092714057ffb869775d3ce50afa7489cb69ea112dadd2"
    else
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.26.0/playbook-0.26.0-x86_64-apple-darwin"
      sha256 "d8ceaaaeac1a813661f48014970d80b28276f5884822e792427c758c615086ed"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.26.0/playbook-0.26.0-aarch64-unknown-linux-musl"
      sha256 "73978eeb563795afc03bd087644810351e5f19e70e47f4db09918b2529b4da86"
    else
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.26.0/playbook-0.26.0-x86_64-unknown-linux-musl"
      sha256 "33a100340d122ebf14f18da86c008e9f1a9c8fe2fead545921104ff8d3eb79c2"
    end
  end

  def install
    bin.install Dir["playbook-*"].first => "playbook"
    bin.install_symlink "playbook" => "pb"
  end

  def caveats
    <<~EOS
      Run `playbook init` once. In a terminal it asks before it adds the safety
      hooks to ~/.claude/settings.json, and it puts playbook on PATH for every
      shell, including the ones Claude Code starts for hooks.
      If you used the old playbook-hooks plugin, run
      `claude plugin uninstall playbook-hooks@pragmatic-engineer` first.
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
