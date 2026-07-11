import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _fixtureDirectory = 'test/fixtures/narrative_event_legacy_corpus';

void main() {
  group('NS-EVENT-V2 Phase C1 legacy corpus', () {
    late File fixtureFile;
    late List<int> fixtureBytes;
    late Map<String, Object?> fixture;
    late List<MapData> maps;
    late List<ScenarioAsset> scenarios;
    late List<SceneAsset> scenes;
    late List<GameState> gameStates;
    late List<WorldRuleDefinition> worldRules;
    late List<SceneConsequence> sceneConsequences;
    late List<ScriptAsset> scripts;

    setUpAll(() {
      fixtureFile = File('$_fixtureDirectory/corpus_v0.json');
      fixtureBytes = fixtureFile.readAsBytesSync();
      fixture =
          _object(decodeNarrativeEventJsonStrict(utf8.decode(fixtureBytes)));
      maps = _list(fixture, 'maps')
          .map((value) => MapData.fromJson(_dynamicObject(value)))
          .toList(growable: false);
      scenarios = _list(fixture, 'scenarios')
          .map((value) => ScenarioAsset.fromJson(_dynamicObject(value)))
          .toList(growable: false);
      scenes = _list(fixture, 'scenes')
          .map((value) => SceneAsset.fromJson(_dynamicObject(value)))
          .toList(growable: false);
      gameStates = _list(fixture, 'gameStates')
          .map((value) => GameState.fromJson(_dynamicObject(value)))
          .toList(growable: false);
      worldRules = _list(fixture, 'worldRules')
          .map((value) => WorldRuleDefinition.fromJson(_dynamicObject(value)))
          .toList(growable: false);
      sceneConsequences = _list(fixture, 'sceneConsequences')
          .map((value) => SceneConsequence.fromJson(_dynamicObject(value)))
          .toList(growable: false);
      scripts = _list(fixture, 'scripts')
          .map((value) => ScriptAsset.fromJson(_dynamicObject(value)))
          .toList(growable: false);
    });

    test('pins raw bytes and never rewrites a source fixture', () {
      final checksumLine =
          File('$_fixtureDirectory/corpus_v0.sha256').readAsStringSync().trim();
      final expected = checksumLine.split(RegExp(r'\s+')).first;
      expect(expected, isNot('PENDING'));
      expect(sha256.convert(fixtureBytes).toString(), expected);

      final before = List<int>.of(fixtureBytes);
      for (final map in maps) {
        final encoded = jsonEncode(map.toJson());
        final decoded = MapData.fromJson(
          _dynamicObject(jsonDecode(jsonEncode(map.toJson()))),
        );
        expect(
          canonicalizeNarrativeEventJsonText(jsonEncode(decoded.toJson())),
          canonicalizeNarrativeEventJsonText(encoded),
        );
      }
      for (final scenario in scenarios) {
        final encoded = jsonEncode(scenario.toJson());
        final decoded = ScenarioAsset.fromJson(
          _dynamicObject(jsonDecode(jsonEncode(scenario.toJson()))),
        );
        expect(
          canonicalizeNarrativeEventJsonText(jsonEncode(decoded.toJson())),
          canonicalizeNarrativeEventJsonText(encoded),
        );
      }
      expect(fixtureFile.readAsBytesSync(), before);
    });

    test('covers every required MapEvent shape without flattening pages', () {
      final events = [for (final map in maps) ...map.events];
      expect(
        events.map((event) => event.type).toSet(),
        containsAll(MapEventType.values),
      );

      final ordered = _event(maps, 'c1_map_a', 'evt_page_order');
      expect(ordered.pages.map((page) => page.pageNumber), [30, 20, 10]);
      expect(ordered.pages[0].isHidden, isTrue);
      expect(ordered.pages[1].isDisabled, isTrue);
      expect(ordered.pages[2].condition, isNull);
      expect(
        readEventBuilderContractFromMapEvent(ordered).diagnostics,
        isNotEmpty,
      );

      final mixed = _event(maps, 'c1_map_a', 'evt_effect_mixed');
      final mixedKinds = readEventBuilderContractFromMapEvent(mixed)
          .diagnostics
          .map((diagnostic) => diagnostic.kind)
          .toSet();
      expect(
        mixedKinds,
        containsAll({
          EventBuilderContractDiagnosticKind.metadataMalformed,
          EventBuilderContractDiagnosticKind.unsupportedLegacyScript,
          EventBuilderContractDiagnosticKind.unsupportedLegacyMessage,
        }),
      );

      final duplicateIds = <String, List<String>>{};
      for (final map in maps) {
        for (final event in map.events) {
          duplicateIds.putIfAbsent(event.id, () => []).add(map.id);
        }
      }
      expect(duplicateIds['evt_shared'], ['c1_map_a', 'c1_map_b']);

      final samePositions = maps
          .singleWhere((map) => map.id == 'c1_map_a')
          .events
          .where((event) => event.position.x == 7 && event.position.y == 7)
          .map((event) => event.id)
          .toSet();
      expect(
        samePositions,
        {'evt_duplicate_position_a', 'evt_duplicate_position_b'},
      );
    });

    test('keeps invalid position and unknown JSON probes loss-aware', () {
      final mapA = maps.singleWhere((map) => map.id == 'c1_map_a');
      final missingLayer = _event(maps, mapA.id, 'evt_missing_layer');
      final outOfBounds = _event(maps, mapA.id, 'evt_out_of_bounds');
      expect(
        mapA.layers.any((layer) => layer.id == missingLayer.position.layerId),
        isFalse,
      );
      expect(outOfBounds.position.x >= mapA.size.width, isTrue);
      expect(outOfBounds.position.y >= mapA.size.height, isTrue);

      final probes = {
        for (final value in _list(fixture, 'decodeProbes'))
          _string(_object(value), 'id'): _object(value),
      };
      expect(
        () => MapEventDefinition.fromJson(
          _dynamicObject(probes['event_position_without_layer']!['json']),
        ),
        throwsA(anything),
      );
      expect(
        probes['unknown_legacy_payload']!['expected'],
        'preservedOrBlocked',
      );
      final unknownProbe = probes['unknown_legacy_payload']!;
      final unknownJson = _object(unknownProbe['json']);
      final canonicalBefore = canonicalizeNarrativeEventJson(unknownJson);
      final canonicalAfter = canonicalizeNarrativeEventJson(
        decodeNarrativeEventJsonStrict(jsonEncode(unknownJson)),
      );
      expect(canonicalAfter, canonicalBefore);
      final rawHash = narrativeEventCanonicalSha256(unknownJson);
      if (unknownProbe['expectedCanonicalSha256'] == 'PENDING') {
        fail('Replace unknown raw hash with $rawHash');
      }
      expect(rawHash, unknownProbe['expectedCanonicalSha256']);
      expect(
        unknownJson['futureBehavior'],
        isNotNull,
      );
      expect(
        () => MapEventDefinition.fromJson(_dynamicObject(unknownJson)),
        throwsA(anything),
      );
    });

    test('covers four Scenario sources and preserves complex graphs', () {
      final sourceKinds = <String>{};
      for (final scenario in scenarios) {
        for (final node in scenario.nodes) {
          final kind = node.payload.actionKind;
          if (kind != null && kind.startsWith('source')) sourceKinds.add(kind);
        }
      }
      expect(
        sourceKinds,
        {
          'sourceMapEnter',
          'sourceTriggerEnter',
          'sourceEntityInteract',
          'sourceOutcome',
        },
      );

      final complex =
          scenarios.singleWhere((scenario) => scenario.id == 'scn_complex');
      expect(complex.activationCondition, isNotNull);
      expect(
        complex.edges.map((edge) => edge.kind).toSet(),
        containsAll(
            {ScenarioEdgeKind.trueBranch, ScenarioEdgeKind.falseBranch}),
      );
      expect(
        complex.nodes.where((node) => node.type == ScenarioNodeType.action),
        hasLength(2),
      );

      final wildcard =
          scenarios.singleWhere((scenario) => scenario.id == 'scn_wildcard');
      expect(wildcard.nodes.first.binding.mapId, isEmpty);
      final malformed =
          scenarios.singleWhere((scenario) => scenario.id == 'scn_malformed');
      expect(malformed.nodes.first.binding.entityId, isNull);
    });

    test('represents every migration classification and corpus feature', () {
      final cases =
          _list(fixture, 'cases').map(_object).toList(growable: false);
      final classifications = {
        for (final value in cases) _string(value, 'classification'),
      };
      expect(
        classifications,
        {'AUTO_SAFE', 'ASSISTED', 'BLOCKED', 'UNSUPPORTED', 'LEGACY_ONLY'},
      );
      expect(
        cases.map((value) => _string(value, 'id')).toSet(),
        hasLength(cases.length),
      );
      for (final value in cases) {
        for (final field in const [
          'decodeBehavior',
          'runtimeBehavior',
          'sourceOfTruth',
          'conversionPossibility',
          'lossRisk',
        ]) {
          expect(
            _string(value, field).trim(),
            isNotEmpty,
            reason: '${value['id']} must characterize $field.',
          );
        }
        expect(value['outgoingReferences'], isA<List>());
        expect(value['incomingReferences'], isA<List>());
      }
      final pageOrders = _object(fixture['pageOrders']);
      expect(pageOrders.keys.toSet(), {
        for (final value in cases) _string(value, 'subject'),
      });
      expect(
        {
          for (final map in maps)
            for (final event in map.events) 'mapEvent:${map.id}:${event.id}',
        },
        {
          for (final value in cases)
            if (_string(value, 'subject').startsWith('mapEvent:'))
              _string(value, 'subject'),
        },
      );
      for (final value in cases) {
        final subject = _string(value, 'subject');
        final expectedOrder = List<int>.from(pageOrders[subject]! as List);
        if (!subject.startsWith('mapEvent:')) {
          expect(expectedOrder, isEmpty);
          continue;
        }
        final parts = subject.split(':');
        expect(
          _event(maps, parts[1], parts[2]).pages.map((page) => page.pageNumber),
          expectedOrder,
        );
      }

      final autoSafeCases = cases.where(
        (value) => _string(value, 'classification') == 'AUTO_SAFE',
      );
      expect(autoSafeCases, isNotEmpty);
      for (final value in autoSafeCases) {
        final subject = _string(value, 'subject').split(':');
        expect(subject.first, 'scenarioSourceNode');
        final scenario = scenarios.singleWhere(
          (candidate) => candidate.id == subject[1],
        );
        final sourceNode = scenario.nodes.singleWhere(
          (node) => node.id == subject[2],
        );
        final sceneId = sourceNode.metadata['eventV2.sceneId'];
        expect(sceneId, isNotNull);
        final scene =
            scenes.singleWhere((candidate) => candidate.id == sceneId);
        final planResult = buildSceneRuntimePlan(scene);
        expect(
          planResult.canBuild,
          isTrue,
          reason: '$sceneId must be executable before AUTO_SAFE is allowed.',
        );
        expect(_scenarioObservableTrace(scenario, sourceNode.id),
            _sceneObservableTrace(scene));
      }

      final features = <String>{
        for (final value in cases)
          for (final feature in _list(value, 'features')) feature as String,
      };
      expect(
        features,
        containsAll({
          'actor',
          'object',
          'triggerZone',
          'effect',
          'sceneTarget',
          'script',
          'message',
          'scriptAndMessage',
          'multiplePages',
          'firstValid',
          'fallbackPage',
          'disabledPage',
          'hiddenPage',
          'unknownLayer',
          'outOfBounds',
          'multipleEventsSamePosition',
          'nearEntity',
          'multipleEntitiesSameFootprint',
          'duplicateIdAcrossMaps',
          'alreadyConsumed',
          'eventReferencedByCondition',
          'worldRuleReference',
          'sceneConsequenceReference',
          'mapEnter',
          'triggerEnter',
          'entityInteract',
          'outcomeReceived',
          'multipleSourceNodes',
          'branches',
          'multipleActions',
          'malformedBinding',
          'emptyMapIdWildcard',
          'unqualifiedOutcome',
          'claimedSource',
        }),
      );
    });

    test('keeps the qualified reference inventory deterministic', () {
      final expected =
          _list(fixture, 'references').map(_object).toList(growable: false);
      final discovered = _discoverReferences(
        maps: maps,
        scenarios: scenarios,
        scenes: scenes,
        gameStates: gameStates,
        worldRules: worldRules,
        sceneConsequences: sceneConsequences,
        scripts: scripts,
      );
      expect(
        discovered.map((value) => value.kind).toSet(),
        containsAll({
          'GameState.consumedEventIds',
          'ScriptCondition',
          'WorldRuleDefinition.source',
          'WorldRuleDefinition.target',
          'EventSceneLinkDiagnostic',
          'SceneConsequence',
          'ScenarioNodeBinding',
          'ScriptCommand',
          'metadata',
        }),
      );

      final expectedKeys = expected.map(_referenceKey).toList()..sort();
      final discoveredKeys = discovered.map((value) => value.key).toList()
        ..sort();
      expect(discoveredKeys, expectedKeys);
      final reversedKeys =
          discovered.reversed.map((value) => value.key).toList()..sort();
      expect(reversedKeys, discoveredKeys);

      final ambiguous = discovered.where(
        (value) => value.rawId == 'evt_shared' && value.candidates.length > 1,
      );
      expect(ambiguous, isNotEmpty);
      expect(
        ambiguous.every((value) => value.selectedCandidate == null),
        isTrue,
      );
    });

    test('pins source fingerprints and proves complete claim cohorts', () {
      final mapEvent = _event(maps, 'c1_map_a', 'evt_actor_scene');
      final source =
          NarrativeEventSourceRef.entityInteract('c1_map_a', 'npc_actor');
      final discoveredBySource = _discoverScenarioSourceProvenances(scenarios);
      final discoveredProvenances = [...discoveredBySource[source]!]
        ..sort(compareLegacySourceRefs);
      final members = [
        for (final provenance in discoveredProvenances)
          provenance.when(
            mapEvent: (_, __) => throw StateError(
              'Scenario cohort unexpectedly contains a MapEvent.',
            ),
            scenarioSourceNode: (scenarioId, nodeId) {
              final scenario = scenarios.singleWhere(
                (candidate) => candidate.id == scenarioId,
              );
              return LegacySourceClaimMember(
                provenance: provenance,
                sourceFingerprint: computeScenarioSourceFingerprint(
                  scenarioId: scenarioId,
                  nodeId: nodeId,
                  scenario: scenario,
                ),
              );
            },
          ),
      ];
      final cohortId = computeLegacySourceCohortId(
        source,
        members.map((member) => member.provenance),
      );
      final actual = <String, String>{
        'mapEventFingerprint': computeMapEventSourceFingerprint(
          mapId: 'c1_map_a',
          event: mapEvent,
        ),
        'scenarioFingerprintA': members[0].sourceFingerprint,
        'scenarioFingerprintB': members[1].sourceFingerprint,
        'cohortId': cohortId,
        'cohortFingerprint':
            computeLegacySourceCohortFingerprint(cohortId, members),
      };
      final expected = _object(fixture['goldens']);
      if (expected.values.contains('PENDING')) {
        fail('Replace C1 goldens with ${jsonEncode(actual)}');
      }
      expect(actual, expected);

      final declaredMembers = _list(
        _list(fixture, 'cohorts').map(_object).single,
        'members',
      ).map((value) => LegacySourceRef.fromJson(value)).toSet();
      final discovered = members.map((member) => member.provenance).toSet();
      expect(discovered, declaredMembers);
      expect(discoveredProvenances, hasLength(2));
      final provenanceA = LegacySourceRef.scenarioSourceNode(
        'scn_entity_a',
        'source',
      );
      final provenanceB = LegacySourceRef.scenarioSourceNode(
        'scn_entity_b',
        'source',
      );
      expect(
        declaredMembers.difference({provenanceA}),
        {provenanceB},
      );

      final claim = LegacySourceClaim(
        cohortId: cohortId,
        source: source,
        members: members,
        cohortFingerprint: actual['cohortFingerprint']!,
        targetEventIds: const ['evt_018f1234-5678-7abc-8def-0123456789ab'],
        migrationReceiptId: 'receipt_c1',
      );
      expect(
          claim.members.map((member) => member.provenance).toSet(), discovered);
    });
  });
}

