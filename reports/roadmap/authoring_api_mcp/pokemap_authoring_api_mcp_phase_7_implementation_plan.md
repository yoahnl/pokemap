# PokeMap Authoring API — Phase 7 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: use the repository's
> `executing-plans` workflow task by task. This run is inline because the user
> already requested implementation and the active instructions do not permit
> sub-agent delegation.

**Goal:** Make `map_editor` consume the canonical Authoring API and ship one
local MCP server that exposes the same read, mutation, render, playtest, job,
artifact, history, and recovery contracts without duplicating domain logic.

**Architecture:** Dart remains the only owner of PokeMap project semantics. The
Flutter editor uses small direct-Dart adapters, while the TypeScript MCP server
talks to the existing sandboxed JSONL worker over stdio. The MCP layer only
maps protocol schemas and errors; it never parses or writes project files.

**Tech stack:** Dart 3, Flutter/Riverpod, PokeMap `map_authoring`, Node 20+,
TypeScript 5, official MCP TypeScript SDK v2, Zod 4, Node test runner.

---

## Phase identity and baseline

- Roadmap phase: **Phase I — Parité éditeur et MCP**.
- Lots: **PMCP-080 → PMCP-084**.
- Execution: current branch, one verified commit per lot, no push.
- Initial Git base: `f61337c15 docs(authoring): correct PMCP-072 evidence wording`.
- Existing Smart Tiles/world-map edits, the host lockfile, and the untracked
  `.superpowers` prototype are external work and must never be staged.
- This phase changes no `FG-*` mechanic status and does not edit the gameplay
  roadmap.

## Phase exit contract

- Editor reads originate from one immutable Authoring snapshot per opened
  project and preserve UI ordering, typed models, diagnostics, and pagination.
- Product mutations use the Authoring plan/apply/history contracts at the
  migrated composition boundaries; receipts and conflicts are presented to UI
  code without importing Flutter into `map_authoring`.
- The selected MCP SDK/version/transport matrix is executable and documented.
- MCP read tools/resources inspect a real fixture and cannot write.
- MCP mutation tools expose plan/apply rather than one tool per action, keep
  retries idempotent, surface conflicts unchanged, and require confirmations.
- Render/playtest/job/artifact/history/recovery capabilities are advertised
  only when the configured Dart backend actually supports them.

## Task 1 — PMCP-080: editor read migration

**Files:**

- Create `packages/map_editor/lib/src/application/authoring_api/authoring_query_adapter.dart`.
- Create `packages/map_editor/lib/src/infrastructure/authoring_api/editor_project_file_reader.dart`.
- Create `packages/map_editor/test/authoring_api/editor_read_parity_test.dart`.
- Modify `packages/map_editor/pubspec.yaml` and the focused repository/provider
  composition files required to share one adapter.
- Create `reports/analysis/pmcp_080_editor_read_migration_evidence.md`.

- [ ] Write parity tests that open the reference fixture, compare typed project
  and map projections with the legacy decoder, assert stable search/pagination,
  reject a path outside the allowed root, and enforce a measured fixture budget.
- [ ] Run the test and record the expected missing-adapter failure.
- [ ] Implement one cached snapshot session with explicit close/invalidate;
  provide typed project/map reads and JSON query/validation projections.
- [ ] Inject the adapter at the editor repository composition root without
  changing any mutation behavior in this lot.
- [ ] Run focused tests, the complete editor suite/analyzer when affordable,
  `flutter build macos --debug` (or document the exact platform blocker), and
  write the evidence report.
- [ ] Stage only PMCP-080 paths, run `git diff --cached --check`, and commit
  `feat(editor): read projects through authoring snapshots`.

## Task 2 — PMCP-081: editor mutation migration

**Files:**

- Create `packages/map_editor/lib/src/application/authoring_api/authoring_mutation_adapter.dart`.
- Create `packages/map_editor/lib/src/application/authoring_api/editor_receipt_presenter.dart`.
- Create `packages/map_editor/test/authoring_api/editor_mutation_parity_test.dart`.
- Create `packages/map_editor/test/authoring_api/editor_write_boundary_test.dart`.
- Modify only clean editor repository/use-case composition files selected by
  the write-boundary inventory; do not touch the concurrent Smart Tiles files.
- Create `reports/analysis/pmcp_081_editor_mutation_migration_evidence.md`.

- [ ] Write failing tests for direct/API receipt parity, plan-before-apply,
  idempotent retry, stale external change, history-backed undo, and UI-safe
  conflict/confirmation presentation.
- [ ] Write a failing static guardrail that inventories project writes and
  accepts only named Authoring adapters plus explicitly documented platform
  sinks outside project authoring.
- [ ] Implement a session-bound mutation adapter over
  `AuthoringMutationApiPort`; it must never manufacture success receipts or
  swallow domain codes.
