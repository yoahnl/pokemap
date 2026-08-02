# PERF-RM-05 Authoring Session Lifecycle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` or `executing-plans` task by task. Every behavior change follows red → green → refactor.

**Goal:** Make the desktop editor retain only the adopted project’s authoring sessions while allowing in-flight work to finish and rejecting stale candidates deterministically.

**Architecture:** PokeMap’s editor has one active project, while MCP remains independently multi-workspace. A shared editor lifecycle coordinator activates a canonical root only after `EditorNotifier` adopts it. Query and mutation adapters retire other roots, await active leases before closing handles, and close late candidates that lose an activation race. No public `map_authoring` or MCP contract changes.

**Tech Stack:** Flutter/Riverpod, editor-internal adapters, canonical `map_authoring` handles, widget/unit parity tests.

---

### Task 1: Characterize one-active-project ownership

**Files:**
- Create: `packages/map_editor/test/authoring_api/authoring_session_lifecycle_test.dart`
- Modify: `packages/map_editor/test/authoring_api/editor_read_parity_test.dart`
- Modify: `packages/map_editor/test/authoring_api/editor_mutation_parity_test.dart`

- [ ] Prove repeated opens of one root share one live read session.
- [ ] Open 1, 3, and 10 roots and show the current unbounded retained-session behavior as a red test.
- [ ] Cover a failed candidate open, A→B→A rapid switch, a late A completion after B adoption, close twice, validation in flight, and mutation in flight.
- [ ] Assert a current response is usable, a stale response cannot become active, and every retired workspace closes exactly once.

### Task 2: Add lease-aware retirement to adapters

**Files:**
- Modify: `packages/map_editor/lib/src/application/authoring_api/authoring_query_adapter.dart`
- Modify: `packages/map_editor/lib/src/application/authoring_api/authoring_mutation_adapter.dart`

- [ ] Add adapter diagnostics for active root, live/opening/retiring session counts, active operations, and close count.
- [ ] Add `activateProjectRoot(String root)` that canonicalizes the root, increments an activation epoch, retains the matching session, and retires every other root.
- [ ] Guard async query validation and every mutation workflow with operation leases; retirement waits for the final lease before detach/close.
- [ ] On a late opening, keep it only when its root matches the current activation; otherwise close it and return a typed stale-session failure.
- [ ] Keep `invalidate(root)` and `closeAll()` idempotent and safe during opens or operations.

### Task 3: Coordinate lifecycle only after project adoption

**Files:**
- Create: `packages/map_editor/lib/src/application/authoring_api/authoring_session_lifecycle_coordinator.dart`
- Modify: `packages/map_editor/lib/src/app/providers/core/repository_providers.dart`
- Modify: `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- Modify only if repository wiring requires it: `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`

- [ ] Provide one coordinator owning the query and mutation adapters.
- [ ] Call it after `createAndActivateProject` or `activateProject` has committed the new `EditorState`, never merely when a candidate begins loading.
- [ ] Keep the previous active root when loading a candidate fails.
- [ ] Do not alter MCP/JSONL multi-workspace handles or broaden any allowed root.

### Task 4: Validate memory and transports

- [ ] Run ten canonical Selbrume root switches, return to one active root, force GC through the existing VM-service harness, and record heap/RSS plus adapter diagnostics.
- [ ] Require no inactive editor handle, no eviction during mutation, no stale adoption, and acceptable retained growth at most 50 MiB or 10%.
- [ ] Re-run direct API, editor read/mutation parity, PMCP-085, MCP tests, and live catalog describe/open/query/validate/close.

**Verification:**

```bash
cd packages/map_editor && flutter test test/authoring_api/authoring_session_lifecycle_test.dart test/authoring_api/editor_read_parity_test.dart test/authoring_api/editor_mutation_parity_test.dart && flutter test && flutter analyze
cd packages/map_authoring && dart run tool/pmcp085_conformance.dart && dart test test/parity/full_authoring_parity_test.dart && dart analyze
cd tools/pokemap_mcp && npm run check && npm test
```

**Non-goals:** an editor multi-project LRU, timers, weak references, changes to public workspace actions, cancellation that interrupts durable mutations, or changes to remembered-project UX.
