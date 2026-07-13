import '../catalogs/narrative_outcome_event_source_catalog.dart';
import '../diagnostics/scene_diagnostics.dart';
import '../models/map_data.dart';
import '../models/narrative_event_source_ref.dart';
import '../models/project_manifest.dart';
import '../models/scenario_asset.dart';
import '../models/scene_asset.dart';
import '../models/scene_consequence.dart';
import '../read_models/linked_asset_public_contracts.dart';
import '../runtime/scene_runtime_plan_builder.dart';
import 'narrative_event_canonical_json.dart';

/// Builds a project-wide, producer-qualified catalog of Event V2 outcomes.
///
/// Yarn expectations remain visible but are selectable only when a Scene end
/// explicitly re-emits the same qualified outcome.
/// Map data is optional, but a Scene that needs it stays unavailable until the
/// exact map snapshot is supplied and its references can be verified.
/// Battle outcomes are adapted from map_core's public linked-asset contracts;
/// this operation has no dependency on map_battle.
NarrativeOutcomeEventSourceCatalog buildNarrativeOutcomeEventSourceCatalog({
  required ProjectManifest project,
  List<MapData> maps = const [],
  List<NarrativeOutcomeRef> referencedOutcomes = const [],
}) {
  final options = <NarrativeOutcomeEventSourceOption>[];
  final diagnostics = <NarrativeOutcomeEventSourceDiagnostic>[];
  final battleContracts = buildBattlePublicContracts(project);
  final mapsById = _uniqueMapsById(maps);

  _appendSceneOutcomes(
    project.scenes,
    project: project,
    mapsById: mapsById,
    options: options,
    diagnostics: diagnostics,
  );
  _appendBattleOutcomes(
    battleContracts,
    options: options,
    diagnostics: diagnostics,
  );
  _appendLegacyScenarioOutcomes(
    project.scenarios,
    options: options,
    diagnostics: diagnostics,
  );
  _appendMissingReferences(
    project: project,
    battleContracts: battleContracts,
    explicitReferences: referencedOutcomes,
    options: options,
    diagnostics: diagnostics,
  );

  options.sort(_compareOptions);
  diagnostics.sort(_compareDiagnostics);
  return NarrativeOutcomeEventSourceCatalog(
    options: options,
    diagnostics: diagnostics,
  );
}

void _appendSceneOutcomes(
  List<SceneAsset> scenes, {
  required ProjectManifest project,
  required Map<String, MapData> mapsById,
  required List<NarrativeOutcomeEventSourceOption> options,
  required List<NarrativeOutcomeEventSourceDiagnostic> diagnostics,
}) {
  final byId = <String, List<SceneAsset>>{};
  for (final scene in scenes) {
    byId.putIfAbsent(scene.id, () => []).add(scene);
  }
  final ids = byId.keys.toList()..sort(compareNarrativeEventUtf16);
  for (final id in ids) {
    final group = byId[id]!;
    final duplicate = group.length > 1;
    if (duplicate) {
      diagnostics.add(
        NarrativeOutcomeEventSourceDiagnostic(
          code: 'duplicateProducerId',
          message: 'Plusieurs Scenes utilisent l’identifiant ${_debug(id)}.',
        ),
      );
    }
    for (final scene in group) {
      _appendSingleSceneOutcomes(
        scene,
        project: project,
        mapsById: mapsById,
        duplicate: duplicate,
        options: options,
        diagnostics: diagnostics,
      );
    }
  }
}

