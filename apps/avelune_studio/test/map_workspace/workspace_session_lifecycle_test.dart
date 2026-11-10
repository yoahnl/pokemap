import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_session_loader.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_session_controllers.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_visual_projection_queue.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_workshop_routes.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_workshop.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/features/scenes/domain/scene_port.dart';
import 'package:avelune_studio/features/stories/domain/story_port.dart';
import 'package:avelune_studio/features/events/domain/event_port.dart';
import 'package:avelune_studio/features/dialogues/domain/dialogue_port.dart';
import 'package:avelune_studio/features/cinematics/domain/cinematic_port.dart';
import 'package:avelune_studio/features/presentations/domain/presentation_port.dart';
import 'package:avelune_studio/features/world/domain/world_port.dart';
import 'package:avelune_studio/features/verification/domain/verification_port.dart';
import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

class _Visuals extends WorkspaceTestVisuals
    implements ResourceWorkspaceVisuals {
  final listeners = <VoidCallback>[];
  final catalogs = <String>[];
  final maps = <MapData>[];
  int disposals = 0;
  Completer<void>? gate;
  bool fail = false;

  @override
  void addListener(VoidCallback listener) => listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => listeners.remove(listener);

  @override
  Future<void> dispose() async {
    disposals++;
    await super.dispose();
  }

  @override
  Future<void> updateCatalog(
    ProjectManifest manifest, {
    Set<String> changedRelativePaths = const {},
  }) async {
    catalogs.add(manifest.name);
    await gate?.future;
    if (fail) throw StateError('catalog failure');
  }

  @override
  void setActiveMap(MapData map) => maps.add(map);

  @override
  void setTerrainBrush(ProjectSmartTilePreset? preset) {}

  @override
  Widget atlasPreview(String tilesetId) => const SizedBox();
}

class _Narrative extends Fake implements NarrativePort {}

class _Scenes extends Fake implements ScenePort {}

class _Stories extends Fake implements StoryPort {}

class _Events extends Fake implements EventPort {}

class _Dialogues extends Fake implements DialoguePort {}

class _Cinematics extends Fake implements CinematicPort {}

class _Presentations extends Fake implements PresentationPort {}

class _World extends Fake implements WorldPort {}

class _Verification extends Fake implements VerificationPort {}

