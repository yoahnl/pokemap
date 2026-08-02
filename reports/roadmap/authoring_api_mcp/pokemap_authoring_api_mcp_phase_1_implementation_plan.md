# PokeMap Authoring API + MCP Phase 1 Implementation Plan

> **For Codex:** Use the local `executing-plans`,
> `test-driven-development`, and `verification-before-completion` workflows.
> Execute each task in order and preserve red/green evidence.

**Goal:** Implement `PMCP-000` through `PMCP-003`: a verifiable authoring
capability baseline, the pure-Dart `map_authoring` package, its public
descriptors and registries, and its common request/result/error/diff/receipt
contracts.

**Architecture:** Repository inspection remains tooling-only. Canonical
authoring contracts live in a new pure-Dart package that depends only on
`map_core`. All public JSON contracts preserve unknown future fields in an
explicit `extensions` map, reject collisions with reserved fields, and remain
independent from Flutter, Flame, MCP, filesystem mutation, and runtime
adapters.

**Tech Stack:** Dart 3.4+, `package:test`, `package:lints`, `map_core`, manual
immutable JSON codecs, deterministic Markdown generation.

---

## Scope decisions

- Work in the current workspace because repository rules prohibit creating a
  branch or worktree without a separate explicit Git authorization.
- Do not modify any consumer pubspec in phase 1.
- Do not implement workspace loading, queries, mutations, transactions, CLI,
  runtime adapters, editor adapters, or MCP tools.
- Treat `SUPPORTED` as an evidence-backed baseline status. Existing source
  without an associated proof remains `MISSING` for the canonical API.
- Generate the `PMCP-000` report from repository facts so repeated generation
  is byte-identical.
- Keep the detailed roadmaps unchanged; propose their status in the evidence
  report instead of editing roadmap status.

## Task 1: PMCP-000 — Capability inventory model

**Files:**

- Create:
  `packages/map_core/test/authoring_capability_inventory_test.dart`
- Create:
  `packages/map_core/lib/src/tooling/authoring_capability_inventory.dart`
- Modify: `packages/map_core/lib/map_core.dart`

### Step 1: Write failing model tests

Cover:

- all four statuses;
- deterministic ordering independent of input order;
- duplicate identifier rejection;
- required owner, source reference, and runtime consumer;
- `SUPPORTED` rejection without evidence;
- deterministic JSON and Markdown rendering.

### Step 2: Verify RED

Run:

```bash
cd packages/map_core
dart test test/authoring_capability_inventory_test.dart
```

Expected: compilation failure because the inventory contracts do not exist.

### Step 3: Implement the minimal inventory contracts

Implement:

- `AuthoringCapabilityStatus`;
- `AuthoringCapabilityKind`;
- `AuthoringCapabilityInventoryEntry`;
- `AuthoringCapabilityInventory`;
- validation, immutable collections, `toJson`, and deterministic Markdown.

Export the contracts from `map_core.dart`.

### Step 4: Verify GREEN

Run the same targeted test and require exit code 0.

## Task 2: PMCP-000 — Repository collector and baseline report

**Files:**

- Modify:
  `packages/map_core/test/authoring_capability_inventory_test.dart`
- Create:
  `packages/map_core/lib/src/tooling/repository_authoring_capability_collector.dart`
- Create:
  `packages/map_core/tool/generate_authoring_capability_inventory.dart`
- Create:
  `reports/analysis/pmcp_000_authoring_capability_baseline.md`

### Step 1: Write failing collector tests

Cover:

- every serialized key of a minimal `ProjectManifest`;
- every serialized key of a minimal `MapData`;
- every command declared by `evaluationCommandCatalog`;
- public editor classes ending in `UseCase`;
- pure `map_core/src/authoring` operation files;
- dotted action identifiers from the approved action catalog;
- stable output over two collection runs;
- no `SUPPORTED` entry without an existing evidence file.

### Step 2: Verify RED

Run the targeted map_core test and confirm the collector is missing.

### Step 3: Implement repository collection

The collector receives an explicit repository root and:

- derives model keys from minimal model JSON;
- parses command IDs from the evaluation command catalog;
- parses public use-case declarations from editor application sources;
- inventories pure authoring operation files;
- parses dotted action IDs from the approved catalog;
- assigns deterministic owners, status, source, runtime consumer, evidence,
  related `FG-*` lots, and canonical-mutation truth.