void _appendSingleSceneOutcomes(
  SceneAsset scene, {
  required ProjectManifest project,
  required Map<String, MapData> mapsById,
  required bool duplicate,
  required List<NarrativeOutcomeEventSourceOption> options,
  required List<NarrativeOutcomeEventSourceDiagnostic> diagnostics,
}) {
  final sceneLabel = _label(scene.name, scene.id, fallback: 'Scene sans nom');
  final reachableNodes = _reachableSceneNodeIds(scene);
  final declarations = <String, SceneOutcome>{
    for (final outcome in scene.declaredOutcomes) outcome.id: outcome,
  };
  final emissions = <String, List<_SceneOutcomeEmission>>{};
  final dialogueExpectedOutcomes = <String>{};
  for (final node in scene.graph.nodes) {
    final payload = node.payload;
    if (payload is SceneEndPayload && payload.sceneOutcomeId != null) {
      emissions.putIfAbsent(payload.sceneOutcomeId!, () => []).add(
            _SceneOutcomeEmission(
              reachable: reachableNodes.contains(node.id),
            ),
          );
    } else if (payload is SceneYarnDialoguePayload) {
      dialogueExpectedOutcomes.addAll(payload.expectedOutcomes);
    }
  }

  final outcomeIds = <String>{
    ...declarations.keys,
    ...emissions.keys,
    ...dialogueExpectedOutcomes,
  }.toList()
    ..sort(compareNarrativeEventUtf16);
  final sceneRuntimeBuildable = buildSceneRuntimePlan(scene).canBuild;
  final sceneProjectReferencesValid = diagnoseSceneAgainstProject(
        scene,
        project,
        mapsById: mapsById,
      ).errorCount ==
      0;
  final sceneMapReferencesVerifiable =
      _sceneMapReferencesVerifiable(scene, mapsById);
  final sceneBuildable = sceneRuntimeBuildable &&
      sceneProjectReferencesValid &&
      sceneMapReferencesVerifiable;
  for (final outcomeId in outcomeIds) {
    final declared = declarations[outcomeId];
    final outcomeEmissions = emissions[outcomeId] ?? const [];
    final reachableEmission =
        outcomeEmissions.any((emission) => emission.reachable);
    final dialogueExpected = dialogueExpectedOutcomes.contains(outcomeId);
    final baseStatus = _sceneOutcomeStatus(
      declared: declared != null,
      hasEmission: outcomeEmissions.isNotEmpty,
      reachableEmission: reachableEmission,
      dialogueExpected: dialogueExpected,
    );
    final outcome = _outcomeRef(
      NarrativeOutcomeProducerKind.scene,
      scene.id,
      outcomeId,
    );
    final identityValid = outcome != null;
    final status = duplicate
        ? NarrativeOutcomeReachabilityStatus.producerDuplicate
        : !sceneBuildable || !identityValid
            ? NarrativeOutcomeReachabilityStatus.producerInvalid
            : baseStatus;
    final selectable = outcome != null &&
        status == NarrativeOutcomeReachabilityStatus.reachable;
    final optionDiagnostics = _sceneOptionDiagnostics(
      scene: scene,
      outcome: outcome,
      declared: declared != null,
      emissions: outcomeEmissions,
      duplicate: duplicate,
      sceneRuntimeBuildable: sceneRuntimeBuildable,
      sceneProjectReferencesValid: sceneProjectReferencesValid,
      sceneMapReferencesVerifiable: sceneMapReferencesVerifiable,
      identityValid: identityValid,
      dialogueExpected: dialogueExpected,
    );
    diagnostics.addAll(optionDiagnostics);
    final outcomeLabel = declared == null
        ? _label(outcomeId, outcomeId, fallback: 'Outcome sans nom')
        : _label(declared.label, outcomeId, fallback: 'Outcome sans nom');
    options.add(
      NarrativeOutcomeEventSourceOption(
        outcome: outcome,
        producerLabel: sceneLabel,
        outcomeLabel: outcomeLabel,
        humanSourceSentence:
            'Après l’issue $outcomeLabel de la Scene $sceneLabel.',
        status: status,
        selectable: selectable,
        unavailableReason: selectable ? null : _sceneUnavailableReason(status),
        origin: NarrativeOutcomeSourceOrigin.scene,
        debugTechnicalLabel:
            'scene:${_debug(scene.id)}:outcome:${_debug(outcomeId)}',
        diagnostics: optionDiagnostics,
      ),
    );
  }
}

NarrativeOutcomeReachabilityStatus _sceneOutcomeStatus({
  required bool declared,
  required bool hasEmission,
  required bool reachableEmission,
  required bool dialogueExpected,
}) {
  if (!declared && !hasEmission && dialogueExpected) {
    return NarrativeOutcomeReachabilityStatus.dialogueOutcomeNotReEmitted;
  }
  if (!declared) {
    return NarrativeOutcomeReachabilityStatus.emittedButUndeclared;
  }
  if (!hasEmission) {
    return NarrativeOutcomeReachabilityStatus.declaredButNotEmitted;
  }
  if (!reachableEmission) {
    return NarrativeOutcomeReachabilityStatus.emittedButUnreachable;
  }
  return NarrativeOutcomeReachabilityStatus.reachable;
}

