import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_input_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_shortcuts.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/platform/input/editor_shortcuts.dart';
import 'package:avelune_studio/platform/rendering/viewports/map_editing_surface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

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

  testWidgets(
    'a text field yields hardware undo to itself while save still reaches the editor',
    (tester) async {
      var undone = 0, saved = 0;
      final input = TextEditingController();
      final field = FocusNode();
      final outer = FocusNode();
      addTearDown(input.dispose);
      addTearDown(field.dispose);
      addTearDown(outer.dispose);
      final platform = defaultTargetPlatform;
      final modifier = platform == TargetPlatform.macOS
          ? const SingleActivator(LogicalKeyboardKey.keyZ, meta: true)
          : const SingleActivator(LogicalKeyboardKey.keyZ, control: true);
      final save = platform == TargetPlatform.macOS
          ? const SingleActivator(LogicalKeyboardKey.keyS, meta: true)
          : const SingleActivator(LogicalKeyboardKey.keyS, control: true);
      await tester.pumpWidget(
        MaterialApp(
          home: CallbackShortcuts(
            bindings: textAwareEditorShortcuts({
              modifier: () => undone++,
              save: () => saved++,
            }),
            child: Scaffold(
              body: Focus(
                focusNode: outer,
                child: TextField(controller: input, focusNode: field),
              ),
            ),
          ),
        ),
      );
      field.requestFocus();
      await tester.pump();
      await tester.enterText(find.byType(TextField), '125');
      await tester.pump(const Duration(seconds: 1));
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump(const Duration(seconds: 1));
      expect(input.text, '12');
      await _command(tester, LogicalKeyboardKey.keyZ);
      expect(input.text, '125');
      expect(undone, 0);
      await _command(tester, LogicalKeyboardKey.keyS);
      expect(saved, 1);
      outer.requestFocus();
      await tester.pump();
      await _command(tester, LogicalKeyboardKey.keyZ);
      expect(undone, 1);
      await tester.pumpWidget(const SizedBox());
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );

  group('production keyboard guard of the editing surface', () {
    Future<
      ({
        MapWorkspaceController workspace,
        MapEditingInputSession input,
        String id,
      })
    >
    mount(WidgetTester tester, {bool busy = false}) async {
      final workspace = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      addTearDown(workspace.dispose);
      await workspace.initialize();
      final document = workspace.active!;
      final id = MapEditingCommands(
        document,
        workspace.project!,
      ).place(workspaceElement, const GridPos(x: 1, y: 1))!;
      document.selectedId = id;
      final view = MapEditingViewportSession();
      addTearDown(view.dispose);
      final input = MapEditingInputSession(
        controller: workspace,
        view: () => view,
      );
      addTearDown(input.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 640,
              height: 480,
              child: MapEditingSurface(
                controller: workspace,
                visuals: WorkspaceTestVisuals(),
                view: view,
                input: input,
                onChanged: () {},
                busy: busy,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return (workspace: workspace, input: input, id: id);
    }

    testWidgets('delete removes the selected decor when editing is available', (
      tester,
    ) async {
      final mounted = await mount(tester);
      final document = mounted.workspace.active!;
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();
      expect(
        document.current.placedElements.where((e) => e.id == mounted.id),
        isEmpty,
      );
    });

    testWidgets('delete does nothing while the surface is busy', (
      tester,
    ) async {
      final mounted = await mount(tester, busy: true);
      final document = mounted.workspace.active!;
      final before = document.current;
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();
      expect(document.current, same(before));
    });

    testWidgets('delete does nothing while the catalogue is busy', (
      tester,
    ) async {
      final mounted = await mount(tester);
      final document = mounted.workspace.active!;
      final before = document.current;
      mounted.workspace.catalogBusy = true;
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();
      expect(document.current, same(before));
    });
  });
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
