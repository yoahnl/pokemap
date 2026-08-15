import '../application/map_mutation_dispatcher.dart';
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

final class AuthoringTransportExecutionReceipt {
  AuthoringTransportExecutionReceipt({
    required String receiptId,
    required String actionId,
    required this.transport,
    required String sourceRevision,
    required String evidenceRevision,
    required String fixtureDigest,
    required String executorDigest,
    required String observedReceiptSha256,
    required String semanticStateDigest,
    required String evidencePath,
  })  : receiptId = _required(receiptId, 'receiptId'),
        actionId = _required(actionId, 'actionId'),
        sourceRevision = _sourceRevision(sourceRevision),
        evidenceRevision = _sha256(evidenceRevision, 'evidenceRevision'),
        fixtureDigest = _sha256(fixtureDigest, 'fixtureDigest'),
        executorDigest = _sha256(executorDigest, 'executorDigest'),
        observedReceiptSha256 = _sha256(
          observedReceiptSha256,
          'observedReceiptSha256',
        ),
        semanticStateDigest = _sha256(
          semanticStateDigest,
          'semanticStateDigest',
        ),
        evidencePath = _required(evidencePath, 'evidencePath');

  factory AuthoringTransportExecutionReceipt.fromJson(
    Map<String, dynamic> json,
  ) {
    const fields = <String>{
      'receiptId',
      'actionId',
      'transport',
      'sourceRevision',
      'evidenceRevision',
      'fixtureDigest',
      'executorDigest',
      'observedReceiptSha256',
      'semanticStateDigest',
      'evidencePath',
    };
    if (json.keys.toSet().difference(fields).isNotEmpty ||
        !json.keys.toSet().containsAll(fields)) {
      throw const FormatException('Transport receipt fields are invalid.');
    }
    final transportName = json['transport'];
    if (transportName is! String) {
      throw const FormatException('transport must be a string');
    }
    final transport = AuthoringTransport.values.where(
      (candidate) => candidate.name == transportName,
    );
    if (transport.length != 1) {
      throw FormatException('Unknown authoring transport: $transportName');
    }
    try {
      return AuthoringTransportExecutionReceipt(
        receiptId: json['receiptId'] as String,
        actionId: json['actionId'] as String,
        transport: transport.single,
        sourceRevision: json['sourceRevision'] as String,
        evidenceRevision: json['evidenceRevision'] as String,
        fixtureDigest: json['fixtureDigest'] as String,
        executorDigest: json['executorDigest'] as String,
        observedReceiptSha256: json['observedReceiptSha256'] as String,
        semanticStateDigest: json['semanticStateDigest'] as String,
        evidencePath: json['evidencePath'] as String,
      );
    } on TypeError {
      throw const FormatException(
        'Transport execution receipt fields must be strings.',
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final String receiptId;
  final String actionId;
  final AuthoringTransport transport;
  final String sourceRevision;
  final String evidenceRevision;
  final String fixtureDigest;
  final String executorDigest;
  final String observedReceiptSha256;
  final String semanticStateDigest;
  final String evidencePath;

  Map<String, Object?> toJson() => <String, Object?>{
        'receiptId': receiptId,
        'actionId': actionId,
        'transport': transport.name,
        'sourceRevision': sourceRevision,
        'evidenceRevision': evidenceRevision,
        'fixtureDigest': fixtureDigest,
        'executorDigest': executorDigest,
        'observedReceiptSha256': observedReceiptSha256,
        'semanticStateDigest': semanticStateDigest,
        'evidencePath': evidencePath,
      };
}

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
    required Iterable<AuthoringTransport> declaredTransports,
    required Map<AuthoringTransport, String> adapterEvidence,
    required String contractTestPath,
    Map<AuthoringTransport, String> endToEndEvidence = const {},
    Map<AuthoringTransport, AuthoringTransportExecutionReceipt>
        transportExecutionReceipts = const {},
  })  : actionId = _required(actionId, 'actionId'),
        declaredTransports = Set.unmodifiable(declaredTransports),
        adapterEvidence = Map.unmodifiable({
          for (final entry in adapterEvidence.entries)
            entry.key: _required(entry.value, 'adapterEvidence'),
        }),
        contractTestPath = _required(contractTestPath, 'contractTestPath'),
        endToEndEvidence = Map.unmodifiable({
          for (final entry in endToEndEvidence.entries)
            entry.key: _required(entry.value, 'endToEndEvidence'),
        }),
        transportExecutionReceipts = Map.unmodifiable({
          for (final entry in transportExecutionReceipts.entries)
            entry.key: entry.value,
        }) {
    final undeclaredAdapters =
        this.adapterEvidence.keys.toSet().difference(this.declaredTransports);
    if (undeclaredAdapters.isNotEmpty) {
      throw ArgumentError.value(
        undeclaredAdapters,
        'adapterEvidence',
        'must reference declared transports',
      );
    }
    final unadaptedEndToEnd = this
        .endToEndEvidence
        .keys
        .toSet()
        .difference(this.adapterEvidence.keys.toSet());
    if (unadaptedEndToEnd.isNotEmpty) {
      throw ArgumentError.value(
        unadaptedEndToEnd,
        'endToEndEvidence',
        'must reference adapter-capable transports',
      );
    }
    final unadaptedReceipts = this
        .transportExecutionReceipts
        .keys
        .toSet()
        .difference(this.adapterEvidence.keys.toSet());
    if (unadaptedReceipts.isNotEmpty) {
      throw ArgumentError.value(
        unadaptedReceipts,
        'transportExecutionReceipts',
        'must reference adapter-capable transports',
      );
    }
    for (final entry in this.transportExecutionReceipts.entries) {
      if (entry.value.actionId != this.actionId ||
          entry.value.transport != entry.key) {
        throw ArgumentError.value(
          entry.value,
          'transportExecutionReceipts',
          'must match the action and transport binding',
        );
      }
    }
  }

