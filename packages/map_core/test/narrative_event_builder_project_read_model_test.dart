import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _eventA = 'evt_00000000-0000-7000-8000-000000000001';
const _eventB = 'evt_00000000-0000-7000-8000-000000000002';
const _eventC = 'evt_00000000-0000-7000-8000-000000000003';

void main() {
  group('NS-EVENT-V2 Phase D D3 unified project read model', () {
    test('keeps enabled and disabled Events sharing one source separate', () {
      final source = NarrativeEventSourceRef.entityInteract(
        'map_port',
        'npc_lysa',
      );
      final project = _project(
        records: [
          _configured(_eventB, 'Deuxième rencontre', source, enabled: false),
          _configured(_eventA, 'Première rencontre', source, enabled: true),
        ],
      );

      final model = buildNarrativeEventBuilderProjectReadModel(
        project: project,
        maps: [_map()],
      );

      expect(model.events, hasLength(2));
      expect(
        model.events.map((event) => event.eventId),
        [_eventB, _eventA],
      );
      expect(
        model.events.map((event) => event.status).toSet(),
        {
          NarrativeEventProjectStatus.configuredEnabledReady,
          NarrativeEventProjectStatus.configuredDisabledReady,
        },
      );
      expect(model.groups, hasLength(1));
      expect(model.groups.single.kind, NarrativeEventProjectGroupKind.map);
      expect(model.groups.single.label, 'Port des Brisants');
      expect(
        model.events.first.source.humanSentence,
        contains('Lysa'),
      );
    });

    test('separates drafts, missing sources, Scenes, and Facts truthfully', () {
      final noSourceDraft = _draft(_eventA, 'Sans source');
      final missingSourceDraft = _draft(
        _eventB,
        'Source disparue',
        source: NarrativeEventSourceRef.entityInteract(
          'map_port',
          'npc_absent',
        ),
      );
      final draftModel = buildNarrativeEventBuilderProjectReadModel(
        project: _project(records: [missingSourceDraft, noSourceDraft]),
        maps: [_map()],
      );

      expect(
        draftModel.events
            .singleWhere((event) => event.eventId == _eventA)
            .status,
        NarrativeEventProjectStatus.draftIncomplete,
      );
      expect(
        draftModel.events
            .singleWhere((event) => event.eventId == _eventB)
            .status,
        NarrativeEventProjectStatus.sourceMissing,
      );
      expect(
        draftModel.groups.map((group) => group.kind),
        containsAll({
          NarrativeEventProjectGroupKind.drafts,
          NarrativeEventProjectGroupKind.missingReferences,
        }),
      );

      final source = NarrativeEventSourceRef.entityInteract(
        'map_port',
        'npc_lysa',
      );
      final missingScene = _configured(
        _eventA,
        'Scene absente',
        source,
        enabled: true,
        sceneId: 'scene_absente',
      );
      final missingFact = _configured(
        _eventB,
        'Fact absent',
        source,
        enabled: true,
        conditions: [NarrativeEventCondition.fact('fact_absent', true)],
      );
      for (final record in [missingScene, missingFact]) {
        final model = buildNarrativeEventBuilderProjectReadModel(
          project: _project(records: [record]),
          maps: [_map()],
        );
        expect(
          model.events.single.status,
          NarrativeEventProjectStatus.referenceInvalid,
        );
        expect(
          model.events.single.group,
          NarrativeEventProjectGroupKind.missingReferences,
        );
      }
    });

    test('rejects unavailable sources and broken references in drafts', () {
      final source = NarrativeEventSourceRef.entityInteract(
        'map_port',
        'npc_lysa',
      );
      final unavailable = buildNarrativeEventBuilderProjectReadModel(
        project: _project(
          records: [
            _configured(
              _eventA,
              'Interaction impossible',
              source,
              enabled: true,
            ),
          ],
        ),
        maps: [_map(entityKind: MapEntityKind.spawn)],
      );
      expect(unavailable.events.single.source.available, isFalse);
      expect(
        unavailable.events.single.status,
        NarrativeEventProjectStatus.referenceInvalid,
      );

      final missingScene = buildNarrativeEventBuilderProjectReadModel(
        project: _project(
          records: [
            _draft(
              _eventB,
              'Brouillon Scene absente',
              source: source,
              sceneId: 'scene_absente',
              reusePolicy: NarrativeEventReusePolicy.oneShot,
            ),
          ],
        ),
        maps: [_map()],
      );
      expect(
        missingScene.events.single.status,
        NarrativeEventProjectStatus.referenceInvalid,
      );

      final missingFact = buildNarrativeEventBuilderProjectReadModel(
        project: _project(
          records: [
            _draft(
              _eventC,
              'Brouillon Fact absent',
              source: source,
              sceneId: 'scene_action',
              reusePolicy: NarrativeEventReusePolicy.oneShot,
              conditions: [NarrativeEventCondition.fact('fact_absent', true)],
            ),
          ],
        ),
        maps: [_map()],
      );
      expect(
        missingFact.events.single.status,
        NarrativeEventProjectStatus.referenceInvalid,
      );
    });

    test('keeps same outcome ID qualified across producer kinds', () {
      final firstSource = NarrativeEventSourceRef.outcomeReceived(
        _sceneOutcome('scene_rival', 'victory'),
      );
      final secondSource = NarrativeEventSourceRef.outcomeReceived(
        _legacyScenarioOutcome('scenario_arena', 'victory'),
      );
      final legacyScenario = ScenarioAsset(
        id: 'scenario_arena',
        name: 'Ancien tournoi',
        entryNodeId: 'start',
        declaredOutcomes: const ['victory'],
      );
      final project = _project(
        maps: const [],
        scenes: [
          _scene('scene_rival', 'Combat contre le rival', outcomeId: 'victory'),
          _scene('scene_action', 'Réaction au résultat'),
        ],
        scenarios: [legacyScenario],
        records: [
          _configured(
            _eventA,
            'Après le rival',
            firstSource,
            enabled: true,
            sceneId: 'scene_action',
          ),
          _configured(
            _eventB,
            'Après l’ancien tournoi',
            secondSource,
            enabled: true,
            sceneId: 'scene_action',
          ),
        ],
      );

      final model = buildNarrativeEventBuilderProjectReadModel(
        project: project,
        maps: const [],
      );

      expect(model.groups.single.kind, NarrativeEventProjectGroupKind.outcomes);
      expect(model.events, hasLength(2));
      expect(
        model.events.map((event) => event.source.humanSentence).toSet(),
        {
          'Après l’issue victory de la Scene Combat contre le rival.',
          'Après l’issue victory du Scenario historique Ancien tournoi.',
        },
      );
      expect(
        model.events.every(
          (event) =>
              event.status ==
              NarrativeEventProjectStatus.configuredEnabledReady,
        ),
        isTrue,
      );
    });

    test('projects Scene consequences and World Rules read-only', () {
      final source = NarrativeEventSourceRef.entityInteract(
        'map_port',
        'npc_lysa',
      );
      final project = _project(
        scenes: [
          _scene(
            'scene_action',
            'Révéler le passage',
            consequences: [
              SceneConsequence.setFact(
                factId: 'fact_passage_open',
                value: true,
              ),
              SceneConsequence.setFact(
                factId: 'fact_passage_open',
                value: false,
              ),
            ],
          ),
        ],
        facts: [
          NarrativeFactDefinition(
            id: 'fact_passage_open',
            label: 'Passage ouvert',
          ),
        ],
        worldRules: [
          WorldRuleDefinition(
            id: 'rule_reveal_lysa',
            label: 'Afficher Lysa au port',
            source: const WorldRuleSource(
              kind: WorldRuleSourceKind.fact,
              sourceId: 'fact_passage_open',
              predicate: WorldRuleSourcePredicate.isTrue,
            ),
            target: const WorldRuleTarget(
              kind: WorldRuleTargetKind.mapEntity,
              mapId: 'map_port',
              entityId: 'npc_lysa',
            ),
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.entityVisible,
            ),
          ),
        ],
        records: [
          _configured(
            _eventA,
            'Ouvrir le passage',
            source,
            enabled: true,
          ),
        ],
      );
      final before = jsonEncode(project.toJson());

      final model = buildNarrativeEventBuilderProjectReadModel(
        project: project,
        maps: [_map()],
      );

      final projection = model.events.single.projection;
      expect(projection.readOnly, isTrue);
      expect(projection.consequences, hasLength(2));
      expect(
        projection.consequences.map((consequence) => consequence.humanLabel),
        {
          'Définit « Passage ouvert » à faux.',
          'Définit « Passage ouvert » à vrai.',
        },
      );
      expect(
        projection.consequences
            .every((value) => value.kind == SceneConsequenceKind.setFact),
        isTrue,
      );
      expect(projection.worldRules, hasLength(1));
      expect(projection.worldRules.single.humanLabel, 'Afficher Lysa au port');
      expect(jsonEncode(project.toJson()), before);
      expect(() => projection.consequences.clear(), throwsUnsupportedError);
      expect(() => projection.worldRules.clear(), throwsUnsupportedError);
    });

    test('fails closed when a Scene has missing project references', () {
      final source = NarrativeEventSourceRef.entityInteract(
        'map_port',
        'npc_lysa',
      );
      final consequences = [
        SceneConsequence.setFact(
          factId: 'fact_absent',
          value: true,
        ),
        SceneConsequence.markEventConsumed(
          mapId: 'map_port',
          eventId: 'event_absent',
        ),
      ];

      for (var index = 0; index < consequences.length; index++) {
        final model = buildNarrativeEventBuilderProjectReadModel(
          project: _project(
            scenes: [
              _scene(
                'scene_action',
                'Scene avec référence absente',
                consequences: [consequences[index]],
              ),
            ],
            records: [
              _configured(
                _eventA,
                'Event avec Scene invalide',
                source,
                enabled: true,
              ),
            ],
          ),
          maps: [_map()],
        );

        expect(model.events.single.scene.valid, isFalse, reason: 'case $index');
        expect(
          model.events.single.status,
          NarrativeEventProjectStatus.referenceInvalid,
          reason: 'case $index',
        );
      }
    });

    test('valid claim attaches compatibility origin without a legacy row', () {
      final fixture = _legacyMapFixture();
      final source = NarrativeEventSourceRef.entityInteract(
        'map_port',
        'npc_lysa',
      );
      final record = _configured(
        _eventA,
        'Rencontre avec Lysa',
        source,
        enabled: false,
      );
      final claim = _claim(
        source: source,
        provenance: fixture.baseProjection.provenance,
        sourceFingerprint: fixture.baseProjection.sourceFingerprint,
        targetIds: const [_eventA],
      );
      final registry = _registry(records: [record], claims: [claim]);
      final projection = projectLegacyMapEventReadOnly(
        mapId: fixture.map.id,
        map: fixture.map,
        event: fixture.event,
        claimIndex: buildValidatedLegacyClaimIndex(registry),
      );
      expect(projection.claimStatus, LegacyProjectionClaimStatus.valid);

      final model = buildNarrativeEventBuilderProjectReadModel(
        project: _project(registry: registry),
        maps: [fixture.map],
      );

      expect(model.events, hasLength(1));
      expect(model.events.single.origin, NarrativeEventProjectOrigin.v2);
      expect(model.events.single.compatibilityOrigins, hasLength(1));
      expect(
        model.events.single.migration.claimStatus,
        LegacyProjectionClaimStatus.valid,
      );
    });

    test('stale claim projection fails closed as one read-only blocker', () {
      final fixture = _legacyMapFixture();
      final source = NarrativeEventSourceRef.entityInteract(
        'map_port',
        'npc_lysa',
      );
      final record = _configured(
        _eventA,
        'Rencontre avec Lysa',
        source,
        enabled: false,
      );
      final claim = _claim(
        source: source,
        provenance: fixture.baseProjection.provenance,
        sourceFingerprint: fixture.baseProjection.sourceFingerprint,
        targetIds: const [_eventA],
      );
      final registry = _registry(records: [record], claims: [claim]);
      final changedEvent = fixture.event.copyWith(title: 'Titre modifié');
      final changedMap = fixture.map.copyWith(events: [changedEvent]);

      final model = buildNarrativeEventBuilderProjectReadModel(
        project: _project(registry: registry),
        maps: [changedMap],
      );

      final blocker = model.events.singleWhere(
        (event) => event.status == NarrativeEventProjectStatus.claimInvalid,
      );
      expect(blocker.readOnly, isTrue);
      expect(blocker.source.source, isNull);
      expect(blocker.compatibilityOrigins, hasLength(1));
      expect(
        model.events.where(
          (event) => event.origin == NarrativeEventProjectOrigin.legacyMapEvent,
        ),
        isEmpty,
      );
    });

    test('tombstone and global claim conflict stay unique without fallback',
        () {
      final fixture = _legacyMapFixture();
      final source = NarrativeEventSourceRef.entityInteract(
        'map_port',
        'npc_lysa',
      );
      final tombstone = _claim(
        source: source,
        provenance: fixture.baseProjection.provenance,
        sourceFingerprint: fixture.baseProjection.sourceFingerprint,
        targetIds: const [_eventC],
      );
      final tombstoneModel = buildNarrativeEventBuilderProjectReadModel(
        project: _project(
          registry: _registry(records: const [], claims: [tombstone]),
        ),
        maps: [fixture.map],
      );
      expect(tombstoneModel.events, hasLength(1));
      expect(
        tombstoneModel.events.single.status,
        NarrativeEventProjectStatus.claimInvalid,
      );

      final record = _configured(
        _eventA,
        'Rencontre avec Lysa',
        source,
        enabled: false,
      );
      final conflictClaim = _claim(
        source: source,
        provenance: fixture.baseProjection.provenance,
        sourceFingerprint: fixture.baseProjection.sourceFingerprint,
        targetIds: const [_eventA],
      );
      final conflictModel = buildNarrativeEventBuilderProjectReadModel(
        project: _project(
          registry: _registry(
            records: [record],
            claims: [conflictClaim, conflictClaim],
          ),
        ),
        maps: [fixture.map],
      );
      expect(
        conflictModel.events.where(
          (event) => event.status == NarrativeEventProjectStatus.claimInvalid,
        ),
        hasLength(1),
      );
      expect(
        conflictModel.events.where(
          (event) => event.origin == NarrativeEventProjectOrigin.legacyMapEvent,
        ),
        isEmpty,
      );
    });

    test('keeps unclaimed MapEvent and Scenario as separate read-only rows',
        () {
      final fixture = _legacyMapFixture();
      final scenario = ScenarioAsset(
        id: 'scenario_port',
        name: 'Ancien parcours du port',
        entryNodeId: 'source',
        nodes: const [
          ScenarioNode(
            id: 'source',
            type: ScenarioNodeType.reference,
            binding: ScenarioNodeBinding(mapId: 'map_port'),
            payload: ScenarioNodePayload(actionKind: 'sourceMapEnter'),
          ),
        ],
      );

      final model = buildNarrativeEventBuilderProjectReadModel(
        project: _project(scenarios: [scenario]),
        maps: [fixture.map],
      );

      expect(model.events, hasLength(2));
      expect(model.events.every((event) => event.readOnly), isTrue);
      expect(
        model.events.map((event) => event.origin).toSet(),
        {
          NarrativeEventProjectOrigin.legacyMapEvent,
          NarrativeEventProjectOrigin.legacyScenario,
        },
      );
      expect(
        model.events
            .singleWhere(
              (event) =>
                  event.origin == NarrativeEventProjectOrigin.legacyScenario,
            )
            .status,
        NarrativeEventProjectStatus.migrationBlocked,
      );
      expect(
        model.groups.single.kind,
        NarrativeEventProjectGroupKind.legacyCompatibility,
      );
    });

    test('fails closed when a legacy MapEvent Scene is missing', () {
      final fixture = _legacyMapFixture();
      final brokenEvent = fixture.event.copyWith(
        pages: const [
          MapEventPage(
            pageNumber: 0,
            sceneTarget: MapEventSceneTarget(sceneId: 'scene_absente'),
          ),
        ],
      );

      final model = buildNarrativeEventBuilderProjectReadModel(
        project: _project(),
        maps: [
          fixture.map.copyWith(events: [brokenEvent])
        ],
      );

      expect(model.events.single.readOnly, isTrue);
      expect(
        model.events.single.status,
        NarrativeEventProjectStatus.migrationBlocked,
      );
      expect(model.events.single.severity,
          NarrativeEventProjectSummarySeverity.error);
      expect(model.events.single.migration.humanLabel, isNot(contains('prêt')));
      expect(
        model.events.single.diagnostics.map((diagnostic) => diagnostic.message),
        contains('Une Scene valide doit être choisie.'),
      );
    });

    test('exposes a literal stable snapshot for an incomplete draft', () {
      final model = buildNarrativeEventBuilderProjectReadModel(
        project: _project(records: [_draft(_eventA, 'Premier brouillon')]),
        maps: [_map()],
      );

      final snapshot = model.toDebugJson();
      expect(snapshot, {
        'groups': [
          {
            'stableKey': 'drafts:unconfigured',
            'label': 'Brouillons sans source',
            'kind': 'drafts',
            'events': [
              {
                'stableKey': 'v2:$_eventA',
                'title': 'Premier brouillon',
                'origin': 'v2',
                'readOnly': false,
                'group': 'drafts',
                'status': 'draftIncomplete',
                'severity': 'warning',
                'source': {
                  'humanSentence': 'Source non choisie.',
                  'sourceTypeLabel': 'À configurer',
                  'available': false,
                  'debug': {'technicalLabel': 'unconfigured'},
                },
                'scene': {
                  'humanLabel': 'Scene à choisir',
                  'valid': false,
                },
                'conditions': {
                  'count': 0,
                  'valid': true,
                  'unresolvedCount': 0,
                  'humanLabel': 'Aucune condition',
                },
                'lifecycle': {'humanLabel': 'Comportement à choisir'},
                'migration': {'humanLabel': 'Configuration en cours.'},
                'projection': {
                  'outcomeLabels': <Object?>[],
                  'consequences': <Object?>[],
                  'worldRules': <Object?>[],
                  'readOnly': true,
                },
                'compatibilityOrigins': <Object?>[],
                'diagnostics': <Object?>[],
                'debug': {
                  'eventId': _eventA,
                  'provenances': <Object?>[],
                  'targetEventIds': <Object?>[],
                },
              },
            ],
          },
        ],
        'diagnostics': <Object?>[],
      });
    });

    test('is deterministic, immutable, and keeps technical words secondary',
        () {
      final source = NarrativeEventSourceRef.entityInteract(
        'map_port',
        'npc_lysa',
      );
      final first = _project(
        records: [
          _configured(_eventB, 'Bêta', source, enabled: false),
          _configured(_eventA, 'Alpha', source, enabled: true),
        ],
      );
      final second = _project(
        records: [
          _configured(_eventA, 'Alpha', source, enabled: true),
          _configured(_eventB, 'Bêta', source, enabled: false),
        ],
      );
      final firstModel = buildNarrativeEventBuilderProjectReadModel(
        project: first,
        maps: [_map()],
      );
      final secondModel = buildNarrativeEventBuilderProjectReadModel(
        project: second,
        maps: [_map()],
      );

      expect(firstModel.toDebugJson(), secondModel.toDebugJson());
      expect(
        firstModel.eventByStableKey('v2:$_eventA')?.title,
        'Alpha',
      );
      expect(
        () => firstModel.groups.add(firstModel.groups.single),
        throwsUnsupportedError,
      );
      expect(
        () => firstModel.groups.single.events.add(firstModel.events.first),
        throwsUnsupportedError,
      );
      expect(
        () => firstModel.events.first.compatibilityOrigins.clear(),
        throwsUnsupportedError,
      );

      final primaryText = [
        for (final group in firstModel.groups) group.label,
        for (final event in firstModel.events) ...[
          event.title,
          event.source.humanSentence,
          event.source.sourceTypeLabel,
          event.scene.humanLabel,
          event.conditions.humanLabel,
          event.lifecycle.humanLabel,
          event.migration.humanLabel,
          for (final diagnostic in event.diagnostics) diagnostic.message,
        ],
      ].join(' ').toLowerCase();
      for (final forbidden in [
        'mapeventdefinition',
        'layerid',
        'metadata',
        'claim',
        'runtime',
      ]) {
        expect(primaryText, isNot(contains(forbidden)));
      }
    });
  });
}

