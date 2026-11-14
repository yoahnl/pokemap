import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/app/di/map_workspace_providers.dart';
import 'package:avelune_studio/app/di/project_session_providers.dart';
import 'package:avelune_studio/presentation/shell/studio_root.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/controlled_project_session_port.dart';
import '../support/map_workspace_fixture.dart';

late ControlledProjectSessionPort sessions;
late WorkspaceMemoryPort maps;
late WorkspaceTestVisuals visuals;
late ProviderContainer container;
var picked = 0;

Future<void> settle(WidgetTester tester) async {
  for (var frame = 0; frame < 6; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> openShell(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1920, 1080);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  sessions = ControlledProjectSessionPort();
  maps = WorkspaceMemoryPort();
  visuals = WorkspaceTestVisuals();
  picked = 0;
  container = ProviderContainer(
    overrides: [
      projectSessionPortProvider.overrideWithValue(sessions),
      projectDirectoryPickerProvider.overrideWithValue(() async {
        picked++;
        return exampleA.directoryPath;
      }),
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
  await settle(tester);
}

IconButton barIcon(WidgetTester tester, String tooltip) => tester.widget(
  find.ancestor(of: find.byTooltip(tooltip), matching: find.byType(IconButton)),
);
