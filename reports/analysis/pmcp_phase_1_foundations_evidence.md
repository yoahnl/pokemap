# PMCP — Phase 1 Foundations Evidence Pack

Date: 2026-07-31  
Scope: `PMCP-000`, `PMCP-001`, `PMCP-002`, `PMCP-003`  
Repository: PokeMap  
Verdict: **phase 1 implemented and eligible to be proposed `DONE`**

## 1. Executive verdict

Phase 1 now provides the pure-Dart foundation required by every future
Authoring API consumer:

- a deterministic repository capability baseline;
- a new `map_authoring` package with machine-tested dependency boundaries;
- versioned JSON contracts for resources, schemas, capabilities, and actions;
- deterministic action and resource-kind registries;
- standard request, result, error, diff, receipt, and artifact envelopes;
- a reusable test-only contract kit proving dry-run safety, single application,
  and idempotent retry;
- deterministic generated registry documentation.

This phase deliberately does **not** read or mutate a real PokeMap workspace.
Those capabilities begin with `PMCP-010` and the later safe-write lots.
Consequently, this report does not claim that an MCP can already create maps;
it establishes the stable boundary on which that MCP will later depend.

## 2. Proposed lot status

| Lot | Proposed status | Fresh proof |
|---|---|---|
| `PMCP-000` | `DONE` | 1,693-row inventory, generated twice with identical SHA-256; inventory tests green |
| `PMCP-001` | `DONE` | pure-Dart package created; architecture guard green; test and analyzer green |
| `PMCP-002` | `DONE` | descriptors and deterministic registries implemented; JSON and registry tests green |
| `PMCP-003` | `DONE` | envelopes, redacted errors, diffs, receipts, contract kit, and docs implemented; tests green |

The roadmap files were not edited because the request asked for implementation,
not a roadmap status mutation. The table above is the evidence-backed status
proposal.

## 3. Initial audit

### 3.1 Initial Git state

The working tree was inspected before edits:

```text
?? pokemap_authoring_api_mcp_lot_roadmap.md
?? pokemap_authoring_api_mcp_phase_roadmap.md
main
```

The two roadmap files were pre-existing untracked user work. They were read as
specifications and preserved without modification.

### 3.2 Repository findings

The audit identified the following authoritative sources:

- the approved dotted-action catalog;
- generated Freezed mixins for the `ProjectManifest` and `MapData` fields;
- `map_editor` authoring use-case declarations;
- pure `map_core` authoring operation files and their tests;
- the PokeMap Eval command catalog and runner tests.

There was no existing canonical pure-Dart Authoring API package. Editor use
cases, core operations, and evaluation commands existed, but they did not share
one versioned request/result/action boundary.

### 3.3 Architecture decisions

- `map_authoring` is pure Dart and depends only on `map_core`.
- Flutter, Flame, editor, runtime, battle, gameplay, and MCP protocol types are
  forbidden from the canonical package.
- Platform adapters remain owned by `map_editor`, `map_runtime`, and the future
  MCP package.
- Unknown top-level JSON fields are rejected. Forward-compatible data must use
  the explicit immutable `extensions` map.
- Reserved keys cannot be smuggled through `extensions`.
- Registry output is canonicalized and sorted independently of registration
  order.
- Errors reject absolute-path and stack-trace leakage.
- Diffs preserve the distinction between an omitted value and an explicit JSON
  `null`.
- No real filesystem mutation, transaction, undo, CLI, or MCP transport was
  introduced in this phase.

## 4. Independent named passes

No sub-agent was launched: the active multi-agent instruction explicitly
forbade delegation unless the user asked for it. To preserve the repository
reporting requirement for independent verdicts, the work was separated into
the following named passes:

| Pass | Focus | Verdict |
|---|---|---|
| Audit / Architecture | boundaries, sources, scope, non-goals | `PASS` |
| Implementation | minimal production code for `PMCP-000` through `003` | `PASS` |
| Test / Contract | red-green TDD, serialization, determinism, safety | `PASS` |
| Build / Validation | full package tests, analyzers, formatting, generator | `PASS` |
| Final Critical Review | adversarial contract and leakage review | `PASS_WITH_FIXES`, then `PASS` after six fixes |

