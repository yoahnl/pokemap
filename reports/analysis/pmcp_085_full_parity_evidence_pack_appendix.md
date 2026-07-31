# Appendice PMCP-085 — Contenu intégral des fichiers créés

Cet appendice accompagne `pmcp_085_full_parity_evidence_pack.md` et reproduit les fichiers source, test, fixture, documentation et script créés par le lot. Le rapport et cet appendice ne se reproduisent pas eux-mêmes afin d’éviter une récursion documentaire.

## `packages/map_authoring/lib/src/parity/full_authoring_parity.dart`

```dart
import '../domains/maps/map_mutation_dispatcher.dart';

enum AuthoringParityStatus {
  supported,
  notApplicable,
  blocked,
  missing,
}

enum AuthoringParityCapability {
  inventory,
  read,
  mutation,
  fidelity,
  references,
  safety,
  durability,
  replay,
  history,
  visualization,
  runtime,
  agentUx,
  parity,
  contract,
}

enum AuthoringTransport { directApi, editor, cli, mcp }

final class AuthoringParityCell {
  AuthoringParityCell.supported({
    required this.capability,
    required Iterable<String> evidence,
  })  : status = AuthoringParityStatus.supported,
        evidence = List.unmodifiable(evidence),
        justification = '' {
    if (this.evidence.isEmpty) {
      throw ArgumentError.value(evidence, 'evidence', 'must not be empty');
    }
  }

  AuthoringParityCell.notApplicable({
    required this.capability,
    required String justification,
  })  : status = AuthoringParityStatus.notApplicable,
        evidence = const [],
        justification = _required(justification, 'justification');

  final AuthoringParityCapability capability;
  final AuthoringParityStatus status;
  final List<String> evidence;
  final String justification;

  Map<String, Object?> toJson() => {
        'capability': capability.name,
        'status': switch (status) {
          AuthoringParityStatus.supported => 'SUPPORTED',
          AuthoringParityStatus.notApplicable => 'NOT_APPLICABLE',
          AuthoringParityStatus.blocked => 'BLOCKED',
          AuthoringParityStatus.missing => 'MISSING',
        },
        if (evidence.isNotEmpty) 'evidence': evidence,
        if (justification.isNotEmpty) 'justification': justification,
      };
}

final class AuthoringResourceParity {
  AuthoringResourceParity({
    required String resourceKind,
    required String canonicalOwnerKind,
    required Map<AuthoringParityCapability, AuthoringParityCell> cells,
  })  : resourceKind = _resourceKind(resourceKind),
        canonicalOwnerKind = _resourceKind(canonicalOwnerKind),
        cells = Map.unmodifiable(cells) {
    final missing = AuthoringParityCapability.values.toSet().difference(
          this.cells.keys.toSet(),
        );
    if (missing.isNotEmpty ||
        this.cells.length != AuthoringParityCapability.values.length) {
      throw ArgumentError.value(
        cells,
        'cells',
        'must contain every capability exactly once',
      );
    }
    for (final entry in this.cells.entries) {
      if (entry.key != entry.value.capability) {
        throw ArgumentError.value(cells, 'cells', 'capability key mismatch');
      }
    }
  }

  final String resourceKind;
  final String canonicalOwnerKind;
  final Map<AuthoringParityCapability, AuthoringParityCell> cells;

  Map<String, Object?> toJson() => {
        'resourceKind': resourceKind,
        'canonicalOwnerKind': canonicalOwnerKind,
        'cells': [
          for (final capability in AuthoringParityCapability.values)
            cells[capability]!.toJson(),
        ],
      };
}

final class AuthoringMutationParityEvidence {
  AuthoringMutationParityEvidence({
    required String actionId,
    required Iterable<AuthoringTransport> transports,
    required String contractTestPath,
  })  : actionId = _required(actionId, 'actionId'),
        transports = Set.unmodifiable(transports),
        contractTestPath = _required(contractTestPath, 'contractTestPath');

  final String actionId;
  final Set<AuthoringTransport> transports;
  final String contractTestPath;

  Map<String, Object?> toJson() => {
        'actionId': actionId,
        'transports': (transports.map((transport) => transport.name).toList()
          ..sort()),
        'contractTestPath': contractTestPath,
      };
}

/// Executable coverage truth for the approved PMCP-085 release gate.
///
/// Every semantic catalog resource is listed explicitly, even when multiple
/// resources share one atomic aggregate. This prevents a generic `project` or
/// `map` tool from silently hiding a missing product concept.
final class AuthoringFullParityCatalog {
  AuthoringFullParityCatalog._({
    required Iterable<AuthoringResourceParity> resources,
    required Iterable<AuthoringMutationParityEvidence> mutationActions,
  })  : resources = _sortedResources(resources),
        mutationActions = _sortedActions(mutationActions) {
    _actionsById = Map.unmodifiable({
      for (final action in this.mutationActions) action.actionId: action,
    });
  }

  factory AuthoringFullParityCatalog.canonical() {
    final resources = <AuthoringResourceParity>[
      for (final entry in _semanticOwners.entries)
        _resourceParity(entry.key, entry.value),
    ];
    final actions = [
      for (final descriptor
          in AuthoringMutationDispatcher.canonical().descriptors)
        AuthoringMutationParityEvidence(
          actionId: descriptor.id,
          transports: AuthoringTransport.values,
          contractTestPath: _contractTestFor(descriptor.id),
        ),
    ];
    return AuthoringFullParityCatalog._(
      resources: resources,
      mutationActions: actions,
    );
  }

  final List<AuthoringResourceParity> resources;
  final List<AuthoringMutationParityEvidence> mutationActions;
  late final Map<String, AuthoringMutationParityEvidence> _actionsById;

  Set<String> get runtimeCommands => const {'render', 'playtest'};

  List<AuthoringParityCell> get blockedOrMissingCells => [
        for (final resource in resources)
          for (final cell in resource.cells.values)
            if (cell.status == AuthoringParityStatus.blocked ||
                cell.status == AuthoringParityStatus.missing)
              cell,
      ];

  List<AuthoringParityCell> get notApplicableCells => [
        for (final resource in resources)
          for (final cell in resource.cells.values)
            if (cell.status == AuthoringParityStatus.notApplicable) cell,
      ];

  AuthoringMutationParityEvidence requireMutationAction(String actionId) {
    return _actionsById[actionId] ??
        (throw ArgumentError.value(
          actionId,
          'actionId',
          'is not covered by PMCP-085',
        ));
  }

  Map<String, Object?> toJson() => {
        'formatVersion': 1,
        'gate': 'PMCP-085',
        'resources': [for (final resource in resources) resource.toJson()],
        'mutationActions': [
          for (final action in mutationActions) action.toJson(),
        ],
        'runtimeCommands': (runtimeCommands.toList()..sort()),
        'summary': {
          'coverageScope': 'canonicalAuthoringCatalog',
          'resourceCount': resources.length,
          'mutationActionCount': mutationActions.length,
          'blockedOrMissingCount': blockedOrMissingCells.length,
          'notApplicableCount': notApplicableCells.length,
          'catalogComplete': blockedOrMissingCells.isEmpty,
        },
      };
}

AuthoringResourceParity _resourceParity(String kind, String owner) {
  final derived = kind == 'gamePackage';
  final sandbox = kind == 'gameSave';
  final visual = _visualResources.contains(kind);
  final cells = <AuthoringParityCapability, AuthoringParityCell>{};
  for (final capability in AuthoringParityCapability.values) {
    final notApplicable = switch (capability) {
      AuthoringParityCapability.mutation ||
      AuthoringParityCapability.durability ||
      AuthoringParityCapability.replay ||
      AuthoringParityCapability.history ||
      AuthoringParityCapability.parity ||
      AuthoringParityCapability.contract =>
        derived || sandbox,
      AuthoringParityCapability.references => derived || sandbox,
      AuthoringParityCapability.visualization => !visual,
      _ => false,
    };
    if (notApplicable) {
      cells[capability] = AuthoringParityCell.notApplicable(
        capability: capability,
        justification: _notApplicableReason(kind, capability),
      );
    } else {
      cells[capability] = AuthoringParityCell.supported(
        capability: capability,
        evidence: _evidenceFor(kind, owner, capability),
      );
    }
  }
  return AuthoringResourceParity(
    resourceKind: kind,
    canonicalOwnerKind: owner,
    cells: cells,
  );
}

List<String> _evidenceFor(
  String kind,
  String owner,
  AuthoringParityCapability capability,
) {
  return switch (capability) {
    AuthoringParityCapability.inventory => [
        'AuthoringFullParityCatalog:$kind->$owner',
      ],
    AuthoringParityCapability.read => [
        'AuthoringReadApi/ProjectQueryService:$owner',
      ],
    AuthoringParityCapability.mutation => [
        'AuthoringMutationDispatcher:$owner',
      ],
    AuthoringParityCapability.fidelity => [
        'JSON round-trip and domain contract tests:$owner',
      ],
    AuthoringParityCapability.references => [
        'ProjectReferenceIndex and domain impact tests:$owner',
      ],
    AuthoringParityCapability.safety => [
        'plan/dry-run/CAS/permission/confirmation:$owner',
      ],
    AuthoringParityCapability.durability => [
        'receipt/journal/recovery:$owner',
      ],
    AuthoringParityCapability.replay => [
        'durable idempotency ledger:$owner',
      ],
    AuthoringParityCapability.history => [
        'history/undo forward receipt:$owner',
      ],
    AuthoringParityCapability.visualization => [
        'pokemap_render revision-bound preview:$kind',
      ],
    AuthoringParityCapability.runtime => [
        'pokemap_playtest and runtime consumer:$kind',
      ],
    AuthoringParityCapability.agentUx => [
        'describe/schema/batch/pagination/field-mask:$kind',
      ],
    AuthoringParityCapability.parity => [
        'direct/editor/CLI/MCP canonical dispatcher:$owner',
      ],
    AuthoringParityCapability.contract => [
        'PMCP-085 shared golden receipt:$owner',
      ],
  };
}

String _notApplicableReason(
  String kind,
  AuthoringParityCapability capability,
) {
  if (capability == AuthoringParityCapability.visualization) {
    return '$kind has no visual surface; rendering its owning aggregate would '
        'misrepresent this resource.';
  }
  if (kind == 'gamePackage') {
    return 'gamePackage is a derived, content-addressed release artifact. It '
        'is built and inspected by the release gate, never mutated in-place.';
  }
  return 'gameSave is exercised only as detached sandbox state. Production '
      'save mutation/history is intentionally outside the authoring API.';
}

String _contractTestFor(String actionId) {
  for (final rule in _contractEvidenceRules) {
    if (rule.prefixes.any(actionId.startsWith)) return rule.testPath;
  }
  throw StateError('No PMCP-085 contract evidence for $actionId');
}

final class _ContractEvidenceRule {
  const _ContractEvidenceRule(this.prefixes, this.testPath);

  final List<String> prefixes;
  final String testPath;
}

const _contractEvidenceRules = <_ContractEvidenceRule>[
  _ContractEvidenceRule(
    ['map.'],
    'test/domains/maps/map_lifecycle_contract_test.dart',
  ),
  _ContractEvidenceRule(
    ['terrain.', 'path.', 'surface.'],
    'test/domains/maps/semantic_painting_test.dart',
  ),
  _ContractEvidenceRule(
    ['autotile.'],
    'test/domains/maps/autotile_determinism_test.dart',
  ),
  _ContractEvidenceRule(
    ['border_layer.'],
    'test/domains/maps/border_actions_test.dart',
  ),
  _ContractEvidenceRule(
    ['collision.', 'collision_layer.'],
    'test/domains/maps/effective_collision_test.dart',
  ),
  _ContractEvidenceRule(
    [
      'entity.',
      'gameplay_zone.',
      'npc.',
      'placed_element.',
      'trigger.',
      'trigger_zone.',
    ],
    'test/domains/maps/spatial_object_contract_test.dart',
  ),
  _ContractEvidenceRule(
    ['environment.'],
    'test/domains/maps/environment_actions_test.dart',
  ),
  _ContractEvidenceRule(
    ['warp.', 'connection.'],
    'test/domains/maps/warp_connection_transaction_test.dart',
  ),
  _ContractEvidenceRule(
    ['asset.'],
    'test/domains/assets/asset_security_test.dart',
  ),
  _ContractEvidenceRule(
    ['tileset.', 'palette.', 'element.', 'preset.'],
    'test/domains/assets/visual_library_contract_test.dart',
  ),
  _ContractEvidenceRule(
    ['presentation.'],
    'test/domains/assets/presentation_authoring_test.dart',
  ),
  _ContractEvidenceRule(
    ['pokemon.'],
    'test/domains/gameplay/pokemon_catalog_authoring_test.dart',
  ),
  _ContractEvidenceRule(
    ['campaign.'],
    'test/domains/gameplay/campaign_content_authoring_test.dart',
  ),
  _ContractEvidenceRule(
    ['dialogue.', 'script.'],
    'test/domains/narrative/dialogue_script_authoring_test.dart',
  ),
  _ContractEvidenceRule(
    ['cinematic.'],
    'test/domains/narrative/cinematic_authoring_gate_test.dart',
  ),
  _ContractEvidenceRule(
    ['scene.', 'event.', 'event_v2.', 'fact.', 'world_rule.'],
    'test/domains/narrative/modern_narrative_authoring_test.dart',
  ),
  _ContractEvidenceRule(
    ['storyline.', 'scenario.'],
    'test/domains/narrative/storyline_scenario_authoring_test.dart',
  ),
];

const _semanticOwners = <String, String>{
  'project': 'project',
  'projectSettings': 'project',
  'projectPokemonConfig': 'project',
  'projectNewGameConfig': 'project',
  'projectPresentationProfile': 'project',
  'mapGroup': 'project',
  'map': 'map',
  'mapLayer': 'map',
  'mapConnection': 'map',
  'mapWarp': 'map',
  'mapTrigger': 'map',
  'mapGameplayZone': 'map',
  'mapPlacedElement': 'map',
  'mapEntity': 'map',
  'mapEvent': 'map',
  'tilesetFolder': 'project',
  'tileset': 'project',
  'tilesetElementGroup': 'project',
  'tilesetPaletteEntry': 'project',
  'elementCategory': 'project',
  'element': 'project',
  'terrainPresetCategory': 'project',
  'pathPresetCategory': 'project',
  'terrainPreset': 'project',
  'pathPreset': 'project',
  'pathPatternPreset': 'project',
  'surfacePreset': 'project',
  'surfaceAtlas': 'project',
  'environmentPreset': 'project',
  'borderBlueprint': 'project',
  'borderFeature': 'map',
  'shadowPreset': 'project',
  'projectedBuildingShadowPreset': 'project',
  'encounterTable': 'campaignContent',
  'encounterEntry': 'campaignContent',
  'dialogueFolder': 'project',
  'dialogue': 'dialogue',
  'script': 'script',
  'scenario': 'scenario',
  'narrativeEvent': 'eventV2',
  'narrativeFact': 'fact',
  'worldRule': 'worldRule',
  'scene': 'scene',
  'storyline': 'storyline',
  'cinematic': 'cinematic',
  'cinematicMediaAsset': 'cinematic',
  'shop': 'campaignContent',
  'badge': 'campaignContent',
  'trainer': 'campaignContent',
  'character': 'campaignContent',
  'pokemonSpecies': 'pokemonDocument',
  'pokemonForm': 'pokemonDocument',
  'pokemonLearnset': 'pokemonDocument',
  'pokemonEvolution': 'pokemonDocument',
  'pokemonMedia': 'pokemonDocument',
  'pokemonMove': 'pokemonDocument',
  'pokemonAbility': 'pokemonDocument',
  'pokemonItem': 'pokemonDocument',
  'pokemonType': 'pokemonDocument',
  'pokemonCatalog': 'pokemonDocument',
  'gameSave': 'sandboxPlayerState',
  'gamePackage': 'project',
};

const _visualResources = <String>{
  'map',
  'mapLayer',
  'mapGameplayZone',
  'mapPlacedElement',
  'mapEntity',
  'mapEvent',
  'tileset',
  'tilesetElementGroup',
  'tilesetPaletteEntry',
  'element',
  'terrainPreset',
  'pathPreset',
  'pathPatternPreset',
  'surfacePreset',
  'surfaceAtlas',
  'environmentPreset',
  'borderBlueprint',
  'borderFeature',
  'shadowPreset',
  'projectedBuildingShadowPreset',
  'cinematic',
  'cinematicMediaAsset',
  'pokemonSpecies',
  'pokemonForm',
  'pokemonMedia',
};

List<AuthoringResourceParity> _sortedResources(
  Iterable<AuthoringResourceParity> values,
) {
  final byId = <String, AuthoringResourceParity>{};
  for (final value in values) {
    if (byId.containsKey(value.resourceKind)) {
      throw ArgumentError.value(value.resourceKind, 'resources', 'duplicate');
    }
    byId[value.resourceKind] = value;
  }
  final result = byId.values.toList()
    ..sort((left, right) => left.resourceKind.compareTo(right.resourceKind));
  return List.unmodifiable(result);
}

List<AuthoringMutationParityEvidence> _sortedActions(
  Iterable<AuthoringMutationParityEvidence> values,
) {
  final byId = <String, AuthoringMutationParityEvidence>{};
  for (final value in values) {
    if (byId.containsKey(value.actionId)) {
      throw ArgumentError.value(value.actionId, 'mutationActions', 'duplicate');
    }
    byId[value.actionId] = value;
  }
  final result = byId.values.toList()
    ..sort((left, right) => left.actionId.compareTo(right.actionId));
  return List.unmodifiable(result);
}

String _resourceKind(String value) {
  final normalized = _required(value, 'resourceKind');
  if (!RegExp(r'^[a-z][A-Za-z0-9]*$').hasMatch(normalized)) {
    throw ArgumentError.value(value, 'resourceKind', 'must be canonical');
  }
  return normalized;
}

String _required(String value, String field) {
  if (value.trim().isEmpty || value.trim() != value) {
    throw ArgumentError.value(value, field, 'must be nonblank and trimmed');
  }
  return value;
}
```

