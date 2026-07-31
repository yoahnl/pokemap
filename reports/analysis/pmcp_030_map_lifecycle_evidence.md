# PMCP-030 — Canonical Map Lifecycle Evidence Pack

Date: 2026-07-31

Phase: PokeMap Authoring API/MCP phase 4

Lot: PMCP-030

Proposed status: `DONE`

## Executive summary

PMCP-030 exposes the complete canonical map lifecycle through the shared
authoring boundary:

- `map.create`, `map.save`, `map.rename`, `map.duplicate`,
  `map.delete_apply`, and `map.resize_apply` are versioned, described actions;
- map loading remains the Phase 2 immutable `map.get`/query contract;
- every mutable action builds a pure, revision-bound plan with a bounded
  preview, structured diff, exact resource pre-images, and no write port;
- lifecycle writes use the Phase 3 secure executor, durable idempotency,
  per-resource CAS, journaled recoverable transactions, audit, history, and
  undo;
- create/duplicate write manifest plus map together; rename freezes manifest,
  source deletion, and destination creation as one three-resource transaction;
- rename and delete refuse incoming connections, warps, new-game, or other
  indexed references instead of silently rewriting them;
- resize delegates to `map_core`'s conservative impact plan and refuses every
  lossy or structurally invalid resize;
- a local mutation session keeps canonical roots server-side behind opaque
  handles, and the JSONL CLI now exposes `plan`, `confirm`, `apply`, `undo`, and
  `recover` without serializing machine paths;
- a Phase 3 post-image revision bug exposed by real revisioned resource refs
  was fixed in both revision-set and journal verification.

Fresh end-of-lot evidence:

- focused lifecycle/JSONL/CLI suite: `+25: All tests passed!`;
- full `map_authoring` package: `+185: All tests passed!`;
- `map_authoring` analyzer: `No issues found!`;
- formatter verification: 99 files, 0 changed;
- editor lifecycle non-regression: `+63: All tests passed!`;
- `map_core` resize-plan regression: `+7: All tests passed!`;
- real authoring CLI empty-stream smoke: exit 0, no output;
- `git diff --check`: exit 0, no output.

## Initial audit

The lot started from a clean tree at:

```text
1e3d8787a feat(authoring): add mutation history and undo
```

The audit found that Phase 3 already supplied the protocol-neutral safe-write
kernel but deliberately exposed no domain mutations. `map_editor` already had
use-case evidence for lifecycle behavior, while `map_core` owned the pure map
model, validation, reference index inputs, and resize impact/resolution logic.
Importing editor repositories into `map_authoring` would have violated package
boundaries, so the implementation adapts the behavior and reuses only
`map_core` contracts.

The audit also identified two requirements that were not optional:

1. `ProjectSnapshot` previously retained typed models and fingerprints but not
   exact disk bytes. Re-encoding a model cannot safely authorize CAS or preserve
   unknown manifest fields, so snapshots now retain immutable bytes under
   path-free identities (`project`, `map:<id>`).
2. The Phase 3 post-image revision set reused a resource ref whose optional
   revision intentionally described the pre-image. Real lifecycle refs exposed
   the contradiction. Post-image sets and journal verification now clone only
   the typed resource identity and extensions before attaching the after
   revision.

This is map-authoring infrastructure, not a fangame-mechanics lot. No `FG-*`
status or mechanics roadmap file was changed.

## Named pass verdicts

No sub-agent was dispatched because the active higher-priority session rule
disallowed delegation unless explicitly requested. The required independent
passes were performed locally:

