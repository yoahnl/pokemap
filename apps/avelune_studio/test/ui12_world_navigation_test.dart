import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/features/world/world_workspace_page.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_primary_navigation.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/m2_ui_fixture.dart';
import 'support/ui05_narrative_fixture.dart';
import 'support/ui12_widget_world_port.dart';
import 'support/ui12_world_harness.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';

Future<void> activate(WidgetTester tester, Finder finder) async {
  await tester.pump(const Duration(milliseconds: 350));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await pumpIo(tester, frames: 12);
}

void main() {
  testWidgets('Histoire opens the states and rules page and comes back', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final h = (await tester.runAsync(
      () => Ui12WorldHarness.create(
        initialize: false,
        wrap: (port) => Ui12WidgetWorldPort(port, tester),
      ),
    ))!;
    final visuals = (await tester.runAsync(
      () => StudioMapResources.load(h.session, h.maps.project!),
    ))!;
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(h.dispose);
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: MapWorkspaceScreen(
          controller: h.maps,
          loadVisuals: (_, _) async => visuals,
          narrativePort: Ui05NarrativePort(
            LocalNarrativeAdapter(session: h.session, mapAdapter: h.adapter),
            tester,
          ),
          worldPort: h.port,
          onClose: () async {},
          registerExitGuard: (_) {},
          runtimeBuilder: (_, _, _) => const SizedBox(),
        ),
      ),
    );
    await pumpIo(tester);

    await activate(
      tester,
      find.descendant(
        of: find.byType(StudioPrimaryNavigation),
        matching: find.byTooltip('Histoire'),
      ),
    );
    await activate(tester, find.text('Voir tous les documents').first);
    await activate(tester, find.text('États et règles du monde').first);
    expect(find.byType(WorldWorkspacePage), findsOneWidget);

    await activate(tester, find.byTooltip('Retour à Histoire'));
    expect(find.byType(WorldWorkspacePage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