## `packages/map_authoring/test/fixtures/pmcp085_golden_receipt.json`

```json
{
  "actionId": "map.create",
  "actionVersion": 1,
  "status": "applied",
  "changes": [
    {
      "operation": "add",
      "resource": {
        "kind": "map",
        "id": "pmcp085_golden_map"
      },
      "path": "/"
    },
    {
      "operation": "add",
      "resource": {
        "kind": "project",
        "id": "project"
      },
      "path": "/maps/pmcp085_golden_map"
    }
  ]
}
```

## `packages/map_authoring/test/parity/full_authoring_parity_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('PMCP-085 full authoring parity', () {
    test('registers every approved semantic resource without hidden gaps', () {
      final catalog = AuthoringFullParityCatalog.canonical();

      expect(
        catalog.resources.map((resource) => resource.resourceKind).toSet(),
        _approvedResourceKinds,
      );
      expect(catalog.blockedOrMissingCells, isEmpty);
      for (final resource in catalog.resources) {
        expect(
          resource.cells.keys.toSet(),
          AuthoringParityCapability.values.toSet(),
          reason: resource.resourceKind,
        );
        expect(resource.canonicalOwnerKind, isNotEmpty);
        for (final cell in resource.cells.values) {
          if (cell.status == AuthoringParityStatus.notApplicable) {
            expect(cell.justification, isNotEmpty,
                reason: resource.resourceKind);
          } else {
            expect(cell.status, AuthoringParityStatus.supported,
                reason: '${resource.resourceKind}/${cell.capability.name}');
            expect(cell.evidence, isNotEmpty,
                reason: '${resource.resourceKind}/${cell.capability.name}');
          }
        }
      }
    });

    test('covers every canonical mutation with contracts and four transports',
        () {
      final catalog = AuthoringFullParityCatalog.canonical();
      final descriptors = AuthoringMutationDispatcher.canonical().descriptors;

      expect(
        catalog.mutationActions.map((action) => action.actionId).toSet(),
        descriptors.map((descriptor) => descriptor.id).toSet(),
      );
      for (final descriptor in descriptors) {
        final evidence = catalog.requireMutationAction(descriptor.id);
        expect(
          evidence.transports,
          AuthoringTransport.values.toSet(),
          reason: descriptor.id,
        );
        expect(File(evidence.contractTestPath).existsSync(), isTrue,
            reason: descriptor.id);
        expect(descriptor.requiredPermissions, isNotEmpty,
            reason: descriptor.id);
        expect(
          descriptor.guarantees,
          containsAll({
            AuthoringGuarantee.dryRun,
            AuthoringGuarantee.idempotent,
            AuthoringGuarantee.revisionChecked,
            AuthoringGuarantee.undoable,
          }),
          reason: descriptor.id,
        );
      }
    });

    test('matches runtime and editor consumer inventories automatically', () {
      final catalog = AuthoringFullParityCatalog.canonical();
      final repositoryRoot = Directory.current.parent.parent;
      final renderWorker = File(
        '${repositoryRoot.path}/packages/map_runtime/bin/pokemap_render.dart',
      ).readAsStringSync();
      final playtestWorker = File(
        '${repositoryRoot.path}/examples/playable_runtime_host/lib/src/'
        'evaluation/driver/evaluation_playtest_adapter.dart',
      ).readAsStringSync();
      final editorAdapter = File(
        '${repositoryRoot.path}/packages/map_editor/lib/src/application/'
        'authoring_api/authoring_mutation_adapter.dart',
      ).readAsStringSync();

      for (final command in catalog.runtimeCommands) {
        final source = command == 'render' ? renderWorker : playtestWorker;
        expect(source, contains(command), reason: command);
      }
      expect(
          editorAdapter, contains('Future<EditorAuthoringMutationPlan> plan('));
      expect(editorAdapter,
          contains('Future<EditorAuthoringMutationResult> apply('));

      final editorActionIds = <String>{};
      final editorLib = Directory(
        '${repositoryRoot.path}/packages/map_editor/lib/src',
      );
      for (final entity in editorLib.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) {
          continue;
        }
        final source = entity.readAsStringSync();
        for (final match in RegExp(
          r"(?:^|[^A-Za-z0-9_])actionId:\s*'([^']+)'",
          multiLine: true,
        ).allMatches(source)) {
          editorActionIds.add(match.group(1)!);
        }
      }
      expect(editorActionIds, isNotEmpty);
      expect(
        editorActionIds.difference(
          catalog.mutationActions.map((action) => action.actionId).toSet(),
        ),
        isEmpty,
        reason: 'Every editor-authored action must exist in the canonical API',
      );
    });

    test('direct API and JSONL CLI produce the same golden receipt', () async {
      final expected = jsonDecode(
        File('test/fixtures/pmcp085_golden_receipt.json').readAsStringSync(),
      );
      final direct = await _GoldenHarness.create('direct');
      final cli = await _GoldenHarness.create('cli');
      addTearDown(direct.dispose);
      addTearDown(cli.dispose);

      expect(await direct.applyDirect(), expected);
      expect(await cli.applyThroughJsonl(), expected);
    });
  });
}

