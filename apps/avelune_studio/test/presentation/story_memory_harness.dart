import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/app/di/game_memory_providers.dart';
import 'package:avelune_studio/app/di/map_workspace_providers.dart';
import 'package:avelune_studio/app/di/presentation_providers.dart';
import 'package:avelune_studio/app/di/project_session_providers.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/storyline/domain/storyline_read_port.dart';
import 'package:avelune_studio/features/world/domain/world_port.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/presentation/shell/studio_root.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../game_memory/game_memory_fakes.dart';
import '../support/controlled_project_session_port.dart';
import '../support/map_workspace_fixture.dart';

const guideTalk = 'evt_00000000-0000-7000-8000-000000000001';

final memorySession = ProjectSession(
  sessionId: exampleA.sessionId,
  name: exampleA.name,
  directoryPath: exampleA.directoryPath,
  storage: ProjectSessionStorage.workingCatalog,
);

final memoryProject = workspaceProject.copyWith(
  eventRegistry: NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: [
      NarrativeEventRecord.draft(
        NarrativeEventDraft(
          id: guideTalk,
          name: 'Parler au guide',
          source: NarrativeEventSourceRef.entityInteract('a', 'guide'),
          conditions: const [],
          priority: 0,
          order: 0,
        ),
      ),
    ],
    legacyClaims: const [],
  ),
);

final doorRule = WorldRuleDefinition(
  id: 'world_rule_door',
  label: 'Porte du bourg',
  source: const WorldRuleSource(
    kind: WorldRuleSourceKind.fact,
    sourceId: 'met',
    predicate: WorldRuleSourcePredicate.isTrue,
  ),
  target: const WorldRuleTarget(
    kind: WorldRuleTargetKind.mapEntity,
    mapId: 'a',
    entityId: 'guide',
    label: 'Guide',
  ),
  effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden),
);

FakeNarrativeIndex memoryIndex({int unrelated = 0}) {
  final index = FakeNarrativeIndex()
    ..addFacts([
      memoryFact('met', 'Rencontre'),
      memoryFact('coins', 'Pièces', value: NarrativeValue.integer(3)),
      for (var i = 0; i < unrelated; i++) memoryFact('unused_$i', 'Inutile $i'),
    ])
    ..rules = [doorRule];
  index.titlesByKind[NarrativeTitleKind.scenes] = const [
    NarrativeTitle(id: 'gate', title: 'Ouverture de la porte'),
  ];
  index.titlesByKind[NarrativeTitleKind.worldRules] = const [
    NarrativeTitle(id: 'world_rule_door', title: 'Porte du bourg'),
  ];
  index.titlesByKind[NarrativeTitleKind.events] = const [
    NarrativeTitle(id: guideTalk, title: 'Parler au guide'),
  ];
  index.users['met'] = NarrativeUsages(
    owners: const [
      NarrativeOwner(
        kind: NarrativeOwnerKind.scene,
        id: 'gate',
        role: NarrativeFactRole.write,
      ),
      NarrativeOwner(
        kind: NarrativeOwnerKind.worldRule,
        id: 'world_rule_door',
        role: NarrativeFactRole.read,
      ),
      NarrativeOwner(
        kind: NarrativeOwnerKind.event,
        id: guideTalk,
        role: NarrativeFactRole.read,
      ),
      NarrativeOwner(
        kind: NarrativeOwnerKind.storyline,
        id: 'main',
        role: NarrativeFactRole.read,
      ),
    ],
    notCovered: const ['maps', 'dialogueDefinitions'],
  );
  return index;
}

Future<void> settleMemory(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<WorkspaceMemoryPort> openMemoryStudio(
  WidgetTester tester,
  FakeNarrativeIndex index, {
  WorldPort Function(WorkspaceMemoryPort maps)? world,
  ProjectSession? session,
  ProjectManifest? project,
  StorylineReadPort? storylines,
}) async {
  final opened = session ?? memorySession;
  tester.view.physicalSize = const Size(1920, 1080);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final sessions = ControlledProjectSessionPort();
  final maps = WorkspaceMemoryPort(manifest: project ?? memoryProject);
  maps.saved['a'] = workspaceMap('a').copyWith(
    entities: const [
      MapEntity(
        id: 'guide',
        name: 'Guide',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 2, y: 2),
        npc: MapEntityNpcData(displayName: 'Guide'),
      ),
    ],
  );
  final container = ProviderContainer(
    overrides: [
      projectSessionPortProvider.overrideWithValue(sessions),
      projectDirectoryPickerProvider.overrideWithValue(
        () async => exampleA.directoryPath,
      ),
      mapWorkspacePortProvider(opened).overrideWithValue(maps),
      workspaceVisualsLoaderProvider.overrideWithValue(
        (session, manifest) async => WorkspaceTestVisuals(),
      ),
      narrativeIndexPortProvider(opened).overrideWithValue(index),
      if (storylines != null)
        storylineReadPortProvider(opened).overrideWithValue(storylines),
      if (world != null)
        worldPortProvider(opened).overrideWithValue(world(maps)),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: studioTheme(), home: const StudioRoot()),
    ),
  );
  await tester.tap(find.byKey(const ValueKey('studio-home-import')));
  await tester.pump();
  sessions.pending.single.complete(opened);
  await settleMemory(tester);
  return maps;
}

Future<void> openTrame(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('studio-rail-story')));
  await settleMemory(tester);
}

Future<void> openWholeGame(WidgetTester tester) async {
  await openTrame(tester);
  await tester.tap(find.byKey(const ValueKey('story-tab-world')));
  await settleMemory(tester);
}

Future<void> openHistoire(WidgetTester tester) async {
  await openWholeGame(tester);
  await tester.tap(find.byKey(const ValueKey('story-tab-memory')));
  await settleMemory(tester);
}

final class MapOnlyWorld implements WorldPort, WorldMapSelectionPort {
  MapOnlyWorld(this.maps);

  final WorkspaceMemoryPort maps;
  final loaded = <String>[];

  @override
  Future<MapData> loadMap(ProjectMapEntry entry) async {
    loaded.add(entry.id);
    return maps.saved[entry.id] ?? workspaceMap(entry.id);
  }

  @override
  Future<ResourceMutationReceipt> publishFact({
    required NarrativeFactDefinition? base,
    required NarrativeFactDefinition current,
  }) => throw UnimplementedError();

  @override
  Future<ResourceMutationReceipt> deleteFact(NarrativeFactDefinition base) =>
      throw UnimplementedError();

  @override
  Future<ResourceMutationReceipt> publishRule({
    required WorldRuleDefinition? base,
    required WorldRuleDefinition current,
  }) => throw UnimplementedError();

  @override
  Future<ResourceMutationReceipt> publishRuleBatch({
    required List<({WorldRuleDefinition? base, WorldRuleDefinition current})>
    rules,
  }) => throw UnimplementedError();

  @override
  Future<ResourceMutationReceipt> deleteRule(WorldRuleDefinition base) =>
      throw UnimplementedError();

  @override
  Future<List<MapData>> loadMaps() => throw UnimplementedError();
}