List<NarrativeOutcomeEventSourceDiagnostic> _sceneOptionDiagnostics({
  required SceneAsset scene,
  required NarrativeOutcomeRef? outcome,
  required bool declared,
  required List<_SceneOutcomeEmission> emissions,
  required bool duplicate,
  required bool sceneRuntimeBuildable,
  required bool sceneProjectReferencesValid,
  required bool sceneMapReferencesVerifiable,
  required bool identityValid,
  required bool dialogueExpected,
}) {
  final result = <NarrativeOutcomeEventSourceDiagnostic>[];
  if (duplicate) {
    result.add(
      NarrativeOutcomeEventSourceDiagnostic(
        code: 'duplicateProducerId',
        message: 'Cette Scene ne possède pas une identité projet unique.',
        outcome: outcome,
      ),
    );
  }
  if (!sceneRuntimeBuildable) {
    result.add(
      NarrativeOutcomeEventSourceDiagnostic(
        code: 'sceneNotBuildable',
        message: 'Cette Scene ne produit pas de plan exécutable valide.',
        outcome: outcome,
      ),
    );
  }
  if (!sceneProjectReferencesValid) {
    result.add(
      NarrativeOutcomeEventSourceDiagnostic(
        code: 'sceneProjectReferencesInvalid',
        message: 'Cette Scene référence une ressource absente du projet.',
        outcome: outcome,
      ),
    );
  }
  if (!sceneMapReferencesVerifiable) {
    result.add(
      NarrativeOutcomeEventSourceDiagnostic(
        code: 'sceneMapDataUnavailable',
        message:
            'Les données de map nécessaires pour vérifier cette Scene sont absentes ou ambiguës.',
        outcome: outcome,
      ),
    );
  }
  if (!identityValid) {
    result.add(
      NarrativeOutcomeEventSourceDiagnostic(
        code: 'invalidOutcomeIdentity',
        message:
            'La Scene ou cet outcome ne possède pas une identité persistable.',
        outcome: outcome,
      ),
    );
  }
  if (!declared && emissions.isNotEmpty) {
    result.add(
      NarrativeOutcomeEventSourceDiagnostic(
        code: 'emittedOutcomeUndeclared',
        message: 'Cet outcome est émis mais absent des déclarations de Scene.',
        outcome: outcome,
      ),
    );
  }
  if (declared && emissions.isEmpty) {
    result.add(
      NarrativeOutcomeEventSourceDiagnostic(
        code: 'declaredOutcomeNotEmitted',
        message: 'Cet outcome est déclaré mais aucune étape ne l’émet.',
        outcome: outcome,
      ),
    );
  }
  if (emissions.isNotEmpty &&
      !emissions.any((emission) => emission.reachable)) {
    result.add(
      NarrativeOutcomeEventSourceDiagnostic(
        code: 'outcomeEmissionUnreachable',
        message: 'L’étape qui émet cet outcome est inaccessible.',
        outcome: outcome,
      ),
    );
  }
  if (dialogueExpected) {
    result.add(
      NarrativeOutcomeEventSourceDiagnostic(
        code: emissions.isEmpty
            ? 'yarnOutcomeNotReEmitted'
            : 'yarnOutcomeReEmittedByScene',
        message: emissions.isEmpty
            ? 'Ce résultat de dialogue doit être réémis par une fin de Scene.'
            : 'Ce résultat de dialogue est réémis explicitement par la Scene.',
        outcome: outcome,
      ),
    );
  }
  return List.unmodifiable(result);
}

Map<String, MapData> _uniqueMapsById(List<MapData> maps) {
  final grouped = <String, List<MapData>>{};
  for (final map in maps) {
    grouped.putIfAbsent(map.id, () => []).add(map);
  }
  return Map.unmodifiable({
    for (final entry in grouped.entries)
      if (entry.value.length == 1) entry.key: entry.value.single,
  });
}

bool _sceneMapReferencesVerifiable(
  SceneAsset scene,
  Map<String, MapData> mapsById,
) {
  for (final node in scene.graph.nodes) {
    final payload = node.payload;
    if (payload is! SceneActionPayload) continue;
    final consequence = payload.consequence;
    if (consequence is SceneMarkEventConsumedConsequence &&
        !mapsById.containsKey(consequence.mapId)) {
      return false;
    }
  }
  return true;
}