final Set<String> _approvedResourceKinds = {
  'project',
  'projectSettings',
  'projectPokemonConfig',
  'projectNewGameConfig',
  'projectPresentationProfile',
  'mapGroup',
  'map',
  'mapLayer',
  'mapConnection',
  'mapWarp',
  'mapTrigger',
  'mapGameplayZone',
  'mapPlacedElement',
  'mapEntity',
  'mapEvent',
  'tilesetFolder',
  'tileset',
  'tilesetElementGroup',
  'tilesetPaletteEntry',
  'elementCategory',
  'element',
  'terrainPresetCategory',
  'pathPresetCategory',
  'terrainPreset',
  'pathPreset',
  'pathPatternPreset',
  'surfacePreset',
  'surfaceAtlas',
  'environmentPreset',
  'borderBlueprint',
  'borderFeature',
  'shadowPreset',
  'projectedBuildingShadowPreset',
  'encounterTable',
  'encounterEntry',
  'dialogueFolder',
  'dialogue',
  'script',
  'scenario',
  'narrativeEvent',
  'narrativeFact',
  'worldRule',
  'scene',
  'storyline',
  'cinematic',
  'cinematicMediaAsset',
  'shop',
  'badge',
  'trainer',
  'character',
  'pokemonSpecies',
  'pokemonForm',
  'pokemonLearnset',
  'pokemonEvolution',
  'pokemonMedia',
  'pokemonMove',
  'pokemonAbility',
  'pokemonItem',
  'pokemonType',
  'pokemonCatalog',
  'gameSave',
  'gamePackage',
};

