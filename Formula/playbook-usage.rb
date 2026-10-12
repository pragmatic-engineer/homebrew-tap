class PlaybookUsage < Formula
  desc "Token and cost usage dashboard for Claude Code sessions"
  homepage "https://github.com/pragmatic-engineer/playbook-usage"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/pragmatic-engineer/playbook-usage/releases/download/v0.1.1/playbook-usage-0.1.1-aarch64-apple-darwin"
      sha256 "6392ca360f5100eec4bf3ba5697e649f65467051b2bef86b6cb77a5644b6bd0a"

      resource "pbtop" do
        url "https://github.com/pragmatic-engineer/playbook-usage/releases/download/v0.1.1/pbtop-0.1.1-aarch64-apple-darwin"
        sha256 "8db19f48017e84a61c62555ab5b60e2c4b42fd0384a4f4972614309a224a240f"
      end
    else
      url "https://github.com/pragmatic-engineer/playbook-usage/releases/download/v0.1.1/playbook-usage-0.1.1-x86_64-apple-darwin"
      sha256 "b78afdfd44610258bb34341dee7145f622160fce9bdfb197aab98ce6f72934a4"

      resource "pbtop" do
        url "https://github.com/pragmatic-engineer/playbook-usage/releases/download/v0.1.1/pbtop-0.1.1-x86_64-apple-darwin"
        sha256 "ed2a949f90c2fddad9277e35fbff2201287760cb3527e7ac64bb9cf7fb52bbee"
      end
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/pragmatic-engineer/playbook-usage/releases/download/v0.1.1/playbook-usage-0.1.1-aarch64-unknown-linux-musl"
      sha256 "a57796f64b9b94c6552e9b68323e34e08a6408dad12c2f5bb48b1b0ae77514ba"

      resource "pbtop" do
        url "https://github.com/pragmatic-engineer/playbook-usage/releases/download/v0.1.1/pbtop-0.1.1-aarch64-unknown-linux-musl"
        sha256 "b7fbe329222c0fa056f61fd12ec6ab400e91d7770de4d46434a2ad7e7ad42abd"
      end
    else
      url "https://github.com/pragmatic-engineer/playbook-usage/releases/download/v0.1.1/playbook-usage-0.1.1-x86_64-unknown-linux-musl"
      sha256 "8d750ff1f8bcf20e6a13493b5d3211c3a178bce982160a0d9916e4cfd7545a8f"

      resource "pbtop" do
        url "https://github.com/pragmatic-engineer/playbook-usage/releases/download/v0.1.1/pbtop-0.1.1-x86_64-unknown-linux-musl"
        sha256 "fa0d545c4d302238374dbc61babeee90682afaf9dabe6fdb7b6f5c60f596cf87"
      end
    end
  end

  def install
    bin.install Dir["playbook-usage-*"].first => "playbook-usage"
    resource("pbtop").stage do
      bin.install Dir["pbtop-*"].first => "pbtop"
    end
  end

  def caveats
    <<~EOS
      `pbtop` is a short alias for `playbook-usage`. Both are installed.
      Run either one to open the terminal view of your Claude Code usage.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/playbook-usage --version")
    assert_match version.to_s, shell_output("#{bin}/pbtop --version")
  end
end