  final String actionId;
  final Set<AuthoringTransport> declaredTransports;
  final Map<AuthoringTransport, String> adapterEvidence;
  final String contractTestPath;
  final Map<AuthoringTransport, String> endToEndEvidence;
  final Map<AuthoringTransport, AuthoringTransportExecutionReceipt>
      transportExecutionReceipts;

  Set<AuthoringTransport> get adapterCapableTransports =>
      Set.unmodifiable(adapterEvidence.keys);

  Set<AuthoringTransport> get endToEndVerifiedTransports =>
      Set.unmodifiable(<AuthoringTransport>{
        ...endToEndEvidence.keys,
        ...transportExecutionReceipts.keys,
      });

  @Deprecated('Use adapterCapableTransports or endToEndVerifiedTransports.')
  Set<AuthoringTransport> get transports => adapterCapableTransports;

  Map<String, Object?> toJson() => {
        'actionId': actionId,
        'declaredTransports': _transportNames(declaredTransports),
        'adapterCapableTransports': _transportNames(adapterCapableTransports),
        'adapterEvidence': _transportEvidenceJson(adapterEvidence),
        'contractTestPath': contractTestPath,
        'endToEndVerifiedTransports':
            _transportNames(endToEndVerifiedTransports),
        'endToEndEvidence': _transportEvidenceJson(endToEndEvidence),
        'transportExecutionReceipts': _transportReceiptJson(
          transportExecutionReceipts,
        ),
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
    Set<String>? queryableResourceKinds,
    Iterable<AuthoringTransportExecutionReceipt> transportExecutionReceipts =
        const [],
    String? transportEvidenceRevision,
    String? transportFixtureDigest,
    String? transportSourceRevision,
  }) {
    final publishedQueryableKinds =
        queryableResourceKinds ?? canonicalQueryableResourceKindIds;
    final descriptors = AuthoringMutationDispatcher.canonical().descriptors;
    final receipts = _validatedTransportReceipts(
      transportExecutionReceipts,
      knownActionIds: descriptors.map((descriptor) => descriptor.id).toSet(),
      expectedRevision: transportEvidenceRevision,
      expectedFixtureDigest: transportFixtureDigest,
      expectedSourceRevision: transportSourceRevision,
    );
    final resources = <AuthoringResourceParity>[
      for (final entry in _semanticOwners.entries)
        _resourceParity(
          entry.key,
          entry.value,
          queryableResourceKinds: publishedQueryableKinds,
        ),
    ];
    final actions = [
      for (final descriptor in descriptors)
        AuthoringMutationParityEvidence(
          actionId: descriptor.id,
          declaredTransports: AuthoringTransport.values,
          adapterEvidence: _canonicalAdapterEvidence,
          contractTestPath: _contractTestFor(descriptor.id),
          endToEndEvidence: descriptor.id.startsWith('item.')
              ? const <AuthoringTransport, String>{}
              : _endToEndEvidenceFor(descriptor.id),
          transportExecutionReceipts: <AuthoringTransport,
              AuthoringTransportExecutionReceipt>{
            for (final receipt
                in receipts.where((item) => item.actionId == descriptor.id))
              receipt.transport: receipt,
          },
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
        'formatVersion': 2,
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
          'endToEndVerifiedMutationActionCount': mutationActions
              .where((action) => action.endToEndVerifiedTransports.isNotEmpty)
              .length,
          'fullyEndToEndVerifiedMutationActionCount': mutationActions
              .where(
                (action) =>
                    action.endToEndVerifiedTransports.length ==
                    action.declaredTransports.length,
              )
              .length,
          'transportCertificationComplete': mutationActions.every(
            (action) =>
                action.endToEndVerifiedTransports.length ==
                action.declaredTransports.length,
          ),
          'itemTransportCertificationComplete': mutationActions
              .where((action) => action.actionId.startsWith('item.'))
              .every(
                (action) =>
                    action.endToEndVerifiedTransports.length ==
                    action.declaredTransports.length,
              ),
        },
      };
}

