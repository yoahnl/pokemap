# PokeMap Authoring API/MCP — Phase 2 Read API Evidence

Date: 2026-07-31
Phase: `Phase 2 — API de lecture sécurisée`
Verdict proposed: `DONE`

## Outcome

Phase 2 delivers a tested, compiled, read-only PokeMap authoring API from disk
boundary to process transport:

```text
allowed roots
  -> opaque expiring handles
  -> coherent immutable snapshot
  -> strict deterministic queries
  -> references and capability truth
  -> shared application API
  -> strict JSONL CLI
```

This is the foundation required by a future MCP server. It is deliberately not
the MCP server itself and cannot mutate a PokeMap project.

## Phase lot verdicts and commits

| Lot | Verdict | Commit | Primary proof |
|---|---|---|---|
| `PMCP-010` secure workspaces | `DONE` | `eea69e83e` | 14 focused tests; allow-list, symlink/traversal, opaque handles |
| `PMCP-011` snapshots and queries | `DONE` | `5af184aff` | 24 focused tests; revisions, five operations, cursors, regions |
| `PMCP-012` references and truth | `DONE` | `7c7bf3f2e` | 12 focused tests; bounded graph, impact, diagnostics, fail-closed truth |
| `PMCP-013` JSONL CLI | `DONE` proposed | current lot commit `feat(authoring): add read-only JSONL CLI` | 14 focused tests; real process and native build |

The current lot cannot embed its own final Git hash without changing that hash.
The post-commit Git log is the authoritative fourth-hash evidence.

## Initial audit

Phase 2 began from:

```text
a5b55717b feat(authoring): add phase 1 foundations
<clean working tree>
```

The implementation plan was recorded at:

`pokemap_authoring_api_mcp_phase_2_implementation_plan.md`

No `map_core` implementation was modified. Phase 2 consumes its canonical
project models, narrative dependency read models, picker compatibility logic,
capability truth gate, and fingerprints.

## What is now usable

### Secure workspace boundary

- one or more canonical allowed roots;
- lexical traversal rejection;
- symlink target containment before and after reads;
- regular-file-only reads;
- a port with no mutation method;
- opaque workspace/project handles;
- expiry and close invalidation;
- no machine path in public open results.

### Immutable project reads

- manifest plus every declared map;
- two-pass change detection;
- exact SHA-256 project revision and resource fingerprints;
- strict map identity/path uniqueness;
- `list`, `get`, `batch_get`, `search`, and `summary`;
- summary/detail projection, filters, sort, field masks, pagination;
- revision/query-bound cursors;
- bounded map-region reads;
- persisted editor API-key and manifest path removal.

### Reference and readiness inspection

- typed cross-domain narrative reference index;
- dependency and dependent directions;
- cycle-safe bounded graph;
- missing/ambiguous/unavailable/cycle/duplicate diagnostics;
- safe navigation intents;
- delete and rename impact;
- canonical picker projection;
- explicit promoted/deferred capability truth;
- no support promotion from mere model presence.

### Direct and process API

- shared protocol-neutral `AuthoringReadApi`;
- `describe`, `open`, `query`, `validate`, `close`;
- strict request and argument objects;
- stable `AuthoringResult` success/failure envelopes;
- safe domain-code mapping and raw-exception redaction;
- UTF-8 line limit and command timeout;
- deterministic golden transcript;
- real JSONL process;
- CLI roots/limits configuration and sysexits-style failures;
- native executable compilation.

## Phase acceptance evidence

Final `map_authoring` verification:

```text
dart test
+99: All tests passed!

dart analyze
Analyzing map_authoring...
No issues found!

dart format --output=none --set-exit-if-changed bin lib test
Formatted 49 files (0 changed) in 0.07 seconds.

dart compile exe bin/pokemap_authoring.dart \
  -o /tmp/pokemap_authoring_phase_2
Generated: /tmp/pokemap_authoring_phase_2
```

Canonical dependency regression:

```text
cd packages/map_core
dart test
+4656: All tests passed!

dart analyze
Analyzing map_core...
No issues found!
```

Exact per-lot evidence:

- `reports/analysis/pmcp_010_secure_workspace_evidence.md`
- `reports/analysis/pmcp_011_snapshot_query_evidence.md`
- `reports/analysis/pmcp_012_reference_diagnostics_evidence.md`
- `reports/analysis/pmcp_013_read_only_jsonl_cli_evidence.md`

Full created-file contents:

- `reports/analysis/pmcp_010_created_files_full_content.md`
- `reports/analysis/pmcp_011_created_files_full_content.md`
- `reports/analysis/pmcp_012_created_files_full_content.md`
- `reports/analysis/pmcp_013_created_files_full_content.md`

## Named pass verdicts

No sub-agent was launched because delegation was not requested or authorized.
Each lot used explicit inline passes:

| Pass | Verdict |
|---|---|
| Initial repository/spec audit | `PASS` |
| Package-boundary and architecture review | `PASS` |
| TDD RED/GREEN cycles | `PASS` |
| Filesystem and data-leak threat review | `PASS_WITH_FIXES`, then `PASS` |
| Determinism, limits, cycles, cursor review | `PASS_WITH_FIXES`, then `PASS` |
| Direct/transport/process parity | `PASS` |
| Package tests/analyzers/formatter | `PASS` |
| Native build | `PASS` |
| Final critical review | `PASS` |

