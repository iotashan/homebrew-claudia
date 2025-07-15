# Homebrew Claudia

Homebrew tap for [Claudia](https://github.com/getAsterisk/claudia), an MCP (Model Context Protocol) server management GUI application.

## About This Formula

This is a **hybrid approach**: while Claudia is a GUI application (which would typically be distributed as a Homebrew Cask), we're using a Formula to build it from source because:

1. Claudia doesn't publish pre-built releases yet
2. Building from source ensures you get the latest version
3. Once Claudia publishes releases, this can be converted to a proper Cask

## Installation

```bash
brew tap iotashan/claudia
brew install --HEAD claudia
```

**Note:** The `--HEAD` flag is required as this builds from the latest source.

After installation, you can run Claudia with:
```bash
claudia
```

This will open the Claudia GUI application.

## Requirements

- macOS 11.0 or higher
- [Claude Code CLI](https://claude.ai/download) must be installed separately (not available via Homebrew)

## What is Claudia?

Claudia is a GUI application for managing Model Context Protocol (MCP) servers. It provides:
- **Server Registry**: Manage MCP servers from a central graphical interface
- **Easy Configuration**: Add servers via UI or import from existing configs
- **Connection Testing**: Verify server connectivity before use
- **Claude Desktop Import**: Import server configurations from Claude Desktop

It's built with Tauri (Rust + TypeScript) for a native macOS experience.

## Troubleshooting

If you encounter issues during installation:

1. Ensure you have the latest Xcode Command Line Tools:
   ```bash
   xcode-select --install
   ```

2. Update Homebrew:
   ```bash
   brew update
   ```

3. Check the build logs:
   ```bash
   brew install --HEAD --verbose --debug claudia
   ```

## Contributing

To contribute to this formula:
1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Run `brew audit --strict claudia` to verify
5. Submit a pull request

## License

The formula is MIT licensed. Claudia itself is licensed under AGPL-3.0.