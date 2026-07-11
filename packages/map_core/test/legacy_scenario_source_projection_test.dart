import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('NS-EVENT-V2 Phase C3 Scenario source projection', () {
    late List<ScenarioAsset> scenarios;
    late List<SceneAsset> scenes;

    setUpAll(() {
      final fixture = Map<String, Object?>.from(
        decodeNarrativeEventJsonStrict(
          File('test/fixtures/narrative_event_legacy_corpus/corpus_v0.json')
              .readAsStringSync(),
        )! as Map,
      );
      scenarios = List<Object?>.from(fixture['scenarios']! as List)
          .map(
            (value) => ScenarioAsset.fromJson(
              Map<String, dynamic>.from(value! as Map),
            ),
          )
          .toList(growable: false);
      scenes = List<Object?>.from(fixture['scenes']! as List)
          .map(
            (value) => SceneAsset.fromJson(
              Map<String, dynamic>.from(value! as Map),
            ),
          )
          .toList(growable: false);
    });

    test('projects all four simple source kinds without promoting Scenario',
        () {
      final cases = <String, NarrativeEventSourceKind>{
        'scn_map_enter': NarrativeEventSourceKind.mapEnter,
        'scn_trigger_enter': NarrativeEventSourceKind.triggerEnter,
        'scn_entity_a': NarrativeEventSourceKind.entityInteract,
      };
      for (final entry in cases.entries) {
        final scenario = _scenario(scenarios, entry.key);
        final node = _node(scenario, 'source');
        final projection = projectLegacyScenarioSourceReadOnly(
          scenario: scenario,
          node: node,
          scenes: scenes,
          claimIndex: _emptyClaimIndex(),
          lifecycleEvidence: LegacyScenarioLifecycleEvidence.reusable,
        );

        expect(projection.source?.kind, entry.value);
        expect(projection.sceneCandidateId, isNotNull);
        expect(
          projection.classification,
          LegacyMigrationClassification.autoSafe,
        );
        expect(projection.graphComplexity,
            LegacyScenarioGraphComplexity.simpleLinear);
        expect(projection.provenance,
            LegacySourceRef.scenarioSourceNode(scenario.id, node.id));
      }

      final outcome = _project(scenarios, scenes, 'scn_outcome', 'source');
      expect(outcome.source, isNull);
      expect(outcome.sceneCandidateId, 'scene_outcome');
      expect(outcome.classification, LegacyMigrationClassification.assisted);
      expect(
        outcome.diagnostics.map((value) => value.code),
        contains(LegacyScenarioDiagnosticCodes.outcomeQualificationRequired),
      );
    });

    test('defaults lifecycle to ASSISTED until project evidence is supplied',
        () {
      final scenario = _scenario(scenarios, 'scn_map_enter');
      final projection = projectLegacyScenarioSourceReadOnly(
        scenario: scenario,
        node: _node(scenario, 'source'),
        scenes: scenes,
        claimIndex: _emptyClaimIndex(),
      );

      expect(projection.classification, LegacyMigrationClassification.assisted);
      expect(
        projection.lifecycleEvidence,
        LegacyScenarioLifecycleEvidence.ambiguous,
      );
      expect(projection.reusePolicyCandidate, isNull);
      expect(
        projection.diagnostics.map((value) => value.code),
        contains(LegacyScenarioDiagnosticCodes.lifecycleEvidenceMissing),
      );
    });

    test('complex, multi-source, choice, and malformed graphs never flatten',
        () {
      final complex = _project(scenarios, scenes, 'scn_complex', 'source');
      final multi = _project(scenarios, scenes, 'scn_multi_source', 'source_a');
      final choice = _project(scenarios, scenes, 'scn_choice', 'source');
      final malformed = _project(scenarios, scenes, 'scn_malformed', 'source');
      final wildcard = _project(scenarios, scenes, 'scn_wildcard', 'source');

      expect(complex.classification, LegacyMigrationClassification.legacyOnly);
      expect(complex.graphComplexity,
          LegacyScenarioGraphComplexity.branchingOrOrchestrated);
      expect(multi.classification, LegacyMigrationClassification.blocked);
      expect(
          multi.graphComplexity, LegacyScenarioGraphComplexity.multipleSources);
      expect(choice.classification, LegacyMigrationClassification.unsupported);
      expect(malformed.classification, LegacyMigrationClassification.blocked);
      expect(malformed.source, isNull);
      expect(wildcard.classification, LegacyMigrationClassification.blocked);
      expect(wildcard.source, isNull);
    });

    test('valid claim, tombstone, and stale full-Scenario hash are distinct',
        () {
      final scenario = _scenario(scenarios, 'scn_entity_a');
      final node = _node(scenario, 'source');
      final source =
          NarrativeEventSourceRef.entityInteract('c1_map_a', 'npc_actor');
      final valid = projectLegacyScenarioSourceReadOnly(
        scenario: scenario,
        node: node,
        scenes: scenes,
        claimIndex: _scenarioClaimIndex(
          scenario: scenario,
          node: node,
          source: source,
          validTarget: true,
        ),
      );
      final tombstone = projectLegacyScenarioSourceReadOnly(
        scenario: scenario,
        node: node,
        scenes: scenes,
        claimIndex: _scenarioClaimIndex(
          scenario: scenario,
          node: node,
          source: source,
          validTarget: false,
        ),
      );
      final changed = scenario.copyWith(name: 'Changed after claim');
      final stale = projectLegacyScenarioSourceReadOnly(
        scenario: changed,
        node: _node(changed, 'source'),
        scenes: scenes,
        claimIndex: _scenarioClaimIndex(
          scenario: scenario,
          node: node,
          source: source,
          validTarget: true,
        ),
      );

      expect(valid.claimStatus, LegacyProjectionClaimStatus.valid);
      expect(valid.existingClaim, isNotNull);
      expect(tombstone.claimStatus, LegacyProjectionClaimStatus.invalid);
      expect(tombstone.classification, LegacyMigrationClassification.blocked);
      expect(stale.claimStatus, LegacyProjectionClaimStatus.invalid);
      expect(stale.existingClaim, isNull);
      expect(
        stale.diagnostics.map((value) => value.code),
        contains(LegacyScenarioDiagnosticCodes.claimFingerprintStale),
      );

      final outcomeScenario = _scenario(scenarios, 'scn_outcome');
      final outcomeNode = _node(outcomeScenario, 'source');
      final wrongOutcomeClaim = projectLegacyScenarioSourceReadOnly(
        scenario: outcomeScenario,
        node: outcomeNode,
        scenes: scenes,
        claimIndex: _scenarioClaimIndex(
          scenario: outcomeScenario,
          node: outcomeNode,
          source: NarrativeEventSourceRef.outcomeReceived(
            NarrativeOutcomeRef(
              producerKind: NarrativeOutcomeProducerKind.scene,
              producerId: 'scene_outcome',
              outcomeId: 'defeat',
            ),
          ),
          validTarget: true,
        ),
        lifecycleEvidence: LegacyScenarioLifecycleEvidence.reusable,
      );
      expect(
        wrongOutcomeClaim.claimStatus,
        LegacyProjectionClaimStatus.invalid,
      );
      expect(
        wrongOutcomeClaim.diagnostics.map((value) => value.code),
        contains(LegacyScenarioDiagnosticCodes.claimSourceMismatch),
      );
    });

    test('projection is immutable deterministic and does not mutate Scenario',
        () {
      final scenario = _scenario(scenarios, 'scn_entity_a');
      final node = _node(scenario, 'source');
      final before = canonicalizeNarrativeEventJson(
        jsonDecode(jsonEncode(scenario.toJson())),
      );
      LegacyScenarioSourceProjection run() =>
          projectLegacyScenarioSourceReadOnly(
            scenario: scenario,
            node: node,
            scenes: scenes,
            claimIndex: _emptyClaimIndex(),
          );

      final first = run();
      final second = run();
      expect(canonicalizeNarrativeEventJson(first.toJson()),
          canonicalizeNarrativeEventJson(second.toJson()));
      expect(
        canonicalizeNarrativeEventJson(
          jsonDecode(jsonEncode(scenario.toJson())),
        ),
        before,
      );
      expect(() => first.actions.clear(), throwsUnsupportedError);
      expect(() => first.conditions.clear(), throwsUnsupportedError);
      expect(
        () => first.preservedScenarioJson['mutate'] = true,
        throwsUnsupportedError,
      );
    });

    test('detached node snapshots and incomplete Scene traces are blocked', () {
      final scenario = _scenario(scenarios, 'scn_entity_a');
      final canonicalNode = _node(scenario, 'source');
      final detachedNode = canonicalNode.copyWith(
        binding: canonicalNode.binding.copyWith(entityId: 'other_entity'),
      );
      final detachedProjection = projectLegacyScenarioSourceReadOnly(
        scenario: scenario,
        node: detachedNode,
        scenes: scenes,
        claimIndex: _emptyClaimIndex(),
      );
      expect(
        detachedProjection.classification,
        LegacyMigrationClassification.blocked,
      );
      expect(
        detachedProjection.source,
        NarrativeEventSourceRef.entityInteract('c1_map_a', 'npc_actor'),
      );
      expect(
        detachedProjection.diagnostics.map((value) => value.code),
        contains(LegacyScenarioDiagnosticCodes.nodeSnapshotMismatch),
      );

      final missingNode = canonicalNode.copyWith(id: 'missing_source');
      final malformedEdges = scenario.copyWith(
        edges: [
          const ScenarioEdge(
            id: 'missing-dialogue',
            fromNodeId: 'missing_source',
            toNodeId: 'dialogue',
          ),
          scenario.edges.last,
        ],
      );
      final missingProjection = projectLegacyScenarioSourceReadOnly(
        scenario: malformedEdges,
        node: missingNode,
        scenes: scenes,
        claimIndex: _emptyClaimIndex(),
        lifecycleEvidence: LegacyScenarioLifecycleEvidence.reusable,
      );
      expect(
        missingProjection.classification,
        LegacyMigrationClassification.blocked,
      );
      expect(
        missingProjection.diagnostics.map((value) => value.code),
        contains(LegacyScenarioDiagnosticCodes.nodeMissing),
      );

      final scene = scenes.singleWhere((value) => value.id == 'scene_entity');
      final sceneJson = Map<String, dynamic>.from(
        jsonDecode(jsonEncode(scene.toJson())) as Map,
      );
      final graph = Map<String, dynamic>.from(sceneJson['graph']! as Map);
      final nodes = List<Object?>.from(graph['nodes']! as List);
      final dialogueIndex = nodes.indexWhere(
        (value) => (value! as Map)['kind'] == 'yarnDialogue',
      );
      final dialogue = Map<String, dynamic>.from(nodes[dialogueIndex]! as Map);
      final payload = Map<String, dynamic>.from(dialogue['payload']! as Map);
      payload['yarnNodeName'] = 'DifferentStartNode';
      dialogue['payload'] = payload;
      nodes[dialogueIndex] = dialogue;
      graph['nodes'] = nodes;
      sceneJson['graph'] = graph;
      final mismatchingScene = SceneAsset.fromJson(sceneJson);
      final traceProjection = projectLegacyScenarioSourceReadOnly(
        scenario: scenario,
        node: canonicalNode,
        scenes: [
          for (final candidate in scenes)
            if (candidate.id == scene.id) mismatchingScene else candidate,
        ],
        claimIndex: _emptyClaimIndex(),
      );
      expect(
        traceProjection.classification,
        LegacyMigrationClassification.blocked,
      );
      expect(
        traceProjection.diagnostics.map((value) => value.code),
        contains(LegacyScenarioDiagnosticCodes.sceneTraceMismatch),
      );
    });

    test('authoring guard freezes whole claimed Scenario and duplicate source',
        () {
      final claimed = _scenario(scenarios, 'scn_entity_a');
      final source =
          NarrativeEventSourceRef.entityInteract('c1_map_a', 'npc_actor');
      final claimIndex = _scenarioClaimIndex(
        scenario: claimed,
        node: _node(claimed, 'source'),
        source: source,
        validTarget: true,
      );
      final siblingEdit = claimed.copyWith(
        nodes: [
          for (final node in claimed.nodes)
            if (node.id == 'dialogue')
              node.copyWith(title: 'Edited sibling')
            else
              node,
        ],
      );
      final unrelated = _scenario(scenarios, 'scn_trigger_enter');
      final duplicate = _scenario(scenarios, 'scn_entity_b');

      final claimedGuard = evaluateScenarioAuthoringClaimGuard(
        claimIndex: claimIndex,
        existingScenario: claimed,
        proposedScenario: siblingEdit,
      );
      final unrelatedGuard = evaluateScenarioAuthoringClaimGuard(
        claimIndex: claimIndex,
        existingScenario: unrelated,
        proposedScenario: unrelated,
      );
      final duplicateGuard = evaluateScenarioAuthoringClaimGuard(
        claimIndex: claimIndex,
        proposedScenario: duplicate,
      );

      expect(claimedGuard.blocked, isTrue);
      expect(claimedGuard.message, contains('Event Builder V2'));
      expect(unrelatedGuard.blocked, isFalse);
      expect(duplicateGuard.blocked, isTrue);
    });

    test('authoring guard mirrors wildcard maps and unqualified outcomes', () {
      final mapScenario = _scenario(scenarios, 'scn_map_enter');
      final mapClaimIndex = _scenarioClaimIndex(
        scenario: mapScenario,
        node: _node(mapScenario, 'source'),
        source: NarrativeEventSourceRef.mapEnter('c1_map_a'),
        validTarget: true,
      );
      final wildcard = _scenario(scenarios, 'scn_wildcard');
      expect(
        evaluateScenarioAuthoringClaimGuard(
          claimIndex: mapClaimIndex,
          proposedScenario: wildcard,
        ).blocked,
        isTrue,
      );

      final outcomeScenario = _scenario(scenarios, 'scn_outcome');
      final outcomeClaimIndex = _scenarioClaimIndex(
        scenario: outcomeScenario,
        node: _node(outcomeScenario, 'source'),
        source: NarrativeEventSourceRef.outcomeReceived(
          NarrativeOutcomeRef(
            producerKind: NarrativeOutcomeProducerKind.scene,
            producerId: 'scene_outcome',
            outcomeId: 'victory',
          ),
        ),
        validTarget: true,
      );
      expect(
        evaluateScenarioAuthoringClaimGuard(
          claimIndex: outcomeClaimIndex,
          proposedScenario: outcomeScenario.copyWith(id: 'other_consumer'),
        ).blocked,
        isTrue,
      );
    });
  });
}

