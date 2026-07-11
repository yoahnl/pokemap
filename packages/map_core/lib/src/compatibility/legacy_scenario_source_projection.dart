import 'dart:convert';

import 'package:meta/meta.dart' show immutable;

import '../models/narrative_event_registry.dart';
import '../models/narrative_event_definition.dart';
import '../models/narrative_event_source_ref.dart';
import '../models/scenario_asset.dart';
import '../models/scene_asset.dart';
import '../models/script_conditions.dart';
import '../operations/narrative_event_claim_fingerprints.dart';
import '../operations/narrative_event_registry_codec.dart';
import '../runtime/scene_runtime_plan_builder.dart';
import 'legacy_event_migration_models.dart';

abstract final class LegacyScenarioDiagnosticCodes {
  static const nodeMissing = 'nodeMissing';
  static const nodeSnapshotMismatch = 'nodeSnapshotMismatch';
  static const malformedSource = 'malformedSource';
  static const outcomeQualificationRequired = 'outcomeQualificationRequired';
  static const lifecycleEvidenceMissing = 'lifecycleEvidenceMissing';
  static const multipleSources = 'multipleSources';
  static const graphOrchestrationPreserved = 'graphOrchestrationPreserved';
  static const unsupportedChoice = 'unsupportedChoice';
  static const sceneCandidateMissing = 'sceneCandidateMissing';
  static const sceneNotBuildable = 'sceneNotBuildable';
  static const sceneTraceMismatch = 'sceneTraceMismatch';
  static const invalidClaim = 'invalidClaim';
  static const claimFingerprintStale = 'claimFingerprintStale';
  static const claimSourceMismatch = 'claimSourceMismatch';
  static const globalClaimConflict = 'globalClaimConflict';
}

enum LegacyScenarioGraphComplexity {
  simpleLinear,
  multipleSources,
  branchingOrOrchestrated,
  malformed,
}

enum LegacyScenarioLifecycleEvidence { reusable, oneShot, ambiguous }

@immutable
final class LegacyScenarioActionProjection {
  LegacyScenarioActionProjection({
    required String nodeId,
    required this.nodeType,
    required String actionKind,
  })  : nodeId = _requireText(nodeId, 'nodeId'),
        actionKind = _requireText(actionKind, 'actionKind');

  final String nodeId;
  final ScenarioNodeType nodeType;
  final String actionKind;

  Map<String, Object?> toJson() => {
        'nodeId': nodeId,
        'nodeType': nodeType.name,
        'actionKind': actionKind,
      };
}

@immutable
final class LegacyScenarioSourceProjection {
  LegacyScenarioSourceProjection({
    required String scenarioId,
    required String nodeId,
    required this.provenance,
    required this.source,
    required this.sceneCandidateId,
    required this.lifecycleEvidence,
    required this.reusePolicyCandidate,
    required this.graphComplexity,
    required this.classification,
    required this.claimStatus,
    required this.existingClaim,
    required String sourceFingerprint,
    required List<LegacyScenarioActionProjection> actions,
    required List<ScriptCondition> conditions,
    required Map<String, Object?> preservedScenarioJson,
    required List<LegacyMigrationDiagnostic> diagnostics,
    required List<String> manualActions,
  })  : scenarioId = _requireText(scenarioId, 'scenarioId'),
        nodeId = _requireText(nodeId, 'nodeId'),
        sourceFingerprint = _requireText(
          sourceFingerprint,
          'sourceFingerprint',
        ),
        actions = List.unmodifiable(actions),
        conditions = List.unmodifiable(conditions),
        preservedScenarioJson = _freezeObject(
          _normalizeJson(preservedScenarioJson),
        ),
        diagnostics = List.unmodifiable(diagnostics),
        manualActions = List.unmodifiable(manualActions);

  final String scenarioId;
  final String nodeId;
  final LegacySourceRef provenance;
  final NarrativeEventSourceRef? source;
  final String? sceneCandidateId;
  final LegacyScenarioLifecycleEvidence lifecycleEvidence;
  final NarrativeEventReusePolicy? reusePolicyCandidate;
  final LegacyScenarioGraphComplexity graphComplexity;
  final LegacyMigrationClassification classification;
  final LegacyProjectionClaimStatus claimStatus;
  final LegacySourceClaim? existingClaim;
  final String sourceFingerprint;
  final List<LegacyScenarioActionProjection> actions;
  final List<ScriptCondition> conditions;
  final Map<String, Object?> preservedScenarioJson;
  final List<LegacyMigrationDiagnostic> diagnostics;
  final List<String> manualActions;

