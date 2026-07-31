# PMCP Phase 1 — Full created-file contents

This appendix is part of the Phase 1 evidence pack. It preserves the complete contents of every implementation, test, generated-baseline, configuration, and execution-plan file created during PMCP-000 through PMCP-003.

The evidence report and this appendix are excluded from their own content listing because embedding either inside itself would be self-referential. The two roadmap files already present in the initial Git state are also excluded because they predate this implementation turn.

## `pokemap_authoring_api_mcp_phase_1_implementation_plan.md`

~~~~~~~~markdown
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
~~~~~~~~

## `packages/map_core/lib/src/tooling/authoring_capability_inventory.dart`

~~~~~~~~dart
/// Evidence status for one row of the PokeMap authoring capability baseline.
///
/// This status describes the canonical Authoring API coverage, not whether a
/// feature happens to exist in an editor widget or runtime component.
enum AuthoringCapabilityStatus {
  supported('SUPPORTED'),
  notApplicable('NOT_APPLICABLE'),
  blocked('BLOCKED'),
  missing('MISSING');

  const AuthoringCapabilityStatus(this.wireName);

  final String wireName;

  static AuthoringCapabilityStatus fromWireName(String value) {
    return AuthoringCapabilityStatus.values.firstWhere(
      (status) => status.wireName == value,
      orElse: () => throw FormatException(
        'Unknown authoring capability status: $value',
      ),
    );
  }
}

/// Origin of an inventory row.
enum AuthoringCapabilityKind {
  catalogAction('catalog_action'),
  projectManifestField('project_manifest_field'),
  mapDataField('map_data_field'),
  editorUseCase('editor_use_case'),
  coreOperation('core_operation'),
  evaluationCommand('evaluation_command');

  const AuthoringCapabilityKind(this.wireName);

  final String wireName;

  static AuthoringCapabilityKind fromWireName(String value) {
    return AuthoringCapabilityKind.values.firstWhere(
      (kind) => kind.wireName == value,
      orElse: () => throw FormatException(
        'Unknown authoring capability kind: $value',
      ),
    );
  }
}

/// One traceable fact in the repository-wide authoring baseline.
///
/// Every row names an owner, source, and runtime consumer even when the
/// canonical capability is missing. This prevents a UI-only implementation
/// from being mistaken for an end-to-end supported capability.
final class AuthoringCapabilityInventoryEntry {
  AuthoringCapabilityInventoryEntry({
    required String id,
    required this.kind,
    required String ownerPackage,
    required this.status,
    required String sourceReference,
    required String runtimeConsumer,
    Iterable<String> evidenceReferences = const [],
    Iterable<String> relatedFgLots = const [],
    required this.hasCanonicalMutation,
  })  : id = _requireNonBlank(id, 'id'),
        ownerPackage = _requireNonBlank(ownerPackage, 'ownerPackage'),
        sourceReference = _requireNonBlank(sourceReference, 'sourceReference'),
        runtimeConsumer = _requireNonBlank(runtimeConsumer, 'runtimeConsumer'),
        evidenceReferences = _normalizedStrings(
          evidenceReferences,
          'evidenceReference',
        ),
        relatedFgLots = _normalizedStrings(
          relatedFgLots,
          'relatedFgLot',
        ) {
    if (status == AuthoringCapabilityStatus.supported &&
        this.evidenceReferences.isEmpty) {
      throw ArgumentError.value(
        this.evidenceReferences,
        'evidenceReferences',
        'A SUPPORTED capability requires evidence',
      );
    }
  }

  factory AuthoringCapabilityInventoryEntry.fromJson(
    Map<String, dynamic> json,
  ) {
    return AuthoringCapabilityInventoryEntry(
      id: _readString(json, 'id'),
      kind: AuthoringCapabilityKind.fromWireName(_readString(json, 'kind')),
      ownerPackage: _readString(json, 'ownerPackage'),
      status:
          AuthoringCapabilityStatus.fromWireName(_readString(json, 'status')),
      sourceReference: _readString(json, 'sourceReference'),
      runtimeConsumer: _readString(json, 'runtimeConsumer'),
      evidenceReferences: _readStringList(json, 'evidenceReferences'),
      relatedFgLots: _readStringList(json, 'relatedFgLots'),
      hasCanonicalMutation: _readBool(json, 'hasCanonicalMutation'),
    );
  }

  final String id;
  final AuthoringCapabilityKind kind;
  final String ownerPackage;
  final AuthoringCapabilityStatus status;
  final String sourceReference;
  final String runtimeConsumer;
  final List<String> evidenceReferences;
  final List<String> relatedFgLots;
  final bool hasCanonicalMutation;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'kind': kind.wireName,
      'ownerPackage': ownerPackage,
      'status': status.wireName,
      'sourceReference': sourceReference,
      'runtimeConsumer': runtimeConsumer,
      'evidenceReferences': evidenceReferences,
      'relatedFgLots': relatedFgLots,
      'hasCanonicalMutation': hasCanonicalMutation,
    };
  }
}

/// Sorted, duplicate-free collection used to generate the PMCP-000 baseline.
final class AuthoringCapabilityInventory {
  AuthoringCapabilityInventory(Iterable<AuthoringCapabilityInventoryEntry> rows)
      : entries = _validatedAndSorted(rows);

  factory AuthoringCapabilityInventory.fromJson(Map<String, dynamic> json) {
    if (json['formatVersion'] != 1) {
      throw FormatException(
        'Unsupported authoring inventory formatVersion: '
        '${json['formatVersion']}',
      );
    }
    final rawEntries = json['entries'];
    if (rawEntries is! List) {
      throw const FormatException('entries must be a JSON list');
    }
    return AuthoringCapabilityInventory(
      rawEntries.map((entry) {
        if (entry is! Map) {
          throw const FormatException('inventory entry must be a JSON object');
        }
        return AuthoringCapabilityInventoryEntry.fromJson(
          Map<String, dynamic>.from(entry),
        );
      }),
    );
  }

  final List<AuthoringCapabilityInventoryEntry> entries;

  Map<String, Object?> toJson() {
    return {
      'formatVersion': 1,
      'entries': entries.map((entry) => entry.toJson()).toList(growable: false),
    };
  }

  /// Renders byte-stable Markdown suitable for a tracked evidence report.
  String toMarkdown({
    String title = 'PokeMap authoring capability baseline',
  }) {
    final buffer = StringBuffer()
      ..writeln('# $title')
      ..writeln()
      ..writeln(
        '| Capability | Kind | Owner | Status | Source | Runtime consumer | '
        'Evidence | FG lots | Canonical mutation |',
      )
      ..writeln(
        '|---|---|---|---|---|---|---|---|---|',
      );

    for (final entry in entries) {
      buffer
        ..write('| `${_escapeCell(entry.id)}` ')
        ..write('| `${entry.kind.wireName}` ')
        ..write('| `${_escapeCell(entry.ownerPackage)}` ')
        ..write('| `${entry.status.wireName}` ')
        ..write('| `${_escapeCell(entry.sourceReference)}` ')
        ..write('| `${_escapeCell(entry.runtimeConsumer)}` ')
        ..write('| ${_formatCodeList(entry.evidenceReferences)} ')
        ..write('| ${_formatCodeList(entry.relatedFgLots)} ')
        ..writeln('| `${entry.hasCanonicalMutation}` |');
    }

    return buffer.toString();
  }

  static List<AuthoringCapabilityInventoryEntry> _validatedAndSorted(
    Iterable<AuthoringCapabilityInventoryEntry> rows,
  ) {
    final byId = <String, AuthoringCapabilityInventoryEntry>{};
    for (final row in rows) {
      if (byId.containsKey(row.id)) {
        throw ArgumentError.value(
          row.id,
          'entries',
          'Duplicate authoring capability id',
        );
      }
      byId[row.id] = row;
    }
    final sorted = byId.values.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    return List.unmodifiable(sorted);
  }
}

String _formatCodeList(List<String> values) {
  if (values.isEmpty) return '—';
  return values.map((value) => '`${_escapeCell(value)}`').join('<br>');
}

String _escapeCell(String value) {
  return value.replaceAll('|', r'\|').replaceAll('\n', '<br>');
}

String _requireNonBlank(String value, String name) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, name, 'must not be blank');
  }
  return normalized;
}

String _readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('$key must be a string');
  }
  return value;
}

bool _readBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! bool) {
    throw FormatException('$key must be a boolean');
  }
  return value;
}

List<String> _readStringList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List || value.any((item) => item is! String)) {
    throw FormatException('$key must be a list of strings');
  }
  return value.cast<String>();
}

List<String> _normalizedStrings(Iterable<String> values, String field) {
  final normalized = values
      .map((value) => _requireNonBlank(value, field))
      .toSet()
      .toList()
    ..sort();
  return List.unmodifiable(normalized);
}
~~~~~~~~

## `packages/map_core/lib/src/tooling/repository_authoring_capability_collector.dart`

~~~~~~~~dart
import 'dart:io';

import 'authoring_capability_inventory.dart';

/// Collects repository facts for PMCP-000 without changing project data.
///
/// The collector intentionally uses source files as its input. It is tooling,
/// not runtime discovery, and must never become a gameplay dependency.
final class RepositoryAuthoringCapabilityCollector {
  RepositoryAuthoringCapabilityCollector({
    required Directory repositoryRoot,
  }) : repositoryRoot = repositoryRoot.absolute;

  final Directory repositoryRoot;

  AuthoringCapabilityInventory collect() {
    _requireRepositoryFile('pokemap_authoring_api_mcp_action_catalog.md');

    return AuthoringCapabilityInventory([
      ..._collectModelFields(
        generatedPath:
            'packages/map_core/lib/src/models/project_manifest.freezed.dart',
        sourcePath: 'packages/map_core/lib/src/models/project_manifest.dart',
        mixinMarker: r'mixin _$ProjectManifest {',
        idPrefix: 'model.project_manifest',
        kind: AuthoringCapabilityKind.projectManifestField,
      ),
      ..._collectModelFields(
        generatedPath: 'packages/map_core/lib/src/models/map_data.freezed.dart',
        sourcePath: 'packages/map_core/lib/src/models/map_data.dart',
        mixinMarker: r'mixin _$MapData {',
        idPrefix: 'model.map_data',
        kind: AuthoringCapabilityKind.mapDataField,
      ),
      ..._collectEditorUseCases(),
      ..._collectCoreOperations(),
      ..._collectEvaluationCommands(),
      ..._collectCatalogActions(),
    ]);
  }

  Iterable<AuthoringCapabilityInventoryEntry> _collectModelFields({
    required String generatedPath,
    required String sourcePath,
    required String mixinMarker,
    required String idPrefix,
    required AuthoringCapabilityKind kind,
  }) sync* {
    final source = _readRepositoryFile(generatedPath);
    final start = source.indexOf(mixinMarker);
    if (start < 0) {
      throw StateError('Missing generated model marker: $mixinMarker');
    }
    final end = source.indexOf('  /// Serializes this', start);
    if (end < 0) {
      throw StateError('Missing generated JSON boundary after $mixinMarker');
    }
    final block = source.substring(start, end);
    final fields = RegExp(
      r'^\s+.+?\s+get\s+([a-zA-Z][a-zA-Z0-9_]*)\s*(?:=>|;)',
      multiLine: true,
    )
        .allMatches(block)
        .map((match) => match.group(1)!)
        .where((field) => field != 'copyWith')
        .toSet()
        .toList()
      ..sort();

    for (final field in fields) {
      yield AuthoringCapabilityInventoryEntry(
        id: '$idPrefix.$field',
        kind: kind,
        ownerPackage: 'map_core',
        // The data field exists, but phase 1 does not yet expose canonical
        // read/write actions for it.
        status: AuthoringCapabilityStatus.missing,
        sourceReference: '$sourcePath#$field',
        runtimeConsumer: 'map_editor,map_runtime',
        hasCanonicalMutation: false,
      );
    }
  }

  Iterable<AuthoringCapabilityInventoryEntry> _collectEditorUseCases() sync* {
    const useCaseRoot = 'packages/map_editor/lib/src/application/use_cases';
    final files = _dartFilesBelow(useCaseRoot);
    final declarationPattern = RegExp(
      r'^(?:final\s+)?class\s+([a-zA-Z][a-zA-Z0-9_]*UseCase)\b',
      multiLine: true,
    );

    for (final file in files) {
      final relativePath = _relativePath(file);
      final source = file.readAsStringSync();
      final classNames = declarationPattern
          .allMatches(source)
          .map((match) => match.group(1)!)
          .toSet()
          .toList()
        ..sort();
      for (final className in classNames) {
        yield AuthoringCapabilityInventoryEntry(
          id: 'editor.use_case.$className',
          kind: AuthoringCapabilityKind.editorUseCase,
          ownerPackage: 'map_editor',
          // Existing UI orchestration is deliberately not called canonical
          // until map_editor migrates in PMCP-080/081.
          status: AuthoringCapabilityStatus.missing,
          sourceReference: '$relativePath#$className',
          runtimeConsumer: 'map_runtime',
          relatedFgLots: _fgLotsForToken(className),
          hasCanonicalMutation: false,
        );
      }
    }
  }

  Iterable<AuthoringCapabilityInventoryEntry> _collectCoreOperations() sync* {
    const operationRoot = 'packages/map_core/lib/src/authoring';
    for (final file in _dartFilesBelow(operationRoot)) {
      final relativePath = _relativePath(file);
      final stem =
          file.uri.pathSegments.last.replaceFirst(RegExp(r'\.dart$'), '');
      final expectedTest = 'packages/map_core/test/${stem}_test.dart';
      final hasExpectedTest = File(
        '${repositoryRoot.path}/$expectedTest',
      ).existsSync();

      yield AuthoringCapabilityInventoryEntry(
        id: 'core.operation.$stem',
        kind: AuthoringCapabilityKind.coreOperation,
        ownerPackage: 'map_core',
        // A source file alone is not enough evidence for SUPPORTED.
        status: hasExpectedTest
            ? AuthoringCapabilityStatus.supported
            : AuthoringCapabilityStatus.missing,
        sourceReference: relativePath,
        runtimeConsumer: 'map_editor,map_runtime',
        evidenceReferences: hasExpectedTest ? [expectedTest] : const [],
        relatedFgLots: _fgLotsForToken(stem),
        hasCanonicalMutation: false,
      );
    }
  }

  Iterable<AuthoringCapabilityInventoryEntry>
      _collectEvaluationCommands() sync* {
    const catalogPath =
        'examples/playable_runtime_host/lib/src/evaluation/scenario/'
        'evaluation_command_catalog.dart';
    const evidencePath = 'examples/playable_runtime_host/test/evaluation/'
        'evaluation_scenario_runner_test.dart';
    final source = _readRepositoryFile(catalogPath);
    final commandIds = RegExp(
      r"^\s*'([^']+)': EvaluationCommandDefinition\(",
      multiLine: true,
    ).allMatches(source).map((match) => match.group(1)!).toSet().toList()
      ..sort();

    if (!File('${repositoryRoot.path}/$evidencePath').existsSync()) {
      throw StateError('Missing evaluation command evidence: $evidencePath');
    }

    for (final commandId in commandIds) {
      yield AuthoringCapabilityInventoryEntry(
        id: 'eval.command.$commandId',
        kind: AuthoringCapabilityKind.evaluationCommand,
        ownerPackage: 'playable_runtime_host',
        status: AuthoringCapabilityStatus.supported,
        sourceReference: '$catalogPath#$commandId',
        runtimeConsumer: 'map_runtime',
        evidenceReferences: const [evidencePath],
        relatedFgLots: _fgLotsForToken(commandId),
        hasCanonicalMutation: false,
      );
    }
  }

  Iterable<AuthoringCapabilityInventoryEntry> _collectCatalogActions() sync* {
    const catalogPath = 'pokemap_authoring_api_mcp_action_catalog.md';
    final source = _readRepositoryFile(catalogPath);
    final actionIds = <String>{};
    var insideCodeFence = false;

    for (final rawLine in source.split('\n')) {
      final line = rawLine.trim();
      if (line.startsWith('```')) {
        insideCodeFence = !insideCodeFence;
        continue;
      }
      if (insideCodeFence && _actionIdPattern.hasMatch(line)) {
        actionIds.add(line);
      }
    }

    for (final match in RegExp(
      r'`([a-z][a-zA-Z0-9_]*(?:\.[a-zA-Z0-9_]+)+)`',
    ).allMatches(source)) {
      final candidate = match.group(1)!;
      if (_actionIdPattern.hasMatch(candidate)) {
        actionIds.add(candidate);
      }
    }

    final sortedActionIds = actionIds.toList()..sort();
    for (final actionId in sortedActionIds) {
      yield AuthoringCapabilityInventoryEntry(
        id: 'action.$actionId',
        kind: AuthoringCapabilityKind.catalogAction,
        ownerPackage: _ownerForAction(actionId),
        status: AuthoringCapabilityStatus.missing,
        sourceReference: '$catalogPath#$actionId',
        runtimeConsumer: _runtimeConsumerForAction(actionId),
        relatedFgLots: _fgLotsForToken(actionId),
        hasCanonicalMutation: false,
      );
    }
  }

  List<File> _dartFilesBelow(String relativeDirectory) {
    final directory = Directory('${repositoryRoot.path}/$relativeDirectory');
    if (!directory.existsSync()) {
      throw StateError('Missing repository directory: $relativeDirectory');
    }
    final files = directory
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList()
      ..sort((left, right) => left.path.compareTo(right.path));
    return files;
  }

  String _readRepositoryFile(String relativePath) {
    final file = _requireRepositoryFile(relativePath);
    return file.readAsStringSync();
  }

  File _requireRepositoryFile(String relativePath) {
    final file = File('${repositoryRoot.path}/$relativePath');
    if (!file.existsSync()) {
      throw StateError('Missing repository file: $relativePath');
    }
    return file;
  }

  String _relativePath(File file) {
    final normalizedRoot = repositoryRoot.path.replaceAll('\\', '/');
    final normalizedFile = file.absolute.path.replaceAll('\\', '/');
    final prefix = '$normalizedRoot/';
    if (!normalizedFile.startsWith(prefix)) {
      throw StateError('File is outside repository root: ${file.path}');
    }
    return normalizedFile.substring(prefix.length);
  }
}

final RegExp _actionIdPattern = RegExp(
  r'^[a-z][a-zA-Z0-9_]*(?:\.[a-zA-Z0-9_]+)+$',
);

String _ownerForAction(String actionId) {
  final root = actionId.split('.').first;
  if (root == 'battle') return 'map_battle';
  if ({
    'movement',
    'encounter',
    'gameplay',
  }.contains(root)) {
    return 'map_gameplay';
  }
  if ({
    'render',
    'playtest',
    'runtime',
    'evidence',
    'probe',
  }.contains(root)) {
    return 'map_runtime';
  }
  if ({
    'workspace',
    'project',
    'asset',
    'artifact',
    'job',
  }.contains(root)) {
    return 'map_editor';
  }
  if ({
    'map',
    'layer',
    'region',
    'terrain',
    'path',
    'surface',
    'dialogue',
    'scene',
    'storyline',
    'cinematic',
    'event',
    'fact',
    'world_rule',
  }.contains(root)) {
    return 'map_core';
  }
  return 'map_authoring';
}

String _runtimeConsumerForAction(String actionId) {
  final root = actionId.split('.').first;
  if ({
    'server',
    'capability',
    'resource_kind',
    'action',
    'schema',
    'validation_code',
  }.contains(root)) {
    return 'map_editor,map_runtime,mcp';
  }
  return 'map_runtime';
}

List<String> _fgLotsForToken(String token) {
  final normalized = token.toLowerCase();
  if (normalized.contains('newgame') ||
      normalized.contains('new_game') ||
      normalized.contains('party') ||
      normalized.contains('save') ||
      normalized.contains('pc')) {
    return const ['FG-010..FG-030'];
  }
  if (normalized.contains('battle') ||
      normalized.contains('item') ||
      normalized.contains('shop') ||
      normalized.contains('heal') ||
      normalized.contains('progress')) {
    return const ['FG-040..FG-073'];
  }
  if (normalized.contains('event') ||
      normalized.contains('dialogue') ||
      normalized.contains('scene') ||
      normalized.contains('story') ||
      normalized.contains('fact') ||
      normalized.contains('worldrule') ||
      normalized.contains('world_rule')) {
    return const ['FG-080..FG-094'];
  }
  if (normalized.contains('encounter')) {
    return const ['FG-100..FG-108'];
  }
  if (normalized.contains('movement') ||
      normalized.contains('terrain') ||
      normalized.contains('path')) {
    return const ['FG-120..FG-129'];
  }
  if (normalized.contains('trainer') ||
      normalized.contains('badge') ||
      normalized.contains('gym')) {
    return const ['FG-140..FG-147'];
  }
  if (normalized.contains('menu') || normalized.contains('overlay')) {
    return const ['FG-160..FG-165'];
  }
  return const [];
}
~~~~~~~~

## `packages/map_core/test/authoring_capability_inventory_test.dart`

~~~~~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_core/src/tooling/repository_authoring_capability_collector.dart';
import 'package:test/test.dart';

void main() {
  group('AuthoringCapabilityInventory', () {
    test('sorts entries deterministically and round-trips through JSON', () {
      final inventory = AuthoringCapabilityInventory([
        _entry(
          id: 'model.project_manifest.maps',
          kind: AuthoringCapabilityKind.projectManifestField,
        ),
        _entry(
          id: 'action.map.create',
          kind: AuthoringCapabilityKind.catalogAction,
        ),
      ]);

      expect(
        inventory.entries.map((entry) => entry.id),
        ['action.map.create', 'model.project_manifest.maps'],
      );

      final encoded =
          jsonDecode(jsonEncode(inventory.toJson())) as Map<String, dynamic>;
      final decoded = AuthoringCapabilityInventory.fromJson(encoded);

      expect(decoded.toJson(), inventory.toJson());
      expect(
        AuthoringCapabilityInventory(inventory.entries.reversed).toMarkdown(),
        inventory.toMarkdown(),
      );
    });

    test('supports every explicit capability status', () {
      final entries = AuthoringCapabilityStatus.values.map(
        (status) => _entry(
          id: 'status.${status.name}',
          status: status,
          evidenceReferences: status == AuthoringCapabilityStatus.supported
              ? const ['test/status_test.dart']
              : const [],
        ),
      );

      final decoded = AuthoringCapabilityInventory.fromJson(
        AuthoringCapabilityInventory(entries).toJson(),
      );

      expect(
        decoded.entries.map((entry) => entry.status).toSet(),
        AuthoringCapabilityStatus.values.toSet(),
      );
    });

    test('sorts evidence and FG lots inside each row', () {
      final entry = _entry(
        id: 'ordered.metadata',
        evidenceReferences: const ['z_test.dart', 'a_test.dart'],
        relatedFgLots: const ['FG-020', 'FG-010'],
      );

      expect(entry.evidenceReferences, ['a_test.dart', 'z_test.dart']);
      expect(entry.relatedFgLots, ['FG-010', 'FG-020']);
    });

    test('rejects unsupported inventory format versions', () {
      expect(
        () => AuthoringCapabilityInventory.fromJson({
          'formatVersion': 2,
          'entries': const [],
        }),
        throwsFormatException,
      );
    });

    test('rejects duplicate identifiers', () {
      expect(
        () => AuthoringCapabilityInventory([
          _entry(id: 'duplicate'),
          _entry(id: 'duplicate'),
        ]),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('Duplicate'),
          ),
        ),
      );
    });

    test('requires ownership and traceability fields', () {
      for (final invalidEntry in [
        () => _entry(id: ''),
        () => _entry(id: 'missing.owner', ownerPackage: ''),
        () => _entry(id: 'missing.source', sourceReference: ''),
        () => _entry(id: 'missing.consumer', runtimeConsumer: ''),
      ]) {
        expect(invalidEntry, throwsArgumentError);
      }
    });

    test('refuses SUPPORTED without an evidence reference', () {
      expect(
        () => _entry(
          id: 'unsupported.claim',
          status: AuthoringCapabilityStatus.supported,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('evidence'),
          ),
        ),
      );
    });

    test('renders a stable Markdown matrix with required columns', () {
      final markdown = AuthoringCapabilityInventory([
        _entry(
          id: 'action.map.create',
          relatedFgLots: const ['FG-010'],
        ),
      ]).toMarkdown(title: 'Baseline');

      expect(markdown, startsWith('# Baseline\n'));
      expect(markdown, contains('| Capability | Kind | Owner | Status |'));
      expect(markdown, contains('Source | Runtime consumer | Evidence |'));
      expect(markdown, contains('`action.map.create`'));
      expect(markdown, contains('`FG-010`'));
    });
  });

  group('RepositoryAuthoringCapabilityCollector', () {
    late Directory repositoryRoot;
    late AuthoringCapabilityInventory inventory;

    setUpAll(() {
      repositoryRoot = Directory.current.parent.parent;
      inventory = RepositoryAuthoringCapabilityCollector(
        repositoryRoot: repositoryRoot,
      ).collect();
    });

    test('collects every ProjectManifest and MapData field', () {
      final ids = inventory.entries.map((entry) => entry.id).toSet();

      expect(
        ids.where((id) => id.startsWith('model.project_manifest.')),
        containsAll({
          'model.project_manifest.name',
          'model.project_manifest.maps',
          'model.project_manifest.smartTileCatalog',
          'model.project_manifest.projectedBuildingShadowCatalog',
        }),
      );
      expect(
        ids.where((id) => id.startsWith('model.map_data.')),
        containsAll({
          'model.map_data.id',
          'model.map_data.layers',
          'model.map_data.gameplayZones',
          'model.map_data.events',
        }),
      );

      final projectFieldCount = _freezedMixinFields(
        File(
          '${repositoryRoot.path}/packages/map_core/lib/src/models/'
          'project_manifest.freezed.dart',
        ),
        r'mixin _$ProjectManifest {',
      ).length;
      final mapFieldCount = _freezedMixinFields(
        File(
          '${repositoryRoot.path}/packages/map_core/lib/src/models/'
          'map_data.freezed.dart',
        ),
        r'mixin _$MapData {',
      ).length;

      expect(
        ids.where((id) => id.startsWith('model.project_manifest.')),
        hasLength(projectFieldCount),
      );
      expect(
        ids.where((id) => id.startsWith('model.map_data.')),
        hasLength(mapFieldCount),
      );
    });

    test('collects every PokeMap Eval command', () {
      final commandSource = File(
        '${repositoryRoot.path}/examples/playable_runtime_host/lib/src/'
        'evaluation/scenario/evaluation_command_catalog.dart',
      ).readAsStringSync();
      final declaredCommands = RegExp(
        r"^\s*'([^']+)': EvaluationCommandDefinition\(",
        multiLine: true,
      ).allMatches(commandSource).map((match) => match.group(1)!).toSet();
      final inventoriedCommands = inventory.entries
          .where(
            (entry) => entry.kind == AuthoringCapabilityKind.evaluationCommand,
          )
          .map((entry) => entry.id.replaceFirst('eval.command.', ''))
          .toSet();

      expect(inventoriedCommands, declaredCommands);
      expect(
        inventory.entries
            .where(
              (entry) =>
                  entry.kind == AuthoringCapabilityKind.evaluationCommand,
            )
            .every(
              (entry) =>
                  entry.status == AuthoringCapabilityStatus.supported &&
                  entry.evidenceReferences.isNotEmpty,
            ),
        isTrue,
      );
    });

    test('collects editor use cases and pure core operations', () {
      final rowsById = {
        for (final entry in inventory.entries) entry.id: entry,
      };

      expect(
        rowsById,
        contains('editor.use_case.CreateMapUseCase'),
      );
      expect(
        rowsById,
        contains('editor.use_case.PaintTerrainOnMapUseCase'),
      );
      expect(
        rowsById,
        contains('core.operation.scene_authoring_operations'),
      );
      expect(
        rowsById['editor.use_case.CreateMapUseCase']!.hasCanonicalMutation,
        isFalse,
      );
    });

    test('collects dotted actions from the approved catalog', () {
      final actionIds = inventory.entries
          .where((entry) => entry.kind == AuthoringCapabilityKind.catalogAction)
          .map((entry) => entry.id)
          .toSet();

      expect(actionIds, contains('action.project.create'));
      expect(actionIds, contains('action.map.apply_operations'));
      expect(actionIds, contains('action.playtest.start'));
    });

    test('is byte-stable over repeated collection', () {
      final second = RepositoryAuthoringCapabilityCollector(
        repositoryRoot: repositoryRoot,
      ).collect();

      expect(
        jsonEncode(second.toJson()),
        jsonEncode(inventory.toJson()),
      );
      expect(second.toMarkdown(), inventory.toMarkdown());
    });

    test('never marks a capability supported without an existing proof', () {
      for (final entry in inventory.entries.where(
        (entry) => entry.status == AuthoringCapabilityStatus.supported,
      )) {
        expect(entry.evidenceReferences, isNotEmpty, reason: entry.id);
        for (final evidence in entry.evidenceReferences) {
          expect(
            File('${repositoryRoot.path}/$evidence').existsSync(),
            isTrue,
            reason: '${entry.id} -> $evidence',
          );
        }
      }
    });
  });
}

Set<String> _freezedMixinFields(File file, String marker) {
  final source = file.readAsStringSync();
  final start = source.indexOf(marker);
  expect(start, isNonNegative, reason: marker);
  final end = source.indexOf('  /// Serializes this', start);
  expect(end, isNonNegative, reason: marker);
  final block = source.substring(start, end);
  return RegExp(
    r'^\s+.+?\s+get\s+([a-zA-Z][a-zA-Z0-9_]*)\s*(?:=>|;)',
    multiLine: true,
  )
      .allMatches(block)
      .map((match) => match.group(1)!)
      .where((name) => name != 'copyWith')
      .toSet();
}

AuthoringCapabilityInventoryEntry _entry({
  required String id,
  AuthoringCapabilityKind kind = AuthoringCapabilityKind.editorUseCase,
  String ownerPackage = 'map_editor',
  AuthoringCapabilityStatus status = AuthoringCapabilityStatus.missing,
  String sourceReference = 'packages/map_editor/lib/example.dart',
  String runtimeConsumer = 'map_runtime',
  List<String> evidenceReferences = const [],
  List<String> relatedFgLots = const [],
}) {
  return AuthoringCapabilityInventoryEntry(
    id: id,
    kind: kind,
    ownerPackage: ownerPackage,
    status: status,
    sourceReference: sourceReference,
    runtimeConsumer: runtimeConsumer,
    evidenceReferences: evidenceReferences,
    relatedFgLots: relatedFgLots,
    hasCanonicalMutation: false,
  );
}
~~~~~~~~

## `packages/map_core/tool/generate_authoring_capability_inventory.dart`

~~~~~~~~dart
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_core/src/tooling/repository_authoring_capability_collector.dart';

void main() {
  final packageRoot = Directory.current.absolute;
  final repositoryRoot = packageRoot.parent.parent;
  final inventory = RepositoryAuthoringCapabilityCollector(
    repositoryRoot: repositoryRoot,
  ).collect();
  final output = File(
    '${repositoryRoot.path}/reports/analysis/'
    'pmcp_000_authoring_capability_baseline.md',
  );

  output.parent.createSync(recursive: true);
  output.writeAsStringSync(_renderReport(inventory));
  stdout.writeln(
    'Generated ${inventory.entries.length} capability rows at '
    '${output.path}',
  );
}

String _renderReport(AuthoringCapabilityInventory inventory) {
  final byKind = <AuthoringCapabilityKind, int>{
    for (final kind in AuthoringCapabilityKind.values) kind: 0,
  };
  final byStatus = <AuthoringCapabilityStatus, int>{
    for (final status in AuthoringCapabilityStatus.values) status: 0,
  };
  for (final entry in inventory.entries) {
    byKind[entry.kind] = byKind[entry.kind]! + 1;
    byStatus[entry.status] = byStatus[entry.status]! + 1;
  }

  final buffer = StringBuffer()
    ..writeln('# PMCP-000 — Authoring capability baseline')
    ..writeln()
    ..writeln(
      '> Generated deterministically by '
      '`packages/map_core/tool/generate_authoring_capability_inventory.dart`. '
      'Do not edit this file manually.',
    )
    ..writeln()
    ..writeln('## Scope')
    ..writeln()
    ..writeln(
      'This baseline inventories model fields, editor use cases, pure core '
      'authoring operations, PokeMap Eval commands, and dotted actions from '
      'the approved Authoring API catalog.',
    )
    ..writeln()
    ..writeln(
      '`SUPPORTED` means that the row has an existing repository proof. '
      'Source code without canonical API evidence remains `MISSING`.',
    )
    ..writeln()
    ..writeln('## Counts')
    ..writeln()
    ..writeln('| Dimension | Value | Count |')
    ..writeln('|---|---|---:|');

  for (final kind in AuthoringCapabilityKind.values) {
    buffer.writeln('| Kind | `${kind.wireName}` | ${byKind[kind]} |');
  }
  for (final status in AuthoringCapabilityStatus.values) {
    buffer.writeln('| Status | `${status.wireName}` | ${byStatus[status]} |');
  }

  buffer
    ..writeln()
    ..writeln(
      inventory.toMarkdown(title: 'Capability matrix').trimRight(),
    )
    ..writeln();
  return buffer.toString();
}
~~~~~~~~

## `reports/analysis/pmcp_000_authoring_capability_baseline.md`

~~~~~~~~markdown
# PMCP-000 — Authoring capability baseline

> Generated deterministically by `packages/map_core/tool/generate_authoring_capability_inventory.dart`. Do not edit this file manually.

## Scope

This baseline inventories model fields, editor use cases, pure core authoring operations, PokeMap Eval commands, and dotted actions from the approved Authoring API catalog.

`SUPPORTED` means that the row has an existing repository proof. Source code without canonical API evidence remains `MISSING`.

## Counts

| Dimension | Value | Count |
|---|---|---:|
| Kind | `catalog_action` | 1391 |
| Kind | `project_manifest_field` | 41 |
| Kind | `map_data_field` | 16 |
| Kind | `editor_use_case` | 185 |
| Kind | `core_operation` | 29 |
| Kind | `evaluation_command` | 31 |
| Status | `SUPPORTED` | 50 |
| Status | `NOT_APPLICABLE` | 0 |
| Status | `BLOCKED` | 0 |
| Status | `MISSING` | 1643 |

# Capability matrix

