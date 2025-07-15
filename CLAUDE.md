# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Homebrew tap repository (iotashan/claudia) that provides a formula for installing [Claudia](https://github.com/getAsterisk/claudia), a Model Context Protocol (MCP) server management tool. 

**Current Status**: The formula is in development and currently installs a placeholder binary while the full build process is being implemented.

## Repository Structure

```
homebrew-claudia/
├── Formula/
│   ├── claudia.rb         # Main formula (head-only, placeholder build)
│   ├── claudia-simple.rb  # Simplified test formula
│   └── claudia-test.rb    # Test formula variant
├── FORMULA_PLAN.md        # Detailed implementation plan
├── README.md              # User documentation
└── CLAUDE.md              # This file
```

## Key Issues and Context

1. **Head-only Formula**: The formula is currently head-only (no stable release), which is why `brew install claudia` fails. Users must use `brew install --HEAD claudia` instead.

2. **Placeholder Binary**: The current formula installs a placeholder shell script instead of building the actual Claudia application from source.

3. **Complex Dependencies**: The full build requires:
   - Node.js (preferably from nvm, falls back to Homebrew)
   - Rust toolchain
   - Bun runtime (downloaded as a resource since it's not in Homebrew core)

4. **Build Process**: The actual build process (lines 55-57 in claudia.rb) is currently commented out as it needs debugging.

## Development Commands

```bash
# Install the formula locally for testing
brew install --build-from-source ./Formula/claudia.rb

# Test the formula
brew test claudia

# Audit the formula
brew audit --strict claudia

# Uninstall for clean testing
brew uninstall claudia
```

## Common Tasks

### Fixing the "head-only" Issue
To make the formula installable with standard `brew install claudia`, you need to:
1. Add a stable version URL and sha256 to the formula
2. Remove or make the `head` specification optional

### Implementing the Full Build
The full build process should:
1. Install Bun as a resource (already implemented)
2. Run `bun install` to install dependencies
3. Run `bun run scripts/fetch-and-build.js -- macos`
4. Run `bun run build`
5. Install the resulting binary from `src-tauri/target/release/claudia`

### Testing Changes
Always run these checks after making changes:
- `brew install --build-from-source ./Formula/claudia.rb`
- `brew test claudia`
- `brew audit --strict claudia`

## Important Notes

- The firebase-debug.log file is unrelated to this project and can be ignored/removed
- Multiple formula variants exist for testing different approaches
- The FORMULA_PLAN.md contains the complete implementation roadmap