MapEventDefinition _event(
  List<MapData> maps,
  String mapId,
  String eventId,
) {
  return maps
      .singleWhere((map) => map.id == mapId)
      .events
      .singleWhere((event) => event.id == eventId);
}

String _referenceKey(Map<String, Object?> reference) {
  return '${_string(reference, 'kind')}|${_string(reference, 'path')}|'
      '${_string(reference, 'rawId')}|${reference['mapId'] ?? ''}|'
      '${_list(reference, 'candidates').join(',')}';
}

List<String> _scenarioObservableTrace(
  ScenarioAsset scenario,
  String sourceNodeId,
) {
  final trace = <String>[];
  var currentId = sourceNodeId;
  final visited = <String>{};
  while (visited.add(currentId)) {
    final node =
        scenario.nodes.singleWhere((candidate) => candidate.id == currentId);
    if (node.type == ScenarioNodeType.dialogue) {
      trace.add('dialogue:${node.binding.dialogueId}');
    } else if (node.type == ScenarioNodeType.end) {
      trace.add('end');
      return trace;
    } else if (node.id != sourceNodeId) {
      throw StateError('Non-equivalent Scenario node ${node.type.name}.');
    }
    final outgoing =
        scenario.edges.where((edge) => edge.fromNodeId == currentId);
    currentId = outgoing.single.toNodeId;
  }
  throw StateError('Scenario trace contains a cycle.');
}

