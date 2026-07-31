# PMCP-010 — Secure Workspace Evidence Pack

Date: 2026-07-31
Lot: `PMCP-010 — Workspace sûr et handles explicites`
Verdict proposed: `DONE`

## Executive summary

`map_authoring` can now open a real PokeMap project through a pure-Dart,
read-only filesystem port. Project roots are constrained to a canonical
allow-list, project-relative paths reject traversal and outward symlinks, and
external callers receive expiring opaque handles rather than filesystem paths.

The implementation opens and parses the real
`examples/playable_runtime_host/p3_narrative_smoke_slice` fixture, computes a
stable initial SHA-256 fingerprint, exposes no write method, and invalidates
both newly resolved and previously retained access after handle expiry or
closure.

## Scope confirmation

Implemented:

- allowed-root configuration;
- canonical directory resolution;
- lexical traversal rejection;
- target symlink resolution and project containment;
- read-only byte port;
- opaque workspace and project handles;
- handle expiry, unknown-handle rejection, and idempotent close;
- safe project manifest parsing;
- initial `sha256:` fingerprint;
- real-fixture proof and file non-modification proof.

Explicitly not implemented:

- map snapshots and project-wide revisions (`PMCP-011`);
- queries and pagination (`PMCP-011`);
- reference/capability diagnostics (`PMCP-012`);
- CLI or MCP transports (`PMCP-013` and phase 8);
- writes, mutations, recovery, transactions, CAS, or undo (phase 3).

## Initial audit

Initial branch and state:

```text
a5b55717b (HEAD -> main) feat(authoring): add phase 1 foundations
<clean working tree>
```

Relevant existing contracts:

- `ProjectManifest.fromJson` in `map_core`;
- `computeNarrativeProjectFingerprint` in `map_core`;
- phase 1 `AuthoringError` path/stack redaction contracts;
- phase 1 pure-Dart package dependency guard;
- real project layout using `project.json` and manifest-relative map paths.

Main risks identified:

- outward symlinks and lexical path traversal;
- exposing canonical machine paths through result JSON or exceptions;
- retaining resolved access after a handle expires or closes;
- accidentally introducing write methods;
- swallowing malformed manifests into ambiguous raw exceptions;
- filesystem time-of-check/time-of-use limits in portable `dart:io`.

## Named pass verdicts

No sub-agent was launched because the active environment instruction forbids
delegation unless explicitly requested. The required independent passes were
performed inline:

| Pass | Verdict | Evidence |
|---|---|---|
| Audit / Architecture | `PASS` | existing loaders, models, fixture, dependency boundary, and threat surface inspected |
| Implementation | `PASS` | four focused production files plus barrel exports |
| Tests | `PASS` | red-green cycles, 14 focused tests, 49 package tests |
| Build / Validation | `PASS` | pure-Dart package compilation through tests and clean analyzer |
| Critique finale | `PASS_WITH_FIX`, then `PASS` | retained-access expiry/close defect reproduced red and fixed |

## File inventory

### Modified file

`packages/map_authoring/lib/map_authoring.dart`

- Zone: public export barrel.
- Change: exports the file-reader port, workspace policy, handle store, and
  project-open service.
- Reason: the lot's contracts must be available through the canonical package
  API.
- Impact: future snapshot and CLI layers consume one stable public boundary.

Exact diff:

```diff
@@ -15,6 +15,10 @@
 export 'src/contracts/resource_ref.dart';
 export 'src/contracts/schema_descriptor.dart';
+export 'src/ports/project_file_reader.dart';
 export 'src/registry/action_registry.dart';
 export 'src/registry/resource_kind_registry.dart';
 export 'src/tooling/registry_documentation.dart';
+export 'src/workspace/project_open_service.dart';
+export 'src/workspace/workspace_handle_store.dart';
+export 'src/workspace/workspace_policy.dart';
```

### Created implementation files

`packages/map_authoring/lib/src/ports/project_file_reader.dart`

- Classes/functions: `WorkspaceAccessException`, `ProjectFileReader`,
  `LocalProjectFileReader`, `workspacePathIsWithin`,
  `validateProjectRelativePath`.
- Reason: isolate the entire phase 2 filesystem capability behind reads.
- Impact: no authoring consumer can obtain a write primitive from this port.

`packages/map_authoring/lib/src/workspace/workspace_policy.dart`

- Class: `WorkspacePolicy`.
- Reason: canonicalize and authorize project roots once against explicit
  allowed roots.
- Impact: direct outside-root and traversal paths are rejected before project
  parsing.

`packages/map_authoring/lib/src/workspace/workspace_handle_store.dart`

- Classes: `WorkspaceHandle`, `ProjectHandle`, `WorkspaceHandleException`,
  `ProjectWorkspaceAccess`, `RegisteredProjectHandles`,
  `WorkspaceHandleStore`.
- Reason: keep canonical paths private and make access revocable and expiring.
- Impact: serialized clients receive only opaque tokens; every resource read
  revalidates current handle state.

`packages/map_authoring/lib/src/workspace/project_open_service.dart`

- Classes/functions: `ProjectOpenException`, `OpenedProject`,
  `ProjectOpenService`, manifest decoder.