| Capability | Kind | Owner | Status | Source | Runtime consumer | Evidence | FG lots | Canonical mutation |
|---|---|---|---|---|---|---|---|---|
| `action.ability.clone` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#ability.clone` | `map_runtime` | — | — | `false` |
| `action.ability.create` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#ability.create` | `map_runtime` | — | — | `false` |
| `action.ability.delete_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#ability.delete_apply` | `map_runtime` | — | — | `false` |
| `action.ability.delete_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#ability.delete_plan` | `map_runtime` | — | — | `false` |
| `action.ability.get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#ability.get` | `map_runtime` | — | — | `false` |
| `action.ability.list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#ability.list` | `map_runtime` | — | — | `false` |
| `action.ability.search` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#ability.search` | `map_runtime` | — | — | `false` |
| `action.ability.set_effect` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#ability.set_effect` | `map_runtime` | — | — | `false` |
| `action.ability.simulate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#ability.simulate` | `map_runtime` | — | — | `false` |
| `action.ability.update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#ability.update` | `map_runtime` | — | — | `false` |
| `action.ability.validate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#ability.validate` | `map_runtime` | — | — | `false` |
| `action.action.describe` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#action.describe` | `map_editor,map_runtime,mcp` | — | — | `false` |
| `action.action.execute` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#action.execute` | `map_editor,map_runtime,mcp` | — | — | `false` |
| `action.action.list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#action.list` | `map_editor,map_runtime,mcp` | — | — | `false` |
| `action.action.plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#action.plan` | `map_editor,map_runtime,mcp` | — | — | `false` |
| `action.action.search` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#action.search` | `map_editor,map_runtime,mcp` | — | — | `false` |
| `action.artifact.download` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#artifact.download` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.artifact.expire` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#artifact.expire` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.artifact.get` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#artifact.get` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.artifact.list` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#artifact.list` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.asset.copy` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#asset.copy` | `map_runtime` | — | — | `false` |
| `action.asset.deduplicate_apply` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#asset.deduplicate_apply` | `map_runtime` | — | — | `false` |
| `action.asset.deduplicate_plan` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#asset.deduplicate_plan` | `map_runtime` | — | — | `false` |
| `action.asset.delete_apply` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#asset.delete_apply` | `map_runtime` | — | — | `false` |
| `action.asset.delete_plan` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#asset.delete_plan` | `map_runtime` | — | — | `false` |
| `action.asset.find_unused` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#asset.find_unused` | `map_runtime` | — | — | `false` |
| `action.asset.find_usages` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#asset.find_usages` | `map_runtime` | — | — | `false` |
| `action.asset.get` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#asset.get` | `map_runtime` | — | — | `false` |
| `action.asset.import_apply` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#asset.import_apply` | `map_runtime` | — | — | `false` |
| `action.asset.import_plan` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#asset.import_plan` | `map_runtime` | — | — | `false` |
| `action.asset.inspect` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#asset.inspect` | `map_runtime` | — | — | `false` |
| `action.asset.license_update` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#asset.license_update` | `map_runtime` | — | — | `false` |
| `action.asset.list` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#asset.list` | `map_runtime` | — | — | `false` |
| `action.asset.metadata_update` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#asset.metadata_update` | `map_runtime` | — | — | `false` |
| `action.asset.move` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#asset.move` | `map_runtime` | — | — | `false` |
| `action.asset.preview` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#asset.preview` | `map_runtime` | — | — | `false` |
| `action.asset.read` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#asset.read` | `map_runtime` | — | — | `false` |
| `action.asset.relink_apply` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#asset.relink_apply` | `map_runtime` | — | — | `false` |
| `action.asset.relink_plan` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#asset.relink_plan` | `map_runtime` | — | — | `false` |
| `action.asset.rename` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#asset.rename` | `map_runtime` | — | — | `false` |
| `action.asset.replace_apply` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#asset.replace_apply` | `map_runtime` | — | — | `false` |
| `action.asset.replace_plan` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#asset.replace_plan` | `map_runtime` | — | — | `false` |
| `action.asset.search` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#asset.search` | `map_runtime` | — | — | `false` |
| `action.asset.thumbnail` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#asset.thumbnail` | `map_runtime` | — | — | `false` |
| `action.asset.verify` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#asset.verify` | `map_runtime` | — | — | `false` |
| `action.asset.write` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#asset.write` | `map_runtime` | — | — | `false` |
| `action.audio.inspect` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#audio.inspect` | `map_runtime` | — | — | `false` |
| `action.audio.normalize_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#audio.normalize_apply` | `map_runtime` | — | — | `false` |
| `action.audio.normalize_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#audio.normalize_plan` | `map_runtime` | — | — | `false` |
| `action.audio.preview` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#audio.preview` | `map_runtime` | — | — | `false` |
| `action.audio.validate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#audio.validate` | `map_runtime` | — | — | `false` |
| `action.audit.get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#audit.get` | `map_runtime` | — | — | `false` |
| `action.audit.list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#audit.list` | `map_runtime` | — | — | `false` |
| `action.autotile.apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#autotile.apply` | `map_runtime` | — | — | `false` |
| `action.autotile.preview` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#autotile.preview` | `map_runtime` | — | — | `false` |
| `action.autotile.rebuild_region` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#autotile.rebuild_region` | `map_runtime` | — | — | `false` |
| `action.autotile.resolve` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#autotile.resolve` | `map_runtime` | — | — | `false` |
| `action.autotile.validate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#autotile.validate` | `map_runtime` | — | — | `false` |
| `action.badge.clone` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#badge.clone` | `map_runtime` | — | `FG-140..FG-147` | `false` |
| `action.badge.create` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#badge.create` | `map_runtime` | — | `FG-140..FG-147` | `false` |
| `action.badge.delete_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#badge.delete_apply` | `map_runtime` | — | `FG-140..FG-147` | `false` |
| `action.badge.delete_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#badge.delete_plan` | `map_runtime` | — | `FG-140..FG-147` | `false` |
| `action.badge.get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#badge.get` | `map_runtime` | — | `FG-140..FG-147` | `false` |
| `action.badge.list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#badge.list` | `map_runtime` | — | `FG-140..FG-147` | `false` |
| `action.badge.set_presentation` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#badge.set_presentation` | `map_runtime` | — | `FG-140..FG-147` | `false` |
| `action.badge.set_unlocks` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#badge.set_unlocks` | `map_runtime` | — | `FG-140..FG-147` | `false` |
| `action.badge.update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#badge.update` | `map_runtime` | — | `FG-140..FG-147` | `false` |
| `action.badge.validate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#badge.validate` | `map_runtime` | — | `FG-140..FG-147` | `false` |
| `action.bag.consume` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#bag.consume` | `map_runtime` | — | — | `false` |
| `action.bag.equip_held_item` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#bag.equip_held_item` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.bag.give` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#bag.give` | `map_runtime` | — | — | `false` |
| `action.bag.inspect` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#bag.inspect` | `map_runtime` | — | — | `false` |
| `action.bag.take` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#bag.take` | `map_runtime` | — | — | `false` |
| `action.bag.unequip_held_item` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#bag.unequip_held_item` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.bag.use_capture_item` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#bag.use_capture_item` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.bag.use_key_item` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#bag.use_key_item` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.bag.use_medicine` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#bag.use_medicine` | `map_runtime` | — | — | `false` |
| `action.bag.use_on_target` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#bag.use_on_target` | `map_runtime` | — | — | `false` |
| `action.bag.use_pp_item` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#bag.use_pp_item` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.bag.use_repel` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#bag.use_repel` | `map_runtime` | — | — | `false` |
| `action.bag.use_revive` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#bag.use_revive` | `map_runtime` | — | — | `false` |
| `action.bag.use_status_cure` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#bag.use_status_cure` | `map_runtime` | — | — | `false` |
| `action.bag.use_tm_hm` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#bag.use_tm_hm` | `map_runtime` | — | — | `false` |
| `action.batch.execute` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#batch.execute` | `map_runtime` | — | — | `false` |
| `action.batch.validate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#batch.validate` | `map_runtime` | — | — | `false` |
| `action.battle.acceptEvolution` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.acceptEvolution` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.battle.acceptMoveLearning` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.acceptMoveLearning` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.battle.advance` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.advance` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.battle.apply_outcome_apply` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.apply_outcome_apply` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.battle.apply_outcome_plan` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.apply_outcome_plan` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.battle.capture` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.capture` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.battle.chooseMove` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.chooseMove` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.battle.chooseTarget` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.chooseTarget` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.battle.choose_move` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.choose_move` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.battle.choose_target` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.choose_target` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.battle.completePostBattle` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.completePostBattle` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.battle.complete_post_battle` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.complete_post_battle` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.battle.inject_rng_probe_only` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.inject_rng_probe_only` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.battle.inject_seed` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.inject_seed` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.battle.inspect_state` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.inspect_state` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.battle.inspect_timeline` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.inspect_timeline` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.battle.pause` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.pause` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.battle.receipt_get` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.receipt_get` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.battle.refuseEvolution` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.refuseEvolution` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.battle.refuseMoveLearning` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.refuseMoveLearning` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.battle.resolve` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.resolve` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.battle.resolve_all` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.resolve_all` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.battle.resolve_turn` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.resolve_turn` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.battle.resume` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.resume` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.battle.run` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.run` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.battle.setup_build_static` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.setup_build_static` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.battle.setup_build_trainer` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.setup_build_trainer` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.battle.setup_build_wild` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.setup_build_wild` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.battle.setup_validate` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.setup_validate` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.battle.simulate` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.simulate` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.battle.start` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.start` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.battle.startStatic` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.startStatic` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.battle.startTrainer` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.startTrainer` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.battle.switch` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.switch` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.battle.useItem` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.useItem` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.battle.use_item` | `catalog_action` | `map_battle` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#battle.use_item` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.border_blueprint.asset_link` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#border_blueprint.asset_link` | `map_runtime` | — | — | `false` |
| `action.border_blueprint.asset_unlink` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#border_blueprint.asset_unlink` | `map_runtime` | — | — | `false` |
| `action.border_blueprint.diagnostics` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#border_blueprint.diagnostics` | `map_runtime` | — | — | `false` |
| `action.border_blueprint.preview` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#border_blueprint.preview` | `map_runtime` | — | — | `false` |
| `action.border_blueprint.primitive_add` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#border_blueprint.primitive_add` | `map_runtime` | — | — | `false` |
| `action.border_blueprint.primitive_remove` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#border_blueprint.primitive_remove` | `map_runtime` | — | — | `false` |
| `action.border_blueprint.primitive_update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#border_blueprint.primitive_update` | `map_runtime` | — | — | `false` |
| `action.border_blueprint.publication_readiness` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#border_blueprint.publication_readiness` | `map_runtime` | — | — | `false` |
| `action.border_layer.diagnostics` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#border_layer.diagnostics` | `map_runtime` | — | — | `false` |
| `action.border_layer.feature_create` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#border_layer.feature_create` | `map_runtime` | — | — | `false` |
| `action.border_layer.feature_delete` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#border_layer.feature_delete` | `map_runtime` | — | — | `false` |
| `action.border_layer.feature_lock` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#border_layer.feature_lock` | `map_runtime` | — | — | `false` |
| `action.border_layer.feature_move` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#border_layer.feature_move` | `map_runtime` | — | — | `false` |
| `action.border_layer.feature_reorder` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#border_layer.feature_reorder` | `map_runtime` | — | — | `false` |
| `action.border_layer.feature_set_blueprint` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#border_layer.feature_set_blueprint` | `map_runtime` | — | — | `false` |
| `action.border_layer.feature_set_keep_out` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#border_layer.feature_set_keep_out` | `map_runtime` | — | — | `false` |
| `action.border_layer.feature_set_variation` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#border_layer.feature_set_variation` | `map_runtime` | — | — | `false` |
| `action.border_layer.feature_unlock` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#border_layer.feature_unlock` | `map_runtime` | — | — | `false` |
| `action.border_layer.feature_update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#border_layer.feature_update` | `map_runtime` | — | — | `false` |
| `action.border_layer.materialize_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#border_layer.materialize_apply` | `map_runtime` | — | — | `false` |
| `action.border_layer.materialize_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#border_layer.materialize_plan` | `map_runtime` | — | — | `false` |
| `action.border_layer.preview` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#border_layer.preview` | `map_runtime` | — | — | `false` |
| `action.border_layer.publication_readiness` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#border_layer.publication_readiness` | `map_runtime` | — | — | `false` |
| `action.border_layer.region_clear` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#border_layer.region_clear` | `map_runtime` | — | — | `false` |
| `action.border_layer.region_fill` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#border_layer.region_fill` | `map_runtime` | — | — | `false` |
| `action.border_layer.relink_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#border_layer.relink_apply` | `map_runtime` | — | — | `false` |
| `action.border_layer.relink_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#border_layer.relink_plan` | `map_runtime` | — | — | `false` |
| `action.border_layer.resize_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#border_layer.resize_apply` | `map_runtime` | — | — | `false` |
| `action.border_layer.resize_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#border_layer.resize_plan` | `map_runtime` | — | — | `false` |
| `action.border_layer.resolve` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#border_layer.resolve` | `map_runtime` | — | — | `false` |
| `action.border_layer.stroke_add` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#border_layer.stroke_add` | `map_runtime` | — | — | `false` |
| `action.border_layer.stroke_delete` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#border_layer.stroke_delete` | `map_runtime` | — | — | `false` |
| `action.border_layer.stroke_update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#border_layer.stroke_update` | `map_runtime` | — | — | `false` |
| `action.capability.get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#capability.get` | `map_editor,map_runtime,mcp` | — | — | `false` |
| `action.capability.list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#capability.list` | `map_editor,map_runtime,mcp` | — | — | `false` |
| `action.catalog.get_options` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#catalog.get_options` | `map_runtime` | — | — | `false` |
| `action.catalog.search` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#catalog.search` | `map_runtime` | — | — | `false` |
| `action.cell.erase` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cell.erase` | `map_runtime` | — | — | `false` |
| `action.cell.get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cell.get` | `map_runtime` | — | — | `false` |
| `action.cell.paint` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cell.paint` | `map_runtime` | — | — | `false` |
| `action.cell.replace` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cell.replace` | `map_runtime` | — | — | `false` |
| `action.cell.sample` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cell.sample` | `map_runtime` | — | — | `false` |
| `action.change.list_since` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#change.list_since` | `map_runtime` | — | — | `false` |
| `action.change_set.diff` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#change_set.diff` | `map_runtime` | — | — | `false` |
| `action.character.animation_add` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#character.animation_add` | `map_runtime` | — | — | `false` |
| `action.character.animation_delete` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#character.animation_delete` | `map_runtime` | — | — | `false` |
| `action.character.animation_reorder` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#character.animation_reorder` | `map_runtime` | — | — | `false` |
| `action.character.animation_update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#character.animation_update` | `map_runtime` | — | — | `false` |
| `action.character.clone` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#character.clone` | `map_runtime` | — | — | `false` |
| `action.character.create` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#character.create` | `map_runtime` | — | — | `false` |
| `action.character.delete_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#character.delete_apply` | `map_runtime` | — | — | `false` |
| `action.character.delete_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#character.delete_plan` | `map_runtime` | — | — | `false` |
| `action.character.frame_add` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#character.frame_add` | `map_runtime` | — | — | `false` |
| `action.character.frame_delete` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#character.frame_delete` | `map_runtime` | — | — | `false` |
| `action.character.frame_reorder` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#character.frame_reorder` | `map_runtime` | — | — | `false` |
| `action.character.frame_update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#character.frame_update` | `map_runtime` | — | — | `false` |
| `action.character.get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#character.get` | `map_runtime` | — | — | `false` |
| `action.character.list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#character.list` | `map_runtime` | — | — | `false` |
| `action.character.render_preview` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#character.render_preview` | `map_runtime` | — | — | `false` |
| `action.character.update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#character.update` | `map_runtime` | — | — | `false` |
| `action.character.validate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#character.validate` | `map_runtime` | — | — | `false` |
| `action.cinematic.actor_add` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.actor_add` | `map_runtime` | — | — | `false` |
| `action.cinematic.actor_remove` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.actor_remove` | `map_runtime` | — | — | `false` |
| `action.cinematic.actor_set_appearance` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.actor_set_appearance` | `map_runtime` | — | — | `false` |
| `action.cinematic.actor_set_initial_placement` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.actor_set_initial_placement` | `map_runtime` | — | — | `false` |
| `action.cinematic.actor_update` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.actor_update` | `map_runtime` | — | — | `false` |
| `action.cinematic.archive` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.archive` | `map_runtime` | — | — | `false` |
| `action.cinematic.bulk_update` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.bulk_update` | `map_runtime` | — | — | `false` |
| `action.cinematic.clone` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.clone` | `map_runtime` | — | — | `false` |
| `action.cinematic.create` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.create` | `map_runtime` | — | — | `false` |
| `action.cinematic.delete_apply` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.delete_apply` | `map_runtime` | — | — | `false` |
| `action.cinematic.delete_plan` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.delete_plan` | `map_runtime` | — | — | `false` |
| `action.cinematic.get` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.get` | `map_runtime` | — | — | `false` |
| `action.cinematic.list` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.list` | `map_runtime` | — | — | `false` |
| `action.cinematic.path_create` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.path_create` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.cinematic.path_delete` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.path_delete` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.cinematic.path_update` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.path_update` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.cinematic.play` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.play` | `map_runtime` | — | — | `false` |
| `action.cinematic.preflight` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.preflight` | `map_runtime` | — | — | `false` |
| `action.cinematic.preview` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.preview` | `map_runtime` | — | — | `false` |
| `action.cinematic.restore` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.restore` | `map_runtime` | — | — | `false` |
| `action.cinematic.stage_point_add` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.stage_point_add` | `map_runtime` | — | — | `false` |
| `action.cinematic.stage_point_remove` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.stage_point_remove` | `map_runtime` | — | — | `false` |
| `action.cinematic.stage_point_update` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.stage_point_update` | `map_runtime` | — | — | `false` |
| `action.cinematic.stage_set_backdrop` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.stage_set_backdrop` | `map_runtime` | — | — | `false` |
| `action.cinematic.stage_set_map` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.stage_set_map` | `map_runtime` | — | — | `false` |
| `action.cinematic.target_add` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.target_add` | `map_runtime` | — | — | `false` |
| `action.cinematic.target_remove` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.target_remove` | `map_runtime` | — | — | `false` |
| `action.cinematic.target_update` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.target_update` | `map_runtime` | — | — | `false` |
| `action.cinematic.timeline_step_add` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.timeline_step_add` | `map_runtime` | — | — | `false` |
| `action.cinematic.timeline_step_clone` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.timeline_step_clone` | `map_runtime` | — | — | `false` |
| `action.cinematic.timeline_step_copy` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.timeline_step_copy` | `map_runtime` | — | — | `false` |
| `action.cinematic.timeline_step_delete` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.timeline_step_delete` | `map_runtime` | — | — | `false` |
| `action.cinematic.timeline_step_move` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.timeline_step_move` | `map_runtime` | — | — | `false` |
| `action.cinematic.timeline_step_paste` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.timeline_step_paste` | `map_runtime` | — | — | `false` |
| `action.cinematic.timeline_step_update` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.timeline_step_update` | `map_runtime` | — | — | `false` |
| `action.cinematic.update` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.update` | `map_runtime` | — | — | `false` |
| `action.cinematic.validate` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#cinematic.validate` | `map_runtime` | — | — | `false` |
| `action.collision.explain_provenance` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#collision.explain_provenance` | `map_runtime` | — | — | `false` |
| `action.collision.preview_player_hitbox` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#collision.preview_player_hitbox` | `map_runtime` | — | — | `false` |
| `action.collision.query_effective_at` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#collision.query_effective_at` | `map_runtime` | — | — | `false` |
| `action.collision.query_effective_region` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#collision.query_effective_region` | `map_runtime` | — | — | `false` |
| `action.collision.validate_reachability` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#collision.validate_reachability` | `map_runtime` | — | — | `false` |
| `action.collision.validate_walkability` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#collision.validate_walkability` | `map_runtime` | — | — | `false` |
| `action.collision_layer.clear` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#collision_layer.clear` | `map_runtime` | — | — | `false` |
| `action.collision_layer.erase` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#collision_layer.erase` | `map_runtime` | — | — | `false` |
| `action.collision_layer.fill` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#collision_layer.fill` | `map_runtime` | — | — | `false` |
| `action.collision_layer.generate_from_elements_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#collision_layer.generate_from_elements_apply` | `map_runtime` | — | — | `false` |
| `action.collision_layer.generate_from_elements_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#collision_layer.generate_from_elements_plan` | `map_runtime` | — | — | `false` |
| `action.collision_layer.invert` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#collision_layer.invert` | `map_runtime` | — | — | `false` |
| `action.collision_layer.merge_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#collision_layer.merge_apply` | `map_runtime` | — | — | `false` |
| `action.collision_layer.merge_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#collision_layer.merge_plan` | `map_runtime` | — | — | `false` |
| `action.collision_layer.paint` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#collision_layer.paint` | `map_runtime` | — | — | `false` |
| `action.collision_layer.replace_region` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#collision_layer.replace_region` | `map_runtime` | — | — | `false` |
| `action.conflict.inspect` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#conflict.inspect` | `map_runtime` | — | — | `false` |
| `action.conflict.resolve` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#conflict.resolve` | `map_runtime` | — | — | `false` |
| `action.connection.create_bidirectional_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#connection.create_bidirectional_apply` | `map_runtime` | — | — | `false` |
| `action.connection.create_bidirectional_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#connection.create_bidirectional_plan` | `map_runtime` | — | — | `false` |
| `action.connection.delete` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#connection.delete` | `map_runtime` | — | — | `false` |
| `action.connection.delete_bidirectional_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#connection.delete_bidirectional_apply` | `map_runtime` | — | — | `false` |
| `action.connection.delete_bidirectional_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#connection.delete_bidirectional_plan` | `map_runtime` | — | — | `false` |
| `action.connection.get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#connection.get` | `map_runtime` | — | — | `false` |
| `action.connection.list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#connection.list` | `map_runtime` | — | — | `false` |
| `action.connection.preview_alignment` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#connection.preview_alignment` | `map_runtime` | — | — | `false` |
| `action.connection.update_bidirectional_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#connection.update_bidirectional_apply` | `map_runtime` | — | — | `false` |
| `action.connection.update_bidirectional_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#connection.update_bidirectional_plan` | `map_runtime` | — | — | `false` |
| `action.connection.upsert` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#connection.upsert` | `map_runtime` | — | — | `false` |
| `action.connection.validate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#connection.validate` | `map_runtime` | — | — | `false` |
| `action.diagnostic.explain` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#diagnostic.explain` | `map_runtime` | — | — | `false` |
| `action.diagnostic.get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#diagnostic.get` | `map_runtime` | — | — | `false` |
| `action.diagnostic.list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#diagnostic.list` | `map_runtime` | — | — | `false` |
| `action.diagnostic.navigate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#diagnostic.navigate` | `map_runtime` | — | — | `false` |
| `action.diagnostic.suppress_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#diagnostic.suppress_apply` | `map_runtime` | — | — | `false` |
| `action.diagnostic.suppress_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#diagnostic.suppress_plan` | `map_runtime` | — | — | `false` |
| `action.diagnostic.unsuppress` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#diagnostic.unsuppress` | `map_runtime` | — | — | `false` |
| `action.dialogue.advance` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#dialogue.advance` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.dialogue.choose` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#dialogue.choose` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.dialogue.clone` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#dialogue.clone` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.dialogue.compile` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#dialogue.compile` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.dialogue.create` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#dialogue.create` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.dialogue.delete_apply` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#dialogue.delete_apply` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.dialogue.delete_plan` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#dialogue.delete_plan` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.dialogue.get` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#dialogue.get` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.dialogue.import_apply` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#dialogue.import_apply` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.dialogue.import_plan` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#dialogue.import_plan` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.dialogue.inspect` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#dialogue.inspect` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.dialogue.list` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#dialogue.list` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.dialogue.move` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#dialogue.move` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.dialogue.outcome_add` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#dialogue.outcome_add` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.dialogue.outcome_delete_apply` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#dialogue.outcome_delete_apply` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.dialogue.outcome_delete_plan` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#dialogue.outcome_delete_plan` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.dialogue.outcome_replace_apply` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#dialogue.outcome_replace_apply` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.dialogue.outcome_replace_plan` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#dialogue.outcome_replace_plan` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.dialogue.outcome_update` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#dialogue.outcome_update` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.dialogue.preview` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#dialogue.preview` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.dialogue.references` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#dialogue.references` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.dialogue.set_default_start_node` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#dialogue.set_default_start_node` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.dialogue.set_tags` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#dialogue.set_tags` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.dialogue.simulate` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#dialogue.simulate` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.dialogue.source_get` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#dialogue.source_get` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.dialogue.source_save` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#dialogue.source_save` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.dialogue.update_metadata` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#dialogue.update_metadata` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.dialogue.validate` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#dialogue.validate` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.dialogue_folder.create` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#dialogue_folder.create` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.dialogue_folder.delete_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#dialogue_folder.delete_apply` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.dialogue_folder.delete_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#dialogue_folder.delete_plan` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.dialogue_folder.list_tree` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#dialogue_folder.list_tree` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.dialogue_folder.move` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#dialogue_folder.move` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.dialogue_folder.rename` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#dialogue_folder.rename` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.dialogue_folder.reorder` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#dialogue_folder.reorder` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.draft.commit` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#draft.commit` | `map_runtime` | — | — | `false` |
| `action.draft.create` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#draft.create` | `map_runtime` | — | — | `false` |
| `action.draft.discard` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#draft.discard` | `map_runtime` | — | — | `false` |
| `action.draft.get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#draft.get` | `map_runtime` | — | — | `false` |
| `action.draft.patch` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#draft.patch` | `map_runtime` | — | — | `false` |
| `action.draft.validate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#draft.validate` | `map_runtime` | — | — | `false` |
| `action.editor.brush_set` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#editor.brush_set` | `map_runtime` | — | — | `false` |
| `action.editor.context_get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#editor.context_get` | `map_runtime` | — | — | `false` |
| `action.editor.dirty_state_get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#editor.dirty_state_get` | `map_runtime` | — | — | `false` |
| `action.editor.focus_region` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#editor.focus_region` | `map_runtime` | — | — | `false` |
| `action.editor.focus_resource` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#editor.focus_resource` | `map_runtime` | — | — | `false` |
| `action.editor.open_map` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#editor.open_map` | `map_runtime` | — | — | `false` |
| `action.editor.open_workspace` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#editor.open_workspace` | `map_runtime` | — | — | `false` |
| `action.editor.preview_close` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#editor.preview_close` | `map_runtime` | — | — | `false` |
| `action.editor.preview_open` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#editor.preview_open` | `map_runtime` | — | — | `false` |
| `action.editor.save` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#editor.save` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.editor.selection_clear` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#editor.selection_clear` | `map_runtime` | — | — | `false` |
| `action.editor.selection_get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#editor.selection_get` | `map_runtime` | — | — | `false` |
| `action.editor.selection_set` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#editor.selection_set` | `map_runtime` | — | — | `false` |
| `action.editor.tool_select` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#editor.tool_select` | `map_runtime` | — | — | `false` |
| `action.editor.viewport_fit_map` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#editor.viewport_fit_map` | `map_runtime` | — | — | `false` |
| `action.editor.viewport_get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#editor.viewport_get` | `map_runtime` | — | — | `false` |
| `action.editor.viewport_pan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#editor.viewport_pan` | `map_runtime` | — | — | `false` |
| `action.editor.viewport_set` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#editor.viewport_set` | `map_runtime` | — | — | `false` |
| `action.editor.viewport_zoom` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#editor.viewport_zoom` | `map_runtime` | — | — | `false` |
| `action.element.change_owner_tileset_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element.change_owner_tileset_apply` | `map_runtime` | — | — | `false` |
| `action.element.change_owner_tileset_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element.change_owner_tileset_plan` | `map_runtime` | — | — | `false` |
| `action.element.clone` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element.clone` | `map_runtime` | — | — | `false` |
| `action.element.create` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element.create` | `map_runtime` | — | — | `false` |
| `action.element.delete_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element.delete_apply` | `map_runtime` | — | — | `false` |
| `action.element.delete_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element.delete_plan` | `map_runtime` | — | — | `false` |
| `action.element.find_usages` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element.find_usages` | `map_runtime` | — | — | `false` |
| `action.element.get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element.get` | `map_runtime` | — | — | `false` |
| `action.element.list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element.list` | `map_runtime` | — | — | `false` |
| `action.element.move` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element.move` | `map_runtime` | — | — | `false` |
| `action.element.render_preview` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element.render_preview` | `map_runtime` | — | — | `false` |
| `action.element.reorder` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element.reorder` | `map_runtime` | — | — | `false` |
| `action.element.search` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element.search` | `map_runtime` | — | — | `false` |
| `action.element.set_animation` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element.set_animation` | `map_runtime` | — | — | `false` |
| `action.element.set_collision_profile` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element.set_collision_profile` | `map_runtime` | — | — | `false` |
| `action.element.set_frames` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element.set_frames` | `map_runtime` | — | — | `false` |
| `action.element.set_projected_shadow` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element.set_projected_shadow` | `map_runtime` | — | — | `false` |
| `action.element.set_recommended_layer` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element.set_recommended_layer` | `map_runtime` | — | — | `false` |
| `action.element.set_shadow` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element.set_shadow` | `map_runtime` | — | — | `false` |
| `action.element.set_tags` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element.set_tags` | `map_runtime` | — | — | `false` |
| `action.element.update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element.update` | `map_runtime` | — | — | `false` |
| `action.element.validate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element.validate` | `map_runtime` | — | — | `false` |
| `action.element_category.create` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element_category.create` | `map_runtime` | — | — | `false` |
| `action.element_category.delete_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element_category.delete_apply` | `map_runtime` | — | — | `false` |
| `action.element_category.delete_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element_category.delete_plan` | `map_runtime` | — | — | `false` |
| `action.element_category.list_tree` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element_category.list_tree` | `map_runtime` | — | — | `false` |
| `action.element_category.move` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element_category.move` | `map_runtime` | — | — | `false` |
| `action.element_category.rename` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element_category.rename` | `map_runtime` | — | — | `false` |
| `action.element_category.reorder` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element_category.reorder` | `map_runtime` | — | — | `false` |
| `action.element_collision.add_cells` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element_collision.add_cells` | `map_runtime` | — | — | `false` |
| `action.element_collision.apply_brush_stroke` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element_collision.apply_brush_stroke` | `map_runtime` | — | — | `false` |
| `action.element_collision.apply_polygon` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element_collision.apply_polygon` | `map_runtime` | — | — | `false` |
| `action.element_collision.clear` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element_collision.clear` | `map_runtime` | — | — | `false` |
| `action.element_collision.describe` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element_collision.describe` | `map_runtime` | — | — | `false` |
| `action.element_collision.generate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element_collision.generate` | `map_runtime` | — | — | `false` |
| `action.element_collision.rebuild` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element_collision.rebuild` | `map_runtime` | — | — | `false` |
| `action.element_collision.recalculate_from_padding` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element_collision.recalculate_from_padding` | `map_runtime` | — | — | `false` |
| `action.element_collision.remove_cells` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element_collision.remove_cells` | `map_runtime` | — | — | `false` |
| `action.element_collision.render_preview` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element_collision.render_preview` | `map_runtime` | — | — | `false` |
| `action.element_collision.reset_overrides` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element_collision.reset_overrides` | `map_runtime` | — | — | `false` |
| `action.element_collision.set_primary_shape` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element_collision.set_primary_shape` | `map_runtime` | — | — | `false` |
| `action.element_collision.use_padding_as_base` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element_collision.use_padding_as_base` | `map_runtime` | — | — | `false` |
| `action.element_collision.validate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#element_collision.validate` | `map_runtime` | — | — | `false` |
| `action.encounter.fishing_create` | `catalog_action` | `map_gameplay` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#encounter.fishing_create` | `map_runtime` | — | `FG-100..FG-108` | `false` |
| `action.encounter.gift_create` | `catalog_action` | `map_gameplay` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#encounter.gift_create` | `map_runtime` | — | `FG-100..FG-108` | `false` |
| `action.encounter.headbutt_create` | `catalog_action` | `map_gameplay` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#encounter.headbutt_create` | `map_runtime` | — | `FG-100..FG-108` | `false` |
| `action.encounter.set_consumption_policy` | `catalog_action` | `map_gameplay` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#encounter.set_consumption_policy` | `map_runtime` | — | `FG-100..FG-108` | `false` |
| `action.encounter.set_respawn_policy` | `catalog_action` | `map_gameplay` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#encounter.set_respawn_policy` | `map_runtime` | — | `FG-100..FG-108` | `false` |
| `action.encounter.static_create` | `catalog_action` | `map_gameplay` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#encounter.static_create` | `map_runtime` | — | `FG-100..FG-108` | `false` |
| `action.encounter.surf_create` | `catalog_action` | `map_gameplay` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#encounter.surf_create` | `map_runtime` | — | `FG-100..FG-108` | `false` |
| `action.encounter_entry.add` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#encounter_entry.add` | `map_runtime` | — | `FG-100..FG-108` | `false` |
| `action.encounter_entry.delete` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#encounter_entry.delete` | `map_runtime` | — | `FG-100..FG-108` | `false` |
| `action.encounter_entry.reorder` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#encounter_entry.reorder` | `map_runtime` | — | `FG-100..FG-108` | `false` |
| `action.encounter_entry.update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#encounter_entry.update` | `map_runtime` | — | `FG-100..FG-108` | `false` |
| `action.encounter_table.assign_to_zone` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#encounter_table.assign_to_zone` | `map_runtime` | — | `FG-100..FG-108` | `false` |
| `action.encounter_table.clone` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#encounter_table.clone` | `map_runtime` | — | `FG-100..FG-108` | `false` |
| `action.encounter_table.create` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#encounter_table.create` | `map_runtime` | — | `FG-100..FG-108` | `false` |
| `action.encounter_table.delete_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#encounter_table.delete_apply` | `map_runtime` | — | `FG-100..FG-108` | `false` |
| `action.encounter_table.delete_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#encounter_table.delete_plan` | `map_runtime` | — | `FG-100..FG-108` | `false` |
| `action.encounter_table.get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#encounter_table.get` | `map_runtime` | — | `FG-100..FG-108` | `false` |
| `action.encounter_table.list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#encounter_table.list` | `map_runtime` | — | `FG-100..FG-108` | `false` |
| `action.encounter_table.set_chance` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#encounter_table.set_chance` | `map_runtime` | — | `FG-100..FG-108` | `false` |
| `action.encounter_table.set_conditions` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#encounter_table.set_conditions` | `map_runtime` | — | `FG-100..FG-108` | `false` |
| `action.encounter_table.set_kind` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#encounter_table.set_kind` | `map_runtime` | — | `FG-100..FG-108` | `false` |
| `action.encounter_table.set_tags` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#encounter_table.set_tags` | `map_runtime` | — | `FG-100..FG-108` | `false` |
| `action.encounter_table.simulate_distribution` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#encounter_table.simulate_distribution` | `map_runtime` | — | `FG-100..FG-108` | `false` |
| `action.encounter_table.update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#encounter_table.update` | `map_runtime` | — | `FG-100..FG-108` | `false` |
| `action.encounter_table.validate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#encounter_table.validate` | `map_runtime` | — | `FG-100..FG-108` | `false` |
| `action.entity.batch_move` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#entity.batch_move` | `map_runtime` | — | — | `false` |
| `action.entity.clear_payload` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#entity.clear_payload` | `map_runtime` | — | — | `false` |
| `action.entity.clear_visual` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#entity.clear_visual` | `map_runtime` | — | — | `false` |
| `action.entity.clone` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#entity.clone` | `map_runtime` | — | — | `false` |
| `action.entity.create` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#entity.create` | `map_runtime` | — | — | `false` |
| `action.entity.delete` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#entity.delete` | `map_runtime` | — | — | `false` |
| `action.entity.find_at` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#entity.find_at` | `map_runtime` | — | — | `false` |
| `action.entity.get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#entity.get` | `map_runtime` | — | — | `false` |
| `action.entity.list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#entity.list` | `map_runtime` | — | — | `false` |
| `action.entity.move` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#entity.move` | `map_runtime` | — | — | `false` |
| `action.entity.patch_properties` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#entity.patch_properties` | `map_runtime` | — | — | `false` |
| `action.entity.resize` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#entity.resize` | `map_runtime` | — | — | `false` |
| `action.entity.set_blocks_movement` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#entity.set_blocks_movement` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.entity.set_item_payload` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#entity.set_item_payload` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.entity.set_npc_payload` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#entity.set_npc_payload` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.entity.set_sign_payload` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#entity.set_sign_payload` | `map_runtime` | — | — | `false` |
| `action.entity.set_spawn_payload` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#entity.set_spawn_payload` | `map_runtime` | — | — | `false` |
| `action.entity.set_visual` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#entity.set_visual` | `map_runtime` | — | — | `false` |
| `action.entity.update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#entity.update` | `map_runtime` | — | — | `false` |
| `action.entity.upsert` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#entity.upsert` | `map_runtime` | — | — | `false` |
| `action.entity.validate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#entity.validate` | `map_runtime` | — | — | `false` |
| `action.environment.area_create` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#environment.area_create` | `map_runtime` | — | — | `false` |
| `action.environment.area_delete` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#environment.area_delete` | `map_runtime` | — | — | `false` |
| `action.environment.area_get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#environment.area_get` | `map_runtime` | — | — | `false` |
| `action.environment.area_list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#environment.area_list` | `map_runtime` | — | — | `false` |
| `action.environment.area_set_preset` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#environment.area_set_preset` | `map_runtime` | — | — | `false` |
| `action.environment.area_set_seed` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#environment.area_set_seed` | `map_runtime` | — | — | `false` |
| `action.environment.area_update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#environment.area_update` | `map_runtime` | — | — | `false` |
| `action.environment.attach_to_tile_layer` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#environment.attach_to_tile_layer` | `map_runtime` | — | — | `false` |
| `action.environment.detach_from_tile_layer` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#environment.detach_from_tile_layer` | `map_runtime` | — | — | `false` |
| `action.environment.diagnostics` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#environment.diagnostics` | `map_runtime` | — | — | `false` |
| `action.environment.generate_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#environment.generate_apply` | `map_runtime` | — | — | `false` |
| `action.environment.generate_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#environment.generate_plan` | `map_runtime` | — | — | `false` |
| `action.environment.generated_placement_add` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#environment.generated_placement_add` | `map_runtime` | — | — | `false` |
| `action.environment.generated_placement_delete` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#environment.generated_placement_delete` | `map_runtime` | — | — | `false` |
| `action.environment.generated_placement_move` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#environment.generated_placement_move` | `map_runtime` | — | — | `false` |
| `action.environment.generated_placements_clear` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#environment.generated_placements_clear` | `map_runtime` | — | — | `false` |
| `action.environment.mask_clear` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#environment.mask_clear` | `map_runtime` | — | — | `false` |
| `action.environment.mask_erase` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#environment.mask_erase` | `map_runtime` | — | — | `false` |
| `action.environment.mask_paint` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#environment.mask_paint` | `map_runtime` | — | — | `false` |
| `action.environment.regenerate_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#environment.regenerate_apply` | `map_runtime` | — | — | `false` |
| `action.environment.regenerate_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#environment.regenerate_plan` | `map_runtime` | — | — | `false` |
| `action.environment.render_preview` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#environment.render_preview` | `map_runtime` | — | — | `false` |
| `action.environment.shuffle_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#environment.shuffle_apply` | `map_runtime` | — | — | `false` |
| `action.environment.shuffle_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#environment.shuffle_plan` | `map_runtime` | — | — | `false` |
| `action.evidence.assertSceneOutcome` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#evidence.assertSceneOutcome` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.evidence.assertVisual` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#evidence.assertVisual` | `map_runtime` | — | — | `false` |
| `action.evidence.checkpoint` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#evidence.checkpoint` | `map_runtime` | — | — | `false` |
| `action.evidence.screenshot` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#evidence.screenshot` | `map_runtime` | — | — | `false` |
| `action.evidence.snapshot` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#evidence.snapshot` | `map_runtime` | — | — | `false` |
| `action.export.run` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#export.run` | `map_runtime` | — | — | `false` |
| `action.fix.apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#fix.apply` | `map_runtime` | — | — | `false` |
| `action.fix.describe` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#fix.describe` | `map_runtime` | — | — | `false` |
| `action.fix.list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#fix.list` | `map_runtime` | — | — | `false` |
| `action.fix.plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#fix.plan` | `map_runtime` | — | — | `false` |
| `action.font.assign_role` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#font.assign_role` | `map_runtime` | — | — | `false` |
| `action.font.import_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#font.import_apply` | `map_runtime` | — | — | `false` |
| `action.font.import_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#font.import_plan` | `map_runtime` | — | — | `false` |
| `action.font.inspect` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#font.inspect` | `map_runtime` | — | — | `false` |
| `action.font.validate_glyph_coverage` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#font.validate_glyph_coverage` | `map_runtime` | — | — | `false` |
| `action.font.validate_license` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#font.validate_license` | `map_runtime` | — | — | `false` |
| `action.game.new` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#game.new` | `map_runtime` | — | — | `false` |
| `action.gameplay_zone.clear_payload` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#gameplay_zone.clear_payload` | `map_runtime` | — | — | `false` |
| `action.gameplay_zone.clone` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#gameplay_zone.clone` | `map_runtime` | — | — | `false` |
| `action.gameplay_zone.create` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#gameplay_zone.create` | `map_runtime` | — | — | `false` |
| `action.gameplay_zone.delete` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#gameplay_zone.delete` | `map_runtime` | — | — | `false` |
| `action.gameplay_zone.find_at` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#gameplay_zone.find_at` | `map_runtime` | — | — | `false` |
| `action.gameplay_zone.get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#gameplay_zone.get` | `map_runtime` | — | — | `false` |
| `action.gameplay_zone.list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#gameplay_zone.list` | `map_runtime` | — | — | `false` |
| `action.gameplay_zone.move` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#gameplay_zone.move` | `map_runtime` | — | — | `false` |
| `action.gameplay_zone.resize` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#gameplay_zone.resize` | `map_runtime` | — | — | `false` |
| `action.gameplay_zone.set_encounter_payload` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#gameplay_zone.set_encounter_payload` | `map_runtime` | — | `FG-100..FG-108` | `false` |
| `action.gameplay_zone.set_hazard_payload` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#gameplay_zone.set_hazard_payload` | `map_runtime` | — | — | `false` |
| `action.gameplay_zone.set_movement_effect_payload` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#gameplay_zone.set_movement_effect_payload` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.gameplay_zone.set_movement_payload` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#gameplay_zone.set_movement_payload` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.gameplay_zone.set_priority` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#gameplay_zone.set_priority` | `map_runtime` | — | — | `false` |
| `action.gameplay_zone.set_special_payload` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#gameplay_zone.set_special_payload` | `map_runtime` | — | — | `false` |
| `action.gameplay_zone.update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#gameplay_zone.update` | `map_runtime` | — | — | `false` |
| `action.gameplay_zone.validate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#gameplay_zone.validate` | `map_runtime` | — | — | `false` |
| `action.history.get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#history.get` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.history.list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#history.list` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.import.run` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#import.run` | `map_runtime` | — | — | `false` |
| `action.item.clone` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#item.clone` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.item.create` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#item.create` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.item.delete_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#item.delete_apply` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.item.delete_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#item.delete_plan` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.item.get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#item.get` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.item.list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#item.list` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.item.search` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#item.search` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.item.set_battle_effect` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#item.set_battle_effect` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.item.set_capture_effect` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#item.set_capture_effect` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.item.set_held_effect` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#item.set_held_effect` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.item.set_overworld_effect` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#item.set_overworld_effect` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.item.set_tm_hm_move` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#item.set_tm_hm_move` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.item.simulate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#item.simulate` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.item.update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#item.update` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.item.validate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#item.validate` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.job.artifacts` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#job.artifacts` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.job.cancel` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#job.cancel` | `map_runtime` | — | — | `false` |
| `action.job.events` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#job.events` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.job.get` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#job.get` | `map_runtime` | — | — | `false` |
| `action.job.retry` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#job.retry` | `map_runtime` | — | — | `false` |
| `action.job.submit` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#job.submit` | `map_runtime` | — | — | `false` |
| `action.layer.add_border` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#layer.add_border` | `map_runtime` | — | — | `false` |
| `action.layer.add_collision` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#layer.add_collision` | `map_runtime` | — | — | `false` |
| `action.layer.add_environment` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#layer.add_environment` | `map_runtime` | — | — | `false` |
| `action.layer.add_object` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#layer.add_object` | `map_runtime` | — | — | `false` |
| `action.layer.add_path` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#layer.add_path` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.layer.add_surface` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#layer.add_surface` | `map_runtime` | — | — | `false` |
| `action.layer.add_terrain` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#layer.add_terrain` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.layer.add_tile` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#layer.add_tile` | `map_runtime` | — | — | `false` |
| `action.layer.assign_tileset` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#layer.assign_tileset` | `map_runtime` | — | — | `false` |
| `action.layer.batch_apply` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#layer.batch_apply` | `map_runtime` | — | — | `false` |
| `action.layer.clear_content` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#layer.clear_content` | `map_runtime` | — | — | `false` |
| `action.layer.clone` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#layer.clone` | `map_runtime` | — | — | `false` |
| `action.layer.copy_between_maps` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#layer.copy_between_maps` | `map_runtime` | — | — | `false` |
| `action.layer.delete` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#layer.delete` | `map_runtime` | — | — | `false` |
| `action.layer.delete_all` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#layer.delete_all` | `map_runtime` | — | — | `false` |
| `action.layer.get` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#layer.get` | `map_runtime` | — | — | `false` |
| `action.layer.get_usage` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#layer.get_usage` | `map_runtime` | — | — | `false` |
| `action.layer.list` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#layer.list` | `map_runtime` | — | — | `false` |
| `action.layer.lock` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#layer.lock` | `map_runtime` | — | — | `false` |
| `action.layer.merge_apply` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#layer.merge_apply` | `map_runtime` | — | — | `false` |
| `action.layer.merge_plan` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#layer.merge_plan` | `map_runtime` | — | — | `false` |
| `action.layer.move` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#layer.move` | `map_runtime` | — | — | `false` |
| `action.layer.remove_property` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#layer.remove_property` | `map_runtime` | — | — | `false` |
| `action.layer.rename` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#layer.rename` | `map_runtime` | — | — | `false` |
| `action.layer.reorder` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#layer.reorder` | `map_runtime` | — | — | `false` |
| `action.layer.set_opacity` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#layer.set_opacity` | `map_runtime` | — | — | `false` |
| `action.layer.set_properties` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#layer.set_properties` | `map_runtime` | — | — | `false` |
| `action.layer.set_visibility` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#layer.set_visibility` | `map_runtime` | — | — | `false` |
| `action.layer.unlock` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#layer.unlock` | `map_runtime` | — | — | `false` |
| `action.layer.validate` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#layer.validate` | `map_runtime` | — | — | `false` |
| `action.map.apply_operations` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map.apply_operations` | `map_runtime` | — | — | `false` |
| `action.map.clear_apply` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map.clear_apply` | `map_runtime` | — | — | `false` |
| `action.map.clear_plan` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map.clear_plan` | `map_runtime` | — | — | `false` |
| `action.map.clone` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map.clone` | `map_runtime` | — | — | `false` |
| `action.map.compare` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map.compare` | `map_runtime` | — | — | `false` |
| `action.map.create` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map.create` | `map_runtime` | — | — | `false` |
| `action.map.delete_apply` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map.delete_apply` | `map_runtime` | — | — | `false` |
| `action.map.delete_plan` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map.delete_plan` | `map_runtime` | — | — | `false` |
| `action.map.dependencies` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map.dependencies` | `map_runtime` | — | — | `false` |
| `action.map.draw_path` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map.draw_path` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.map.duplicate` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map.duplicate` | `map_runtime` | — | — | `false` |
| `action.map.get` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map.get` | `map_runtime` | — | — | `false` |
| `action.map.get_region` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map.get_region` | `map_runtime` | — | — | `false` |
| `action.map.get_summary` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map.get_summary` | `map_runtime` | — | — | `false` |
| `action.map.incoming_references` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map.incoming_references` | `map_runtime` | — | — | `false` |
| `action.map.list` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map.list` | `map_runtime` | — | — | `false` |
| `action.map.patch_properties` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map.patch_properties` | `map_runtime` | — | — | `false` |
| `action.map.rename` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map.rename` | `map_runtime` | — | — | `false` |
| `action.map.render` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map.render` | `map_runtime` | — | — | `false` |
| `action.map.render_region` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map.render_region` | `map_runtime` | — | — | `false` |
| `action.map.resize_apply` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map.resize_apply` | `map_runtime` | — | — | `false` |
| `action.map.resize_plan` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map.resize_plan` | `map_runtime` | — | — | `false` |
| `action.map.save` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map.save` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.map.snapshot` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map.snapshot` | `map_runtime` | — | — | `false` |
| `action.map.update_metadata` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map.update_metadata` | `map_runtime` | — | — | `false` |
| `action.map.validate` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map.validate` | `map_runtime` | — | — | `false` |
| `action.map.visual_stack_inspect` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map.visual_stack_inspect` | `map_runtime` | — | — | `false` |
| `action.map.visual_stack_migrate_apply` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map.visual_stack_migrate_apply` | `map_runtime` | — | — | `false` |
| `action.map.visual_stack_migrate_plan` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map.visual_stack_migrate_plan` | `map_runtime` | — | — | `false` |
| `action.map_event.clone` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map_event.clone` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.map_event.create` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map_event.create` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.map_event.delete_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map_event.delete_apply` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.map_event.delete_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map_event.delete_plan` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.map_event.get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map_event.get` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.map_event.list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map_event.list` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.map_event.move` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map_event.move` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.map_event.page_add` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map_event.page_add` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.map_event.page_delete` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map_event.page_delete` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.map_event.page_disable` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map_event.page_disable` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.map_event.page_enable` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map_event.page_enable` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.map_event.page_reorder` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map_event.page_reorder` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.map_event.page_set_condition` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map_event.page_set_condition` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.map_event.page_set_scene` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map_event.page_set_scene` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.map_event.page_set_script` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map_event.page_set_script` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.map_event.page_set_sprite` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map_event.page_set_sprite` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.map_event.page_update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map_event.page_update` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.map_event.update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map_event.update` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.map_event.validate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map_event.validate` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.map_group.create` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map_group.create` | `map_runtime` | — | — | `false` |
| `action.map_group.delete_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map_group.delete_apply` | `map_runtime` | — | — | `false` |
| `action.map_group.delete_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map_group.delete_plan` | `map_runtime` | — | — | `false` |
| `action.map_group.list_tree` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map_group.list_tree` | `map_runtime` | — | — | `false` |
| `action.map_group.move` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map_group.move` | `map_runtime` | — | — | `false` |
| `action.map_group.move_map` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map_group.move_map` | `map_runtime` | — | — | `false` |
| `action.map_group.patch_properties` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map_group.patch_properties` | `map_runtime` | — | — | `false` |
| `action.map_group.rename` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map_group.rename` | `map_runtime` | — | — | `false` |
| `action.map_group.reorder` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map_group.reorder` | `map_runtime` | — | — | `false` |
| `action.map_group.set_tags` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map_group.set_tags` | `map_runtime` | — | — | `false` |
| `action.map_group.update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#map_group.update` | `map_runtime` | — | — | `false` |
| `action.menu.bag.open` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#menu.bag.open` | `map_runtime` | — | `FG-160..FG-165` | `false` |
| `action.menu.bag.use` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#menu.bag.use` | `map_runtime` | — | `FG-160..FG-165` | `false` |
| `action.menu.options.open` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#menu.options.open` | `map_runtime` | — | `FG-160..FG-165` | `false` |
| `action.menu.party.open` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#menu.party.open` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.menu.party.reorder` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#menu.party.reorder` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.menu.party.setLead` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#menu.party.setLead` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.menu.party.summary` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#menu.party.summary` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.menu.pause.close` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#menu.pause.close` | `map_runtime` | — | `FG-160..FG-165` | `false` |
| `action.menu.pause.open` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#menu.pause.open` | `map_runtime` | — | `FG-160..FG-165` | `false` |
| `action.menu.pokedex.open` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#menu.pokedex.open` | `map_runtime` | — | `FG-160..FG-165` | `false` |
| `action.menu.save.open` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#menu.save.open` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.migration.run` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#migration.run` | `map_runtime` | — | — | `false` |
| `action.money.give` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#money.give` | `map_runtime` | — | — | `false` |
| `action.money.inspect` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#money.inspect` | `map_runtime` | — | — | `false` |
| `action.money.set_probe_only` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#money.set_probe_only` | `map_runtime` | — | — | `false` |
| `action.money.take` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#money.take` | `map_runtime` | — | — | `false` |
| `action.move.clone` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#move.clone` | `map_runtime` | — | — | `false` |
| `action.move.create` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#move.create` | `map_runtime` | — | — | `false` |
| `action.move.delete_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#move.delete_apply` | `map_runtime` | — | — | `false` |
| `action.move.delete_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#move.delete_plan` | `map_runtime` | — | — | `false` |
| `action.move.get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#move.get` | `map_runtime` | — | — | `false` |
| `action.move.list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#move.list` | `map_runtime` | — | — | `false` |
| `action.move.search` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#move.search` | `map_runtime` | — | — | `false` |
| `action.move.set_effect` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#move.set_effect` | `map_runtime` | — | — | `false` |
| `action.move.set_engine_support` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#move.set_engine_support` | `map_runtime` | — | — | `false` |
| `action.move.simulate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#move.simulate` | `map_runtime` | — | — | `false` |
| `action.move.update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#move.update` | `map_runtime` | — | — | `false` |
| `action.move.validate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#move.validate` | `map_runtime` | — | — | `false` |
| `action.movement.crossConnection` | `catalog_action` | `map_gameplay` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#movement.crossConnection` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.movement.enterGameplayZone` | `catalog_action` | `map_gameplay` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#movement.enterGameplayZone` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.movement.navigate` | `catalog_action` | `map_gameplay` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#movement.navigate` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.movement.step` | `catalog_action` | `map_gameplay` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#movement.step` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.narrative_event.activate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_event.activate` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_event.clone` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_event.clone` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_event.condition_add` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_event.condition_add` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_event.condition_remove` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_event.condition_remove` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_event.condition_set` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_event.condition_set` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_event.configure` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_event.configure` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_event.create_draft` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_event.create_draft` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_event.deactivate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_event.deactivate` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_event.delete_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_event.delete_apply` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_event.delete_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_event.delete_plan` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_event.get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_event.get` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_event.list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_event.list` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_event.migrate_legacy_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_event.migrate_legacy_apply` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_event.migrate_legacy_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_event.migrate_legacy_plan` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_event.priority_set` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_event.priority_set` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_event.publish` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_event.publish` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_event.reachability` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_event.reachability` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_event.rename` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_event.rename` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_event.reset_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_event.reset_apply` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_event.reset_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_event.reset_plan` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_event.reuse_policy_set` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_event.reuse_policy_set` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_event.scene_set` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_event.scene_set` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_event.simulate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_event.simulate` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_event.source_remove` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_event.source_remove` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_event.source_replace` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_event.source_replace` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_event.source_set` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_event.source_set` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_event.unpublish` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_event.unpublish` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_event.validate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_event.validate` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_fact.clone` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_fact.clone` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_fact.create` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_fact.create` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_fact.delete_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_fact.delete_apply` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_fact.delete_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_fact.delete_plan` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_fact.find_usages` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_fact.find_usages` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_fact.get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_fact.get` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_fact.list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_fact.list` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_fact.type_change_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_fact.type_change_apply` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_fact.type_change_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_fact.type_change_plan` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_fact.update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_fact.update` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.narrative_fact.validate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#narrative_fact.validate` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.network.external` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#network.external` | `map_runtime` | — | — | `false` |
| `action.new_game.build_initial_state` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#new_game.build_initial_state` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.new_game.preview` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#new_game.preview` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.new_game.set_avatar_options` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#new_game.set_avatar_options` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.new_game.set_identity_defaults` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#new_game.set_identity_defaults` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.new_game.set_initial_bag` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#new_game.set_initial_bag` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.new_game.set_initial_facts` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#new_game.set_initial_facts` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.new_game.set_initial_party` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#new_game.set_initial_party` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.new_game.set_start_map` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#new_game.set_start_map` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.new_game.set_start_spawn` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#new_game.set_start_spawn` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.new_game.set_starting_money` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#new_game.set_starting_money` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.new_game.starter_clone` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#new_game.starter_clone` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.new_game.starter_create` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#new_game.starter_create` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.new_game.starter_delete` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#new_game.starter_delete` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.new_game.starter_reorder` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#new_game.starter_reorder` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.new_game.starter_update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#new_game.starter_update` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.new_game.validate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#new_game.validate` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.npc.conditional_dialogue_add` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#npc.conditional_dialogue_add` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.npc.conditional_dialogue_remove` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#npc.conditional_dialogue_remove` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.npc.conditional_dialogue_update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#npc.conditional_dialogue_update` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.npc.preview_route` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#npc.preview_route` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.npc.set_character` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#npc.set_character` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.npc.set_defeat_dialogue` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#npc.set_defeat_dialogue` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.npc.set_dialogue` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#npc.set_dialogue` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.npc.set_facing` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#npc.set_facing` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.npc.set_movement_mode` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#npc.set_movement_mode` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.npc.set_trainer` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#npc.set_trainer` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.npc.set_visibility_rule` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#npc.set_visibility_rule` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.npc.waypoint_add` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#npc.waypoint_add` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.npc.waypoint_clear` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#npc.waypoint_clear` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.npc.waypoint_move` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#npc.waypoint_move` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.npc.waypoint_remove` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#npc.waypoint_remove` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.npc.waypoint_reorder` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#npc.waypoint_reorder` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.package.build` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#package.build` | `map_runtime` | — | — | `false` |
| `action.package.compare` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#package.compare` | `map_runtime` | — | — | `false` |
| `action.package.compatibility_check` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#package.compatibility_check` | `map_runtime` | — | — | `false` |
| `action.package.export_artifact` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#package.export_artifact` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.package.inspect` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#package.inspect` | `map_runtime` | — | — | `false` |
| `action.package.install_receipt_verify` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#package.install_receipt_verify` | `map_runtime` | — | — | `false` |
| `action.package.install_request_build` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#package.install_request_build` | `map_runtime` | — | — | `false` |
| `action.package.inventory` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#package.inventory` | `map_runtime` | — | — | `false` |
| `action.package.personalization_preflight` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#package.personalization_preflight` | `map_runtime` | — | — | `false` |
| `action.package.plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#package.plan` | `map_runtime` | — | — | `false` |
| `action.package.release_decision` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#package.release_decision` | `map_runtime` | — | — | `false` |
| `action.package.release_gate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#package.release_gate` | `map_runtime` | — | — | `false` |
| `action.package.sign` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#package.sign` | `map_runtime` | — | — | `false` |
| `action.package.verify_content` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#package.verify_content` | `map_runtime` | — | — | `false` |
| `action.package.verify_digest` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#package.verify_digest` | `map_runtime` | — | — | `false` |
| `action.package.verify_signature` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#package.verify_signature` | `map_runtime` | — | — | `false` |
| `action.palette_entry.clone` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#palette_entry.clone` | `map_runtime` | — | — | `false` |
| `action.palette_entry.create` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#palette_entry.create` | `map_runtime` | — | — | `false` |
| `action.palette_entry.delete` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#palette_entry.delete` | `map_runtime` | — | — | `false` |
| `action.palette_entry.get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#palette_entry.get` | `map_runtime` | — | — | `false` |
| `action.palette_entry.list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#palette_entry.list` | `map_runtime` | — | — | `false` |
| `action.palette_entry.move_category` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#palette_entry.move_category` | `map_runtime` | — | — | `false` |
| `action.palette_entry.render_preview` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#palette_entry.render_preview` | `map_runtime` | — | — | `false` |
| `action.palette_entry.reorder` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#palette_entry.reorder` | `map_runtime` | — | — | `false` |
| `action.palette_entry.set_animation` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#palette_entry.set_animation` | `map_runtime` | — | — | `false` |
| `action.palette_entry.set_frames` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#palette_entry.set_frames` | `map_runtime` | — | — | `false` |
| `action.palette_entry.update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#palette_entry.update` | `map_runtime` | — | — | `false` |
| `action.palette_entry.upsert` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#palette_entry.upsert` | `map_runtime` | — | — | `false` |
| `action.palette_entry.validate_source_rect` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#palette_entry.validate_source_rect` | `map_runtime` | — | — | `false` |
| `action.party.add` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#party.add` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.party.cure_status` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#party.cure_status` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.party.equip_held_item` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#party.equip_held_item` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.party.evolve` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#party.evolve` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.party.forget_move` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#party.forget_move` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.party.give_pokemon` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#party.give_pokemon` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.party.heal` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#party.heal` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.party.inspect` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#party.inspect` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.party.learn_move` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#party.learn_move` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.party.remove_guarded` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#party.remove_guarded` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.party.reorder` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#party.reorder` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.party.replace_move` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#party.replace_move` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.party.restore_pp` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#party.restore_pp` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.party.revive` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#party.revive` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.party.set_lead` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#party.set_lead` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.party.summary` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#party.summary` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.party.swap` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#party.swap` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.party.unequip_held_item` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#party.unequip_held_item` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.path.assign_preset` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#path.assign_preset` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.path.erase` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#path.erase` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.path.erase_pattern` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#path.erase_pattern` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.path.fill` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#path.fill` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.path.paint` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#path.paint` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.path.paint_pattern` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#path.paint_pattern` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.path.preview` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#path.preview` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.path.set_animation_mode` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#path.set_animation_mode` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.path.set_properties` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#path.set_properties` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.path.trigger_add` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#path.trigger_add` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.path.trigger_remove` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#path.trigger_remove` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.path.trigger_update` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#path.trigger_update` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.path_preset.autotile_preview` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#path_preset.autotile_preview` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.path_preset.autotile_validate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#path_preset.autotile_validate` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.path_preset.variant_map` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#path_preset.variant_map` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.path_preset.variant_unmap` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#path_preset.variant_unmap` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.pc.box_get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#pc.box_get` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.pc.box_list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#pc.box_list` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.pc.deposit` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#pc.deposit` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.pc.inspect` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#pc.inspect` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.pc.move_between_boxes` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#pc.move_between_boxes` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.pc.move_within_box` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#pc.move_within_box` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.pc.place_first_available` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#pc.place_first_available` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.pc.summary` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#pc.summary` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.pc.swap_party_with_box` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#pc.swap_party_with_box` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.pc.validate_capacity` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#pc.validate_capacity` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.pc.withdraw` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#pc.withdraw` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.placed_element.batch_place` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#placed_element.batch_place` | `map_runtime` | — | — | `false` |
| `action.placed_element.behavior_add` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#placed_element.behavior_add` | `map_runtime` | — | — | `false` |
| `action.placed_element.behavior_disable` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#placed_element.behavior_disable` | `map_runtime` | — | — | `false` |
| `action.placed_element.behavior_enable` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#placed_element.behavior_enable` | `map_runtime` | — | — | `false` |
| `action.placed_element.behavior_remove` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#placed_element.behavior_remove` | `map_runtime` | — | — | `false` |
| `action.placed_element.behavior_update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#placed_element.behavior_update` | `map_runtime` | — | — | `false` |
| `action.placed_element.clear_shadow_override` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#placed_element.clear_shadow_override` | `map_runtime` | — | — | `false` |
| `action.placed_element.clone` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#placed_element.clone` | `map_runtime` | — | — | `false` |
| `action.placed_element.delete` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#placed_element.delete` | `map_runtime` | — | — | `false` |
| `action.placed_element.detach_from_tile_projection` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#placed_element.detach_from_tile_projection` | `map_runtime` | — | — | `false` |
| `action.placed_element.find_at` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#placed_element.find_at` | `map_runtime` | — | — | `false` |
| `action.placed_element.get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#placed_element.get` | `map_runtime` | — | — | `false` |
| `action.placed_element.list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#placed_element.list` | `map_runtime` | — | — | `false` |
| `action.placed_element.move` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#placed_element.move` | `map_runtime` | — | — | `false` |
| `action.placed_element.patch_properties` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#placed_element.patch_properties` | `map_runtime` | — | — | `false` |
| `action.placed_element.place` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#placed_element.place` | `map_runtime` | — | — | `false` |
| `action.placed_element.replace_for_layer` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#placed_element.replace_for_layer` | `map_runtime` | — | — | `false` |
| `action.placed_element.reset_animation` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#placed_element.reset_animation` | `map_runtime` | — | — | `false` |
| `action.placed_element.rotate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#placed_element.rotate` | `map_runtime` | — | — | `false` |
| `action.placed_element.set_animation` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#placed_element.set_animation` | `map_runtime` | — | — | `false` |
| `action.placed_element.set_collision` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#placed_element.set_collision` | `map_runtime` | — | — | `false` |
| `action.placed_element.set_opacity` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#placed_element.set_opacity` | `map_runtime` | — | — | `false` |
| `action.placed_element.set_shadow_override` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#placed_element.set_shadow_override` | `map_runtime` | — | — | `false` |
| `action.placed_element.update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#placed_element.update` | `map_runtime` | — | — | `false` |
| `action.placed_element.validate_footprint` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#placed_element.validate_footprint` | `map_runtime` | — | — | `false` |
| `action.playtest.assert` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#playtest.assert` | `map_runtime` | — | — | `false` |
| `action.playtest.capture` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#playtest.capture` | `map_runtime` | — | — | `false` |
| `action.playtest.command` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#playtest.command` | `map_runtime` | — | — | `false` |
| `action.playtest.control` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#playtest.control` | `map_runtime` | — | — | `false` |
| `action.playtest.inspect_events` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#playtest.inspect_events` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.playtest.inspect_logs` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#playtest.inspect_logs` | `map_runtime` | — | — | `false` |
| `action.playtest.inspect_state` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#playtest.inspect_state` | `map_runtime` | — | — | `false` |
| `action.playtest.pause` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#playtest.pause` | `map_runtime` | — | — | `false` |
| `action.playtest.receipt_get` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#playtest.receipt_get` | `map_runtime` | — | — | `false` |
| `action.playtest.resume` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#playtest.resume` | `map_runtime` | — | — | `false` |
| `action.playtest.run` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#playtest.run` | `map_runtime` | — | — | `false` |
| `action.playtest.run_scenario` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#playtest.run_scenario` | `map_runtime` | — | — | `false` |
| `action.playtest.scenario_list` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#playtest.scenario_list` | `map_runtime` | — | — | `false` |
| `action.playtest.start` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#playtest.start` | `map_runtime` | — | — | `false` |
| `action.playtest.stop` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#playtest.stop` | `map_runtime` | — | — | `false` |
| `action.pokemon_catalog.create_entry` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#pokemon_catalog.create_entry` | `map_runtime` | — | — | `false` |
| `action.pokemon_catalog.delete_entry_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#pokemon_catalog.delete_entry_apply` | `map_runtime` | — | — | `false` |
| `action.pokemon_catalog.delete_entry_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#pokemon_catalog.delete_entry_plan` | `map_runtime` | — | — | `false` |
| `action.pokemon_catalog.export` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#pokemon_catalog.export` | `map_runtime` | — | — | `false` |
| `action.pokemon_catalog.find_usages` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#pokemon_catalog.find_usages` | `map_runtime` | — | — | `false` |
| `action.pokemon_catalog.get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#pokemon_catalog.get` | `map_runtime` | — | — | `false` |
| `action.pokemon_catalog.import_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#pokemon_catalog.import_apply` | `map_runtime` | — | — | `false` |
| `action.pokemon_catalog.import_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#pokemon_catalog.import_plan` | `map_runtime` | — | — | `false` |
| `action.pokemon_catalog.list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#pokemon_catalog.list` | `map_runtime` | — | — | `false` |
| `action.pokemon_catalog.search` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#pokemon_catalog.search` | `map_runtime` | — | — | `false` |
| `action.pokemon_catalog.sync_external_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#pokemon_catalog.sync_external_apply` | `map_runtime` | — | — | `false` |
| `action.pokemon_catalog.sync_external_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#pokemon_catalog.sync_external_plan` | `map_runtime` | — | — | `false` |
| `action.pokemon_catalog.update_entry` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#pokemon_catalog.update_entry` | `map_runtime` | — | — | `false` |
| `action.pokemon_catalog.upsert_entry` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#pokemon_catalog.upsert_entry` | `map_runtime` | — | — | `false` |
| `action.pokemon_catalog.validate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#pokemon_catalog.validate` | `map_runtime` | — | — | `false` |
| `action.preset.export` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#preset.export` | `map_runtime` | — | — | `false` |
| `action.preset.import_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#preset.import_apply` | `map_runtime` | — | — | `false` |
| `action.preset.import_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#preset.import_plan` | `map_runtime` | — | — | `false` |
| `action.preset.publish_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#preset.publish_apply` | `map_runtime` | — | — | `false` |
| `action.preset.publish_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#preset.publish_plan` | `map_runtime` | — | — | `false` |
| `action.preset.render_preview` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#preset.render_preview` | `map_runtime` | — | — | `false` |
| `action.preset.validate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#preset.validate` | `map_runtime` | — | — | `false` |
| `action.probe.goto` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#probe.goto` | `map_runtime` | — | — | `false` |
| `action.probe.loadCheckpoint` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#probe.loadCheckpoint` | `map_runtime` | — | — | `false` |
| `action.probe.overrideFact` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#probe.overrideFact` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.probe.seedBag` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#probe.seedBag` | `map_runtime` | — | — | `false` |
| `action.probe.seedParty` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#probe.seedParty` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.probe.setMoney` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#probe.setMoney` | `map_runtime` | — | — | `false` |
| `action.process.execute` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#process.execute` | `map_runtime` | — | — | `false` |
| `action.progression.accept_evolution` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#progression.accept_evolution` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.progression.accept_move_learning` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#progression.accept_move_learning` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.progression.apply_badge` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#progression.apply_badge` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.progression.apply_capture_destination` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#progression.apply_capture_destination` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.progression.apply_level_up` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#progression.apply_level_up` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.progression.apply_rewards` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#progression.apply_rewards` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.progression.apply_trainer_defeated` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#progression.apply_trainer_defeated` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.progression.apply_xp` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#progression.apply_xp` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.progression.preview_evolution` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#progression.preview_evolution` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.progression.preview_level_up` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#progression.preview_level_up` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.progression.preview_move_learning` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#progression.preview_move_learning` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.progression.preview_rewards` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#progression.preview_rewards` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.progression.preview_xp` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#progression.preview_xp` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.progression.refuse_evolution` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#progression.refuse_evolution` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.progression.refuse_move_learning` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#progression.refuse_move_learning` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.project.clone` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.clone` | `map_runtime` | — | — | `false` |
| `action.project.close` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.close` | `map_runtime` | — | — | `false` |
| `action.project.create` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.create` | `map_runtime` | — | — | `false` |
| `action.project.delete_apply` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.delete_apply` | `map_runtime` | — | — | `false` |
| `action.project.delete_plan` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.delete_plan` | `map_runtime` | — | — | `false` |
| `action.project.destructive` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.destructive` | `map_runtime` | — | — | `false` |
| `action.project.diff` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.diff` | `map_runtime` | — | — | `false` |
| `action.project.export` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.export` | `map_runtime` | — | — | `false` |
| `action.project.global_properties_get` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.global_properties_get` | `map_runtime` | — | — | `false` |
| `action.project.global_properties_patch` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.global_properties_patch` | `map_runtime` | — | — | `false` |
| `action.project.global_properties_remove` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.global_properties_remove` | `map_runtime` | — | — | `false` |
| `action.project.import_apply` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.import_apply` | `map_runtime` | — | — | `false` |
| `action.project.import_plan` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.import_plan` | `map_runtime` | — | — | `false` |
| `action.project.inspect` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.inspect` | `map_runtime` | — | — | `false` |
| `action.project.list_content` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.list_content` | `map_runtime` | — | — | `false` |
| `action.project.list_files` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.list_files` | `map_runtime` | — | — | `false` |
| `action.project.migration_apply` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.migration_apply` | `map_runtime` | — | — | `false` |
| `action.project.migration_list` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.migration_list` | `map_runtime` | — | — | `false` |
| `action.project.migration_plan` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.migration_plan` | `map_runtime` | — | — | `false` |
| `action.project.new_game_config_get` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.new_game_config_get` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.project.new_game_config_update` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.new_game_config_update` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.project.open` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.open` | `map_runtime` | — | — | `false` |
| `action.project.pokemon_config_get` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.pokemon_config_get` | `map_runtime` | — | — | `false` |
| `action.project.pokemon_config_update` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.pokemon_config_update` | `map_runtime` | — | — | `false` |
| `action.project.presentation_get` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.presentation_get` | `map_runtime` | — | — | `false` |
| `action.project.presentation_update` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.presentation_update` | `map_runtime` | — | — | `false` |
| `action.project.read` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.read` | `map_runtime` | — | — | `false` |
| `action.project.reference_graph` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.reference_graph` | `map_runtime` | — | — | `false` |
| `action.project.reload` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.reload` | `map_runtime` | — | — | `false` |
| `action.project.revision_get` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.revision_get` | `map_runtime` | — | — | `false` |
| `action.project.search` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.search` | `map_runtime` | — | — | `false` |
| `action.project.settings_get` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.settings_get` | `map_runtime` | — | — | `false` |
| `action.project.settings_update` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.settings_update` | `map_runtime` | — | — | `false` |
| `action.project.statistics` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.statistics` | `map_runtime` | — | — | `false` |
| `action.project.update` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.update` | `map_runtime` | — | — | `false` |
| `action.project.validate` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.validate` | `map_runtime` | — | — | `false` |
| `action.project.version_upgrade_apply` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.version_upgrade_apply` | `map_runtime` | — | — | `false` |
| `action.project.version_upgrade_plan` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.version_upgrade_plan` | `map_runtime` | — | — | `false` |
| `action.project.write` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project.write` | `map_runtime` | — | — | `false` |
| `action.project_snapshot.create` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project_snapshot.create` | `map_runtime` | — | — | `false` |
| `action.project_snapshot.delete` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project_snapshot.delete` | `map_runtime` | — | — | `false` |
| `action.project_snapshot.get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project_snapshot.get` | `map_runtime` | — | — | `false` |
| `action.project_snapshot.list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project_snapshot.list` | `map_runtime` | — | — | `false` |
| `action.project_snapshot.restore_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project_snapshot.restore_apply` | `map_runtime` | — | — | `false` |
| `action.project_snapshot.restore_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#project_snapshot.restore_plan` | `map_runtime` | — | — | `false` |
| `action.raster.build_atlas` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#raster.build_atlas` | `map_runtime` | — | — | `false` |
| `action.raster.crop` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#raster.crop` | `map_runtime` | — | — | `false` |
| `action.raster.detect_grid` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#raster.detect_grid` | `map_runtime` | — | — | `false` |
| `action.raster.inspect_alpha` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#raster.inspect_alpha` | `map_runtime` | — | — | `false` |
| `action.raster.inspect_dimensions` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#raster.inspect_dimensions` | `map_runtime` | — | — | `false` |
| `action.raster.normalize_grid` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#raster.normalize_grid` | `map_runtime` | — | — | `false` |
| `action.raster.optimize` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#raster.optimize` | `map_runtime` | — | — | `false` |
| `action.raster.render_preview` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#raster.render_preview` | `map_runtime` | — | — | `false` |
| `action.raster.slice` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#raster.slice` | `map_runtime` | — | — | `false` |
| `action.raster.transparent_color_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#raster.transparent_color_apply` | `map_runtime` | — | — | `false` |
| `action.raster.transparent_color_preview` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#raster.transparent_color_preview` | `map_runtime` | — | — | `false` |
| `action.raster.validate_bounds` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#raster.validate_bounds` | `map_runtime` | — | — | `false` |
| `action.readiness.authoring_parity_report` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#readiness.authoring_parity_report` | `map_runtime` | — | — | `false` |
| `action.readiness.capability_truth` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#readiness.capability_truth` | `map_runtime` | — | — | `false` |
| `action.readiness.gameplay_report` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#readiness.gameplay_report` | `map_runtime` | — | — | `false` |
| `action.readiness.golden_slice_run` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#readiness.golden_slice_run` | `map_runtime` | — | — | `false` |
| `action.readiness.regression_matrix` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#readiness.regression_matrix` | `map_runtime` | — | — | `false` |
| `action.readiness.release_gate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#readiness.release_gate` | `map_runtime` | — | — | `false` |
| `action.readiness.roadmap_dashboard` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#readiness.roadmap_dashboard` | `map_runtime` | — | — | `false` |
| `action.readiness.runtime_consumer_report` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#readiness.runtime_consumer_report` | `map_runtime` | — | — | `false` |
| `action.receipt.get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#receipt.get` | `map_runtime` | — | — | `false` |
| `action.recovery.apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#recovery.apply` | `map_runtime` | — | — | `false` |
| `action.recovery.dismiss` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#recovery.dismiss` | `map_runtime` | — | — | `false` |
| `action.recovery.inspect` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#recovery.inspect` | `map_runtime` | — | — | `false` |
| `action.recovery.plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#recovery.plan` | `map_runtime` | — | — | `false` |
| `action.redo.apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#redo.apply` | `map_runtime` | — | — | `false` |
| `action.redo.plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#redo.plan` | `map_runtime` | — | — | `false` |
| `action.region.clear` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#region.clear` | `map_runtime` | — | — | `false` |
| `action.region.copy` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#region.copy` | `map_runtime` | — | — | `false` |
| `action.region.crop` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#region.crop` | `map_runtime` | — | — | `false` |
| `action.region.cut` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#region.cut` | `map_runtime` | — | — | `false` |
| `action.region.draw_line` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#region.draw_line` | `map_runtime` | — | — | `false` |
| `action.region.draw_polyline` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#region.draw_polyline` | `map_runtime` | — | — | `false` |
| `action.region.fill_layer` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#region.fill_layer` | `map_runtime` | — | — | `false` |
| `action.region.fill_polygon` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#region.fill_polygon` | `map_runtime` | — | — | `false` |
| `action.region.fill_rect` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#region.fill_rect` | `map_runtime` | — | — | `false` |
| `action.region.find_usages` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#region.find_usages` | `map_runtime` | — | — | `false` |
| `action.region.flip_horizontal` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#region.flip_horizontal` | `map_runtime` | — | — | `false` |
| `action.region.flip_vertical` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#region.flip_vertical` | `map_runtime` | — | — | `false` |
| `action.region.flood_fill` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#region.flood_fill` | `map_runtime` | — | — | `false` |
| `action.region.get` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#region.get` | `map_runtime` | — | — | `false` |
| `action.region.histogram` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#region.histogram` | `map_runtime` | — | — | `false` |
| `action.region.invert` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#region.invert` | `map_runtime` | — | — | `false` |
| `action.region.move` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#region.move` | `map_runtime` | — | — | `false` |
| `action.region.paint_pattern` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#region.paint_pattern` | `map_runtime` | — | — | `false` |
| `action.region.paste` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#region.paste` | `map_runtime` | — | — | `false` |
| `action.region.replace` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#region.replace` | `map_runtime` | — | — | `false` |
| `action.region.rotate` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#region.rotate` | `map_runtime` | — | — | `false` |
| `action.region.stamp` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#region.stamp` | `map_runtime` | — | — | `false` |
| `action.region.stamp_template` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#region.stamp_template` | `map_runtime` | — | — | `false` |
| `action.render.before_after` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#render.before_after` | `map_runtime` | — | — | `false` |
| `action.render.cancel` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#render.cancel` | `map_runtime` | — | — | `false` |
| `action.render.change_preview` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#render.change_preview` | `map_runtime` | — | — | `false` |
| `action.render.layer` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#render.layer` | `map_runtime` | — | — | `false` |
| `action.render.map` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#render.map` | `map_runtime` | — | — | `false` |
| `action.render.map_region` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#render.map_region` | `map_runtime` | — | — | `false` |
| `action.render.overlay` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#render.overlay` | `map_runtime` | — | `FG-160..FG-165` | `false` |
| `action.render.resource` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#render.resource` | `map_runtime` | — | — | `false` |
| `action.render.run` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#render.run` | `map_runtime` | — | — | `false` |
| `action.render.status` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#render.status` | `map_runtime` | — | — | `false` |
| `action.render.thumbnail` | `catalog_action` | `map_runtime` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#render.thumbnail` | `map_runtime` | — | — | `false` |
| `action.resource.batch` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#resource.batch` | `map_runtime` | — | — | `false` |
| `action.resource.batch_get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#resource.batch_get` | `map_runtime` | — | — | `false` |
| `action.resource.clone` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#resource.clone` | `map_runtime` | — | — | `false` |
| `action.resource.create` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#resource.create` | `map_runtime` | — | — | `false` |
| `action.resource.delete_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#resource.delete_apply` | `map_runtime` | — | — | `false` |
| `action.resource.delete_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#resource.delete_plan` | `map_runtime` | — | — | `false` |
| `action.resource.diff` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#resource.diff` | `map_runtime` | — | — | `false` |
| `action.resource.export` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#resource.export` | `map_runtime` | — | — | `false` |
| `action.resource.get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#resource.get` | `map_runtime` | — | — | `false` |
| `action.resource.import_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#resource.import_apply` | `map_runtime` | — | — | `false` |
| `action.resource.import_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#resource.import_plan` | `map_runtime` | — | — | `false` |
| `action.resource.link` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#resource.link` | `map_runtime` | — | — | `false` |
| `action.resource.list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#resource.list` | `map_runtime` | — | — | `false` |
| `action.resource.migrate_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#resource.migrate_apply` | `map_runtime` | — | — | `false` |
| `action.resource.migrate_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#resource.migrate_plan` | `map_runtime` | — | — | `false` |
| `action.resource.move` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#resource.move` | `map_runtime` | — | — | `false` |
| `action.resource.patch` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#resource.patch` | `map_runtime` | — | — | `false` |
| `action.resource.reorder` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#resource.reorder` | `map_runtime` | — | — | `false` |
| `action.resource.restore` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#resource.restore` | `map_runtime` | — | — | `false` |
| `action.resource.search` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#resource.search` | `map_runtime` | — | — | `false` |
| `action.resource.snapshot` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#resource.snapshot` | `map_runtime` | — | — | `false` |
| `action.resource.summary` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#resource.summary` | `map_runtime` | — | — | `false` |
| `action.resource.unlink` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#resource.unlink` | `map_runtime` | — | — | `false` |
| `action.resource.update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#resource.update` | `map_runtime` | — | — | `false` |
| `action.resource.upsert` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#resource.upsert` | `map_runtime` | — | — | `false` |
| `action.resource_kind.describe` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#resource_kind.describe` | `map_editor,map_runtime,mcp` | — | — | `false` |
| `action.resource_kind.list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#resource_kind.list` | `map_editor,map_runtime,mcp` | — | — | `false` |
| `action.revision.diff` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#revision.diff` | `map_runtime` | — | — | `false` |
| `action.revision.revert_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#revision.revert_apply` | `map_runtime` | — | — | `false` |
| `action.revision.revert_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#revision.revert_plan` | `map_runtime` | — | — | `false` |
| `action.save.checkpoint_create` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#save.checkpoint_create` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.save.checkpoint_restore` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#save.checkpoint_restore` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.save.clone` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#save.clone` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.save.decode` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#save.decode` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.save.delete_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#save.delete_apply` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.save.delete_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#save.delete_plan` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.save.diff` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#save.diff` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.save.encode` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#save.encode` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.save.export` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#save.export` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.save.get_slot` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#save.get_slot` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.save.import_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#save.import_apply` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.save.import_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#save.import_plan` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.save.inspect` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#save.inspect` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.save.list_slots` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#save.list_slots` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.save.migrate_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#save.migrate_apply` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.save.migrate_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#save.migrate_plan` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.save.reload` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#save.reload` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.save.rollback` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#save.rollback` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.save.slotSelect` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#save.slotSelect` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.save.validate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#save.validate` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.save.write` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#save.write` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.scenario.binding_set` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scenario.binding_set` | `map_runtime` | — | — | `false` |
| `action.scenario.clone` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scenario.clone` | `map_runtime` | — | — | `false` |
| `action.scenario.condition_set` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scenario.condition_set` | `map_runtime` | — | — | `false` |
| `action.scenario.create` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scenario.create` | `map_runtime` | — | — | `false` |
| `action.scenario.delete_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scenario.delete_apply` | `map_runtime` | — | — | `false` |
| `action.scenario.delete_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scenario.delete_plan` | `map_runtime` | — | — | `false` |
| `action.scenario.edge_add` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scenario.edge_add` | `map_runtime` | — | — | `false` |
| `action.scenario.edge_delete` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scenario.edge_delete` | `map_runtime` | — | — | `false` |
| `action.scenario.edge_update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scenario.edge_update` | `map_runtime` | — | — | `false` |
| `action.scenario.get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scenario.get` | `map_runtime` | — | — | `false` |
| `action.scenario.list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scenario.list` | `map_runtime` | — | — | `false` |
| `action.scenario.migrate_to_storyline_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scenario.migrate_to_storyline_apply` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.scenario.migrate_to_storyline_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scenario.migrate_to_storyline_plan` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.scenario.node_add` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scenario.node_add` | `map_runtime` | — | — | `false` |
| `action.scenario.node_delete` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scenario.node_delete` | `map_runtime` | — | — | `false` |
| `action.scenario.node_move` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scenario.node_move` | `map_runtime` | — | — | `false` |
| `action.scenario.node_update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scenario.node_update` | `map_runtime` | — | — | `false` |
| `action.scenario.simulate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scenario.simulate` | `map_runtime` | — | — | `false` |
| `action.scenario.update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scenario.update` | `map_runtime` | — | — | `false` |
| `action.scenario.validate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scenario.validate` | `map_runtime` | — | — | `false` |
| `action.scene.action_configure` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scene.action_configure` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.scene.archive` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scene.archive` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.scene.battle_configure` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scene.battle_configure` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.scene.branch_configure` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scene.branch_configure` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.scene.cinematic_configure` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scene.cinematic_configure` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.scene.clone` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scene.clone` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.scene.condition_configure` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scene.condition_configure` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.scene.create` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scene.create` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.scene.delete_apply` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scene.delete_apply` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.scene.delete_plan` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scene.delete_plan` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.scene.dialogue_configure` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scene.dialogue_configure` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.scene.edge_add` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scene.edge_add` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.scene.edge_delete` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scene.edge_delete` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.scene.edge_set_layout` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scene.edge_set_layout` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.scene.edge_update` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scene.edge_update` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.scene.end_configure` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scene.end_configure` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.scene.get` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scene.get` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.scene.list` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scene.list` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.scene.merge_configure` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scene.merge_configure` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.scene.node_add` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scene.node_add` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.scene.node_clone` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scene.node_clone` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.scene.node_delete` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scene.node_delete` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.scene.node_set_layout` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scene.node_set_layout` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.scene.node_update` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scene.node_update` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.scene.outcome_add` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scene.outcome_add` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.scene.outcome_delete` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scene.outcome_delete` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.scene.outcome_update` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scene.outcome_update` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.scene.preview` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scene.preview` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.scene.reachability` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scene.reachability` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.scene.restore` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scene.restore` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.scene.simulate` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scene.simulate` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.scene.start_set` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scene.start_set` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.scene.update` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scene.update` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.scene.validate` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#scene.validate` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.schema.get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#schema.get` | `map_editor,map_runtime,mcp` | — | — | `false` |
| `action.schema.list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#schema.list` | `map_editor,map_runtime,mcp` | — | — | `false` |
| `action.script.clone` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#script.clone` | `map_runtime` | — | — | `false` |
| `action.script.command_add` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#script.command_add` | `map_runtime` | — | — | `false` |
| `action.script.command_delete` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#script.command_delete` | `map_runtime` | — | — | `false` |
| `action.script.command_reorder` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#script.command_reorder` | `map_runtime` | — | — | `false` |
| `action.script.command_update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#script.command_update` | `map_runtime` | — | — | `false` |
| `action.script.condition_set` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#script.condition_set` | `map_runtime` | — | — | `false` |
| `action.script.create` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#script.create` | `map_runtime` | — | — | `false` |
| `action.script.delete_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#script.delete_apply` | `map_runtime` | — | — | `false` |
| `action.script.delete_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#script.delete_plan` | `map_runtime` | — | — | `false` |
| `action.script.get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#script.get` | `map_runtime` | — | — | `false` |
| `action.script.list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#script.list` | `map_runtime` | — | — | `false` |
| `action.script.migrate_to_scene_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#script.migrate_to_scene_apply` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.script.migrate_to_scene_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#script.migrate_to_scene_plan` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.script.node_add` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#script.node_add` | `map_runtime` | — | — | `false` |
| `action.script.node_delete` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#script.node_delete` | `map_runtime` | — | — | `false` |
| `action.script.node_move` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#script.node_move` | `map_runtime` | — | — | `false` |
| `action.script.node_reorder` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#script.node_reorder` | `map_runtime` | — | — | `false` |
| `action.script.node_update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#script.node_update` | `map_runtime` | — | — | `false` |
| `action.script.simulate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#script.simulate` | `map_runtime` | — | — | `false` |
| `action.script.update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#script.update` | `map_runtime` | — | — | `false` |
| `action.script.validate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#script.validate` | `map_runtime` | — | — | `false` |
| `action.secret.use` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#secret.use` | `map_runtime` | — | — | `false` |
| `action.server.get_info` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#server.get_info` | `map_editor,map_runtime,mcp` | — | — | `false` |
| `action.server.get_limits` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#server.get_limits` | `map_editor,map_runtime,mcp` | — | — | `false` |
| `action.server.health` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#server.health` | `map_editor,map_runtime,mcp` | — | `FG-040..FG-073` | `false` |
| `action.service.heal` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#service.heal` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.service.heal_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#service.heal_apply` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.service.heal_close` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#service.heal_close` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.service.heal_confirm` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#service.heal_confirm` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.service.heal_open` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#service.heal_open` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.service.pc.deposit` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#service.pc.deposit` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.service.pc.move` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#service.pc.move` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.service.pc.summary` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#service.pc.summary` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.service.pc.swap` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#service.pc.swap` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.service.pc.withdraw` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#service.pc.withdraw` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.service.pc_close` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#service.pc_close` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.service.pc_open` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#service.pc_open` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.service.shop.buy` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#service.shop.buy` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.service.shop.close` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#service.shop.close` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.service.shop.inspect` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#service.shop.inspect` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.service.shop.sell` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#service.shop.sell` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.service.shop_buy` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#service.shop_buy` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.service.shop_close` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#service.shop_close` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.service.shop_inspect` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#service.shop_inspect` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.service.shop_open` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#service.shop_open` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.service.shop_sell` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#service.shop_sell` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.shop.clone` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#shop.clone` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.shop.create` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#shop.create` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.shop.delete_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#shop.delete_apply` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.shop.delete_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#shop.delete_plan` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.shop.entry_add` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#shop.entry_add` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.shop.entry_delete` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#shop.entry_delete` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.shop.entry_reorder` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#shop.entry_reorder` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.shop.entry_update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#shop.entry_update` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.shop.get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#shop.get` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.shop.list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#shop.list` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.shop.set_conditions` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#shop.set_conditions` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.shop.set_state` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#shop.set_state` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.shop.set_stock_policy` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#shop.set_stock_policy` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.shop.simulate_transaction` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#shop.simulate_transaction` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.shop.update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#shop.update` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.shop.validate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#shop.validate` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.species.batch_import_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#species.batch_import_apply` | `map_runtime` | — | — | `false` |
| `action.species.batch_import_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#species.batch_import_plan` | `map_runtime` | — | — | `false` |
| `action.species.clone` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#species.clone` | `map_runtime` | — | — | `false` |
| `action.species.create` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#species.create` | `map_runtime` | — | — | `false` |
| `action.species.delete_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#species.delete_apply` | `map_runtime` | — | — | `false` |
| `action.species.delete_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#species.delete_plan` | `map_runtime` | — | — | `false` |
| `action.species.form_add` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#species.form_add` | `map_runtime` | — | — | `false` |
| `action.species.form_delete` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#species.form_delete` | `map_runtime` | — | — | `false` |
| `action.species.form_update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#species.form_update` | `map_runtime` | — | — | `false` |
| `action.species.get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#species.get` | `map_runtime` | — | — | `false` |
| `action.species.import_external_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#species.import_external_apply` | `map_runtime` | — | — | `false` |
| `action.species.import_external_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#species.import_external_plan` | `map_runtime` | — | — | `false` |
| `action.species.import_json_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#species.import_json_apply` | `map_runtime` | — | — | `false` |
| `action.species.import_json_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#species.import_json_plan` | `map_runtime` | — | — | `false` |
| `action.species.list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#species.list` | `map_runtime` | — | — | `false` |
| `action.species.render_preview` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#species.render_preview` | `map_runtime` | — | — | `false` |
| `action.species.search` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#species.search` | `map_runtime` | — | — | `false` |
| `action.species.set_abilities` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#species.set_abilities` | `map_runtime` | — | — | `false` |
| `action.species.set_breeding_data` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#species.set_breeding_data` | `map_runtime` | — | — | `false` |
| `action.species.set_capture_data` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#species.set_capture_data` | `map_runtime` | — | — | `false` |
| `action.species.set_classification` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#species.set_classification` | `map_runtime` | — | — | `false` |
| `action.species.set_evolutions` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#species.set_evolutions` | `map_runtime` | — | — | `false` |
| `action.species.set_growth_data` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#species.set_growth_data` | `map_runtime` | — | — | `false` |
| `action.species.set_learnset` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#species.set_learnset` | `map_runtime` | — | — | `false` |
| `action.species.set_media` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#species.set_media` | `map_runtime` | — | — | `false` |
| `action.species.set_metadata` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#species.set_metadata` | `map_runtime` | — | — | `false` |
| `action.species.set_moves` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#species.set_moves` | `map_runtime` | — | — | `false` |
| `action.species.set_stats` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#species.set_stats` | `map_runtime` | — | — | `false` |
| `action.species.set_types` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#species.set_types` | `map_runtime` | — | — | `false` |
| `action.species.update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#species.update` | `map_runtime` | — | — | `false` |
| `action.species.validate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#species.validate` | `map_runtime` | — | — | `false` |
| `action.storyline.anchor_set` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.anchor_set` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.storyline.archive` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.archive` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.storyline.chapter_add` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.chapter_add` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.storyline.chapter_clone` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.chapter_clone` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.storyline.chapter_delete` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.chapter_delete` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.storyline.chapter_move` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.chapter_move` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.storyline.chapter_reorder` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.chapter_reorder` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.storyline.chapter_update` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.chapter_update` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.storyline.clone` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.clone` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.storyline.completion_preview` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.completion_preview` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.storyline.create` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.create` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.storyline.delete_apply` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.delete_apply` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.storyline.delete_plan` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.delete_plan` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.storyline.effect_add` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.effect_add` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.storyline.effect_remove` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.effect_remove` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.storyline.effect_update` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.effect_update` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.storyline.get` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.get` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.storyline.list` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.list` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.storyline.progression_connect` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.progression_connect` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.storyline.progression_disconnect` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.progression_disconnect` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.storyline.reachability` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.reachability` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.storyline.relationship_add` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.relationship_add` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.storyline.relationship_remove` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.relationship_remove` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.storyline.relationship_update` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.relationship_update` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.storyline.restore` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.restore` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.storyline.scene_link_add` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.scene_link_add` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.storyline.scene_link_remove` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.scene_link_remove` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.storyline.scene_link_update` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.scene_link_update` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.storyline.step_add` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.step_add` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.storyline.step_clone` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.step_clone` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.storyline.step_delete` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.step_delete` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.storyline.step_move` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.step_move` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.storyline.step_reorder` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.step_reorder` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.storyline.step_update` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.step_update` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.storyline.update` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.update` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.storyline.validate` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#storyline.validate` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.surface.clear` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#surface.clear` | `map_runtime` | — | — | `false` |
| `action.surface.ensure_layer` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#surface.ensure_layer` | `map_runtime` | — | — | `false` |
| `action.surface.erase` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#surface.erase` | `map_runtime` | — | — | `false` |
| `action.surface.erase_area` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#surface.erase_area` | `map_runtime` | — | — | `false` |
| `action.surface.generate_gameplay_zones_apply` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#surface.generate_gameplay_zones_apply` | `map_runtime` | — | — | `false` |
| `action.surface.generate_gameplay_zones_plan` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#surface.generate_gameplay_zones_plan` | `map_runtime` | — | — | `false` |
| `action.surface.inspect_usage` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#surface.inspect_usage` | `map_runtime` | — | — | `false` |
| `action.surface.paint` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#surface.paint` | `map_runtime` | — | — | `false` |
| `action.surface.render_preview` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#surface.render_preview` | `map_runtime` | — | — | `false` |
| `action.surface.replace_placements` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#surface.replace_placements` | `map_runtime` | — | — | `false` |
| `action.surface.validate` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#surface.validate` | `map_runtime` | — | — | `false` |
| `action.surface_catalog.clear_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#surface_catalog.clear_apply` | `map_runtime` | — | — | `false` |
| `action.surface_catalog.clear_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#surface_catalog.clear_plan` | `map_runtime` | — | — | `false` |
| `action.surface_catalog.diagnostics` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#surface_catalog.diagnostics` | `map_runtime` | — | — | `false` |
| `action.surface_catalog.inspect` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#surface_catalog.inspect` | `map_runtime` | — | — | `false` |
| `action.surface_catalog.replace_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#surface_catalog.replace_apply` | `map_runtime` | — | — | `false` |
| `action.surface_catalog.replace_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#surface_catalog.replace_plan` | `map_runtime` | — | — | `false` |
| `action.terrain.erase` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#terrain.erase` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.terrain.erase_pattern` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#terrain.erase_pattern` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.terrain.fill` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#terrain.fill` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.terrain.paint` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#terrain.paint` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.terrain.paint_pattern` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#terrain.paint_pattern` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.terrain.replace` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#terrain.replace` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.terrain_preset.variant_add` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#terrain_preset.variant_add` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.terrain_preset.variant_remove` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#terrain_preset.variant_remove` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.terrain_preset.variant_reorder` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#terrain_preset.variant_reorder` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.terrain_preset.variant_update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#terrain_preset.variant_update` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.terrain_preset.weight_normalize` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#terrain_preset.weight_normalize` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.tileset.assign_to_layer` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset.assign_to_layer` | `map_runtime` | — | — | `false` |
| `action.tileset.assign_to_map` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset.assign_to_map` | `map_runtime` | — | — | `false` |
| `action.tileset.build_atlas` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset.build_atlas` | `map_runtime` | — | — | `false` |
| `action.tileset.clone` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset.clone` | `map_runtime` | — | — | `false` |
| `action.tileset.delete_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset.delete_apply` | `map_runtime` | — | — | `false` |
| `action.tileset.delete_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset.delete_plan` | `map_runtime` | — | — | `false` |
| `action.tileset.find_usages` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset.find_usages` | `map_runtime` | — | — | `false` |
| `action.tileset.get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset.get` | `map_runtime` | — | — | `false` |
| `action.tileset.import_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset.import_apply` | `map_runtime` | — | — | `false` |
| `action.tileset.import_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset.import_plan` | `map_runtime` | — | — | `false` |
| `action.tileset.list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset.list` | `map_runtime` | — | — | `false` |
| `action.tileset.list_assignable` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset.list_assignable` | `map_runtime` | — | — | `false` |
| `action.tileset.normalize` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset.normalize` | `map_runtime` | — | — | `false` |
| `action.tileset.regrid_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset.regrid_apply` | `map_runtime` | — | — | `false` |
| `action.tileset.regrid_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset.regrid_plan` | `map_runtime` | — | — | `false` |
| `action.tileset.reorder` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset.reorder` | `map_runtime` | — | — | `false` |
| `action.tileset.replace_image_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset.replace_image_apply` | `map_runtime` | — | — | `false` |
| `action.tileset.replace_image_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset.replace_image_plan` | `map_runtime` | — | — | `false` |
| `action.tileset.set_transparent_color` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset.set_transparent_color` | `map_runtime` | — | — | `false` |
| `action.tileset.tile_property_get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset.tile_property_get` | `map_runtime` | — | — | `false` |
| `action.tileset.tile_property_remove` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset.tile_property_remove` | `map_runtime` | — | — | `false` |
| `action.tileset.tile_property_set` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset.tile_property_set` | `map_runtime` | — | — | `false` |
| `action.tileset.update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset.update` | `map_runtime` | — | — | `false` |
| `action.tileset.validate_bounds` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset.validate_bounds` | `map_runtime` | — | — | `false` |
| `action.tileset_element_group.create` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset_element_group.create` | `map_runtime` | — | — | `false` |
| `action.tileset_element_group.delete_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset_element_group.delete_apply` | `map_runtime` | — | — | `false` |
| `action.tileset_element_group.delete_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset_element_group.delete_plan` | `map_runtime` | — | — | `false` |
| `action.tileset_element_group.list_tree` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset_element_group.list_tree` | `map_runtime` | — | — | `false` |
| `action.tileset_element_group.move` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset_element_group.move` | `map_runtime` | — | — | `false` |
| `action.tileset_element_group.rename` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset_element_group.rename` | `map_runtime` | — | — | `false` |
| `action.tileset_element_group.reorder` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset_element_group.reorder` | `map_runtime` | — | — | `false` |
| `action.tileset_folder.assign_tileset` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset_folder.assign_tileset` | `map_runtime` | — | — | `false` |
| `action.tileset_folder.create` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset_folder.create` | `map_runtime` | — | — | `false` |
| `action.tileset_folder.delete` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset_folder.delete` | `map_runtime` | — | — | `false` |
| `action.tileset_folder.list_tree` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset_folder.list_tree` | `map_runtime` | — | — | `false` |
| `action.tileset_folder.move` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset_folder.move` | `map_runtime` | — | — | `false` |
| `action.tileset_folder.move_tileset_to_root` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset_folder.move_tileset_to_root` | `map_runtime` | — | — | `false` |
| `action.tileset_folder.rename` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#tileset_folder.rename` | `map_runtime` | — | — | `false` |
| `action.trainer.apply_template` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#trainer.apply_template` | `map_runtime` | — | `FG-140..FG-147` | `false` |
| `action.trainer.assign_to_npc` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#trainer.assign_to_npc` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.trainer.build_battle_setup` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#trainer.build_battle_setup` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.trainer.clone` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#trainer.clone` | `map_runtime` | — | `FG-140..FG-147` | `false` |
| `action.trainer.create` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#trainer.create` | `map_runtime` | — | `FG-140..FG-147` | `false` |
| `action.trainer.delete_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#trainer.delete_apply` | `map_runtime` | — | `FG-140..FG-147` | `false` |
| `action.trainer.delete_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#trainer.delete_plan` | `map_runtime` | — | `FG-140..FG-147` | `false` |
| `action.trainer.get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#trainer.get` | `map_runtime` | — | `FG-140..FG-147` | `false` |
| `action.trainer.list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#trainer.list` | `map_runtime` | — | `FG-140..FG-147` | `false` |
| `action.trainer.set_dialogues` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#trainer.set_dialogues` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.trainer.set_held_item` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#trainer.set_held_item` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.trainer.set_moves` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#trainer.set_moves` | `map_runtime` | — | `FG-140..FG-147` | `false` |
| `action.trainer.set_rematch_policy` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#trainer.set_rematch_policy` | `map_runtime` | — | `FG-140..FG-147` | `false` |
| `action.trainer.set_rewards` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#trainer.set_rewards` | `map_runtime` | — | `FG-140..FG-147` | `false` |
| `action.trainer.simulate_battle` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#trainer.simulate_battle` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `action.trainer.team_add` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#trainer.team_add` | `map_runtime` | — | `FG-140..FG-147` | `false` |
| `action.trainer.team_clone` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#trainer.team_clone` | `map_runtime` | — | `FG-140..FG-147` | `false` |
| `action.trainer.team_delete` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#trainer.team_delete` | `map_runtime` | — | `FG-140..FG-147` | `false` |
| `action.trainer.team_reorder` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#trainer.team_reorder` | `map_runtime` | — | `FG-140..FG-147` | `false` |
| `action.trainer.team_update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#trainer.team_update` | `map_runtime` | — | `FG-140..FG-147` | `false` |
| `action.trainer.update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#trainer.update` | `map_runtime` | — | `FG-140..FG-147` | `false` |
| `action.trainer.validate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#trainer.validate` | `map_runtime` | — | `FG-140..FG-147` | `false` |
| `action.transaction.abort` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#transaction.abort` | `map_runtime` | — | — | `false` |
| `action.transaction.begin` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#transaction.begin` | `map_runtime` | — | — | `false` |
| `action.transaction.commit` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#transaction.commit` | `map_runtime` | — | — | `false` |
| `action.transaction.preview` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#transaction.preview` | `map_runtime` | — | — | `false` |
| `action.transaction.recover` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#transaction.recover` | `map_runtime` | — | — | `false` |
| `action.transaction.stage` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#transaction.stage` | `map_runtime` | — | — | `false` |
| `action.transaction.status` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#transaction.status` | `map_runtime` | — | — | `false` |
| `action.transaction.validate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#transaction.validate` | `map_runtime` | — | — | `false` |
| `action.trigger.clone` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#trigger.clone` | `map_runtime` | — | — | `false` |
| `action.trigger.create` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#trigger.create` | `map_runtime` | — | — | `false` |
| `action.trigger.delete_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#trigger.delete_apply` | `map_runtime` | — | — | `false` |
| `action.trigger.delete_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#trigger.delete_plan` | `map_runtime` | — | — | `false` |
| `action.trigger.find_at` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#trigger.find_at` | `map_runtime` | — | — | `false` |
| `action.trigger.get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#trigger.get` | `map_runtime` | — | — | `false` |
| `action.trigger.list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#trigger.list` | `map_runtime` | — | — | `false` |
| `action.trigger.move` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#trigger.move` | `map_runtime` | — | — | `false` |
| `action.trigger.patch_properties` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#trigger.patch_properties` | `map_runtime` | — | — | `false` |
| `action.trigger.references` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#trigger.references` | `map_runtime` | — | — | `false` |
| `action.trigger.resize` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#trigger.resize` | `map_runtime` | — | — | `false` |
| `action.trigger.update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#trigger.update` | `map_runtime` | — | — | `false` |
| `action.trigger.validate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#trigger.validate` | `map_runtime` | — | — | `false` |
| `action.undo.apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#undo.apply` | `map_runtime` | — | — | `false` |
| `action.undo.plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#undo.plan` | `map_runtime` | — | — | `false` |
| `action.validate.accessibility` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#validate.accessibility` | `map_runtime` | — | — | `false` |
| `action.validate.affected` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#validate.affected` | `map_runtime` | — | — | `false` |
| `action.validate.assets` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#validate.assets` | `map_runtime` | — | — | `false` |
| `action.validate.collisions` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#validate.collisions` | `map_runtime` | — | — | `false` |
| `action.validate.encounters` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#validate.encounters` | `map_runtime` | — | `FG-100..FG-108` | `false` |
| `action.validate.export` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#validate.export` | `map_runtime` | — | — | `false` |
| `action.validate.identities` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#validate.identities` | `map_runtime` | — | — | `false` |
| `action.validate.layer_lengths` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#validate.layer_lengths` | `map_runtime` | — | — | `false` |
| `action.validate.localization` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#validate.localization` | `map_runtime` | — | — | `false` |
| `action.validate.map_bounds` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#validate.map_bounds` | `map_runtime` | — | — | `false` |
| `action.validate.narrative` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#validate.narrative` | `map_runtime` | — | — | `false` |
| `action.validate.new_game` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#validate.new_game` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.validate.package` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#validate.package` | `map_runtime` | — | — | `false` |
| `action.validate.performance_budget` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#validate.performance_budget` | `map_runtime` | — | — | `false` |
| `action.validate.playability` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#validate.playability` | `map_runtime` | — | — | `false` |
| `action.validate.pokemon_data` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#validate.pokemon_data` | `map_runtime` | — | — | `false` |
| `action.validate.presentation` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#validate.presentation` | `map_runtime` | — | — | `false` |
| `action.validate.project` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#validate.project` | `map_runtime` | — | — | `false` |
| `action.validate.references` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#validate.references` | `map_runtime` | — | — | `false` |
| `action.validate.resource` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#validate.resource` | `map_runtime` | — | — | `false` |
| `action.validate.runtime_consumption` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#validate.runtime_consumption` | `map_runtime` | — | — | `false` |
| `action.validate.save_compatibility` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#validate.save_compatibility` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `action.validate.schema` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#validate.schema` | `map_runtime` | — | — | `false` |
| `action.validate.security` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#validate.security` | `map_runtime` | — | — | `false` |
| `action.validate.selection` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#validate.selection` | `map_runtime` | — | — | `false` |
| `action.validate.story_reachability` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#validate.story_reachability` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.validate.trainers` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#validate.trainers` | `map_runtime` | — | `FG-140..FG-147` | `false` |
| `action.validate.walkability` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#validate.walkability` | `map_runtime` | — | — | `false` |
| `action.validate.warp_pairs` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#validate.warp_pairs` | `map_runtime` | — | — | `false` |
| `action.validate.world_graph` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#validate.world_graph` | `map_runtime` | — | — | `false` |
| `action.validation_code.describe` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#validation_code.describe` | `map_editor,map_runtime,mcp` | — | — | `false` |
| `action.validation_code.list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#validation_code.list` | `map_editor,map_runtime,mcp` | — | — | `false` |
| `action.video.captions_validate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#video.captions_validate` | `map_runtime` | — | — | `false` |
| `action.video.inspect` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#video.inspect` | `map_runtime` | — | — | `false` |
| `action.video.poster_generate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#video.poster_generate` | `map_runtime` | — | — | `false` |
| `action.video.transcode_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#video.transcode_apply` | `map_runtime` | — | — | `false` |
| `action.video.transcode_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#video.transcode_plan` | `map_runtime` | — | — | `false` |
| `action.video.validate` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#video.validate` | `map_runtime` | — | — | `false` |
| `action.warp.create` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#warp.create` | `map_runtime` | — | — | `false` |
| `action.warp.create_reciprocal_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#warp.create_reciprocal_apply` | `map_runtime` | — | — | `false` |
| `action.warp.create_reciprocal_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#warp.create_reciprocal_plan` | `map_runtime` | — | — | `false` |
| `action.warp.delete` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#warp.delete` | `map_runtime` | — | — | `false` |
| `action.warp.delete_pair_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#warp.delete_pair_apply` | `map_runtime` | — | — | `false` |
| `action.warp.delete_pair_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#warp.delete_pair_plan` | `map_runtime` | — | — | `false` |
| `action.warp.get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#warp.get` | `map_runtime` | — | — | `false` |
| `action.warp.list` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#warp.list` | `map_runtime` | — | — | `false` |
| `action.warp.update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#warp.update` | `map_runtime` | — | — | `false` |
| `action.warp.update_pair_apply` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#warp.update_pair_apply` | `map_runtime` | — | — | `false` |
| `action.warp.update_pair_plan` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#warp.update_pair_plan` | `map_runtime` | — | — | `false` |
| `action.warp.validate_pairs` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#warp.validate_pairs` | `map_runtime` | — | — | `false` |
| `action.warp.validate_target` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#warp.validate_target` | `map_runtime` | — | — | `false` |
| `action.workspace.close` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#workspace.close` | `map_runtime` | — | — | `false` |
| `action.workspace.inspect` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#workspace.inspect` | `map_runtime` | — | — | `false` |
| `action.workspace.list` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#workspace.list` | `map_runtime` | — | — | `false` |
| `action.workspace.open` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#workspace.open` | `map_runtime` | — | — | `false` |
| `action.workspace.recover` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#workspace.recover` | `map_runtime` | — | — | `false` |
| `action.workspace.recovery_status` | `catalog_action` | `map_editor` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#workspace.recovery_status` | `map_runtime` | — | — | `false` |
| `action.world.enterEncounter` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#world.enterEncounter` | `map_runtime` | — | `FG-100..FG-108` | `false` |
| `action.world.enterTrigger` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#world.enterTrigger` | `map_runtime` | — | — | `false` |
| `action.world.enterWarp` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#world.enterWarp` | `map_runtime` | — | — | `false` |
| `action.world.inspect` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#world.inspect` | `map_runtime` | — | — | `false` |
| `action.world.interact` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#world.interact` | `map_runtime` | — | — | `false` |
| `action.world.wait` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#world.wait` | `map_runtime` | — | — | `false` |
| `action.world.waitForFact` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#world.waitForFact` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.world_graph.find_path` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#world_graph.find_path` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `action.world_graph.inspect` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#world_graph.inspect` | `map_runtime` | — | — | `false` |
| `action.world_graph.list_connected` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#world_graph.list_connected` | `map_runtime` | — | — | `false` |
| `action.world_graph.list_disconnected` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#world_graph.list_disconnected` | `map_runtime` | — | — | `false` |
| `action.world_graph.render` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#world_graph.render` | `map_runtime` | — | — | `false` |
| `action.world_graph.validate_consistency` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#world_graph.validate_consistency` | `map_runtime` | — | — | `false` |
| `action.world_rule.clone` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#world_rule.clone` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.world_rule.create` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#world_rule.create` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.world_rule.delete_apply` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#world_rule.delete_apply` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.world_rule.delete_plan` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#world_rule.delete_plan` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.world_rule.disable` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#world_rule.disable` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.world_rule.enable` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#world_rule.enable` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.world_rule.get` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#world_rule.get` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.world_rule.list` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#world_rule.list` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.world_rule.reorder` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#world_rule.reorder` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.world_rule.simulate` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#world_rule.simulate` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.world_rule.update` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#world_rule.update` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.world_rule.validate` | `catalog_action` | `map_core` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#world_rule.validate` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `action.yarn.choice_add` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#yarn.choice_add` | `map_runtime` | — | — | `false` |
| `action.yarn.choice_delete` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#yarn.choice_delete` | `map_runtime` | — | — | `false` |
| `action.yarn.choice_update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#yarn.choice_update` | `map_runtime` | — | — | `false` |
| `action.yarn.command_add` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#yarn.command_add` | `map_runtime` | — | — | `false` |
| `action.yarn.command_delete` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#yarn.command_delete` | `map_runtime` | — | — | `false` |
| `action.yarn.command_update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#yarn.command_update` | `map_runtime` | — | — | `false` |
| `action.yarn.condition_set` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#yarn.condition_set` | `map_runtime` | — | — | `false` |
| `action.yarn.jump_set` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#yarn.jump_set` | `map_runtime` | — | — | `false` |
| `action.yarn.line_add` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#yarn.line_add` | `map_runtime` | — | — | `false` |
| `action.yarn.line_delete` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#yarn.line_delete` | `map_runtime` | — | — | `false` |
| `action.yarn.line_update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#yarn.line_update` | `map_runtime` | — | — | `false` |
| `action.yarn.localization_get` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#yarn.localization_get` | `map_runtime` | — | — | `false` |
| `action.yarn.localization_update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#yarn.localization_update` | `map_runtime` | — | — | `false` |
| `action.yarn.node_clone` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#yarn.node_clone` | `map_runtime` | — | — | `false` |
| `action.yarn.node_create` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#yarn.node_create` | `map_runtime` | — | — | `false` |
| `action.yarn.node_delete` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#yarn.node_delete` | `map_runtime` | — | — | `false` |
| `action.yarn.node_update` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#yarn.node_update` | `map_runtime` | — | — | `false` |
| `action.yarn.outcome_set` | `catalog_action` | `map_authoring` | `MISSING` | `pokemap_authoring_api_mcp_action_catalog.md#yarn.outcome_set` | `map_runtime` | — | — | `false` |
| `core.operation.cinematic_authoring_operations` | `core_operation` | `map_core` | `SUPPORTED` | `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart` | `map_editor,map_runtime` | `packages/map_core/test/cinematic_authoring_operations_test.dart` | — | `false` |
| `core.operation.cinematic_command_authoring_operations` | `core_operation` | `map_core` | `MISSING` | `packages/map_core/lib/src/authoring/cinematic_command_authoring_operations.dart` | `map_editor,map_runtime` | — | — | `false` |
| `core.operation.cinematic_timeline_editing_operations` | `core_operation` | `map_core` | `SUPPORTED` | `packages/map_core/lib/src/authoring/cinematic_timeline_editing_operations.dart` | `map_editor,map_runtime` | `packages/map_core/test/cinematic_timeline_editing_operations_test.dart` | — | `false` |
| `core.operation.event_builder_authoring_operations` | `core_operation` | `map_core` | `SUPPORTED` | `packages/map_core/lib/src/authoring/event_builder_authoring_operations.dart` | `map_editor,map_runtime` | `packages/map_core/test/event_builder_authoring_operations_test.dart` | `FG-080..FG-094` | `false` |
| `core.operation.event_builder_contract` | `core_operation` | `map_core` | `SUPPORTED` | `packages/map_core/lib/src/authoring/event_builder_contract.dart` | `map_editor,map_runtime` | `packages/map_core/test/event_builder_contract_test.dart` | `FG-080..FG-094` | `false` |
| `core.operation.event_builder_draft_creation_operations` | `core_operation` | `map_core` | `SUPPORTED` | `packages/map_core/lib/src/authoring/event_builder_draft_creation_operations.dart` | `map_editor,map_runtime` | `packages/map_core/test/event_builder_draft_creation_operations_test.dart` | `FG-080..FG-094` | `false` |
| `core.operation.narrative_asset_clone_plan` | `core_operation` | `map_core` | `SUPPORTED` | `packages/map_core/lib/src/authoring/narrative_asset_clone_plan.dart` | `map_editor,map_runtime` | `packages/map_core/test/narrative_asset_clone_plan_test.dart` | — | `false` |
| `core.operation.narrative_asset_mutation` | `core_operation` | `map_core` | `SUPPORTED` | `packages/map_core/lib/src/authoring/narrative_asset_mutation.dart` | `map_editor,map_runtime` | `packages/map_core/test/narrative_asset_mutation_test.dart` | — | `false` |
| `core.operation.narrative_event_activation_operations` | `core_operation` | `map_core` | `MISSING` | `packages/map_core/lib/src/authoring/narrative_event_activation_operations.dart` | `map_editor,map_runtime` | — | `FG-080..FG-094` | `false` |
| `core.operation.narrative_event_authoring_contract` | `core_operation` | `map_core` | `MISSING` | `packages/map_core/lib/src/authoring/narrative_event_authoring_contract.dart` | `map_editor,map_runtime` | — | `FG-080..FG-094` | `false` |
| `core.operation.narrative_event_authoring_support` | `core_operation` | `map_core` | `MISSING` | `packages/map_core/lib/src/authoring/narrative_event_authoring_support.dart` | `map_editor,map_runtime` | — | `FG-080..FG-094` | `false` |
| `core.operation.narrative_event_authoring_verification` | `core_operation` | `map_core` | `SUPPORTED` | `packages/map_core/lib/src/authoring/narrative_event_authoring_verification.dart` | `map_editor,map_runtime` | `packages/map_core/test/narrative_event_authoring_verification_test.dart` | `FG-080..FG-094` | `false` |
| `core.operation.narrative_event_configuration_operations` | `core_operation` | `map_core` | `MISSING` | `packages/map_core/lib/src/authoring/narrative_event_configuration_operations.dart` | `map_editor,map_runtime` | — | `FG-080..FG-094` | `false` |
| `core.operation.narrative_event_configuration_validation` | `core_operation` | `map_core` | `MISSING` | `packages/map_core/lib/src/authoring/narrative_event_configuration_validation.dart` | `map_editor,map_runtime` | — | `FG-080..FG-094` | `false` |
| `core.operation.narrative_event_draft_operations` | `core_operation` | `map_core` | `MISSING` | `packages/map_core/lib/src/authoring/narrative_event_draft_operations.dart` | `map_editor,map_runtime` | — | `FG-080..FG-094` | `false` |
| `core.operation.narrative_event_publication_operations` | `core_operation` | `map_core` | `MISSING` | `packages/map_core/lib/src/authoring/narrative_event_publication_operations.dart` | `map_editor,map_runtime` | — | `FG-080..FG-094` | `false` |
| `core.operation.narrative_event_source_authoring_operations` | `core_operation` | `map_core` | `SUPPORTED` | `packages/map_core/lib/src/authoring/narrative_event_source_authoring_operations.dart` | `map_editor,map_runtime` | `packages/map_core/test/narrative_event_source_authoring_operations_test.dart` | `FG-080..FG-094` | `false` |
| `core.operation.narrative_event_source_operations_v2` | `core_operation` | `map_core` | `MISSING` | `packages/map_core/lib/src/authoring/narrative_event_source_operations_v2.dart` | `map_editor,map_runtime` | — | `FG-080..FG-094` | `false` |
| `core.operation.narrative_fact_authoring_operations` | `core_operation` | `map_core` | `SUPPORTED` | `packages/map_core/lib/src/authoring/narrative_fact_authoring_operations.dart` | `map_editor,map_runtime` | `packages/map_core/test/narrative_fact_authoring_operations_test.dart` | `FG-080..FG-094` | `false` |
| `core.operation.narrative_outcome_authoring_operations` | `core_operation` | `map_core` | `SUPPORTED` | `packages/map_core/lib/src/authoring/narrative_outcome_authoring_operations.dart` | `map_editor,map_runtime` | `packages/map_core/test/narrative_outcome_authoring_operations_test.dart` | — | `false` |
| `core.operation.narrative_predicate_authoring_draft` | `core_operation` | `map_core` | `SUPPORTED` | `packages/map_core/lib/src/authoring/narrative_predicate_authoring_draft.dart` | `map_editor,map_runtime` | `packages/map_core/test/narrative_predicate_authoring_draft_test.dart` | — | `false` |
| `core.operation.narrative_reference_rewrite` | `core_operation` | `map_core` | `MISSING` | `packages/map_core/lib/src/authoring/narrative_reference_rewrite.dart` | `map_editor,map_runtime` | — | — | `false` |
| `core.operation.narrative_scenario_authoring_draft` | `core_operation` | `map_core` | `SUPPORTED` | `packages/map_core/lib/src/authoring/narrative_scenario_authoring_draft.dart` | `map_editor,map_runtime` | `packages/map_core/test/narrative_scenario_authoring_draft_test.dart` | — | `false` |
| `core.operation.narrative_validator_authoring_adapter` | `core_operation` | `map_core` | `SUPPORTED` | `packages/map_core/lib/src/authoring/narrative_validator_authoring_adapter.dart` | `map_editor,map_runtime` | `packages/map_core/test/narrative_validator_authoring_adapter_test.dart` | — | `false` |
| `core.operation.scene_authoring_operations` | `core_operation` | `map_core` | `SUPPORTED` | `packages/map_core/lib/src/authoring/scene_authoring_operations.dart` | `map_editor,map_runtime` | `packages/map_core/test/scene_authoring_operations_test.dart` | `FG-080..FG-094` | `false` |
| `core.operation.storyline_authoring_operations` | `core_operation` | `map_core` | `SUPPORTED` | `packages/map_core/lib/src/authoring/storyline_authoring_operations.dart` | `map_editor,map_runtime` | `packages/map_core/test/storyline_authoring_operations_test.dart` | `FG-080..FG-094` | `false` |
| `core.operation.storyline_legacy_import_preview` | `core_operation` | `map_core` | `SUPPORTED` | `packages/map_core/lib/src/authoring/storyline_legacy_import_preview.dart` | `map_editor,map_runtime` | `packages/map_core/test/storyline_legacy_import_preview_test.dart` | `FG-080..FG-094` | `false` |
| `core.operation.storyline_progression_operations` | `core_operation` | `map_core` | `SUPPORTED` | `packages/map_core/lib/src/authoring/storyline_progression_operations.dart` | `map_editor,map_runtime` | `packages/map_core/test/storyline_progression_operations_test.dart` | `FG-040..FG-073` | `false` |
| `core.operation.world_rule_authoring_operations` | `core_operation` | `map_core` | `SUPPORTED` | `packages/map_core/lib/src/authoring/world_rule_authoring_operations.dart` | `map_editor,map_runtime` | `packages/map_core/test/world_rule_authoring_operations_test.dart` | `FG-080..FG-094` | `false` |
| `editor.use_case.AddEncounterEntryUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/encounter_table_use_cases.dart#AddEncounterEntryUseCase` | `map_runtime` | — | `FG-100..FG-108` | `false` |
| `editor.use_case.AddEntityToMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/entity_use_cases.dart#AddEntityToMapUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.AddEnvironmentAreaUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart#AddEnvironmentAreaUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.AddGameplayZoneToMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/gameplay_zone_use_cases.dart#AddGameplayZoneToMapUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.AddMapLayerUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart#AddMapLayerUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.AddTileLayerEnvironmentGeneratedPlacementAtUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_generated_placement_edit_use_cases.dart#AddTileLayerEnvironmentGeneratedPlacementAtUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.AddTrainerPokemonUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/trainer_use_cases.dart#AddTrainerPokemonUseCase` | `map_runtime` | — | `FG-140..FG-147` | `false` |
| `editor.use_case.AddTriggerToMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/trigger_use_cases.dart#AddTriggerToMapUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.AddWarpToMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/warp_use_cases.dart#AddWarpToMapUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.ApplyElementAutoShadowSuggestionsUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/apply_element_auto_shadow_suggestions_use_case.dart#ApplyElementAutoShadowSuggestionsUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.ApplyEnvironmentGeneratedPlacementsUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/environment_generator_apply_use_cases.dart#ApplyEnvironmentGeneratedPlacementsUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.AssignDialogueToLibraryFolderUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_dialogue_library_use_cases.dart#AssignDialogueToLibraryFolderUseCase` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `editor.use_case.AssignPathPresetToLayerUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/path_layer_use_cases.dart#AssignPathPresetToLayerUseCase` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `editor.use_case.AssignTilesetToLibraryFolderUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_tileset_library_use_cases.dart#AssignTilesetToLibraryFolderUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.AssignTilesetToMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_tileset_use_cases.dart#AssignTilesetToMapUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.BatchImportExternalPokemonSpeciesUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart#BatchImportExternalPokemonSpeciesUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.ClearEnvironmentGeneratedPlacementsUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/environment_generator_clear_use_cases.dart#ClearEnvironmentGeneratedPlacementsUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.ClearTileLayerEnvironmentAreaGeneratedPlacementsUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_clear_use_cases.dart#ClearTileLayerEnvironmentAreaGeneratedPlacementsUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.CreateCharacterUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/character_use_cases.dart#CreateCharacterUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.CreateDialogueLibraryFolderUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_dialogue_library_use_cases.dart#CreateDialogueLibraryFolderUseCase` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `editor.use_case.CreateElementCategoryUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_element_use_cases.dart#CreateElementCategoryUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.CreateElementSubcategoryUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_element_use_cases.dart#CreateElementSubcategoryUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.CreateEncounterTableUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/encounter_table_use_cases.dart#CreateEncounterTableUseCase` | `map_runtime` | — | `FG-100..FG-108` | `false` |
| `editor.use_case.CreateGroupUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_group_use_cases.dart#CreateGroupUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.CreateMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/map_use_cases.dart#CreateMapUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.CreateNarrativeEventFromMapSourceUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/create_narrative_event_from_map_source_use_case.dart#CreateNarrativeEventFromMapSourceUseCase` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `editor.use_case.CreatePathPresetUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/terrain_preset_use_cases.dart#CreatePathPresetUseCase` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `editor.use_case.CreatePresetCategoryUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/terrain_preset_use_cases.dart#CreatePresetCategoryUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.CreateProjectDialogueUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_dialogue_use_cases.dart#CreateProjectDialogueUseCase` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `editor.use_case.CreateProjectElementUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_element_use_cases.dart#CreateProjectElementUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.CreateProjectScenarioUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart#CreateProjectScenarioUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.CreateProjectUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_management_use_cases.dart#CreateProjectUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.CreateReciprocalWarpUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/warp_use_cases.dart#CreateReciprocalWarpUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.CreateTerrainPresetUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/terrain_preset_use_cases.dart#CreateTerrainPresetUseCase` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `editor.use_case.CreateTileLayerEnvironmentAreaUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_attachment_use_cases.dart#CreateTileLayerEnvironmentAreaUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.CreateTilesetElementGroupUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_element_use_cases.dart#CreateTilesetElementGroupUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.CreateTilesetElementSubgroupUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_element_use_cases.dart#CreateTilesetElementSubgroupUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.CreateTilesetLibraryFolderUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_tileset_library_use_cases.dart#CreateTilesetLibraryFolderUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.CreateTilesetPaletteEntryUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_tileset_use_cases.dart#CreateTilesetPaletteEntryUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.CreateTrainerUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/trainer_use_cases.dart#CreateTrainerUseCase` | `map_runtime` | — | `FG-140..FG-147` | `false` |
| `editor.use_case.DeleteAllMapLayersUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart#DeleteAllMapLayersUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.DeleteCharacterUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/character_use_cases.dart#DeleteCharacterUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.DeleteDialogueLibraryFolderUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_dialogue_library_use_cases.dart#DeleteDialogueLibraryFolderUseCase` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `editor.use_case.DeleteEncounterEntryUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/encounter_table_use_cases.dart#DeleteEncounterEntryUseCase` | `map_runtime` | — | `FG-100..FG-108` | `false` |
| `editor.use_case.DeleteEncounterTableUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/encounter_table_use_cases.dart#DeleteEncounterTableUseCase` | `map_runtime` | — | `FG-100..FG-108` | `false` |
| `editor.use_case.DeleteEntityFromMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/entity_use_cases.dart#DeleteEntityFromMapUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.DeleteGameplayZoneFromMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/gameplay_zone_use_cases.dart#DeleteGameplayZoneFromMapUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.DeleteGroupUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_group_use_cases.dart#DeleteGroupUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.DeleteMapConnectionUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/map_connection_use_cases.dart#DeleteMapConnectionUseCase` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `editor.use_case.DeleteMapLayerUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart#DeleteMapLayerUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.DeleteMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/map_use_cases.dart#DeleteMapUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.DeletePathPresetUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/terrain_preset_use_cases.dart#DeletePathPresetUseCase` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `editor.use_case.DeletePokedexSpeciesUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/delete_pokedex_species_use_case.dart#DeletePokedexSpeciesUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.DeletePresetCategoryUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/terrain_preset_use_cases.dart#DeletePresetCategoryUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.DeleteProjectDialogueUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_dialogue_use_cases.dart#DeleteProjectDialogueUseCase` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `editor.use_case.DeleteProjectElementUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_element_use_cases.dart#DeleteProjectElementUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.DeleteProjectScenarioUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart#DeleteProjectScenarioUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.DeleteProjectTilesetUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_tileset_use_cases.dart#DeleteProjectTilesetUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.DeleteTerrainPresetUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/terrain_preset_use_cases.dart#DeleteTerrainPresetUseCase` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `editor.use_case.DeleteTileLayerEnvironmentAreaUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_area_management_use_cases.dart#DeleteTileLayerEnvironmentAreaUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.DeleteTileLayerEnvironmentGeneratedPlacementAtUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_generated_placement_edit_use_cases.dart#DeleteTileLayerEnvironmentGeneratedPlacementAtUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.DeleteTilesetLibraryFolderUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_tileset_library_use_cases.dart#DeleteTilesetLibraryFolderUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.DeleteTrainerPokemonUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/trainer_use_cases.dart#DeleteTrainerPokemonUseCase` | `map_runtime` | — | `FG-140..FG-147` | `false` |
| `editor.use_case.DeleteTrainerUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/trainer_use_cases.dart#DeleteTrainerUseCase` | `map_runtime` | — | `FG-140..FG-147` | `false` |
| `editor.use_case.DeleteTriggerFromMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/trigger_use_cases.dart#DeleteTriggerFromMapUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.DeleteWarpFromMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/warp_use_cases.dart#DeleteWarpFromMapUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.DuplicateMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/map_use_cases.dart#DuplicateMapUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.EnableTileLayerEnvironmentAttachmentUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_attachment_use_cases.dart#EnableTileLayerEnvironmentAttachmentUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.EraseCollisionOnMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/collision_use_cases.dart#EraseCollisionOnMapUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.EraseCollisionPatternOnMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/collision_use_cases.dart#EraseCollisionPatternOnMapUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.ErasePathOnMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/path_layer_use_cases.dart#ErasePathOnMapUseCase` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `editor.use_case.ErasePathPatternOnMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/path_layer_use_cases.dart#ErasePathPatternOnMapUseCase` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `editor.use_case.EraseTerrainOnMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/terrain_use_cases.dart#EraseTerrainOnMapUseCase` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `editor.use_case.EraseTerrainPatternOnMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/terrain_use_cases.dart#EraseTerrainPatternOnMapUseCase` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `editor.use_case.EraseTileOnMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/paint_use_cases.dart#EraseTileOnMapUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.EraseTilePatternOnMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/paint_use_cases.dart#EraseTilePatternOnMapUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.GenerateEnvironmentAreaPlacementsUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/environment_generator_use_cases.dart#GenerateEnvironmentAreaPlacementsUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.GenerateTileLayerEnvironmentAreaPlacementsUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_generation_use_cases.dart#GenerateTileLayerEnvironmentAreaPlacementsUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.ImportExternalPokemonSpeciesUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart#ImportExternalPokemonSpeciesUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.ImportPokemonCatalogJsonUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/import_pokemon_catalog_json_use_case.dart#ImportPokemonCatalogJsonUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.ImportPokemonEvolutionJsonUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/import_pokemon_evolution_json_use_case.dart#ImportPokemonEvolutionJsonUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.ImportPokemonJsonBundleUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/import_pokemon_json_bundle_use_case.dart#ImportPokemonJsonBundleUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.ImportPokemonLearnsetJsonUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/import_pokemon_learnset_json_use_case.dart#ImportPokemonLearnsetJsonUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.ImportPokemonMediaJsonUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/import_pokemon_media_json_use_case.dart#ImportPokemonMediaJsonUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.ImportPokemonSpeciesJsonUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/import_pokemon_species_json_use_case.dart#ImportPokemonSpeciesJsonUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.ImportProjectDialogueUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_dialogue_use_cases.dart#ImportProjectDialogueUseCase` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `editor.use_case.ImportProjectTilesetUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_tileset_use_cases.dart#ImportProjectTilesetUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.InitializePokemonProjectStorageUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart#InitializePokemonProjectStorageUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.InspectNarrativeEventRegistryRecoveryUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/narrative_event_registry_persistence_use_cases.dart#InspectNarrativeEventRegistryRecoveryUseCase` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `editor.use_case.ListPokedexEntriesUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/list_pokedex_entries_use_case.dart#ListPokedexEntriesUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.LoadMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/map_use_cases.dart#LoadMapUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.LoadPokedexSpeciesDetailUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/load_pokedex_species_detail_use_case.dart#LoadPokedexSpeciesDetailUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.LoadPokemonItemsCatalogUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/load_pokemon_items_catalog_use_case.dart#LoadPokemonItemsCatalogUseCase` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `editor.use_case.LoadPokemonMovesCatalogUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart#LoadPokemonMovesCatalogUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.LoadProjectUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_management_use_cases.dart#LoadProjectUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.MapVisualStackMigrationUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/map_visual_stack_migration_use_case.dart#MapVisualStackMigrationUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.MoveDialogueLibraryFolderUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_dialogue_library_use_cases.dart#MoveDialogueLibraryFolderUseCase` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `editor.use_case.MoveDialogueToLibraryRootUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_dialogue_library_use_cases.dart#MoveDialogueToLibraryRootUseCase` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `editor.use_case.MoveMapLayerUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart#MoveMapLayerUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.MoveMapToGroupUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_group_use_cases.dart#MoveMapToGroupUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.MoveTilesetLibraryFolderUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_tileset_library_use_cases.dart#MoveTilesetLibraryFolderUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.MoveTilesetToLibraryRootUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_tileset_library_use_cases.dart#MoveTilesetToLibraryRootUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.NarrativeEventBuilderV2UseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/narrative_event_builder_v2_use_case.dart#NarrativeEventBuilderV2UseCase` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `editor.use_case.NarrativeEventExplicitSourceCreationUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/narrative_event_explicit_source_creation_use_case.dart#NarrativeEventExplicitSourceCreationUseCase` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `editor.use_case.NarrativeEventMigrationPreviewUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/narrative_event_migration_preview_use_case.dart#NarrativeEventMigrationPreviewUseCase` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `editor.use_case.NarrativeEventSpatialSourceLinkUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/narrative_event_spatial_source_link_use_case.dart#NarrativeEventSpatialSourceLinkUseCase` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `editor.use_case.NarrativeEventV2ModeActivationUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/narrative_event_v2_mode_activation_use_case.dart#NarrativeEventV2ModeActivationUseCase` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `editor.use_case.PaintCollisionOnMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/collision_use_cases.dart#PaintCollisionOnMapUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.PaintCollisionPatternOnMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/collision_use_cases.dart#PaintCollisionPatternOnMapUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.PaintEnvironmentAreaMaskBrushStrokeUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/environment_mask_use_cases.dart#PaintEnvironmentAreaMaskBrushStrokeUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.PaintEnvironmentAreaMaskCellUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/environment_mask_use_cases.dart#PaintEnvironmentAreaMaskCellUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.PaintPathOnMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/path_layer_use_cases.dart#PaintPathOnMapUseCase` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `editor.use_case.PaintPathPatternOnMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/path_layer_use_cases.dart#PaintPathPatternOnMapUseCase` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `editor.use_case.PaintTerrainOnMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/terrain_use_cases.dart#PaintTerrainOnMapUseCase` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `editor.use_case.PaintTerrainPatternOnMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/terrain_use_cases.dart#PaintTerrainPatternOnMapUseCase` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `editor.use_case.PaintTileOnMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/paint_use_cases.dart#PaintTileOnMapUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.PaintTilePatternOnMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/paint_use_cases.dart#PaintTilePatternOnMapUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.PersistNarrativeEventRegistryUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/narrative_event_registry_persistence_use_cases.dart#PersistNarrativeEventRegistryUseCase` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `editor.use_case.PrepareNarrativeEventAuthoringSessionUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/narrative_event_registry_persistence_use_cases.dart#PrepareNarrativeEventAuthoringSessionUseCase` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `editor.use_case.RecoverNarrativeEventRegistryWritesUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/narrative_event_registry_persistence_use_cases.dart#RecoverNarrativeEventRegistryWritesUseCase` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `editor.use_case.RegenerateTileLayerEnvironmentAreaPlacementsUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_regenerate_use_cases.dart#RegenerateTileLayerEnvironmentAreaPlacementsUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.RemoveEnvironmentAreaUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart#RemoveEnvironmentAreaUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.RenameDialogueLibraryFolderUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_dialogue_library_use_cases.dart#RenameDialogueLibraryFolderUseCase` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `editor.use_case.RenameElementCategoryUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_element_use_cases.dart#RenameElementCategoryUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.RenameGroupUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_group_use_cases.dart#RenameGroupUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.RenameMapLayerUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart#RenameMapLayerUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.RenameMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/map_use_cases.dart#RenameMapUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.RenamePresetCategoryUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/terrain_preset_use_cases.dart#RenamePresetCategoryUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.RenameTileLayerEnvironmentAreaUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_area_management_use_cases.dart#RenameTileLayerEnvironmentAreaUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.RenameTilesetElementGroupUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_element_use_cases.dart#RenameTilesetElementGroupUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.RenameTilesetLibraryFolderUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_tileset_library_use_cases.dart#RenameTilesetLibraryFolderUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.ReorderMapLayersUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart#ReorderMapLayersUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.ReorderProjectTilesetUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_tileset_use_cases.dart#ReorderProjectTilesetUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.ResetTileLayerEnvironmentAreaParamsOverrideUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_area_settings_use_cases.dart#ResetTileLayerEnvironmentAreaParamsOverrideUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.ResizeMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/map_use_cases.dart#ResizeMapUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.ResolveAssignableTilesetsForMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_tileset_use_cases.dart#ResolveAssignableTilesetsForMapUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.ResolveExternalPokemonBatchSelectionUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/resolve_external_pokemon_batch_selection_use_case.dart#ResolveExternalPokemonBatchSelectionUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.ResolveMapConnectionTargetUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/map_connection_use_cases.dart#ResolveMapConnectionTargetUseCase` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `editor.use_case.ResolveTilesetElementsUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_element_use_cases.dart#ResolveTilesetElementsUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.ResolveVisibleProjectElementsUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_element_use_cases.dart#ResolveVisibleProjectElementsUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.SaveDialogueYarnBodyUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_dialogue_use_cases.dart#SaveDialogueYarnBodyUseCase` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `editor.use_case.SaveMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/map_use_cases.dart#SaveMapUseCase` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `editor.use_case.SearchExternalPokemonSpeciesUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/search_external_pokemon_species_use_case.dart#SearchExternalPokemonSpeciesUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.SeedPokemonDemoDataUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart#SeedPokemonDemoDataUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.SetEnvironmentAreaPresetUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart#SetEnvironmentAreaPresetUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.SetEnvironmentAreaSeedUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/environment_generator_regenerate_use_cases.dart#SetEnvironmentAreaSeedUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.SetEnvironmentLayerTargetTileLayerUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart#SetEnvironmentLayerTargetTileLayerUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.SetMapLayerOpacityUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart#SetMapLayerOpacityUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.SetMapLayerVisibilityUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart#SetMapLayerVisibilityUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.SetPathLayerPropertiesUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/path_layer_use_cases.dart#SetPathLayerPropertiesUseCase` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `editor.use_case.SetPlayerCharacterUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/character_use_cases.dart#SetPlayerCharacterUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.SetTileLayerEnvironmentAreaParamsOverrideUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_area_settings_use_cases.dart#SetTileLayerEnvironmentAreaParamsOverrideUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.SetTileLayerEnvironmentAreaSeedForTileLayerUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_area_settings_use_cases.dart#SetTileLayerEnvironmentAreaSeedForTileLayerUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.ShuffleTileLayerEnvironmentAreaPlacementsUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_regenerate_use_cases.dart#ShuffleTileLayerEnvironmentAreaPlacementsUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.SyncExternalPokemonItemsCatalogUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/sync_pokemon_items_catalog_use_case.dart#SyncExternalPokemonItemsCatalogUseCase` | `map_runtime` | — | `FG-040..FG-073` | `false` |
| `editor.use_case.SyncExternalPokemonMovesCatalogUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart#SyncExternalPokemonMovesCatalogUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.SyncPokemonSdkMovesCatalogUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart#SyncPokemonSdkMovesCatalogUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.UndoNarrativeEventRegistryWriteUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/narrative_event_registry_persistence_use_cases.dart#UndoNarrativeEventRegistryWriteUseCase` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `editor.use_case.UpdateCharacterUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/character_use_cases.dart#UpdateCharacterUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.UpdateEncounterEntryUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/encounter_table_use_cases.dart#UpdateEncounterEntryUseCase` | `map_runtime` | — | `FG-100..FG-108` | `false` |
| `editor.use_case.UpdateEncounterTableUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/encounter_table_use_cases.dart#UpdateEncounterTableUseCase` | `map_runtime` | — | `FG-100..FG-108` | `false` |
| `editor.use_case.UpdateEntityOnMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/entity_use_cases.dart#UpdateEntityOnMapUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.UpdateGameplayZoneOnMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/gameplay_zone_use_cases.dart#UpdateGameplayZoneOnMapUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.UpdateMapMetadataUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/map_use_cases.dart#UpdateMapMetadataUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.UpdatePathPresetUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/terrain_preset_use_cases.dart#UpdatePathPresetUseCase` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `editor.use_case.UpdatePokedexSpeciesEvolutionUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/update_pokedex_species_evolution_use_case.dart#UpdatePokedexSpeciesEvolutionUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.UpdatePokedexSpeciesFormsClassificationUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/update_pokedex_species_forms_classification_use_case.dart#UpdatePokedexSpeciesFormsClassificationUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.UpdatePokedexSpeciesLearnsetUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/update_pokedex_species_learnset_use_case.dart#UpdatePokedexSpeciesLearnsetUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.UpdatePokedexSpeciesMediaUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/update_pokedex_species_media_use_case.dart#UpdatePokedexSpeciesMediaUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.UpdatePokedexSpeciesMetadataUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/update_pokedex_species_metadata_use_case.dart#UpdatePokedexSpeciesMetadataUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.UpdateProjectDialogueUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_dialogue_use_cases.dart#UpdateProjectDialogueUseCase` | `map_runtime` | — | `FG-080..FG-094` | `false` |
| `editor.use_case.UpdateProjectElementUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_element_use_cases.dart#UpdateProjectElementUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.UpdateProjectScenarioUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart#UpdateProjectScenarioUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.UpdateProjectSettingsUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_management_use_cases.dart#UpdateProjectSettingsUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.UpdateProjectTilesetUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_tileset_use_cases.dart#UpdateProjectTilesetUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.UpdateTerrainPresetUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/terrain_preset_use_cases.dart#UpdateTerrainPresetUseCase` | `map_runtime` | — | `FG-120..FG-129` | `false` |
| `editor.use_case.UpdateTrainerPokemonUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/trainer_use_cases.dart#UpdateTrainerPokemonUseCase` | `map_runtime` | — | `FG-140..FG-147` | `false` |
| `editor.use_case.UpdateTrainerUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/trainer_use_cases.dart#UpdateTrainerUseCase` | `map_runtime` | — | `FG-140..FG-147` | `false` |
| `editor.use_case.UpdateTriggerOnMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/trigger_use_cases.dart#UpdateTriggerOnMapUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.UpdateWarpOnMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/warp_use_cases.dart#UpdateWarpOnMapUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.UpsertCharacterAnimationUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/character_use_cases.dart#UpsertCharacterAnimationUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.UpsertMapConnectionUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/map_connection_use_cases.dart#UpsertMapConnectionUseCase` | `map_runtime` | — | `FG-010..FG-030` | `false` |
| `editor.use_case.UpsertTilesetPaletteEntryUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/project_tileset_use_cases.dart#UpsertTilesetPaletteEntryUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.ValidatePokemonProjectDataUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/validate_pokemon_project_data_use_case.dart#ValidatePokemonProjectDataUseCase` | `map_runtime` | — | — | `false` |
| `editor.use_case.ValidateWarpTargetMapUseCase` | `editor_use_case` | `map_editor` | `MISSING` | `packages/map_editor/lib/src/application/use_cases/warp_use_cases.dart#ValidateWarpTargetMapUseCase` | `map_runtime` | — | — | `false` |
| `eval.command.battle.capture` | `evaluation_command` | `playable_runtime_host` | `SUPPORTED` | `examples/playable_runtime_host/lib/src/evaluation/scenario/evaluation_command_catalog.dart#battle.capture` | `map_runtime` | `examples/playable_runtime_host/test/evaluation/evaluation_scenario_runner_test.dart` | `FG-040..FG-073` | `false` |
| `eval.command.battle.chooseMove` | `evaluation_command` | `playable_runtime_host` | `SUPPORTED` | `examples/playable_runtime_host/lib/src/evaluation/scenario/evaluation_command_catalog.dart#battle.chooseMove` | `map_runtime` | `examples/playable_runtime_host/test/evaluation/evaluation_scenario_runner_test.dart` | `FG-040..FG-073` | `false` |
| `eval.command.battle.completePostBattle` | `evaluation_command` | `playable_runtime_host` | `SUPPORTED` | `examples/playable_runtime_host/lib/src/evaluation/scenario/evaluation_command_catalog.dart#battle.completePostBattle` | `map_runtime` | `examples/playable_runtime_host/test/evaluation/evaluation_scenario_runner_test.dart` | `FG-040..FG-073` | `false` |
| `eval.command.battle.resolve` | `evaluation_command` | `playable_runtime_host` | `SUPPORTED` | `examples/playable_runtime_host/lib/src/evaluation/scenario/evaluation_command_catalog.dart#battle.resolve` | `map_runtime` | `examples/playable_runtime_host/test/evaluation/evaluation_scenario_runner_test.dart` | `FG-040..FG-073` | `false` |
| `eval.command.battle.run` | `evaluation_command` | `playable_runtime_host` | `SUPPORTED` | `examples/playable_runtime_host/lib/src/evaluation/scenario/evaluation_command_catalog.dart#battle.run` | `map_runtime` | `examples/playable_runtime_host/test/evaluation/evaluation_scenario_runner_test.dart` | `FG-040..FG-073` | `false` |
| `eval.command.battle.useItem` | `evaluation_command` | `playable_runtime_host` | `SUPPORTED` | `examples/playable_runtime_host/lib/src/evaluation/scenario/evaluation_command_catalog.dart#battle.useItem` | `map_runtime` | `examples/playable_runtime_host/test/evaluation/evaluation_scenario_runner_test.dart` | `FG-040..FG-073` | `false` |
| `eval.command.dialogue.advance` | `evaluation_command` | `playable_runtime_host` | `SUPPORTED` | `examples/playable_runtime_host/lib/src/evaluation/scenario/evaluation_command_catalog.dart#dialogue.advance` | `map_runtime` | `examples/playable_runtime_host/test/evaluation/evaluation_scenario_runner_test.dart` | `FG-080..FG-094` | `false` |
| `eval.command.dialogue.choose` | `evaluation_command` | `playable_runtime_host` | `SUPPORTED` | `examples/playable_runtime_host/lib/src/evaluation/scenario/evaluation_command_catalog.dart#dialogue.choose` | `map_runtime` | `examples/playable_runtime_host/test/evaluation/evaluation_scenario_runner_test.dart` | `FG-080..FG-094` | `false` |
| `eval.command.evidence.checkpoint` | `evaluation_command` | `playable_runtime_host` | `SUPPORTED` | `examples/playable_runtime_host/lib/src/evaluation/scenario/evaluation_command_catalog.dart#evidence.checkpoint` | `map_runtime` | `examples/playable_runtime_host/test/evaluation/evaluation_scenario_runner_test.dart` | — | `false` |
| `eval.command.evidence.snapshot` | `evaluation_command` | `playable_runtime_host` | `SUPPORTED` | `examples/playable_runtime_host/lib/src/evaluation/scenario/evaluation_command_catalog.dart#evidence.snapshot` | `map_runtime` | `examples/playable_runtime_host/test/evaluation/evaluation_scenario_runner_test.dart` | — | `false` |
| `eval.command.game.new` | `evaluation_command` | `playable_runtime_host` | `SUPPORTED` | `examples/playable_runtime_host/lib/src/evaluation/scenario/evaluation_command_catalog.dart#game.new` | `map_runtime` | `examples/playable_runtime_host/test/evaluation/evaluation_scenario_runner_test.dart` | — | `false` |
| `eval.command.movement.crossConnection` | `evaluation_command` | `playable_runtime_host` | `SUPPORTED` | `examples/playable_runtime_host/lib/src/evaluation/scenario/evaluation_command_catalog.dart#movement.crossConnection` | `map_runtime` | `examples/playable_runtime_host/test/evaluation/evaluation_scenario_runner_test.dart` | `FG-120..FG-129` | `false` |
| `eval.command.movement.enterGameplayZone` | `evaluation_command` | `playable_runtime_host` | `SUPPORTED` | `examples/playable_runtime_host/lib/src/evaluation/scenario/evaluation_command_catalog.dart#movement.enterGameplayZone` | `map_runtime` | `examples/playable_runtime_host/test/evaluation/evaluation_scenario_runner_test.dart` | `FG-120..FG-129` | `false` |
| `eval.command.movement.navigate` | `evaluation_command` | `playable_runtime_host` | `SUPPORTED` | `examples/playable_runtime_host/lib/src/evaluation/scenario/evaluation_command_catalog.dart#movement.navigate` | `map_runtime` | `examples/playable_runtime_host/test/evaluation/evaluation_scenario_runner_test.dart` | `FG-120..FG-129` | `false` |
| `eval.command.probe.goto` | `evaluation_command` | `playable_runtime_host` | `SUPPORTED` | `examples/playable_runtime_host/lib/src/evaluation/scenario/evaluation_command_catalog.dart#probe.goto` | `map_runtime` | `examples/playable_runtime_host/test/evaluation/evaluation_scenario_runner_test.dart` | — | `false` |
| `eval.command.probe.loadCheckpoint` | `evaluation_command` | `playable_runtime_host` | `SUPPORTED` | `examples/playable_runtime_host/lib/src/evaluation/scenario/evaluation_command_catalog.dart#probe.loadCheckpoint` | `map_runtime` | `examples/playable_runtime_host/test/evaluation/evaluation_scenario_runner_test.dart` | — | `false` |
| `eval.command.probe.overrideFact` | `evaluation_command` | `playable_runtime_host` | `SUPPORTED` | `examples/playable_runtime_host/lib/src/evaluation/scenario/evaluation_command_catalog.dart#probe.overrideFact` | `map_runtime` | `examples/playable_runtime_host/test/evaluation/evaluation_scenario_runner_test.dart` | `FG-080..FG-094` | `false` |
| `eval.command.probe.seedBag` | `evaluation_command` | `playable_runtime_host` | `SUPPORTED` | `examples/playable_runtime_host/lib/src/evaluation/scenario/evaluation_command_catalog.dart#probe.seedBag` | `map_runtime` | `examples/playable_runtime_host/test/evaluation/evaluation_scenario_runner_test.dart` | — | `false` |
| `eval.command.probe.seedParty` | `evaluation_command` | `playable_runtime_host` | `SUPPORTED` | `examples/playable_runtime_host/lib/src/evaluation/scenario/evaluation_command_catalog.dart#probe.seedParty` | `map_runtime` | `examples/playable_runtime_host/test/evaluation/evaluation_scenario_runner_test.dart` | `FG-010..FG-030` | `false` |
| `eval.command.probe.setMoney` | `evaluation_command` | `playable_runtime_host` | `SUPPORTED` | `examples/playable_runtime_host/lib/src/evaluation/scenario/evaluation_command_catalog.dart#probe.setMoney` | `map_runtime` | `examples/playable_runtime_host/test/evaluation/evaluation_scenario_runner_test.dart` | — | `false` |
| `eval.command.save.reload` | `evaluation_command` | `playable_runtime_host` | `SUPPORTED` | `examples/playable_runtime_host/lib/src/evaluation/scenario/evaluation_command_catalog.dart#save.reload` | `map_runtime` | `examples/playable_runtime_host/test/evaluation/evaluation_scenario_runner_test.dart` | `FG-010..FG-030` | `false` |
| `eval.command.save.write` | `evaluation_command` | `playable_runtime_host` | `SUPPORTED` | `examples/playable_runtime_host/lib/src/evaluation/scenario/evaluation_command_catalog.dart#save.write` | `map_runtime` | `examples/playable_runtime_host/test/evaluation/evaluation_scenario_runner_test.dart` | `FG-010..FG-030` | `false` |
| `eval.command.service.heal` | `evaluation_command` | `playable_runtime_host` | `SUPPORTED` | `examples/playable_runtime_host/lib/src/evaluation/scenario/evaluation_command_catalog.dart#service.heal` | `map_runtime` | `examples/playable_runtime_host/test/evaluation/evaluation_scenario_runner_test.dart` | `FG-040..FG-073` | `false` |
| `eval.command.service.pc.withdraw` | `evaluation_command` | `playable_runtime_host` | `SUPPORTED` | `examples/playable_runtime_host/lib/src/evaluation/scenario/evaluation_command_catalog.dart#service.pc.withdraw` | `map_runtime` | `examples/playable_runtime_host/test/evaluation/evaluation_scenario_runner_test.dart` | `FG-010..FG-030` | `false` |
| `eval.command.service.shop.buy` | `evaluation_command` | `playable_runtime_host` | `SUPPORTED` | `examples/playable_runtime_host/lib/src/evaluation/scenario/evaluation_command_catalog.dart#service.shop.buy` | `map_runtime` | `examples/playable_runtime_host/test/evaluation/evaluation_scenario_runner_test.dart` | `FG-040..FG-073` | `false` |
| `eval.command.service.shop.inspect` | `evaluation_command` | `playable_runtime_host` | `SUPPORTED` | `examples/playable_runtime_host/lib/src/evaluation/scenario/evaluation_command_catalog.dart#service.shop.inspect` | `map_runtime` | `examples/playable_runtime_host/test/evaluation/evaluation_scenario_runner_test.dart` | `FG-040..FG-073` | `false` |
| `eval.command.world.enterEncounter` | `evaluation_command` | `playable_runtime_host` | `SUPPORTED` | `examples/playable_runtime_host/lib/src/evaluation/scenario/evaluation_command_catalog.dart#world.enterEncounter` | `map_runtime` | `examples/playable_runtime_host/test/evaluation/evaluation_scenario_runner_test.dart` | `FG-100..FG-108` | `false` |
| `eval.command.world.enterTrigger` | `evaluation_command` | `playable_runtime_host` | `SUPPORTED` | `examples/playable_runtime_host/lib/src/evaluation/scenario/evaluation_command_catalog.dart#world.enterTrigger` | `map_runtime` | `examples/playable_runtime_host/test/evaluation/evaluation_scenario_runner_test.dart` | — | `false` |
| `eval.command.world.enterWarp` | `evaluation_command` | `playable_runtime_host` | `SUPPORTED` | `examples/playable_runtime_host/lib/src/evaluation/scenario/evaluation_command_catalog.dart#world.enterWarp` | `map_runtime` | `examples/playable_runtime_host/test/evaluation/evaluation_scenario_runner_test.dart` | — | `false` |
| `eval.command.world.interact` | `evaluation_command` | `playable_runtime_host` | `SUPPORTED` | `examples/playable_runtime_host/lib/src/evaluation/scenario/evaluation_command_catalog.dart#world.interact` | `map_runtime` | `examples/playable_runtime_host/test/evaluation/evaluation_scenario_runner_test.dart` | — | `false` |
| `eval.command.world.waitForFact` | `evaluation_command` | `playable_runtime_host` | `SUPPORTED` | `examples/playable_runtime_host/lib/src/evaluation/scenario/evaluation_command_catalog.dart#world.waitForFact` | `map_runtime` | `examples/playable_runtime_host/test/evaluation/evaluation_scenario_runner_test.dart` | `FG-080..FG-094` | `false` |
| `model.map_data.connections` | `map_data_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/map_data.dart#connections` | `map_editor,map_runtime` | — | — | `false` |
| `model.map_data.entities` | `map_data_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/map_data.dart#entities` | `map_editor,map_runtime` | — | — | `false` |
| `model.map_data.events` | `map_data_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/map_data.dart#events` | `map_editor,map_runtime` | — | — | `false` |
| `model.map_data.gameplayZones` | `map_data_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/map_data.dart#gameplayZones` | `map_editor,map_runtime` | — | — | `false` |
| `model.map_data.id` | `map_data_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/map_data.dart#id` | `map_editor,map_runtime` | — | — | `false` |
| `model.map_data.layers` | `map_data_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/map_data.dart#layers` | `map_editor,map_runtime` | — | — | `false` |
| `model.map_data.mapMetadata` | `map_data_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/map_data.dart#mapMetadata` | `map_editor,map_runtime` | — | — | `false` |
| `model.map_data.name` | `map_data_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/map_data.dart#name` | `map_editor,map_runtime` | — | — | `false` |
| `model.map_data.placedElements` | `map_data_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/map_data.dart#placedElements` | `map_editor,map_runtime` | — | — | `false` |
| `model.map_data.properties` | `map_data_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/map_data.dart#properties` | `map_editor,map_runtime` | — | — | `false` |
| `model.map_data.size` | `map_data_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/map_data.dart#size` | `map_editor,map_runtime` | — | — | `false` |
| `model.map_data.tilesetId` | `map_data_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/map_data.dart#tilesetId` | `map_editor,map_runtime` | — | — | `false` |
| `model.map_data.triggers` | `map_data_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/map_data.dart#triggers` | `map_editor,map_runtime` | — | — | `false` |
| `model.map_data.version` | `map_data_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/map_data.dart#version` | `map_editor,map_runtime` | — | — | `false` |
| `model.map_data.visualStack` | `map_data_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/map_data.dart#visualStack` | `map_editor,map_runtime` | — | — | `false` |
| `model.map_data.warps` | `map_data_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/map_data.dart#warps` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.badges` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#badges` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.borderCatalog` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#borderCatalog` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.characters` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#characters` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.cinematicMediaAssets` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#cinematicMediaAssets` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.cinematics` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#cinematics` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.dialogueFolders` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#dialogueFolders` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.dialogues` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#dialogues` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.elementCategories` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#elementCategories` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.elements` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#elements` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.encounterTables` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#encounterTables` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.environmentPresets` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#environmentPresets` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.eventRegistry` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#eventRegistry` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.facts` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#facts` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.globalProperties` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#globalProperties` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.groups` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#groups` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.maps` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#maps` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.name` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#name` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.narrativeDiagnosticSuppressions` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#narrativeDiagnosticSuppressions` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.newGame` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#newGame` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.pathCategories` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#pathCategories` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.pathPatternPresets` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#pathPatternPresets` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.pathPresets` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#pathPresets` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.pokemon` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#pokemon` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.presentation` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#presentation` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.projectedBuildingShadowCatalog` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#projectedBuildingShadowCatalog` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.scenarios` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#scenarios` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.scenes` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#scenes` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.scripts` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#scripts` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.settings` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#settings` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.shadowCatalog` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#shadowCatalog` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.shops` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#shops` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.smartTileCatalog` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#smartTileCatalog` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.storylines` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#storylines` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.surfaceCatalog` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#surfaceCatalog` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.terrainCategories` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#terrainCategories` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.terrainPresets` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#terrainPresets` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.tilesetFolders` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#tilesetFolders` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.tilesets` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#tilesets` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.trainers` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#trainers` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.version` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#version` | `map_editor,map_runtime` | — | — | `false` |
| `model.project_manifest.worldRules` | `project_manifest_field` | `map_core` | `MISSING` | `packages/map_core/lib/src/models/project_manifest.dart#worldRules` | `map_editor,map_runtime` | — | — | `false` |