String _sceneUnavailableReason(NarrativeOutcomeReachabilityStatus status) {
  return switch (status) {
    NarrativeOutcomeReachabilityStatus.declaredButNotEmitted =>
      'Cet outcome est déclaré, mais aucune étape ne l’émet.',
    NarrativeOutcomeReachabilityStatus.emittedButUndeclared =>
      'Cet outcome doit être déclaré par la Scene.',
    NarrativeOutcomeReachabilityStatus.emittedButUnreachable =>
      'L’étape qui émet cet outcome n’est pas atteignable.',
    NarrativeOutcomeReachabilityStatus.dialogueOutcomeNotReEmitted =>
      'Ce résultat de dialogue n’est pas réémis par une fin de Scene.',
    NarrativeOutcomeReachabilityStatus.outcomeMissing =>
      'Le producteur existe, mais cet outcome n’est pas exposé.',
    NarrativeOutcomeReachabilityStatus.producerDuplicate =>
      'L’identifiant de cette Scene est dupliqué.',
    NarrativeOutcomeReachabilityStatus.producerInvalid =>
      'Cette Scene ne peut pas produire un plan valide.',
    _ => 'Cet outcome de Scene n’est pas disponible.',
  };
}

Set<String> _reachableSceneNodeIds(SceneAsset scene) {
  final outgoing = <String, List<String>>{};
  for (final edge in scene.graph.edges) {
    outgoing.putIfAbsent(edge.fromNodeId, () => []).add(edge.toNodeId);
  }
  final known = {for (final node in scene.graph.nodes) node.id};
  final reached = <String>{};
  final queue = <String>[scene.graph.startNodeId];
  var cursor = 0;
  while (cursor < queue.length) {
    final nodeId = queue[cursor++];
    if (!known.contains(nodeId) || !reached.add(nodeId)) continue;
    queue.addAll(outgoing[nodeId] ?? const []);
  }
  return reached;
}

void _appendBattleOutcomes(
  List<BattlePublicContract> contracts, {
  required List<NarrativeOutcomeEventSourceOption> options,
  required List<NarrativeOutcomeEventSourceDiagnostic> diagnostics,
}) {
  final byProducer = <String, List<BattlePublicContract>>{};
  for (final contract in contracts) {
    byProducer.putIfAbsent(contract.battleRefId, () => []).add(contract);
  }
  final producerIds = byProducer.keys.toList()
    ..sort(compareNarrativeEventUtf16);
  for (final producerId in producerIds) {
    final group = byProducer[producerId]!;
    final duplicate = group.length > 1;
    if (duplicate) {
      diagnostics.add(
        NarrativeOutcomeEventSourceDiagnostic(
          code: 'duplicateProducerId',
          message: 'Plusieurs combats utilisent la référence $producerId.',
        ),
      );
    }
    for (final contract in group) {
      final stable = _exact(contract.trainerId) &&
          _exact(contract.battleRefId) &&
          contract.status == LinkedAssetContractStatus.available;
      for (final publicOutcome in contract.possibleOutcomes) {
        final outcome = stable
            ? _outcomeRef(
                NarrativeOutcomeProducerKind.battle,
                contract.battleRefId,
                publicOutcome.id,
              )
            : null;
        final status = duplicate
            ? NarrativeOutcomeReachabilityStatus.producerDuplicate
            : stable && outcome != null
                ? NarrativeOutcomeReachabilityStatus.available
                : NarrativeOutcomeReachabilityStatus.producerInvalid;
        final selectable =
            status == NarrativeOutcomeReachabilityStatus.available;
        final optionDiagnostics = <NarrativeOutcomeEventSourceDiagnostic>[
          for (final diagnostic in contract.diagnostics)
            NarrativeOutcomeEventSourceDiagnostic(
              code: diagnostic.code.name,
              message: diagnostic.message,
              outcome: outcome,
            ),
          if (duplicate)
            NarrativeOutcomeEventSourceDiagnostic(
              code: 'duplicateProducerId',
              message: 'Cette référence de combat n’est pas unique.',
              outcome: outcome,
            ),
        ];
        diagnostics.addAll(optionDiagnostics);
        options.add(
          NarrativeOutcomeEventSourceOption(
            outcome: outcome,
            producerLabel: _label(
              contract.label,
              contract.battleRefId,
              fallback: 'Combat sans nom',
            ),
            outcomeLabel: _label(
              publicOutcome.label,
              publicOutcome.id,
              fallback: 'Résultat sans nom',
            ),
            humanSourceSentence:
                'Après le résultat ${publicOutcome.label} du combat ${contract.label}.',
            status: status,
            selectable: selectable,
            unavailableReason: selectable
                ? null
                : duplicate
                    ? 'Cette référence de combat est dupliquée.'
                    : 'Ce combat ne possède pas une identité projet stable.',
            origin: NarrativeOutcomeSourceOrigin.battle,
            debugTechnicalLabel:
                'battle:${_debug(contract.battleRefId)}:outcome:${_debug(publicOutcome.id)}',
            diagnostics: optionDiagnostics,
          ),
        );
      }
    }
  }
}

