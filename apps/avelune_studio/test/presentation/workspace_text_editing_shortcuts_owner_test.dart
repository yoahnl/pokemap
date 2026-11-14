import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import 'workspace_text_editing_shortcuts_owner_support.dart';

void main() {
  testWidgets(
    'generic field handles hardware deletion under workspace shortcuts',
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
      await tester.pumpWidget(
        MaterialApp(
          home: CallbackShortcuts(
            bindings: mapEditingShortcuts(workspace, null, (action) {
              if (FocusManager.instance.primaryFocus?.context
                      ?.findAncestorWidgetOfExactType<EditableText>() ==
                  null) {
                action();
              }
            }),
            child: Scaffold(body: TextField(controller: input)),
          ),
        ),
      );
      await tester.tap(find.byType(TextField));
      await tester.pump();
      final editing = tester
          .widget<EditableText>(find.byType(EditableText))
          .controller;
      editing.selection = TextSelection.collapsed(offset: editing.text.length);
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(editing.text, 'Bour');
      editing.selection = const TextSelection.collapsed(offset: 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();
      expect(editing.text, 'Bur');
      await shortcutCommand(tester, LogicalKeyboardKey.keyA);
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
          home: CallbackShortcuts(
            bindings: mapEditingShortcuts(
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
      await shortcutCommand(tester, LogicalKeyboardKey.keyA);
      await shortcutCommand(tester, LogicalKeyboardKey.keyX);
      expect(input.text, isEmpty);
      expect(clipboard, 'Bourg');
      await tester.pump(const Duration(seconds: 1));
      await shortcutCommand(tester, LogicalKeyboardKey.keyZ);
      expect(input.text, 'Bourg');
      await shortcutCommand(tester, LogicalKeyboardKey.keyA);
      await shortcutCommand(tester, LogicalKeyboardKey.keyC);
      expect(clipboard, 'Bourg');
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(input.text, isEmpty);
      await shortcutCommand(tester, LogicalKeyboardKey.keyV);
      expect(input.text, 'Bourg');
      expect(document.current, same(map));
      expect(document.undoCount, historyCount);
      await shortcutCommand(tester, LogicalKeyboardKey.keyS);
      expect(saves, 1);
      canvas.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();
      expect(document.current.placedElements, isEmpty);
      await shortcutCommand(tester, LogicalKeyboardKey.keyZ);
      expect(document.current.placedElements.single.id, 'tree');
      await tester.pumpWidget(const SizedBox());
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );
}
