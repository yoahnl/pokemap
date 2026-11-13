import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space_outline.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

final _scene = SceneAsset(
  id: 'scene',
  name: 'Scène',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'end',
        kind: SceneNodeKind.end,
        payload: SceneEndPayload(outcomePolicy: SceneOutcomePolicy.progression),
      ),
    ],
    edges: [
      SceneEdge(
        id: 'start-end',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  ),
);

NarrativeEventRecord _event(
  int index,
  String name,
  NarrativeEventSourceRef source,
) => NarrativeEventRecord.configuredStructurallyUnchecked(
  NarrativeEventDefinition(
    id: 'evt_00000000-0000-7000-8000-${index.toString().padLeft(12, '0')}',
    name: name,
    source: source,
    conditions: const [],
    sceneId: 'scene',
    reusePolicy: NarrativeEventReusePolicy.oneShot,
    priority: 0,
    order: index,
  ),
  enabled: true,
);

final _meeting = _event(
  1,
  'meeting',
  NarrativeEventSourceRef.entityInteract('a', 'luth'),
);
final _ghost = _event(
  2,
  'ghost',
  NarrativeEventSourceRef.entityInteract('a', 'gone'),
);
final _lostZone = _event(
  3,
  'lost zone',
  NarrativeEventSourceRef.triggerEnter('a', 'old-zone'),
);
final _elsewhere = _event(
  4,
  'elsewhere',
  NarrativeEventSourceRef.entityInteract('b', 'gone'),
);

ProjectManifest _project(List<NarrativeEventRecord> records) =>
    workspaceProject.copyWith(
      scenes: [_scene],
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: records,
        legacyClaims: const [],
      ),
    );

MapData _map() => workspaceMap('a').copyWith(
  entities: const [
    MapEntity(
      id: 'luth',
      name: 'Luth',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 3, y: 2),
      npc: MapEntityNpcData(displayName: 'Luth'),
    ),
    MapEntity(
      id: 'board',
      name: 'Panneau du village',
      kind: MapEntityKind.sign,
      pos: GridPos(x: 8, y: 1),
      sign: MapEntitySignData(plainText: 'Bourg Geon'),
    ),
  ],
  triggers: const [
    MapTrigger(
      id: 'departure',
      name: 'Départ vers la route',
      type: TriggerType.event,
      area: MapRect(
        pos: GridPos(x: 1, y: 6),
        size: GridSize(width: 2, height: 2),
      ),
    ),
  ],
);

