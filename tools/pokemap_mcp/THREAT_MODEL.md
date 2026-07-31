# PokeMap MCP threat model

Scope: local stdio server, canonical Dart authoring worker, configured project
roots, opaque artifacts, render worker and sandboxed playtest jobs. Remote
transport, cloud synchronization and arbitrary process execution are out of
scope.

## Assets and trust boundaries

- Project files and revisions are untrusted inputs but PokeMap-owned data.
- Allowed roots, project paths and process commands are server-owned authority.
- Handles, receipts, diagnostics and artifact URIs may cross the MCP boundary.
- Dart owns validation, planning, permissions, confirmation, CAS, idempotency,
  journals and recovery. TypeScript may translate but must not reimplement
  those domain rules.

## Threats and controls

| Threat | Control | Executable evidence |
|---|---|---|
| Path traversal or symlink escape | Canonical allowed-root policy; opaque resource/artifact handles | `read_only_server.test.ts` |
| Unauthorized or destructive mutation | Canonical permission policy, plan first, exact confirmation | `mutation_server.test.ts` |
| Recovery abuse | Recovery permission plus `RECOVER <operationId>` phrase | `mutation_server.test.ts` |
| Oversized input | UTF-8 budget before any gateway call; worker byte limit | `conformance_security.test.ts` |
| Request flooding | Shared fixed-window admission budget across authoring, resources, artifacts and runtime | `conformance_security.test.ts` |
| Schema confusion or unknown fields | Strict Zod objects, discriminated unions and semantic query refinement | `conformance_security.test.ts` |
| Duplicate writes or stale plans | Durable idempotency ledger and revision CAS | `mutation_server.test.ts` |
| Filesystem or stack-trace disclosure | Redacted structured errors and opaque artifact URIs | `read_only_server.test.ts`, Dart worker tests |
| Runtime escape | Fixed render/eval commands; no shell tool; project identity check | `runtime_server.test.ts` |

## Residual risks

- Rate state and jobs are process-local and reset after restart.
- The default local rate budget is defensive, not an authentication mechanism.
- Interactive playtest retains the permissions of the launched local process.
- Remote MCP transport would require a separate authentication, authorization,
  tenancy and network threat model before release.
