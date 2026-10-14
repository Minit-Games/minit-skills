# Minit MCP client setup

Connect an AI coding client to the hosted Minit MCP server at `https://mcp.minit.games/mcp`
(streamable HTTP, OAuth login with a Minit Games account).

## Claude Code

- With the `minit` plugin installed, the server is already configured. Run `/mcp`, select `minit`
  and complete the browser login.
- Without the plugin:

  ```bash
  claude mcp add --transport http minit https://mcp.minit.games/mcp
  ```

  Then run `/mcp` inside Claude Code to log in.

## Codex

```bash
codex mcp add minit --url https://mcp.minit.games/mcp
codex mcp login minit
```

`codex mcp login` opens the browser for the OAuth login.

## Cursor

Add the server to `.cursor/mcp.json` in the project, or to `~/.cursor/mcp.json` for every
project:

```json
{
  "mcpServers": {
    "minit": {
      "url": "https://mcp.minit.games/mcp"
    }
  }
}
```

Complete the OAuth login when Cursor prompts for it.

## VS Code

Add the server to `.vscode/mcp.json` in the workspace (VS Code uses a top-level `servers` key):

```json
{
  "servers": {
    "minit": {
      "type": "http",
      "url": "https://mcp.minit.games/mcp"
    }
  }
}
```

Start the server with the code lens in `mcp.json` or **MCP: List Servers**, then complete the
browser login when prompted.

## Verify

Call `minit_whoami`. It returns the logged-in creator's identity; an authentication error means
the login did not complete.