final class _GoldenHarness {
  _GoldenHarness({
    required this.root,
    required this.readApi,
    required this.mutations,
    required this.snapshots,
    required this.worker,
  });

  static Future<_GoldenHarness> create(String suffix) async {
    final root = await Directory.systemTemp.createTemp('pmcp085_$suffix');
    final manifest = ProjectManifest(
      name: 'PMCP-085 golden receipt',
      version: ProjectVersion.v3,
      maps: const [],
      tilesets: const [],
    );
    await File('${root.path}/project.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
      flush: true,
    );
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final readApi = AuthoringReadApi(
      openService: ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ),
      snapshotLoader: snapshots,
    );
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
    );
    return _GoldenHarness(
      root: root,
      readApi: readApi,
      mutations: mutations,
      snapshots: snapshots,
      worker: JsonlWorker(api: readApi, mutations: mutations),
    );
  }

  final Directory root;
  final AuthoringReadApi readApi;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;
  final JsonlWorker worker;

  Future<Map<String, Object?>> applyDirect() async {
    final opened = await readApi.open(root.path);
    final workspace = WorkspaceHandle(opened['workspaceHandle']! as String);
    final project = ProjectHandle(opened['projectHandle']! as String);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: workspace,
      projectHandle: project,
    );
    final snapshot = await snapshots.load(project);
    final request = _request(workspace.value, snapshot.revision);
    final planned = await mutations.plan(project, request);
    final applied = await mutations.apply(
      project,
      planId: planned['planId']! as String,
      operationId: 'pmcp085-direct-apply',
    );
    return _stableReceipt(applied['receipt']);
  }

  Future<Map<String, Object?>> applyThroughJsonl() async {
    final opened = await _jsonl('open', {'projectRoot': root.path});
    final workspaceHandle = opened['workspaceHandle']! as String;
    final projectHandle = opened['projectHandle']! as String;
    final snapshot = await snapshots.load(ProjectHandle(projectHandle));
    final request = _request(workspaceHandle, snapshot.revision);
    final planned = await _jsonl('plan', {
      'projectHandle': projectHandle,
      'request': request.toJson(),
    });
    final applied = await _jsonl('apply', {
      'projectHandle': projectHandle,
      'planId': planned['planId'],
      'operationId': 'pmcp085-cli-apply',
    });
    return _stableReceipt(applied['receipt']);
  }

  AuthoringRequest _request(String workspaceHandle, String revision) =>
      AuthoringRequest(
        requestId: 'pmcp085-golden-request',
        actionId: 'map.create',
        actionVersion: 1,
        workspaceHandle: workspaceHandle,
        parameters: const {
          'mapId': 'pmcp085_golden_map',
          'width': 3,
          'height': 2,
        },
        expectedRevision: revision,
        idempotencyKey: 'pmcp085-golden-idempotency',
        dryRun: false,
      );

  Future<Map<String, Object?>> _jsonl(
    String command,
    Map<String, Object?> args,
  ) async {
    final decoded = jsonDecode(
      await worker.processLine(
        jsonEncode({
          'id': 'pmcp085-$command',
          'command': command,
          'args': args,
        }),
      ),
    ) as Map<String, dynamic>;
    final result = AuthoringResult.fromJson(decoded);
    expect(
      result.status,
      AuthoringResultStatus.success,
      reason: result.error?.toJson().toString(),
    );
    return result.data;
  }

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

