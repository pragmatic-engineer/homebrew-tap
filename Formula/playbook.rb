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
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.37.0/playbook-0.37.0-aarch64-apple-darwin"
      sha256 "f4d47a2ac72f57240fae57c1987e563582d5d5af2623003175bd9f4d8cca3654"
    else
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.37.0/playbook-0.37.0-x86_64-apple-darwin"
      sha256 "ea48c47ce0a326cecc9663a8ff684f6d3d460e7f862dadd78c8e34c3ea8ac5cd"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.37.0/playbook-0.37.0-aarch64-unknown-linux-musl"
      sha256 "f0869c67ad7213ab50acae24252f815f4f8ee31a041539f3ac334aabd3671385"
    else
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.37.0/playbook-0.37.0-x86_64-unknown-linux-musl"
      sha256 "b03223a35756d5a5d1d4640491038f38c1ad36b0f7c17474c30e2efd96dbabda"
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
