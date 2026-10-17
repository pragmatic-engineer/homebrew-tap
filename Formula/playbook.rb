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
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.36.0/playbook-0.36.0-aarch64-apple-darwin"
      sha256 "2a60ba0aa0880d907948cf818dae0557de7162e0ff4bcae6007cf738dd4c4211"
    else
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.36.0/playbook-0.36.0-x86_64-apple-darwin"
      sha256 "9d5cf25f987c024161863fc3856865088adf8ce447d873c71719a1b161a47d62"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.36.0/playbook-0.36.0-aarch64-unknown-linux-musl"
      sha256 "d07c456b03786e3aca51739d69bddcbe1a1b7fe0eae4cd7f44a3d0499cb5d9cf"
    else
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.36.0/playbook-0.36.0-x86_64-unknown-linux-musl"
      sha256 "89c22cfeefd518db77aa6c3847eb709adda04549d5b469722dd75f48e7f6430a"
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
