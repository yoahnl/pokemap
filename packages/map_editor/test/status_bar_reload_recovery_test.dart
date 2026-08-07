import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

import 'shell_chrome_test_harness.dart';

/// A desynchronised session blocks every write, so the status bar must offer
/// the repair rather than leaving the author to guess that reloading is the fix.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('offers reloading when the session is out of date',
      (tester) async {
    await pumpStatusBarHarness(
      tester,
      initialState: const EditorState(
        errorMessage: editorReloadRequiredMessage,
      ),
    );

    expect(
      find.byKey(const Key('status-bar-reload-active-map')),
      findsOneWidget,
    );
    expect(find.textContaining('Recharger'), findsOneWidget);
  });

  testWidgets('stays out of the way for an ordinary error', (tester) async {
    await pumpStatusBarHarness(
      tester,
      initialState: const EditorState(
        errorMessage: 'Le preset n’est pas publié.',
      ),
    );

    expect(
      find.byKey(const Key('status-bar-reload-active-map')),
      findsNothing,
    );
  });

  testWidgets('warns before discarding unsaved work', (tester) async {
    await pumpStatusBarHarness(
      tester,
      initialState: const EditorState(
        errorMessage: editorReloadRequiredMessage,
        isDirty: true,
      ),
      // The confirmation is a full dialog; the default strip cannot host it.
      surfaceSize: const Size(900, 700),
    );

    await tester.tap(find.byKey(const Key('status-bar-reload-active-map')));
    await tester.pumpAndSettle();

    // Reloading adopts the stored document, so anything unsaved is dropped.
    expect(find.textContaining('perdu'), findsOneWidget);
    expect(find.text('Recharger et perdre'), findsOneWidget);
    expect(find.text('Annuler'), findsOneWidget);
  });

  testWidgets('reloads straight away when nothing is unsaved', (tester) async {
    await pumpStatusBarHarness(
      tester,
      initialState: const EditorState(
        errorMessage: editorReloadRequiredMessage,
      ),
      surfaceSize: const Size(900, 700),
    );

    await tester.tap(find.byKey(const Key('status-bar-reload-active-map')));
    await tester.pumpAndSettle();

    expect(find.text('Recharger et perdre'), findsNothing);
  });

  testWidgets('shows nothing to recover when there is no error',
      (tester) async {
    await pumpStatusBarHarness(
      tester,
      initialState: const EditorState(),
    );

    expect(
      find.byKey(const Key('status-bar-reload-active-map')),
      findsNothing,
    );
  });
}