const Map<AuthoringTransport, String> _canonicalAdapterEvidence = {
  AuthoringTransport.directApi:
      'lib/src/api/local_map_authoring_mutation_api.dart',
  AuthoringTransport.cli: 'lib/src/tooling/jsonl_worker.dart',
  AuthoringTransport.editor:
      '../map_editor/lib/src/application/authoring_api/authoring_mutation_adapter.dart',
  AuthoringTransport.mcp: '../../tools/pokemap_mcp/src/authoring_client.ts',
};

Map<AuthoringTransport, String> _endToEndEvidenceFor(String actionId) {
  if (_cinematicLibraryTransportCertifiedActionIds.contains(actionId)) {
    return const <AuthoringTransport, String>{
      AuthoringTransport.directApi:
          'test/domains/narrative/cinematic_library_authoring_test.dart',
      AuthoringTransport.cli:
          'test/tooling/jsonl_cinematic_library_flow_test.dart',
      AuthoringTransport.editor:
          '../map_editor/test/authoring_api/editor_mutation_parity_test.dart',
      AuthoringTransport.mcp:
          '../../tools/pokemap_mcp/test/mutation_server.test.ts',
    };
  }
  if (_characterStudioTransportCertifiedActionIds.contains(actionId)) {
    return const <AuthoringTransport, String>{
      AuthoringTransport.directApi:
          'test/parity/character_studio_full_parity_test.dart',
      AuthoringTransport.cli:
          'test/parity/character_studio_full_parity_test.dart',
      AuthoringTransport.editor: '../map_editor/test/features/character_studio/'
          'character_studio_authoring_adapter_test.dart',
      AuthoringTransport.mcp:
          '../../tools/pokemap_mcp/test/mutation_server.test.ts',
    };
  }
  if (actionId == 'smart_tile.layer.set_animation_activation') {
    return const <AuthoringTransport, String>{
      AuthoringTransport.directApi:
          'test/domains/maps/smart_tile_layer_actions_test.dart',
      AuthoringTransport.cli:
          'test/domains/maps/smart_tile_layer_actions_test.dart',
      AuthoringTransport.editor:
          '../map_editor/test/features/editor/presentation/world_map/'
              'smart_tile_layer_preset_change_flow_test.dart',
      AuthoringTransport.mcp:
          '../../tools/pokemap_mcp/test/mutation_server.test.ts',
    };
  }
  if (actionId == 'smart_tile.layer.change_preset') {
    return const <AuthoringTransport, String>{
      AuthoringTransport.directApi:
          'test/domains/maps/smart_tile_layer_preset_change_action_test.dart',
      AuthoringTransport.cli:
          'test/domains/maps/smart_tile_layer_preset_change_action_test.dart',
      AuthoringTransport.editor:
          '../map_editor/test/features/editor/presentation/world_map/'
              'smart_tile_layer_preset_change_flow_test.dart',
      AuthoringTransport.mcp:
          '../../tools/pokemap_mcp/test/mutation_server.test.ts',
    };
  }
  if (actionId == 'presentation.update') {
    return const {
      AuthoringTransport.directApi:
          'test/parity/full_authoring_parity_test.dart',
      AuthoringTransport.cli: 'test/parity/full_authoring_parity_test.dart',
      AuthoringTransport.editor: '../map_editor/test/personalization/'
          'phase_6_personalization_studio_export_e2e_test.dart',
      AuthoringTransport.mcp:
          '../../tools/pokemap_mcp/test/mutation_server.test.ts',
    };
  }
  if (actionId == 'presentationMedia.import') {
    return const <AuthoringTransport, String>{
      AuthoringTransport.directApi:
          'test/domains/assets/presentation_media_import_transaction_test.dart',
      AuthoringTransport.cli:
          'test/domains/assets/presentation_media_import_transaction_test.dart',
    };
  }
  if (actionId == 'presentationMedia.configure') {
    return const <AuthoringTransport, String>{
      AuthoringTransport.directApi:
          'test/domains/assets/presentation_media_configuration_test.dart',
      AuthoringTransport.cli:
          'test/domains/assets/presentation_media_configuration_test.dart',
      AuthoringTransport.mcp:
          '../../tools/pokemap_mcp/test/mutation_server.test.ts',
    };
  }
  if (actionId == 'presentationClip.create') {
    return const <AuthoringTransport, String>{
      AuthoringTransport.directApi:
          'test/tooling/jsonl_presentation_cinematic_flow_test.dart',
      AuthoringTransport.cli:
          'test/tooling/jsonl_presentation_cinematic_flow_test.dart',
    };
  }
  if (actionId == 'campaign.encounter_table.upsert' ||
      actionId == 'campaign.encounter_table.delete') {
    return const <AuthoringTransport, String>{
      AuthoringTransport.directApi:
          'test/parity/full_authoring_parity_test.dart',
      AuthoringTransport.cli: 'test/parity/full_authoring_parity_test.dart',
      AuthoringTransport.editor:
          '../map_editor/test/authoring_api/editor_mutation_parity_test.dart',
      AuthoringTransport.mcp:
          '../../tools/pokemap_mcp/test/mutation_server.test.ts',
    };
  }
  if (actionId == 'presentation.preset.export') {
    return const {
      AuthoringTransport.directApi:
          'test/parity/full_authoring_parity_test.dart',
      AuthoringTransport.cli: 'test/parity/full_authoring_parity_test.dart',
      AuthoringTransport.editor:
          '../map_editor/test/authoring_api/editor_mutation_parity_test.dart',
      AuthoringTransport.mcp:
          '../../tools/pokemap_mcp/test/mutation_server.test.ts',
    };
  }
  if (actionId == 'map.create') {
    return const {
      AuthoringTransport.directApi:
          'test/parity/full_authoring_parity_test.dart',
      AuthoringTransport.cli: 'test/parity/full_authoring_parity_test.dart',
      AuthoringTransport.mcp:
          '../../tools/pokemap_mcp/test/mutation_server.test.ts',
    };
  }
  return const {};
}

