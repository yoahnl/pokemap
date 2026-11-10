import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/events/domain/event_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/workspace_navigation.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_navigation_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_session_controllers.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_session_loader.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_workshop_routes.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/scenes/domain/scene_port.dart';
import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/platform/rendering/contracts/workspace_resource_diagnostic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/scoped_map_workspace_port.dart';

const _routedEventId = 'evt_019abcde-9000-7000-8000-000000000106';

void main() {
  test('map event route loads its registry before resolving the source', () async {
    final port = _RoutedPort();
    final maps = MapWorkspaceController(scopedMapSession, port);
    addTearDown(maps.dispose);
    final loaded = await loadWorkspaceSession(
      workspace: maps,
      loadVisuals: (_, _) async => _Visuals(),
      narrativePort: _NarrativePort(),
      isActive: () => true,
      changed: () {},
      onUse: (_) async {},
    );
    final owners = WorkspaceSessionControllers(
      controller: maps,
      changed: () {},
      visualCatalogChanged: (_) {},
      flushEditors: () async => true,
      eventPort: _EventPort(),
    );
    owners.initializeLoaded(loaded!);
    addTearDown(owners.dispose);
    final routes = WorkspaceWorkshopRoutes(
      controller: maps,
      isActive: () => true,
      failed: (error) { if (error != null) throw error; },
      changed: () {},
    );
    final opened = Completer<void>();
    late final WorkspaceNavigationSession navigation;
    navigation = WorkspaceNavigationSession(
      controller: maps,
      isActive: () => true,
      changed: () {
        if (navigation.space == WorkspaceSpace.events && !opened.isCompleted) {
          opened.complete();
        }
      },
      events: () => owners.events,
      narrative: () => owners.narrative,
      prepareWorkshop: routes.prepare,
      navigationRequest: () => routes.request,
      nextNavigationRequest: () => ++routes.request,
    );
    expect(maps.project!.eventRegistry, isNull);
    await navigation.openEventSource(
      NarrativeEventSourceRef.entityInteract('first', 'guide'),
      choose: (matches) async {
        expect(port.workshops, [MapWorkspaceWorkshop.events]);
        expect(matches.map((record) => record.id), [_routedEventId]);
        expect(maps.project!.eventRegistry!.records.single.id, _routedEventId);
        return matches.single.id;
      },
      askName: () async => throw StateError('Existing source needs no creation'),
    );
    await opened.future.timeout(const Duration(seconds: 5));
    expect(owners.events!.active!.id, _routedEventId);
    expect(port.fullReads, 0);
  });

  test('scoped workshops retain owners and drafts without materializing', () async {
    final port = ScopedTestMapPort();
    final maps = MapWorkspaceController(scopedMapSession, port);
    addTearDown(maps.dispose);
    final visuals = _Visuals();
    var visualLoads = 0;
    final loaded = await loadWorkspaceSession(
      workspace: maps,
      loadVisuals: (_, _) async { visualLoads++; return visuals; },
      narrativePort: _NarrativePort(),
      isActive: () => true,
      changed: () {},
      onUse: (_) async {},
    );
    final owners = WorkspaceSessionControllers(
      controller: maps,
      changed: () {},
      visualCatalogChanged: (_) {},
      flushEditors: () async => true,
      scenePort: _ScenePort(),
    );
    owners.initializeLoaded(loaded!);
    addTearDown(owners.dispose);
    final routes = WorkspaceWorkshopRoutes(
      controller: maps,
      isActive: () => true,
      failed: (error) { if (error != null) throw error; },
      changed: () {},
    );
    final mapDraft = maps.active!;
    mapDraft.commit(mapDraft.current.copyWith(name: 'Carte en préparation'));
    final narrative = owners.narrative;
    final sceneOwner = owners.scenes!;
    await routes.open(MapWorkspaceWorkshop.story, opened: () {});
    final draft = sceneOwner.create('Scène en préparation')!;
    draft.mutate((scene) => SceneAsset.fromJson({
      ...scene.toJson(), 'name': 'Brouillon conservé',
    }));
    await routes.open(MapWorkspaceWorkshop.scene, opened: () {});
    await maps.activate(secondScopedMap);
    await routes.open(MapWorkspaceWorkshop.story, opened: () {});
    expect(owners.narrative, same(narrative));
    expect(owners.scenes, same(sceneOwner));
    expect(sceneOwner.active, same(draft));
    expect(draft.current.name, 'Brouillon conservé');
    expect(draft.canUndo, isTrue);
    expect(maps.documents[firstScopedMap.id], same(mapDraft));
    expect(mapDraft.current.name, 'Carte en préparation');
    expect(mapDraft.dirty, isTrue);
    expect(port.fullReads, 0);
    expect(port.workshops, [MapWorkspaceWorkshop.story, MapWorkspaceWorkshop.scene]);
    expect(visualLoads, 1);
    expect(visuals.disposed, isFalse);
    await owners.dispose();
    expect(visuals.disposed, isTrue);
  });

  test('a delayed workshop cannot replace a newer navigation', () async {
    final port = _DelayedPort();
    final maps = MapWorkspaceController(scopedMapSession, port);
    addTearDown(maps.dispose);
    await maps.initialize();
    final routes = WorkspaceWorkshopRoutes(
      controller: maps,
      isActive: () => true,
      failed: (error) { if (error != null) throw error; },
      changed: () {},
    );
    var destination = WorkspaceSpace.map;
    final pending = routes.open(
      MapWorkspaceWorkshop.story,
      opened: () => destination = WorkspaceSpace.story,
    );
    expect(port.workshops, [MapWorkspaceWorkshop.story]);
    routes.request++;
    destination = WorkspaceSpace.map;
    port.ready.complete();
    await pending;
    expect(destination, WorkspaceSpace.map);
    expect(port.fullReads, 0);
    await routes.open(
      MapWorkspaceWorkshop.story,
      opened: () => destination = WorkspaceSpace.story,
    );
    expect(destination, WorkspaceSpace.story);
    expect(port.workshops, [MapWorkspaceWorkshop.story]);
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
