import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

import '../../shell_chrome_test_harness.dart';

void main() {
  for (final width in <double>[1672, 1440, 1280, 720]) {
    testWidgets('Character Studio has no overflow at ${width.toInt()} px', (
      tester,
    ) async {
      await _pumpWorkspace(tester, width);

      expect(
        find.byKey(const ValueKey<String>('character-studio-canvas-region')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('wide layout exposes the three semantic regions', (tester) async {
    await _pumpWorkspace(tester, 1672);

    expect(
      find.byKey(const ValueKey<String>('character-studio-layout-wide')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Bibliothèque des personnages'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Espace d’édition du personnage'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Inspecteur Character Studio'),
      findsOneWidget,
    );
  });

  for (final width in <double>[1440, 1280]) {
    testWidgets('medium layout alternates library and inspector at $width px', (
      tester,
    ) async {
      await _pumpWorkspace(tester, width);

      expect(
        find.byKey(const ValueKey<String>('character-studio-layout-medium')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('character-studio-library-region')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('character-studio-inspector-region')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('character-studio-inspector-toggle')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('character-studio-library-region')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('character-studio-inspector-region')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('compact layout opens each region in an accessible side sheet', (
    tester,
  ) async {
    await _pumpWorkspace(tester, 720);

    expect(
      find.byKey(const ValueKey<String>('character-studio-layout-compact')),
      findsOneWidget,
    );
    expect(find.byType(PokeMapDesktopSideSheet), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('character-studio-library-toggle')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PokeMapDesktopSideSheet), findsOneWidget);
    expect(
      find.bySemanticsLabel('Bibliothèque des personnages'),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('character-studio-inspector-toggle')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PokeMapDesktopSideSheet), findsOneWidget);
    expect(
      find.bySemanticsLabel('Inspecteur Character Studio'),
      findsOneWidget,
    );
  });

  testWidgets('tabs participate in keyboard focus traversal', (tester) async {
    await _pumpWorkspace(tester, 1672);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(tester.binding.focusManager.primaryFocus, isNotNull);
    expect(
      find.byKey(const ValueKey<String>('character-studio-tab-identity')),
      findsOneWidget,
    );
  });
}

Future<void> _pumpWorkspace(WidgetTester tester, double width) async {
  await pumpEditorCanvasHostHarness(
    tester,
    initialState: EditorState(
      projectRootPath: '/tmp/character-studio-layout',
      project: buildShellChromeProject(name: 'Encounter Studio certification'),
      workspaceMode: EditorWorkspaceMode.characterStudio,
      statusMessage: 'Sauvegardé à l’instant',
    ),
    surfaceSize: Size(width, 840),
  );
}
