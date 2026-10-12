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
      url "https://github.com/pragmatic-engineer/playbook-telemetry/releases/download/v0.1.5/playbook-telemetry-0.1.5-aarch64-apple-darwin.tar.gz"
      sha256 "9b66798556302195d8847e9f2fe222285a5c3f6af5c6569c2addd77a18884896"
    else
      url "https://github.com/pragmatic-engineer/playbook-telemetry/releases/download/v0.1.5/playbook-telemetry-0.1.5-x86_64-apple-darwin.tar.gz"
      sha256 "f9af9d517e486cbac1c76625b0ae9b429cd84b0a25d8d8002c8268f6f5a117ed"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/pragmatic-engineer/playbook-telemetry/releases/download/v0.1.5/playbook-telemetry-0.1.5-aarch64-unknown-linux-musl.tar.gz"
      sha256 "94647b67c6611e53001af4f6021eb0d0534ad59e734092fd3a3b7b29fac26ad8"
    else
      url "https://github.com/pragmatic-engineer/playbook-telemetry/releases/download/v0.1.5/playbook-telemetry-0.1.5-x86_64-unknown-linux-musl.tar.gz"
      sha256 "5385328367c1ce6df49afc9049a0527f3e208524750d005f231be68bf32252d4"
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
