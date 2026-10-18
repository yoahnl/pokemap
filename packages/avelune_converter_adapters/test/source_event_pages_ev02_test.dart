import 'dart:convert';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';

Future<({LiteralTileFixture fixture, SourceEventAnalysis analysis})> _source(
    List<LiteralFixtureEventPage> pages,
    {List<String?> switchNames = const [null, 'Gate'], String eventName = 'Original event'}) async {
  final fixture = await LiteralTileFixture.create(
    interpretationProfile: syntheticSourceInterpretationProfile,
    scriptsBytes: syntheticInterpretationArchive,
    includeEventSystem: true,
    switchNames: switchNames,
    extraFiles: {
      for (final name in pages
          .map((page) => page.characterName)
          .where((name) => name.isNotEmpty)
          .toSet())
        'Graphics/Characters/$name.png': literalFixtureAtlas(),
    },
    maps: [
      LiteralFixtureMap(id: 1, events: [
        LiteralFixtureEvent(id: 1, x: 1, y: 0, pages: pages, name: eventName),
      ]),
    ],
  );
  return (
    fixture: fixture,
    analysis: SourceEventAnalyzer.forProject(fixture.source,
            profile: SourceEventProfile.forProject(fixture.source))
        .analyze(),
  );
}

SourceEventProjection _project(
        ({LiteralTileFixture fixture, SourceEventAnalysis analysis}) source,
        {MapInstanceRetentionPolicy? retentionPolicy, bool uniqueCharacters = false}) =>
    const SourceEventProjector().project(
      source: source.fixture.source,
      analysis: source.analysis,
      nativeMaps: {
        1: MapData(
          id: 'map',
          name: 'Map',
          size: const GridSize(width: 3, height: 1),
          layers: [],
        ),
      },
      characterBindings: {
        for (final graphic in source.analysis.events
            .expand((event) => event.pages)
            .map((page) => page.graphic!)
            .where((graphic) => graphic.characterName.isNotEmpty))
          sourceEventCharacterBindingKey(
                  characterName: graphic.characterName,
                  pattern: graphic.pattern,
                  direction: graphic.direction):
              SourceEventCharacterBinding(
                  characterId: uniqueCharacters ? 'fixture-${graphic.characterName}' : 'fixture-character',
                  sourceSnapshotHash: source.fixture.snapshot.canonicalHash,
                  sourceFileId: source.fixture.snapshot.entries
                      .singleWhere((file) =>
                          file.relativePath ==
                          'Graphics/Characters/${graphic.characterName}.png')
                      .fileId,
                  sourceFileHash: source.fixture.snapshot.entries
                      .singleWhere((file) =>
                          file.relativePath ==
                          'Graphics/Characters/${graphic.characterName}.png')
                      .sha256!,
                  sourcePattern: graphic.pattern,
                  sourceDirection: graphic.direction),
      },
      retentionPolicy: retentionPolicy,
    );

