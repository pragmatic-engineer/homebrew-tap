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
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.36.0/pbtop-0.36.0-aarch64-apple-darwin.tar.gz"
      sha256 "35edfe43735a1788816812a38d22e16bd2f752d864154cca5796cabc89d03f40"
    else
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.36.0/pbtop-0.36.0-x86_64-apple-darwin.tar.gz"
      sha256 "c8a72b3ce1497f383c1a6089d1b2a580b35565bcc42a167152373a729be10805"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.36.0/pbtop-0.36.0-aarch64-unknown-linux-musl.tar.gz"
      sha256 "50699af41d042558d4c2993e250cbd78c2425b1ffce453f9b3cd052f69ca4868"
    else
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.36.0/pbtop-0.36.0-x86_64-unknown-linux-musl.tar.gz"
      sha256 "3bca3fa3c2ac9057c83e5064468f0735f36a382eaaeaab0392d467dfb2e2c503"
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
