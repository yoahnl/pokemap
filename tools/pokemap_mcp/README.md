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
./scripts/pmcp085_release_gate.sh
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
   Its `fullParity` section exposes the PMCP-085 matrix, the explicit owner of
   every semantic resource, all registered mutations, evidence paths and the
   release claim summary.
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

## Conformance and security

The PMCP-085 inventory currently covers 62 approved semantic resources and all
223 canonical mutation actions. A release is refused when any applicable cell
is `MISSING` or `BLOCKED`; every `NOT_APPLICABLE` cell carries a reason. Generate
the machine-readable matrix with:

```bash
cd packages/map_authoring
dart run tool/pmcp085_conformance.dart
```

`catalogComplete` in that output covers the canonical API catalog only. Run the
cross-package release gate from this directory with:

```bash
./scripts/pmcp085_release_gate.sh
```

The gate currently exits non-zero after running every validation because the
five PMCP-081 editor mutation bypasses are still explicitly inventoried. This
is intentional: availability through the generic editor adapter does not prove
that every existing product gesture has migrated to it.

The server applies one shared admission guard before authoring, resource,
artifact or runtime gateways. Defaults are 64 KiB of serialized UTF-8 input and
512 admitted requests per 60-second process-local window. Oversized requests
return `resource_limit`; excess rate returns retryable `rate_limited`. The Dart
worker independently enforces its own input limit.

See [THREAT_MODEL.md](THREAT_MODEL.md) for trust boundaries, controls and
residual risks. These controls protect a local stdio server; they are not an
authentication design for a remote deployment.
