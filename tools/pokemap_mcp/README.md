# PokeMap MCP

Local MCP adapter for the canonical Dart `map_authoring` API. The server uses
stdio only and accepts explicit project roots. It never turns arbitrary paths
or UI gestures into an authoring contract.

## Build and verify

```bash
cd tools/pokemap_mcp
npm ci
npm run check
npm test
```

## Local client configuration

Build once, then configure the MCP client with an absolute command path:

```json
{
  "command": "node",
  "args": [
    "/absolute/path/to/pokemonProject/tools/pokemap_mcp/dist/src/index.js",
    "--root",
    "/absolute/path/to/a/pokemap/project"
  ]
}
```

Repeat `--root <path>` to authorize several projects. Optional advanced flags:

- `--authoring-package <path>` locates `packages/map_authoring` when the
  repository layout cannot be discovered;
- `--dart <executable>` selects a Dart executable.

All protocol output is written to stdout. Diagnostics are written to stderr.

## Read-only workflow

1. Call `pokemap_describe` to discover resource kinds and query operations.
2. Call `pokemap_workspace` with `operation: "open"` and an authorized root.
3. Keep the returned `projectHandle` and `workspaceHandle` opaque.
4. Use `pokemap_query`, following `nextCursor` without modification.
5. Use `pokemap_validate` or the project resource templates.
6. Close the workspace with its explicit handle.

The PMCP-083 server exposes no plan/apply/undo/recover tool. Artifact reads are
limited to handles registered inside this process; filesystem and arbitrary
HTTPS reads are forbidden.