const Set<String> _cinematicLibraryTransportCertifiedActionIds = <String>{
  'cinematicLibraryAsset.create',
  'cinematicLibraryAsset.duplicate',
  'cinematicLibraryAsset.delete',
  'cinematicLibraryFolder.create',
  'cinematicLibraryFolder.rename',
  'cinematicLibraryFolder.move',
  'cinematicLibraryFolder.reorder',
  'cinematicLibraryFolder.setArchived',
  'cinematicLibraryFolder.delete',
  'cinematicLibraryEntry.place',
  'cinematicLibraryEntry.reorder',
  'cinematicLibraryEntry.setArchived',
  'cinematicLibraryEntry.remove',
};

const Set<String> _characterStudioTransportCertifiedActionIds = <String>{
  'characterStudio.character.create',
  'characterStudio.character.update',
  'characterStudio.character.delete',
  'characterStudio.character.deletePlan',
  'characterStudio.character.setDefault',
  'characterStudio.character.portrait.assign',
  'characterStudio.character.portrait.clear',
  'characterStudio.portraitState.create',
  'characterStudio.portraitState.update',
  'characterStudio.portraitState.reorder',
  'characterStudio.portraitState.delete',
  'characterStudio.portraitState.deletePlan',
  'characterStudio.animationDefinition.create',
  'characterStudio.animationDefinition.update',
  'characterStudio.animationDefinition.reorder',
  'characterStudio.animationDefinition.delete',
  'characterStudio.animationDefinition.deletePlan',
  'characterStudio.animationClip.upsert',
  'characterStudio.animationClip.delete',
  'characterStudio.animationFrame.insert',
  'characterStudio.animationFrame.update',
  'characterStudio.animationFrame.reorder',
  'characterStudio.animationFrame.delete',
  'characterStudio.asset.import',
  'characterStudio.asset.replace',
};