  Map<String, Object?> toJson() => {
        'scenarioId': scenarioId,
        'nodeId': nodeId,
        'provenance': provenance.toJson(),
        if (source != null) 'source': source!.toJson(),
        if (sceneCandidateId != null) 'sceneCandidateId': sceneCandidateId,
        'lifecycleEvidence': lifecycleEvidence.name,
        if (reusePolicyCandidate != null)
          'reusePolicyCandidate': reusePolicyCandidate!.name,
        'graphComplexity': graphComplexity.name,
        'classification': classification.name,
        'claimStatus': claimStatus.name,
        if (existingClaim != null) 'existingClaim': existingClaim!.toJson(),
        'sourceFingerprint': sourceFingerprint,
        'actions': [for (final action in actions) action.toJson()],
        'conditions': [
          for (final condition in conditions) condition.toJson(),
        ],
        'preservedScenarioJson': preservedScenarioJson,
        'diagnostics': [
          for (final diagnostic in diagnostics) diagnostic.toJson(),
        ],
        'manualActions': manualActions,
      };
}

LegacyScenarioSourceProjection projectLegacyScenarioSourceReadOnly({
  required ScenarioAsset scenario,
  required ScenarioNode node,
  required List<SceneAsset> scenes,
  required ValidatedLegacyClaimIndex claimIndex,
  LegacyScenarioLifecycleEvidence lifecycleEvidence =
      LegacyScenarioLifecycleEvidence.ambiguous,
}) {
  final requestedNodeId = node.id;
  final provenance = LegacySourceRef.scenarioSourceNode(
    scenario.id,
    requestedNodeId,
  );
  var classification = LegacyMigrationClassification.autoSafe;
  var complexity = LegacyScenarioGraphComplexity.simpleLinear;
  final diagnostics = <LegacyMigrationDiagnostic>[];
  final manualActions = <String>[];
  final reusePolicyCandidate = switch (lifecycleEvidence) {
    LegacyScenarioLifecycleEvidence.reusable =>
      NarrativeEventReusePolicy.reusable,
    LegacyScenarioLifecycleEvidence.oneShot =>
      NarrativeEventReusePolicy.oneShot,
    LegacyScenarioLifecycleEvidence.ambiguous => null,
  };

  void escalate(LegacyMigrationClassification next) {
    if (_classificationRank(next) > _classificationRank(classification)) {
      classification = next;
    }
  }

  void diagnose(
    String code,
    LegacyMigrationDiagnosticSeverity severity,
    String message,
    String path,
  ) {
    diagnostics.add(
      LegacyMigrationDiagnostic(
        code: code,
        severity: severity,
        message: message,
        path: path,
      ),
    );
  }

  if (lifecycleEvidence == LegacyScenarioLifecycleEvidence.ambiguous) {
    escalate(LegacyMigrationClassification.assisted);
    manualActions.add('Confirm whether this Scenario is reusable or one-shot.');
    diagnose(
      LegacyScenarioDiagnosticCodes.lifecycleEvidenceMissing,
      LegacyMigrationDiagnosticSeverity.warning,
      'Project-level lifecycle references have not been qualified.',
      'scenario.lifecycle',
    );
  }

  final actualNodes = scenario.nodes
      .where((candidate) => candidate.id == requestedNodeId)
      .toList(growable: false);
  final hasCanonicalNode = actualNodes.length == 1;
  var effectiveNode = node;
  if (!hasCanonicalNode) {
    complexity = LegacyScenarioGraphComplexity.malformed;
    escalate(LegacyMigrationClassification.blocked);
    diagnose(
      LegacyScenarioDiagnosticCodes.nodeMissing,
      LegacyMigrationDiagnosticSeverity.error,
      'The source node is absent from the complete ScenarioAsset.',
      'scenario.nodes',
    );
  } else {
    effectiveNode = actualNodes.single;
    if (effectiveNode != node) {
      escalate(LegacyMigrationClassification.blocked);
      diagnose(
        LegacyScenarioDiagnosticCodes.nodeSnapshotMismatch,
        LegacyMigrationDiagnosticSeverity.error,
        'The supplied node snapshot differs from the complete ScenarioAsset.',
        'scenario.nodes.$requestedNodeId',
      );
    }
  }

  final isUnqualifiedOutcome = hasCanonicalNode &&
      effectiveNode.type == ScenarioNodeType.reference &&
      effectiveNode.payload.actionKind == 'sourceOutcome' &&
      _exact(effectiveNode.binding.outcomeId);
  final source = hasCanonicalNode ? _readScenarioSource(effectiveNode) : null;
  if (source == null && !isUnqualifiedOutcome) {
    complexity = LegacyScenarioGraphComplexity.malformed;
    escalate(LegacyMigrationClassification.blocked);
    diagnose(
      LegacyScenarioDiagnosticCodes.malformedSource,
      LegacyMigrationDiagnosticSeverity.error,
      'The legacy source binding is incomplete or non-exact.',
      'scenario.nodes.$requestedNodeId.binding',
    );
  } else if (isUnqualifiedOutcome) {
    escalate(LegacyMigrationClassification.assisted);
    manualActions.add(
      'Choose the producer that qualifies this legacy outcome.',
    );
    diagnose(
      LegacyScenarioDiagnosticCodes.outcomeQualificationRequired,
      LegacyMigrationDiagnosticSeverity.warning,
      'A legacy outcomeId does not identify its producer.',
      'scenario.nodes.$requestedNodeId.binding.outcomeId',
    );
  }

  final sourceNodes = scenario.nodes.where(_isScenarioSourceNode).toList();
  final hasChoice = scenario.nodes.any(
    (candidate) => candidate.type == ScenarioNodeType.choice,
  );
  final isSimple =
      hasCanonicalNode && _isSimpleLinearScenario(scenario, effectiveNode);
  if (sourceNodes.length > 1) {
    complexity = LegacyScenarioGraphComplexity.multipleSources;
    escalate(LegacyMigrationClassification.blocked);
    manualActions.add('Review and claim every source node in this Scenario.');
    diagnose(
      LegacyScenarioDiagnosticCodes.multipleSources,
      LegacyMigrationDiagnosticSeverity.error,
      'A multi-source Scenario cannot be projected as one Event silently.',
      'scenario.nodes',
    );
  } else if (hasChoice) {
    complexity = LegacyScenarioGraphComplexity.branchingOrOrchestrated;
    escalate(LegacyMigrationClassification.unsupported);
    diagnose(
      LegacyScenarioDiagnosticCodes.unsupportedChoice,
      LegacyMigrationDiagnosticSeverity.error,
      'Choice orchestration remains outside Event V2 V0.',
      'scenario.nodes',
    );
  } else if (!isSimple &&
      complexity != LegacyScenarioGraphComplexity.malformed) {
    complexity = LegacyScenarioGraphComplexity.branchingOrOrchestrated;
    escalate(LegacyMigrationClassification.legacyOnly);
    diagnose(
      LegacyScenarioDiagnosticCodes.graphOrchestrationPreserved,
      LegacyMigrationDiagnosticSeverity.warning,
      'The complete Scenario graph remains legacy orchestration.',
      'scenario',
    );
  }

  String? sceneCandidateId;
  if (isSimple &&
      (source != null || isUnqualifiedOutcome) &&
      sourceNodes.length == 1) {
    final rawSceneId = effectiveNode.metadata['eventV2.sceneId'];
    if (rawSceneId == null ||
        rawSceneId.isEmpty ||
        rawSceneId.trim() != rawSceneId) {
      escalate(LegacyMigrationClassification.blocked);
      manualActions.add('Choose an explicit Scene for this source.');
      diagnose(
        LegacyScenarioDiagnosticCodes.sceneCandidateMissing,
        LegacyMigrationDiagnosticSeverity.error,
        'No exact Scene candidate is encoded for this source node.',
        'scenario.nodes.$requestedNodeId.metadata.eventV2.sceneId',
      );
    } else {
      final matches = scenes.where((scene) => scene.id == rawSceneId).toList();
      if (matches.length != 1) {
        escalate(LegacyMigrationClassification.blocked);
        diagnose(
          LegacyScenarioDiagnosticCodes.sceneCandidateMissing,
          LegacyMigrationDiagnosticSeverity.error,
          'The encoded Scene candidate does not resolve exactly once.',
          'scenario.nodes.$requestedNodeId.metadata.eventV2.sceneId',
        );
      } else {
        final scene = matches.single;
        final plan = buildSceneRuntimePlan(scene);
        if (!plan.canBuild) {
          escalate(LegacyMigrationClassification.blocked);
          diagnose(
            LegacyScenarioDiagnosticCodes.sceneNotBuildable,
            LegacyMigrationDiagnosticSeverity.error,
            'The Scene candidate cannot produce a runtime plan.',
            'scenes.${scene.id}',
          );
        } else if (!_sameObservableTrace(
          scenario,
          requestedNodeId,
          scene,
        )) {
          escalate(LegacyMigrationClassification.blocked);
          diagnose(
            LegacyScenarioDiagnosticCodes.sceneTraceMismatch,
            LegacyMigrationDiagnosticSeverity.error,
            'Scenario and Scene observable traces are not equivalent.',
            'scenes.${scene.id}',
          );
        } else {
          sceneCandidateId = scene.id;
        }
      }
    }
  }

  final sourceFingerprint = computeScenarioSourceFingerprint(
    scenarioId: scenario.id,
    nodeId: requestedNodeId,
    scenario: scenario,
  );
  final indexedClaim = claimIndex.validByProvenance[provenance];
  final indexedInvalid = claimIndex.invalidByProvenance[provenance];
  var contextualClaim = indexedClaim;
  var contextualInvalid = indexedInvalid != null;
  if (indexedClaim != null) {
    final members = indexedClaim.members
        .where((member) => member.provenance == provenance)
        .toList();
    if (members.length != 1 ||
        members.single.sourceFingerprint != sourceFingerprint) {
      contextualClaim = null;
      contextualInvalid = true;
      escalate(LegacyMigrationClassification.blocked);
      diagnose(
        LegacyScenarioDiagnosticCodes.claimFingerprintStale,
        LegacyMigrationDiagnosticSeverity.error,
        'The claim no longer matches the complete ScenarioAsset fingerprint.',
        'claim.members',
      );
    }
    final claimSourceMatches = source != null
        ? indexedClaim.source == source
        : isUnqualifiedOutcome
            ? _claimMatchesUnqualifiedOutcome(
                indexedClaim,
                effectiveNode.binding.outcomeId!,
              )
            : true;
    if (!claimSourceMatches) {
      contextualClaim = null;
      contextualInvalid = true;
      escalate(LegacyMigrationClassification.blocked);
      diagnose(
        LegacyScenarioDiagnosticCodes.claimSourceMismatch,
        LegacyMigrationDiagnosticSeverity.error,
        'The claim source contradicts the projected Scenario source.',
        'claim.source',
      );
    }
  }
  if (indexedInvalid != null) {
    escalate(LegacyMigrationClassification.blocked);
    diagnose(
      LegacyScenarioDiagnosticCodes.invalidClaim,
      LegacyMigrationDiagnosticSeverity.error,
      'This source node is covered by an invalid or tombstone claim.',
      'claimIndex.invalidByProvenance',
    );
  }
  if (claimIndex.globalConflicts.isNotEmpty) {
    escalate(LegacyMigrationClassification.blocked);
    diagnose(
      LegacyScenarioDiagnosticCodes.globalClaimConflict,
      LegacyMigrationDiagnosticSeverity.error,
      'The claim index contains a global conflict.',
      'claimIndex.globalConflicts',
    );
  }
  final claimStatus = contextualClaim != null
      ? LegacyProjectionClaimStatus.valid
      : contextualInvalid
          ? LegacyProjectionClaimStatus.invalid
          : LegacyProjectionClaimStatus.absent;

  final conditions = <ScriptCondition>[
    if (scenario.activationCondition != null) scenario.activationCondition!,
    for (final candidate in scenario.nodes)
      if (candidate.payload.condition != null) candidate.payload.condition!,
  ];
  final actions = <LegacyScenarioActionProjection>[
    for (final candidate in scenario.nodes)
      if (candidate.type == ScenarioNodeType.action ||
          candidate.type == ScenarioNodeType.dialogue)
        LegacyScenarioActionProjection(
          nodeId: candidate.id,
          nodeType: candidate.type,
          actionKind: candidate.type == ScenarioNodeType.dialogue
              ? 'dialogue:${candidate.binding.dialogueId ?? ''}'
              : candidate.payload.actionKind ?? 'action:unknown',
        ),
  ];

  return LegacyScenarioSourceProjection(
    scenarioId: scenario.id,
    nodeId: requestedNodeId,
    provenance: provenance,
    source: source,
    sceneCandidateId: sceneCandidateId,
    lifecycleEvidence: lifecycleEvidence,
    reusePolicyCandidate: reusePolicyCandidate,
    graphComplexity: complexity,
    classification: classification,
    claimStatus: claimStatus,
    existingClaim: contextualClaim,
    sourceFingerprint: sourceFingerprint,
    actions: actions,
    conditions: conditions,
    preservedScenarioJson: Map<String, Object?>.from(
      jsonDecode(jsonEncode(scenario.toJson())) as Map,
    ),
    diagnostics: diagnostics,
    manualActions: manualActions,
  );
}

