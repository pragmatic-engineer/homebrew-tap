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
      url "https://github.com/pragmatic-engineer/playbook-telemetry/releases/download/v0.1.7/playbook-telemetry-0.1.7-aarch64-apple-darwin.tar.gz"
      sha256 "f2d4d09395e5368555941943bb2775ada8f83c631551cfd231fc99cbeb2f2a7b"
    else
      url "https://github.com/pragmatic-engineer/playbook-telemetry/releases/download/v0.1.7/playbook-telemetry-0.1.7-x86_64-apple-darwin.tar.gz"
      sha256 "16df77d0866e3e7dcf8d4a1f7d71b3e3377e32e757b0b9e6f080ae0e9e584942"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/pragmatic-engineer/playbook-telemetry/releases/download/v0.1.7/playbook-telemetry-0.1.7-aarch64-unknown-linux-musl.tar.gz"
      sha256 "7d3943ebe062ef32199a60b5ac76801b02cc8f383236e3a66308531f7297218b"
    else
      url "https://github.com/pragmatic-engineer/playbook-telemetry/releases/download/v0.1.7/playbook-telemetry-0.1.7-x86_64-unknown-linux-musl.tar.gz"
      sha256 "753b77e7e4945444edbceb3da43e043735b764aee6f868e3ffaedd7d465a64bb"
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
