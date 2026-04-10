import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

import 'shell_chrome_test_harness.dart';

void main() {
  group('StatusBar', () {
    testWidgets('shows ready and zoom when no map is active', (tester) async {
      await pumpStatusBarHarness(
        tester,
        initialState: const EditorState(),
      );

      expect(find.text('Ready'), findsOneWidget);
      expect(find.text('Zoom 100%'), findsOneWidget);
      expect(find.textContaining('Map '), findsNothing);
    });

    testWidgets('shows active map chips and formatted zoom', (tester) async {
      await pumpStatusBarHarness(
        tester,
        initialState: EditorState(
          activeMap: buildShellChromeMap(),
          zoom: 1.5,
        ),
      );

      expect(find.text('Map route_1'), findsOneWidget);
      expect(find.text('20 x 15'), findsOneWidget);
      expect(find.text('Zoom 150%'), findsOneWidget);
    });

    testWidgets('prioritizes error text over status text', (tester) async {
      await pumpStatusBarHarness(
        tester,
        initialState: EditorState(
          activeMap: buildShellChromeMap(),
          statusMessage: 'Map saved',
          errorMessage: 'Disk full',
        ),
      );

      expect(find.text('Disk full'), findsOneWidget);
      expect(find.text('Map saved'), findsNothing);
    });
  });
}
