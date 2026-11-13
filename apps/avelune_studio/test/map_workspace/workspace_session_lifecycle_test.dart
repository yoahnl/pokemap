import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_session_loader.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_visual_projection_queue.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_workshop_routes.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_workshop.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
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

void main() {
  late WorkspaceMemoryPort port;
  late MapWorkspaceController controller;

  setUp(() async {
    port = WorkspaceMemoryPort();
    controller = MapWorkspaceController(workspaceSession, port);
    await controller.initialize();
  });
  tearDown(() => controller.dispose());

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