The final critical pass found and corrected:

1. unsorted nested evidence and FG-lot lists in the inventory;
2. an inventory decoder that did not reject an unsupported format version;
3. action IDs that could omit the required dotted namespace;
4. error leakage guards that missed `/workspace`, `trace`, and raw `#0` stack
   lines;
5. diffs that could not distinguish omitted values from explicit `null`;
6. malformed receipt timestamps leaking `ArgumentError` instead of the
   documented `FormatException`.

Each correction first received a failing regression test and then a passing
implementation.

## 5. File inventory and impact

### 5.1 Modified tracked file

- `packages/map_core/lib/map_core.dart`
  - Zone: public export barrel, line 343 after implementation.
  - Change: exports the new capability inventory model.
  - Impact: repository tooling and tests can consume the model through the
    stable `map_core` public API; no gameplay behavior changes.

Exact diff:

```diff
@@ -340,3 +340,4 @@ export 'src/save/save_contract_exception.dart';
 export 'src/save/save_envelope.dart';
 export 'src/save/save_envelope_codec.dart';
 export 'src/save/save_migration.dart';
+export 'src/tooling/authoring_capability_inventory.dart';
```

### 5.2 Phase execution plan

- `pokemap_authoring_api_mcp_phase_1_implementation_plan.md`
  - Detailed red-green implementation and verification plan for all four lots.

### 5.3 `PMCP-000` inventory implementation

- `packages/map_core/lib/src/tooling/authoring_capability_inventory.dart`
  - Immutable inventory row/model, enums, validation, canonical JSON, Markdown
    rendering, and deterministic nested ordering.
- `packages/map_core/lib/src/tooling/repository_authoring_capability_collector.dart`
  - Repository scanner for catalog actions, model fields, editor use cases,
    core operations, evaluation commands, source ownership, consumers, FG lots,
    and proof files.
- `packages/map_core/test/authoring_capability_inventory_test.dart`
  - Fourteen focused tests for deterministic collection, complete dimensions,
    evidence validity, canonical JSON, supported proofs, and format guards.
- `packages/map_core/tool/generate_authoring_capability_inventory.dart`
  - Reproducible repository-root-aware generator.
- `reports/analysis/pmcp_000_authoring_capability_baseline.md`
  - Generated 1,693-row baseline and coverage counts.

### 5.4 `PMCP-001` package and boundaries

- `packages/map_authoring/pubspec.yaml`
  - Pure-Dart package definition with only `map_core` as a production
    dependency.
- `packages/map_authoring/analysis_options.yaml`
  - Repository lint baseline.
- `packages/map_authoring/lib/map_authoring.dart`
  - Public package barrel.
- `packages/map_authoring/lib/src/architecture/package_boundaries.dart`
  - Machine-readable dependency and adapter ownership rules.
- `packages/map_authoring/test/package_boundary_test.dart`
  - Guard against Flutter, Flame, editor, runtime, gameplay, and battle imports.

### 5.5 `PMCP-002` contracts and registries

- `packages/map_authoring/lib/src/contracts/json_contract_support.dart`
  - Strict JSON parsing, immutable map/list copying, extension handling, and
    validation helpers.
- `packages/map_authoring/lib/src/contracts/resource_ref.dart`
  - Typed versioned resource references.
- `packages/map_authoring/lib/src/contracts/schema_descriptor.dart`
  - Versioned input/output schema metadata.
- `packages/map_authoring/lib/src/contracts/capability_descriptor.dart`
  - Versioned capability descriptor.
- `packages/map_authoring/lib/src/contracts/action_descriptor.dart`
  - Dotted action ID, risk, permissions, guarantees, schemas, capabilities, and
    metadata.