- [ ] Route the clean central project/map authoring composition boundaries
  through that adapter and keep Flutter types out of `map_authoring`.
- [ ] Run focused parity/guardrail tests, editor suite/analyzer/build, write the
  evidence report, and state honestly whether legacy specialized sinks keep the
  roadmap lot `PARTIAL`.
- [ ] Stage only PMCP-081 paths, check the staged diff, and commit
  `feat(editor): route mutations through authoring receipts`.

## Task 3 — PMCP-082: MCP SDK and protocol gate

**Files:**

- Create `tools/pokemap_mcp/package.json`, `package-lock.json`,
  `tsconfig.json`, `src/protocol.ts`, and focused SDK conformance tests.
- Create `reports/analysis/pmcp_082_mcp_sdk_compatibility_decision.md`.

- [ ] Pin the current official SDK and client packages rather than a moving
  range; record Node requirements and the exact npm metadata used.
- [ ] Write failing protocol tests for stdio discovery, tools/resources,
  structured content, protocol `2026-07-28`, documented fallback, and the Tasks
  extension behavior needed by PMCP-084.
- [ ] Implement the smallest server/client probe using the official SDK v2;
  include Streamable HTTP only if the stateless probe passes without adding
  project semantics to TypeScript.
- [ ] Run `npm test`, `npm run typecheck`, and `npm run build`; document the
  reproducible matrix, upgrade policy, and fallback.
- [ ] Stage only PMCP-082 paths, check the staged diff, and commit
  `build(mcp): select official sdk and protocol`.

## Task 4 — PMCP-083: read-only MCP and resources

**Files:**

- Create `tools/pokemap_mcp/src/authoring_client.ts`, server composition,
  read-only tool modules, resource modules, documentation, tests, and golden
  transcripts.
- Create `reports/analysis/pmcp_083_read_only_mcp_evidence.md`.

- [ ] Write failing tests for the stable tool list, schemas, real project open
  and query, validation, artifact read, pagination, invalid handles, invalid
  resource URIs, root escape, and absence of mutation tools.
- [ ] Implement a long-lived JSONL child-process client with correlated request
  IDs, bounded lines/timeouts, stderr isolation, close/kill cleanup, and no
  project parser.
- [ ] Register exactly `pokemap_describe`, read-only `pokemap_workspace`,
  `pokemap_query`, read-only `pokemap_validate`, and read-only
  `pokemap_artifact`, plus project/map/catalog/diagnostics templates.
- [ ] Run unit, protocol, golden, typecheck, build, and real-fixture smoke tests;
  write local connection documentation and the evidence report.
- [ ] Stage only PMCP-083 paths, check the staged diff, and commit
  `feat(mcp): add read-only pokemap server`.

## Task 5 — PMCP-084: mutation, render, playtest, jobs, history

**Files:**

- Extend the Dart JSONL backend only where protocol-neutral capabilities from
  phases 5/6 are not yet dispatchable.
- Extend `tools/pokemap_mcp/src/tools/`, `src/resources/`, client, tests, and
  transcripts without adding action-specific MCP tools.
- Create `reports/analysis/pmcp_084_full_mcp_authoring_evidence.md`.

- [ ] Write failing tests for plan/apply/confirmation, idempotent retry, stale
  conflict, render artifact, sandboxed playtest receipt, job status/events/
  cancel, history undo, and permission-gated recovery.
- [ ] Register exactly `pokemap_plan`, `pokemap_apply`, `pokemap_render`,
  `pokemap_playtest`, `pokemap_job`, `pokemap_history`, and
  `pokemap_recovery`; keep action growth behind `pokemap_apply`.
- [ ] Map Dart error envelopes into repairable MCP structured content without
  changing domain codes, retryability, remediation, or confirmation rules.
- [ ] Prove a real fixture batch can plan, preview, validate, apply, retry, and
  return artifacts; never advertise runtime-only capabilities without a real
  configured backend.
- [ ] Run Dart tests/analyzer plus all MCP tests/typecheck/build and the parity
  matrix; write the evidence report with remaining runtime-host limits.
- [ ] Stage only PMCP-084 paths, check the staged diff, and commit
  `feat(mcp): expose full authoring workflow`.

## Final verification and critique

- [ ] Re-read every PMCP-080…084 done criterion and mark `DONE`, `PARTIAL`, or
  `BLOCKED` from fresh proof only.
- [ ] Run five named local passes: Audit/Architecture, Implementation, Tests,
  Build/Validation, and Final Critique.
- [ ] Confirm every created source file is represented in the required evidence
  appendix/content and every external dirty file remains unstaged.
- [ ] Report exact commands/results, final commit list, known limits, and final
  `git status --short --untracked-files=all`; do not push.