### Step 4: Generate the report twice

Run:

```bash
cd packages/map_core
dart run tool/generate_authoring_capability_inventory.dart
shasum -a 256 ../../reports/analysis/pmcp_000_authoring_capability_baseline.md
dart run tool/generate_authoring_capability_inventory.dart
shasum -a 256 ../../reports/analysis/pmcp_000_authoring_capability_baseline.md
```

Require identical hashes.

### Step 5: Verify GREEN

Run the targeted map_core test and require exit code 0.

## Task 3: PMCP-001 — Pure-Dart package boundary

**Files:**

- Create: `packages/map_authoring/pubspec.yaml`
- Create: `packages/map_authoring/analysis_options.yaml`
- Create: `packages/map_authoring/lib/map_authoring.dart`
- Create:
  `packages/map_authoring/lib/src/architecture/package_boundaries.dart`
- Create: `packages/map_authoring/test/package_boundary_test.dart`

### Step 1: Scaffold configuration only

Create the package manifest and analysis configuration so tests can resolve.
Dependencies are limited to `map_core`; dev dependencies are `lints` and
`test`.

### Step 2: Write failing architecture tests

Cover:

- declared package ownership and allowed dependency set;
- source scan rejecting `package:flutter` and `package:flame`;
- source scan rejecting imports of editor/runtime packages;
- public barrel existence and compilation.

### Step 3: Verify RED

Run:

```bash
cd packages/map_authoring
dart pub get
dart test test/package_boundary_test.dart
```

Expected: compilation failure because boundary contracts do not exist.

### Step 4: Implement boundaries and barrel

Document:

- contracts and orchestration owned by `map_authoring`;
- data models owned by `map_core`;
- Flutter/runtime adapters owned by their consumer packages;
- MCP protocol translation owned outside all Dart product packages.

### Step 5: Verify GREEN

Run the targeted boundary test and require exit code 0.

## Task 4: PMCP-002 — Descriptors and resource references

**Files:**

- Create:
  `packages/map_authoring/test/contracts/descriptor_json_test.dart`
- Create:
  `packages/map_authoring/lib/src/contracts/json_contract_support.dart`
- Create:
  `packages/map_authoring/lib/src/contracts/resource_ref.dart`
- Create:
  `packages/map_authoring/lib/src/contracts/schema_descriptor.dart`
- Create:
  `packages/map_authoring/lib/src/contracts/capability_descriptor.dart`
- Create:
  `packages/map_authoring/lib/src/contracts/action_descriptor.dart`
- Modify: `packages/map_authoring/lib/map_authoring.dart`

### Step 1: Write failing descriptor tests

Cover positive, negative, guardrail, and non-regression cases for:

- typed resource references;
- schema descriptors;
- capability descriptors;
- action risk, permissions, and guarantees;
- JSON round-trips;
- preservation of unknown fields;
- rejection of extension collisions with reserved fields;
- immutable public collections.

### Step 2: Verify RED

Run the descriptor test and confirm compilation fails for missing contracts.

### Step 3: Implement minimal immutable contracts

Use handwritten codecs with:

- strict required-field and enum decoding;
- positive integer contract versions;
- normalized non-empty identifiers;
- explicit `extensions`;
- deterministic key ordering;
- no MCP types or vocabulary.

### Step 4: Verify GREEN

Run the descriptor test and require exit code 0.

## Task 5: PMCP-002 — Deterministic registries

**Files:**

- Create:
  `packages/map_authoring/test/registry/action_registry_test.dart`
- Create:
  `packages/map_authoring/lib/src/registry/action_registry.dart`
- Create:
  `packages/map_authoring/lib/src/registry/resource_kind_registry.dart`
- Modify: `packages/map_authoring/lib/map_authoring.dart`

### Step 1: Write failing registry tests

Cover:

- stable ordering independent of registration order;
- lookup by ID;
- duplicate ID and version rejection;
- incompatible version rejection;
- unknown lookup;
- minimal resource kinds `project`, `map`, `layer`, and `region`;
- deterministic registry JSON.

### Step 2: Verify RED

Run the registry test and confirm compilation fails for missing registries.

### Step 3: Implement registries