void _appendLegacyScenarioOutcomes(
  List<ScenarioAsset> scenarios, {
  required List<NarrativeOutcomeEventSourceOption> options,
  required List<NarrativeOutcomeEventSourceDiagnostic> diagnostics,
}) {
  final byId = <String, List<ScenarioAsset>>{};
  for (final scenario in scenarios) {
    byId.putIfAbsent(scenario.id, () => []).add(scenario);
  }
  final ids = byId.keys.toList()..sort(compareNarrativeEventUtf16);
  for (final id in ids) {
    final group = byId[id]!;
    final duplicate = group.length > 1;
    if (duplicate) {
      diagnostics.add(
        NarrativeOutcomeEventSourceDiagnostic(
          code: 'duplicateProducerId',
          message: 'Plusieurs Scenarios utilisent l’identifiant ${_debug(id)}.',
        ),
      );
    }
    for (final scenario in group) {
      final compatibleOutcomeIds = <String>{
        for (final value in scenario.declaredOutcomes)
          if (value.trim().isNotEmpty) value.trim(),
      };
      final incompatibleBindingOutcomeIds = <String>{};
      for (final node in scenario.nodes) {
        final actionKind = node.payload.actionKind?.trim();
        final outcomeId = node.binding.outcomeId?.trim();
        if ((actionKind == 'sourceOutcome' || actionKind == 'emitOutcome') &&
            outcomeId != null &&
            outcomeId.isNotEmpty) {
          final runtimeCompatible = (actionKind == 'sourceOutcome' &&
                  node.type == ScenarioNodeType.reference) ||
              (actionKind == 'emitOutcome' &&
                  node.type == ScenarioNodeType.action);
          (runtimeCompatible
                  ? compatibleOutcomeIds
                  : incompatibleBindingOutcomeIds)
              .add(outcomeId);
        }
      }
      final outcomeIds = <String>{
        ...compatibleOutcomeIds,
        ...incompatibleBindingOutcomeIds,
      };
      final sortedOutcomeIds = outcomeIds.toList()
        ..sort(compareNarrativeEventUtf16);
      for (final outcomeId in sortedOutcomeIds) {
        final outcome = _outcomeRef(
          NarrativeOutcomeProducerKind.legacyScenario,
          scenario.id,
          outcomeId,
        );
        final bindingCompatible = compatibleOutcomeIds.contains(outcomeId);
        final hasIgnoredBinding =
            incompatibleBindingOutcomeIds.contains(outcomeId);
        final valid = outcome != null && !duplicate && bindingCompatible;
        final optionDiagnostics = <NarrativeOutcomeEventSourceDiagnostic>[
          if (valid)
            NarrativeOutcomeEventSourceDiagnostic(
              code: 'legacyScenarioCompatibility',
              message:
                  'Cet outcome reste qualifié par son Scenario historique.',
              outcome: outcome,
            ),
          if (duplicate)
            NarrativeOutcomeEventSourceDiagnostic(
              code: 'duplicateProducerId',
              message: 'Ce Scenario ne possède pas une identité unique.',
              outcome: outcome,
            ),
          if (outcome == null)
            NarrativeOutcomeEventSourceDiagnostic(
              code: 'invalidOutcomeIdentity',
              message:
                  'Ce Scenario ou cet outcome ne possède pas une identité persistable.',
              outcome: outcome,
            ),
          if (!bindingCompatible)
            NarrativeOutcomeEventSourceDiagnostic(
              code: 'legacyOutcomeBindingInvalid',
              message:
                  'Ce binding legacy ne peut pas produire ou recevoir cet outcome au runtime.',
              outcome: outcome,
            )
          else if (hasIgnoredBinding)
            NarrativeOutcomeEventSourceDiagnostic(
              code: 'legacyOutcomeBindingIgnored',
              message:
                  'Un binding legacy incompatible a été ignoré pour cet outcome.',
              outcome: outcome,
            ),
        ];
        diagnostics.addAll(optionDiagnostics);
        final label = _label(
          scenario.name,
          scenario.id,
          fallback: 'Scenario sans nom',
        );
        options.add(
          NarrativeOutcomeEventSourceOption(
            outcome: outcome,
            producerLabel: label,
            outcomeLabel:
                _label(outcomeId, outcomeId, fallback: 'Outcome sans nom'),
            humanSourceSentence:
                'Après l’issue $outcomeId du Scenario historique $label.',
            status: duplicate
                ? NarrativeOutcomeReachabilityStatus.producerDuplicate
                : outcome == null
                    ? NarrativeOutcomeReachabilityStatus.producerInvalid
                    : !bindingCompatible
                        ? NarrativeOutcomeReachabilityStatus
                            .legacyBindingInvalid
                        : NarrativeOutcomeReachabilityStatus.legacyCompatible,
            selectable: valid,
            unavailableReason: valid
                ? null
                : duplicate
                    ? 'L’identifiant de ce Scenario est dupliqué.'
                    : outcome == null
                        ? 'Ce Scenario ou cet outcome possède un identifiant invalide.'
                        : 'Ce binding legacy ne correspond pas à un nœud exécutable.',
            origin: NarrativeOutcomeSourceOrigin.legacyScenario,
            debugTechnicalLabel:
                'legacyScenario:${_debug(scenario.id)}:outcome:${_debug(outcomeId)}',
            diagnostics: optionDiagnostics,
          ),
        );
      }
    }
  }
}