ProjectManifest _project({
  List<ProjectMapEntry>? maps,
  List<SceneAsset>? scenes,
  List<NarrativeFactDefinition> facts = const [],
  List<WorldRuleDefinition> worldRules = const [],
  List<ScenarioAsset> scenarios = const [],
  List<NarrativeEventRecord> records = const [],
  NarrativeEventRegistry? registry,
}) {
  final effectiveMaps = maps ?? [_mapEntry()];
  final effectiveScenes = scenes ?? [_scene('scene_action', 'Rencontre')];
  return ProjectManifest(
    name: 'Selbrume',
    maps: effectiveMaps,
    tilesets: const [],
    scenes: effectiveScenes,
    facts: facts,
    worldRules: worldRules,
    scenarios: scenarios,
    eventRegistry: registry ?? _registry(records: records),
  );
}

NarrativeEventRegistry _registry({
  required List<NarrativeEventRecord> records,
  List<LegacySourceClaim> claims = const [],
}) {
  return NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.dualRead,
    records: records,
    legacyClaims: claims,
  );
}

NarrativeEventRecord _configured(
  String id,
  String name,
  NarrativeEventSourceRef source, {
  required bool enabled,
  String sceneId = 'scene_action',
  List<NarrativeEventCondition> conditions = const [],
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: id,
      name: name,
      source: source,
      conditions: conditions,
      sceneId: sceneId,
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: 0,
      order: 0,
    ),
    enabled: enabled,
  );
}

