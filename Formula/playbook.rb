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
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.35.0/playbook-0.35.0-aarch64-apple-darwin"
      sha256 "8edbdde2b1c672b624186447eb0089db8245fa8dc67802557ecad8ae375d45f6"
    else
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.35.0/playbook-0.35.0-x86_64-apple-darwin"
      sha256 "52b91ac8d56c0f33f7f6ab4e4717afa799891637242f533f739079cbeb3ab34f"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.35.0/playbook-0.35.0-aarch64-unknown-linux-musl"
      sha256 "8f23801404fb250727b26f2a72b974c88ff0f2378d315bbb3de2afac1877929c"
    else
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.35.0/playbook-0.35.0-x86_64-unknown-linux-musl"
      sha256 "ae75336441f84d0997e2ac7957781998824522c08f252cdc1cb799e471723896"
    end
  end

  def install
    bin.install Dir["playbook-*"].first => "playbook"
    bin.install_symlink "playbook" => "pb"
  end

  def caveats
    <<~EOS
      Run `playbook init` once (`playbook setup` from 0.35.0). In a terminal
      it asks before it adds the safety hooks to ~/.claude/settings.json, and
      it puts playbook on PATH for every shell, including the ones Claude Code
      starts for hooks.
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