void main() {
  late MapWorkspaceController maps;
  late MapBuilderStoryBinding story;

  Future<void> open(
    WidgetTester tester,
    List<NarrativeEventRecord> records,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final port = WorkspaceMemoryPort(manifest: _project(records));
    port.saved['a'] = _map();
    maps = MapWorkspaceController(workspaceSession, port);
    addTearDown(maps.dispose);
    await maps.initialize();
    final view = MapEditingViewportSession();
    addTearDown(view.dispose);
    final tick = ValueNotifier(0);
    addTearDown(tick.dispose);
    story = MapBuilderStoryBinding(
      maps: maps,
      changed: () => tick.value++,
      view: () => view,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ListenableBuilder(
            listenable: tick,
            builder: (context, _) => Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MapBuilderStoryPanel(
                  outline: mapBuilderSpaceOutline(
                    MapBuilderSpace.story,
                    AppLocalizations.of(context),
                  )!,
                  binding: story,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Finder key(String value) => find.byKey(ValueKey(value));
  Finder orphan(NarrativeEventRecord record) =>
      key('map-story-orphan-${record.id}');

  NarrativeEventRecord? draft(NarrativeEventRecord record) => story.behaviours
      .registry(maps.project!)!
      .records
      .where((item) => item.id == record.id)
      .firstOrNull;

  NarrativeEventRecord saved(NarrativeEventRecord record) => maps
      .project!
      .eventRegistry!
      .records
      .singleWhere((item) => item.id == record.id);

  testWidgets('a map whose behaviours all have their element shows no repair', (
    tester,
  ) async {
    await open(tester, [_meeting, _elsewhere]);

    expect(story.orphans, isEmpty);
    expect(key('map-story-repair'), findsNothing);
    expect(find.text('À réparer'), findsNothing);
  });

  testWidgets('behaviours whose element left the map are listed to repair', (
    tester,
  ) async {
    await open(tester, [_meeting, _ghost, _lostZone, _elsewhere]);

    expect(find.text('À réparer'), findsOneWidget);
    expect(orphan(_ghost), findsOneWidget);
    expect(orphan(_lostZone), findsOneWidget);
    expect(orphan(_meeting), findsNothing);
    expect(orphan(_elsewhere), findsNothing);
    expect(find.text('ghost'), findsOneWidget);
    expect(find.text('lost zone'), findsOneWidget);
    expect(
      find.text('Son élément n’existe plus sur cette carte.'),
      findsNWidgets(2),
    );
    expect(find.text('Réattribuer'), findsNWidgets(2));
    expect(find.text('Supprimer'), findsNWidgets(2));
  });

  testWidgets('reassigning an orphan rewrites its source in the draft', (
    tester,
  ) async {
    await open(tester, [_meeting, _ghost]);

    final select = tester.widget<StudioSelect>(
      key('map-story-orphan-reassign-${_ghost.id}'),
    );
    expect(select.options.keys, [
      'entity:luth',
      'entity:board',
      'trigger:departure',
    ]);
    select.onChanged!('entity:board');
    await tester.pump();

    expect(story.repairError, isNull);
    expect(
      draft(_ghost)!.source,
      NarrativeEventSourceRef.entityInteract('a', 'board'),
    );
    expect(
      story.elements!.byKey('entity:board')!.behaviours.single.id,
      _ghost.id,
    );
    expect(key('map-story-repair'), findsNothing);
    expect(story.dirty, isTrue);
    expect(
      saved(_ghost).source,
      NarrativeEventSourceRef.entityInteract('a', 'gone'),
    );

    story.undo();
    await tester.pump();
    expect(
      draft(_ghost)!.source,
      NarrativeEventSourceRef.entityInteract('a', 'gone'),
    );
    expect(orphan(_ghost), findsOneWidget);
    expect(story.dirty, isFalse);

    story.redo();
    await tester.pump();
    expect(orphan(_ghost), findsNothing);
    expect(story.dirty, isTrue);
  });

  testWidgets('an orphan reassigned to a zone triggers when entering it', (
    tester,
  ) async {
    await open(tester, [_ghost]);

    tester
        .widget<StudioSelect>(key('map-story-orphan-reassign-${_ghost.id}'))
        .onChanged!('trigger:departure');
    await tester.pump();

    expect(story.repairError, isNull);
    expect(
      draft(_ghost)!.source,
      NarrativeEventSourceRef.triggerEnter('a', 'departure'),
    );
    expect(key('map-story-repair'), findsNothing);
  });

  testWidgets('deleting an orphan removes it from the draft', (tester) async {
    await open(tester, [_meeting, _ghost, _lostZone]);

    await tester.tap(key('map-story-orphan-delete-${_lostZone.id}'));
    await tester.pump();

    expect(story.repairError, isNull);
    expect(draft(_lostZone), isNull);
    expect(orphan(_lostZone), findsNothing);
    expect(orphan(_ghost), findsOneWidget);
    expect(story.dirty, isTrue);
    expect(saved(_lostZone).name, 'lost zone');

    story.undo();
    await tester.pump();
    expect(orphan(_lostZone), findsOneWidget);
    expect(story.dirty, isFalse);
  });

  testWidgets('an element deleted from the map draft orphans its behaviours', (
    tester,
  ) async {
    await open(tester, [_meeting]);
    expect(key('map-story-repair'), findsNothing);

    final document = maps.active!;
    document.commit(
      document.current.copyWith(
        entities: [
          for (final entity in document.current.entities)
            if (entity.id != 'luth') entity,
        ],
      ),
    );
    maps.notify();
    story.changed();
    await tester.pump();

    expect(orphan(_meeting), findsOneWidget);
    document.restore(redo: false);
    story.changed();
    await tester.pump();
    expect(key('map-story-repair'), findsNothing);
  });
}
