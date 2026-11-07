import 'package:avelune_studio/features/resources/application/environment_draft.dart';
import 'package:avelune_studio/presentation/features/resources/environment_editor_screen.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

Future<void> _pump(WidgetTester tester, Map<String, int> zones) async {
  tester.view.physicalSize = const Size(1440, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final preset = EnvironmentPreset(
    id: 'forest',
    name: 'Forêt claire',
    templateId: 'manual',
    sortOrder: 0,
    palette: [
      EnvironmentPaletteItem(elementId: workspaceElement.id, weight: 1),
    ],
    defaultParams: EnvironmentGenerationParams.standard(),
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: EnvironmentEditorScreen(
          draft: EnvironmentDraft(original: preset),
          project: workspaceProject.copyWith(environmentPresets: [preset]),
          visuals: WorkspaceTestVisuals(),
          openZones: zones,
          onSave: () async {},
          onChanged: () {},
          onClose: () {},
          onDiscard: () {},
          onEditDecor: (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'the environment workshop separates the shared definition from its zones',
    (tester) async {
      await _pump(tester, {'Route 29': 2, 'Bois aux Chênes': 1});
      final scope = find.byKey(const ValueKey('environment-shared-scope'));
      expect(scope, findsOneWidget);
      expect(
        find.descendant(
          of: scope,
          matching: find.textContaining('3 zones sur 2 cartes ouvertes'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: scope,
          matching: find.textContaining('gardent leurs objets générés'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: scope,
          matching: find.textContaining('Autre répartition'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('an unused environment says no open zone uses it', (
    tester,
  ) async {
    await _pump(tester, const {});
    expect(
      find.textContaining('Aucune zone des cartes ouvertes'),
      findsOneWidget,
    );
  });
}