void main() {
  for (final name in ['Npc size(999999999999999999999999999999,1)',
    'Npc size(1000000000,1000000000)', 'Npc size(2147483647,2147483647)',
    'Npc size(0,1)', 'Npc size(1,0)', 'Npc size(65,1)']) {
    test('EV03 malformed dimensions quarantine the event safely: $name', () async {
      final source = await _source(const [LiteralFixtureEventPage(characterName: 'A',
        commands: [LiteralFixtureEventCommand(101, ['Text'])])], eventName: name);
      final result = _project(source);
      expect(result.nativeMaps[1]!.entities, isEmpty);
      expect(result.registry.records.single.definitionOrNull, isNull);
      expect(jsonEncode(result.semanticEvidence['events']), contains('eventPositionInvalid'));
    });
  }
  test('EV03 follows the source first size tag without combining later tags', () async {
    final source = await _source(const [LiteralFixtureEventPage(characterName: 'A',
      commands: [LiteralFixtureEventCommand(101, ['Text'])])], eventName: 'Npc size(1,1) size(0,0)');
    expect(_project(source).nativeMaps[1]!.entities.single.size, const GridSize(width: 1, height: 1));
  });
  test('EV03 page variants switch graphics, solid state and overlap semantics on one owner', () async {
    final source = await _source(const [
      LiteralFixtureEventPage(characterName: 'A', commands: [LiteralFixtureEventCommand(101, ['Base'])]),
      LiteralFixtureEventPage(characterName: 'B', direction: 4, through: true, globalSwitch: 1,
        commands: [LiteralFixtureEventCommand(101, ['Changed'])]),
    ]);
    final result = _project(source, uniqueCharacters: true);
    final map = result.nativeMaps[1]!;
    expect(map.entities, hasLength(1), reason: jsonEncode(result.semanticEvidence['events']));
    final owner = map.entities.single;
    expect(owner.presentation!.variants.map((variant) => variant.id), ['page_1', 'page_0']);
    expect(result.mutations.any((mutation) => mutation.actionId == 'entity.set_presentation'), isTrue);
    final project = ProjectManifest(name: 'Test', maps: const [], tilesets: const [], facts: result.facts,
      characters: const [ProjectCharacterEntry(id: 'fixture-A', name: 'A', tilesetId: 'actors'),
        ProjectCharacterEntry(id: 'fixture-B', name: 'B', tilesetId: 'actors')]);
    for (final changed in [false, true, false]) {
      final state = GameState(saveId: 'save', narrativeFactRuntimeState: NarrativeFactRuntimeState(
        overridesByFactId: {result.facts.single.id: changed}));
      final entity = projectMapEntityPresentations(project: project, gameState: state, map: map).entities.single;
      expect(entity.id, owner.id);
      expect(entity.npc!.characterId, changed ? 'fixture-B' : 'fixture-A');
      expect(entity.npc!.facing, changed ? EntityFacing.west : EntityFacing.south);
      expect(entity.blocksMovement, !changed);
      expect(entity.interactionMode, changed ? MapEntityInteractionMode.overlap : MapEntityInteractionMode.front);
    }
  });
  for (final mode in ['On', 'Off']) {
    for (final letter in ['A', 'B', 'C', 'D']) {
      test('literal ts$mode $letter qualifies pages and both branch polarities',
          () async {
        final source = await _source(const [
          LiteralFixtureEventPage(trigger: 1, through: true, commands: []),
          LiteralFixtureEventPage(
              trigger: 1,
              through: true,
              globalSwitch: 1,
              commands: [
                LiteralFixtureEventCommand(111, [0, 1, 0]),
                LiteralFixtureEventCommand(412, []),
                LiteralFixtureEventCommand(111, [0, 1, 1]),
                LiteralFixtureEventCommand(412, []),
              ]),
        ], switchNames: [
          null,
          's:ts$mode?("$letter")'
        ]);
        final event = source.analysis.events.single;
        expect(event.isQuarantined, isFalse);
        final condition = event.pages.last.condition.children.single;
        expect(condition.kind, SourceEventConditionKind.tempSwitch);
        expect(condition.tempSwitchLetter, letter);
        expect(condition.expectedValue, mode == 'On');
        expect(condition.evaluate(), isNull);
        for (final value in [false, true]) {
          final temporary = {letter: value};
          expect(
              event.selectPage(eventTempSwitches: temporary)!.originalPageIndex,
              value == (mode == 'On') ? 1 : 0);
          final branches = event.pages.last.body.nodes
              .whereType<SourceConditionalNode>()
              .toList();
          expect(branches, hasLength(2));
          expect(
              branches.first.condition.evaluate(eventTempSwitches: temporary),
              value == (mode == 'On'));
          expect(branches.last.condition.evaluate(eventTempSwitches: temporary),
              value != (mode == 'On'));
        }
        final projection = _project(source, retentionPolicy: _retention());
        expect(
            projection.registry.records
                .every((r) => r.definitionOrNull != null),
            isTrue,
            reason: '${projection.semanticEvidence}');
        final native = projection.registry.records.last.definitionOrNull!
            .conditionExpression.leaves.single
            .toJson();
        expect(native['kind'], 'mapEventInstanceBoolean');
        expect(native['eventId'], projection.nativeMaps[1]!.entities.single.id);
        expect(native['key'], letter);
        expect(native['expectedValue'], mode == 'On');
        expect(_project(source).semanticEvidence.toString(),
            contains('sourceMapInstanceRetentionMissing'));
      });
    }
  }

  for (final name in [
    's:tsOn?("A") ',
    's:tsOn?("A")\n',
    's:tsOn?("A"); arbitrary_ruby()',
    's:tsOn?("E")',
    's:tsOn?("a")',
    "s:tsOn?('A')",
    's:tsOn?("A", true)',
    's:tsOn("A")',
  ]) {
    test(
        'temporary switch names retain exact literal boundary ${jsonEncode(name)}',
        () async {
      final source = await _source(const [
        LiteralFixtureEventPage(trigger: 1, through: true, commands: []),
        LiteralFixtureEventPage(
            trigger: 1, through: true, globalSwitch: 1, commands: []),
      ], switchNames: [
        null,
        name
      ]);
      expect(source.analysis.events.single.isQuarantined, isTrue);
      final projection = _project(source, retentionPolicy: _retention());
      expect(projection.registry.records.single.definitionOrNull, isNull);
      expect(projection.scenes, isEmpty);
    });
  }

  test('page triggers are projected from each page rather than the first',
      () async {
    final source = await _source(const [
      LiteralFixtureEventPage(commands: [], through: true),
      LiteralFixtureEventPage(
        trigger: 1,
        through: true,
        globalSwitch: 1,
        commands: [
          LiteralFixtureEventCommand(101, ['Contact'])
        ],
      ),
    ]);
    final projection = _project(source);
    expect(projection.registry.records.every((r) => r.definitionOrNull != null),
        isTrue,
        reason: '${projection.semanticEvidence}');
    expect(
        projection.registry.records[0].definitionOrNull!.source,
        NarrativeEventSourceRef.entityInteract(
            'map', projection.nativeMaps[1]!.entities.single.id));
    expect(
        projection.registry.records[1].definitionOrNull!.source,
        NarrativeEventSourceRef.triggerEnter(
            'map', projection.nativeMaps[1]!.triggers.single.id));
  });

  test('stationary event contact trigger 2 uses proven native enter contact',
      () async {
    final source = await _source(const [
      LiteralFixtureEventPage(
        trigger: 2,
        through: true,
        commands: [
          LiteralFixtureEventCommand(101, ['Contact'])
        ],
      ),
    ]);
    final projection = _project(source);
    expect(projection.registry.records.single.definitionOrNull, isNotNull,
        reason: '${projection.semanticEvidence}');
  });

  for (final trigger in [1, 2]) {
    test('stationary blocking character contact $trigger uses entity bump',
        () async {
      final source = await _source([
        const LiteralFixtureEventPage(characterName: 'Actor', commands: []),
        LiteralFixtureEventPage(
            characterName: 'Actor',
            trigger: trigger,
            globalSwitch: 1,
            commands: const [
              LiteralFixtureEventCommand(101, ['Front contact'])
            ]),
      ]);
      final projection = _project(source);
      expect(
          projection.registry.records.every((r) => r.definitionOrNull != null),
          isTrue,
          reason: '${projection.semanticEvidence}');
      final anchor = projection.nativeMaps[1]!.entities.single.id;
      expect(projection.nativeMaps[1]!.triggers, isEmpty);
      expect(projection.registry.records.first.definitionOrNull!.source,
          NarrativeEventSourceRef.entityInteract('map', anchor));
      expect(projection.registry.records.last.definitionOrNull!.source,
          NarrativeEventSourceRef.entityBump('map', anchor));
    });
  }

  test('ordinary temporary switch writes use event instance state', () async {
    final source = await _source(const [
      LiteralFixtureEventPage(
        trigger: 1,
        through: true,
        commands: [
          LiteralFixtureEventCommand(355, ['setTempSwitchOn("A")'])
        ],
      ),
    ]);
    final projection = _project(source,
        retentionPolicy: MapInstanceRetentionPolicy(
            viewportWidthTiles: 20, viewportHeightTiles: 15, marginTiles: 1));
    expect(projection.registry.records.single.definitionOrNull, isNotNull,
        reason: '${projection.semanticEvidence}');
    final missing = _project(source);
    expect(missing.semanticEvidence.toString(),
        contains('sourceMapInstanceRetentionMissing'));
  });

  test('temporary page selection uses the current event snapshot and priority',
      () async {
    final source = await _source(const [
      LiteralFixtureEventPage(trigger: 1, through: true, commands: [
        LiteralFixtureEventCommand(101, ['Base'])
      ]),
      LiteralFixtureEventPage(
          trigger: 1, through: true, globalSwitch: 1, commands: []),
    ], switchNames: [
      null,
      's:tsOff?("A")'
    ]);
    final event = source.analysis.events.single;
    expect(event.selectPage(), isNull);
    expect(event.selectPage(eventTempSwitches: {})!.originalPageIndex, 1);
    expect(event.selectPage(eventTempSwitches: {})!.isEmpty, isTrue);
    expect(
        event.selectPage(eventTempSwitches: {'A': true})!.originalPageIndex, 0);
    final projection = _project(source, retentionPolicy: _retention());
    expect(projection.registry.records.every((r) => r.definitionOrNull != null),
        isTrue,
        reason: '${projection.semanticEvidence}');
    final conditions = projection
        .registry.records.last.definitionOrNull!.conditionExpression.leaves;
    expect(conditions.single.toJson(), {
      'kind': 'mapEventInstanceBoolean',
      'mapId': 'map',
      'eventId': projection.nativeMaps[1]!.entities.single.id,
      'key': 'A',
      'expectedValue': false,
    });
    expect(_project(source).semanticEvidence.toString(),
        contains('sourceMapInstanceRetentionMissing'));
  });

  test('nested temporary writes and guards require retention', () async {
    final source = await _source(const [
      LiteralFixtureEventPage(trigger: 1, through: true, commands: [
        LiteralFixtureEventCommand(111, [0, 1, 0]),
        LiteralFixtureEventCommand(355, ['setTempSwitchOn("B")'], indent: 1),
        LiteralFixtureEventCommand(411, []),
        LiteralFixtureEventCommand(355, ['setTempSwitchOn("D")'], indent: 1),
        LiteralFixtureEventCommand(412, []),
      ]),
    ], switchNames: [
      null,
      's:tsOff?("C")'
    ]);
    expect(source.analysis.events.single.isQuarantined, isFalse);
    expect(_project(source).semanticEvidence.toString(),
        contains('sourceMapInstanceRetentionMissing'));
    final projection = _project(source, retentionPolicy: _retention());
    expect(projection.registry.records.single.definitionOrNull, isNotNull,
        reason: '${projection.semanticEvidence}');
    final branches = projection.scenes.single.graph.nodes
        .map((node) => node.payload)
        .whereType<SceneConditionPayload>();
    expect(branches.single.conditionSource!.toJson()['sourceKind'],
        'mapEventInstanceBoolean');
    expect(_tempWrites(projection).map((c) => c.key).toSet(), {'B', 'D'});
  });

  test('moving contact and unqualified automatic execution stay quarantined',
      () async {
    for (final page in const [
      LiteralFixtureEventPage(
          trigger: 2,
          through: true,
          moveType: 1,
          commands: [
            LiteralFixtureEventCommand(101, ['Moving'])
          ]),
      LiteralFixtureEventPage(trigger: 3, through: true, commands: [
        LiteralFixtureEventCommand(101, ['Autorun'])
      ]),
      LiteralFixtureEventPage(trigger: 4, through: true, commands: [
        LiteralFixtureEventCommand(101, ['Parallel'])
      ]),
      LiteralFixtureEventPage(trigger: 1, through: true, commands: [
        LiteralFixtureEventCommand(355, ['arbitrary_ruby()'])
      ]),
    ]) {
      final projection = _project(await _source([page]));
      expect(projection.registry.records.single.definitionOrNull, isNull);
      expect(projection.scenes, isEmpty);
    }
  });

  test('native dispatch respects each trigger and suppresses lower pages',
      () async {
    final source = await _source(const [
      LiteralFixtureEventPage(commands: [], through: true),
      LiteralFixtureEventPage(
          trigger: 2, through: true, globalSwitch: 1, commands: []),
    ]);
    final projection = _project(source);
    final low = projection.registry.records.first.definitionOrNull!;
    final high = projection.registry.records.last.definitionOrNull!;
    final initial = _state();
    expect(
        (_dispatch(projection, low.source, initial)
                as NarrativeEventDispatchHandled)
            .eventId,
        low.id);
    expect(_dispatch(projection, high.source, initial),
        isA<NarrativeEventDispatchNoMatch>());
    final on = initial.copyWith(
        narrativeFactRuntimeState:
            NarrativeFactRuntimeState(overridesByFactId: {
      projection.facts.single.id: true,
    }));
    expect(_dispatch(projection, low.source, on),
        isA<NarrativeEventDispatchNoMatch>());
    expect(
        (_dispatch(projection, high.source, on)
                as NarrativeEventDispatchHandled)
            .eventId,
        high.id);
  });

  test(
      'projected temp writes dispatch after save restore and reset on eviction',
      () async {
    final source = await _source(const [
      LiteralFixtureEventPage(trigger: 1, through: true, commands: [
        LiteralFixtureEventCommand(355, ['setTempSwitchOn("A")']),
        LiteralFixtureEventCommand(121, [2, 2, 0]),
        LiteralFixtureEventCommand(123, ['B', 0]),
      ]),
      LiteralFixtureEventPage(
          trigger: 1, through: true, globalSwitch: 1, commands: []),
    ], switchNames: [
      null,
      's:tsOff?("A")',
      'Persistent'
    ]);
    final projection = _project(source, retentionPolicy: _retention());
    expect(projection.registry.records.every((r) => r.definitionOrNull != null),
        isTrue,
        reason: '${projection.semanticEvidence}');
    final initial = _state();
    final anchor = projection.nativeMaps[1]!.entities.single.id;
    final low = projection.registry.records.first.definitionOrNull!;
    final high = projection.registry.records.last.definitionOrNull!;
    expect(
        (_dispatch(projection, high.source, initial)
                as NarrativeEventDispatchHandled)
            .eventId,
        high.id);
    final instance = initial.mapInstanceWorldState.instanceRef('map')!;
    final changed = applySceneMapEventInstanceBoolean(
      gameState: initial,
      consequence: _tempWrites(projection).single,
      map: projection.nativeMaps[1]!,
      expectedInstance: instance,
    ).copyWith(
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
      overridesByFactId: {for (final fact in projection.facts) fact.id: true},
    ));
    final restored = gameStateFromSaveData(saveDataFromGameState(changed));
    expect(restored.mapInstanceWorldState.instanceRef('map'), instance);
    expect(restored.mapInstanceWorldState.eventBoolean(instance, anchor, 'A'),
        isTrue);
    expect(
        restored.narrativeFactRuntimeState, changed.narrativeFactRuntimeState);
    expect(
        (_dispatch(projection, low.source, restored)
                as NarrativeEventDispatchHandled)
            .eventId,
        low.id);
    final evicted = restored.copyWith(
        mapInstanceWorldState: setupDifferentMapInstance(
            state: restored.mapInstanceWorldState,
            targetMapId: 'neighbor',
            allocateId: (_) => 'neighbor-instance'));
    final recreated = evicted.copyWith(
        mapInstanceWorldState: setupDifferentMapInstance(
            state: evicted.mapInstanceWorldState,
            targetMapId: 'map',
            allocateId: (_) => 'new-map-instance'));
    final fresh = recreated.mapInstanceWorldState.instanceRef('map')!;
    expect(recreated.mapInstanceWorldState.eventBoolean(fresh, anchor, 'A'),
        isFalse);
    expect(recreated.narrativeFactRuntimeState,
        restored.narrativeFactRuntimeState);
    expect(
        (_dispatch(projection, high.source, recreated)
                as NarrativeEventDispatchHandled)
            .eventId,
        high.id);
    expect(
        () =>
            recreated.mapInstanceWorldState.eventBoolean(instance, anchor, 'A'),
        throwsStateError);
  });

  test('self switches stay distinct across maps and events and global switches',
      () async {
    final fixture = await LiteralTileFixture.create(
      interpretationProfile: syntheticSourceInterpretationProfile,
      scriptsBytes: syntheticInterpretationArchive,
      includeEventSystem: true,
      maps: [
        for (final mapId in [1, 2])
          LiteralFixtureMap(id: mapId, events: [
            for (final eventId in [1, 2])
              LiteralFixtureEvent(id: eventId, x: 1, y: 0, pages: const [
                LiteralFixtureEventPage(commands: []),
                LiteralFixtureEventPage(commands: [], selfSwitch: 'A'),
                LiteralFixtureEventPage(commands: [], globalSwitch: 1),
              ]),
          ])
      ],
    );
    final analysis = SourceEventAnalyzer.forProject(fixture.source,
            profile: SourceEventProfile.forProject(fixture.source))
        .analyze();
    final selfIds = analysis.events
        .map((event) => event.pages[1].condition.children.single.factId!)
        .toSet();
    expect(selfIds, hasLength(4));
    final globalIds = analysis.events
        .map((event) => event.pages[2].condition.children.single.factId!)
        .toSet();
    expect(globalIds, hasLength(1));
    expect(selfIds.intersection(globalIds), isEmpty);
    final active = analysis.events.first;
    final facts = {active.pages[1].condition.children.single.factId!: true};
    for (final event in analysis.events) {
      expect(event.selectPage(facts: facts)!.originalPageIndex,
          identical(event, active) ? 1 : 0);
      expect(
          event.selectPage(
              facts: {...facts, globalIds.single: true})!.originalPageIndex,
          2);
    }
  });

  test('page selection forwards item position and facing execution context',
      () async {
    final source = await _source(const [
      LiteralFixtureEventPage(commands: []),
      LiteralFixtureEventPage(commands: [], globalSwitch: 1),
    ]);
    final original = source.analysis.events.single;
    final page = original.pages.last;
    final event = SourceEventDefinition(
        sourceMapId: original.sourceMapId,
        sourceEventId: original.sourceEventId,
        sourceFileId: original.sourceFileId,
        identity: original.identity,
        name: original.name,
        x: original.x,
        y: original.y,
        locator: original.locator,
        pages: [
          original.pages.first,
          SourceEventPageAnalysis(
              sourcePage: page.sourcePage,
              locator: page.locator,
              graphic: page.graphic,
              body: page.body,
              rawDataRef: page.rawDataRef,
              diagnostics: [],
              condition: SourceEventCondition(
                  kind: SourceEventConditionKind.all,
                  children: [
                    SourceEventCondition(
                        kind: SourceEventConditionKind.itemPresence,
                        sourceItemSymbol: 'POTION'),
                    SourceEventCondition(
                        kind: SourceEventConditionKind.playerOnEvent),
                    SourceEventCondition(
                        kind: SourceEventConditionKind.playerFacing,
                        sourceDirection: 6),
                  ])),
        ]);
    expect(event.selectPage(itemQuantities: {'POTION': 1}), isNull);
    expect(
        event.selectPage(
            itemQuantities: {'POTION': 1},
            playerOnEvent: true,
            playerFacing: 6)!.originalPageIndex,
        1);
    expect(
        event.selectPage(
            itemQuantities: {'POTION': 1},
            playerOnEvent: false)!.originalPageIndex,
        0);
  });

  test('projected temp semantics use canonical authoring action JSON envelopes',
      () async {
    final projection = _project(
        await _source(const [
          LiteralFixtureEventPage(trigger: 1, through: true, commands: [
            LiteralFixtureEventCommand(355, ['setTempSwitchOn("A")'])
          ]),
          LiteralFixtureEventPage(
              trigger: 1, through: true, globalSwitch: 1, commands: []),
        ], switchNames: [
          null,
          's:tsOff?("A")'
        ]),
        retentionPolicy: _retention());
    final project = _projectManifest(projection);
    final mutations = projection.mutations.where((mutation) =>
        ['scene.upsert', 'event_v2.record_upsert'].contains(mutation.actionId));
    expect(mutations, hasLength(4));
    for (final mutation in mutations) {
      final before = mutation.actionId == 'scene.upsert'
          ? project.copyWith(
              scenes: project.scenes
                  .where((scene) =>
                      scene.id != (mutation.parameters['scene'] as Map)['id'])
                  .toList())
          : project.copyWith(
              eventRegistry: NarrativeEventRegistry(
                  schemaVersion: 1,
                  mode: EventSystemMode.v2Only,
                  legacyClaims: [],
                  records: projection.registry.records
                      .where((record) =>
                          record.id !=
                          NarrativeEventRecord.fromJson(
                                  mutation.parameters['record'])
                              .id)
                      .toList()));
      final bytes = {
        'project': utf8.encode(jsonEncode(before.toJson())),
        for (final map in projection.nativeMaps.values)
          'map:${map.id}': utf8.encode(jsonEncode(map.toJson())),
      };
      final snapshot = ProjectSnapshot(
          projectHandle: const ProjectHandle('prj_ev02'),
          revision: 'sha256:${'1' * 64}',
          manifest: before,
          maps: projection.nativeMaps.values,
          resourceBytes: bytes,
          resourceFingerprints: {
            for (final entry in bytes.entries)
              entry.key: computeAuthoringBytesFingerprint(entry.value,
                  logicalName: entry.key == 'project'
                      ? 'project.json'
                      : 'maps/${entry.key.substring(4)}.json')
          });
      final request = AuthoringRequest.fromJson(jsonDecode(jsonEncode(
          AuthoringRequest(
                  requestId: mutation.operationId.value,
                  actionId: mutation.actionId,
                  actionVersion: mutation.actionVersion,
                  workspaceHandle: 'workspace_ev02',
                  expectedRevision: snapshot.revision,
                  parameters: mutation.parameters)
              .toJson())) as Map<String, dynamic>);
      final context = AuthoringPlanningContext(
          snapshot: snapshot, request: request, planId: 'plan_ev02', seed: 1);
      final draft = mutation.actionId == 'scene.upsert'
          ? const SceneActions().build(context)
          : const EventV2Actions().build(context);
      expect(draft.changeSet.changes, hasLength(1));
      final after = ProjectManifest.fromJson(
          jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
              as Map<String, dynamic>);
      expect(after.eventRegistry!.records.length, 2);
      expect(after.scenes.length, 2);
      expect(jsonEncode(after.toJson()), contains('mapEventInstanceBoolean'));
      expect(
          jsonEncode(after.toJson()), contains('setMapEventInstanceBoolean'));
    }
  });
}