~~~~~~~~

## `packages/map_authoring/analysis_options.yaml`

~~~~~~~~yaml
include: package:lints/recommended.yaml
~~~~~~~~

## `packages/map_authoring/lib/map_authoring.dart`

~~~~~~~~dart
/// Canonical pure-Dart authoring contracts for PokeMap.
///
/// Platform adapters and MCP protocol translation deliberately live outside
/// this package. Keeping this barrel free of those dependencies is an
/// architectural invariant tested by `package_boundary_test.dart`.
library;

export 'src/architecture/package_boundaries.dart';
export 'src/contracts/action_descriptor.dart';
export 'src/contracts/capability_descriptor.dart';
export 'src/contracts/authoring_diff.dart';
export 'src/contracts/authoring_error.dart';
export 'src/contracts/authoring_receipt.dart';
export 'src/contracts/authoring_request.dart';
export 'src/contracts/authoring_result.dart';
export 'src/contracts/resource_ref.dart';
export 'src/contracts/schema_descriptor.dart';
export 'src/registry/action_registry.dart';
export 'src/registry/resource_kind_registry.dart';
export 'src/tooling/registry_documentation.dart';
~~~~~~~~

## `packages/map_authoring/lib/src/architecture/package_boundaries.dart`

~~~~~~~~dart
/// Machine-testable ownership rules for the canonical Authoring API package.
///
/// These declarations document where future phase work belongs. They are not
/// a dependency injector and must not be used to reach platform packages.
abstract final class MapAuthoringPackageBoundaries {
  static const String packageName = 'map_authoring';

