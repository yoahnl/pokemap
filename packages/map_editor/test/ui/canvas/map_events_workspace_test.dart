import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/events_v2/map_events_workspace.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

const _eventId = 'evt_20000000-0000-7000-8000-000000000001';

void main() {
  testWidgets('lists physical sources and synchronizes their linked Event',
      (tester) async {
    final openedSources = <String>[];
    final openedEvents = <String>[];
    final model = _model();
    await _pump(
      tester,
      MapEventsWorkspace(
        readModel: model,
        onOpenSource: (row) => openedSources.add(row.stableKey),
        onOpenEvent: openedEvents.add,
      ),
    );

    expect(find.text('Port des Brisants'), findsWidgets);
    expect(find.text('Lysa — PNJ'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('map-events-source-npc_lysa')));
    await tester.pump();

    expect(find.text('Aperçu de la map'), findsOneWidget);
    expect(find.text('Rencontre au port'), findsWidgets);
    await tester.tap(
      find.byKey(const ValueKey('map-events-open-source')),
    );
    await tester.tap(
      find.byKey(const ValueKey('map-events-open-event-$_eventId')),
    );

    expect(openedSources, hasLength(1));
    expect(openedEvents, [_eventId]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('filters unlinked sources and opens exact Scene Fact and Rule',
      (tester) async {
    final openedScenes = <String>[];
    final openedFacts = <String>[];
    final openedRules = <String>[];
    await _pump(
      tester,
      MapEventsWorkspace(
        readModel: _model(),
        onOpenScene: openedScenes.add,
        onOpenFact: openedFacts.add,
        onOpenWorldRule: openedRules.add,
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('map-events-status-unlinked')),
    );
    await tester.pump();
    expect(find.text('Quai nord — Zone'), findsOneWidget);
    expect(find.text('Lysa — PNJ'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('map-events-view-events')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('map-events-event-$_eventId')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('map-events-open-scene-scene_port')),
    );
    await tester.tap(
      find.byKey(const ValueKey('map-events-open-fact-fact_port_open')),
    );

    await tester.tap(
      find.byKey(const ValueKey('map-events-view-rules')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('map-events-rule-rule_hide_lysa')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('map-events-open-rule-rule_hide_lysa')),
    );

    expect(openedScenes, ['scene_port']);
    expect(openedFacts, ['fact_port_open']);
    expect(openedRules, ['rule_hide_lysa']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('restores the focused physical row after Map Editor return',
      (tester) async {
    final model = _model();
    final source = model.maps.single.sources.singleWhere(
      (row) => row.option.ownerId == 'npc_lysa',
    );
    await _pump(
      tester,
      MapEventsWorkspace(
        readModel: model,
        requestedFocusAnchorId: source.stableKey,
        requestedSelectionNonce: 7,
      ),
    );

    final card = tester.widget<PokeMapCard>(
      find.byKey(const ValueKey('map-events-source-npc_lysa')),
    );
    expect(card.selected, isTrue);
    expect(find.text('Lysa — PNJ'), findsWidgets);
  });

  testWidgets('keeps the synchronized inspector available on a narrow canvas',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(body: MapEventsWorkspace(readModel: _model())),
      ),
    );
    await tester.pump();

    expect(find.text('Aperçu de la map'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('map-events-open-source')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.binding.setSurfaceSize(const Size(1400, 820));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(body: child),
    ),
  );
  await tester.pump();
}

NarrativeMapEventsReadModel _model() {
  final source = NarrativeEventSourceRef.entityInteract('map_port', 'npc_lysa');
  final event = NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: _eventId,
      name: 'Rencontre au port',
      source: source,
      conditions: [
        NarrativeEventCondition.fact('fact_port_open', true),
      ],
      sceneId: 'scene_port',
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: 3,
      order: 1,
    ),
    enabled: true,
  );
  final project = ProjectManifest(
    name: 'Selbrume',
    maps: const [
      ProjectMapEntry(
        id: 'map_port',
        name: 'Port des Brisants',
        relativePath: 'maps/port.json',
      ),
    ],
    tilesets: const [],
    facts: [
      NarrativeFactDefinition(
        id: 'fact_port_open',
        label: 'Port ouvert',
      ),
    ],
    scenes: [_scene()],
    worldRules: [
      WorldRuleDefinition(
        id: 'rule_hide_lysa',
        label: 'Lysa disparaît',
        source: const WorldRuleSource(
          kind: WorldRuleSourceKind.fact,
          sourceId: 'fact_port_open',
          predicate: WorldRuleSourcePredicate.isTrue,
        ),
        target: const WorldRuleTarget(
          kind: WorldRuleTargetKind.mapEntity,
          mapId: 'map_port',
          entityId: 'npc_lysa',
        ),
        effect: const WorldRuleEffect(
          kind: WorldRuleEffectKind.entityHidden,
        ),
      ),
    ],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: [event],
      legacyClaims: const [],
    ),
  );
  const map = MapData(
    id: 'map_port',
    name: 'Port des Brisants',
    size: GridSize(width: 12, height: 10),
    entities: [
      MapEntity(
        id: 'npc_lysa',
        name: 'Lysa',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 2, y: 3),
      ),
    ],
    triggers: [
      MapTrigger(
        id: 'zone_quay',
        name: 'Quai nord',
        type: TriggerType.event,
        area: MapRect(
          pos: GridPos(x: 4, y: 3),
          size: GridSize(width: 2, height: 1),
        ),
      ),
    ],
  );
  return buildNarrativeMapEventsReadModel(project: project, maps: [map]);
}

SceneAsset _scene() => SceneAsset(
      id: 'scene_port',
      name: 'Rencontre au port',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'edge',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      ),
    );
