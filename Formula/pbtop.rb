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
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.35.0/pbtop-0.35.0-aarch64-apple-darwin.tar.gz"
      sha256 "18ccbc4612d82a901ff6e11b48dbea1f4de7ac41158107de277688ae73462c1d"
    else
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.35.0/pbtop-0.35.0-x86_64-apple-darwin.tar.gz"
      sha256 "948c0ae78b27f5d7fa9b26554b8b4e03b1ea96ac005463e79acd177d0aa900a6"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.35.0/pbtop-0.35.0-aarch64-unknown-linux-musl.tar.gz"
      sha256 "a756dee220ce04141607fbe4907305f69c8c8812f2848c51ad44579612e106e7"
    else
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.35.0/pbtop-0.35.0-x86_64-unknown-linux-musl.tar.gz"
      sha256 "2c09db9d8646bc9bb3ff9d8aa63bd8ab132dc6adb7824ffb8de427369e9d35ac"
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