void main() {
  late WorkspaceMemoryPort port;
  late MapWorkspaceController controller;

  setUp(() async {
    port = WorkspaceMemoryPort();
    controller = MapWorkspaceController(workspaceSession, port);
    await controller.initialize();
  });
  tearDown(() => controller.dispose());

  test('workshops compose without loading unrelated project data', () async {
    final visuals = _Visuals();
    final loaded = (await loadWorkspaceSession(
      workspace: controller,
      loadVisuals: (_, _) async => visuals,
      narrativePort: _Narrative(),
      isActive: () => true,
      changed: () {},
      onUse: (_) async {},
    ))!;
    final reads = port.reads;
    final catalogs = port.catalogs;
    var flushes = 0;
    final owners = WorkspaceSessionControllers(
      controller: controller,
      changed: () {},
      visualCatalogChanged: (_) {},
      flushEditors: () async {
        flushes++;
        return true;
      },
      scenePort: _Scenes(),
      storyPort: _Stories(),
      eventPort: _Events(),
      dialoguePort: _Dialogues(),
      cinematicPort: _Cinematics(),
      presentationPort: _Presentations(),
      worldPort: _World(),
      verificationPort: _Verification(),
    );

    owners.initializeLoaded(loaded);

    expect(owners.narrative, same(loaded.narrative));
    expect(owners.scenes, isNotNull);
    expect(owners.stories, isNotNull);
    expect(owners.events, isNotNull);
    expect(owners.dialogues, isNotNull);
    expect(owners.cinematics, isNotNull);
    expect(owners.presentations, isNotNull);
    expect(owners.world!.initialized, isFalse);
    expect(await owners.verification!.flushEdits!(), isTrue);
    expect(flushes, 1);
    expect(port.reads, reads);
    expect(port.catalogs, catalogs);
    final first = owners.dispose();
    expect(identical(first, owners.dispose()), isTrue);
    await first;
    expect(visuals.disposals, 1);
    expect(visuals.listeners, isEmpty);
    expect(controller.historyGuard, isNull);
  });

  test(
    'session owns visual listener and history guard through disposal',
    () async {
      final visuals = _Visuals();
      final session = (await loadWorkspaceSession(
        workspace: controller,
        loadVisuals: (_, _) async => visuals,
        narrativePort: _Narrative(),
        isActive: () => true,
        changed: () {},
        onUse: (_) async {},
      ))!;
      expect(visuals.listeners, hasLength(1));
      expect(controller.historyGuard, isNotNull);
      final first = session.dispose();
      final second = session.dispose();
      expect(identical(first, second), isTrue);
      await first;
      expect(visuals.listeners, isEmpty);
      expect(visuals.disposals, 1);
      expect(controller.historyGuard, isNull);
    },
  );

  test('an older session does not erase a newer history owner', () async {
    final session = (await loadWorkspaceSession(
      workspace: controller,
      loadVisuals: (_, _) async => _Visuals(),
      narrativePort: _Narrative(),
      isActive: () => true,
      changed: () {},
      onUse: (_) async {},
    ))!;
    String? newerGuard(MapData before, MapData after) => 'new owner';
    controller.historyGuard = newerGuard;

    await session.dispose();

    expect(controller.historyGuard, same(newerGuard));
  });

  test(
    'late visual load releases its resources without publishing a session',
    () async {
      final loaded = Completer<void>();
      final ready = Completer<MapWorkspaceVisuals>();
      final visuals = _Visuals();
      var active = true;
      final pending = loadWorkspaceSession(
        workspace: controller,
        loadVisuals: (_, _) {
          loaded.complete();
          return ready.future;
        },
        isActive: () => active,
        changed: () {},
        onUse: (_) async {},
      );
      await loaded.future;
      active = false;
      ready.complete(visuals);

      expect(await pending, isNull);
      expect(visuals.disposals, 1);
      expect(visuals.listeners, isEmpty);
      expect(controller.historyGuard, isNull);
    },
  );

  test(
    'visual queue serializes updates and publishes only the newest map',
    () async {
      final visuals = _Visuals()..gate = Completer<void>();
      final prepared = <MapData?>[];
      final failures = <Object>[];
      var map = workspaceMap('a');
      final queue = WorkspaceVisualProjectionQueue(
        currentVisuals: () => visuals,
        activeMap: () => map,
        isActive: () => true,
        prepared: prepared.add,
        failed: failures.add,
        changed: () {},
      );
      final first = queue.refresh(workspaceProject.copyWith(name: 'first'));
      await Future<void>.delayed(Duration.zero);
      final second = queue.refresh(workspaceProject.copyWith(name: 'second'));
      map = workspaceMap('b');
      visuals.gate!.complete();
      await Future.wait([first, second]);

      expect(visuals.catalogs, ['first', 'second']);
      expect(visuals.maps, [map]);
      expect(prepared, [map]);
      expect(failures, isEmpty);
      expect(queue.loading, isFalse);
    },
  );

  test('a catalog failure keeps the queue usable for retry', () async {
    final visuals = _Visuals()..fail = true;
    final failures = <Object>[];
    final queue = WorkspaceVisualProjectionQueue(
      currentVisuals: () => visuals,
      activeMap: () => controller.active!.current,
      isActive: () => true,
      prepared: (_) {},
      failed: failures.add,
      changed: () {},
    );

    await queue.refresh(workspaceProject);
    expect(failures, hasLength(1));
    expect(visuals.maps, isEmpty);
    visuals.fail = false;
    await queue.refresh(workspaceProject);

    expect(visuals.maps, hasLength(1));
    expect(queue.loading, isFalse);
  });

  test(
    'a navigation request invalidates a workshop still loading dependencies',
    () async {
      final ready = Completer<void>();
      final waiting = Completer<void>();
      var opened = 0;
      var prepared = 0;
      final routes = WorkspaceWorkshopRoutes(
        controller: controller,
        isActive: () => true,
        failed: (_) {},
        changed: () {},
      );
      final pending = routes.open(
        MapWorkspaceWorkshop.resources,
        opened: () => opened++,
        prepare: () => prepared++,
        loadDependencies: () {
          waiting.complete();
          return ready.future;
        },
      );
      await waiting.future;
      routes.request++;
      routes.loading = false;
      ready.complete();
      await pending;

      expect(opened, 0);
      expect(prepared, 0);
      expect(port.catalogs, 1);
      expect(routes.loading, isFalse);
    },
  );
}