bool _claimMatchesUnqualifiedOutcome(
  LegacySourceClaim claim,
  String outcomeId,
) {
  return claim.source.when(
    entityInteract: (_, __) => false,
    triggerEnter: (_, __) => false,
    mapEnter: (_) => false,
    outcomeReceived: (outcome) => outcome.outcomeId == outcomeId,
  );
}

@immutable
final class ScenarioAuthoringClaimGuardResult {
  ScenarioAuthoringClaimGuardResult({
    required this.blocked,
    required this.message,
    required List<LegacySourceRef> claimedProvenances,
    required List<NarrativeEventSourceRef> conflictingSources,
  })  : claimedProvenances = List.unmodifiable(claimedProvenances),
        conflictingSources = List.unmodifiable(conflictingSources);

  final bool blocked;
  final String? message;
  final List<LegacySourceRef> claimedProvenances;
  final List<NarrativeEventSourceRef> conflictingSources;
}

ScenarioAuthoringClaimGuardResult evaluateScenarioAuthoringClaimGuard({
  required ValidatedLegacyClaimIndex claimIndex,
  ScenarioAsset? existingScenario,
  ScenarioAsset? proposedScenario,
}) {
  if (existingScenario == null && proposedScenario == null) {
    throw ArgumentError('An existing or proposed Scenario is required.');
  }
  final claimedProvenanceKeys = <LegacySourceRef>{
    ...claimIndex.validByProvenance.keys,
    ...claimIndex.invalidByProvenance.keys,
  };
  final claimedProvenances = <LegacySourceRef>[];
  if (existingScenario != null) {
    for (final provenance in claimedProvenanceKeys) {
      if (_belongsToScenario(provenance, existingScenario.id)) {
        claimedProvenances.add(provenance);
      }
    }
  }
  if (proposedScenario != null &&
      (existingScenario == null ||
          existingScenario.id != proposedScenario.id)) {
    for (final provenance in claimedProvenanceKeys) {
      if (_belongsToScenario(provenance, proposedScenario.id) &&
          !claimedProvenances.contains(provenance)) {
        claimedProvenances.add(provenance);
      }
    }
  }
  final claimedSources = <NarrativeEventSourceRef>{
    ...claimIndex.validBySource.keys,
    ...claimIndex.invalidBySource.keys,
  };
  final conflictingSources = <NarrativeEventSourceRef>{};
  for (final source in claimedSources) {
    final existingMatches = existingScenario == null
        ? 0
        : _scenarioSourceMatchCount(existingScenario, source);
    final proposedMatches = proposedScenario == null
        ? 0
        : _scenarioSourceMatchCount(proposedScenario, source);
    if (existingMatches > 0 || proposedMatches > 0) {
      conflictingSources.add(source);
    }
  }
  final blocked = claimedProvenances.isNotEmpty ||
      conflictingSources.isNotEmpty ||
      claimIndex.globalConflicts.isNotEmpty;
  return ScenarioAuthoringClaimGuardResult(
    blocked: blocked,
    message: blocked
        ? 'Cette source est gérée par Event Builder V2. '
            'Ouvrez les événements liés ou retirez explicitement la migration.'
        : null,
    claimedProvenances: claimedProvenances,
    conflictingSources: conflictingSources.toList(growable: false),
  );
}