  /// `map_core` owns PokeMap's serializable data and pure domain operations.
  static const Set<String> allowedPackageDependencies = {'map_core'};

  static const Set<String> ownedResponsibilities = {
    'authoring contracts',
    'authoring orchestration',
    'action registry',
  };

  /// Adapters remain owned by consumers so Flutter, Flame, and MCP protocol
  /// types cannot leak into canonical contracts.
  static const Map<String, String> platformAdapterOwners = {
    'editor': 'map_editor',
    'runtime': 'map_runtime',
    'mcp': 'tools/pokemap_mcp',
  };
}
~~~~~~~~

## `packages/map_authoring/lib/src/contracts/action_descriptor.dart`

~~~~~~~~dart
import 'json_contract_support.dart';

enum AuthoringRiskLevel {
  readOnly('read_only'),
  low('low'),
  medium('medium'),
  high('high'),
  critical('critical');

  const AuthoringRiskLevel(this.wireName);

  final String wireName;

  static AuthoringRiskLevel fromWireName(String value) {
    return AuthoringRiskLevel.values.firstWhere(
      (item) => item.wireName == value,
      orElse: () => throw FormatException('Unknown riskLevel: $value'),
    );
  }
}

enum AuthoringPermission {
  projectRead('project.read'),
  projectWrite('project.write'),
  assetRead('asset.read'),
  assetWrite('asset.write'),
  render('render'),
  playtest('playtest'),
  recovery('recovery');

