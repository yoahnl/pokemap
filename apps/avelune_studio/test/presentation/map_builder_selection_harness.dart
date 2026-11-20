import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/app/di/game_export_providers.dart';
import 'package:avelune_studio/features/game_export/domain/studio_game_export_port.dart';
import 'package:avelune_studio/app/di/map_workspace_providers.dart';
import 'package:avelune_studio/app/di/project_session_providers.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_catalog_port.dart';
import 'package:avelune_studio/presentation/shell/studio_root.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../map_workspace/spatial_shared_commands_support.dart';
import '../support/controlled_project_session_port.dart';
import '../support/map_workspace_fixture.dart';
import '../support/spatial_environment_fixture.dart';

ProjectManifest selectionProject() {
  final project = spatialEnvironmentProject();
  final oak = project.models3d.single;
  return project.copyWith(
    models3d: [
      oak,
      ProjectModel3dEntry(
        id: 'windmill',
        name: 'Moulin animé',
        sourceAssetId: 'windmill-source',
        relativePath: 'assets/models3d/windmill.glb',
        inspection: Model3dInspection(
          bounds: oak.inspection.bounds,
          meshCount: 1,
          triangleCount: 4,
          animations: [
            Model3dAnimation(index: 0, name: 'Tourne', durationSeconds: 2),
          ],
        ),
      ),
    ],
  );
}

MapData selectionMap(String id) {
  final map = spatialEnvironmentMap();
  return map.copyWith(
    id: id,
    spatialScene: map.spatialScene!.copyWith(
      instances: [
        if (id == 'a') ...[
          SpatialModelInstance(
            id: 'oak_1',
            modelId: 'oak',
            position: Model3dVector3(x: 2.5, y: 0, z: 2.5),
          ),
          SpatialModelInstance(
            id: 'oak_2',
            modelId: 'oak',
            position: Model3dVector3(x: 4.5, y: 0, z: 2.5),
          ),
          SpatialModelInstance(
            id: 'mill',
            modelId: 'windmill',
            position: Model3dVector3(x: 8.5, y: 0, z: 2.5),
          ),
        ],
      ],
    ),
  );
}

class SelectionHost {
  SelectionHost(this.tester, this.container, this.port);
  final WidgetTester tester;
  final ProviderContainer container;
  final WorkspaceMemoryPort port;

  MapWorkspaceController get maps =>
      container.read(mapWorkspaceControllerProvider(exampleA));

  List<SpatialModelInstance> get instances =>
      maps.active!.current.spatialScene!.instances;

  SpatialSceneView get scene => tester.widget(find.byType(SpatialSceneView));

  Future<void> settle() async {
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  Future<void> click(String id, {bool shift = false}) async {
    final instance = instances.firstWhere((item) => item.id == id);
    if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    scene.onContent!(
      SpatialSceneContentHit(
        kind: SpatialSceneContentKind.model,
        id: id,
        cell: (instance.position.x.floor(), instance.position.z.floor()),
      ),
    );
    if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await settle();
  }

  Future<void> rightClick(int x, int z) async {
    scene.onContextMenu!(GridPos(x: x, y: z), const Offset(700, 400));
    await settle();
  }
}

Future<SelectionHost> openSelectionHost(
  WidgetTester tester, {
  MapCatalogPort? catalog,
  ProjectManifest? manifest,
  WorkspaceMemoryPort? workspace,
  StudioGameExportPort? exportPort,
  PickGameExportFile? exportPicker,
}) async {
  tester.view.physicalSize = const Size(1920, 1080);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final sessions = ControlledProjectSessionPort();
  final port =
      (workspace ??
            WorkspaceMemoryPort(manifest: manifest ?? selectionProject()))
        ..saved['a'] = selectionMap('a')
        ..saved['b'] = selectionMap('b');
  final container = ProviderContainer(
    overrides: [
      if (exportPort != null)
        gameExportPortProvider(exampleA).overrideWithValue(exportPort),
      if (exportPicker != null)
        gameExportPickerProvider.overrideWithValue(exportPicker),
      projectSessionPortProvider.overrideWithValue(sessions),
      projectDirectoryPickerProvider.overrideWithValue(
        () async => exampleA.directoryPath,
      ),
      mapWorkspacePortProvider(exampleA).overrideWithValue(port),
      if (catalog != null)
        mapCatalogPortProvider(exampleA).overrideWithValue(catalog),
      workspaceVisualsLoaderProvider.overrideWithValue(
        (session, manifest) async => SpatialTestVisuals(),
      ),
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
  sessions.pending.single.complete(exampleA);
  final host = SelectionHost(tester, container, port);
  await host.settle();
  return host;
}
