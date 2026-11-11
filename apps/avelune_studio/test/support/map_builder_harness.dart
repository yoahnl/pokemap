import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/app/di/map_workspace_providers.dart';
import 'package:avelune_studio/app/di/project_session_providers.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/presentation/shell/studio_root.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'controlled_project_session_port.dart';
import 'map_workspace_fixture.dart';

class MapBuilderHarness {
  MapBuilderHarness._(this.tester, this.maps, this.visuals, this.container);

  final WidgetTester tester;
  final WorkspaceMemoryPort maps;
  final WorkspaceTestVisuals visuals;
  final ProviderContainer container;

  MapWorkspaceController get controller =>
      container.read(mapWorkspaceControllerProvider(exampleA));

  static Future<MapBuilderHarness> open(
    WidgetTester tester, {
    WorkspaceMemoryPort? port,
  }) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sessions = ControlledProjectSessionPort();
    final maps = port ?? WorkspaceMemoryPort();
    final visuals = WorkspaceTestVisuals();
    final container = ProviderContainer(
      overrides: [
        projectSessionPortProvider.overrideWithValue(sessions),
        projectDirectoryPickerProvider.overrideWithValue(
          () async => exampleA.directoryPath,
        ),
        mapWorkspacePortProvider(exampleA).overrideWithValue(maps),
        workspaceVisualsLoaderProvider.overrideWithValue(
          (session, manifest) async => visuals,
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
    final harness = MapBuilderHarness._(tester, maps, visuals, container);
    await harness.settle();
    return harness;
  }

  Future<void> settle() async {
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }
}
