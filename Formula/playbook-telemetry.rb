class PlaybookTelemetry < Formula
  desc "Usage and cost tracking for Claude Code in a terminal dashboard"
  homepage "https://github.com/pragmatic-engineer/playbook-telemetry"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/pragmatic-engineer/playbook-telemetry/releases/download/v0.1.6/playbook-telemetry-0.1.6-aarch64-apple-darwin.tar.gz"
      sha256 "ff6cc047d8c3d7f06304a7e1e76f39e1837a90d5e2d1e7ad920765466c81f9cc"
    else
      url "https://github.com/pragmatic-engineer/playbook-telemetry/releases/download/v0.1.6/playbook-telemetry-0.1.6-x86_64-apple-darwin.tar.gz"
      sha256 "e2a8e8f089fde850b551c7f1a523913d4f22b12926b0346c0b882d38b2c6c25d"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/pragmatic-engineer/playbook-telemetry/releases/download/v0.1.6/playbook-telemetry-0.1.6-aarch64-unknown-linux-musl.tar.gz"
      sha256 "8415ffda1fdb8a0669f022c74cb5492e91fc1b62a06f6926bedb96c22447c866"
    else
      url "https://github.com/pragmatic-engineer/playbook-telemetry/releases/download/v0.1.6/playbook-telemetry-0.1.6-x86_64-unknown-linux-musl.tar.gz"
      sha256 "28eeaca29a49e1aadf12769849e5f484727d9d45644d346137bf140608d65dd0"
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