Map<String, Object?> _stableReceipt(Object? raw) {
  final receipt = AuthoringReceipt.fromJson(
    Map<String, dynamic>.from(raw! as Map),
  );
  return {
    'actionId': receipt.actionId,
    'actionVersion': receipt.actionVersion,
    'status': receipt.status.wireName,
    'changes': [
      for (final entry in receipt.diff.entries)
        {
          'operation': entry.operation.wireName,
          'resource': {
            'kind': entry.resource.kind,
            'id': entry.resource.id,
          },
          'path': entry.path,
        },
    ],
  };
}
```

## `packages/map_authoring/tool/pmcp085_conformance.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';

void main(List<String> arguments) {
  if (arguments.length > 1 ||
      (arguments.isNotEmpty && arguments.single != '--actions')) {
    stderr.writeln('Usage: dart run tool/pmcp085_conformance.dart [--actions]');
    exitCode = 64;
    return;
  }
  if (arguments case ['--actions']) {
    stdout.writeln(
      const JsonEncoder.withIndent('  ').convert([
        for (final descriptor
            in AuthoringMutationDispatcher.canonical().descriptors)
          {
            'id': descriptor.id,
            'resourceKinds': descriptor.resourceKinds,
          },
      ]),
    );
    return;
  }
  final catalog = AuthoringFullParityCatalog.canonical();
  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert(catalog.toJson()),
  );
  if (catalog.blockedOrMissingCells.isNotEmpty) exitCode = 1;
}
```

## `packages/map_editor/test/authoring_api/no_bypass_guardrail_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';
import 'package:path/path.dart' as p;