NarrativeEventRecord _draft(
  String id,
  String name, {
  NarrativeEventSourceRef? source,
  List<NarrativeEventCondition> conditions = const [],
  String? sceneId,
  NarrativeEventReusePolicy? reusePolicy,
}) {
  return NarrativeEventRecord.draft(
    NarrativeEventDraft(
      id: id,
      name: name,
      source: source,
      conditions: conditions,
      sceneId: sceneId,
      reusePolicy: reusePolicy,
      priority: 0,
      order: 0,
    ),
  );
}

ProjectMapEntry _mapEntry() {
  return const ProjectMapEntry(
    id: 'map_port',
    name: 'Port des Brisants',
    relativePath: 'maps/port.json',
  );
}

MapData _map({
  List<MapEventDefinition> events = const [],
  MapEntityKind entityKind = MapEntityKind.npc,
}) {
  return MapData(
    id: 'map_port',
    name: 'Port des Brisants',
    size: const GridSize(width: 12, height: 10),
    layers: const [MapLayer.object(id: 'events', name: 'Événements')],
    entities: [
      MapEntity(
        id: 'npc_lysa',
        name: 'Lysa',
        kind: entityKind,
        pos: const GridPos(x: 2, y: 3),
      ),
    ],
    events: events,
  );
}

SceneAsset _scene(
  String id,
  String name, {
  String? outcomeId,
  List<SceneConsequence> consequences = const [],
}) {
  final path = [
    'start',
    for (var index = 0; index < consequences.length; index++) 'action_$index',
    'end',
  ];
  return SceneAsset(
    id: id,
    name: name,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        for (var index = 0; index < consequences.length; index++)
          SceneNode(
            id: 'action_$index',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(consequences[index]),
          ),
        SceneNode(
          id: 'end',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: outcomeId),
        ),
      ],
      edges: [
        for (var index = 0; index < path.length - 1; index++)
          SceneEdge(
            id: 'edge_$index',
            fromNodeId: path[index],
            fromPortId: 'completed',
            toNodeId: path[index + 1],
            kind: SceneEdgeKind.defaultFlow,
          ),
      ],
    ),
    declaredOutcomes: outcomeId == null
        ? const []
        : [SceneOutcome(id: outcomeId, label: outcomeId)],
  );
}

