# Homebrew Claudia

Homebrew tap for [Claudia](https://github.com/getAsterisk/claudia), an MCP (Model Context Protocol) server management tool.

## Installation

```bash
brew tap iotashan/claudia
brew install claudia
```

## Requirements

- macOS 11.0 or higher
- [Claude Code CLI](https://claude.ai/download) must be installed separately (not available via Homebrew)

## What is Claudia?

Claudia is a Model Context Protocol (MCP) server management tool that provides:
- Server Registry: Manage MCP servers from a central UI
- Easy Configuration: Add servers via UI or import from existing configs
- Connection Testing: Verify server connectivity before use
- Claude Desktop Import: Import server configurations from Claude Desktop

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
   brew install --verbose --debug claudia
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