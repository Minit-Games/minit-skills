---
name: minit
description: Build, port, validate, upload and publish Minit games (Minit Games short-form mobile web games). Use when the user wants to create a new Minit game, port an existing HTML5/JS, Phaser, Pixi, Three.js, Unity, Godot or Defold game to Minit, fix a bundle that fails Minit validation, upload a game ZIP, create a Post, or publish or schedule a Post on Minit Games.
license: MIT
---

# Minit games

Minit Games plays short, self-contained portrait games in a mobile feed. A game ships as a ZIP
with `index.html` at its root, talks to the platform through the Minit SDK, and reaches players
as a **Post** created from a **Game**. The hosted Minit MCP server (`https://mcp.minit.games/mcp`)
does validation, upload and publishing.

## 1. Connect and log in first

Every Minit MCP tool, including `minit_get_requirements`, needs an OAuth login. If no `minit_*`
tools are available, or a call returns an authentication error, ask the user to connect:

- **Claude Code** (plugin installed): run `/mcp`, select `minit`, and complete the browser login.
- **Codex**: `codex mcp add minit --url https://mcp.minit.games/mcp`, then `codex mcp login minit`.
- **Cursor / VS Code**: see [references/client-setup.md](references/client-setup.md).

Confirm the session with `minit_whoami`. Until the user is logged in, keep working from the rules
in this file: scaffold or port the game, apply sections 3 and 4, and validate once connected.

## 2. Creator workflow

| Step | What to do | MCP tool |
|------|------------|----------|
| Requirements | Load the current rules and SDK API before writing code | `minit_get_requirements`, `minit_get_sdk_reference` |
| Scaffold | New game: generate a starter (`vanilla`, `phaser`, `pixi`, `three`) and write the returned files to disk | `minit_scaffold_game` |
| Build | Implement the game; add a root `meta.json` with `config` (section 3); run the project's build (e.g. `npm run build`) so the ZIP holds built output, not source | — |
| SDK lifecycle | Wire `loadingDone()`, `reportResult()`, viewability pause, userData (section 3) | — |
| Validate | Validate the built bundle; fix every error before uploading | `minit_validate_build` |
| Upload (new Game) | First upload creates the Game; `meta.json` sets its founding title, description and result sorting | `minit_create_game` |
| Upload (new revision) | Upload a new build to an existing Game | `minit_upload_game_bundle` |
| Wait for processing | Poll until `completed` or `failed`; read the target `draftRevisionId` | `minit_get_upload_status`, `minit_get_game` |
| Create Post | Create a draft Post pinned to the uploaded revision (pass `revision` explicitly) | `minit_create_post` |
| Test | Get the phone preview link (expires after 15 min) and have the user play it | `minit_get_post_preview_link` |
| Publish | Publish now, or schedule up to 4 weeks ahead, or submit to an event | `minit_publish`, `minit_schedule_post`, `minit_list_post_targets` |

Workflow rules:

- When connected, call `minit_get_requirements` and `minit_get_sdk_reference` before building or
  porting. They are the source of truth; this file is a summary.
- Always run `minit_validate_build` before any upload. `zipBase64` holds a ZIP of at most 4.4 MB;
  for larger bundles pass the text files as a `files` map.
- Upload tools return a presigned S3 URL and a curl template. Run the upload yourself and follow
  the tool response's steps; do not hand the curl command to the user.
- A Post created without `revision` uses the Game's current revision, not the new draft.
- Publishing requires the `user` role; a `guest` account gets a 403.
- Re-uploads ignore `meta.json` `title` and `resultSorting`. A re-upload that creates a new draft
  revision (the latest revision is locked or has non-draft Posts) applies the other fields `meta.json`
  declares; one that replaces the unlocked draft ignores them. `config` and `schemaVersion` apply
  on every upload. An omitted field keeps its current value.
- Change Game metadata after the first upload with `minit_update_game`.

## 3. Core platform rules

### Layout and input

- Portrait only. Author every position, size and hitbox against a fixed **960 × 1480** design
  surface; never derive gameplay coordinates from the raw viewport size.
- Hold the game in one wrapper element and scale it with a single uniform `transform: scale(...)`;
  never scale x and y separately.
- The canvas or game container fills the viewport; `overflow: hidden` on `body`; pin the viewport
  meta tag.
- Touch or pointer input first (`pointerdown`, `pointermove`, `pointerup`): every action must work
  by touch. Keyboard is fine as an extra input (e.g. for desktop play). No hover: it never fires on
  touch screens. Set `touch-action: none` on the canvas.
- Cap rendering at 60 FPS and use delta time.

### SDK lifecycle

- HTML5/JS games import the helpers from `@minit-games/sdk` and call `initializeSDK()` once at
  startup. The vanilla scaffold has no build step: keep its vendored SDK imports and setup.
- Call `loadingDone()` once the first interactive frame is ready.
- Call `reportResult(result, options?)` **exactly once**, when the run ends. `result` is a number
  for score or time games (time in **seconds**), or a result-group string such as `"WIN"` for
  group games. Never pass `null` or `undefined`.