NarrativeOutcomeRef _sceneOutcome(String sceneId, String outcomeId) {
  return NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.scene,
    producerId: sceneId,
    outcomeId: outcomeId,
  );
}

NarrativeOutcomeRef _legacyScenarioOutcome(
  String scenarioId,
  String outcomeId,
) {
  return NarrativeOutcomeRef(
    producerKind: NarrativeOutcomeProducerKind.legacyScenario,
    producerId: scenarioId,
    outcomeId: outcomeId,
  );
}

LegacySourceClaim _claim({
  required NarrativeEventSourceRef source,
  required LegacySourceRef provenance,
  required String sourceFingerprint,
  required List<String> targetIds,
}) {
  final member = LegacySourceClaimMember(
    provenance: provenance,
    sourceFingerprint: sourceFingerprint,
  );
  final cohortId = computeLegacySourceCohortId(source, [provenance]);
  return LegacySourceClaim(
    cohortId: cohortId,
    source: source,
    members: [member],
    cohortFingerprint: computeLegacySourceCohortFingerprint(
      cohortId,
      [member],
    ),
    targetEventIds: targetIds,
    migrationReceiptId: 'receipt_phase_d',
  );
}

_LegacyMapFixture _legacyMapFixture() {
  const event = MapEventDefinition(
    id: 'legacy_lysa',
    title: 'Ancienne rencontre avec Lysa',
    pages: [
      MapEventPage(
        pageNumber: 0,
        sceneTarget: MapEventSceneTarget(sceneId: 'scene_action'),
      ),
    ],
    position: EventPosition(layerId: 'events', x: 2, y: 3),
  );
  final map = _map(events: const [event]);
  final baseProjection = projectLegacyMapEventReadOnly(
    mapId: map.id,
    map: map,
    event: event,
    claimIndex: buildValidatedLegacyClaimIndex(
      _registry(records: const []),
    ),
  );
  return _LegacyMapFixture(
    map: map,
    event: event,
    baseProjection: baseProjection,
  );
}

final class _LegacyMapFixture {
  const _LegacyMapFixture({
    required this.map,
    required this.event,
    required this.baseProjection,
  });

  final MapData map;
  final MapEventDefinition event;
  final LegacyMapEventProjection baseProjection;
}
