# PMCP-012 — Reference Diagnostics and Capability Truth Evidence Pack

Date: 2026-07-31
Lot: `PMCP-012 — Références, diagnostics et capability truth`
Verdict proposed: `DONE`

## Executive summary

`map_authoring` now projects the canonical `map_core` narrative dependency
index into a deterministic, path-free authoring reference API. It exposes typed
nodes and edges, dependency/dependent queries, bounded breadth-first graphs,
coded and navigable diagnostics, delete/rename impact, and picker options
adapted from the existing canonical narrative picker read model.

The lot also exposes an immutable JSON-safe capability-truth projection. It
delegates to `ProjectCapabilityTruthReport.evaluate` and accepts only explicit
`ProjectCapabilityTruthRecord` attestations plus the required capability IDs.
There is deliberately no API that infers promoted support from a
`ProjectManifest`.

## Scope confirmation

Implemented:

- typed reference identity preserving kind, scope, parent, and source kind;
- cross-domain reference extraction from a frozen `ProjectSnapshot`;
- deterministic nodes, edges, diagnostics, and JSON projections;
- dependency and dependent directions;
- iterative cycle-safe graph traversal bounded by depth and node count;
- coded missing, ambiguous, unavailable, legacy, duplicate, and cycle
  diagnostics;
- navigation intents without filesystem paths;
- direct delete and rename impact, including self-references;
- runtime-blocking impact classification;
- canonical narrative picker adaptation, including missing selections;
- explicit capability truth with promoted/deferred evidence;
- fail-closed missing/duplicate/incomplete capability diagnostics;
- deterministic capability output independent of input order.

Explicitly not implemented:

- reference mutation or automatic rewrite;
- paginated graph cursors; this lot supplies the roadmap-approved bounded form;
- non-narrative discovery engines not yet represented by the canonical
  `map_core` dependency index;
- capability inference from manifest content;
- JSONL/CLI transport (`PMCP-013`);
- filesystem writes or project mutations.

## Initial audit

Initial branch and state:

```text
5af184aff (HEAD -> main) feat(authoring): add snapshot query API
<clean working tree>
```

Relevant existing contracts inspected:

- `NarrativeDependencyKey`, definitions, usages, issues, and deterministic
  `NarrativeDependencyIndex`;
- `buildNarrativeDependencyIndex(project:, maps:)`;
- `buildCanonicalNarrativeReferencePickerReadModel`;
- `NarrativeDependencyNavigationIntent`;
- `ProjectCapabilityTruthRecord` and
  `ProjectCapabilityTruthReport.evaluate`;
- `ProjectSnapshot` from `PMCP-011`;
- strict JSON-safe `AuthoringResourceRef` extensions from phase 1.

Key design decisions:

1. `map_core` remains the sole discovery and picker-compatibility authority.
   `map_authoring` adapts those results instead of duplicating domain rules.
2. Reference keys retain every narrative qualifier. Conversion to
   `AuthoringResourceRef` stores qualifiers in safe extensions.
3. Graph traversal is iterative breadth-first traversal with a visited set.
   The response reports `truncated` when either bound prevents complete
   expansion.
4. Capability support is fail-closed and explicit. Project data is never
   accepted as capability proof.

## Named pass verdicts

No sub-agent was launched because delegation was not requested or authorized.
The required independent passes were executed inline:

| Pass | Verdict | Evidence |
|---|---|---|
| Audit / Architecture | `PASS` | canonical core index, picker, capability gate, and package boundary inspected |
| TDD / Implementation | `PASS` | missing contracts observed RED before each implementation; 12 focused tests green |
| Determinism / Safety | `PASS` | sorted output, path-free real-fixture JSON, bounded cyclic graph, JSON encoding |
| Regression | `PASS_WITH_FIX`, then `PASS` | self-reference was initially omitted from impact, reproduced by test and corrected |
| Package Validation | `PASS` | 85 package tests, analyzer, formatter, and diff check green |
| Critique finale | `PASS` | no blocker remains inside PMCP-012 scope |

## File inventory

### Modified file

`packages/map_authoring/lib/map_authoring.dart`

- Zone: canonical public exports.
- Change: exports capability truth and the three reference API modules.
- Reason: direct users and the forthcoming read API/CLI must consume one public
  package surface.

Exact diff zone:

```diff
+export 'src/domains/project/capability_truth_adapter.dart';
+export 'src/references/project_reference_index.dart';
+export 'src/references/reference_impact.dart';
+export 'src/references/reference_queries.dart';
```

### Created production files

`packages/map_authoring/lib/src/references/project_reference_index.dart`

- Stable typed identities and `AuthoringResourceRef` conversion.
- Nodes, usage edges, coded diagnostics, navigation projection.
- Adaptation from snapshots and canonical narrative indexes.
- Deterministic ordering and JSON-safe output.

`packages/map_authoring/lib/src/references/reference_queries.dart`

- Dependency/dependent queries.
- Bounded iterative graph with cycle termination and truncation signal.
- Canonical narrative picker projection.

