import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/events/domain/event_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/scenes/domain/scene_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_layout.dart';
import 'package:avelune_studio/presentation/features/events/event_workspace_page.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/map_workspace/workspace_resource_diagnostic.dart';
import 'package:avelune_studio/presentation/features/narrative/narrative_story_pane.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_builder_page.dart';
import 'package:avelune_studio/presentation/shell/studio_home_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/scoped_map_workspace_port.dart';

const _routedEventId = 'evt_019abcde-9000-7000-8000-000000000106';

void main() {
  testWidgets('map event route loads its registry before resolving the source', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1500, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final port = _RoutedPort();
    final maps = MapWorkspaceController(scopedMapSession, port);
    addTearDown(maps.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MapWorkspaceScreen(
          controller: maps,
          loadVisuals: (_, _) async => _Visuals(),
          narrativePort: _NarrativePort(),
          eventPort: _EventPort(),
          runtimeBuilder: (_, _, _) => const SizedBox(),
          onClose: () async {},
          registerExitGuard: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(maps.project!.eventRegistry, isNull);
    tester
        .widget<MapWorkspaceLayout>(find.byType(MapWorkspaceLayout))
        .onEditInteraction!(
      const MapEntity(
        id: 'guide',
        name: 'Guide',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 0, y: 0),
      ),
    );
    await tester.pumpAndSettle();
    expect(port.workshops, [MapWorkspaceWorkshop.events]);
    expect(maps.project!.eventRegistry?.records.single.id, _routedEventId);
    expect(find.text('Événements de cette source'), findsOneWidget);
    expect(find.text('Rencontre du guide'), findsOneWidget);
    expect(
      find.text(
        'Aucun événement. Créez explicitement un brouillon pour cette source.',
      ),
      findsNothing,
    );
    await tester.tap(find.text('Rencontre du guide'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<EventWorkspacePage>(find.byType(EventWorkspacePage))
          .controller
          .active
          ?.id,
      _routedEventId,
    );
    expect(port.fullReads, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'scoped workshops retain owners and drafts without materializing',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1500, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final port = ScopedTestMapPort();
      final maps = MapWorkspaceController(scopedMapSession, port);
      final home = StudioHomeNavigation();
      final visuals = _Visuals();
      var visualLoads = 0;
      addTearDown(maps.dispose);
      addTearDown(home.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: MapWorkspaceScreen(
            controller: maps,
            home: home,
            loadVisuals: (_, _) async {
              visualLoads++;
              return visuals;
            },
            narrativePort: _NarrativePort(),
            scenePort: _ScenePort(),
            runtimeBuilder: (_, _, _) => const SizedBox(),
            onClose: () async {},
            registerExitGuard: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final mapDraft = maps.active!;
      mapDraft.commit(mapDraft.current.copyWith(name: 'Carte en préparation'));
      home.navigate('story');
      await tester.pumpAndSettle();
      expect(find.text('Charger tous les ateliers du projet ?'), findsNothing);
      expect(find.byType(NarrativeStoryPane), findsOneWidget);
      final first = tester.widget<NarrativeStoryPane>(
        find.byType(NarrativeStoryPane),
      );
      final sceneOwner = first.sceneOwner!;
      final draft = sceneOwner.create('Scène en préparation')!;
      draft.mutate(
        (scene) => SceneAsset.fromJson({
          ...scene.toJson(),
          'name': 'Brouillon conservé',
        }),
      );
      first.onScenes!();
      await tester.pumpAndSettle();
      expect(find.byType(SceneBuilderPage), findsOneWidget);
      expect(
        tester
            .widget<SceneBuilderPage>(find.byType(SceneBuilderPage))
            .controller,
        same(sceneOwner),
      );
      home.navigate('map');
      await tester.pumpAndSettle();
      await maps.activate(secondScopedMap);
      await tester.pumpAndSettle();
      home.navigate('story');
      await tester.pumpAndSettle();
      final reopened = tester.widget<NarrativeStoryPane>(
        find.byType(NarrativeStoryPane),
      );
      expect(reopened.controller, same(first.controller));
      expect(reopened.sceneOwner, same(sceneOwner));
      expect(sceneOwner.active, same(draft));
      expect(draft.current.name, 'Brouillon conservé');
      expect(draft.canUndo, isTrue);
      expect(maps.documents[firstScopedMap.id], same(mapDraft));
      expect(mapDraft.current.name, 'Carte en préparation');
      expect(mapDraft.dirty, isTrue);
      expect(port.fullReads, 0);
      expect(port.workshops, [
        MapWorkspaceWorkshop.story,
        MapWorkspaceWorkshop.scene,
      ]);
      expect(visualLoads, 1);
      expect(visuals.disposed, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      expect(visuals.disposed, isTrue);
    },
  );
  testWidgets('a delayed workshop cannot replace a newer navigation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1500, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final port = _DelayedPort();
    final maps = MapWorkspaceController(scopedMapSession, port);
    final home = StudioHomeNavigation();
    addTearDown(maps.dispose);
    addTearDown(home.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MapWorkspaceScreen(
          controller: maps,
          home: home,
          loadVisuals: (_, _) async => _Visuals(),
          narrativePort: _NarrativePort(),
          runtimeBuilder: (_, _, _) => const SizedBox(),
          onClose: () async {},
          registerExitGuard: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    home.navigate('story');
    await tester.pump();
    expect(port.workshops, [MapWorkspaceWorkshop.story]);
    home.navigate('map');
    await tester.pump();
    port.ready.complete();
    await tester.pumpAndSettle();
    expect(find.byType(NarrativeStoryPane), findsNothing);
    expect(find.text('Carte first'), findsWidgets);
    expect(port.fullReads, 0);
    home.navigate('story');
    await tester.pumpAndSettle();
    expect(find.byType(NarrativeStoryPane), findsOneWidget);
    expect(port.workshops, [MapWorkspaceWorkshop.story]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}

class _DelayedPort extends ScopedTestMapPort {
  final ready = Completer<void>();

  @override
  Future<MapWorkspaceCatalog> loadWorkshop(
    ProjectSession session,
    MapWorkspaceWorkshop workshop,
  ) async {
    workshops.add(workshop);
    await ready.future;
    return MapWorkspaceCatalog(metadata: metadata, revision: 'catalog-1');
  }
}

class _RoutedPort extends ScopedTestMapPort {
  @override
  Future<MapWorkspaceCatalog> loadWorkshop(
    ProjectSession session,
    MapWorkspaceWorkshop workshop,
  ) async {
    workshops.add(workshop);
    return MapWorkspaceCatalog(
      revision: 'catalog-1',
      metadata: metadata.copyWith(
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.legacyOnly,
          legacyClaims: const [],
          records: [
            NarrativeEventRecord.draft(
              NarrativeEventDraft(
                id: _routedEventId,
                name: 'Rencontre du guide',
                conditions: const [],
                priority: 0,
                order: 0,
                source: NarrativeEventSourceRef.entityInteract(
                  'first',
                  'guide',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventPort implements EventPort {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Navigation must not publish events.');
}

class _NarrativePort implements NarrativePort {
  @override
  Future<NarrativeDialogueSource> readDialogue(ProjectDialogueEntry entry) =>
      throw StateError('Opening a workshop must not read dialogue sources.');

  @override
  Future<NarrativePublicationReceipt> publish(
    NarrativePublication publication,
  ) => throw StateError('Navigation must not publish drafts.');
}

class _ScenePort implements ScenePort {
  @override
  Future<ScenePublicationReceipt> publishScene({
    required SceneAsset? base,
    required SceneAsset current,
  }) => throw StateError('Navigation must not publish drafts.');
}

class _Visuals extends ChangeNotifier
    implements MapWorkspaceVisuals, ResourceWorkspaceVisuals {
  bool disposed = false;

  @override
  Future<void> updateCatalog(
    ProjectManifest manifest, {
    Set<String> changedRelativePaths = const {},
  }) async {}

  @override
  Widget canvas(
    MapData map, {
    MapPlacedElement? placedElementPreview,
    Color? collisionColor,
  }) => Text('Carte ${map.id}');

  @override
  List<WorkspaceResourceDiagnostic> get diagnostics => const [];
  @override
  Set<String> get activeResourceIds => const {};
  @override
  List<String> get warnings => const [];
  @override
  void setActiveMap(MapData map) {}
  @override
  void setBrush(ProjectElementEntry? element, TileLayerPaletteEntry? tile) {}
  @override
  void setTerrainBrush(ProjectSmartTilePreset? preset) {}
  @override
  Future<void> retryResources(Iterable<String> resourceIds) async {}
  @override
  Widget thumbnail(ProjectElementEntry element, {double size = 48}) =>
      const SizedBox();
  @override
  Widget placementPreview(ProjectElementEntry element, Size size) =>
      const SizedBox();
  @override
  Widget tileThumbnail(TileLayerPaletteEntry tile, {double size = 48}) =>
      const SizedBox();
  @override
  Widget atlasPreview(String tilesetId) => const SizedBox();
  @override
  Future<void> dispose() async {
    disposed = true;
    super.dispose();
  }
}