- Pause timers, audio and gameplay when the game is not viewable: `isViewable()` /
  `onViewableChange(fn)`.
- Unity, Godot and Defold games use their engine facade (Unity `Minit.cs`, Godot `addons/minit`,
  Defold `minit.minit`) instead of the JS SDK.

### Config values

- Declare the values a Post can tune (e.g. `level`, `seed`, `difficulty`, `background`) in
  `meta.json` `config`, and read them with `getConfigValue(key, fallback)`. Values arrive as
  strings: coerce them (`Number(...)`, `=== "true"`).
- Each Post sets its own values with `minit_create_post` `config` (`{ key, value }` pairs); when
  supplied it must include every Game config key. Omit it to use the declared defaults.
- Declaring config also unlocks Superposting: other creators post variations of the Game.

```json
{
  "config": [
    { "key": "difficulty", "valueType": "number", "value": 2, "min": 1, "max": 3 },
    { "key": "seed", "valueType": "number", "value": 42 },
    { "key": "background", "valueType": "color", "value": "#1a1a2e" }
  ]
}
```

### Storage and network

- No `localStorage`, `sessionStorage` or cookies. Persist cross-session state with SDK userData:
  write it with `reportResult(score, { userData })`, read it with `getUserData()`. The Game needs
  a `userDataKey` (set with `minit_update_game`); values are one string of at most 1024 bytes.
- No requests to external URLs: no CDN scripts, stylesheets, fonts or remote `fetch`/XHR. Only
  same-origin requests for files inside the ZIP are allowed.
- No camera, microphone or geolocation. Device motion (accelerometer, gyroscope) is allowed with a
  touch fallback.

### Gameplay

- Instantly playable: no splash screens, progress bars or runtime asset downloads.
- One self-contained session with a clear ending; no progression systems, monetisation, accounts,
  logins, leaderboards or social features.
- First-play tutorials only through the SDK overlay, gated by `shouldShowTutorial()`.

### Bundle

- ZIP file with `index.html` at the root (not in a sub-folder) containing a `<script>` tag, and at
  least one `.js` file or inline script.
- Every asset inside the ZIP; script references point at built `.js`/`.mjs` files that exist.
- Limits: ZIP at most 50 MB compressed; each file at most 50 MB uncompressed; all files together
  at most 300 MB uncompressed; `index.html` at most 10 MB; at most 2000 files. Aim for under 5 MB.
- Recommended `meta.json` at the root (every field is optional): `title`, `description`,
  `controls`, `logic`, `resultSorting`, `config` (see Config values), `license` (SPDX id or `proprietary`), `credits`, `sourceUrl`. Attribution licenses need
  a `THIRD-PARTY-NOTICES.txt` at the root.

## 4. Hard-fail list

`minit_validate_build` reports these error codes. Any one of them makes the bundle invalid; fix it
before uploading.

| Error code | Cause | Fix |
|------------|-------|-----|
| `invalid-zip` | `zipBase64` is not a readable ZIP, has no files, or has an entry that won't decompress | Re-create the ZIP with standard deflate compression |
| `zip-too-many-entries` | `zipBase64` holds more than 2000 files | Remove unused files |
| `missing-index-html` | No `index.html` at the bundle root | Zip the build output folder's contents, not the folder |
| `missing-js` | No `.js`/`.mjs` file and no inline script in `index.html` | Include the built JavaScript |
| `missing-script-tag` | `index.html` has no `<script>` tag | Reference the game script from `index.html` |
| `missing-report-result` | No `reportResult()` call found | Call `reportResult()` once when the run ends (engine bundles get a warning instead) |
| `bundle-too-large` | Over 50 MB compressed, a file over 50 MB, or over 300 MB uncompressed in total | Remove unused assets, compress audio and images |
| `bare-import-specifier` | A bare module import (e.g. `"phaser"`) the browser cannot resolve | Bundle the game and upload the built output |
| `unbuilt-source-reference` | `index.html` references a `.ts`/`.tsx`/`.jsx` file | Build and reference the compiled `.js` |
| `missing-script-src` | `index.html` references a script file that is not in the ZIP | Include the file or fix the path |
| `unbuilt-source-tree` | The ZIP is a source export (`package.json` + build config, no build output) | Run the build and upload the `dist/` contents |
| `license-not-allowed` | `meta.json` declares a license the platform cannot host (NC variants, GPL, AGPL) | Use a permitted license or `proprietary` |

`zip-too-large` means the ZIP inflates past the validator's own 64 MB input limit, not a platform
rejection: validate the text files as a `files` map instead. `invalid-input` and `empty-input` mean
the call itself was wrong: pass exactly one of `files` or `zipBase64`, and a non-empty `files` map.

The platform also rejects an `index.html` over 10 MB and bundles with more than 2000 files. The
validator reports these as warnings (`index-html-too-large`, and `zip-entry-count-too-high` for a
`files` map): treat them as blocking. Review every other warning too; most flag platform rules from
section 3.