MapInstanceRetentionPolicy _retention() => MapInstanceRetentionPolicy(
    viewportWidthTiles: 20, viewportHeightTiles: 15, marginTiles: 1);

GameState _state() => GameState(
    saveId: 'ev02',
    currentMapId: 'map',
    mapInstanceWorldState: MapInstanceWorldState(instancesByMapId: {
      'map': MapInstanceRuntimeState(instanceId: 'map-instance'),
    }));

Iterable<SceneSetMapEventInstanceBooleanConsequence> _tempWrites(
        SourceEventProjection projection) =>
    projection.scenes
        .expand((scene) => scene.graph.nodes)
        .map((node) => node.payload)
        .whereType<SceneActionPayload>()
        .map((action) => action.consequence)
        .whereType<SceneSetMapEventInstanceBooleanConsequence>();

NarrativeEventDispatchDecision _dispatch(SourceEventProjection projection,
    NarrativeEventSourceRef occurrence, GameState state) {
  final maps = projection.nativeMaps.values.toList();
  final project = _projectManifest(projection);
  final catalog =
      buildNarrativeEventProjectCatalog(project: project, maps: maps);
  expect(catalog.hasBlockingDiagnostics, isFalse,
      reason: '${catalog.diagnostics.map((d) => d.code).toList()}');
  final authority = NarrativeEventDispatchAuthority.prepare(
      registryResult: EventRegistryDecodeResult.decoded(projection.registry),
      occurrence: NarrativeEventOccurrence(source: occurrence),
      factResolver: NarrativeFactRuntimeResolver.fromFacts(projection.facts),
      projectCatalog: catalog,
      project: project,
      maps: maps);
  expect(authority, isA<NarrativeEventDispatchAuthorityReady>());
  return NarrativeEventDispatchPlanner().plan(
      authority: authority as NarrativeEventDispatchAuthorityReady,
      gameState: state);
}

ProjectManifest _projectManifest(SourceEventProjection projection) =>
    ProjectManifest(
        name: 'EV02',
        tilesets: [],
        maps: [
          for (final map in projection.nativeMaps.values)
            ProjectMapEntry(
                id: map.id, name: map.name, relativePath: 'maps/${map.id}.json')
        ],
        eventRegistry: projection.registry,
        scenes: projection.scenes,
        facts: projection.facts,
        dialogues: projection.dialogues);
