class Playbook < Formula
  desc "Claude Code plugin toolkit: hooks, launcher, and installer in one binary"
  homepage "https://github.com/pragmatic-engineer/playbook"
  license "Apache-2.0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.23.0/playbook-0.23.0-aarch64-apple-darwin"
      sha256 "5354444d27c15f0f461082e39aecd8f31c765aff84e25e9e16564339c6ee2d92"
    else
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.23.0/playbook-0.23.0-x86_64-apple-darwin"
      sha256 "6c02ce4113bfe2d84dcd5f2eeb27d042a762c823c7433d44ce7f228f012fc723"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.23.0/playbook-0.23.0-aarch64-unknown-linux-musl"
      sha256 "d0fe9e74198d485ee696a8151edaa9797ee66987248d49c21ce789d6b18eaef0"
    else
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.23.0/playbook-0.23.0-x86_64-unknown-linux-musl"
      sha256 "50cf00ba8fc413b6ec41f46eddba78f4896f0fbe7dd65fec7c98c2693ddb7b2e"
    end
  end

  def install
    bin.install Dir["playbook-*"].first => "playbook"
  end

  def caveats
    <<~EOS
      Run `playbook init` once to wire the safety hooks and put playbook on PATH
      for every shell, including the ones Claude Code starts for hooks.
      Until then the Claude Code plugin works, without the ccc and ccd launcher.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/playbook --version")
  end
end