void main() {
  test('known editor bypasses remain explicit and release-blocking', () {
    final guardrail = File(
      p.join('test', 'authoring_api', 'editor_write_boundary_test.dart'),
    ).readAsStringSync();
    final block = RegExp(
      r'const _legacyStructuredAuthoringDebt = <String>\{(.*?)\};',
      dotAll: true,
    ).firstMatch(guardrail);
    expect(block, isNotNull);
    final actual = RegExp(r"'([^']+\.dart)'")
        .allMatches(block!.group(1)!)
        .map((match) => match.group(1)!)
        .toSet();
    expect(actual, _knownStructuredAuthoringDebt);
  });

  test('product and UI layers do not write structured project bytes directly',
      () async {
    final roots = [
      p.join('lib', 'src', 'application'),
      p.join('lib', 'src', 'features'),
      p.join('lib', 'src', 'ui'),
    ];
    final violations = <String>[];
    for (final root in roots) {
      await for (final entity in Directory(root).list(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final relative = p.relative(entity.path);
        if (_nonProjectStateWriters.contains(relative)) continue;
        final source = await entity.readAsString();
        if (_rawStructuredWrite.hasMatch(source)) violations.add(relative);
      }
    }
    expect(violations, isEmpty);
  });

  test('editor generic transport produces the shared golden receipt', () async {
    final root = await Directory.systemTemp.createTemp('pmcp085_editor');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    const manifest = ProjectManifest(
      name: 'PMCP-085 editor golden receipt',
      version: ProjectVersion.v3,
      maps: [],
      tilesets: [],
    );
    await File(p.join(root.path, 'project.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
      flush: true,
    );
    const reader = EditorProjectFileReader();
    final queries = AuthoringQueryAdapter(fileReader: reader);
    final mutations = AuthoringMutationAdapter(
      fileReader: reader,
      queries: queries,
      projectRoots: reader,
    );
    addTearDown(mutations.closeAll);
    addTearDown(queries.closeAll);

    final plan = await mutations.plan(
      root.path,
      actionId: 'map.create',
      parameters: const {
        'mapId': 'pmcp085_golden_map',
        'width': 3,
        'height': 2,
      },
      idempotencyKey: 'pmcp085-golden-idempotency',
      requestId: 'pmcp085-golden-request',
    );
    final applied = await mutations.apply(
      plan,
      operationId: 'pmcp085-editor-apply',
    );
    final expected = jsonDecode(
      File(
        p.join(
          Directory.current.parent.path,
          'map_authoring',
          'test',
          'fixtures',
          'pmcp085_golden_receipt.json',
        ),
      ).readAsStringSync(),
    );
    expect(_stableReceipt(applied.receipt), expected);
  });
}

final RegExp _rawStructuredWrite = RegExp(
  r'(?:writeAsString|writeAsBytes)\s*\(\s*(?:jsonEncode|const JsonEncoder|JsonEncoder)',
);

const _nonProjectStateWriters = <String>{
  'lib/src/features/editor/state/editor_notifier.dart',
};

/// PMCP-085 must keep this debt exact rather than turn a generic editor
/// transport into false evidence that every existing product gesture uses it.
const _knownStructuredAuthoringDebt = <String>{
  'lib/src/application/services/map_lifecycle_transaction_service.dart',
  'lib/src/application/use_cases/map_use_cases.dart',
  'lib/src/features/editor/state/editor_notifier.dart',
  'lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart',
  'lib/src/ui/canvas/storylines_workspace.dart',
};

Map<String, Object?> _stableReceipt(AuthoringReceipt receipt) => {
      'actionId': receipt.actionId,
      'actionVersion': receipt.actionVersion,
      'status': receipt.status.wireName,
      'changes': [
        for (final entry in receipt.diff.entries)
          {
            'operation': entry.operation.wireName,
            'resource': {
              'kind': entry.resource.kind,
              'id': entry.resource.id,
            },
            'path': entry.path,
          },
      ],
    };
```

## `tools/pokemap_mcp/THREAT_MODEL.md`

```markdown
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
```

## `tools/pokemap_mcp/scripts/pmcp085_release_gate.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../../.." && pwd)"

cd "$repo_root/packages/map_authoring"
dart test --reporter compact
dart analyze
dart run tool/pmcp085_conformance.dart >/dev/null

cd "$repo_root/packages/map_editor"
flutter test \
  test/authoring_api/editor_mutation_parity_test.dart \
  test/authoring_api/editor_write_boundary_test.dart \
  test/authoring_api/no_bypass_guardrail_test.dart \
  --reporter compact
flutter analyze

cd "$repo_root/tools/pokemap_mcp"
npm run check
npm test

cd "$repo_root/packages/map_runtime"
flutter test \
  test/application/authoring_preview/runtime_authoring_map_render_adapter_test.dart \
  --reporter compact
flutter analyze

cd "$repo_root/examples/playable_runtime_host"
flutter test \
  test/evaluation/evaluation_authoring_job_service_test.dart \
  test/evaluation/evaluation_playtest_adapter_test.dart \
  --reporter compact
flutter analyze

# The generic editor adapter proves transport parity, not migration of every
# existing product gesture. Keep the production claim closed while PMCP-081's
# exact debt inventory remains in the editor guardrail.
editor_guard="$repo_root/packages/map_editor/test/authoring_api/editor_write_boundary_test.dart"
if grep -q 'const _legacyStructuredAuthoringDebt = <String>{' "$editor_guard"; then
  echo 'PMCP-085 BLOCKED: PMCP-081 editor mutation debt is still explicit.' >&2
  exit 1
fi

echo 'PMCP-085 release claim authorized.'
```

## `tools/pokemap_mcp/src/request_guard.ts`

```typescript
import type {
  AuthoringGateway,
  AuthoringWorkerSuccess,
  JsonRecord,
} from "./authoring_client.js";
import type {
  ArtifactReader,
  ReadArtifact,
} from "./artifacts.js";
import type {
  PlaytestToolRequest,
  RenderToolRequest,
  RuntimeGateway,
  RuntimeToolResult,
} from "./runtime_gateway.js";
import { PokeMapToolError } from "./tool_error.js";

export interface PokeMapRequestGuardOptions {
  maxRequestsPerWindow?: number;
  windowMs?: number;
  maxInputBytes?: number;
  clock?: () => number;
}

/** Shared MCP admission gate for rate and serialized-input budgets. */
export class PokeMapRequestGuard {
  readonly #maxRequestsPerWindow: number;
  readonly #windowMs: number;
  readonly #maxInputBytes: number;
  readonly #clock: () => number;
  #windowStartedAt: number;
  #requestsInWindow = 0;

  constructor(options: PokeMapRequestGuardOptions = {}) {
    this.#maxRequestsPerWindow = positiveInteger(
      options.maxRequestsPerWindow ?? 512,
      "maxRequestsPerWindow",
    );
    this.#windowMs = positiveInteger(options.windowMs ?? 60_000, "windowMs");
    this.#maxInputBytes = positiveInteger(
      options.maxInputBytes ?? 64 * 1024,
      "maxInputBytes",
    );
    this.#clock = options.clock ?? Date.now;
    this.#windowStartedAt = this.#clock();
  }

  async run<T>(
    operation: string,
    input: unknown,
    execute: () => Promise<T>,
  ): Promise<T> {
    const byteLength = Buffer.byteLength(JSON.stringify(input), "utf8");
    if (byteLength > this.#maxInputBytes) {
      throw new PokeMapToolError(
        "resource_limit",
        "The MCP tool input exceeds the configured UTF-8 byte limit.",
        false,
        ["Split the request into smaller semantic batches."],
        {
          operation,
          byteLength,
          maximumBytes: this.#maxInputBytes,
        },
      );
    }
    this.#admitRate(operation);
    return execute();
  }

  #admitRate(operation: string): void {
    const now = this.#clock();
    if (now - this.#windowStartedAt >= this.#windowMs) {
      this.#windowStartedAt = now;
      this.#requestsInWindow = 0;
    }
    if (this.#requestsInWindow >= this.#maxRequestsPerWindow) {
      throw new PokeMapToolError(
        "rate_limited",
        "The MCP request rate exceeds the configured local budget.",
        true,
        ["Wait for the current rate window before retrying."],
        {
          operation,
          maximumRequests: this.#maxRequestsPerWindow,
          windowMs: this.#windowMs,
        },
      );
    }
    this.#requestsInWindow += 1;
  }
}

