import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/app/providers/pokedex/pokedex_providers.dart';
import 'package:map_editor/src/ui/editor_shell_page.dart';

import 'encounter_studio_test_fixture.dart';
import 'shell_chrome_test_harness.dart';
import 'support/narrative_studio_capture_fonts.dart';

const _captureFontFamily = 'PokeMapEncounterStudioCapture';

void main() {
  testWidgets('matches the approved Encounter Studio state at 1672x941', (
    tester,
  ) async {
    await loadNarrativeStudioCaptureFonts(
      textFamilies: const <String>[_captureFontFamily],
    );
    await pumpEditorShellPage(
      tester,
      initialState: encounterStudioFixtureState,
      surfaceSize: const Size(1672, 941),
      fontFamily: _captureFontFamily,
      cupertinoFontFamily: _captureFontFamily,
      overrides: [
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => encounterStudioFixtureSpecies,
        ),
      ],
    );
    await tester.tap(
      find.byKey(const Key('encounter-roster-entry-route_1_grass-0')),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 200));

    await expectLater(
      find.byType(EditorShellPage),
      matchesGoldenFile(
        'goldens/encounter_studio/encounter_studio_1672x941.png',
      ),
    );
  });
}
