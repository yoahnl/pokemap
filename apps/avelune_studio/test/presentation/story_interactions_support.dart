import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/app/di/map_workspace_providers.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import 'story_memory_harness.dart';

const motherTalk = 'evt_00000000-0000-7000-8000-000000000002';
const emptyMap = ProjectMapEntry(
  id: 'empty',
  name: 'Carte vide',
  relativePath: 'empty.json',
);

NarrativeEventRecord interactionRecord(
  String id,
  String mapId,
  String source,
  String name,
) => NarrativeEventRecord.draft(
  NarrativeEventDraft(
    id: id,
    name: name,
    source: NarrativeEventSourceRef.entityInteract(mapId, source),
    conditions: const [],
    priority: 0,
    order: 0,
  ),
);

MapBuilderStoryBinding interactionBinding(WidgetTester tester) => tester
    .widget<MapBuilderStoryPanel>(
      find.byType(MapBuilderStoryPanel, skipOffstage: false),
    )
    .binding;

MapWorkspaceController interactionMaps(WidgetTester tester) =>
    ProviderScope.containerOf(
      tester.element(find.byKey(const ValueKey('map-builder'))),
    ).read(mapWorkspaceControllerProvider(memorySession));

Finder interactionKey(String key) => find.byKey(ValueKey(key));

Future<void> openInteractions(WidgetTester tester) async {
  final project = memoryProject.copyWith(
    maps: [...workspaceEntries, emptyMap],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: [
        interactionRecord(guideTalk, 'a', 'guide', 'Parler au guide'),
        interactionRecord(motherTalk, 'b', 'mother', 'Parler à Maman'),
      ],
      legacyClaims: const [],
    ),
  );
  final index = memoryIndex();
  index.titlesByKind[NarrativeTitleKind.events] = const [
    NarrativeTitle(id: guideTalk, title: 'Parler au guide'),
    NarrativeTitle(id: motherTalk, title: 'Parler à Maman'),
  ];
  await openMemoryStudio(
    tester,
    index,
    project: project,
    world: MapOnlyWorld.new,
    initialMaps: {
      'b': workspaceMap('b').copyWith(
        entities: const [
          MapEntity(
            id: 'mother',
            name: 'Maman',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 4, y: 4),
            npc: MapEntityNpcData(displayName: 'Maman'),
          ),
        ],
      ),
    },
  );
  await tester.tap(interactionKey('map-space-story'));
  await settleMemory(tester);
}

Future<void> selectInteraction(WidgetTester tester, String source) async {
  await tester.tap(interactionKey('map-story-element-entity:$source'));
  await settleMemory(tester);
  await tester.tap(find.text('Déclencheurs'));
  await settleMemory(tester);
}

Future<void> openInteractionRule(WidgetTester tester) async {
  await selectInteraction(tester, 'guide');
  await tester.tap(interactionKey('map-interaction-trigger-open-$guideTalk'));
  await settleMemory(tester);
}

StudioSelect interactionFilter(WidgetTester tester) =>
    tester.widget<StudioSelect>(interactionKey('behaviours-map-filter'));

Future<void> filterInteractions(WidgetTester tester, String mapId) async {
  interactionFilter(tester).onChanged!(mapId);
  await settleMemory(tester);
}
