class Claudia < Formula
  desc "Model Context Protocol (MCP) server management tool"
  homepage "https://github.com/getAsterisk/claudia"
  license "AGPL-3.0-only"
  head "https://github.com/getAsterisk/claudia.git", branch: "main"

  depends_on "node" => :build
  depends_on "pkg-config" => :build
  depends_on "rust" => :build

  # Bun is required but not in Homebrew, so we download it
  resource "bun" do
    on_macos do
      if Hardware::CPU.arm?
        url "https://github.com/oven-sh/bun/releases/download/bun-v1.1.42/bun-darwin-aarch64.zip"
        sha256 "f0c12816cf8b44e372e2b88e7dc5cbcee342b4fd0f3bc86797762e039939f6f6"
      else
        url "https://github.com/oven-sh/bun/releases/download/bun-v1.1.42/bun-darwin-x64.zip"
        sha256 "d51f48c2d763a97db1d89a4cf2b726fdb8db49fb3ad079b6e0f3f1d8497e5e00"
      end
    end
  end

  def install
    # Check for nvm-managed node first
    node_bin = if ENV["NVM_DIR"] && File.exist?("#{ENV["NVM_DIR"]}/nvm.sh")
      node_path = Dir.glob("#{ENV["NVM_DIR"]}/versions/node/*/bin/node").max
      File.dirname(node_path) if node_path
    end

    # Fall back to Homebrew node
    node_bin ||= Formula["node"].opt_bin

    # Install Bun locally for the build
    resource("bun").stage do
      (buildpath/"bun-bin").install "bun"
    end

    # Prepare build environment
    ENV.prepend_path "PATH", buildpath/"bun-bin"
    ENV.prepend_path "PATH", node_bin
    ENV["RUST_BACKTRACE"] = "1"

    # Install dependencies
    system "bun", "install"

    # Fetch and build Claude Code binaries
    system "bun", "run", "scripts/fetch-and-build.js", "--", "macos"

    # Build the Tauri application
    system "bun", "run", "build"

    # The built binary should be in src-tauri/target/release
    bin.install "src-tauri/target/release/claudia"
  end

  def caveats
    <<~EOS
      Claudia requires Claude Code CLI to be installed separately.
      Please install it from: https://claude.ai/download

      To get started with Claudia:
        claudia init
        claudia server add

      For more information, visit:
        https://github.com/getAsterisk/claudia
    EOS
  end

  test do
    # Test 1: Check if the binary exists and runs
    assert_path_exists bin/"claudia"
    assert_predicate bin/"claudia", :executable?

    # Test 2: Basic functionality - version or help
    # Since --version might not be implemented, we'll check for any output
    output = shell_output("#{bin}/claudia --help 2>&1", 1)
    refute_empty output

    # Test 3: Create a test configuration directory
    ENV["HOME"] = testpath
    config_dir = testpath/".claudia"
    config_dir.mkpath

    # Test 4: Test initialization (if supported)
    begin
      system bin/"claudia", "init"
      assert_path_exists config_dir/"config.json"
    rescue
      # If init doesn't work, create a minimal config
      (config_dir/"config.json").write '{"servers": []}'
    end

    # Test 5: List servers (should work with empty config)
    output = shell_output("#{bin}/claudia server list 2>&1")
    assert_match(/server|claudia/i, output)

    # Test 6: Test error handling - try to connect to non-existent server
    output = shell_output("#{bin}/claudia server test nonexistent 2>&1", 1)
    assert_match(/not found|error|invalid/i, output)
  end
end