## Complete phase file inventory

### Planning

- `pokemap_authoring_api_mcp_phase_2_implementation_plan.md`

### Modified package files

- `packages/map_authoring/lib/map_authoring.dart`
- `packages/map_authoring/pubspec.yaml`

### Created production and executable files

- `packages/map_authoring/bin/pokemap_authoring.dart`
- `packages/map_authoring/lib/src/api/authoring_read_api.dart`
- `packages/map_authoring/lib/src/contracts/query_page.dart`
- `packages/map_authoring/lib/src/contracts/query_request.dart`
- `packages/map_authoring/lib/src/domains/maps/map_region_query.dart`
- `packages/map_authoring/lib/src/domains/project/capability_truth_adapter.dart`
- `packages/map_authoring/lib/src/ports/project_file_reader.dart`
- `packages/map_authoring/lib/src/references/project_reference_index.dart`
- `packages/map_authoring/lib/src/references/reference_impact.dart`
- `packages/map_authoring/lib/src/references/reference_queries.dart`
- `packages/map_authoring/lib/src/tooling/cli_exit_codes.dart`
- `packages/map_authoring/lib/src/tooling/jsonl_worker.dart`
- `packages/map_authoring/lib/src/workspace/project_open_service.dart`
- `packages/map_authoring/lib/src/workspace/project_query_service.dart`
- `packages/map_authoring/lib/src/workspace/project_snapshot.dart`
- `packages/map_authoring/lib/src/workspace/project_snapshot_loader.dart`
- `packages/map_authoring/lib/src/workspace/workspace_handle_store.dart`
- `packages/map_authoring/lib/src/workspace/workspace_policy.dart`

### Created tests and golden

- `packages/map_authoring/test/contracts/query_pagination_test.dart`
- `packages/map_authoring/test/domains/maps/map_region_query_test.dart`
- `packages/map_authoring/test/domains/project/capability_truth_adapter_test.dart`
- `packages/map_authoring/test/references/project_reference_index_test.dart`
- `packages/map_authoring/test/tooling/cli_golden_test.dart`
- `packages/map_authoring/test/tooling/goldens/describe_and_error.jsonl`
- `packages/map_authoring/test/tooling/jsonl_worker_test.dart`
- `packages/map_authoring/test/workspace/project_open_service_test.dart`
- `packages/map_authoring/test/workspace/project_snapshot_test.dart`
- `packages/map_authoring/test/workspace/workspace_path_security_test.dart`

### Created engineering evidence

- `reports/analysis/pmcp_010_created_files_full_content.md`
- `reports/analysis/pmcp_010_secure_workspace_evidence.md`
- `reports/analysis/pmcp_011_created_files_full_content.md`
- `reports/analysis/pmcp_011_snapshot_query_evidence.md`
- `reports/analysis/pmcp_012_created_files_full_content.md`
- `reports/analysis/pmcp_012_reference_diagnostics_evidence.md`
- `reports/analysis/pmcp_013_created_files_full_content.md`
- `reports/analysis/pmcp_013_read_only_jsonl_cli_evidence.md`
- `reports/analysis/pmcp_phase_2_read_api_evidence.md`

The four created-content appendices reproduce every created implementation and
test artifact per lot. Reports exclude themselves to avoid recursive content.

## Decisions and non-goals

Decisions:

- PokeMap owns and reads its native project data.
- `map_core` remains the canonical model/read-model authority.
- filesystem paths stay behind workspace closures and opaque handles;
- exact persisted bytes define snapshot revision;
- read projections are immutable and deterministic;
- capability support is explicit and fail-closed;
- the CLI delegates to the same API used directly;
- no phase 2 type imports Flutter, Flame, editor, or runtime internals.

Non-goals:

- no project write, rename, delete, resize, or migration apply;
- no transaction journal or undo;
- no MCP server or SDK binding;
- no remote transport or credentials;
- no generic read coverage beyond project/maps plus reference projections;
- no durable sessions.

## Critical self-review and residual risks

1. Filesystem containment uses portable canonicalization and double resolution,
   not descriptor-relative OS primitives such as `openat`. It substantially
   reduces symlink races but cannot provide a kernel-level transaction.
2. Snapshot double reads reject observed changes but are not a multi-file
   filesystem snapshot. Phase 3 writes must enforce expected revision at apply
   time.
3. Generic queries currently expose only project and map resources. Later
   domain lots must add registries and projections deliberately.
4. Reference coverage is limited to the canonical narrative dependency
   discovery currently emitted by `map_core`.
5. Query cursors are semantically bound but unsigned.
6. A command timeout does not cancel its underlying Dart future.
7. The CLI worker limits completed lines; a hostile newline-free stream should
   be handled by a byte-bounded decoder before any remote deployment.
8. Handles are process-local and intentionally non-durable.
9. The phase proves the API boundary, not end-user MCP consent, authentication,
   or write safety.

## Recommended next phase

Proceed to the phase 3 write kernel in small committed lots:

1. expected-revision preconditions;
2. dry-run impact and deterministic diff;
3. staged atomic apply;
4. backup/undo receipts;
5. reference-aware rename/delete planning;
6. only then expose write tools through MCP.

Do not add MCP write tools before those transaction guarantees exist.