- `packages/map_authoring/lib/src/registry/action_registry.dart`
  - Deterministic action registration, duplicate/incompatible-version guards,
    lookup, and canonical JSON.
- `packages/map_authoring/lib/src/registry/resource_kind_registry.dart`
  - Deterministic resource-kind registration and canonical minimal kinds:
    `project`, `map`, `layer`, and `region`.
- `packages/map_authoring/test/contracts/descriptor_json_test.dart`
  - Strict JSON, extension, canonicalization, validation, and round-trip tests.
- `packages/map_authoring/test/registry/action_registry_test.dart`
  - Ordering, collision, version, lookup, round-trip, and minimal-kind tests.

### 5.6 `PMCP-003` envelopes and contract kit

- `packages/map_authoring/lib/src/contracts/authoring_request.dart`
  - Request ID, action ID, parameters, dry-run flag, expected revision, and
    idempotency key.
- `packages/map_authoring/lib/src/contracts/authoring_error.dart`
  - Stable error code/message/details envelope with machine-path and stack-trace
    leakage rejection.
- `packages/map_authoring/lib/src/contracts/authoring_diff.dart`
  - Typed diff entries preserving omitted versus explicit-null values.
- `packages/map_authoring/lib/src/contracts/authoring_receipt.dart`
  - Mutation receipt, revision transition, timestamp, touched resources, and
    recovery metadata.
- `packages/map_authoring/lib/src/contracts/authoring_result.dart`
  - Success/failure invariants, output, warnings, diff, receipt, and safe
    artifact references.
- `packages/map_authoring/lib/src/tooling/registry_documentation.dart`
  - Deterministic Markdown registry documentation renderer.
- `packages/map_authoring/test/contracts/envelope_json_test.dart`
  - Envelope invariants, redaction, URI restrictions, malformed timestamp, and
    explicit-null round-trip tests.
- `packages/map_authoring/test/contract_kit/authoring_action_contract.dart`
  - Reusable test-only fake repository and standard action-contract harness.
- `packages/map_authoring/test/contract_kit/authoring_action_contract_test.dart`
  - Demonstrates dry-run non-mutation, apply-once behavior, and idempotent retry.
- `packages/map_authoring/test/tooling/registry_documentation_test.dart`
  - Stable output and registration-order independence.

### 5.7 Evidence artifacts

- `reports/analysis/pmcp_phase_1_created_files_full_content.md`
  - Full-content appendix for all 30 implementation, test, configuration,
    generated-baseline, and execution-plan files created during this phase.
- `reports/analysis/pmcp_phase_1_foundations_evidence.md`
  - This audit, verification, and handoff report.

The evidence report and appendix cannot recursively embed themselves. All other
created files are reproduced in full in the appendix.

## 6. `PMCP-000` baseline result

Final generated counts:

| Dimension | Count |
|---|---:|
| Catalog actions | 1,391 |
| `ProjectManifest` fields | 41 |
| `MapData` fields | 16 |
| `map_editor` use cases | 185 |
| `map_core` authoring operation files | 29 |
| PokeMap Eval commands | 31 |
| Total rows | 1,693 |
| `SUPPORTED` | 50 |
| `MISSING` | 1,643 |
| `BLOCKED` | 0 |
| `NOT_APPLICABLE` | 0 |

`SUPPORTED` is intentionally conservative: every such row has both a source
file and existing test evidence. Existing code without a canonical Authoring
API proof remains `MISSING`.

The generator was executed twice after the final code changes:

```text
Generated 1693 capability rows at
/Users/karim/Project/pokemonProject/reports/analysis/pmcp_000_authoring_capability_baseline.md
d080a5421c0364a4a841fac21395c13e2f840e13df8dfab1f26311a0ff89435f
```

The SHA-256 was identical on both executions.

## 7. TDD evidence

The implementation followed red-green-refactor checkpoints:

- inventory model tests initially failed because the types did not exist;
- repository collector tests initially failed because the collector did not
  exist;
- package-boundary tests initially failed because `map_authoring` and its barrel
  did not exist;