  const AuthoringPermission(this.wireName);

  final String wireName;

  static AuthoringPermission fromWireName(String value) {
    return AuthoringPermission.values.firstWhere(
      (item) => item.wireName == value,
      orElse: () => throw FormatException('Unknown permission: $value'),
    );
  }
}

enum AuthoringGuarantee {
  dryRun('dry_run'),
  idempotent('idempotent'),
  atomic('atomic'),
  revisionChecked('revision_checked'),
  undoable('undoable');

  const AuthoringGuarantee(this.wireName);

  final String wireName;

  static AuthoringGuarantee fromWireName(String value) {
    return AuthoringGuarantee.values.firstWhere(
      (item) => item.wireName == value,
      orElse: () => throw FormatException('Unknown guarantee: $value'),
    );
  }
}

/// Public, protocol-neutral description of one canonical authoring action.
final class AuthoringActionDescriptor {
  AuthoringActionDescriptor({
    required String id,
    required int version,
    required String summary,
    required String inputSchemaId,
    required String outputSchemaId,
    required this.riskLevel,
    Iterable<String> resourceKinds = const [],
    Iterable<String> capabilityIds = const [],
    Iterable<AuthoringPermission> requiredPermissions = const [],
    Iterable<AuthoringGuarantee> guarantees = const [],
    Map<String, Object?> extensions = const {},
  })  : id = _actionId(id),
        version = _positiveVersion(version),
        summary = _nonBlank(summary, 'summary'),
        inputSchemaId = _nonBlank(inputSchemaId, 'inputSchemaId'),
        outputSchemaId = _nonBlank(outputSchemaId, 'outputSchemaId'),
        resourceKinds = normalizedContractStrings(
          resourceKinds,
          'resourceKinds',
        ),
        capabilityIds = normalizedContractStrings(
          capabilityIds,
          'capabilityIds',
        ),
        requiredPermissions = normalizedContractEnums(
          requiredPermissions,
          (permission) => permission.wireName,
        ),
        guarantees = normalizedContractEnums(
          guarantees,
          (guarantee) => guarantee.wireName,
        ),
        extensions = validateContractExtensions(
          extensions,
          reservedKeys: _reservedKeys,
        );