| Pass | Verdict | Evidence |
|---|---|---|
| Audit / Architecture | PASS | Pure-Dart boundary retained; editor behavior was characterized without importing editor code; canonical roots remain private. |
| TDD contract | PASS | Initial lifecycle RED failed to load on the absent action/snapshot APIs; transaction and JSONL tests also failed before their adapters existed. |
| Lifecycle implementation | PASS | Six mutable actions plus existing load/query cover create/load/save/rename/duplicate/delete/resize. |
| Dependency and validation guards | PASS | Case-insensitive ID/path ownership, portable IDs, map/project validators, indexed references, and conservative resize impacts fail closed. |
| Transaction and recovery | PASS after revision fix | Manifest+map creation crashes after promotion 0, remains inspectable, and resumes to one recovered receipt and coherent saved state. |
| Authorization and confirmation | PASS | Local actor scopes are server-owned; high-risk deletion requires a plan-bound one-use confirmation. |
| History and undo | PASS | Creation records exact before/after blobs; undo is a new CAS/idempotent transaction restoring the empty manifest and deleting the map. |
| JSONL/CLI parity | PASS | Optional mutation mode preserves Phase 2 read-only goldens while the real CLI advertises and executes lifecycle planning/apply. |
| Editor compatibility | PASS | Two-space map encoding matches the editor boundary; focused existing editor lifecycle tests remain +63. |
| Build / Validation | PASS | Focused, full package, analyzer, formatter, editor, core, CLI, and diff checks are green. |
| Critique finale | PASS with limits | Local filesystem trust, in-memory plan lifetime, reference rewrite non-goal, and rendering/remaining map lots are explicit below. |

## File inventory and precise changed zones

### Modified files

- `packages/map_authoring/bin/pokemap_authoring.dart`
  - composes one shared snapshot loader and the local mutation API;
  - passes mutation capability to the JSONL worker;
  - removes the obsolete “read-only workspace” initialization wording.
- `packages/map_authoring/lib/map_authoring.dart`
  - exports mutation API ports/adapters, lifecycle actions/adapter, and the map
    mutation dispatcher.
- `packages/map_authoring/lib/src/tooling/jsonl_worker.dart`
  - keeps mutation support optional so Phase 2 read-only tests remain exact;
  - merges read and mutation descriptions deterministically;
  - attaches/detaches local mutation sessions on open/close;
  - dispatches strict `plan`, `confirm`, `apply`, `undo`, and `recover` commands;
  - maps domain/plan/auth/CAS/idempotency/recovery/history failures into safe
    transport errors and redacts structured details.
- `packages/map_authoring/lib/src/transactions/revision_set.dart`
  - constructs post-image revision entries from revision-free typed resource
    identities instead of reusing pre-image revisions.
- `packages/map_authoring/lib/src/transactions/transaction_journal.dart`
  - applies the same post-image identity rule while verifying intended receipt
    revision fingerprints.
- `packages/map_authoring/lib/src/workspace/project_snapshot.dart`
  - accepts, freezes, validates, and privately retains exact resource bytes;
  - exposes defensive-copy lookup by path-free resource identity.
- `packages/map_authoring/lib/src/workspace/project_snapshot_loader.dart`
  - retains the exact twice-verified manifest and map bytes in each snapshot.
- `packages/map_authoring/test/tooling/cli_golden_test.dart`
  - updates the real CLI expectation from read-only to writable authoring mode
    while retaining direct read-query parity and path-leak checks.

### Created production files

- `packages/map_authoring/lib/src/api/authoring_mutation_api.dart`
  - protocol-neutral mutation port for session attach/detach and
    plan/confirm/apply/undo/recover.
- `packages/map_authoring/lib/src/api/local_map_authoring_mutation_api.dart`
  - authorized root binding, secure local session composition, descriptor-based
    planning, confirmation, transaction apply, history undo, and recovery.
- `packages/map_authoring/lib/src/domains/maps/map_lifecycle_actions.dart`
  - six canonical versioned action descriptors and action dispatch.
- `packages/map_authoring/lib/src/domains/maps/map_lifecycle_adapter.dart`
  - pure lifecycle drafts, validation, manifest preservation, reference impact,
    resize diagnostics, editor-compatible encoding, and stable domain errors.
- `packages/map_authoring/lib/src/domains/maps/map_mutation_dispatcher.dart`
  - deterministic descriptor/handler registry extended by later Phase 4 lots.

### Created tests

- `packages/map_authoring/test/domains/maps/map_lifecycle_contract_test.dart`
  - descriptor coverage, create/save/duplicate/rename, reference refusal,
    resize impact refusal, exact bytes, and three-resource rename draft.
- `packages/map_authoring/test/domains/maps/map_lifecycle_transaction_test.dart`
  - real filesystem plan/apply/history/undo, destructive confirmation, crash
    between promotions, and forward recovery.