List<String> _transportNames(Iterable<AuthoringTransport> transports) =>
    transports.map((transport) => transport.name).toList()..sort();

Map<String, String> _transportEvidenceJson(
  Map<AuthoringTransport, String> evidence,
) =>
    Map.fromEntries(
      evidence.entries
          .map((entry) => MapEntry(entry.key.name, entry.value))
          .toList()
        ..sort((left, right) => left.key.compareTo(right.key)),
    );

Map<String, Object?> _transportReceiptJson(
  Map<AuthoringTransport, AuthoringTransportExecutionReceipt> receipts,
) =>
    Map.fromEntries(
      receipts.entries
          .map((entry) => MapEntry(entry.key.name, entry.value.toJson()))
          .toList()
        ..sort((left, right) => left.key.compareTo(right.key)),
    );

List<AuthoringTransportExecutionReceipt> _validatedTransportReceipts(
  Iterable<AuthoringTransportExecutionReceipt> receipts, {
  required Set<String> knownActionIds,
  required String? expectedRevision,
  required String? expectedFixtureDigest,
  required String? expectedSourceRevision,
}) {
  final values = receipts.toList(growable: false);
  if (values.isEmpty) {
    if (expectedRevision != null ||
        expectedFixtureDigest != null ||
        expectedSourceRevision != null) {
      throw ArgumentError(
        'Transport evidence binding requires at least one receipt.',
      );
    }
    return const <AuthoringTransportExecutionReceipt>[];
  }
  if (expectedRevision == null ||
      expectedFixtureDigest == null ||
      expectedSourceRevision == null) {
    throw ArgumentError(
      'Transport receipts require revision and fixture bindings.',
    );
  }
  final revision = _sha256(expectedRevision, 'transportEvidenceRevision');
  final fixture = _sha256(
    expectedFixtureDigest,
    'transportFixtureDigest',
  );
  final sourceRevision = _sourceRevision(expectedSourceRevision);
  final bindings = <String>{};
  final receiptIds = <String>{};
  final observedReceiptDigests = <String>{};
  for (final receipt in values) {
    if (!knownActionIds.contains(receipt.actionId) ||
        !receipt.actionId.startsWith('item.')) {
      throw ArgumentError.value(
        receipt.actionId,
        'transportExecutionReceipts',
        'must reference one canonical item action',
      );
    }
    if (receipt.sourceRevision != sourceRevision ||
        receipt.evidenceRevision != revision ||
        receipt.fixtureDigest != fixture) {
      throw ArgumentError.value(
        receipt.receiptId,
        'transportExecutionReceipts',
        'must match the requested revision and fixture',
      );
    }
    final binding = '${receipt.actionId}/${receipt.transport.name}';
    if (!bindings.add(binding) ||
        !receiptIds.add(receipt.receiptId) ||
        !observedReceiptDigests.add(receipt.observedReceiptSha256)) {
      throw ArgumentError.value(
        receipt.receiptId,
        'transportExecutionReceipts',
        'must have unique receipt and action/transport bindings',
      );
    }
  }
  return List.unmodifiable(values);
}

String _sourceRevision(String value) {
  final normalized = _required(value, 'sourceRevision');
  if (!RegExp(r'^[0-9a-f]{40,64}$').hasMatch(normalized)) {
    throw ArgumentError.value(
      value,
      'sourceRevision',
      'must be a Git object id',
    );
  }
  return normalized;
}

