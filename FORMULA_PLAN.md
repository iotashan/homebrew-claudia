# Claudia Homebrew Formula Implementation Plan

## Overview
This document outlines the complete plan for creating a Homebrew formula for Claudia MCP server.

## Formula Architecture

### 1. Basic Structure
```ruby
class Claudia < Formula
  desc "Model Context Protocol (MCP) server management tool"
  homepage "https://github.com/getAsterisk/claudia"
  license "AGPL-3.0"
  
  # Version and URL (to be determined)
  url "https://github.com/getAsterisk/claudia/archive/refs/tags/v#{version}.tar.gz"
  sha256 "..."
  
  # Dependencies
  # Test block
  # Install method
end
```

### 2. Dependency Management

#### Node.js Strategy
- Primary: Check for nvm-managed Node installation
- Fallback: Use Homebrew's node formula
- Implementation:
```ruby
def node_path
  if ENV["NVM_DIR"] && File.exist?("#{ENV["NVM_DIR"]}/nvm.sh")
    # Find nvm's active Node
    Dir.glob("#{ENV["NVM_DIR"]}/versions/node/*/bin/node").max
  else
    Formula["node"].opt_bin/"node"
  end
end
```

#### Bun Runtime
Since Bun is not in Homebrew core, we'll download it as a resource:
```ruby
resource "bun" do
  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/oven-sh/bun/releases/download/bun-v1.1.42/bun-darwin-aarch64.zip"
      sha256 "..."
    else
      url "https://github.com/oven-sh/bun/releases/download/bun-v1.1.42/bun-darwin-x64.zip"
      sha256 "..."
    end
  end
end
```

#### Other Dependencies
```ruby
depends_on "rust" => :build
depends_on "node" => :build  # Fallback only
depends_on "pkg-config" => :build  # If needed
```

### 3. Build Process

The install method will:
1. Stage Bun resource
2. Set up build environment
3. Run Claudia's build scripts
4. Install the resulting binary

```ruby
def install
  # Extract and prepare Bun
  resource("bun").stage do
    bin.install "bun"
  end
  
  # Set up environment
  ENV.prepend_path "PATH", bin
  ENV["NODE_PATH"] = node_path.dirname
  
  # Build process
  system "bun", "install"
  system "bun", "run", "scripts/fetch-and-build.js", "--", "macos"
  system "bun", "run", "build"
  
  # Install binary
  bin.install "src-tauri/target/release/claudia"
end
```

### 4. Testing Strategy

Following Homebrew best practices:
```ruby
test do
  # Test 1: Basic functionality
  assert_match "Claudia", shell_output("#{bin}/claudia --version")
  
  # Test 2: Configuration creation
  testpath = testpath/"test_config"
  testpath.mkpath
  
  ENV["HOME"] = testpath
  system bin/"claudia", "init"
  assert_predicate testpath/".claudia/config.json", :exist?
  
  # Test 3: Server management (without actual connection)
  output = shell_output("#{bin}/claudia server list 2>&1")
  assert_match "No servers configured", output
  
  # Test 4: Error handling
  output = shell_output("#{bin}/claudia server test nonexistent 2>&1", 1)
  assert_match "Server not found", output
end
```

### 5. Caveats

```ruby
def caveats
  <<~EOS
    Claudia requires Claude Code CLI to be installed separately.
    Please install it from: https://claude.ai/download
    
    To get started:
      claudia init
      claudia server add
  EOS
end
```

## Implementation Steps

1. **Version Discovery**
   - Check for stable releases on GitHub
   - Determine versioning strategy (tags vs commits)

2. **Formula Creation**
   - Create initial formula file
   - Add all sections documented above
   - Calculate SHA256 checksums

3. **Local Testing**
   - Run `brew install --build-from-source ./Formula/claudia.rb`
   - Debug any build issues
   - Verify all tests pass

4. **Audit & Refinement**
   - Run `brew audit --new --strict claudia`
   - Fix any style or convention issues
   - Optimize build process

5. **CI/CD Setup**
   - Create GitHub Actions workflow
   - Test on multiple macOS versions
   - Automate formula updates

## Known Challenges

1. **Bun Dependency**: Not in Homebrew, must download directly
2. **Claude Code CLI**: Cannot be installed via Homebrew, must be caveat
3. **Version Tags**: Need to verify Claudia has stable releases
4. **Build Complexity**: Tauri + TypeScript + Rust toolchain

## Success Criteria

- [ ] Formula installs without errors
- [ ] All tests pass
- [ ] `brew audit --strict` passes
- [ ] Works on macOS 11+ (Intel and Apple Silicon)
- [ ] Clear documentation and caveats
- [ ] Users can successfully manage MCP servers

## Future Improvements

1. Switch to binary distribution when available
2. Submit to homebrew-core after stability proven
3. Add bottle (pre-compiled binary) support
4. Consider cask formula if GUI elements added