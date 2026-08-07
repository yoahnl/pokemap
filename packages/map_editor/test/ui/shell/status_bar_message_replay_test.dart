import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/state/editor_toast_replay_provider.dart';

import '../../shell_chrome_test_harness.dart';

void main() {
  const pillFinderKey = Key('status-bar-message-pill');

  late List<String> copiedTexts;

  setUp(() {
    copiedTexts = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copiedTexts.add((call.arguments as Map)['text'] as String);
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('Status bar message pill', () {
    testWidgets('copies the error message and asks for a toast replay',
        (tester) async {
      const message =
          'Densité non enregistrée : Editeur d’environnement en cours';
      final container = await pumpStatusBarHarness(
        tester,
        initialState: const EditorState(errorMessage: message),
      );

      await tester.tap(find.byKey(pillFinderKey));
      await tester.pump();

      expect(copiedTexts, [message]);
      final request = container.read(editorToastReplayProvider);
      expect(request, isNotNull);
      expect(request!.message, message);
      expect(request.isError, isTrue);
    });

    testWidgets('replays a status message as a non-error toast',
        (tester) async {
      const message = 'Carte « Selbrume » chargée';
      final container = await pumpStatusBarHarness(
        tester,
        initialState: const EditorState(statusMessage: message),
      );

      await tester.tap(find.byKey(pillFinderKey));
      await tester.pump();

      expect(copiedTexts, [message]);
      expect(container.read(editorToastReplayProvider)!.isError, isFalse);
    });

    testWidgets('bumps the revision so the same message replays twice',
        (tester) async {
      const message = 'Densité non enregistrée';
      final container = await pumpStatusBarHarness(
        tester,
        initialState: const EditorState(errorMessage: message),
      );

      await tester.tap(find.byKey(pillFinderKey));
      await tester.pump();
      final firstRevision = container.read(editorToastReplayProvider)!.revision;

      await tester.tap(find.byKey(pillFinderKey));
      await tester.pump();

      expect(
        container.read(editorToastReplayProvider)!.revision,
        firstRevision + 1,
      );
      expect(copiedTexts, [message, message]);
    });
  });

  group('Editor shell toast replay', () {
    testWidgets('brings the toast back when the status bar pill is tapped',
        (tester) async {
      const message = 'Densité non enregistrée : sauvegardez le calque';
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/status_bar_replay_test',
          project: buildShellChromeProject(),
          errorMessage: message,
        ),
      );

      // Seeded state never flashed a toast, so only the pill shows the text.
      expect(find.text(message), findsOneWidget);

      await tester.tap(find.byKey(pillFinderKey));
      await tester.pump();

      expect(find.text(message), findsNWidgets(2));

      // The replayed toast lingers longer than the automatic 2s flash.
      await tester.pump(const Duration(seconds: 3));
      expect(find.text(message), findsNWidgets(2));

      await tester.pump(const Duration(seconds: 4));
      expect(find.text(message), findsOneWidget);
    });
  });
}