String _sha256(String value, String name) {
  final normalized = _required(value, name);
  if (!RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(normalized)) {
    throw ArgumentError.value(value, name, 'must be a SHA-256 digest');
  }
  return normalized;
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
    [
      'cinematicLibraryAsset.',
      'cinematicLibraryFolder.',
      'cinematicLibraryEntry.',
    ],
    'test/domains/narrative/cinematic_library_authoring_test.dart',
  ),
  _ContractEvidenceRule(
    ['presentationCinematicTemplate.'],
    'test/domains/narrative/presentation_cinematic_template_authoring_test.dart',
  ),
  _ContractEvidenceRule(
    [
      'presentationCinematic.',
      'presentationTrack.',
      'presentationClip.',
      'presentationLayer.',
      'presentationVisualFolder.',
    ],
    'test/domains/narrative/presentation_cinematic_authoring_test.dart',
  ),
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
    ['smart_tile.layer.change_preset'],
    'test/domains/maps/smart_tile_layer_preset_change_action_test.dart',
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
    ['characterStudio.asset.'],
    'test/domains/assets/character_studio_asset_actions_test.dart',
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
    ['presentationMedia.import'],
    'test/domains/assets/presentation_media_import_transaction_test.dart',
  ),
  _ContractEvidenceRule(
    ['presentationMedia.configure'],
    'test/domains/assets/presentation_media_configuration_test.dart',
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
    ['item.'],
    'test/domains/gameplay/item_catalog_actions_test.dart',
  ),
  _ContractEvidenceRule(
    ['campaign.'],
    'test/domains/gameplay/campaign_content_authoring_test.dart',
  ),
  _ContractEvidenceRule(
    ['characterStudio.portraitState.'],
    'test/domains/gameplay/character_studio_portrait_state_actions_test.dart',
  ),
  _ContractEvidenceRule(
    ['characterStudio.animationDefinition.'],
    'test/domains/gameplay/character_studio_animation_definition_actions_test.dart',
  ),
  _ContractEvidenceRule(
    ['characterStudio.character.'],
    'test/domains/gameplay/character_studio_character_actions_test.dart',
  ),
  _ContractEvidenceRule(
    ['characterStudio.animationClip.', 'characterStudio.animationFrame.'],
    'test/domains/gameplay/character_studio_animation_clip_actions_test.dart',
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
  'projectPresentationPreset': 'project',
  'presentationPreviewContext': 'project',
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
  'cinematicLibraryCatalog': 'project',
  'cinematicLibraryFolder': 'cinematicLibraryCatalog',
  'cinematicLibraryEntry': 'cinematicLibraryCatalog',
  'presentationCinematic': 'project',
  'presentationCinematicTemplate': 'project',
  'presentationTrack': 'presentationCinematic',
  'presentationClip': 'presentationCinematic',
  'presentationLayer': 'presentationCinematic',
  'presentationVisualFolder': 'presentationCinematic',
  'shop': 'campaignContent',
  'badge': 'campaignContent',
  'trainer': 'campaignContent',
  'character': 'campaignContent',
  'characterStudioCatalog': 'project',
  'characterStudioCharacter': 'project',
  'characterStudioDependency': 'project',
  'characterStudioReadiness': 'project',
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
  'itemCatalog': 'itemCatalog',
  'itemDefinition': 'itemCatalog',
  'itemUsage': 'itemCatalog',
  'itemReadiness': 'itemCatalog',
  'gameSave': 'sandboxPlayerState',
  'gamePackage': 'project',
};

const _requiredDirectReadResourceKinds = <String>{
  'characterStudioCatalog',
  'characterStudioCharacter',
  'characterStudioDependency',
  'characterStudioReadiness',
  'itemCatalog',
  'itemDefinition',
  'itemUsage',
  'itemReadiness',
  'mapConnection',
  'cinematicLibraryCatalog',
  'cinematicLibraryFolder',
  'cinematicLibraryEntry',
  'presentationCinematic',
  'presentationCinematicTemplate',
  'presentationTrack',
  'presentationClip',
  'presentationLayer',
  'presentationVisualFolder',
  'presentationPreviewContext',
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
