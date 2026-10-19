class Pbtop < Formula
  desc "Terminal dashboard of Claude Code token use and cost"
  homepage "https://github.com/pragmatic-engineer/playbook"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_releases
    regex(/^v(\d+(?:\.\d+)+)$/i)
  end

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.38.0/pbtop-0.38.0-aarch64-apple-darwin.tar.gz"
      sha256 "8c7ce00086d1c7f05d0e8478384b01c4e5583ca3e6ff3226600f5a2109e78d0c"
    else
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.38.0/pbtop-0.38.0-x86_64-apple-darwin.tar.gz"
      sha256 "7f40d4636a5e977707a4bdd6b38bb44aaaac6c2ab1ccfd5bf4a6c11e5c035bdc"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.38.0/pbtop-0.38.0-aarch64-unknown-linux-musl.tar.gz"
      sha256 "695a35bd0d82878303ed64175f209518c088084dfaa287d3b20329efe9a0c676"
    else
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.38.0/pbtop-0.38.0-x86_64-unknown-linux-musl.tar.gz"
      sha256 "39075fecab24bb4507817a0e48f791cb8bb9b630ee2f8c3193f8653cbe27ac85"
    end
  end

  def install
    bin.install "pbtop"
  end

  def caveats
    <<~EOS
      Run `pbtop` to start.
      Release notes: https://github.com/pragmatic-engineer/playbook/releases/tag/v#{version}
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/pbtop --version")
  end
end
