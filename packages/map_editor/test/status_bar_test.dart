import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

import 'shell_chrome_test_harness.dart';

void main() {
  group('StatusBar', () {
    testWidgets('shows ready and zoom when no map is active', (tester) async {
      await pumpStatusBarHarness(
        tester,
        initialState: const EditorState(),
      );

      expect(find.text('Prêt'), findsOneWidget);
      expect(find.text('Zoom 100 %'), findsOneWidget);
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

      expect(find.text('Carte route_1'), findsOneWidget);
      expect(find.text('20 x 15'), findsOneWidget);
      expect(find.text('Zoom 150 %'), findsOneWidget);
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

    testWidgets('shows persistent unsaved-project signal when project is dirty',
        (tester) async {
      await pumpStatusBarHarness(
        tester,
        initialState: const EditorState(
          isProjectDirty: true,
          statusMessage: 'Map saved',
        ),
      );

      expect(
        find.text(
          'Projet modifié en mémoire — sauvegardez le projet avec la disquette.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('status-bar-project-dirty-chip')),
          findsOneWidget);
    });

    testWidgets('hides unsaved-project signal after project save success',
        (tester) async {
      final container = await pumpStatusBarHarness(
        tester,
        initialState: const EditorState(isProjectDirty: true),
      );

      container.read(editorNotifierProvider.notifier).state =
          container.read(editorNotifierProvider).copyWith(
                isProjectDirty: false,
                statusMessage: 'Projet sauvegardé via le flux projet existant.',
              );
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('status-bar-project-dirty-chip')), findsNothing);
      expect(
        find.text(
          'Projet modifié en mémoire — sauvegardez le projet avec la disquette.',
        ),
        findsNothing,
      );
    });
  });
}