void _appendMissingReferences({
  required ProjectManifest project,
  required List<BattlePublicContract> battleContracts,
  required List<NarrativeOutcomeRef> explicitReferences,
  required List<NarrativeOutcomeEventSourceOption> options,
  required List<NarrativeOutcomeEventSourceDiagnostic> diagnostics,
}) {
  final references = <NarrativeOutcomeRef>{...explicitReferences};
  final registry = project.eventRegistry;
  if (registry != null) {
    for (final record in registry.records) {
      final source =
          record.definitionOrNull?.source ?? record.draftOrNull?.source;
      if (source == null) continue;
      source.when<void>(
        entityInteract: (_, __) {},
        triggerEnter: (_, __) {},
        mapEnter: (_) {},
        outcomeReceived: references.add,
      );
    }
  }
  final existingOutcomes = <NarrativeOutcomeRef>{
    for (final option in options)
      if (option.outcome != null) option.outcome!,
  };
  final producers = <(NarrativeOutcomeProducerKind, String)>{
    for (final scene in project.scenes)
      (NarrativeOutcomeProducerKind.scene, scene.id),
    for (final battle in battleContracts)
      (NarrativeOutcomeProducerKind.battle, battle.battleRefId),
    for (final scenario in project.scenarios)
      (NarrativeOutcomeProducerKind.legacyScenario, scenario.id),
  };
  final sortedReferences = references.toList()..sort(_compareOutcomeRefs);
  for (final reference in sortedReferences) {
    if (existingOutcomes.contains(reference)) continue;
    final producerExists = producers.contains(
      (reference.producerKind, reference.producerId),
    );
    final code = producerExists ? 'missingOutcome' : 'missingProducer';
    final reason = producerExists
        ? 'Le producteur existe, mais cet outcome n’est pas exposé.'
        : 'Le producteur de cet outcome est introuvable.';
    final diagnostic = NarrativeOutcomeEventSourceDiagnostic(
      code: code,
      message: reason,
      outcome: reference,
    );
    diagnostics.add(diagnostic);
    final producerLabel = _missingProducerLabel(reference);
    options.add(
      NarrativeOutcomeEventSourceOption(
        outcome: reference,
        producerLabel: producerLabel,
        outcomeLabel: reference.outcomeId,
        humanSourceSentence: producerExists
            ? 'Outcome ${reference.outcomeId} non exposé par $producerLabel.'
            : 'Outcome ${reference.outcomeId} référencé sans producteur disponible.',
        status: producerExists
            ? NarrativeOutcomeReachabilityStatus.outcomeMissing
            : NarrativeOutcomeReachabilityStatus.producerMissing,
        selectable: false,
        unavailableReason: reason,
        origin: NarrativeOutcomeSourceOrigin.referencedMissing,
        debugTechnicalLabel:
            'missing:${reference.producerKind.name}:${reference.producerId}:${reference.outcomeId}',
        diagnostics: [diagnostic],
      ),
    );
    existingOutcomes.add(reference);
  }
}