- descriptor tests initially failed on missing public contracts;
- registry tests initially failed on missing registry types;
- envelope tests initially failed on missing request/result/error/diff/receipt
  types;
- contract-kit and documentation tests initially failed on their missing
  helpers;
- the six critical-review regressions failed for the specific defects listed in
  section 4 before their fixes were applied.

Relevant green checkpoints:

```text
packages/map_core:
dart test test/authoring_capability_inventory_test.dart
+14: All tests passed!

packages/map_authoring:
dart test test/contracts/descriptor_json_test.dart \
  test/contracts/envelope_json_test.dart
+19: All tests passed!
```

Earlier pre-review checkpoints were also green (`+12` inventory tests and `+33`
package tests), then were superseded by the final regression-expanded suites.

## 8. Final commands and exact results

### 8.1 `map_core`

```text
Command:
cd packages/map_core
set -o pipefail
dart test --reporter expanded 2>&1 | tail -n 5

Result:
+4656: All tests passed!
Exit code: 0
```

```text
Command:
cd packages/map_core
dart analyze

Result:
Analyzing map_core...
No issues found!
Exit code: 0
```

```text
Command:
cd packages/map_core
dart format --output=none --set-exit-if-changed \
  lib/src/tooling \
  test/authoring_capability_inventory_test.dart \
  tool/generate_authoring_capability_inventory.dart

Result:
Formatted 6 files (0 changed) in 0.01 seconds.
Exit code: 0
```

### 8.2 `map_authoring`

```text
Command:
cd packages/map_authoring
set -o pipefail
dart test --reporter expanded 2>&1 | tail -n 5

Result:
+35: All tests passed!
Exit code: 0
```

```text
Command:
cd packages/map_authoring
dart analyze

Result:
Analyzing map_authoring...
No issues found!
Exit code: 0
```

```text
Command:
cd packages/map_authoring
dart format --output=none --set-exit-if-changed lib test

Result:
Formatted 22 files (0 changed) in 0.03 seconds.
Exit code: 0
```

### 8.3 Determinism and repository hygiene

```text
Command, run twice:
cd packages/map_core
dart run tool/generate_authoring_capability_inventory.dart
shasum -a 256 \
  ../../reports/analysis/pmcp_000_authoring_capability_baseline.md

Result on both runs:
Generated 1693 capability rows ...
d080a5421c0364a4a841fac21395c13e2f840e13df8dfab1f26311a0ff89435f
Exit code: 0
```

```text
Command:
git diff --check

Result:
No output.
Exit code: 0
```

The first manual forbidden-import scan included the architecture test itself
and therefore matched its literal forbidden-package fixtures, exiting `1`.
The corrected production-source-only scan was:

```text
if rg -n \
  "package:(flutter|flame|map_editor|map_runtime|map_gameplay|map_battle)/" \
  packages/map_authoring/lib
then
  exit 1
fi
```

Result: no matches, exit code `0`.

### 8.4 Build evidence

`map_core` and `map_authoring` are pure Dart libraries and this phase adds no
executable or deployable artifact, so there is no meaningful app build command.
The proportional build proof is compilation of every test target plus
package-wide static analysis. Both packages passed those checks.

No Flutter or Flame command was necessary because the phase intentionally did
not change `map_editor`, `map_runtime`, or gameplay behavior.

## 9. Final Git state

