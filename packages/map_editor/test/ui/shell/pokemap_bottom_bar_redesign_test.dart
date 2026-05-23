import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

import '../../shell_chrome_test_harness.dart';

void main() {
  group('PokeMap Bottom Bar Redesign Tests', () {
    testWidgets('Renders essential segments and handles wide layout segments',
        (tester) async {
      // Pump on wide surface (1280 wide) to trigger isWide layout
      await pumpStatusBarHarness(
        tester,
        initialState: const EditorState(
          isProjectDirty: false,
          statusMessage: 'Carte « Selbrume » chargée',
        ),
        surfaceSize: const Size(1280, 200),
      );

      // Verify status message in capsule
      expect(find.text('Carte « Selbrume » chargée'), findsOneWidget);

      // Verify wide status metadata
      expect(find.text('Synchronisé'), findsOneWidget);
      expect(find.textContaining('Sauvegardé : à l\'instant'), findsOneWidget);
      expect(find.text('Projet : Bon'), findsOneWidget);

      // Verify locale and version
      expect(find.text('Locale : FR'), findsOneWidget);
      expect(find.text('v0.3.0'), findsOneWidget);
    });

    testWidgets('Hides wide layout segments on narrow viewports to avoid overflows',
        (tester) async {
      // Pump on narrow surface (800 wide) which is below the threshold
      await pumpStatusBarHarness(
        tester,
        initialState: const EditorState(
          isProjectDirty: false,
          statusMessage: 'Carte « Selbrume » chargée',
        ),
        surfaceSize: const Size(800, 200),
      );

      // Verify status message is still visible
      expect(find.text('Carte « Selbrume » chargée'), findsOneWidget);

      // Verify wide status elements are hidden
      expect(find.text('Synchronisé'), findsNothing);
      expect(find.textContaining('Sauvegardé :'), findsNothing);
      expect(find.text('Projet : Bon'), findsNothing);
      expect(find.text('Locale : FR'), findsNothing);
      expect(find.text('v0.3.0'), findsNothing);
    });
  });
}
