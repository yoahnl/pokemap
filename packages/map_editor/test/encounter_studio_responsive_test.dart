import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/app/providers/pokedex/pokedex_providers.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/encounter_studio_panel.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_editor/src/ui/panels/encounter_tables_panel.dart';

import 'encounter_studio_test_fixture.dart';
import 'shell_chrome_test_harness.dart';

void main() {
  for (final width in const <double>[1280, 1440, 1672]) {
    testWidgets('full shell stays responsive at ${width.toInt()}x941', (
      tester,
    ) async {
      await pumpEditorShellPage(
        tester,
        initialState: encounterStudioFixtureState,
        surfaceSize: Size(width, 941),
        overrides: [
          pokedexEntryLoaderProvider.overrideWithValue(
            (_) async => encounterStudioFixtureSpecies,
          ),
        ],
      );

      expect(
        find.byKey(const ValueKey<String>('right-inspector-region')),
        findsNothing,
        reason: '$width px',
      );
      expect(tester.takeException(), isNull, reason: '$width px');

      if (width == 1672) {
        expect(find.byKey(encounterWorkspaceLibraryKey), findsOneWidget);
        expect(find.byKey(encounterWorkspaceTableKey), findsOneWidget);
        expect(find.byKey(encounterWorkspaceInspectorKey), findsOneWidget);
      } else {
        expect(find.byKey(encounterWorkspaceLibraryKey), findsNothing);
        expect(find.byKey(encounterWorkspaceTableKey), findsOneWidget);
        expect(find.byKey(encounterWorkspaceInspectorKey), findsNothing);
        expect(find.text('Bibliothèque'), findsWidgets);
        expect(find.text('Inspecteur'), findsWidgets);

        await tester.tap(find.text('Bibliothèque').last);
        await tester.pumpAndSettle();
        expect(find.byKey(encounterWorkspaceLibraryKey), findsOneWidget);
        expect(find.byKey(encounterWorkspaceTableKey), findsNothing);
        expect(tester.takeException(), isNull, reason: '$width px library');

        await tester.tap(find.text('Inspecteur').last);
        await tester.pumpAndSettle();
        expect(find.byKey(encounterWorkspaceLibraryKey), findsNothing);
        expect(find.byKey(encounterWorkspaceInspectorKey), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$width px inspector');
      }
    });
  }

  testWidgets('trainer workspace reflows in a shallow desktop shell', (
    tester,
  ) async {
    await pumpEditorShellPage(
      tester,
      initialState: encounterStudioFixtureState.copyWith(
        encounterStudioSection: EncounterStudioSection.trainers,
      ),
      surfaceSize: const Size(1280, 720),
      overrides: [
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => encounterStudioFixtureSpecies,
        ),
      ],
    );

    expect(
      find.byKey(const Key('trainer-library-new-trainer-button')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('table and roster selections follow keyboard traversal', (
    tester,
  ) async {
    await _pumpEncounterShell(tester);

    final selectedTable = find.byKey(
      const Key('encounter-tables-table-toggle-route_1_grass'),
    );
    final selectedTableDetector = find.descendant(
      of: selectedTable,
      matching: find.byType(FocusableActionDetector),
    );
    final entry = find.byKey(
      const Key('encounter-roster-entry-route_1_grass-1'),
    );
    final entryDetector = find.descendant(
      of: entry,
      matching: find.byType(FocusableActionDetector),
    );
    final selectedTableFocusNode = tester
        .widget<FocusableActionDetector>(selectedTableDetector)
        .focusNode!;
    final entryFocusNode = tester
        .widget<FocusableActionDetector>(entryDetector)
        .focusNode!;
    selectedTableFocusNode.requestFocus();
    await tester.pump();
    for (var step = 0; step < 30 && !entryFocusNode.hasFocus; step++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }

    expect(entryFocusNode.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(tester.widget<PokeMapCard>(entry).selected, isTrue);
    expect(find.text('Rattata'), findsWidgets);
    expect(find.text('Inspecteur de l’entrée'), findsOneWidget);

    final table = find.byKey(
      const Key('encounter-tables-table-toggle-route_1_surf'),
    );
    final tableDetector = find.descendant(
      of: table,
      matching: find.byType(FocusableActionDetector),
    );
    tester
        .widget<FocusableActionDetector>(tableDetector)
        .focusNode!
        .requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();

    expect(tester.widget<PokeMapCard>(table).selected, isTrue);
    expect(find.text('Route 1 — Surf'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('visible icon-only actions expose tooltips and semantics', (
    tester,
  ) async {
    await _pumpEncounterShell(tester);
    final buttons = find.descendant(
      of: find.byKey(encounterStudioPanelKey),
      matching: find.byType(PokeMapIconButton),
    );

    expect(buttons, findsWidgets);
    for (final element in buttons.evaluate()) {
      final button = element.widget as PokeMapIconButton;
      expect(button.tooltip?.trim(), isNotEmpty);
    }

    final semantics = tester.getSemantics(
      find.bySemanticsLabel('Ajouter une entrée'),
    );
    expect(semantics.label, contains('Ajouter une entrée'));
  });
}

Future<void> _pumpEncounterShell(WidgetTester tester) {
  return pumpEditorShellPage(
    tester,
    initialState: encounterStudioFixtureState,
    surfaceSize: const Size(1672, 941),
    overrides: [
      pokedexEntryLoaderProvider.overrideWithValue(
        (_) async => encounterStudioFixtureSpecies,
      ),
    ],
  );
}