List<String> _sceneObservableTrace(SceneAsset scene) {
  final trace = <String>[];
  var currentId = scene.graph.startNodeId;
  final visited = <String>{};
  while (visited.add(currentId)) {
    final node = scene.graph.nodes.singleWhere(
      (candidate) => candidate.id == currentId,
    );
    if (node.kind == SceneNodeKind.yarnDialogue) {
      final payload = node.payload as SceneYarnDialoguePayload;
      trace.add('dialogue:${payload.dialogueId}');
    } else if (node.kind == SceneNodeKind.end) {
      trace.add('end');
      return trace;
    } else if (node.kind != SceneNodeKind.start) {
      throw StateError('Non-equivalent Scene node ${node.kind.name}.');
    }
    final outgoing = scene.graph.edges.where(
      (edge) => edge.fromNodeId == currentId,
    );
    currentId = outgoing.single.toNodeId;
  }
  throw StateError('Scene trace contains a cycle.');
}

Map<NarrativeEventSourceRef, List<LegacySourceRef>>
    _discoverScenarioSourceProvenances(List<ScenarioAsset> scenarios) {
  final result = <NarrativeEventSourceRef, List<LegacySourceRef>>{};
  for (final scenario in scenarios) {
    for (final node in scenario.nodes) {
      final binding = node.binding;
      final source = switch (node.payload.actionKind) {
        'sourceMapEnter' when (binding.mapId ?? '').isNotEmpty =>
          NarrativeEventSourceRef.mapEnter(binding.mapId!),
        'sourceTriggerEnter'
            when (binding.mapId ?? '').isNotEmpty &&
                (binding.triggerId ?? '').isNotEmpty =>
          NarrativeEventSourceRef.triggerEnter(
            binding.mapId!,
            binding.triggerId!,
          ),
        'sourceEntityInteract'
            when (binding.mapId ?? '').isNotEmpty &&
                (binding.entityId ?? '').isNotEmpty =>
          NarrativeEventSourceRef.entityInteract(
            binding.mapId!,
            binding.entityId!,
          ),
        'sourceOutcome' when (binding.outcomeId ?? '').isNotEmpty =>
          NarrativeEventSourceRef.outcomeReceived(
            NarrativeOutcomeRef(
              producerKind: NarrativeOutcomeProducerKind.legacyScenario,
              producerId: scenario.id,
              outcomeId: binding.outcomeId!,
            ),
          ),
        _ => null,
      };
      if (source == null) continue;
      result.putIfAbsent(source, () => []).add(
            LegacySourceRef.scenarioSourceNode(scenario.id, node.id),
          );
    }
  }
  return result;
}

