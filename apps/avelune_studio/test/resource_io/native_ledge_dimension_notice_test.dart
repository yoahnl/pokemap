import 'package:avelune_studio/presentation/features/resources/native_ledge_panel.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import 'ledge_border_metadata_test.dart' show NativeLedgeResourceFixture;

void main() {
  for (final dimension in ProjectDimension.values) {
    testWidgets('a ledge jump says where the game applies it ($dimension)', (
      tester,
    ) async {
      final fixture = (await tester.runAsync(
        NativeLedgeResourceFixture.create,
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final project = fixture.project.copyWith(
        settings: fixture.project.settings.copyWith(dimension: dimension),
      );
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: NativeLedgePanel(
                record: fixture.record,
                project: project,
                visuals: WorkspaceTestVisuals(),
                jumpSide: BorderLineSide.primary,
                onJumpSideChanged: null,
              ),
            ),
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('native-ledge-jump-summary')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('native-ledge-jump-2d-only')),
        dimension == ProjectDimension.threeD ? findsOneWidget : findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
