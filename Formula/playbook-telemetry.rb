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
      url "https://github.com/pragmatic-engineer/playbook-telemetry/releases/download/v0.1.4/playbook-telemetry-0.1.4-aarch64-apple-darwin.tar.gz"
      sha256 "b5166ea5db3db6973b24cbcce86b6daeb7283b601ba6f70cae1d561763a5aeee"
    else
      url "https://github.com/pragmatic-engineer/playbook-telemetry/releases/download/v0.1.4/playbook-telemetry-0.1.4-x86_64-apple-darwin.tar.gz"
      sha256 "ed8f2e78caf558064cdd28ec0b4d375f1ca815b665c0bee1404b84fdfa978c95"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/pragmatic-engineer/playbook-telemetry/releases/download/v0.1.4/playbook-telemetry-0.1.4-aarch64-unknown-linux-musl.tar.gz"
      sha256 "24985dd2b35ffef25d698a1c1d9c19e63daef89202483dae702e08bde08cd88c"
    else
      url "https://github.com/pragmatic-engineer/playbook-telemetry/releases/download/v0.1.4/playbook-telemetry-0.1.4-x86_64-unknown-linux-musl.tar.gz"
      sha256 "0624f99a5bcb748b3687a6a66ac7dc482dda83dad56fa9afed7f763834466c88"
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
