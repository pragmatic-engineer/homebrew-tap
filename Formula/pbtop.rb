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
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.39.0/pbtop-0.39.0-aarch64-apple-darwin.tar.gz"
      sha256 "ddae670dbc5ef3f72225567d533345278acdf3b5535a54db275944a284586106"
    else
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.39.0/pbtop-0.39.0-x86_64-apple-darwin.tar.gz"
      sha256 "774a969ef7bf49924e942967c755cdb04de82e7e7252726ddb974eccd0bfb4e2"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.39.0/pbtop-0.39.0-aarch64-unknown-linux-musl.tar.gz"
      sha256 "f4f80e54d6e925f518c756df22fec6889223037769b8274755661e9dd29d9232"
    else
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.39.0/pbtop-0.39.0-x86_64-unknown-linux-musl.tar.gz"
      sha256 "ce806cdfdf28bab3923d715d11b3d45cebeb3b0224537f983bf31449acd192b7"
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