List<_DiscoveredReference> _discoverReferences({
  required List<MapData> maps,
  required List<ScenarioAsset> scenarios,
  required List<SceneAsset> scenes,
  required List<GameState> gameStates,
  required List<WorldRuleDefinition> worldRules,
  required List<SceneConsequence> sceneConsequences,
  required List<ScriptAsset> scripts,
}) {
  final byBareId = <String, List<String>>{};
  for (final map in maps) {
    for (final event in map.events) {
      byBareId.putIfAbsent(event.id, () => []).add('${map.id}:${event.id}');
    }
  }
  for (final values in byBareId.values) {
    values.sort();
  }

  List<String> candidates(String eventId, {String? mapId}) {
    if (mapId != null) {
      final qualified = '$mapId:$eventId';
      return byBareId[eventId]?.contains(qualified) == true
          ? [qualified]
          : const [];
    }
    return List.unmodifiable(byBareId[eventId] ?? const []);
  }

  final result = <_DiscoveredReference>[];
  void add(
    String kind,
    String path,
    String eventId, {
    String? mapId,
  }) {
    result.add(
      _DiscoveredReference(
        kind: kind,
        path: path,
        rawId: eventId,
        mapId: mapId,
        candidates: candidates(eventId, mapId: mapId),
        selectedCandidate: null,
      ),
    );
  }

  for (final state in gameStates) {
    final eventIds = state.consumedEventIds.toList()..sort();
    for (var index = 0; index < eventIds.length; index++) {
      add(
        'GameState.consumedEventIds',
        'gameStates.${state.saveId}.consumedEventIds[$index]',
        eventIds[index],
      );
    }
  }
  for (final map in maps) {
    for (final event in map.events) {
      for (var pageIndex = 0; pageIndex < event.pages.length; pageIndex++) {
        final page = event.pages[pageIndex];
        _discoverConditionReferences(
          page.condition,
          path: 'maps.${map.id}.events.${event.id}.pages[$pageIndex].condition',
          add: (eventId, path) => add('ScriptCondition', path, eventId),
        );
        for (final entry in page.metadata.entries) {
          if (entry.key.toLowerCase().contains('eventid') &&
              byBareId.containsKey(entry.value)) {
            add(
              'metadata',
              'maps.${map.id}.events.${event.id}.pages[$pageIndex].metadata.${entry.key}',
              entry.value,
            );
          }
        }
      }
    }
  }
  for (final rule in worldRules) {
    if (rule.source.kind == WorldRuleSourceKind.consumedEvent) {
      add(
        'WorldRuleDefinition.source',
        'worldRules.${rule.id}.source',
        rule.source.sourceId,
      );
    }
    if (rule.target.kind == WorldRuleTargetKind.mapEvent &&
        rule.target.eventId != null) {
      add(
        'WorldRuleDefinition.target',
        'worldRules.${rule.id}.target',
        rule.target.eventId!,
        mapId: rule.target.mapId,
      );
    }
  }
  final diagnosticProject = ProjectManifest(
    name: 'C1 diagnostic inventory',
    maps: const [],
    tilesets: const [],
    scenes: scenes,
  );
  final linkDiagnostics = diagnoseEventSceneLinks(
    project: diagnosticProject,
    maps: maps,
  ).diagnostics;
  for (var index = 0; index < linkDiagnostics.length; index++) {
    final diagnostic = linkDiagnostics[index];
    add(
      'EventSceneLinkDiagnostic',
      'diagnostics.eventSceneLinks[$index]',
      diagnostic.eventId,
      mapId: diagnostic.mapId,
    );
  }
  for (var index = 0; index < sceneConsequences.length; index++) {
    final consequence = sceneConsequences[index];
    if (consequence is SceneMarkEventConsumedConsequence) {
      add(
        'SceneConsequence',
        'sceneConsequences[$index]',
        consequence.eventId,
        mapId: consequence.mapId,
      );
    }
  }
  for (final scenario in scenarios) {
    for (final node in scenario.nodes) {
      final eventId = node.binding.eventId;
      if (eventId != null && eventId.isNotEmpty) {
        add(
          'ScenarioNodeBinding',
          'scenarios.${scenario.id}.nodes.${node.id}.binding',
          eventId,
          mapId: node.binding.mapId,
        );
      }
    }
  }
  for (final script in scripts) {
    for (final node in script.nodes) {
      for (var index = 0; index < node.commands.length; index++) {
        final command = node.commands[index];
        final eventId = command.params['eventId'];
        if (command.type == ScriptCommandType.markEventConsumed &&
            eventId != null &&
            eventId.isNotEmpty) {
          add(
            'ScriptCommand',
            'scripts.${script.id}.nodes.${node.id}.commands[$index]',
            eventId,
          );
        }
      }
    }
    for (final entry in script.metadata.entries) {
      if (entry.key.toLowerCase().contains('eventid') &&
          byBareId.containsKey(entry.value)) {
        add(
          'metadata',
          'scripts.${script.id}.metadata.${entry.key}',
          entry.value,
        );
      }
    }
  }
  return List.unmodifiable(result);
}