- `packages/map_authoring/test/tooling/jsonl_mutation_worker_test.dart`
  - combined description, open binding, lifecycle plan/apply, saved file, and
    canonical-root leak guard.

### Planning and reporting artifacts

- `pokemap_authoring_api_mcp_phase_4_implementation_plan.md`
  - phase exit contract, architecture, six lots, per-lot commits, and validation
    matrix.
- `reports/analysis/pmcp_030_map_lifecycle_evidence.md`
  - this Evidence Pack.
- `reports/analysis/pmcp_030_created_files_full_content.md`
  - exact full content of all nine created production/test/planning files.

The full-content appendix and this report intentionally exclude themselves to
avoid recursive reporting.

## Lifecycle contract

All lifecycle requests use `AuthoringRequest` version 1 and require the current
project snapshot revision plus an idempotency key. Planning reads one coherent
snapshot and returns a frozen plan and planned receipt. Apply resolves that
same plan, checks the current snapshot and every touched resource revision, and
promotes staged bytes through the existing journal.

`map.create` accepts a structured map intent: portable ID, optional name,
positive dimensions, optional group, role, and tileset. It creates the same
canonical visual stack and base/terrain/collision layer foundation used by the
editor. Default tileset selection is deterministic.

`map.save` validates a complete typed map document and changes only its
manifest-owned path. `map.duplicate` preserves source data, group, and role and
allocates a bounded `_copy` identity if none is supplied. `map.rename` creates
the destination, removes the exact source pre-image, and updates the manifest
inside one recoverable transaction. `map.delete_apply` removes the exact map
and manifest entry together. `map.resize_apply` delegates all impact analysis
and Border resizing to `map_core`; it never offers a destructive override.

## Reference and manifest protection

Manifest ownership is checked case-insensitively for both IDs and normalized
portable relative paths. Newly authored IDs follow the editor's 64-character,
lowercase, filename-safe, Windows-portable policy. Rename alone may identify
one legacy source ID, but its destination is always canonical.

Rename/delete build the canonical project reference index and target the
physical map key. Any incoming edge blocks the mutation and returns a bounded
impact summary. No reference is guessed or rewritten. Project validation also
protects enabled new-game start maps and other manifest-level invariants.

## Transaction, recovery, and undo evidence

The crash test interrupts creation after promotion index 0. Because changes are
ordered by typed resource identity, the map document is visible while the old
manifest is still intact. The journal, staged pre/post images, and pending
idempotency reservation survive. `recover` verifies the visible map after-image,
promotes the manifest after-image, records history, and completes the same
receipt as `recovered`. A second coherent snapshot then loads the map declared
by the manifest.

Normal create commits one history entry retaining both manifest and map images.
Undo plans the inverse, rechecks current bytes, restores the original manifest,
deletes the created map, and records a new `history.undo` receipt. No filesystem
rollback bypass is used.

## Commands and exact results

### RED evidence

Initial lifecycle contract run:

```text
dart test test/domains/maps/map_lifecycle_contract_test.dart
exit 1
Undefined name 'MapLifecycleActions'; MapAuthoringException and exact snapshot
resource bytes were also absent.
```

Initial transaction adapter run:

```text
dart test test/domains/maps/map_lifecycle_transaction_test.dart
exit 1
Type 'LocalMapAuthoringMutationApi' not found.
```

The first executable transaction run then exposed and reproduced the Phase 3
post-image resource-revision contradiction in both revision-set and journal
construction. After the identity-only post-image fix, the same crash/recovery
tests passed.

### Focused GREEN

```text
cd packages/map_authoring
dart test test/domains/maps/map_lifecycle_contract_test.dart \
  test/domains/maps/map_lifecycle_transaction_test.dart \
  test/tooling/jsonl_mutation_worker_test.dart \
  test/tooling/jsonl_worker_test.dart \
  test/tooling/cli_golden_test.dart
```

Result: exit 0, `+25: All tests passed!`.

### Full package

```text
cd packages/map_authoring
dart test
```

Result: exit 0, `+185: All tests passed!`.

```text
cd packages/map_authoring
dart analyze
```

Result: exit 0, `No issues found!`.

```text
cd packages/map_authoring
dart format --output=none --set-exit-if-changed lib test bin
```

