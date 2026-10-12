class Playbook < Formula
  desc "Claude Code plugin toolkit: hooks, launcher, and installer in one binary"
  homepage "https://github.com/pragmatic-engineer/playbook"
  license "Apache-2.0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.24.0/playbook-0.24.0-aarch64-apple-darwin"
      sha256 "f58c1d5f9a4b0e5d0832c93dd9ed3697bd79fa07bd00d2121db164d3cf5e0b3c"
    else
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.24.0/playbook-0.24.0-x86_64-apple-darwin"
      sha256 "dddff265fe45fb2787f67871dc1e4c96d585b6fc1fd7545eae158fc2850710fc"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.24.0/playbook-0.24.0-aarch64-unknown-linux-musl"
      sha256 "f9b9a853010663aa5fdc15cb01e2b4cadab5e653b2a1cbbe3fd62cf5f0b0268a"
    else
      url "https://github.com/pragmatic-engineer/playbook/releases/download/v0.24.0/playbook-0.24.0-x86_64-unknown-linux-musl"
      sha256 "605853226ee8c2a573d0bd5d2077b95b15d9e6aafe8737e97159e629b22cdc25"
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
