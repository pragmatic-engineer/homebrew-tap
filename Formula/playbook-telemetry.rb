class PlaybookTelemetry < Formula
  desc "Usage and cost tracking for Claude Code in a terminal dashboard"
  homepage "https://github.com/pragmatic-engineer/playbook-telemetry"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_releases
    regex(/^(?:telemetry-)?v(\d+(?:\.\d+)+)$/i)
  end

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/pragmatic-engineer/playbook/releases/download/telemetry-v0.2.0/playbook-telemetry-0.2.0-aarch64-apple-darwin.tar.gz"
      sha256 "a52313290edccddd2fc7079fb8af3be66259a070da8734785aca75aaf8d03150"
    else
      url "https://github.com/pragmatic-engineer/playbook/releases/download/telemetry-v0.2.0/playbook-telemetry-0.2.0-x86_64-apple-darwin.tar.gz"
      sha256 "52275898fd6dc612c3c7c9cd670901c98924241dc6085c788c6f81e67fdc1381"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/pragmatic-engineer/playbook/releases/download/telemetry-v0.2.0/playbook-telemetry-0.2.0-aarch64-unknown-linux-musl.tar.gz"
      sha256 "ddfab23a740074bde0704a191b685dc2c79ef9a444854e287e2e88f57cf4f36b"
    else
      url "https://github.com/pragmatic-engineer/playbook/releases/download/telemetry-v0.2.0/playbook-telemetry-0.2.0-x86_64-unknown-linux-musl.tar.gz"
      sha256 "b7d76b17817196bb755b0af94751471bbc5ce9ef2419fae668a1cacdaf0b275a"
    end
  end

  def install
    bin.install "playbook-telemetry", "pbtop"
  end

  def caveats
    <<~EOS
      Run `pbtop` to start. It is the short alias of `playbook-telemetry`,
      which is the long name for scripts. Both are installed.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/playbook-telemetry --version")
    assert_match version.to_s, shell_output("#{bin}/pbtop --version")
  end
end