  factory AuthoringActionDescriptor.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _reservedKeys);
    try {
      return AuthoringActionDescriptor(
        id: requireContractString(json['id'], 'id'),
        version: requirePositiveContractVersion(json['version'], 'version'),
        summary: requireContractString(json['summary'], 'summary'),
        inputSchemaId:
            requireContractString(json['inputSchemaId'], 'inputSchemaId'),
        outputSchemaId:
            requireContractString(json['outputSchemaId'], 'outputSchemaId'),
        riskLevel: AuthoringRiskLevel.fromWireName(
          requireContractString(json['riskLevel'], 'riskLevel'),
        ),
        resourceKinds:
            readContractStringList(json['resourceKinds'], 'resourceKinds'),
        capabilityIds:
            readContractStringList(json['capabilityIds'], 'capabilityIds'),
        requiredPermissions: _readPermissions(json['requiredPermissions']),
        guarantees: _readGuarantees(json['guarantees']),
        extensions: readContractExtensions(
          json['extensions'],
          reservedKeys: _reservedKeys,
        ),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  static const Set<String> _reservedKeys = {
    'id',
    'version',
    'summary',
    'inputSchemaId',
    'outputSchemaId',
    'riskLevel',
    'resourceKinds',
    'capabilityIds',
    'requiredPermissions',
    'guarantees',
    'extensions',
  };

  final String id;
  final int version;
  final String summary;
  final String inputSchemaId;
  final String outputSchemaId;
  final AuthoringRiskLevel riskLevel;
  final List<String> resourceKinds;
  final List<String> capabilityIds;
  final List<AuthoringPermission> requiredPermissions;
  final List<AuthoringGuarantee> guarantees;
  final Map<String, Object?> extensions;

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'id': id,
      'version': version,
      'summary': summary,
      'inputSchemaId': inputSchemaId,
      'outputSchemaId': outputSchemaId,
      'riskLevel': riskLevel.wireName,
      'resourceKinds': resourceKinds,
      'capabilityIds': capabilityIds,
      'requiredPermissions': requiredPermissions
          .map((permission) => permission.wireName)
          .toList(growable: false),
      'guarantees': guarantees
          .map((guarantee) => guarantee.wireName)
          .toList(growable: false),
    };
    writeContractExtensions(json, extensions);
    return json;
  }
}

List<AuthoringPermission> _readPermissions(Object? value) {
  return normalizedContractEnums(
    readContractStringList(value, 'requiredPermissions')
        .map(AuthoringPermission.fromWireName),
    (permission) => permission.wireName,
  );
}

List<AuthoringGuarantee> _readGuarantees(Object? value) {
  return normalizedContractEnums(
    readContractStringList(value, 'guarantees')
        .map(AuthoringGuarantee.fromWireName),
    (guarantee) => guarantee.wireName,
  );
}

String _nonBlank(String value, String field) {
  try {
    return requireContractString(value, field);
  } on FormatException catch (error) {
    throw ArgumentError.value(value, field, error.message);
  }
}

int _positiveVersion(int value) {
  try {
    return requirePositiveContractVersion(value, 'version');
  } on FormatException catch (error) {
    throw ArgumentError.value(value, 'version', error.message);
  }
}

String _actionId(String value) {
  final normalized = _nonBlank(value, 'id');
  if (!RegExp(
    r'^[a-z][a-zA-Z0-9_]*(?:\.[a-zA-Z0-9_]+)+$',
  ).hasMatch(normalized)) {
    throw ArgumentError.value(
      value,
      'id',
      'must be a stable dotted action identifier',
    );
  }
  return normalized;
}
~~~~~~~~

## `packages/map_authoring/lib/src/contracts/authoring_diff.dart`

~~~~~~~~dart
import 'json_contract_support.dart';
import 'resource_ref.dart';

enum AuthoringDiffOperation {
  add('add'),
  remove('remove'),
  replace('replace'),
  move('move'),
  link('link'),
  unlink('unlink');

  const AuthoringDiffOperation(this.wireName);

  final String wireName;

  static AuthoringDiffOperation fromWireName(String value) {
    return AuthoringDiffOperation.values.firstWhere(
      (item) => item.wireName == value,
      orElse: () => throw FormatException('Unknown diff operation: $value'),
    );
  }
}

/// One deterministic change against one typed resource.
final class AuthoringDiffEntry {
  factory AuthoringDiffEntry({
    required AuthoringDiffOperation operation,
    required AuthoringResourceRef resource,
    required String path,
    Object? before = _absentJsonValue,
    Object? after = _absentJsonValue,
    Map<String, Object?> extensions = const {},
  }) {
    return AuthoringDiffEntry._(
      operation: operation,
      resource: resource,
      path: _nonBlank(path, 'path'),
      hasBefore: !identical(before, _absentJsonValue),
      before: identical(before, _absentJsonValue)
          ? null
          : freezeContractJsonValue(before, field: 'before'),
      hasAfter: !identical(after, _absentJsonValue),
      after: identical(after, _absentJsonValue)
          ? null
          : freezeContractJsonValue(after, field: 'after'),
      extensions: validateContractExtensions(
        extensions,
        reservedKeys: _reservedKeys,
      ),
    );
  }

  AuthoringDiffEntry._({
    required this.operation,
    required this.resource,
    required this.path,
    required this.hasBefore,
    required this.before,
    required this.hasAfter,
    required this.after,
    required this.extensions,
  });

  factory AuthoringDiffEntry.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _reservedKeys);
    final rawResource = json['resource'];
    if (rawResource is! Map) {
      throw const FormatException('resource must be a JSON object');
    }
    try {
      return AuthoringDiffEntry(
        operation: AuthoringDiffOperation.fromWireName(
          requireContractString(json['operation'], 'operation'),
        ),
        resource: AuthoringResourceRef.fromJson(
          Map<String, dynamic>.from(rawResource),
        ),
        path: requireContractString(json['path'], 'path'),
        before: json.containsKey('before') ? json['before'] : _absentJsonValue,
        after: json.containsKey('after') ? json['after'] : _absentJsonValue,
        extensions: readContractExtensions(
          json['extensions'],
          reservedKeys: _reservedKeys,
        ),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  static const Set<String> _reservedKeys = {
    'operation',
    'resource',
    'path',
    'before',
    'after',
    'extensions',
  };

  final AuthoringDiffOperation operation;
  final AuthoringResourceRef resource;
  final String path;
  final bool hasBefore;
  final Object? before;
  final bool hasAfter;
  final Object? after;
  final Map<String, Object?> extensions;

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'operation': operation.wireName,
      'resource': resource.toJson(),
      'path': path,
      if (hasBefore) 'before': before,
      if (hasAfter) 'after': after,
    };
    writeContractExtensions(json, extensions);
    return json;
  }
}

const Object _absentJsonValue = Object();

/// Sorted diff plus the exact set of resources it affects.
final class AuthoringDiff {
  AuthoringDiff(Iterable<AuthoringDiffEntry> changes)
      : entries = _sortedEntries(changes) {
    final byKey = <String, AuthoringResourceRef>{};
    for (final entry in entries) {
      byKey[_resourceKey(entry.resource)] = entry.resource;
    }
    affectedResources = List.unmodifiable(
      byKey.values.toList()
        ..sort(
            (left, right) => _resourceKey(left).compareTo(_resourceKey(right))),
    );
  }

  factory AuthoringDiff.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, const {'entries'});
    final rawEntries = json['entries'];
    if (rawEntries is! List) {
      throw const FormatException('entries must be a JSON list');
    }
    return AuthoringDiff(
      rawEntries.map((rawEntry) {
        if (rawEntry is! Map) {
          throw const FormatException('diff entry must be a JSON object');
        }
        return AuthoringDiffEntry.fromJson(
          Map<String, dynamic>.from(rawEntry),
        );
      }),
    );
  }

  final List<AuthoringDiffEntry> entries;
  late final List<AuthoringResourceRef> affectedResources;

  Map<String, Object?> toJson() {
    return {
      'entries': entries.map((entry) => entry.toJson()).toList(growable: false),
    };
  }

  static List<AuthoringDiffEntry> _sortedEntries(
    Iterable<AuthoringDiffEntry> changes,
  ) {
    final sorted = changes.toList()
      ..sort((left, right) {
        final resourceComparison =
            _resourceKey(left.resource).compareTo(_resourceKey(right.resource));
        if (resourceComparison != 0) return resourceComparison;
        final pathComparison = left.path.compareTo(right.path);
        if (pathComparison != 0) return pathComparison;
        return left.operation.wireName.compareTo(right.operation.wireName);
      });
    return List.unmodifiable(sorted);
  }
}

String _resourceKey(AuthoringResourceRef resource) {
  return '${resource.kind}\u0000${resource.id}\u0000${resource.revision ?? ''}';
}

String _nonBlank(String value, String field) {
  try {
    return requireContractString(value, field);
  } on FormatException catch (error) {
    throw ArgumentError.value(value, field, error.message);
  }
}
~~~~~~~~

## `packages/map_authoring/lib/src/contracts/authoring_error.dart`

~~~~~~~~dart
import 'json_contract_support.dart';

enum AuthoringErrorCode {
  invalidRequest('invalid_request'),
  notFound('not_found'),
  validationFailed('validation_failed'),
  permissionDenied('permission_denied'),
  revisionConflict('revision_conflict'),
  unsupported('unsupported'),
  internal('internal');

  const AuthoringErrorCode(this.wireName);

  final String wireName;

  static AuthoringErrorCode fromWireName(String value) {
    return AuthoringErrorCode.values.firstWhere(
      (item) => item.wireName == value,
      orElse: () => throw FormatException('Unknown error code: $value'),
    );
  }
}

/// Safe, structured error intended for external authoring clients.
///
/// Raw exceptions, stack traces, and machine-local paths must be logged behind
/// the adapter boundary instead of being serialized here.
final class AuthoringError {
  AuthoringError({
    required this.code,
    required String message,
    required this.retryable,
    String? fieldPath,
    Iterable<String> remediation = const [],
    Map<String, Object?> details = const {},
    Map<String, Object?> extensions = const {},
  })  : message = _safeText(message, 'message'),
        fieldPath =
            fieldPath == null ? null : _safeText(fieldPath, 'fieldPath'),
        remediation = List.unmodifiable(
          remediation.map((item) => _safeText(item, 'remediation')),
        ),
        details = freezeContractJsonObject(details, field: 'details'),
        extensions = validateContractExtensions(
          extensions,
          reservedKeys: _reservedKeys,
        ) {
    _rejectUnsafeJson(this.details, 'details');
    _rejectUnsafeJson(this.extensions, 'extensions');
  }

  factory AuthoringError.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _reservedKeys);
    final rawRemediation = json['remediation'];
    final rawDetails = json['details'];
    if (rawRemediation is! List ||
        rawRemediation.any((item) => item is! String)) {
      throw const FormatException('remediation must be a list of strings');
    }
    if (rawDetails is! Map) {
      throw const FormatException('details must be a JSON object');
    }
    try {
      return AuthoringError(
        code: AuthoringErrorCode.fromWireName(
          requireContractString(json['code'], 'code'),
        ),
        message: requireContractString(json['message'], 'message'),
        retryable: requireContractBool(json['retryable'], 'retryable'),
        fieldPath: readOptionalContractString(json['fieldPath'], 'fieldPath'),
        remediation: rawRemediation.cast<String>(),
        details: Map<String, Object?>.from(rawDetails),
        extensions: readContractExtensions(
          json['extensions'],
          reservedKeys: _reservedKeys,
        ),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  static const Set<String> _reservedKeys = {
    'code',
    'message',
    'retryable',
    'fieldPath',
    'remediation',
    'details',
    'extensions',
  };

  final AuthoringErrorCode code;
  final String message;
  final bool retryable;
  final String? fieldPath;
  final List<String> remediation;
  final Map<String, Object?> details;
  final Map<String, Object?> extensions;

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'code': code.wireName,
      'message': message,
      'retryable': retryable,
      if (fieldPath != null) 'fieldPath': fieldPath,
      'remediation': remediation,
      'details': details,
    };
    writeContractExtensions(json, extensions);
    return json;
  }
}

String _safeText(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, field, 'must not be blank');
  }
  if (_machinePathPattern.hasMatch(normalized)) {
    throw ArgumentError.value(
      value,
      field,
      'must not contain a machine-local path',
    );
  }
  if (normalized.toLowerCase().contains('stack trace')) {
    throw ArgumentError.value(value, field, 'must not contain a stack trace');
  }
  if (RegExp(r'(?:^|\n)\s*#\d+\s').hasMatch(normalized)) {
    throw ArgumentError.value(value, field, 'must not contain a stack trace');
  }
  return normalized;
}

void _rejectUnsafeJson(Object? value, String field) {
  if (value is String) {
    _safeText(value, field);
    return;
  }
  if (value is List) {
    for (var index = 0; index < value.length; index++) {
      _rejectUnsafeJson(value[index], '$field[$index]');
    }
    return;
  }
  if (value is Map) {
    for (final entry in value.entries) {
      final normalizedKey =
          entry.key.toString().replaceAll(RegExp(r'[_\-\s]'), '').toLowerCase();
      if (normalizedKey == 'stack' ||
          normalizedKey == 'trace' ||
          normalizedKey == 'stacktrace') {
        throw ArgumentError.value(
          entry.key,
          field,
          'must not expose stack traces',
        );
      }
      _rejectUnsafeJson(entry.value, '$field.${entry.key}');
    }
  }
}

final RegExp _machinePathPattern = RegExp(
  r'(?:/Users/|/home/|/private/|/tmp/|/var/folders/|'
  r'/workspace/|'
  r'[A-Za-z]:\\(?:Users|Documents and Settings)\\)',
  caseSensitive: false,
);
~~~~~~~~

## `packages/map_authoring/lib/src/contracts/authoring_receipt.dart`

~~~~~~~~dart
import 'authoring_diff.dart';
import 'json_contract_support.dart';
import 'resource_ref.dart';

enum AuthoringReceiptStatus {
  planned('planned'),
  applied('applied'),
  recovered('recovered');

  const AuthoringReceiptStatus(this.wireName);

  final String wireName;

  static AuthoringReceiptStatus fromWireName(String value) {
    return AuthoringReceiptStatus.values.firstWhere(
      (item) => item.wireName == value,
      orElse: () => throw FormatException('Unknown receipt status: $value'),
    );
  }
}