- Reason: provide the canonical project-open operation.
- Impact: a real `project.json` is typed, fingerprinted, and registered without
  exposing its root.

### Created tests

`packages/map_authoring/test/workspace/workspace_path_security_test.dart`

- Positive: real allowed-root project and regular relative file.
- Negative: outside root, traversal, absolute path, relative traversal,
  outward symlink.
- Guardrail: port source contains no write/delete/rename primitive.

`packages/map_authoring/test/workspace/project_open_service_test.dart`

- Positive: real fixture, stable fingerprint, opaque result, read-only access,
  unchanged fixture bytes.
- Negative: malformed manifest, unknown handle, expired handle.
- Guardrail: retained access fails after expiry and after close; close is
  idempotent.

### Created plan

`pokemap_authoring_api_mcp_phase_2_implementation_plan.md`

- Complete four-lot TDD and commit plan for `PMCP-010` through `PMCP-013`.

### Evidence appendix

`reports/analysis/pmcp_010_created_files_full_content.md`

- Reproduces the complete contents of all seven non-report files created by
  this lot.

The report and appendix exclude themselves from recursive embedding. All other
created files are present in full in the appendix.

## TDD evidence

Initial RED command:

```text
cd packages/map_authoring
dart test test/workspace/workspace_path_security_test.dart \
  test/workspace/project_open_service_test.dart
```

Observed result:

```text
Exit code: 1
Undefined name 'WorkspacePolicy'.
Couldn't find constructor 'LocalProjectFileReader'.
Type 'WorkspaceHandleStore' not found.
Type 'ProjectOpenService' not found.
Some tests failed.
```

After the first implementation:

```text
+14: All tests passed!
Exit code: 0
```

Critical-review RED:

```text
ProjectOpenService rejects and removes an expired project handle
Expected WorkspaceHandleException(workspace.handle_expired)
Actual retained access returned project bytes.

ProjectOpenService closes a workspace idempotently and invalidates its project
Expected WorkspaceHandleException(workspace.handle_unknown)
Actual retained access returned project bytes.

Exit code: 1
```

After changing retained access to validate the store before and after every
read:

```text
+14: All tests passed!
Exit code: 0
```

## Final commands and exact results

Focused tests:

```text
Command:
dart test test/workspace/project_open_service_test.dart \
  test/workspace/workspace_path_security_test.dart

Result:
+14: All tests passed!
Exit code: 0
```

Full package tests:

```text
Command:
set -o pipefail
dart test --reporter expanded 2>&1 | tail -n 8

Result:
+49: All tests passed!
Exit code: 0
```

Static analysis:

```text
Command:
dart analyze

Result:
Analyzing map_authoring...
No issues found!
Exit code: 0
```

Formatting:

```text
Command:
dart format --output=none --set-exit-if-changed lib test

Result:
Formatted 28 files (0 changed) in 0.04 seconds.
Exit code: 0
```

Build:

`map_authoring` is a pure Dart library and `PMCP-010` adds no executable, so
there is no deployable binary to build in this lot. The proportional build
proof is compilation of every package test target plus package-wide
`dart analyze`; both exited `0`. The executable build becomes mandatory in
`PMCP-013`.

## Final Git state before the lot commit

```text
 M packages/map_authoring/lib/map_authoring.dart
?? packages/map_authoring/lib/src/ports/project_file_reader.dart
?? packages/map_authoring/lib/src/workspace/project_open_service.dart
?? packages/map_authoring/lib/src/workspace/workspace_handle_store.dart
?? packages/map_authoring/lib/src/workspace/workspace_policy.dart
?? packages/map_authoring/test/workspace/project_open_service_test.dart
?? packages/map_authoring/test/workspace/workspace_path_security_test.dart
?? pokemap_authoring_api_mcp_phase_2_implementation_plan.md
?? reports/analysis/pmcp_010_created_files_full_content.md
?? reports/analysis/pmcp_010_secure_workspace_evidence.md
```

No unrelated file was modified. The implementation plan is intentionally
included in this first phase 2 lot.

## Critical self-review

Strengths:

- portable pure-Dart implementation with no new dependency;
- canonical root and resolved target checks;
- errors and result JSON contain no project path;
- real project parsing, not a synthetic-only proof;
- live revocation enforced even for previously retained access;
- production port cannot write.

Remaining risks:

1. Portable `dart:io` cannot provide Unix `openat`/`O_NOFOLLOW` semantics.
   Resolving before and after reading narrows but cannot mathematically remove
   every hostile concurrent symlink race.
2. Handles are in-memory and process-local by design; durable sessions are not
   claimed.
3. The initial fingerprint covers `project.json` only. `PMCP-011` must derive
   the coherent global revision from the manifest and all declared maps.
4. `WorkspacePolicy.authorizeProjectRoot` returns the canonical root to trusted
   in-package composition code. Transport results deliberately do not expose
   it.
5. Opening validates the manifest but does not yet verify every declared map;
   snapshot loading owns that proof.

## Next step

Proceed only to `PMCP-011 — Snapshot projet, queries et pagination`: load the
manifest and declared maps twice through retained handle checks, derive a
global revision, and add deterministic compact queries. Do not introduce any
write capability.

## Full-content appendix

`reports/analysis/pmcp_010_created_files_full_content.md`