String _missingProducerLabel(NarrativeOutcomeRef reference) {
  return switch (reference.producerKind) {
    NarrativeOutcomeProducerKind.scene => 'Scene ${reference.producerId}',
    NarrativeOutcomeProducerKind.battle => 'Combat ${reference.producerId}',
    NarrativeOutcomeProducerKind.legacyScenario =>
      'Scenario ${reference.producerId}',
  };
}

NarrativeOutcomeRef? _outcomeRef(
  NarrativeOutcomeProducerKind kind,
  String producerId,
  String outcomeId,
) {
  if (!_exact(producerId) || !_exact(outcomeId)) return null;
  return NarrativeOutcomeRef(
    producerKind: kind,
    producerId: producerId,
    outcomeId: outcomeId,
  );
}

bool _exact(String value) => value.isNotEmpty && value.trim() == value;

String _label(String preferred, String id, {required String fallback}) {
  final preferredTrimmed = preferred.trim();
  if (preferredTrimmed.isNotEmpty) return preferredTrimmed;
  final idTrimmed = id.trim();
  return idTrimmed.isEmpty ? fallback : idTrimmed;
}

String _debug(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '<identifiant-invalide>' : trimmed;
}

int _compareOutcomeRefs(NarrativeOutcomeRef left, NarrativeOutcomeRef right) {
  for (final comparison in [
    left.producerKind.index.compareTo(right.producerKind.index),
    compareNarrativeEventUtf16(left.producerId, right.producerId),
    compareNarrativeEventUtf16(left.outcomeId, right.outcomeId),
  ]) {
    if (comparison != 0) return comparison;
  }
  return 0;
}

int _compareOptions(
  NarrativeOutcomeEventSourceOption left,
  NarrativeOutcomeEventSourceOption right,
) {
  final leftRef = left.outcome;
  final rightRef = right.outcome;
  for (final comparison in [
    (leftRef?.producerKind.index ?? left.origin.index)
        .compareTo(rightRef?.producerKind.index ?? right.origin.index),
    compareNarrativeEventUtf16(left.producerLabel, right.producerLabel),
    compareNarrativeEventUtf16(
      leftRef?.producerId ?? left.debugTechnicalLabel,
      rightRef?.producerId ?? right.debugTechnicalLabel,
    ),
    compareNarrativeEventUtf16(left.outcomeLabel, right.outcomeLabel),
    compareNarrativeEventUtf16(
      leftRef?.outcomeId ?? left.debugTechnicalLabel,
      rightRef?.outcomeId ?? right.debugTechnicalLabel,
    ),
    compareNarrativeEventUtf16(
      left.debugTechnicalLabel,
      right.debugTechnicalLabel,
    ),
    compareNarrativeEventUtf16(
      _safeOptionSortKey(left),
      _safeOptionSortKey(right),
    ),
  ]) {
    if (comparison != 0) return comparison;
  }
  return 0;
}

String _safeOptionSortKey(NarrativeOutcomeEventSourceOption option) {
  final value = option.toDebugJson();
  try {
    return canonicalizeNarrativeEventJson(value);
  } on FormatException {
    return value.toString();
  }
}

int _compareDiagnostics(
  NarrativeOutcomeEventSourceDiagnostic left,
  NarrativeOutcomeEventSourceDiagnostic right,
) {
  final leftRef = left.outcome;
  final rightRef = right.outcome;
  for (final comparison in [
    (leftRef?.producerKind.index ?? -1)
        .compareTo(rightRef?.producerKind.index ?? -1),
    compareNarrativeEventUtf16(
      leftRef?.producerId ?? '',
      rightRef?.producerId ?? '',
    ),
    compareNarrativeEventUtf16(
      leftRef?.outcomeId ?? '',
      rightRef?.outcomeId ?? '',
    ),
    compareNarrativeEventUtf16(left.code, right.code),
    compareNarrativeEventUtf16(left.message, right.message),
  ]) {
    if (comparison != 0) return comparison;
  }
  return 0;
}

final class _SceneOutcomeEmission {
  const _SceneOutcomeEmission({
    required this.reachable,
  });

  final bool reachable;
}
