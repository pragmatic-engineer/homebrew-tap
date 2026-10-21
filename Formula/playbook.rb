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
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.39.0/playbook-0.39.0-aarch64-apple-darwin"
      sha256 "f2f02d62c110a117aeaf703adf244cdd870c85a263ec7c62e39e96e17c2fd2ff"
      resource "pbdoc" do
        url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.39.0/pbdoc-0.39.0-aarch64-apple-darwin.tar.gz"
        sha256 "2c31692d5f05837f341bd2d36b7e0e93e380769ce39484e699b323edf81583f4"
      end
    else
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.39.0/playbook-0.39.0-x86_64-apple-darwin"
      sha256 "42ff9d657fe4f126265998c2e2164128706d209fc6b1931a10019181ce17845c"
      resource "pbdoc" do
        url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.39.0/pbdoc-0.39.0-x86_64-apple-darwin.tar.gz"
        sha256 "8676c663347d36321fbf4f2ea957aa0729624a0b42e872ccf511eeda14a183d1"
      end
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.39.0/playbook-0.39.0-aarch64-unknown-linux-musl"
      sha256 "fb3382fc07566c4ff955a35bf65db4ed6f2edb1022e2028655d3913d1561f4d6"
      resource "pbdoc" do
        url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.39.0/pbdoc-0.39.0-aarch64-unknown-linux-musl.tar.gz"
        sha256 "64554a2ec9726c1623ca08805bc92caa8d94e27569903aa8df2d71e36eb93137"
      end
    else
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.39.0/playbook-0.39.0-x86_64-unknown-linux-musl"
      sha256 "8b78e65032b3d8c8155fdae84b2d8bc65b6f0ab692424ce2e5cfdaff3a6b5f13"
      resource "pbdoc" do
        url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.39.0/pbdoc-0.39.0-x86_64-unknown-linux-musl.tar.gz"
        sha256 "4b3b4750d738cfddacfc5949aaf5d523f6e61c9aeb8e83b8d49c38ddfa349ece"
      end
    end
  end

  def install
    bin.install Dir["playbook-*"].first => "playbook"
    bin.install_symlink "playbook" => "pb"
    resource("pbdoc").stage do
      bin.install "pbdoc"
      doc.install "NOTICE-pbdoc"
    end
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
    assert_match version.to_s, shell_output("#{bin}/pbdoc --version")
  end
end