bool _belongsToScenario(LegacySourceRef provenance, String scenarioId) {
  return provenance.when(
    mapEvent: (_, __) => false,
    scenarioSourceNode: (candidateScenarioId, _) =>
        candidateScenarioId == scenarioId,
  );
}

int _scenarioSourceMatchCount(
  ScenarioAsset scenario,
  NarrativeEventSourceRef source,
) {
  return scenario.nodes
      .where((node) => _legacyScenarioNodeMayMatchSource(node, source))
      .length;
}

bool _legacyScenarioNodeMayMatchSource(
  ScenarioNode node,
  NarrativeEventSourceRef source,
) {
  if (node.type != ScenarioNodeType.reference) return false;
  final actionKind = node.payload.actionKind?.trim() ?? '';
  final bindingMapId = node.binding.mapId?.trim() ?? '';
  return source.when(
    entityInteract: (mapId, entityId) =>
        actionKind == 'sourceEntityInteract' &&
        (bindingMapId.isEmpty || bindingMapId == mapId) &&
        node.binding.entityId?.trim() == entityId,
    triggerEnter: (mapId, triggerId) =>
        actionKind == 'sourceTriggerEnter' &&
        (bindingMapId.isEmpty || bindingMapId == mapId) &&
        node.binding.triggerId?.trim() == triggerId,
    mapEnter: (mapId) =>
        actionKind == 'sourceMapEnter' &&
        (bindingMapId.isEmpty || bindingMapId == mapId),
    outcomeReceived: (outcome) =>
        actionKind == 'sourceOutcome' &&
        node.binding.outcomeId?.trim() == outcome.outcomeId,
  );
}