void _discoverConditionReferences(
  ScriptCondition? condition, {
  required String path,
  required void Function(String eventId, String path) add,
}) {
  if (condition == null) return;
  if (condition.type == ScriptConditionType.eventIsConsumed) {
    final eventId = condition.params[ScriptConditionParams.eventId];
    if (eventId != null && eventId.isNotEmpty) add(eventId, path);
  }
  for (var index = 0; index < condition.children.length; index++) {
    _discoverConditionReferences(
      condition.children[index],
      path: '$path.children[$index]',
      add: add,
    );
  }
}

final class _DiscoveredReference {
  const _DiscoveredReference({
    required this.kind,
    required this.path,
    required this.rawId,
    required this.mapId,
    required this.candidates,
    required this.selectedCandidate,
  });

  final String kind;
  final String path;
  final String rawId;
  final String? mapId;
  final List<String> candidates;
  final String? selectedCandidate;

  String get key => '$kind|$path|$rawId|${mapId ?? ''}|${candidates.join(',')}';
}

Map<String, Object?> _object(Object? value) {
  return Map<String, Object?>.from(value! as Map);
}

Map<String, dynamic> _dynamicObject(Object? value) {
  return Map<String, dynamic>.from(value! as Map);
}

List<Object?> _list(Map<String, Object?> object, String key) {
  return List<Object?>.from(object[key]! as List);
}

String _string(Map<String, Object?> object, String key) {
  return object[key]! as String;
}