Provide immutable sorted descriptors, explicit registration exceptions, and
the canonical minimal resource registry.

### Step 4: Verify GREEN

Run the registry test and require exit code 0.

## Task 6: PMCP-003 — Common envelopes

**Files:**

- Create:
  `packages/map_authoring/test/contracts/envelope_json_test.dart`
- Create:
  `packages/map_authoring/lib/src/contracts/authoring_request.dart`
- Create:
  `packages/map_authoring/lib/src/contracts/authoring_error.dart`
- Create:
  `packages/map_authoring/lib/src/contracts/authoring_diff.dart`
- Create:
  `packages/map_authoring/lib/src/contracts/authoring_receipt.dart`
- Create:
  `packages/map_authoring/lib/src/contracts/authoring_result.dart`
- Modify: `packages/map_authoring/lib/map_authoring.dart`

### Step 1: Write failing envelope tests

Cover:

- request/result/error/diff/receipt round-trips;
- request revision, idempotency key, and dry-run fields;
- success/failure invariant enforcement;
- deterministic diff ordering;
- compact artifact references;
- rejection of stack traces and machine paths;
- preservation of safe future fields;
- invalid enum and malformed JSON failures.

### Step 2: Verify RED

Run the envelope test and confirm compilation fails for missing contracts.

### Step 3: Implement minimal envelope contracts

Keep all maps and lists immutable. Reject contradictory result states and
unsafe diagnostic content at construction and decode time.

### Step 4: Verify GREEN

Run the envelope test and require exit code 0.

## Task 7: PMCP-003 — Contract kit and registry documentation

**Files:**

- Create:
  `packages/map_authoring/test/contract_kit/authoring_action_contract.dart`
- Create:
  `packages/map_authoring/test/contract_kit/authoring_action_contract_test.dart`
- Create:
  `packages/map_authoring/test/tooling/registry_documentation_test.dart`
- Create:
  `packages/map_authoring/lib/src/tooling/registry_documentation.dart`
- Modify: `packages/map_authoring/lib/map_authoring.dart`

### Step 1: Write failing contract-kit tests

Cover:

- fake repository dry-run without mutation;
- apply mutation exactly once;
- retry by request/idempotency key without duplicate application;
- deterministic registry documentation independent of input order.

### Step 2: Verify RED

Run both targeted tests and confirm the missing behavior.

### Step 3: Implement the test kit and documentation renderer

Keep the fake repository under `test/`. Production code only receives the
deterministic documentation renderer.

### Step 4: Verify GREEN

Run both targeted tests and require exit code 0.

## Task 8: Format and package verification

### Step 1: Format changed Dart files

```bash
dart format packages/map_core/lib/src/tooling \
  packages/map_core/tool/generate_authoring_capability_inventory.dart \
  packages/map_core/test/authoring_capability_inventory_test.dart \
  packages/map_authoring/lib \
  packages/map_authoring/test
```

### Step 2: Verify `map_authoring`

```bash
cd packages/map_authoring
dart test
dart analyze
```

### Step 3: Verify `map_core`

```bash
cd packages/map_core
dart test test/authoring_capability_inventory_test.dart
dart analyze
dart test
```

### Step 4: Best available build proof

Pure Dart libraries do not produce an application binary in this phase. Use
successful `dart analyze`, complete package tests, and a tool execution as the
build-equivalent proof.

## Task 9: Evidence report and critical review

**Files:**

- Complete:
  `reports/analysis/pmcp_000_authoring_capability_baseline.md`
- Create:
  `reports/analysis/pmcp_phase_1_foundations_evidence.md`

### Step 1: Run named review passes

- Audit / Architecture pass;
- Implementation pass;
- Tests pass;
- Build / Validation pass;
- Final Critical Review pass.

### Step 2: Inspect scope and diff

Run:

```bash
git diff --check
git diff --name-only
git status --short --untracked-files=all
```

### Step 3: Write complete evidence

Include:

- exact lot names;
- initial and final Git state;
- inventory;
- all changed files and modified zones;
- full contents of created implementation files;
- exact command results;
- preserved limits;
- verdict for each named pass;
- risks and recommended next phase;
- proposed lot statuses without changing the roadmap.

### Step 4: Final verification

Re-run the complete commands whose success will be claimed in the handoff.