NarrativeEventSourceRef? _readScenarioSource(ScenarioNode node) {
  if (node.type != ScenarioNodeType.reference) return null;
  final binding = node.binding;
  return switch (node.payload.actionKind) {
    'sourceMapEnter' when _exact(binding.mapId) =>
      NarrativeEventSourceRef.mapEnter(binding.mapId!),
    'sourceTriggerEnter'
        when _exact(binding.mapId) && _exact(binding.triggerId) =>
      NarrativeEventSourceRef.triggerEnter(
        binding.mapId!,
        binding.triggerId!,
      ),
    'sourceEntityInteract'
        when _exact(binding.mapId) && _exact(binding.entityId) =>
      NarrativeEventSourceRef.entityInteract(
        binding.mapId!,
        binding.entityId!,
      ),
    _ => null,
  };
}

bool _isScenarioSourceNode(ScenarioNode node) {
  return node.type == ScenarioNodeType.reference &&
      const {
        'sourceMapEnter',
        'sourceTriggerEnter',
        'sourceEntityInteract',
        'sourceOutcome',
      }.contains(node.payload.actionKind);
}

bool _isSimpleLinearScenario(ScenarioAsset scenario, ScenarioNode source) {
  if (scenario.activationCondition != null ||
      scenario.declaredOutcomes.isNotEmpty ||
      scenario.nodes.length != 3 ||
      scenario.edges.length != 2 ||
      !_hasOnlySourceSemantics(source)) {
    return false;
  }
  final sourceEdges =
      scenario.edges.where((edge) => edge.fromNodeId == source.id).toList();
  if (sourceEdges.length != 1 ||
      sourceEdges.single.kind != ScenarioEdgeKind.next) {
    return false;
  }
  final dialogue = scenario.nodes.where(
    (node) =>
        node.id == sourceEdges.single.toNodeId &&
        node.type == ScenarioNodeType.dialogue &&
        _hasOnlyDialogueSemantics(node),
  );
  if (dialogue.length != 1) return false;
  final dialogueEdges = scenario.edges
      .where((edge) => edge.fromNodeId == dialogue.single.id)
      .toList();
  if (dialogueEdges.length != 1 ||
      dialogueEdges.single.kind != ScenarioEdgeKind.next) {
    return false;
  }
  final hasEnd = scenario.nodes.any(
    (node) =>
        node.id == dialogueEdges.single.toNodeId &&
        node.type == ScenarioNodeType.end &&
        _hasOnlyEndSemantics(node),
  );
  return hasEnd &&
      scenario.edges.every(
        (edge) =>
            edge.kind == ScenarioEdgeKind.next &&
            edge.label.isEmpty &&
            edge.metadata.isEmpty,
      );
}

