class Claudia < Formula
  desc "Model Context Protocol (MCP) server management GUI (built from source)"
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
        sha256 "64a70fe290bd6391a09d555d4e4e1a8df56543e526bb1381ab344a385348572c"
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
      chmod 0755, buildpath/"bun-bin/bun"
    end

    # Prepare build environment
    ENV.prepend_path "PATH", buildpath/"bun-bin"
    ENV.prepend_path "PATH", node_bin
    ENV["RUST_BACKTRACE"] = "1"

    # Log the environment for debugging
    ohai "Building Claudia with:"
    ohai "Bun: #{buildpath/"bun-bin/bun"}"
    ohai "Node: #{node_bin}"
    ohai "Rust: #{which("rustc")}"

    # Install dependencies
    ohai "Installing dependencies..."
    system buildpath/"bun-bin/bun", "install"

    # Build Claudia using Tauri
    ohai "Building Claudia (this may take a while)..."
    begin
      system buildpath/"bun-bin/bun", "run", "tauri", "build"
    rescue => e
      opoo "Tauri build encountered an error: #{e.message}"
    end

    # Find the generated .dmg installer
    ohai "Looking for generated installer..."
    dmg_path = Dir.glob(buildpath/"src-tauri/target/release/bundle/dmg/*.dmg").first
    
    # If no DMG found, check for the app bundle
    if dmg_path.nil?
      app_path = buildpath/"src-tauri/target/release/bundle/macos/Claudia.app"
      if app_path.exist?
        opoo "DMG creation failed, but app bundle was built successfully"
        
        # Install the app bundle to the prefix
        ohai "Installing Claudia.app..."
        prefix.install app_path
        
        # Create a wrapper script that opens the app
        (bin/"claudia").write <<~EOS
          #!/usr/bin/env bash
          exec open "#{prefix}/Claudia.app" "$@"
        EOS
        chmod 0755, bin/"claudia"
        
        # Skip DMG creation and return early
        return
      else
        odie "Build failed: neither DMG nor app bundle was found!"
      end
    end
    
    # If we got here, DMG was created but we'll still use the app bundle approach
    # for consistency
    opoo "DMG was created but we'll install the app bundle for better Homebrew integration"
    
    app_path = buildpath/"src-tauri/target/release/bundle/macos/Claudia.app"
    if app_path.exist?
      # Install the app bundle to the prefix
      ohai "Installing Claudia.app..."
      prefix.install app_path
      
      # Create a wrapper script that opens the app
      (bin/"claudia").write <<~EOS
        #!/usr/bin/env bash
        exec open "#{prefix}/Claudia.app" "$@"
      EOS
      chmod 0755, bin/"claudia"
    else
      odie "Build succeeded but app bundle not found!"
    end
  end

  def caveats
    <<~EOS
      Claudia.app has been built from source and installed to:
        #{prefix}/Claudia.app

      To run Claudia:
        claudia

      This will open the Claudia GUI application.

      You can also:
        - Open directly: open #{prefix}/Claudia.app
        - Add to Applications folder: ln -sf #{prefix}/Claudia.app /Applications/
        - Add to Launchpad: open #{prefix}

      Note: This is a GUI application built as a formula (not a cask) because
      Claudia doesn't publish pre-built releases yet. Once releases are available,
      this may be converted to a cask for easier installation.

      Claudia requires Claude Code CLI to be installed separately.
      Please install it from: https://claude.ai/download

      For more information, visit:
        https://github.com/getAsterisk/claudia
    EOS
  end

  test do
    # Test 1: Check if the claudia launcher exists and is executable
    assert_path_exists bin/"claudia"
    assert_predicate bin/"claudia", :executable?
    
    # Test 2: Check if Claudia.app was installed
    assert_path_exists prefix/"Claudia.app"
    assert_path_exists prefix/"Claudia.app/Contents/MacOS/Claudia"
    
    # Test 3: Verify the launcher script contains the correct path
    launcher_content = File.read(bin/"claudia")
    assert_match prefix/"Claudia.app", launcher_content
  end
end