Result: exit 0, `Formatted 99 files (0 changed)`.

### Cross-package non-regression

```text
cd packages/map_editor
flutter test test/application/use_cases/map_lifecycle_use_cases_test.dart \
  test/application/services/map_lifecycle_transaction_service_test.dart \
  test/infrastructure/repositories/map_lifecycle_transaction_file_gateway_test.dart \
  test/app/providers/map_lifecycle_provider_wiring_test.dart
```

Result: exit 0, `+63: All tests passed!`.

```text
cd packages/map_core
dart test test/map_resize_plan_test.dart
```

Result: exit 0, `+7: All tests passed!`.

### Executable and repository checks

```text
cd packages/map_authoring
dart run bin/pokemap_authoring.dart \
  --root ../../examples/playable_runtime_host </dev/null
```

Result: exit 0, stdout/stderr empty.

```text
git diff --check
```

Result: exit 0, no output.

No code generation was required. No dependency or lockfile changed.

## Git state

Initial state:

```text
clean at 1e3d8787a feat(authoring): add mutation history and undo
```

Expected lot-only state immediately before staging:

```text
 M packages/map_authoring/bin/pokemap_authoring.dart
 M packages/map_authoring/lib/map_authoring.dart
 M packages/map_authoring/lib/src/tooling/jsonl_worker.dart
 M packages/map_authoring/lib/src/transactions/revision_set.dart
 M packages/map_authoring/lib/src/transactions/transaction_journal.dart
 M packages/map_authoring/lib/src/workspace/project_snapshot.dart
 M packages/map_authoring/lib/src/workspace/project_snapshot_loader.dart
 M packages/map_authoring/test/tooling/cli_golden_test.dart
?? packages/map_authoring/lib/src/api/authoring_mutation_api.dart
?? packages/map_authoring/lib/src/api/local_map_authoring_mutation_api.dart
?? packages/map_authoring/lib/src/domains/maps/map_lifecycle_actions.dart
?? packages/map_authoring/lib/src/domains/maps/map_lifecycle_adapter.dart
?? packages/map_authoring/lib/src/domains/maps/map_mutation_dispatcher.dart
?? packages/map_authoring/test/domains/maps/map_lifecycle_contract_test.dart
?? packages/map_authoring/test/domains/maps/map_lifecycle_transaction_test.dart
?? packages/map_authoring/test/tooling/jsonl_mutation_worker_test.dart
?? pokemap_authoring_api_mcp_phase_4_implementation_plan.md
?? reports/analysis/pmcp_030_created_files_full_content.md
?? reports/analysis/pmcp_030_map_lifecycle_evidence.md
```

No unrelated pre-existing change was present or absorbed.

## Critique finale and known limits

- Plans and confirmation bindings are intentionally in memory. A process
  restart can recover an already journaled operation, but an unapplied preview
  plan must be recreated.
- Local project identity is a SHA-256 derivative of the authorized canonical
  root. It is not exposed, but moving a project creates a new audit/history
  project scope unless a later portable project UUID is introduced.
- Root-to-handle attachment verifies every exact snapshot pre-image before
  creating a write session. Cooperative local writers remain protected by CAS
  and OS locks; an attacker already controlling the project filesystem is
  outside the trust model.
- Manifest writes preserve unknown top-level keys. Complete map saves retain
  the editor's current behavior of serializing the typed `MapData` document;
  unknown map-document keys are not promised.
- Rename/delete deliberately refuse references rather than rewriting them.
  Explicit reference-rewrite actions belong to later domain lots.
- Resize remains strictly non-lossy because `map_core` offers no destructive
  override. Users must move or clear impacted data before shrinking.
- PMCP-030 does not yet supply region tools, semantic painting, environment,
  borders, spatial-object CRUD, world graph, or rendering. Those are precisely
  PMCP-031 through PMCP-035.
- The JSONL adapter is now writable for trusted local CLI composition. The MCP
  transport itself is still a later phase and is not claimed here.

With these limits explicit and all fresh checks green, PMCP-030 can be proposed
as `DONE`. The next dependency-ready lot is PMCP-031 — layers, regions, and
atomic map operation batches. Roadmap status files are not edited because the
user requested implementation and per-lot commits, not roadmap mutation.