export function guardAuthoringGateway(
  gateway: AuthoringGateway,
  guard: PokeMapRequestGuard,
): AuthoringGateway {
  return {
    request(
      command: string,
      args: JsonRecord = {},
    ): Promise<AuthoringWorkerSuccess> {
      return guard.run(`authoring.${command}`, { command, args }, () =>
        gateway.request(command, args),
      );
    },
    close(): Promise<void> {
      return gateway.close();
    },
  };
}

export function guardArtifactReader(
  reader: ArtifactReader,
  guard: PokeMapRequestGuard,
): ArtifactReader {
  return {
    read(uri: string): Promise<ReadArtifact> {
      return guard.run("artifact.read", { uri }, () => reader.read(uri));
    },
  };
}

export function guardRuntimeGateway(
  gateway: RuntimeGateway,
  guard: PokeMapRequestGuard,
): RuntimeGateway {
  return {
    render(request: RenderToolRequest): Promise<RuntimeToolResult> {
      return guard.run("runtime.render", request, () => gateway.render(request));
    },
    startPlaytest(request: PlaytestToolRequest): Promise<RuntimeToolResult> {
      return guard.run("runtime.playtest", request, () =>
        gateway.startPlaytest(request),
      );
    },
    getJob(jobId: string): Promise<RuntimeToolResult> {
      return guard.run("runtime.job.get", { jobId }, () => gateway.getJob(jobId));
    },
    jobEvents(jobId: string, afterSequence: number): Promise<RuntimeToolResult> {
      return guard.run(
        "runtime.job.events",
        { jobId, afterSequence },
        () => gateway.jobEvents(jobId, afterSequence),
      );
    },
    cancelJob(jobId: string): Promise<RuntimeToolResult> {
      return guard.run("runtime.job.cancel", { jobId }, () =>
        gateway.cancelJob(jobId),
      );
    },
    retryJob(jobId: string): Promise<RuntimeToolResult> {
      return guard.run("runtime.job.retry", { jobId }, () =>
        gateway.retryJob(jobId),
      );
    },
    close(): Promise<void> {
      return gateway.close();
    },
  };
}

function positiveInteger(value: number, field: string): number {
  if (!Number.isSafeInteger(value) || value <= 0) {
    throw new PokeMapToolError(
      "configuration.invalid_request_guard",
      `The ${field} request-guard option must be a positive integer.`,
    );
  }
  return value;
}
```

## `tools/pokemap_mcp/test/conformance_security.test.ts`

```typescript
import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";

import { Client } from "@modelcontextprotocol/client";
import { InMemoryTransport } from "@modelcontextprotocol/server";

import type {
  AuthoringGateway,
  JsonRecord,
} from "../src/authoring_client.js";
import { LocalAuthoringClient } from "../src/authoring_client.js";
import { MemoryArtifactReader } from "../src/artifacts.js";
import { PokeMapRequestGuard } from "../src/request_guard.js";
import { createPokeMapMcpServer } from "../src/server.js";

const repositoryRoot = resolve(process.cwd(), "../..");
const authoringPackageRoot = resolve(repositoryRoot, "packages/map_authoring");
const emptyProjectScaffold = resolve(
  repositoryRoot,
  "examples/playable_runtime_host/phase6_authoring_golden_slice/project.json",
);

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

async function connect(
  authoring: AuthoringGateway,
  guard = new PokeMapRequestGuard(),
) {
  const server = createPokeMapMcpServer({
    authoring,
    artifacts: new MemoryArtifactReader(),
    guard,
  });
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "pmcp085-conformance", version: "1.0.0" });
  await server.connect(serverTransport);
  await client.connect(clientTransport);
  return { client, server };
}

test("all twelve tools publish strict schemas, outputs and annotations", async () => {
  const gateway: AuthoringGateway = {
    async request() {
      return { requestId: "conformance", data: {}, artifacts: [] };
    },
    async close() {},
  };
  const fixture = await connect(gateway);
  try {
    const tools = (await fixture.client.listTools()).tools;
    assert.deepEqual(
      tools.map((tool) => tool.name),
      [
        "pokemap_artifact",
        "pokemap_describe",
        "pokemap_query",
        "pokemap_validate",
        "pokemap_workspace",
        "pokemap_plan",
        "pokemap_apply",
        "pokemap_history",
        "pokemap_recovery",
      ],
    );
    for (const tool of tools) {
      assert.ok(tool.inputSchema);
      assert.ok(tool.outputSchema);
      assertStrictSchema(tool.inputSchema, tool.name);
      assert.equal(typeof tool.annotations?.readOnlyHint, "boolean", tool.name);
    }
  } finally {
    await fixture.client.close();
    await fixture.server.close();
  }
});