/// Compact link to a generated artifact.
///
/// Local filesystem paths are forbidden because clients may run on another
/// machine and because paths can disclose private workspace information.
final class AuthoringArtifactRef {
  AuthoringArtifactRef({
    required String id,
    required String mediaType,
    required String uri,
    int? byteLength,
    String? sha256,
    Map<String, Object?> extensions = const {},
  })  : id = _nonBlank(id, 'id'),
        mediaType = _nonBlank(mediaType, 'mediaType'),
        uri = _safeArtifactUri(uri),
        byteLength = _nonNegativeLength(byteLength),
        sha256 = sha256 == null ? null : _nonBlank(sha256, 'sha256'),
        extensions = validateContractExtensions(
          extensions,
          reservedKeys: _artifactReservedKeys,
        );

  factory AuthoringArtifactRef.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _artifactReservedKeys);
    final rawLength = json['byteLength'];
    if (rawLength != null && rawLength is! int) {
      throw const FormatException('byteLength must be an integer');
    }
    try {
      return AuthoringArtifactRef(
        id: requireContractString(json['id'], 'id'),
        mediaType: requireContractString(json['mediaType'], 'mediaType'),
        uri: requireContractString(json['uri'], 'uri'),
        byteLength: rawLength as int?,
        sha256: readOptionalContractString(json['sha256'], 'sha256'),
        extensions: readContractExtensions(
          json['extensions'],
          reservedKeys: _artifactReservedKeys,
        ),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final String id;
  final String mediaType;
  final String uri;
  final int? byteLength;
  final String? sha256;
  final Map<String, Object?> extensions;

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'id': id,
      'mediaType': mediaType,
      'uri': uri,
      if (byteLength != null) 'byteLength': byteLength,
      if (sha256 != null) 'sha256': sha256,
    };
    writeContractExtensions(json, extensions);
    return json;
  }
}

/// Durable evidence returned by a planned or applied authoring action.
final class AuthoringReceipt {
  AuthoringReceipt({
    required String receiptId,
    required String requestId,
    required String actionId,
    required int actionVersion,
    required this.status,
    String? beforeRevision,
    String? afterRevision,
    required String createdAtUtc,
    required this.diff,
    Iterable<AuthoringArtifactRef> artifacts = const [],
    Map<String, Object?> extensions = const {},
  })  : receiptId = _nonBlank(receiptId, 'receiptId'),
        requestId = _nonBlank(requestId, 'requestId'),
        actionId = _nonBlank(actionId, 'actionId'),
        actionVersion = _positiveVersion(actionVersion),
        beforeRevision = beforeRevision == null
            ? null
            : _nonBlank(beforeRevision, 'beforeRevision'),
        afterRevision = afterRevision == null
            ? null
            : _nonBlank(afterRevision, 'afterRevision'),
        createdAtUtc = _utcTimestamp(createdAtUtc),
        artifacts = _sortedArtifacts(artifacts),
        extensions = validateContractExtensions(
          extensions,
          reservedKeys: _receiptReservedKeys,
        );

  factory AuthoringReceipt.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _receiptReservedKeys);
    final rawDiff = json['diff'];
    final rawArtifacts = json['artifacts'];
    final rawAffected = json['affectedResources'];
    if (rawDiff is! Map) {
      throw const FormatException('diff must be a JSON object');
    }
    if (rawArtifacts is! List) {
      throw const FormatException('artifacts must be a JSON list');
    }
    if (rawAffected is! List) {
      throw const FormatException('affectedResources must be a JSON list');
    }
    final diff = AuthoringDiff.fromJson(Map<String, dynamic>.from(rawDiff));
    late final AuthoringReceipt receipt;
    try {
      receipt = AuthoringReceipt(
        receiptId: requireContractString(json['receiptId'], 'receiptId'),
        requestId: requireContractString(json['requestId'], 'requestId'),
        actionId: requireContractString(json['actionId'], 'actionId'),
        actionVersion: requirePositiveContractVersion(
          json['actionVersion'],
          'actionVersion',
        ),
        status: AuthoringReceiptStatus.fromWireName(
          requireContractString(json['status'], 'status'),
        ),
        beforeRevision: readOptionalContractString(
          json['beforeRevision'],
          'beforeRevision',
        ),
        afterRevision: readOptionalContractString(
          json['afterRevision'],
          'afterRevision',
        ),
        createdAtUtc:
            requireContractString(json['createdAtUtc'], 'createdAtUtc'),
        diff: diff,
        artifacts: rawArtifacts.map((rawArtifact) {
          if (rawArtifact is! Map) {
            throw const FormatException('artifact must be a JSON object');
          }
          return AuthoringArtifactRef.fromJson(
            Map<String, dynamic>.from(rawArtifact),
          );
        }),
        extensions: readContractExtensions(
          json['extensions'],
          reservedKeys: _receiptReservedKeys,
        ),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }

    final declaredAffected = rawAffected.map((rawReference) {
      if (rawReference is! Map) {
        throw const FormatException(
          'affected resource must be a JSON object',
        );
      }
      return AuthoringResourceRef.fromJson(
        Map<String, dynamic>.from(rawReference),
      ).toJson();
    }).toList(growable: false);
    final derivedAffected = receipt.diff.affectedResources
        .map((reference) => reference.toJson())
        .toList(growable: false);
    if (!_jsonListsEqual(declaredAffected, derivedAffected)) {
      throw const FormatException(
        'affectedResources must match resources derived from diff',
      );
    }
    return receipt;
  }

  final String receiptId;
  final String requestId;
  final String actionId;
  final int actionVersion;
  final AuthoringReceiptStatus status;
  final String? beforeRevision;
  final String? afterRevision;
  final String createdAtUtc;
  final AuthoringDiff diff;
  final List<AuthoringArtifactRef> artifacts;
  final Map<String, Object?> extensions;

  List<AuthoringResourceRef> get affectedResources => diff.affectedResources;

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'receiptId': receiptId,
      'requestId': requestId,
      'actionId': actionId,
      'actionVersion': actionVersion,
      'status': status.wireName,
      if (beforeRevision != null) 'beforeRevision': beforeRevision,
      if (afterRevision != null) 'afterRevision': afterRevision,
      'createdAtUtc': createdAtUtc,
      'diff': diff.toJson(),
      'affectedResources': affectedResources
          .map((reference) => reference.toJson())
          .toList(growable: false),
      'artifacts': artifacts
          .map((artifact) => artifact.toJson())
          .toList(growable: false),
    };
    writeContractExtensions(json, extensions);
    return json;
  }
}

const Set<String> _artifactReservedKeys = {
  'id',
  'mediaType',
  'uri',
  'byteLength',
  'sha256',
  'extensions',
};

const Set<String> _receiptReservedKeys = {
  'receiptId',
  'requestId',
  'actionId',
  'actionVersion',
  'status',
  'beforeRevision',
  'afterRevision',
  'createdAtUtc',
  'diff',
  'affectedResources',
  'artifacts',
  'extensions',
};

String _safeArtifactUri(String value) {
  final normalized = _nonBlank(value, 'uri');
  final parsed = Uri.tryParse(normalized);
  if (parsed == null ||
      !parsed.hasScheme ||
      !const {'artifact', 'https'}.contains(parsed.scheme)) {
    throw ArgumentError.value(
      value,
      'uri',
      'must use artifact:// or https://',
    );
  }
  return normalized;
}

int? _nonNegativeLength(int? value) {
  if (value != null && value < 0) {
    throw ArgumentError.value(value, 'byteLength', 'must not be negative');
  }
  return value;
}

String _utcTimestamp(String value) {
  final normalized = _nonBlank(value, 'createdAtUtc');
  final parsed = DateTime.tryParse(normalized);
  if (parsed == null || !parsed.isUtc || !normalized.endsWith('Z')) {
    throw ArgumentError.value(
      value,
      'createdAtUtc',
      'must be an ISO-8601 UTC timestamp ending in Z',
    );
  }
  return normalized;
}

List<AuthoringArtifactRef> _sortedArtifacts(
  Iterable<AuthoringArtifactRef> artifacts,
) {
  final byId = <String, AuthoringArtifactRef>{};
  for (final artifact in artifacts) {
    if (byId.containsKey(artifact.id)) {
      throw ArgumentError.value(
        artifact.id,
        'artifacts',
        'duplicate artifact id',
      );
    }
    byId[artifact.id] = artifact;
  }
  final sorted = byId.values.toList()
    ..sort((left, right) => left.id.compareTo(right.id));
  return List.unmodifiable(sorted);
}

bool _jsonListsEqual(
  List<Map<String, Object?>> left,
  List<Map<String, Object?>> right,
) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index].toString() != right[index].toString()) return false;
  }
  return true;
}

String _nonBlank(String value, String field) {
  try {
    return requireContractString(value, field);
  } on FormatException catch (error) {
    throw ArgumentError.value(value, field, error.message);
  }
}

int _positiveVersion(int value) {
  try {
    return requirePositiveContractVersion(value, 'actionVersion');
  } on FormatException catch (error) {
    throw ArgumentError.value(value, 'actionVersion', error.message);
  }
}
~~~~~~~~

## `packages/map_authoring/lib/src/contracts/authoring_request.dart`

~~~~~~~~dart
import 'json_contract_support.dart';

/// Protocol-neutral request envelope shared by direct API, CLI, editor, and
/// future MCP adapters.
final class AuthoringRequest {
  AuthoringRequest({
    required String requestId,
    required String actionId,
    required int actionVersion,
    required String workspaceHandle,
    Map<String, Object?> parameters = const {},
    String? expectedRevision,
    String? idempotencyKey,
    this.dryRun = false,
    Map<String, Object?> extensions = const {},
  })  : requestId = _nonBlank(requestId, 'requestId'),
        actionId = _nonBlank(actionId, 'actionId'),
        actionVersion = _positiveVersion(actionVersion),
        workspaceHandle = _nonBlank(workspaceHandle, 'workspaceHandle'),
        parameters = freezeContractJsonObject(
          parameters,
          field: 'parameters',
        ),
        expectedRevision = expectedRevision == null
            ? null
            : _nonBlank(expectedRevision, 'expectedRevision'),
        idempotencyKey = idempotencyKey == null
            ? null
            : _nonBlank(idempotencyKey, 'idempotencyKey'),
        extensions = validateContractExtensions(
          extensions,
          reservedKeys: _reservedKeys,
        );

  factory AuthoringRequest.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _reservedKeys);
    final rawParameters = json['parameters'];
    if (rawParameters is! Map) {
      throw const FormatException('parameters must be a JSON object');
    }
    try {
      return AuthoringRequest(
        requestId: requireContractString(json['requestId'], 'requestId'),
        actionId: requireContractString(json['actionId'], 'actionId'),
        actionVersion: requirePositiveContractVersion(
            json['actionVersion'], 'actionVersion'),
        workspaceHandle:
            requireContractString(json['workspaceHandle'], 'workspaceHandle'),
        parameters: Map<String, Object?>.from(rawParameters),
        expectedRevision: readOptionalContractString(
          json['expectedRevision'],
          'expectedRevision',
        ),
        idempotencyKey: readOptionalContractString(
          json['idempotencyKey'],
          'idempotencyKey',
        ),
        dryRun: requireContractBool(json['dryRun'], 'dryRun'),
        extensions: readContractExtensions(
          json['extensions'],
          reservedKeys: _reservedKeys,
        ),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  static const Set<String> _reservedKeys = {
    'requestId',
    'actionId',
    'actionVersion',
    'workspaceHandle',
    'parameters',
    'expectedRevision',
    'idempotencyKey',
    'dryRun',
    'extensions',
  };

  final String requestId;
  final String actionId;
  final int actionVersion;
  final String workspaceHandle;
  final Map<String, Object?> parameters;
  final String? expectedRevision;
  final String? idempotencyKey;
  final bool dryRun;
  final Map<String, Object?> extensions;

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'requestId': requestId,
      'actionId': actionId,
      'actionVersion': actionVersion,
      'workspaceHandle': workspaceHandle,
      'parameters': parameters,
      if (expectedRevision != null) 'expectedRevision': expectedRevision,
      if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      'dryRun': dryRun,
    };
    writeContractExtensions(json, extensions);
    return json;
  }
}

String _nonBlank(String value, String field) {
  try {
    return requireContractString(value, field);
  } on FormatException catch (error) {
    throw ArgumentError.value(value, field, error.message);
  }
}

int _positiveVersion(int value) {
  try {
    return requirePositiveContractVersion(value, 'actionVersion');
  } on FormatException catch (error) {
    throw ArgumentError.value(value, 'actionVersion', error.message);
  }
}
~~~~~~~~

## `packages/map_authoring/lib/src/contracts/authoring_result.dart`

~~~~~~~~dart
import 'authoring_error.dart';
import 'authoring_receipt.dart';
import 'json_contract_support.dart';

enum AuthoringResultStatus {
  success('success'),
  failure('failure');

  const AuthoringResultStatus(this.wireName);

  final String wireName;

  static AuthoringResultStatus fromWireName(String value) {
    return AuthoringResultStatus.values.firstWhere(
      (item) => item.wireName == value,
      orElse: () => throw FormatException('Unknown result status: $value'),
    );
  }
}

/// Compact, unambiguous result envelope shared by every authoring transport.
final class AuthoringResult {
  AuthoringResult({
    required String requestId,
    required this.status,
    Map<String, Object?> data = const {},
    this.error,
    this.receipt,
    Iterable<AuthoringArtifactRef> artifacts = const [],
    Map<String, Object?> extensions = const {},
  })  : requestId = _nonBlank(requestId, 'requestId'),
        data = freezeContractJsonObject(data, field: 'data'),
        artifacts = _sortedArtifacts(artifacts),
        extensions = validateContractExtensions(
          extensions,
          reservedKeys: _reservedKeys,
        ) {
    if (status == AuthoringResultStatus.success && error != null) {
      throw ArgumentError.value(
        error,
        'error',
        'A successful result cannot contain an error',
      );
    }
    if (status == AuthoringResultStatus.failure && error == null) {
      throw ArgumentError.value(
        error,
        'error',
        'A failed result requires an error',
      );
    }
    if (status == AuthoringResultStatus.failure && receipt != null) {
      throw ArgumentError.value(
        receipt,
        'receipt',
        'A failed result cannot claim a receipt',
      );
    }
  }

  factory AuthoringResult.success({
    required String requestId,
    Map<String, Object?> data = const {},
    AuthoringReceipt? receipt,
    Iterable<AuthoringArtifactRef> artifacts = const [],
    Map<String, Object?> extensions = const {},
  }) {
    return AuthoringResult(
      requestId: requestId,
      status: AuthoringResultStatus.success,
      data: data,
      receipt: receipt,
      artifacts: artifacts,
      extensions: extensions,
    );
  }

  factory AuthoringResult.failure({
    required String requestId,
    required AuthoringError error,
    Map<String, Object?> data = const {},
    Iterable<AuthoringArtifactRef> artifacts = const [],
    Map<String, Object?> extensions = const {},
  }) {
    return AuthoringResult(
      requestId: requestId,
      status: AuthoringResultStatus.failure,
      data: data,
      error: error,
      artifacts: artifacts,
      extensions: extensions,
    );
  }

  factory AuthoringResult.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _reservedKeys);
    final rawData = json['data'];
    final rawArtifacts = json['artifacts'];
    if (rawData is! Map) {
      throw const FormatException('data must be a JSON object');
    }
    if (rawArtifacts is! List) {
      throw const FormatException('artifacts must be a JSON list');
    }
    final rawError = json['error'];
    final rawReceipt = json['receipt'];
    if (rawError != null && rawError is! Map) {
      throw const FormatException('error must be a JSON object');
    }
    if (rawReceipt != null && rawReceipt is! Map) {
      throw const FormatException('receipt must be a JSON object');
    }
    try {
      return AuthoringResult(
        requestId: requireContractString(json['requestId'], 'requestId'),
        status: AuthoringResultStatus.fromWireName(
          requireContractString(json['status'], 'status'),
        ),
        data: Map<String, Object?>.from(rawData),
        error: rawError == null
            ? null
            : AuthoringError.fromJson(Map<String, dynamic>.from(rawError)),
        receipt: rawReceipt == null
            ? null
            : AuthoringReceipt.fromJson(
                Map<String, dynamic>.from(rawReceipt),
              ),
        artifacts: rawArtifacts.map((rawArtifact) {
          if (rawArtifact is! Map) {
            throw const FormatException('artifact must be a JSON object');
          }
          return AuthoringArtifactRef.fromJson(
            Map<String, dynamic>.from(rawArtifact),
          );
        }),
        extensions: readContractExtensions(
          json['extensions'],
          reservedKeys: _reservedKeys,
        ),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  static const Set<String> _reservedKeys = {
    'requestId',
    'status',
    'data',
    'error',
    'receipt',
    'artifacts',
    'extensions',
  };

  final String requestId;
  final AuthoringResultStatus status;
  final Map<String, Object?> data;
  final AuthoringError? error;
  final AuthoringReceipt? receipt;
  final List<AuthoringArtifactRef> artifacts;
  final Map<String, Object?> extensions;

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'requestId': requestId,
      'status': status.wireName,
      'data': data,
      if (error != null) 'error': error!.toJson(),
      if (receipt != null) 'receipt': receipt!.toJson(),
      'artifacts': artifacts
          .map((artifact) => artifact.toJson())
          .toList(growable: false),
    };
    writeContractExtensions(json, extensions);
    return json;
  }
}

List<AuthoringArtifactRef> _sortedArtifacts(
  Iterable<AuthoringArtifactRef> artifacts,
) {
  final byId = <String, AuthoringArtifactRef>{};
  for (final artifact in artifacts) {
    if (byId.containsKey(artifact.id)) {
      throw ArgumentError.value(
        artifact.id,
        'artifacts',
        'duplicate artifact id',
      );
    }
    byId[artifact.id] = artifact;
  }
  final sorted = byId.values.toList()
    ..sort((left, right) => left.id.compareTo(right.id));
  return List.unmodifiable(sorted);
}

String _nonBlank(String value, String field) {
  try {
    return requireContractString(value, field);
  } on FormatException catch (error) {
    throw ArgumentError.value(value, field, error.message);
  }
}
~~~~~~~~

## `packages/map_authoring/lib/src/contracts/capability_descriptor.dart`

~~~~~~~~dart
import 'json_contract_support.dart';

/// Versioned grouping of related authoring actions and resource kinds.
final class AuthoringCapabilityDescriptor {
  AuthoringCapabilityDescriptor({
    required String id,
    required int version,
    required String summary,
    Iterable<String> resourceKinds = const [],
    Iterable<String> actionIds = const [],
    Map<String, Object?> extensions = const {},
  })  : id = _nonBlank(id, 'id'),
        version = _positiveVersion(version),
        summary = _nonBlank(summary, 'summary'),
        resourceKinds = normalizedContractStrings(
          resourceKinds,
          'resourceKinds',
        ),
        actionIds = normalizedContractStrings(actionIds, 'actionIds'),
        extensions = validateContractExtensions(
          extensions,
          reservedKeys: _reservedKeys,
        );

  factory AuthoringCapabilityDescriptor.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _reservedKeys);
    try {
      return AuthoringCapabilityDescriptor(
        id: requireContractString(json['id'], 'id'),
        version: requirePositiveContractVersion(json['version'], 'version'),
        summary: requireContractString(json['summary'], 'summary'),
        resourceKinds:
            readContractStringList(json['resourceKinds'], 'resourceKinds'),
        actionIds: readContractStringList(json['actionIds'], 'actionIds'),
        extensions: readContractExtensions(
          json['extensions'],
          reservedKeys: _reservedKeys,
        ),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  static const Set<String> _reservedKeys = {
    'id',
    'version',
    'summary',
    'resourceKinds',
    'actionIds',
    'extensions',
  };

  final String id;
  final int version;
  final String summary;
  final List<String> resourceKinds;
  final List<String> actionIds;
  final Map<String, Object?> extensions;

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'id': id,
      'version': version,
      'summary': summary,
      'resourceKinds': resourceKinds,
      'actionIds': actionIds,
    };
    writeContractExtensions(json, extensions);
    return json;
  }
}

String _nonBlank(String value, String field) {
  try {
    return requireContractString(value, field);
  } on FormatException catch (error) {
    throw ArgumentError.value(value, field, error.message);
  }
}

int _positiveVersion(int value) {
  try {
    return requirePositiveContractVersion(value, 'version');
  } on FormatException catch (error) {
    throw ArgumentError.value(value, 'version', error.message);
  }
}
~~~~~~~~

## `packages/map_authoring/lib/src/contracts/json_contract_support.dart`

~~~~~~~~dart
/// Shared strict JSON helpers for public Authoring API contracts.
///
/// Unknown top-level fields are rejected. Forward-compatible vendor data must
/// live under `extensions`, where it is preserved but cannot shadow a reserved
/// contract key.
void rejectUnknownContractKeys(
  Map<String, dynamic> json,
  Set<String> allowedKeys,
) {
  final unknown = json.keys.where((key) => !allowedKeys.contains(key)).toList()
    ..sort();
  if (unknown.isNotEmpty) {
    throw FormatException(
      'Unknown contract field(s): ${unknown.join(', ')}',
    );
  }
}

String requireContractString(Object? value, String field) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$field must be a non-blank string');
  }
  return value.trim();
}

String? readOptionalContractString(Object? value, String field) {
  if (value == null) return null;
  return requireContractString(value, field);
}

int requirePositiveContractVersion(Object? value, String field) {
  if (value is! int || value <= 0) {
    throw FormatException('$field must be a positive integer');
  }
  return value;
}

bool requireContractBool(Object? value, String field) {
  if (value is! bool) {
    throw FormatException('$field must be a boolean');
  }
  return value;
}

List<String> readContractStringList(Object? value, String field) {
  if (value is! List) {
    throw FormatException('$field must be a list of strings');
  }
  return normalizedContractStrings(value, field);
}

List<String> normalizedContractStrings(
  Iterable<Object?> values,
  String field,
) {
  final normalized = values
      .map((value) => requireContractString(value, field))
      .toSet()
      .toList()
    ..sort();
  return List.unmodifiable(normalized);
}

List<T> normalizedContractEnums<T>(
  Iterable<T> values,
  String Function(T value) wireName,
) {
  final normalized = values.toSet().toList()
    ..sort((left, right) => wireName(left).compareTo(wireName(right)));
  return List.unmodifiable(normalized);
}

Map<String, Object?> validateContractExtensions(
  Map<String, Object?> extensions, {
  required Set<String> reservedKeys,
}) {
  final collisions = extensions.keys
      .where((key) => reservedKeys.contains(key))
      .toList()
    ..sort();
  if (collisions.isNotEmpty) {
    throw ArgumentError.value(
      collisions,
      'extensions',
      'Extension keys collide with reserved contract fields',
    );
  }
  return freezeContractJsonObject(extensions, field: 'extensions');
}

Map<String, Object?> readContractExtensions(
  Object? value, {
  required Set<String> reservedKeys,
}) {
  if (value == null) return const {};
  if (value is! Map) {
    throw const FormatException('extensions must be a JSON object');
  }
  final object = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw const FormatException('extensions keys must be strings');
    }
    object[entry.key as String] = entry.value;
  }
  try {
    return validateContractExtensions(object, reservedKeys: reservedKeys);
  } on ArgumentError catch (error) {
    throw FormatException(error.message.toString());
  }
}

Map<String, Object?> freezeContractJsonObject(
  Map<String, Object?> value, {
  required String field,
}) {
  final sortedKeys = value.keys.toList()..sort();
  final frozen = <String, Object?>{};
  for (final key in sortedKeys) {
    if (key.trim().isEmpty) {
      throw ArgumentError.value(key, field, 'JSON keys must not be blank');
    }
    frozen[key] = _freezeJsonValue(value[key], '$field.$key');
  }
  return Map.unmodifiable(frozen);
}

Object? _freezeJsonValue(Object? value, String field) {
  if (value == null || value is String || value is bool || value is num) {
    if (value is double && !value.isFinite) {
      throw ArgumentError.value(value, field, 'must be finite JSON number');
    }
    return value;
  }
  if (value is List) {
    return List.unmodifiable([
      for (var index = 0; index < value.length; index++)
        _freezeJsonValue(value[index], '$field[$index]'),
    ]);
  }
  if (value is Map) {
    final object = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw ArgumentError.value(
          entry.key,
          field,
          'JSON object keys must be strings',
        );
      }
      object[entry.key as String] = entry.value;
    }
    return freezeContractJsonObject(object, field: field);
  }
  throw ArgumentError.value(
    value,
    field,
    'must contain only JSON-compatible values',
  );
}

Object? freezeContractJsonValue(Object? value, {required String field}) {
  return _freezeJsonValue(value, field);
}

void writeContractExtensions(
  Map<String, Object?> target,
  Map<String, Object?> extensions,
) {
  if (extensions.isNotEmpty) {
    target['extensions'] = extensions;
  }
}
~~~~~~~~

## `packages/map_authoring/lib/src/contracts/resource_ref.dart`

~~~~~~~~dart
import 'json_contract_support.dart';

/// Typed, opaque reference to a PokeMap authoring resource.
///
/// Callers may compare and transport [id], but must not interpret it as a
/// filesystem path.
final class AuthoringResourceRef {
  AuthoringResourceRef({
    required String kind,
    required String id,
    String? revision,
    Map<String, Object?> extensions = const {},
  })  : kind = _validateResourceKind(kind),
        id = _validateNonBlank(id, 'id'),
        revision =
            revision == null ? null : _validateNonBlank(revision, 'revision'),
        extensions = validateContractExtensions(
          extensions,
          reservedKeys: _reservedKeys,
        );

  factory AuthoringResourceRef.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _reservedKeys);
    try {
      return AuthoringResourceRef(
        kind: requireContractString(json['kind'], 'kind'),
        id: requireContractString(json['id'], 'id'),
        revision: readOptionalContractString(json['revision'], 'revision'),
        extensions: readContractExtensions(
          json['extensions'],
          reservedKeys: _reservedKeys,
        ),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  static const Set<String> _reservedKeys = {
    'kind',
    'id',
    'revision',
    'extensions',
  };

  final String kind;
  final String id;
  final String? revision;
  final Map<String, Object?> extensions;

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'kind': kind,
      'id': id,
      if (revision != null) 'revision': revision,
    };
    writeContractExtensions(json, extensions);
    return json;
  }
}

String _validateResourceKind(String value) {
  final normalized = _validateNonBlank(value, 'kind');
  if (!RegExp(r'^[a-z][a-zA-Z0-9_]*$').hasMatch(normalized)) {
    throw ArgumentError.value(
      value,
      'kind',
      'must be a stable lower-camel identifier',
    );
  }
  return normalized;
}

String _validateNonBlank(String value, String field) {
  try {
    return requireContractString(value, field);
  } on FormatException catch (error) {
    throw ArgumentError.value(value, field, error.message);
  }
}
~~~~~~~~

## `packages/map_authoring/lib/src/contracts/schema_descriptor.dart`

~~~~~~~~dart
import 'json_contract_support.dart';

/// Versioned reference to a canonical request or result JSON Schema.
final class AuthoringSchemaDescriptor {
  AuthoringSchemaDescriptor({
    required String id,
    required int version,
    required String uri,
    required String sha256,
    String? description,
    Map<String, Object?> extensions = const {},
  })  : id = _nonBlank(id, 'id'),
        version = _positiveVersion(version),
        uri = _nonBlank(uri, 'uri'),
        sha256 = _nonBlank(sha256, 'sha256'),
        description =
            description == null ? null : _nonBlank(description, 'description'),
        extensions = validateContractExtensions(
          extensions,
          reservedKeys: _reservedKeys,
        );

  factory AuthoringSchemaDescriptor.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _reservedKeys);
    try {
      return AuthoringSchemaDescriptor(
        id: requireContractString(json['id'], 'id'),
        version: requirePositiveContractVersion(json['version'], 'version'),
        uri: requireContractString(json['uri'], 'uri'),
        sha256: requireContractString(json['sha256'], 'sha256'),
        description:
            readOptionalContractString(json['description'], 'description'),
        extensions: readContractExtensions(
          json['extensions'],
          reservedKeys: _reservedKeys,
        ),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  static const Set<String> _reservedKeys = {
    'id',
    'version',
    'uri',
    'sha256',
    'description',
    'extensions',
  };

  final String id;
  final int version;
  final String uri;
  final String sha256;
  final String? description;
  final Map<String, Object?> extensions;

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'id': id,
      'version': version,
      'uri': uri,
      'sha256': sha256,
      if (description != null) 'description': description,
    };
    writeContractExtensions(json, extensions);
    return json;
  }
}

String _nonBlank(String value, String field) {
  try {
    return requireContractString(value, field);
  } on FormatException catch (error) {
    throw ArgumentError.value(value, field, error.message);
  }
}

int _positiveVersion(int value) {
  try {
    return requirePositiveContractVersion(value, 'version');
  } on FormatException catch (error) {
    throw ArgumentError.value(value, 'version', error.message);
  }
}
~~~~~~~~

## `packages/map_authoring/lib/src/registry/action_registry.dart`

~~~~~~~~dart
import '../contracts/action_descriptor.dart';
import '../contracts/json_contract_support.dart';

/// Duplicate registration of the exact same action contract.
final class DuplicateAuthoringActionException implements Exception {
  const DuplicateAuthoringActionException(this.actionId, this.version);

  final String actionId;
  final int version;

  @override
  String toString() {
    return 'Duplicate authoring action: $actionId v$version';
  }
}

/// Registration of two contract versions under one action ID.
///
/// Phase 1 intentionally keeps one active version per ID. A future version
/// negotiation policy must be explicit rather than silently selecting one.
final class IncompatibleAuthoringActionVersionException implements Exception {
  IncompatibleAuthoringActionVersionException(
    this.actionId,
    Iterable<int> versions,
  ) : versions = List.unmodifiable(versions.toSet().toList()..sort());

  final String actionId;
  final List<int> versions;

  @override
  String toString() {
    return 'Incompatible versions for $actionId: ${versions.join(', ')}';
  }
}

final class UnknownAuthoringActionException implements Exception {
  const UnknownAuthoringActionException(this.actionId);

  final String actionId;

  @override
  String toString() => 'Unknown authoring action: $actionId';
}

/// Immutable, deterministic registry of public authoring actions.
final class AuthoringActionRegistry {
  AuthoringActionRegistry(Iterable<AuthoringActionDescriptor> descriptors)
      : actions = _validateAndSort(descriptors) {
    _byId = Map.unmodifiable({
      for (final action in actions) action.id: action,
    });
  }

  factory AuthoringActionRegistry.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, const {'formatVersion', 'actions'});
    if (json['formatVersion'] != 1) {
      throw FormatException(
        'Unsupported action registry formatVersion: ${json['formatVersion']}',
      );
    }
    final rawActions = json['actions'];
    if (rawActions is! List) {
      throw const FormatException('actions must be a JSON list');
    }
    return AuthoringActionRegistry(
      rawActions.map((rawAction) {
        if (rawAction is! Map) {
          throw const FormatException('action must be a JSON object');
        }
        return AuthoringActionDescriptor.fromJson(
          Map<String, dynamic>.from(rawAction),
        );
      }),
    );
  }

  final List<AuthoringActionDescriptor> actions;
  late final Map<String, AuthoringActionDescriptor> _byId;

  AuthoringActionDescriptor? find(String actionId) => _byId[actionId];

  AuthoringActionDescriptor require(String actionId) {
    return find(actionId) ?? (throw UnknownAuthoringActionException(actionId));
  }

  Map<String, Object?> toJson() {
    return {
      'formatVersion': 1,
      'actions':
          actions.map((action) => action.toJson()).toList(growable: false),
    };
  }

  static List<AuthoringActionDescriptor> _validateAndSort(
    Iterable<AuthoringActionDescriptor> descriptors,
  ) {
    final byId = <String, AuthoringActionDescriptor>{};
    for (final descriptor in descriptors) {
      final existing = byId[descriptor.id];
      if (existing != null) {
        if (existing.version == descriptor.version) {
          throw DuplicateAuthoringActionException(
            descriptor.id,
            descriptor.version,
          );
        }
        throw IncompatibleAuthoringActionVersionException(
          descriptor.id,
          [existing.version, descriptor.version],
        );
      }
      byId[descriptor.id] = descriptor;
    }
    final sorted = byId.values.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    return List.unmodifiable(sorted);
  }
}
~~~~~~~~

## `packages/map_authoring/lib/src/registry/resource_kind_registry.dart`

~~~~~~~~dart
import '../contracts/json_contract_support.dart';

/// Public description of one resource kind accepted by authoring contracts.
final class AuthoringResourceKindDescriptor {
  AuthoringResourceKindDescriptor({
    required String id,
    required int version,
    required String displayName,
    required String summary,
    Map<String, Object?> extensions = const {},
  })  : id = _nonBlank(id, 'id'),
        version = _positiveVersion(version),
        displayName = _nonBlank(displayName, 'displayName'),
        summary = _nonBlank(summary, 'summary'),
        extensions = validateContractExtensions(
          extensions,
          reservedKeys: _reservedKeys,
        );

  factory AuthoringResourceKindDescriptor.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _reservedKeys);
    try {
      return AuthoringResourceKindDescriptor(
        id: requireContractString(json['id'], 'id'),
        version: requirePositiveContractVersion(json['version'], 'version'),
        displayName: requireContractString(json['displayName'], 'displayName'),
        summary: requireContractString(json['summary'], 'summary'),
        extensions: readContractExtensions(
          json['extensions'],
          reservedKeys: _reservedKeys,
        ),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  static const Set<String> _reservedKeys = {
    'id',
    'version',
    'displayName',
    'summary',
    'extensions',
  };

  final String id;
  final int version;
  final String displayName;
  final String summary;
  final Map<String, Object?> extensions;

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'id': id,
      'version': version,
      'displayName': displayName,
      'summary': summary,
    };
    writeContractExtensions(json, extensions);
    return json;
  }
}

final class DuplicateAuthoringResourceKindException implements Exception {
  const DuplicateAuthoringResourceKindException(this.kindId, this.version);

  final String kindId;
  final int version;

  @override
  String toString() => 'Duplicate authoring resource kind: $kindId v$version';
}

final class IncompatibleAuthoringResourceKindVersionException
    implements Exception {
  IncompatibleAuthoringResourceKindVersionException(
    this.kindId,
    Iterable<int> versions,
  ) : versions = List.unmodifiable(versions.toSet().toList()..sort());

  final String kindId;
  final List<int> versions;

  @override
  String toString() {
    return 'Incompatible resource kind versions for $kindId: '
        '${versions.join(', ')}';
  }
}

final class UnknownAuthoringResourceKindException implements Exception {
  const UnknownAuthoringResourceKindException(this.kindId);

  final String kindId;

  @override
  String toString() => 'Unknown authoring resource kind: $kindId';
}

/// Immutable registry of resource kinds, sorted by stable identifier.
final class AuthoringResourceKindRegistry {
  AuthoringResourceKindRegistry(
    Iterable<AuthoringResourceKindDescriptor> descriptors,
  ) : resourceKinds = _validateAndSort(descriptors) {
    _byId = Map.unmodifiable({
      for (final descriptor in resourceKinds) descriptor.id: descriptor,
    });
  }

  factory AuthoringResourceKindRegistry.canonicalMinimal() {
    return AuthoringResourceKindRegistry([
      AuthoringResourceKindDescriptor(
        id: 'project',
        version: 1,
        displayName: 'Project',
        summary: 'PokeMap project manifest and project-owned content',
      ),
      AuthoringResourceKindDescriptor(
        id: 'map',
        version: 1,
        displayName: 'Map',
        summary: 'Editable PokeMap map',
      ),
      AuthoringResourceKindDescriptor(
        id: 'layer',
        version: 1,
        displayName: 'Layer',
        summary: 'Ordered layer owned by a map',
      ),
      AuthoringResourceKindDescriptor(
        id: 'region',
        version: 1,
        displayName: 'Region',
        summary: 'Named or bounded spatial region in a map',
      ),
    ]);
  }

