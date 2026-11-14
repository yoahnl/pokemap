import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_input_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/coordination/editor_shortcuts.dart';
import 'package:avelune_studio/platform/rendering/viewports/map_editing_surface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import 'workspace_text_editing_shortcuts_owner_support.dart';

void main() {
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
      await shortcutCommand(tester, LogicalKeyboardKey.keyZ);
      expect(input.text, '125');
      expect(undone, 0);
      await shortcutCommand(tester, LogicalKeyboardKey.keyS);
      expect(saved, 1);
      outer.requestFocus();
      await tester.pump();
      await shortcutCommand(tester, LogicalKeyboardKey.keyZ);
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