`packages/map_authoring/lib/src/references/reference_impact.dart`

- Delete and rename impact.
- Sorted unique direct dependents, affected edges, diagnostics, and
  runtime-blocking classification.

`packages/map_authoring/lib/src/domains/project/capability_truth_adapter.dart`

- Immutable authoring records/issues/report.
- Explicit-only adapter over the canonical fail-closed core report.

### Created tests

`packages/map_authoring/test/references/project_reference_index_test.dart`

- Real P3 fixture and cross-domain snapshot adaptation.
- Typed qualifier preservation and JSON encoding.
- Dependencies, dependents, diagnostics, navigation, bounded cycles.
- Delete/rename impact including self-reference.
- Canonical picker reuse and deterministic declaration order.

`packages/map_authoring/test/domains/project/capability_truth_adapter_test.dart`

- Explicit promoted proof.
- Deferred reason preservation.
- Coded missing attestations.
- Input-order determinism.
- Proof that populated project models do not promote capabilities.

### Full-content appendix

`reports/analysis/pmcp_012_created_files_full_content.md` reproduces all six
created production and test files in full. The evidence report and appendix
exclude themselves to avoid recursive content.

## TDD evidence

Reference API RED:

```text
Command:
dart test test/references/project_reference_index_test.dart

Result:
Error: Undefined name 'ProjectReferenceIndex'.
Error: Method not found: 'ProjectReferenceQueries'.
Error: Method not found: 'ProjectReferenceImpactAnalyzer'.
+0 -1: Some tests failed.
Exit code: 1
```

Reference API first GREEN:

```text
+7: All tests passed!
Exit code: 0
```

Capability truth RED:

```text
Command:
dart test test/domains/project/capability_truth_adapter_test.dart

Result:
Error: Undefined name 'ProjectCapabilityTruthAdapter'.
+0 -1: Some tests failed.
Exit code: 1
```

Capability truth first GREEN:

```text
+5: All tests passed!
Exit code: 0
```

Critical-review regression:

```text
Expected: ['fact.old', 'scene.owner']
Actual: ['scene.owner']
+0 -1: Some tests failed.
```

The impact analyzer had removed the target from its own dependent set. The
filter was removed so self-referencing resources remain visible in rename and
delete plans.

Final focused results:

```text
dart test test/references/project_reference_index_test.dart
+7: All tests passed!

dart test test/domains/project/capability_truth_adapter_test.dart
+5: All tests passed!
```

## Final commands and exact results

Full package tests:

```text
Command:
dart test

Result:
+85: All tests passed!
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
Formatted 43 files (0 changed).
Exit code: 0
```

Diff hygiene:

```text
Command:
git diff --check

Result:
<no output>
Exit code: 0
```

Build:

`map_authoring` remains a pure Dart library and PMCP-012 adds no executable.
Compilation of every package test target plus package-wide static analysis is
the proportional build proof. The standalone executable belongs to PMCP-013.

## Final Git state before the lot commit

```text
 M packages/map_authoring/lib/map_authoring.dart
?? packages/map_authoring/lib/src/domains/project/capability_truth_adapter.dart
?? packages/map_authoring/lib/src/references/project_reference_index.dart
?? packages/map_authoring/lib/src/references/reference_impact.dart
?? packages/map_authoring/lib/src/references/reference_queries.dart
?? packages/map_authoring/test/domains/project/capability_truth_adapter_test.dart
?? packages/map_authoring/test/references/project_reference_index_test.dart
?? reports/analysis/pmcp_012_created_files_full_content.md
?? reports/analysis/pmcp_012_reference_diagnostics_evidence.md
```

## Critical self-review

Strengths:

- discovery and picker compatibility stay centralized in `map_core`;
- graph traversal cannot recurse indefinitely and has explicit response bounds;
- all reference outputs are deterministically ordered;
- opaque workspace paths never enter the real-fixture projection;
- diagnostics retain stable codes, owners, field paths, and navigation;
- self-references remain visible in destructive-operation impact;
- capability truth cannot silently infer support from project content.

Remaining risks:

1. The reference index currently covers domains emitted by the canonical
   narrative dependency builder. Later domain lots must extend that core
   discovery engine or add an equally explicit adapter before claiming global
   reference coverage.
2. The graph is bounded but not cursor-paginated. Callers that need larger
   traversals must request another bounded view after a future pagination
   contract is defined.
3. Reference metadata comes from authored project data. It is JSON-safe, but
   future secret-bearing metadata fields require a centralized redaction rule.
4. Rename impact reports direct incoming references; it does not rewrite them.
   Planning/apply mutation remains a later phase responsibility.
5. Capability truth is only as complete as the explicit records supplied by
   the caller. Missing records fail closed, which is safe but may require
   domain-specific attestation collectors later.

## Next step

Proceed to `PMCP-013 — CLI JSONL en lecture seule`: expose the shared read API
through a strict, bounded one-request/one-response JSONL worker without
duplicating business logic.

## Full-content appendix

`reports/analysis/pmcp_012_created_files_full_content.md`