  factory AuthoringResourceKindRegistry.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, const {'formatVersion', 'resourceKinds'});
    if (json['formatVersion'] != 1) {
      throw FormatException(
        'Unsupported resource registry formatVersion: '
        '${json['formatVersion']}',
      );
    }
    final rawKinds = json['resourceKinds'];
    if (rawKinds is! List) {
      throw const FormatException('resourceKinds must be a JSON list');
    }
    return AuthoringResourceKindRegistry(
      rawKinds.map((rawKind) {
        if (rawKind is! Map) {
          throw const FormatException('resource kind must be a JSON object');
        }
        return AuthoringResourceKindDescriptor.fromJson(
          Map<String, dynamic>.from(rawKind),
        );
      }),
    );
  }

  final List<AuthoringResourceKindDescriptor> resourceKinds;
  late final Map<String, AuthoringResourceKindDescriptor> _byId;

  AuthoringResourceKindDescriptor? find(String kindId) => _byId[kindId];

  AuthoringResourceKindDescriptor require(String kindId) {
    return find(kindId) ??
        (throw UnknownAuthoringResourceKindException(kindId));
  }

  Map<String, Object?> toJson() {
    return {
      'formatVersion': 1,
      'resourceKinds': resourceKinds
          .map((descriptor) => descriptor.toJson())
          .toList(growable: false),
    };
  }

  static List<AuthoringResourceKindDescriptor> _validateAndSort(
    Iterable<AuthoringResourceKindDescriptor> descriptors,
  ) {
    final byId = <String, AuthoringResourceKindDescriptor>{};
    for (final descriptor in descriptors) {
      final existing = byId[descriptor.id];
      if (existing != null) {
        if (existing.version == descriptor.version) {
          throw DuplicateAuthoringResourceKindException(
            descriptor.id,
            descriptor.version,
          );
        }
        throw IncompatibleAuthoringResourceKindVersionException(
          descriptor.id,
          [existing.version, descriptor.version],
        );
      }
      byId[descriptor.id] = descriptor;
    }
    final sorted = byId.values.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    return List.unmodifiable(sorted);
  }
}

String _nonBlank(String value, String field) {
  try {
    return requireContractString(value, field);
  } on FormatException catch (error) {
    throw ArgumentError.value(value, field, error.message);
  }
}

int _positiveVersion(int value) {
  try {
    return requirePositiveContractVersion(value, 'version');
  } on FormatException catch (error) {
    throw ArgumentError.value(value, 'version', error.message);
  }
}
~~~~~~~~

## `packages/map_authoring/lib/src/tooling/registry_documentation.dart`

~~~~~~~~dart
import '../contracts/action_descriptor.dart';
import '../registry/action_registry.dart';
import '../registry/resource_kind_registry.dart';

/// Deterministic Markdown documentation for the public authoring registry.
abstract final class AuthoringRegistryDocumentation {
  static String render({
    required AuthoringActionRegistry actions,
    required AuthoringResourceKindRegistry resourceKinds,
  }) {
    final buffer = StringBuffer()
      ..writeln('# PokeMap Authoring API registry')
      ..writeln()
      ..writeln(
        '> Generated from canonical registries. No timestamp is included so '
        'equivalent registries produce identical bytes.',
      )
      ..writeln()
      ..writeln('## Resource kinds')
      ..writeln()
      ..writeln('| ID | Version | Name | Summary |')
      ..writeln('|---|---:|---|---|');

    for (final descriptor in resourceKinds.resourceKinds) {
      buffer.writeln(
        '| `${_escape(descriptor.id)}` | ${descriptor.version} | '
        '${_escape(descriptor.displayName)} | ${_escape(descriptor.summary)} |',
      );
    }

    buffer
      ..writeln()
      ..writeln('## Actions')
      ..writeln()
      ..writeln(
        '| ID | Version | Risk | Summary | Resources | Permissions | '
        'Guarantees | Input schema | Output schema | Capabilities |',
      )
      ..writeln('|---|---:|---|---|---|---|---|---|---|---|');

    for (final descriptor in actions.actions) {
      buffer.writeln(_actionRow(descriptor));
    }
    return buffer.toString();
  }
}

String _actionRow(AuthoringActionDescriptor descriptor) {
  return '| `${_escape(descriptor.id)}` '
      '| ${descriptor.version} '
      '| `${descriptor.riskLevel.wireName}` '
      '| ${_escape(descriptor.summary)} '
      '| ${_codeList(descriptor.resourceKinds)} '
      '| ${_codeList(
    descriptor.requiredPermissions
        .map((permission) => permission.wireName)
        .toList(),
  )} '
      '| ${_codeList(
    descriptor.guarantees.map((guarantee) => guarantee.wireName).toList(),
  )} '
      '| `${_escape(descriptor.inputSchemaId)}` '
      '| `${_escape(descriptor.outputSchemaId)}` '
      '| ${_codeList(descriptor.capabilityIds)} |';
}

String _codeList(List<String> values) {
  if (values.isEmpty) return '—';
  return values.map((value) => '`${_escape(value)}`').join('<br>');
}

String _escape(String value) {
  return value.replaceAll('|', r'\|').replaceAll('\n', '<br>');
}
~~~~~~~~

## `packages/map_authoring/pubspec.yaml`

~~~~~~~~yaml
name: map_authoring
description: >-
  Canonical pure-Dart authoring contracts and orchestration for PokeMap.
version: 0.1.0
publish_to: none

environment:
  sdk: '>=3.4.0 <4.0.0'

dependencies:
  map_core:
    path: ../map_core

dev_dependencies:
  lints: ^3.0.0
  test: ^1.24.0
~~~~~~~~

## `packages/map_authoring/test/contract_kit/authoring_action_contract.dart`

~~~~~~~~dart
import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

/// Reusable assertions for every future action adapter contract test.
abstract final class AuthoringActionContractKit {
  static void expectWellFormed({
    required AuthoringRequest request,
    required AuthoringResult result,
  }) {
    expect(result.requestId, request.requestId);
    if (result.status == AuthoringResultStatus.success) {
      expect(result.error, isNull);
      final receipt = result.receipt;
      if (receipt != null) {
        expect(receipt.requestId, request.requestId);
        expect(receipt.actionId, request.actionId);
        expect(receipt.actionVersion, request.actionVersion);
        expect(
          receipt.status,
          request.dryRun
              ? AuthoringReceiptStatus.planned
              : AuthoringReceiptStatus.applied,
        );
      }
    } else {
      expect(result.error, isNotNull);
      expect(result.receipt, isNull);
    }
  }
}

/// In-memory fixture that proves the common dry-run and idempotency contract.
///
/// It is intentionally test-only. Real persistence and durable idempotency
/// belong to PMCP-021 and must not be implied by this fixture.
final class FakeAuthoringActionRepository {
  final Map<String, AuthoringResult> _appliedByIdempotencyKey = {};

  int value = 0;
  int applyCount = 0;

  AuthoringResult execute(AuthoringRequest request) {
    final amount = request.parameters['amount'];
    if (amount is! int) {
      return AuthoringResult.failure(
        requestId: request.requestId,
        error: AuthoringError(
          code: AuthoringErrorCode.validationFailed,
          message: 'amount must be an integer',
          retryable: false,
          fieldPath: r'$.parameters.amount',
        ),
      );
    }

    if (!request.dryRun) {
      final idempotencyKey = request.idempotencyKey;
      if (idempotencyKey != null) {
        final previous = _appliedByIdempotencyKey[idempotencyKey];
        if (previous != null) return previous;
      }
    }

    final before = value;
    final after = before + amount;
    if (!request.dryRun) {
      value = after;
      applyCount++;
    }

    final status = request.dryRun
        ? AuthoringReceiptStatus.planned
        : AuthoringReceiptStatus.applied;
    final result = AuthoringResult.success(
      requestId: request.requestId,
      data: {
        'value': after,
        'mutated': !request.dryRun,
      },
      receipt: AuthoringReceipt(
        receiptId: 'receipt-${request.requestId}',
        requestId: request.requestId,
        actionId: request.actionId,
        actionVersion: request.actionVersion,
        status: status,
        beforeRevision: 'rev-$before',
        afterRevision: request.dryRun ? 'rev-$before' : 'rev-$after',
        createdAtUtc: '2026-07-31T00:00:00.000Z',
        diff: AuthoringDiff([
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.replace,
            resource: AuthoringResourceRef(
              kind: 'project',
              id: 'fixture',
            ),
            path: r'$.value',
            before: before,
            after: after,
          ),
        ]),
      ),
    );

    final idempotencyKey = request.idempotencyKey;
    if (!request.dryRun && idempotencyKey != null) {
      _appliedByIdempotencyKey[idempotencyKey] = result;
    }
    return result;
  }
}
~~~~~~~~

## `packages/map_authoring/test/contract_kit/authoring_action_contract_test.dart`

~~~~~~~~dart
import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import 'authoring_action_contract.dart';

void main() {
  group('FakeAuthoringActionRepository', () {
    test('dry-run returns a plan without mutating state', () {
      final repository = FakeAuthoringActionRepository();
      final request = _request(
        requestId: 'req-plan',
        idempotencyKey: 'idem-plan',
        dryRun: true,
      );

      final result = repository.execute(request);

      AuthoringActionContractKit.expectWellFormed(
        request: request,
        result: result,
      );
      expect(repository.value, 0);
      expect(repository.applyCount, 0);
      expect(result.receipt?.status, AuthoringReceiptStatus.planned);
    });

    test('apply mutates exactly once and returns an applied receipt', () {
      final repository = FakeAuthoringActionRepository();
      final request = _request(
        requestId: 'req-apply',
        idempotencyKey: 'idem-apply',
        dryRun: false,
      );

      final result = repository.execute(request);

      AuthoringActionContractKit.expectWellFormed(
        request: request,
        result: result,
      );
      expect(repository.value, 1);
      expect(repository.applyCount, 1);
      expect(result.receipt?.status, AuthoringReceiptStatus.applied);
    });

    test('retry with the same idempotency key reuses the first result', () {
      final repository = FakeAuthoringActionRepository();
      final firstRequest = _request(
        requestId: 'req-first',
        idempotencyKey: 'idem-shared',
        dryRun: false,
      );
      final retryRequest = _request(
        requestId: 'req-retry',
        idempotencyKey: 'idem-shared',
        dryRun: false,
      );

      final first = repository.execute(firstRequest);
      final retry = repository.execute(retryRequest);

      expect(retry.toJson(), first.toJson());
      expect(repository.value, 1);
      expect(repository.applyCount, 1);
    });
  });
}

AuthoringRequest _request({
  required String requestId,
  required String idempotencyKey,
  required bool dryRun,
}) {
  return AuthoringRequest(
    requestId: requestId,
    actionId: 'fixture.increment',
    actionVersion: 1,
    workspaceHandle: 'workspace:fixture',
    parameters: const {'amount': 1},
    expectedRevision: 'rev-0',
    idempotencyKey: idempotencyKey,
    dryRun: dryRun,
  );
}
~~~~~~~~

## `packages/map_authoring/test/contracts/descriptor_json_test.dart`

~~~~~~~~dart
import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  group('AuthoringResourceRef', () {
    test('round-trips a typed resource reference', () {
      final reference = AuthoringResourceRef(
        kind: 'map',
        id: 'bourg-palette',
        revision: 'rev-42',
        extensions: const {
          'vendorHint': {
            'labels': ['outdoor', 'starter'],
          },
        },
      );

      expect(
        AuthoringResourceRef.fromJson(_jsonRoundTrip(reference.toJson()))
            .toJson(),
        reference.toJson(),
      );
      expect(reference.toJson()['kind'], 'map');
    });

    test('rejects malformed identifiers and unknown top-level fields', () {
      expect(
        () => AuthoringResourceRef(kind: '', id: 'map-1'),
        throwsArgumentError,
      );
      expect(
        () => AuthoringResourceRef(kind: 'map', id: ' '),
        throwsArgumentError,
      );
      expect(
        () => AuthoringResourceRef.fromJson({
          'kind': 'map',
          'id': 'map-1',
          'futureField': true,
        }),
        throwsFormatException,
      );
    });
  });

  group('authoring descriptors', () {
    test('round-trips schema and capability descriptors', () {
      final schema = AuthoringSchemaDescriptor(
        id: 'schema.map.create.input',
        version: 1,
        uri: 'pokemap-schema://map/create/input/v1',
        sha256: 'sha256:fixture',
        description: 'Create-map input',
        extensions: const {'vendorRevision': 2},
      );
      final capability = AuthoringCapabilityDescriptor(
        id: 'map.lifecycle',
        version: 1,
        summary: 'Create and manage maps',
        resourceKinds: const ['map', 'project'],
        actionIds: const ['map.inspect', 'map.create'],
        extensions: const {'stability': 'experimental'},
      );

      expect(
        AuthoringSchemaDescriptor.fromJson(
          _jsonRoundTrip(schema.toJson()),
        ).toJson(),
        schema.toJson(),
      );
      expect(
        AuthoringCapabilityDescriptor.fromJson(
          _jsonRoundTrip(capability.toJson()),
        ).toJson(),
        capability.toJson(),
      );
      expect(
        capability.toJson()['resourceKinds'],
        ['map', 'project'],
      );
      expect(
        capability.toJson()['actionIds'],
        ['map.create', 'map.inspect'],
      );
    });

    test('round-trips action risk, permissions, and guarantees', () {
      final descriptor = _actionDescriptor();
      final decoded = AuthoringActionDescriptor.fromJson(
        _jsonRoundTrip(descriptor.toJson()),
      );

      expect(decoded.toJson(), descriptor.toJson());
      expect(decoded.riskLevel, AuthoringRiskLevel.high);
      expect(
        decoded.requiredPermissions,
        [
          AuthoringPermission.projectRead,
          AuthoringPermission.projectWrite,
        ],
      );
      expect(
        decoded.guarantees,
        [
          AuthoringGuarantee.dryRun,
          AuthoringGuarantee.idempotent,
          AuthoringGuarantee.revisionChecked,
        ],
      );
    });

    test('preserves safe extension data through JSON', () {
      final descriptor = _actionDescriptor(
        extensions: const {
          'vendor': {
            'priority': 3,
            'flags': [true, false],
          },
        },
      );

      final decoded = AuthoringActionDescriptor.fromJson(
        _jsonRoundTrip(descriptor.toJson()),
      );

      expect(decoded.extensions, descriptor.extensions);
      expect(
        decoded.toJson()['extensions'],
        descriptor.toJson()['extensions'],
      );
    });

    test('rejects reserved extension collisions for every descriptor', () {
      expect(
        () => AuthoringResourceRef(
          kind: 'map',
          id: 'map-1',
          extensions: const {'id': 'override'},
        ),
        throwsArgumentError,
      );
      expect(
        () => AuthoringSchemaDescriptor(
          id: 'schema.map',
          version: 1,
          uri: 'pokemap-schema://map/v1',
          sha256: 'sha256:fixture',
          extensions: const {'version': 9},
        ),
        throwsArgumentError,
      );
      expect(
        () => _actionDescriptor(
          extensions: const {'riskLevel': 'read_only'},
        ),
        throwsArgumentError,
      );
    });

    test('rejects invalid versions, enums, and unknown fields', () {
      expect(
        () => AuthoringSchemaDescriptor(
          id: 'schema.map',
          version: 0,
          uri: 'pokemap-schema://map/v1',
          sha256: 'sha256:fixture',
        ),
        throwsArgumentError,
      );
      final invalidEnum = _actionDescriptor().toJson()
        ..['riskLevel'] = 'impossibly_safe';
      expect(
        () => AuthoringActionDescriptor.fromJson(invalidEnum),
        throwsFormatException,
      );
      final unknownField = _actionDescriptor().toJson()..['surprise'] = true;
      expect(
        () => AuthoringActionDescriptor.fromJson(unknownField),
        throwsFormatException,
      );
      expect(
        () => AuthoringActionDescriptor(
          id: 'map create',
          version: 1,
          summary: 'Invalid action id',
          inputSchemaId: 'schema.map.create.input',
          outputSchemaId: 'schema.map.create.output',
          riskLevel: AuthoringRiskLevel.low,
        ),
        throwsArgumentError,
      );
    });

    test('exposes immutable and deterministically ordered collections', () {
      final descriptor = _actionDescriptor();

      expect(
        () => descriptor.resourceKinds.add('region'),
        throwsUnsupportedError,
      );
      expect(
        () => descriptor.extensions['new'] = true,
        throwsUnsupportedError,
      );
      expect(
        AuthoringActionDescriptor(
          id: descriptor.id,
          version: descriptor.version,
          summary: descriptor.summary,
          inputSchemaId: descriptor.inputSchemaId,
          outputSchemaId: descriptor.outputSchemaId,
          riskLevel: descriptor.riskLevel,
          resourceKinds: descriptor.resourceKinds.reversed,
          capabilityIds: descriptor.capabilityIds.reversed,
          requiredPermissions: descriptor.requiredPermissions.reversed,
          guarantees: descriptor.guarantees.reversed,
        ).toJson(),
        descriptor.toJson()..remove('extensions'),
      );
    });
  });
}

AuthoringActionDescriptor _actionDescriptor({
  Map<String, Object?> extensions = const {},
}) {
  return AuthoringActionDescriptor(
    id: 'map.create',
    version: 1,
    summary: 'Create a map',
    inputSchemaId: 'schema.map.create.input',
    outputSchemaId: 'schema.map.create.output',
    riskLevel: AuthoringRiskLevel.high,
    resourceKinds: const ['project', 'map'],
    capabilityIds: const ['map.lifecycle'],
    requiredPermissions: const [
      AuthoringPermission.projectWrite,
      AuthoringPermission.projectRead,
    ],
    guarantees: const [
      AuthoringGuarantee.revisionChecked,
      AuthoringGuarantee.idempotent,
      AuthoringGuarantee.dryRun,
    ],
    extensions: extensions,
  );
}

Map<String, dynamic> _jsonRoundTrip(Map<String, Object?> value) {
  return jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
}
~~~~~~~~

## `packages/map_authoring/test/contracts/envelope_json_test.dart`

~~~~~~~~dart
import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  group('AuthoringRequest', () {
    test('round-trips revision, idempotency, dry-run, and parameters', () {
      final request = AuthoringRequest(
        requestId: 'req-001',
        actionId: 'map.create',
        actionVersion: 1,
        workspaceHandle: 'workspace:demo',
        parameters: const {
          'name': 'Bourg Palette',
          'size': {'width': 32, 'height': 24},
        },
        expectedRevision: 'rev-10',
        idempotencyKey: 'idem-001',
        dryRun: true,
        extensions: const {'traceLabel': 'golden-map'},
      );

      final decoded = AuthoringRequest.fromJson(_roundTrip(request.toJson()));

      expect(decoded.toJson(), request.toJson());
      expect(decoded.dryRun, isTrue);
      expect(decoded.expectedRevision, 'rev-10');
      expect(
        () => decoded.parameters['other'] = true,
        throwsUnsupportedError,
      );
    });

    test('rejects invalid versions and unknown top-level fields', () {
      expect(
        () => AuthoringRequest(
          requestId: 'req',
          actionId: 'map.create',
          actionVersion: 0,
          workspaceHandle: 'workspace:demo',
        ),
        throwsArgumentError,
      );
      expect(
        () => AuthoringRequest.fromJson({
          ..._request().toJson(),
          'unknown': true,
        }),
        throwsFormatException,
      );
    });
  });

  group('AuthoringError', () {
    test('round-trips structured remediation without unsafe diagnostics', () {
      final error = AuthoringError(
        code: AuthoringErrorCode.revisionConflict,
        message: 'The project revision changed',
        retryable: true,
        fieldPath: r'$.expectedRevision',
        remediation: const [
          'Reload the project snapshot',
          'Plan the action again',
        ],
        details: const {
          'expected': 'rev-10',
          'actual': 'rev-11',
        },
      );

      expect(
        AuthoringError.fromJson(_roundTrip(error.toJson())).toJson(),
        error.toJson(),
      );
    });

    test('rejects stack traces and machine-local paths', () {
      expect(
        () => AuthoringError(
          code: AuthoringErrorCode.internal,
          message: 'Failure in /Users/alice/project/file.dart',
          retryable: false,
        ),
        throwsArgumentError,
      );
      expect(
        () => AuthoringError(
          code: AuthoringErrorCode.internal,
          message: 'Internal failure',
          retryable: false,
          details: const {
            'stackTrace': '#0 privateFunction (file.dart:12)',
          },
        ),
        throwsArgumentError,
      );
      expect(
        () => AuthoringError(
          code: AuthoringErrorCode.internal,
          message: r'Failure in C:\Users\alice\project\file.dart',
          retryable: false,
        ),
        throwsArgumentError,
      );
      expect(
        () => AuthoringError(
          code: AuthoringErrorCode.internal,
          message: 'Failure in /workspace/private/file.dart',
          retryable: false,
        ),
        throwsArgumentError,
      );
      expect(
        () => AuthoringError(
          code: AuthoringErrorCode.internal,
          message: 'Internal failure',
          retryable: false,
          details: const {'trace': '#0 privateFunction (file.dart:12)'},
        ),
        throwsArgumentError,
      );
      expect(
        () => AuthoringError(
          code: AuthoringErrorCode.internal,
          message: '#0 privateFunction (file.dart:12)',
          retryable: false,
        ),
        throwsArgumentError,
      );
    });
  });

  group('AuthoringDiff and AuthoringReceipt', () {
    test('sorts changes and derives stable affected resources', () {
      final mapRef = AuthoringResourceRef(kind: 'map', id: 'map-1');
      final layerRef = AuthoringResourceRef(kind: 'layer', id: 'layer-1');
      final diff = AuthoringDiff([
        AuthoringDiffEntry(
          operation: AuthoringDiffOperation.replace,
          resource: mapRef,
          path: r'$.name',
          before: 'Old',
          after: 'New',
        ),
        AuthoringDiffEntry(
          operation: AuthoringDiffOperation.add,
          resource: layerRef,
          path: r'$.layers[0]',
          after: const {'id': 'layer-1'},
        ),
        AuthoringDiffEntry(
          operation: AuthoringDiffOperation.replace,
          resource: mapRef,
          path: r'$.size.width',
          before: 16,
          after: 32,
        ),
      ]);

      expect(
        diff.entries.map((entry) => '${entry.resource.kind}:${entry.path}'),
        [
          r'layer:$.layers[0]',
          r'map:$.name',
          r'map:$.size.width',
        ],
      );
      expect(
        diff.affectedResources.map((reference) => reference.kind),
        ['layer', 'map'],
      );
      expect(
        AuthoringDiff.fromJson(_roundTrip(diff.toJson())).toJson(),
        diff.toJson(),
      );
    });

    test('preserves explicit null values in structured changes', () {
      final resource = AuthoringResourceRef(kind: 'map', id: 'map-1');
      final diff = AuthoringDiff([
        AuthoringDiffEntry(
          operation: AuthoringDiffOperation.add,
          resource: resource,
          path: r'$.nullableValue',
          after: null,
        ),
        AuthoringDiffEntry(
          operation: AuthoringDiffOperation.remove,
          resource: resource,
          path: r'$.oldNullableValue',
          before: null,
        ),
      ]);

      expect(diff.entries.first.toJson(), containsPair('after', null));
      expect(diff.entries.last.toJson(), containsPair('before', null));
      expect(
        AuthoringDiff.fromJson(_roundTrip(diff.toJson())).toJson(),
        diff.toJson(),
      );
    });

    test('round-trips receipts and compact artifact links', () {
      final artifact = AuthoringArtifactRef(
        id: 'artifact-preview-1',
        mediaType: 'image/png',
        uri: 'artifact://preview/map-1',
        byteLength: 1200,
        sha256: 'sha256:fixture',
      );
      final receipt = AuthoringReceipt(
        receiptId: 'receipt-1',
        requestId: 'req-001',
        actionId: 'map.create',
        actionVersion: 1,
        status: AuthoringReceiptStatus.planned,
        beforeRevision: 'rev-10',
        afterRevision: 'rev-10',
        createdAtUtc: '2026-07-31T08:00:00.000Z',
        diff: AuthoringDiff([
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.add,
            resource: AuthoringResourceRef(kind: 'map', id: 'map-1'),
            path: r'$',
            after: const {'id': 'map-1'},
          ),
        ]),
        artifacts: [artifact],
      );

      expect(
        AuthoringReceipt.fromJson(_roundTrip(receipt.toJson())).toJson(),
        receipt.toJson(),
      );
      expect(artifact.toJson().keys, {
        'id',
        'mediaType',
        'uri',
        'byteLength',
        'sha256',
      });
      expect(
        () => AuthoringArtifactRef(
          id: 'unsafe',
          mediaType: 'text/plain',
          uri: 'file:///Users/alice/private.txt',
        ),
        throwsArgumentError,
      );
    });

    test(
        'decoding malformed receipt values consistently throws FormatException',
        () {
      final malformed = _receipt().toJson()
        ..['createdAtUtc'] = 'not-a-timestamp';

      expect(
        () => AuthoringReceipt.fromJson(malformed),
        throwsFormatException,
      );
    });
  });

  group('AuthoringResult', () {
    test('round-trips successful data, receipt, and artifact links', () {
      final result = AuthoringResult.success(
        requestId: 'req-001',
        data: const {'planned': true},
        receipt: _receipt(),
        artifacts: [
          AuthoringArtifactRef(
            id: 'artifact-1',
            mediaType: 'application/json',
            uri: 'artifact://diff/receipt-1',
          ),
        ],
        extensions: const {'transportHint': 'inline'},
      );

      final decoded = AuthoringResult.fromJson(_roundTrip(result.toJson()));

      expect(decoded.toJson(), result.toJson());
      expect(decoded.status, AuthoringResultStatus.success);
      expect(decoded.error, isNull);
    });

    test('round-trips a structured failure', () {
      final result = AuthoringResult.failure(
        requestId: 'req-002',
        error: AuthoringError(
          code: AuthoringErrorCode.permissionDenied,
          message: 'Project write permission is required',
          retryable: false,
          remediation: const ['Request project.write permission'],
        ),
      );

      final decoded = AuthoringResult.fromJson(_roundTrip(result.toJson()));

      expect(decoded.toJson(), result.toJson());
      expect(decoded.status, AuthoringResultStatus.failure);
      expect(decoded.error?.code, AuthoringErrorCode.permissionDenied);
    });

    test('rejects contradictory success and failure states', () {
      expect(
        () => AuthoringResult(
          requestId: 'req',
          status: AuthoringResultStatus.success,
          error: AuthoringError(
            code: AuthoringErrorCode.internal,
            message: 'Safe failure',
            retryable: false,
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => AuthoringResult(
          requestId: 'req',
          status: AuthoringResultStatus.failure,
        ),
        throwsArgumentError,
      );
      expect(
        () => AuthoringResult.fromJson({
          ...AuthoringResult.failure(
            requestId: 'req',
            error: AuthoringError(
              code: AuthoringErrorCode.internal,
              message: 'Safe failure',
              retryable: false,
            ),
          ).toJson(),
          'status': 'future_status',
        }),
        throwsFormatException,
      );
    });
  });
}

AuthoringRequest _request() {
  return AuthoringRequest(
    requestId: 'req',
    actionId: 'map.inspect',
    actionVersion: 1,
    workspaceHandle: 'workspace:demo',
  );
}

AuthoringReceipt _receipt() {
  return AuthoringReceipt(
    receiptId: 'receipt-1',
    requestId: 'req-001',
    actionId: 'map.create',
    actionVersion: 1,
    status: AuthoringReceiptStatus.planned,
    createdAtUtc: '2026-07-31T08:00:00.000Z',
    diff: AuthoringDiff(const []),
  );
}

Map<String, dynamic> _roundTrip(Map<String, Object?> value) {
  return jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
}
~~~~~~~~

## `packages/map_authoring/test/package_boundary_test.dart`

~~~~~~~~dart
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  group('map_authoring package boundary', () {
    test('declares canonical ownership and the only allowed dependency', () {
      expect(MapAuthoringPackageBoundaries.packageName, 'map_authoring');
      expect(
        MapAuthoringPackageBoundaries.allowedPackageDependencies,
        {'map_core'},
      );
      expect(
        MapAuthoringPackageBoundaries.ownedResponsibilities,
        containsAll({
          'authoring contracts',
          'authoring orchestration',
          'action registry',
        }),
      );
      expect(
        MapAuthoringPackageBoundaries.platformAdapterOwners,
        {
          'editor': 'map_editor',
          'runtime': 'map_runtime',
          'mcp': 'tools/pokemap_mcp',
        },
      );
    });

    test('contains no Flutter, Flame, editor, or runtime package imports', () {
      final forbiddenImports = <String>{
        'package:flutter/',
        'package:flame/',
        'package:map_editor/',
        'package:map_runtime/',
      };
      final violations = <String>[];

      for (final file in _dartFiles(Directory('lib'))) {
        final source = file.readAsStringSync();
        for (final forbiddenImport in forbiddenImports) {
          if (source.contains(forbiddenImport)) {
            violations.add('${file.path}: $forbiddenImport');
          }
        }
      }

      expect(violations, isEmpty);
    });

    test('pubspec keeps production dependencies limited to map_core', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final dependenciesBlock = RegExp(
        r'^dependencies:\n(?<body>(?:  .+\n?)+)',
        multiLine: true,
      ).firstMatch(pubspec)?.namedGroup('body');

      expect(dependenciesBlock, isNotNull);
      final dependencyNames = RegExp(
        r'^  ([a-zA-Z0-9_]+):',
        multiLine: true,
      ).allMatches(dependenciesBlock!).map((match) => match.group(1)!).toSet();
      expect(dependencyNames, {'map_core'});
      expect(pubspec, isNot(contains('sdk: flutter')));
    });
  });
}

Iterable<File> _dartFiles(Directory directory) {
  return directory
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));
}
~~~~~~~~

## `packages/map_authoring/test/registry/action_registry_test.dart`

~~~~~~~~dart
import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  group('AuthoringActionRegistry', () {
    test('sorts actions independently of registration order', () {
      final first = AuthoringActionRegistry([
        _action('map.update'),
        _action('map.create'),
      ]);
      final second = AuthoringActionRegistry([
        _action('map.create'),
        _action('map.update'),
      ]);

      expect(
        first.actions.map((action) => action.id),
        ['map.create', 'map.update'],
      );
      expect(first.toJson(), second.toJson());
    });

    test('looks up known actions and distinguishes unknown actions', () {
      final registry = AuthoringActionRegistry([_action('map.create')]);

      expect(registry.find('map.create')?.id, 'map.create');
      expect(registry.find('map.unknown'), isNull);
      expect(
        () => registry.require('map.unknown'),
        throwsA(isA<UnknownAuthoringActionException>()),
      );
    });

    test('rejects a duplicate action id and version', () {
      expect(
        () => AuthoringActionRegistry([
          _action('map.create'),
          _action('map.create'),
        ]),
        throwsA(isA<DuplicateAuthoringActionException>()),
      );
    });

    test('rejects incompatible versions for the same action id', () {
      expect(
        () => AuthoringActionRegistry([
          _action('map.create', version: 1),
          _action('map.create', version: 2),
        ]),
        throwsA(
          isA<IncompatibleAuthoringActionVersionException>().having(
            (error) => error.versions,
            'versions',
            [1, 2],
          ),
        ),
      );
    });

    test('round-trips deterministically through JSON', () {
      final registry = AuthoringActionRegistry([
        _action('map.update'),
        _action('map.create'),
      ]);
      final encoded =
          jsonDecode(jsonEncode(registry.toJson())) as Map<String, dynamic>;

      expect(
        AuthoringActionRegistry.fromJson(encoded).toJson(),
        registry.toJson(),
      );
    });
  });

  group('AuthoringResourceKindRegistry', () {
    test('provides the canonical minimal resource kinds', () {
      final registry = AuthoringResourceKindRegistry.canonicalMinimal();

      expect(
        registry.resourceKinds.map((descriptor) => descriptor.id),
        ['layer', 'map', 'project', 'region'],
      );
      expect(registry.require('map').displayName, 'Map');
      expect(registry.find('unknown'), isNull);
    });

    test('rejects duplicate and incompatible kind versions', () {
      expect(
        () => AuthoringResourceKindRegistry([
          _kind('map'),
          _kind('map'),
        ]),
        throwsA(isA<DuplicateAuthoringResourceKindException>()),
      );
      expect(
        () => AuthoringResourceKindRegistry([
          _kind('map', version: 1),
          _kind('map', version: 2),
        ]),
        throwsA(isA<IncompatibleAuthoringResourceKindVersionException>()),
      );
    });

    test('round-trips deterministically through JSON', () {
      final registry = AuthoringResourceKindRegistry([
        _kind('region'),
        _kind('map'),
      ]);
      final encoded =
          jsonDecode(jsonEncode(registry.toJson())) as Map<String, dynamic>;

      expect(
        AuthoringResourceKindRegistry.fromJson(encoded).toJson(),
        registry.toJson(),
      );
    });
  });
}

AuthoringActionDescriptor _action(String id, {int version = 1}) {
  return AuthoringActionDescriptor(
    id: id,
    version: version,
    summary: 'Action $id',
    inputSchemaId: 'schema.$id.input',
    outputSchemaId: 'schema.$id.output',
    riskLevel: AuthoringRiskLevel.readOnly,
    resourceKinds: const ['map'],
    requiredPermissions: const [AuthoringPermission.projectRead],
  );
}

AuthoringResourceKindDescriptor _kind(String id, {int version = 1}) {
  return AuthoringResourceKindDescriptor(
    id: id,
    version: version,
    displayName: id[0].toUpperCase() + id.substring(1),
    summary: '$id resource',
  );
}
~~~~~~~~

## `packages/map_authoring/test/tooling/registry_documentation_test.dart`

~~~~~~~~dart
import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  group('AuthoringRegistryDocumentation', () {
    test('renders deterministic documentation for equivalent registries', () {
      final first = AuthoringActionRegistry([
        _action('map.update'),
        _action('map.create'),
      ]);
      final second = AuthoringActionRegistry([
        _action('map.create'),
        _action('map.update'),
      ]);
      final resourceKinds = AuthoringResourceKindRegistry.canonicalMinimal();

      final firstDocument = AuthoringRegistryDocumentation.render(
        actions: first,
        resourceKinds: resourceKinds,
      );
      final secondDocument = AuthoringRegistryDocumentation.render(
        actions: second,
        resourceKinds: resourceKinds,
      );

      expect(secondDocument, firstDocument);
      expect(firstDocument, startsWith('# PokeMap Authoring API registry\n'));
      expect(firstDocument, contains('## Resource kinds'));
      expect(firstDocument, contains('## Actions'));
      expect(firstDocument, contains('`map.create`'));
      expect(firstDocument, contains('`project.read`'));
      expect(firstDocument, isNot(contains('Generated at')));
    });

    test('escapes Markdown table separators in human-readable text', () {
      final action = AuthoringActionDescriptor(
        id: 'map.inspect',
        version: 1,
        summary: 'Inspect summary | detail',
        inputSchemaId: 'schema.map.inspect.input',
        outputSchemaId: 'schema.map.inspect.output',
        riskLevel: AuthoringRiskLevel.readOnly,
        resourceKinds: const ['map'],
        requiredPermissions: const [AuthoringPermission.projectRead],
      );

      final document = AuthoringRegistryDocumentation.render(
        actions: AuthoringActionRegistry([action]),
        resourceKinds: AuthoringResourceKindRegistry.canonicalMinimal(),
      );

      expect(document, contains(r'Inspect summary \| detail'));
    });
  });
}

AuthoringActionDescriptor _action(String id) {
  return AuthoringActionDescriptor(
    id: id,
    version: 1,
    summary: 'Action $id',
    inputSchemaId: 'schema.$id.input',
    outputSchemaId: 'schema.$id.output',
    riskLevel: AuthoringRiskLevel.readOnly,
    resourceKinds: const ['map'],
    capabilityIds: const ['map.lifecycle'],
    requiredPermissions: const [AuthoringPermission.projectRead],
    guarantees: const [AuthoringGuarantee.dryRun],
  );
}
~~~~~~~~


