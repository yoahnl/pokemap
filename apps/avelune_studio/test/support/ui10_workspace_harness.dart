import 'package:avelune_studio/features/cinematics/data/local_cinematic_adapter.dart';
import 'package:avelune_studio/presentation/features/cinematics/cinematic_workspace_page.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_primary_navigation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'capture_m3_widget.dart';
import 'm2_ui_fixture.dart';
import 'ui08_workspace_harness.dart';
import 'ui10_cinematic_fixture.dart';
import 'ui10_widget_port.dart';

class Ui10WorkspaceHarness {
  Ui10WorkspaceHarness(this.workspace, this.port);
  final Ui08WorkspaceHarness workspace;
  final Ui10WidgetPort port;
  static Future<Ui10WorkspaceHarness> create(
    WidgetTester tester, {
    int tileSize = 32,
  }) async {
    final fixture = await createUi10Fixture(tileSize: tileSize);
    final workspace = await Ui08WorkspaceHarness.create(
      tester,
      fixture: fixture,
    );
    final map = await fixture.maps.loadMap(
      fixture.session,
      workspace.maps.project!.maps.first,
    );
    workspace.visuals.setActiveMap(map.map);
    await workspace.visuals.settled;
    return Ui10WorkspaceHarness(
      workspace,
      Ui10WidgetPort(
        LocalCinematicAdapter(
          session: fixture.session,
          mapAdapter: fixture.maps,
        ),
        tester,
      ),
    );
  }

  Widget app({double textScale = 1}) =>
      workspace.app(cinematicPort: port, textScale: textScale);
  CinematicWorkspacePage page(WidgetTester tester) =>
      tester.widget(find.byType(CinematicWorkspacePage));
  Future<void> open(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(StudioPrimaryNavigation),
        matching: find.byTooltip('Histoire'),
      ),
    );
    await pumpIo(tester, frames: 8);
    if (find.text('Cinématiques sur carte').evaluate().isEmpty) {
      await tester.tap(find.byTooltip('Actions Histoire'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Cinématiques sur carte').first);
    await pumpIo(tester, frames: 15);
    await tester.tap(
      find.byKey(const ValueKey('cinematic-library-$ui10CinematicId')),
    );
    await pumpIo(tester, frames: 30);
  }

  Future<void> capture(WidgetTester tester, String name) =>
      captureM3Widget(tester, workspace.captureKey, name);
  Future<void> dispose() => workspace.dispose();
}