bool _hasOnlySourceSemantics(ScenarioNode node) {
  if (!_isScenarioSourceNode(node) ||
      node.type != ScenarioNodeType.reference ||
      node.payload.message != null ||
      node.payload.condition != null ||
      node.payload.choiceLabels.isNotEmpty ||
      node.payload.params.isNotEmpty ||
      node.metadata.keys.any((key) => key != 'eventV2.sceneId')) {
    return false;
  }
  final allowedBindings = switch (node.payload.actionKind) {
    'sourceMapEnter' => const {'mapId'},
    'sourceTriggerEnter' => const {'mapId', 'triggerId'},
    'sourceEntityInteract' => const {'mapId', 'entityId'},
    'sourceOutcome' => const {'outcomeId'},
    _ => const <String>{},
  };
  return _bindingContainsOnly(node.binding, allowedBindings);
}

bool _hasOnlyDialogueSemantics(ScenarioNode node) {
  return _exact(node.binding.dialogueId) &&
      _bindingContainsOnly(node.binding, const {'dialogueId'}) &&
      node.payload.actionKind == null &&
      node.payload.message == null &&
      node.payload.condition == null &&
      node.payload.choiceLabels.isEmpty &&
      node.payload.params.keys.every((key) => key == 'startNode') &&
      node.metadata.isEmpty;
}

