import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets('undo shortcuts follow the history the canvas is given', (
    tester,
  ) async {
    final port = WorkspaceMemoryPort();
    final maps = MapWorkspaceController(workspaceSession, port);
    addTearDown(maps.dispose);
    await maps.initialize();
    final steps = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: CallbackShortcuts(
          bindings: mapEditingShortcuts(
            maps,
            null,
            (action) => action(),
            onUndo: () => steps.add('undo'),
            onRedo: () => steps.add('redo'),
          ),
          child: const Focus(autofocus: true, child: SizedBox()),
        ),
      ),
    );
    await tester.pump();

    Future<void> press(
      LogicalKeyboardKey modifier, {
      bool shift = false,
    }) async {
      await tester.sendKeyDownEvent(modifier);
      if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyUpEvent(modifier);
    }

    await press(LogicalKeyboardKey.meta);
    await press(LogicalKeyboardKey.meta, shift: true);
    await press(LogicalKeyboardKey.control);
    await press(LogicalKeyboardKey.control, shift: true);

    expect(steps, ['undo', 'redo', 'undo', 'redo']);
    expect(maps.active?.canUndo, isFalse);
  });
}
