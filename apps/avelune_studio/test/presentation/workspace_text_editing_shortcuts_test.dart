import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_shortcuts.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_draft_field.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_search_field.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import '../support/map_host_fixture.dart';
import '../support/m2_ui_fixture.dart' show pumpIo;
import '../support/ui11_workspace_harness.dart';
import '../ui11_presentation_widget_test.dart' show tapUi11;

void main() {
  for (final field in ['generic', 'search', 'draft']) {
    testWidgets(
      '$field field handles hardware deletion under workspace shortcuts',
      (tester) async {
        final workspace = MapWorkspaceController(
          workspaceSession,
          WorkspaceMemoryPort(),
        );
        addTearDown(workspace.dispose);
        await workspace.initialize();
        final document = workspace.active!;
        document.commit(
          document.current.copyWith(name: 'Map history stays intact'),
        );
        final map = document.current;
        final historyCount = document.undoCount;
        final input = TextEditingController(text: 'Bourg');
        addTearDown(input.dispose);
        final child = switch (field) {
          'search' => StudioSearchField(controller: input, onChanged: (_) {}),
          'draft' => StudioDraftField(
            value: 'Bourg',
            label: 'Name',
            onChanged: (_) {},
          ),
          _ => TextField(controller: input),
        };
        await tester.pumpWidget(
          MaterialApp(
            theme: studioTheme(),
            home: CallbackShortcuts(
              bindings: workspaceShortcuts(workspace, null, (action) {
                if (FocusManager.instance.primaryFocus?.context
                        ?.findAncestorWidgetOfExactType<EditableText>() ==
                    null) {
                  action();
                }
              }),
              child: Scaffold(body: child),
            ),
          ),
        );
        await tester.tap(find.byType(TextField));
        await tester.pump();
        final editing = tester
            .widget<EditableText>(find.byType(EditableText))
            .controller;
        editing.selection = TextSelection.collapsed(
          offset: editing.text.length,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
        await tester.pump();
        expect(editing.text, 'Bour');
        editing.selection = const TextSelection.collapsed(offset: 1);
        await tester.sendKeyEvent(LogicalKeyboardKey.delete);
        await tester.pump();
        expect(editing.text, 'Bur');
        await _command(tester, LogicalKeyboardKey.keyA);
        expect(
          editing.selection,
          const TextSelection(baseOffset: 0, extentOffset: 3),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
        await tester.pump();
        expect(editing.text, isEmpty);
        expect(document.current, same(map));
        expect(document.undoCount, historyCount);
        await tester.pumpWidget(const SizedBox());
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.macOS,
        TargetPlatform.windows,
      }),
    );
  }

  testWidgets(
    'real map sidebar and Elements search accept hardware editing',
    (tester) async {
      final host = await MapHostFixture.open(tester);
      final document = host.document;
      final map = document.current;
      final historyCount = document.undoCount;
      await tester.tap(find.byTooltip('Rechercher une carte'));
      await pumpIo(tester, frames: 2);
      final sidebar = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Rechercher une carte',
      );
      expect(sidebar, findsOneWidget);
      await tester.enterText(sidebar, 'Bourg');
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await pumpIo(tester, frames: 2);
      expect(tester.widget<TextField>(sidebar).controller!.text, 'Bour');
      await _command(tester, LogicalKeyboardKey.keyA);
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await pumpIo(tester, frames: 2);
      expect(tester.widget<TextField>(sidebar).controller!.text, isEmpty);
      await tester.tap(find.byKey(const ValueKey('map-open-elements')));
      await pumpIo(tester, frames: 2);
      final search = find.descendant(
        of: find.byKey(const ValueKey('map-elements-search')),
        matching: find.byType(TextField),
      );
      expect(search, findsOneWidget);
      await tester.enterText(search, 'brume');
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await pumpIo(tester, frames: 2);
      expect(tester.widget<TextField>(search).controller!.text, 'brum');
      await _command(tester, LogicalKeyboardKey.keyA);
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await pumpIo(tester, frames: 2);
      expect(tester.widget<TextField>(search).controller!.text, isEmpty);
      expect(document.current, same(map));
      expect(document.undoCount, historyCount);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets(
    'Presentation inspector yields hardware undo to its text field',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final harness = (await tester.runAsync(
        () => Ui11WorkspaceHarness.create(tester),
      ))!;
      addTearDown(() => harness.shutdown(tester));
      await tester.pumpWidget(harness.app());
      await harness.settle(tester);
      await tapUi11(
        tester,
        harness,
        find.byKey(const ValueKey('presentation-canvas')),
      );
      final duration = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Durée (s)',
      );
      await tester.ensureVisible(duration);
      await tester.enterText(duration, '125');
      await tester.pump(const Duration(seconds: 1));
      final asset = harness.controller.active!.asset;
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.widget<TextField>(duration).controller!.text, '12');
      await _command(tester, LogicalKeyboardKey.keyZ);
      expect(tester.widget<TextField>(duration).controller!.text, '125');
      expect(harness.controller.active!.asset, asset);
      expect(harness.port.writes, 0);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets(
    'text cut and undo stay local while save and unfocused editor keys work',
    (tester) async {
      final workspace = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      addTearDown(workspace.dispose);
      await workspace.initialize();
      final document = workspace.active!;
      final initial = document.current;
      document.commit(
        initial.copyWith(
          placedElements: const [
            MapPlacedElement(
              id: 'tree',
              layerId: 'ground',
              elementId: 'tree',
              pos: GridPos(x: 1, y: 1),
            ),
          ],
        ),
      );
      document.selectedId = 'tree';
      final map = document.current;
      final historyCount = document.undoCount;
      final input = TextEditingController(text: 'Bourg');
      final canvas = FocusNode();
      addTearDown(input.dispose);
      addTearDown(canvas.dispose);
      var saves = 0;
      String clipboard = '';
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String;
          }
          if (call.method == 'Clipboard.getData') return {'text': clipboard};
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: CallbackShortcuts(
            bindings: workspaceShortcuts(
              workspace,
              null,
              (action) {
                if (FocusManager.instance.primaryFocus?.context
                        ?.findAncestorWidgetOfExactType<EditableText>() ==
                    null) {
                  action();
                }
              },
              onSave: () => saves++,
              guardedWhileTyping: (action) => action(),
            ),
            child: Scaffold(
              body: Column(
                children: [
                  TextField(controller: input),
                  Focus(
                    focusNode: canvas,
                    child: const SizedBox(width: 100, height: 100),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(TextField));
      await tester.pump(const Duration(seconds: 1));
      await _command(tester, LogicalKeyboardKey.keyA);
      await _command(tester, LogicalKeyboardKey.keyX);
      expect(input.text, isEmpty);
      expect(clipboard, 'Bourg');
      await tester.pump(const Duration(seconds: 1));
      await _command(tester, LogicalKeyboardKey.keyZ);
      expect(input.text, 'Bourg');
      await _command(tester, LogicalKeyboardKey.keyA);
      await _command(tester, LogicalKeyboardKey.keyC);
      expect(clipboard, 'Bourg');
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(input.text, isEmpty);
      await _command(tester, LogicalKeyboardKey.keyV);
      expect(input.text, 'Bourg');
      expect(document.current, same(map));
      expect(document.undoCount, historyCount);
      await _command(tester, LogicalKeyboardKey.keyS);
      expect(saves, 1);
      canvas.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();
      expect(document.current.placedElements, isEmpty);
      await _command(tester, LogicalKeyboardKey.keyZ);
      expect(document.current.placedElements.single.id, 'tree');
      await tester.pumpWidget(const SizedBox());
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );
}

Future<void> _command(WidgetTester tester, LogicalKeyboardKey key) async {
  final modifier = defaultTargetPlatform == TargetPlatform.macOS
      ? LogicalKeyboardKey.metaLeft
      : LogicalKeyboardKey.controlLeft;
  await tester.sendKeyDownEvent(modifier);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(modifier);
  await tester.pump();
}
