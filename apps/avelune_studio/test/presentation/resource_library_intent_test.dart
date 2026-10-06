import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/resources/resource_library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets('families explain their tools and creation follows selection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var imports = 0;
    var borders = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResourceLibraryScreen(
            project: workspaceProject,
            visuals: WorkspaceTestVisuals(),
            state: ResourceLibraryState(),
            onUse: (_) {},
            onEdit: (_) {},
            onTerrain: (_) {},
            onCreateBorder: () => borders++,
            onResumeBorder: (_) {},
            onImport: () => imports++,
            onBack: () {},
          ),
        ),
      ),
    );
    expect(find.text('Poser un objet'), findsOneWidget);
    expect(find.text('Peindre le sol'), findsOneWidget);
    expect(find.text('Tracer un contour'), findsOneWidget);
    expect(find.text('Répartir des décors'), findsOneWidget);
    expect(find.text('Créer un décor'), findsOneWidget);
    expect(find.text('Créer une bordure'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('resource-family-borders')));
    await tester.pumpAndSettle();
    expect(find.text('Créer une bordure'), findsOneWidget);
    expect(find.text('Créer un décor'), findsNothing);
    await tester.tap(find.text('Créer une bordure'));
    expect(borders, 1);
    expect(imports, 0);
    await tester.tap(find.byKey(const ValueKey('resource-family-images')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Importer une image'));
    expect(imports, 1);
    expect(borders, 1);
    expect(tester.takeException(), isNull);
  });
}
