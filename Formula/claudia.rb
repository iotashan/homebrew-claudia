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
        opoo "The app bundle is available at: #{app_path}"
        
        # Try to create DMG manually
        ohai "Attempting to create DMG manually..."
        dmg_name = "Claudia_0.1.0_#{Hardware::CPU.arch}.dmg"
        dmg_dir = buildpath/"src-tauri/target/release/bundle/dmg"
        dmg_path = dmg_dir/dmg_name
        
        # Ensure the directory exists and remove any existing DMG
        dmg_dir.mkpath
        dmg_path.unlink if dmg_path.exist?
        
        # Create a simple DMG from the app bundle
        system "hdiutil", "create", "-volname", "Claudia", "-srcfolder", app_path, 
               "-ov", "-format", "UDZO", dmg_path
        
        unless File.exist?(dmg_path)
          odie "Failed to create DMG installer. App bundle is at: #{app_path}"
        end
      else
        odie "Build failed: neither DMG nor app bundle was found!"
      end
    end
    
    ohai "Found installer: #{File.basename(dmg_path)}"
    
    # Create installers directory and copy the .dmg
    (prefix/"installers").mkpath
    installer_name = File.basename(dmg_path)
    installer_dest = prefix/"installers"/installer_name
    cp dmg_path, installer_dest
    
    # Store the installer path for use in caveats
    @installer_path = installer_dest
    
    # Create a helper script to output the installer path
    (bin/"claudia-installer-path").write <<~EOS
      #!/usr/bin/env bash
      echo "#{installer_dest}"
    EOS
    chmod 0755, bin/"claudia-installer-path"
    
    # Also create a convenience script to open the installer
    (bin/"claudia-install").write <<~EOS
      #!/usr/bin/env bash
      INSTALLER_PATH="#{installer_dest}"
      if [[ -f "$INSTALLER_PATH" ]]; then
        echo "Opening Claudia installer..."
        open "$INSTALLER_PATH"
      else
        echo "Error: Installer not found at $INSTALLER_PATH"
        exit 1
      fi
    EOS
    chmod 0755, bin/"claudia-install"
  end

  def caveats
    installer_msg = if @installer_path && File.exist?(@installer_path)
      <<~MSG
        Claudia installer has been built and saved to:
          #{@installer_path}

        To install Claudia, you can either:
          - Run: claudia-install
          - Run: open "#{@installer_path}"
          - Double-click the .dmg file in Finder

        To get the installer path programmatically:
          claudia-installer-path
      MSG
    else
      <<~MSG
        Note: The Claudia installer location will be displayed after installation.
      MSG
    end

    <<~EOS
      #{installer_msg}

      Claudia requires Claude Code CLI to be installed separately.
      Please install it from: https://claude.ai/download

      For more information, visit:
        https://github.com/getAsterisk/claudia
    EOS
  end

  test do
    # Test 1: Check if the helper scripts exist and are executable
    assert_path_exists bin/"claudia-installer-path"
    assert_predicate bin/"claudia-installer-path", :executable?
    
    assert_path_exists bin/"claudia-install"
    assert_predicate bin/"claudia-install", :executable?

    # Test 2: Check if installer path script returns a path
    output = shell_output("#{bin}/claudia-installer-path")
    assert_match %r{/installers/.*\.dmg}, output

    # Test 3: Verify the installer exists at the reported path
    installer_path = output.strip
    assert_match "Claudia", installer_path
  end
end