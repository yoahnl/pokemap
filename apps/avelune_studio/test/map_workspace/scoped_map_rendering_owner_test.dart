import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_session_loader.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_visual_projection_queue.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_workshop_routes.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import '../support/scoped_map_workspace_port.dart';

class _ScopedVisuals extends WorkspaceTestVisuals
    implements ResourceWorkspaceVisuals {
  _ScopedVisuals(this.contexts);

  final List<List<String>> contexts;
  final activeMaps = <String>[];
  Completer<void>? nextUpdate;

  @override
  Future<void> updateCatalog(
    ProjectManifest manifest, {
    Set<String> changedRelativePaths = const {},
  }) async {
    final delayed = nextUpdate;
    nextUpdate = null;
    await delayed?.future;
    contexts.add(manifest.tilesets.map((entry) => entry.id).toList());
  }

  @override
  void setActiveMap(MapData map) => activeMaps.add(map.id);

  @override
  void setTerrainBrush(ProjectSmartTilePreset? preset) {}

  @override
  Widget atlasPreview(String tilesetId) => const SizedBox();
}

class _GatedWorkshopPort extends ScopedTestMapPort {
  Completer<void>? workshopGate;

  @override
  Future<MapWorkspaceCatalog> loadWorkshop(
    ProjectSession session,
    MapWorkspaceWorkshop workshop,
  ) async {
    await workshopGate?.future;
    return super.loadWorkshop(session, workshop);
  }
}

Future<void> _settle(WorkspaceVisualProjectionQueue projection) async {
  for (var turn = 0; turn < 20; turn++) {
    await projection.queue;
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('map rendering stays scoped without a global workshop banner', () async {
    final port = _GatedWorkshopPort();
    final controller = MapWorkspaceController(scopedMapSession, port);
    addTearDown(controller.dispose);
    final contexts = <List<String>>[];
    final loadedVisuals = <_ScopedVisuals>[];
    final failures = <Object>[];
    final session = (await loadWorkspaceSession(
      workspace: controller,
      loadVisuals: (_, project) async {
        contexts.add(project.tilesets.map((entry) => entry.id).toList());
        final visuals = _ScopedVisuals(contexts);
        loadedVisuals.add(visuals);
        return visuals;
      },
      isActive: () => true,
      changed: () {},
      onUse: (_) async {},
    ))!;
    addTearDown(session.dispose);
    late final WorkspaceVisualProjectionQueue projection;
    late final WorkspaceWorkshopRoutes workshops;
    void follow() => projection.follow(controller, workshops);
    workshops = WorkspaceWorkshopRoutes(
      controller: controller,
      isActive: () => true,
      failed: (failure) {
        if (failure != null) failures.add(failure);
      },
      changed: follow,
    );
    projection = WorkspaceVisualProjectionQueue(
      currentVisuals: () => session.visuals,
      activeMap: () => controller.active?.current,
      isActive: () => true,
      prepared: (_) {},
      failed: failures.add,
      changed: () {},
    )..acknowledgeDefinitions(controller.visualProject);
    controller.addListener(follow);
    addTearDown(() => controller.removeListener(follow));

    expect(port.fullReads, 0);
    expect(contexts.single, ['first']);
    expect(loadedVisuals, hasLength(1));
    final visuals = loadedVisuals.single;

    final delayed = Completer<void>();
    visuals.nextUpdate = delayed;
    await controller.activate(secondScopedMap);
    await controller.activate(firstScopedMap);
    delayed.complete();
    await _settle(projection);
    expect(contexts.last, ['first']);
    expect(visuals.activeMaps.last, 'first');

    await controller.activate(secondScopedMap);
    await _settle(projection);
    expect(contexts.last, ['second']);
    expect(visuals.activeMaps.last, 'second');
    final projected = contexts.length;

    var opened = 0;
    final gate = Completer<void>();
    port.workshopGate = gate;
    final opening = workshops.open(
      MapWorkspaceWorkshop.pokemon,
      opened: () => opened++,
    );
    await _settle(projection);
    expect(workshops.loading, isTrue);
    expect(contexts, hasLength(projected));
    await controller.activate(firstScopedMap);
    await _settle(projection);
    expect(contexts, hasLength(projected));
    gate.complete();
    await opening;
    await _settle(projection);
    expect(opened, 1);
    expect(contexts.last, ['first']);
    await controller.activate(secondScopedMap);
    await _settle(projection);

    expect(port.workshops, [MapWorkspaceWorkshop.pokemon]);
    expect(port.fullReads, 0);
    expect(controller.hasCompleteProject, isFalse);
    expect(contexts.last, ['second']);
    expect(loadedVisuals, hasLength(1));
    expect(visuals.disposed, isFalse);
    expect(controller.active?.base.mapId, 'second');
    expect(failures, isEmpty);
    expect(projection.loading, isFalse);
  });
}
