import '../domains/maps/map_mutation_dispatcher.dart';
import '../registry/resource_kind_registry.dart';

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

  AuthoringParityCell.missing({
    required this.capability,
    required String justification,
  })  : status = AuthoringParityStatus.missing,
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

  factory AuthoringFullParityCatalog.canonical({
    Set<String> queryableResourceKinds = canonicalQueryableResourceKindIds,
  }) {
    final resources = <AuthoringResourceParity>[
      for (final entry in _semanticOwners.entries)
        _resourceParity(
          entry.key,
          entry.value,
          queryableResourceKinds: queryableResourceKinds,
        ),
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

AuthoringResourceParity _resourceParity(
  String kind,
  String owner, {
  required Set<String> queryableResourceKinds,
}) {
  final derived = kind == 'gamePackage';
  final sandbox = kind == 'gameSave';
  final visual = _visualResources.contains(kind);
  final cells = <AuthoringParityCapability, AuthoringParityCell>{};
  for (final capability in AuthoringParityCapability.values) {
    if (capability == AuthoringParityCapability.read &&
        _requiredDirectReadResourceKinds.contains(kind) &&
        !queryableResourceKinds.contains(kind)) {
      cells[capability] = AuthoringParityCell.missing(
        capability: capability,
        justification: '$kind is required as a first-class query resource but '
            'is absent from the published readable inventory.',
      );
      continue;
    }
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
      AuthoringParityCapability.runtime => kind == 'smartTileDraft',
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
  if (kind == 'smartTileDraft' &&
      capability == AuthoringParityCapability.runtime) {
    return 'smartTileDraft is authoring-only; runtime resolution deliberately '
        'reads published presets and never draft state.';
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
    ['smart_tile.pattern.upsert', 'smart_tile.pattern.delete'],
    'test/domains/maps/smart_tile_catalog_actions_test.dart',
  ),
  _ContractEvidenceRule(
    ['smart_tile.pattern.paint', 'smart_tile.pattern.erase'],
    'test/domains/maps/smart_tile_cell_actions_test.dart',
  ),
  _ContractEvidenceRule(
    ['smart_tile.tiled_wang.'],
    'test/domains/maps/smart_tile_catalog_actions_test.dart',
  ),
  _ContractEvidenceRule(
    ['smart_tile.preset.draft.'],
    'test/domains/maps/smart_tile_draft_actions_test.dart',
  ),
  _ContractEvidenceRule(
    ['map.tiled.import'],
    'test/domains/maps/tiled_map_import_transaction_test.dart',
  ),
  _ContractEvidenceRule(
    ['map.'],
    'test/domains/maps/map_lifecycle_contract_test.dart',
  ),
  _ContractEvidenceRule(
    ['terrain.', 'path.', 'surface.'],
    'test/domains/maps/semantic_painting_test.dart',
  ),
  _ContractEvidenceRule(
    [
      'smart_tile.animation.',
      'smart_tile.atlas.',
      'smart_tile.material.',
      'smart_tile.preset.',
    ],
    'test/domains/maps/smart_tile_catalog_actions_test.dart',
  ),
  _ContractEvidenceRule(
    ['smart_tile.cell.'],
    'test/domains/maps/smart_tile_cell_actions_test.dart',
  ),
  _ContractEvidenceRule(
    ['smart_tile.layer.create', 'smart_tile.layer.delete'],
    'test/domains/maps/smart_tile_layer_editing_actions_test.dart',
  ),
  _ContractEvidenceRule(
    ['smart_tile.layer.'],
    'test/domains/maps/smart_tile_layer_actions_test.dart',
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
    ['asset.raw.'],
    'test/domains/assets/content_addressing_test.dart',
  ),
  _ContractEvidenceRule(
    ['asset.'],
    'test/domains/assets/asset_security_test.dart',
  ),
  _ContractEvidenceRule(
    [
      'tileset.',
      'tileset_folder.',
      'palette.',
      'element.',
      'element_category.',
      'preset.',
    ],
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
  'mapConnection': 'mapConnection',
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
  'smartTileAtlas': 'project',
  'smartTileMaterial': 'project',
  'smartTilePattern': 'project',
  'smartTileAnimation': 'project',
  'smartTileDraft': 'project',
  'smartTilePreset': 'project',
  'smartTileLayer': 'map',
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

const _requiredDirectReadResourceKinds = <String>{
  'mapConnection',
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
  'smartTileAtlas',
  'smartTilePattern',
  'smartTilePreset',
  'smartTileLayer',
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