Current branch: `main`

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_authoring/analysis_options.yaml
?? packages/map_authoring/lib/map_authoring.dart
?? packages/map_authoring/lib/src/architecture/package_boundaries.dart
?? packages/map_authoring/lib/src/contracts/action_descriptor.dart
?? packages/map_authoring/lib/src/contracts/authoring_diff.dart
?? packages/map_authoring/lib/src/contracts/authoring_error.dart
?? packages/map_authoring/lib/src/contracts/authoring_receipt.dart
?? packages/map_authoring/lib/src/contracts/authoring_request.dart
?? packages/map_authoring/lib/src/contracts/authoring_result.dart
?? packages/map_authoring/lib/src/contracts/capability_descriptor.dart
?? packages/map_authoring/lib/src/contracts/json_contract_support.dart
?? packages/map_authoring/lib/src/contracts/resource_ref.dart
?? packages/map_authoring/lib/src/contracts/schema_descriptor.dart
?? packages/map_authoring/lib/src/registry/action_registry.dart
?? packages/map_authoring/lib/src/registry/resource_kind_registry.dart
?? packages/map_authoring/lib/src/tooling/registry_documentation.dart
?? packages/map_authoring/pubspec.yaml
?? packages/map_authoring/test/contract_kit/authoring_action_contract.dart
?? packages/map_authoring/test/contract_kit/authoring_action_contract_test.dart
?? packages/map_authoring/test/contracts/descriptor_json_test.dart
?? packages/map_authoring/test/contracts/envelope_json_test.dart
?? packages/map_authoring/test/package_boundary_test.dart
?? packages/map_authoring/test/registry/action_registry_test.dart
?? packages/map_authoring/test/tooling/registry_documentation_test.dart
?? packages/map_core/lib/src/tooling/authoring_capability_inventory.dart
?? packages/map_core/lib/src/tooling/repository_authoring_capability_collector.dart
?? packages/map_core/test/authoring_capability_inventory_test.dart
?? packages/map_core/tool/generate_authoring_capability_inventory.dart
?? pokemap_authoring_api_mcp_lot_roadmap.md
?? pokemap_authoring_api_mcp_phase_1_implementation_plan.md
?? pokemap_authoring_api_mcp_phase_roadmap.md
?? reports/analysis/pmcp_000_authoring_capability_baseline.md
?? reports/analysis/pmcp_phase_1_created_files_full_content.md
?? reports/analysis/pmcp_phase_1_foundations_evidence.md
```

The two roadmap files in this list are the same pre-existing untracked files
recorded in the initial state; all other untracked paths are phase 1 outputs.

No Git write operation was performed: no add, commit, branch switch, merge,
stash, reset, or push. The implementation remains in the current working tree
for the user to review.

## 10. Self-critique and known risks

### Strengths

- The canonical boundary is small, pure Dart, and independently testable.
- Determinism is asserted at row, registry, JSON, Markdown, and generator
  levels.
- Extension behavior is explicit instead of silently swallowing future fields.
- Error and artifact contracts are defensive before real workspace access is
  introduced.
- Full `map_core` regression coverage proves no observed behavior change in the
  existing package.

### Risks and limitations

1. The capability collector is intentionally source-convention-aware. Renaming
   generated mixins, use-case declarations, or catalog headings may require the
   collector to evolve.
2. The baseline records current repository evidence; it is not yet a runtime
   conformance suite and must not be interpreted as MCP parity.
3. Error redaction is a contract guard, not a replacement for producer-side
   path hygiene. Workspace implementations must still avoid producing secrets
   and machine paths.
4. Idempotency and dry-run are proven through a test fake only. Real atomic
   filesystem behavior belongs to the phase 3 safe-write kernel.
5. The action registry infrastructure is ready, but the 1,391 catalog actions
   are not yet implemented or bulk-registered as executable handlers.
6. There is no workspace root canonicalization, symlink defense, pagination,
   query engine, revision storage, or MCP transport in phase 1.
7. The generated baseline is large by design. It should remain generated and
   reviewed by summary/hash rather than manually edited.

## 11. Handoff

The phase 1 exit condition is met: contracts and registries are stable enough
to begin **Phase 2 — API de lecture**, starting with:

```text
PMCP-010 — Workspace sûr et handles explicites
```

Recommended next proof: open a real fixture project through `map_authoring`
without Flutter, enforce allowed roots and symlink containment, and return an
explicit workspace handle through the request/result contracts created here.

## 12. Full-content appendix

The complete contents of every non-self-referential file created by this phase
are preserved in:

`reports/analysis/pmcp_phase_1_created_files_full_content.md`