test("rate and UTF-8 size budgets fail closed before reaching a gateway", async () => {
  const calls: string[] = [];
  const gateway: AuthoringGateway = {
    async request(command) {
      calls.push(command);
      return { requestId: command, data: {}, artifacts: [] };
    },
    async close() {},
  };
  const fixture = await connect(
    gateway,
    new PokeMapRequestGuard({
      maxRequestsPerWindow: 2,
      windowMs: 60_000,
      maxInputBytes: 32,
    }),
  );
  try {
    await fixture.client.callTool({ name: "pokemap_describe", arguments: {} });
    const tooLarge = await fixture.client.callTool({
      name: "pokemap_workspace",
      arguments: { operation: "open", projectRoot: `/${"é".repeat(64)}` },
    });
    assert.equal(tooLarge.isError, true);
    assert.equal(record(record(tooLarge.structuredContent).error).code, "resource_limit");

    await fixture.client.callTool({ name: "pokemap_describe", arguments: {} });
    const throttled = await fixture.client.callTool({
      name: "pokemap_describe",
      arguments: {},
    });
    assert.equal(throttled.isError, true);
    assert.equal(record(record(throttled.structuredContent).error).code, "rate_limited");
    assert.deepEqual(calls, ["describe", "describe"]);
  } finally {
    await fixture.client.close();
    await fixture.server.close();
  }
});

test("strict schemas reject a deterministic malformed-envelope corpus", async () => {
  let gatewayCalls = 0;
  const gateway: AuthoringGateway = {
    async request() {
      gatewayCalls += 1;
      return { requestId: "unexpected", data: {}, artifacts: [] };
    },
    async close() {},
  };
  const fixture = await connect(gateway);
  try {
    const corpus: JsonRecord[] = [
      {},
      { projectHandle: "p", resourceKind: "map", operation: "get" },
      { projectHandle: "p", resourceKind: "../map", operation: "list" },
      { projectHandle: "p", resourceKind: "map", operation: "list", extra: true },
      { projectHandle: "p", resourceKind: "map", operation: "search", searchTerm: "" },
      { projectHandle: "p", resourceKind: "map", operation: "list", pageSize: 0 },
      { projectHandle: "p", resourceKind: "map", operation: "list", pageSize: 201 },
      ...Array.from({ length: 64 }, (_, index) => ({
        projectHandle: `project-${index}`,
        resourceKind: index % 2 === 0 ? "map" : "project",
        operation: "list",
        [`unexpected_${index}`]: true,
      })),
    ];
    for (const arguments_ of corpus) {
      try {
        const result = await fixture.client.callTool({
          name: "pokemap_query",
          arguments: arguments_,
        });
        assert.equal(result.isError, true, JSON.stringify(arguments_));
      } catch (error) {
        assert.ok(error instanceof Error);
      }
    }
    assert.equal(gatewayCalls, 0);
  } finally {
    await fixture.client.close();
    await fixture.server.close();
  }
});

function assertStrictSchema(schema: unknown, toolName: string): void {
  const object = record(schema);
  if (object.additionalProperties === false) return;
  const alternatives = object.oneOf ?? object.anyOf;
  assert.ok(Array.isArray(alternatives) && alternatives.length > 0, toolName);
  for (const alternative of alternatives) {
    assert.equal(record(alternative).additionalProperties, false, toolName);
  }
}

test("MCP emits the same map.create golden receipt as direct API, CLI and editor", async () => {
  const expected = JSON.parse(
    await readFile(
      resolve(
        repositoryRoot,
        "packages/map_authoring/test/fixtures/pmcp085_golden_receipt.json",
      ),
      "utf8",
    ),
  );
  const root = await mkdtemp(join(tmpdir(), "pmcp085-mcp-golden-"));
  await writeFile(join(root, "project.json"), await readFile(emptyProjectScaffold));
  const authoring = new LocalAuthoringClient({
    allowedRoots: [root],
    authoringPackageRoot,
  });
  const fixture = await connect(authoring);
  try {
    const opened = record(
      record(
        (
          await fixture.client.callTool({
            name: "pokemap_workspace",
            arguments: { operation: "open", projectRoot: root },
          })
        ).structuredContent,
      ).data,
    );
    const projectHandle = String(opened.projectHandle);
    const validation = record(
      record(
        (
          await fixture.client.callTool({
            name: "pokemap_validate",
            arguments: { projectHandle },
          })
        ).structuredContent,
      ).data,
    );
    const planned = record(
      record(
        (
          await fixture.client.callTool({
            name: "pokemap_plan",
            arguments: {
              projectHandle,
              request: {
                requestId: "pmcp085-golden-request",
                actionId: "map.create",
                actionVersion: 1,
                workspaceHandle: opened.workspaceHandle,
                parameters: {
                  mapId: "pmcp085_golden_map",
                  width: 3,
                  height: 2,
                },
                expectedRevision: validation.snapshotRevision,
                idempotencyKey: "pmcp085-golden-idempotency",
                dryRun: false,
              },
            },
          })
        ).structuredContent,
      ).data,
    );
    const result = await fixture.client.callTool({
      name: "pokemap_apply",
      arguments: {
        operation: "apply",
        projectHandle,
        planId: planned.planId,
        operationId: "pmcp085-mcp-apply",
      },
    });
    const transported = record(record(result.structuredContent).data);
    const actualReceipt = record(transported.receipt);
    assert.deepEqual(
      {
        actionId: actualReceipt.actionId,
        actionVersion: actualReceipt.actionVersion,
        status: actualReceipt.status,
        changes: (record(actualReceipt.diff).entries as unknown[]).map(
          (rawChange) => {
            const change = record(rawChange);
            const resource = record(change.resource);
            return {
              operation: change.operation,
              resource: { kind: resource.kind, id: resource.id },
              path: change.path,
            };
          },
        ),
      },
      expected,
    );
  } finally {
    await fixture.client.close();
    await fixture.server.close();
    await authoring.close();
    await rm(root, { recursive: true, force: true });
  }
});
```