bool _hasOnlyEndSemantics(ScenarioNode node) {
  return _bindingContainsOnly(node.binding, const {}) &&
      node.payload.actionKind == null &&
      node.payload.message == null &&
      node.payload.condition == null &&
      node.payload.choiceLabels.isEmpty &&
      node.payload.params.isEmpty &&
      node.metadata.isEmpty;
}

bool _bindingContainsOnly(
  ScenarioNodeBinding binding,
  Set<String> allowed,
) {
  final values = <String, String?>{
    'mapId': binding.mapId,
    'eventId': binding.eventId,
    'entityId': binding.entityId,
    'warpId': binding.warpId,
    'triggerId': binding.triggerId,
    'trainerId': binding.trainerId,
    'dialogueId': binding.dialogueId,
    'scriptId': binding.scriptId,
    'outcomeId': binding.outcomeId,
    'flagName': binding.flagName,
    'variableName': binding.variableName,
  };
  return values.entries.every(
    (entry) => entry.value == null || allowed.contains(entry.key),
  );
}

bool _sameObservableTrace(
  ScenarioAsset scenario,
  String sourceNodeId,
  SceneAsset scene,
) {
  if (scene.declaredOutcomes.isNotEmpty) return false;
  return _scenarioTrace(scenario, sourceNodeId).join('|') ==
      _sceneTrace(scene).join('|');
}

/// Replays the C3 Scene proof against the current immutable project assets.
bool hasEquivalentLegacyScenarioSceneCandidate({
  required ScenarioAsset scenario,
  required String sourceNodeId,
  required SceneAsset scene,
}) {
  final matchingNodes = scenario.nodes
      .where((node) => node.id == sourceNodeId)
      .toList(growable: false);
  if (matchingNodes.length != 1 || !buildSceneRuntimePlan(scene).canBuild) {
    return false;
  }
  return _sameObservableTrace(scenario, sourceNodeId, scene);
}

/// Restricts an assisted source choice to the source encoded by the Scenario.
bool isCompatibleLegacyScenarioSourceChoice({
  required LegacyScenarioSourceProjection projection,
  required ScenarioAsset scenario,
  required NarrativeEventSourceRef selectedSource,
}) {
  final projectedSource = projection.source;
  if (projectedSource != null) return selectedSource == projectedSource;
  final matchingNodes = scenario.nodes
      .where((node) => node.id == projection.nodeId)
      .toList(growable: false);
  if (matchingNodes.length != 1) return false;
  final node = matchingNodes.single;
  final rawOutcomeId = node.binding.outcomeId;
  if (node.payload.actionKind != 'sourceOutcome' || !_exact(rawOutcomeId)) {
    return false;
  }
  return selectedSource.when(
    entityInteract: (_, __) => false,
    triggerEnter: (_, __) => false,
    mapEnter: (_) => false,
    outcomeReceived: (outcome) => outcome.outcomeId == rawOutcomeId,
  );
}

