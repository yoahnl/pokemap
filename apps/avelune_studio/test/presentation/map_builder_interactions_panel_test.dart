import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/scoped_map_workspace_port.dart';
import '../story_draft/story_fake_ports.dart';

import 'map_builder_story_harness.dart';
import 'map_builder_story_support.dart' as support;
import 'story_memory_harness.dart' as memory;

Finder _key(String value) => find.byKey(ValueKey(value));

void main() {
  testWidgets(
    'a partial appearance list can load the remaining characters explicitly',
    (tester) async {
      final port = _Characters();
      final maps = MapWorkspaceController(scopedMapSession, port);
      addTearDown(maps.dispose);
      await maps.initialize();
      final tick = ValueNotifier(0);
      addTearDown(tick.dispose);
      final view = MapEditingViewportSession();
      final story = MapBuilderStoryBinding(
        maps: maps,
        changed: () => tick.value++,
        view: () => view,
      );
      final fixture = (
        maps: maps,
        story: story,
        tick: tick,
        ports: StoryFakePorts(() => maps.project!),
      );
      await support.pumpStoryInspector(tester, fixture);
      expect(port.resourceKinds, isEmpty);
      expect(
        tester.widget<StudioSelect>(_key('map-story-appearance')).options.keys,
        ['luth'],
      );
      expect(_key('map-story-load-characters'), findsOneWidget);
      await tester.tap(_key('map-story-load-characters'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<StudioSelect>(_key('map-story-appearance')).options.keys,
        ['luth', 'maman'],
      );
      expect(port.resourceKinds, ['character']);
      expect(port.fullReads, 0);
      expect(story.dirty, isFalse);
      expect(_key('map-story-load-characters'), findsNothing);
    },
  );

  testWidgets('canvas selection also starts the next carrier on Properties', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(_key('map-story-element-entity:luth'));
    story.reconcile();
    await tester.pump();
    story.openTab(MapStoryTab.behaviour);
    await tester.pump();
    view.select(maps.active!, MapSelectionFamily.marker, 'board');
    story.reconcile();
    story.changed();
    await tester.pump();
    expect(story.tab, MapStoryTab.properties);
    expect(_key('map-story-properties-entity:board'), findsOneWidget);
  });

  testWidgets('a missing scene can be repaired through Complete in Story', (
    tester,
  ) async {
    final record = support.storyRecord(
      1,
      sceneId: 'lost',
      source: NarrativeEventSourceRef.entityInteract('a', 'guide'),
    );
    await memory.openMemoryStudio(
      tester,
      memory.memoryIndex(),
      world: memory.MapOnlyWorld.new,
      project: memory.memoryProject.copyWith(
        scenes: [support.storyPlainScene('valid')],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [record],
          legacyClaims: [],
        ),
      ),
    );
    await tester.tap(_key('map-space-story'));
    await memory.settleMemory(tester);
    await tester.tap(_key('map-story-element-entity:guide'));
    await memory.settleMemory(tester);
    await tester.tap(find.text('Déclencheurs'));
    await memory.settleMemory(tester);
    await tester.tap(_key('map-interaction-trigger-open-${memory.guideTalk}'));
    await memory.settleMemory(tester);
    expect(_key('story-trigger-editor'), findsOneWidget);
    expect(_key('map-story-then'), findsOneWidget);
    final picker = tester.widget<StudioSelect>(_key('map-story-then'));
    expect(picker.value, 'lost');
    picker.onChanged!('valid');
    await memory.settleMemory(tester);
    expect(tester.widget<StudioSelect>(_key('map-story-then')).value, 'valid');
    expect(find.textContaining('lost'), findsNothing);
  });

  testWidgets('each local link and creation opens its exact central rule', (
    tester,
  ) async {
    await memory.openMemoryStudio(
      tester,
      memory.memoryIndex(),
      world: memory.MapOnlyWorld.new,
    );
    await tester.tap(_key('map-space-story'));
    await memory.settleMemory(tester);
    await tester.tap(_key('map-story-element-entity:guide'));
    await memory.settleMemory(tester);
    await tester.tap(find.text('Déclencheurs'));
    await memory.settleMemory(tester);
    await tester.tap(_key('map-interaction-trigger-open-${memory.guideTalk}'));
    await memory.settleMemory(tester);
    expect(_key('story-trigger-editor'), findsOneWidget);
    expect(
      _key('map-story-behaviour-name-${memory.guideTalk}'),
      findsOneWidget,
    );
    await tester.tap(_key('story-return'));
    await memory.settleMemory(tester);
    expect(_key('map-interaction-triggers'), findsOneWidget);
    await tester.tap(_key('map-story-behaviour-add'));
    await memory.settleMemory(tester);
    expect(_key('story-trigger-editor'), findsOneWidget);
    expect(_key('map-story-behaviour-name-${memory.guideTalk}'), findsNothing);
    expect(find.text('Déclencheur 2'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Interactions starts with physical properties for each carrier', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Interactions'), findsOneWidget);
    for (final target in ['entity:luth', 'entity:board', 'trigger:departure']) {
      await tester.tap(_key('map-story-element-$target'));
      await tester.pump();
      expect(story.tab, MapStoryTab.properties);
      expect(_key('map-story-properties-$target'), findsOneWidget);
      expect(_key('map-story-x'), findsOneWidget);
      expect(_key('map-story-y'), findsOneWidget);
      expect(_key('map-story-when'), findsNothing);
      expect(_key('map-story-then'), findsNothing);
    }
    expect(_key('map-story-width'), findsOneWidget);
    expect(_key('map-story-height'), findsOneWidget);
  });

  testWidgets('trigger cards replace the local narrative form', (tester) async {
    await open(tester);
    await tester.tap(_key('map-story-element-entity:luth'));
    await tester.pump();
    await tester.tap(find.text('Déclencheurs'));
    await tester.pump();
    expect(story.tab, MapStoryTab.behaviour);
    expect(_key('map-interaction-triggers'), findsOneWidget);
    expect(_key('map-story-when'), findsNothing);
    expect(_key('map-story-condition-add'), findsNothing);
    expect(_key('map-story-then'), findsNothing);
    expect(_key('map-story-after'), findsNothing);
    expect(_key('map-story-simulate'), findsNothing);
    expect(_key('map-story-line-loading'), findsNothing);
  });
}

class _Characters extends ScopedTestMapPort {
  _Characters()
    : super(
        metadata: scopedMapMetadata.copyWith(
          characters: const [
            ProjectCharacterEntry(id: 'luth', name: 'Luth', tilesetId: 'first'),
          ],
        ),
        resourceDefinitions: {
          'character': scopedMapMetadata.copyWith(
            characters: const [
              ProjectCharacterEntry(
                id: 'luth',
                name: 'Luth',
                tilesetId: 'first',
              ),
              ProjectCharacterEntry(
                id: 'maman',
                name: 'Maman',
                tilesetId: 'first',
              ),
            ],
          ),
        },
      );

  @override
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    final document = await super.loadMap(session, entry);
    return MapWorkspaceDocument(
      map: document.map.copyWith(
        entities: const [
          MapEntity(
            id: 'luth',
            name: 'Luth',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 0, y: 0),
            npc: MapEntityNpcData(characterId: 'luth'),
          ),
        ],
      ),
      revision: document.revision,
      mapId: document.mapId,
    );
  }
}
