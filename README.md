# Minit skills

Agent skill and Claude Code plugin for building games on [Minit Games](https://minit.games).

The `minit` skill teaches an AI coding agent how to build, port, validate, upload and publish a
Minit game: the creator workflow, the platform rules (portrait 960 × 1480 design surface,
touch-only input, Minit SDK lifecycle, no browser storage or external requests) and the bundle
errors that fail validation. It works together with the hosted Minit MCP server
(`https://mcp.minit.games/mcp`), which validates bundles, uploads them, and creates and publishes
Posts. The MCP server needs a login with your Minit Games account.

## Claude Code

Install the plugin, which adds the skill and the Minit MCP server:

```text
/plugin marketplace add Minit-Games/minit-skills
/plugin install minit@minit
```

Then run `/mcp`, select `minit` and complete the browser login.

## Codex

1. Add the MCP server and log in:

   ```bash
   codex mcp add minit --url https://mcp.minit.games/mcp
   codex mcp login minit
   ```

2. Install the skill so that it ends up at `~/.agents/skills/minit/SKILL.md`, either way:
   - Download [`minit-skill.zip`](https://github.com/Minit-Games/minit-skills/releases/latest/download/minit-skill.zip)
     and unzip it into `~/.agents/skills/`.
   - Ask Codex: `$skill-installer install the minit skill from https://github.com/Minit-Games/minit-skills/tree/main/plugins/minit/skills/minit`

3. Restart Codex so it picks up the new skill.

## Cursor and VS Code

1. Download [`AGENTS.md`](https://github.com/Minit-Games/minit-skills/releases/latest/download/AGENTS.md)
   into your game project's root. Cursor reads it automatically; in VS Code, make sure the
   `chat.useAgentsMdFile` setting is enabled.
2. Add the Minit MCP server:
   - Cursor, `.cursor/mcp.json`:

     ```json
     {
       "mcpServers": {
         "minit": {
           "url": "https://mcp.minit.games/mcp"
         }
       }
     }
     ```

   - VS Code, `.vscode/mcp.json`:

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

3. Start the server and complete the browser login when prompted.

More detail per client: [`client-setup.md`](plugins/minit/skills/minit/references/client-setup.md).

## Repository layout

| Path | Contents |
|------|----------|
| `.claude-plugin/marketplace.json` | Claude Code marketplace `minit` |
| `plugins/minit/` | The `minit` Claude Code plugin |
| `plugins/minit/.mcp.json` | Minit MCP server config |
| `plugins/minit/skills/minit/SKILL.md` | The skill (Agent Skills format) |

## License

[MIT](LICENSE)
