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
- `--repository-root <path>`, `--runtime-package <path>`, and
  `--runtime-host <path>` locate the runtime adapters when the repository
  layout cannot be discovered;
- `--dart <executable>` selects a Dart executable.

All protocol output is written to stdout. Diagnostics are written to stderr.

## Authoring workflow

1. Call `pokemap_describe` to discover resource kinds and query operations.
2. Call `pokemap_workspace` with `operation: "open"` and an authorized root.
3. Keep the returned `projectHandle` and `workspaceHandle` opaque.
4. Use `pokemap_query`, following `nextCursor` without modification, then
   `pokemap_validate` or the project resource templates.
5. Send a revision-bound action to `pokemap_plan`; inspect its diff and planned
   receipt before using `pokemap_apply`.
6. For destructive plans, request a plan-bound token with
   `pokemap_apply(operation: "confirm")` and return it unchanged when applying.
7. Use `pokemap_history` for paginated history or undo. Recovery additionally
   requires the exact phrase `RECOVER <operationId>` and the canonical recovery
   permission.
8. Use `pokemap_render` for a revision-bound PNG artifact. Use
   `pokemap_playtest` and poll `pokemap_job` for sandboxed runtime receipts,
   ordered events, cancellation, retry, and artifacts.
9. Close the workspace with its explicit handle.

Artifact reads are limited to handles registered inside this process;
filesystem and arbitrary HTTPS reads are forbidden. Project roots remain
server-side bindings and never appear in receipts, job snapshots, or artifact
references.