LegacyScenarioSourceProjection _project(
  List<ScenarioAsset> scenarios,
  List<SceneAsset> scenes,
  String scenarioId,
  String nodeId,
) {
  final scenario = _scenario(scenarios, scenarioId);
  return projectLegacyScenarioSourceReadOnly(
    scenario: scenario,
    node: _node(scenario, nodeId),
    scenes: scenes,
    claimIndex: _emptyClaimIndex(),
    lifecycleEvidence: LegacyScenarioLifecycleEvidence.reusable,
  );
}

ScenarioAsset _scenario(List<ScenarioAsset> scenarios, String id) {
  return scenarios.singleWhere((scenario) => scenario.id == id);
}

ScenarioNode _node(ScenarioAsset scenario, String id) {
  return scenario.nodes.singleWhere((node) => node.id == id);
}

ValidatedLegacyClaimIndex _emptyClaimIndex() {
  return buildValidatedLegacyClaimIndex(
    NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.legacyOnly,
      records: const [],
      legacyClaims: const [],
    ),
  );
}

ValidatedLegacyClaimIndex _scenarioClaimIndex({
  required ScenarioAsset scenario,
  required ScenarioNode node,
  required NarrativeEventSourceRef source,
  required bool validTarget,
}) {
  final provenance = LegacySourceRef.scenarioSourceNode(scenario.id, node.id);
  final member = LegacySourceClaimMember(
    provenance: provenance,
    sourceFingerprint: computeScenarioSourceFingerprint(
      scenarioId: scenario.id,
      nodeId: node.id,
      scenario: scenario,
    ),
  );
  final cohortId = computeLegacySourceCohortId(source, [provenance]);
  const targetId = 'evt_018f1234-5678-7abc-8def-0123456789ab';
  final claim = LegacySourceClaim(
    cohortId: cohortId,
    source: source,
    members: [member],
    cohortFingerprint: computeLegacySourceCohortFingerprint(cohortId, [member]),
    targetEventIds: const [targetId],
    migrationReceiptId: 'receipt_c3',
  );
  return buildValidatedLegacyClaimIndex(
    NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.legacyOnly,
      records: validTarget
          ? [
              NarrativeEventRecord.configuredStructurallyUnchecked(
                NarrativeEventDefinition(
                  id: targetId,
                  name: 'C3 target',
                  source: source,
                  conditions: const [],
                  sceneId: 'scene_entity',
                  reusePolicy: NarrativeEventReusePolicy.oneShot,
                  priority: 0,
                  order: 0,
                ),
                enabled: false,
              ),
            ]
          : const [],
      legacyClaims: [claim],
    ),
  );
}
