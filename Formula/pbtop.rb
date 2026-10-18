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
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.37.0/pbtop-0.37.0-aarch64-apple-darwin.tar.gz"
      sha256 "05b2370b3b361e90f6a67a526afd6762ed2f9b08e46422f8a85ebc910b86c886"
    else
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.37.0/pbtop-0.37.0-x86_64-apple-darwin.tar.gz"
      sha256 "ac94c08bbd3640a639585ad3d81860168e4eed02cc70d131bb54812838693af7"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.37.0/pbtop-0.37.0-aarch64-unknown-linux-musl.tar.gz"
      sha256 "62f8ed1d4febf823eaf54bd472bb5123353c85802c47874ec8b9d37c28107096"
    else
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.37.0/pbtop-0.37.0-x86_64-unknown-linux-musl.tar.gz"
      sha256 "8e4071b3a4c98ac597952c4c1f76cf81a2b8ffeeea4c393115af2099a19e8161"
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
