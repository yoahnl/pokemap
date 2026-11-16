import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/app/di/dialogue_providers.dart';
import 'package:avelune_studio/app/di/map_workspace_providers.dart';
import 'package:avelune_studio/app/di/project_session_providers.dart';
import 'package:avelune_studio/presentation/shell/studio_root.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/controlled_project_session_port.dart';
import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets('publication resources live with the project page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sessions = ControlledProjectSessionPort();
    var opened = 0;
    var closed = 0;
    final container = ProviderContainer(
      overrides: [
        projectSessionPortProvider.overrideWithValue(sessions),
        projectDirectoryPickerProvider.overrideWithValue(
          () async => exampleA.directoryPath,
        ),
        mapWorkspacePortProvider(exampleA)
            .overrideWithValue(WorkspaceMemoryPort()),
        workspaceVisualsLoaderProvider.overrideWithValue(
          (_, _) async => WorkspaceTestVisuals(),
        ),
        dialoguePortProvider(exampleA).overrideWith((ref) {
          opened++;
          ref.onDispose(() => closed++);
          return null;
        }),
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
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.byKey(const ValueKey('map-builder')), findsOneWidget);
    expect(opened, 1);
    expect(closed, 0);
    await tester.tap(find.byTooltip('Accueil du projet'));
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.byKey(const ValueKey('studio-home')), findsOneWidget);
    expect(closed, 1);
  });
}