List<String> _scenarioTrace(ScenarioAsset scenario, String sourceNodeId) {
  final result = <String>[];
  var currentId = sourceNodeId;
  final visited = <String>{};
  while (visited.add(currentId)) {
    final node = scenario.nodes.singleWhere((item) => item.id == currentId);
    if (node.type == ScenarioNodeType.dialogue) {
      result.add(
        jsonEncode({
          'kind': 'dialogue',
          'dialogueId': node.binding.dialogueId,
          'startNode': _optionalRuntimeText(node.payload.params['startNode']),
          'expectedOutcomes': const <String>[],
          'speakerHints': const <String>[],
        }),
      );
    } else if (node.type == ScenarioNodeType.end) {
      result.add(jsonEncode({'kind': 'end', 'outcomeId': null}));
      return result;
    } else if (node.id != sourceNodeId) {
      return const ['unsupported'];
    }
    final outgoing =
        scenario.edges.where((edge) => edge.fromNodeId == currentId).toList();
    if (outgoing.length != 1) return const ['unsupported'];
    currentId = outgoing.single.toNodeId;
  }
  return const ['cycle'];
}

List<String> _sceneTrace(SceneAsset scene) {
  final result = <String>[];
  var currentId = scene.graph.startNodeId;
  final visited = <String>{};
  while (visited.add(currentId)) {
    final node = scene.graph.nodes.singleWhere((item) => item.id == currentId);
    if (node.kind == SceneNodeKind.yarnDialogue) {
      final payload = node.payload as SceneYarnDialoguePayload;
      result.add(
        jsonEncode({
          'kind': 'dialogue',
          'dialogueId': payload.dialogueId,
          'startNode': _optionalRuntimeText(payload.yarnNodeName),
          'expectedOutcomes': payload.expectedOutcomes,
          'speakerHints': payload.speakerHints,
        }),
      );
    } else if (node.kind == SceneNodeKind.end) {
      final payload = node.payload as SceneEndPayload;
      result.add(
        jsonEncode({'kind': 'end', 'outcomeId': payload.sceneOutcomeId}),
      );
      return result;
    } else if (node.kind != SceneNodeKind.start) {
      return const ['unsupported'];
    }
    final outgoing = scene.graph.edges
        .where((edge) => edge.fromNodeId == currentId)
        .toList();
    if (outgoing.length != 1 ||
        outgoing.single.kind != SceneEdgeKind.defaultFlow ||
        outgoing.single.fromPortId != 'completed') {
      return const ['unsupported'];
    }
    currentId = outgoing.single.toNodeId;
  }
  return const ['cycle'];
}

String? _optionalRuntimeText(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

bool _exact(String? value) {
  return value != null && value.isNotEmpty && value.trim() == value;
}

int _classificationRank(LegacyMigrationClassification value) {
  return switch (value) {
    LegacyMigrationClassification.autoSafe => 0,
    LegacyMigrationClassification.assisted => 1,
    LegacyMigrationClassification.legacyOnly => 2,
    LegacyMigrationClassification.blocked => 3,
    LegacyMigrationClassification.unsupported => 4,
  };
}

Map<String, Object?> _normalizeJson(Map<String, Object?> value) {
  return Map<String, Object?>.from(jsonDecode(jsonEncode(value)) as Map);
}

Map<String, Object?> _freezeObject(Map<String, Object?> value) {
  return Map.unmodifiable({
    for (final entry in value.entries) entry.key: _freezeJson(entry.value),
  });
}

Object? _freezeJson(Object? value) {
  if (value is Map) {
    return Map<String, Object?>.unmodifiable({
      for (final entry in value.entries)
        entry.key as String: _freezeJson(entry.value),
    });
  }
  if (value is List) {
    return List<Object?>.unmodifiable(value.map(_freezeJson));
  }
  return value;
}

String _requireText(String value, String name) {
  if (value.isEmpty || value.trim() != value) {
    throw ArgumentError.value(value, name, 'must be non-empty and trimmed');
  }
  return value;
}
