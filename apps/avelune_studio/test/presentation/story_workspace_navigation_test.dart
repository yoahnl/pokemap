import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_name_field.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'story_memory_harness.dart';

Future<void> section(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(ValueKey('story-section-$name')));
  await settleMemory(tester);
}

void main() {
  testWidgets(
    'a new project session starts without the previous selection or query',
    (tester) async {
      await openMemoryStudio(tester, memoryIndex());
      await openHistoire(tester);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('memory-fact-search')),
          matching: find.byType(TextField),
        ),
        'Pièces',
      );
      await settleMemory(tester);
      await section(tester, 'scenes');
      await tester.tap(find.byKey(const ValueKey('story-scene-gate')));
      await settleMemory(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      await settleMemory(tester);
      await openMemoryStudio(
        tester,
        memoryIndex(),
        session: const ProjectSession(
          sessionId: 'second',
          name: 'Autre projet',
          directoryPath: '/fixture-other',
          storage: ProjectSessionStorage.workingCatalog,
        ),
      );
      await openHistoire(tester);
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const ValueKey('memory-fact-search')),
                matching: find.byType(TextField),
              ),
            )
            .controller!
            .text,
        isEmpty,
      );
      expect(find.text('Rencontre'), findsOneWidget);
      await section(tester, 'scenes');
      expect(
        tester
            .widget<StudioChoice>(
              find.byKey(const ValueKey('story-scene-gate')),
            )
            .selected,
        isFalse,
      );
      expect(find.byKey(const ValueKey('story-return')), findsNothing);
    },
  );

  testWidgets(
    'a renamed created fact keeps a usable selection across undo and redo',
    (tester) async {
      await openMemoryStudio(tester, memoryIndex());
      await openHistoire(tester);
      await tester.tap(find.byKey(const ValueKey('memory-new-fact')));
      await settleMemory(tester);
      await tester.enterText(
        find.byKey(const ValueKey('memory-new-fact-name')),
        'Ancien',
      );
      await settleMemory(tester);
      await tester.tap(find.byKey(const ValueKey('memory-new-fact-create')));
      await settleMemory(tester);
      final field = find.descendant(
        of: find.byType(MapBuilderNameField),
        matching: find.byType(TextField),
      );
      expect(field, findsOneWidget);
      await tester.enterText(field, 'Nouveau');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settleMemory(tester);
      await tester.tap(find.widgetWithIcon(IconButton, Icons.undo).first);
      await settleMemory(tester);
      expect(tester.widget<TextField>(field).controller!.text, 'Ancien');
      await tester.tap(find.widgetWithIcon(IconButton, Icons.redo).first);
      await settleMemory(tester);
      expect(tester.widget<TextField>(field).controller!.text, 'Nouveau');
      await tester.tap(find.widgetWithIcon(IconButton, Icons.undo).first);
      await settleMemory(tester);
      await tester.tap(find.widgetWithIcon(IconButton, Icons.undo).first);
      await settleMemory(tester);
      expect(
        find.byKey(const ValueKey('memory-fact-unavailable')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.redo).first,
            )
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets(
    'selecting another fact commits the field before its owner changes',
    (tester) async {
      await openMemoryStudio(tester, memoryIndex());
      await openHistoire(tester);
      await tester.tap(find.byKey(const ValueKey('memory-fact-coins')));
      await settleMemory(tester);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('memory-fact-name-coins')),
          matching: find.byType(TextField),
        ),
        'Or saisi',
      );
      await tester.tap(find.byKey(const ValueKey('memory-fact-met')));
      await settleMemory(tester);
      expect(
        tester
            .widget<StudioChoice>(
              find.byKey(const ValueKey('memory-fact-coins')),
            )
            .label,
        'Or saisi',
      );
    },
  );

  testWidgets(
    'changing section preserves the selected scene without rereading titles',
    (tester) async {
      final index = memoryIndex();
      await openMemoryStudio(tester, index);
      await openTrame(tester);
      await section(tester, 'scenes');
      await tester.tap(find.byKey(const ValueKey('story-scene-gate')));
      await settleMemory(tester);
      final requests = index.titleRequests.length;
      await section(tester, 'dialogues');
      await section(tester, 'scenes');
      expect(
        tester
            .widget<StudioChoice>(
              find.byKey(const ValueKey('story-scene-gate')),
            )
            .selected,
        isTrue,
      );
      expect(find.byKey(const ValueKey('story-scene-open')), findsOneWidget);
      expect(index.titleRequests.length, requests);
      expect(index.documentRequests, isEmpty);
    },
  );

  testWidgets(
    'fact list scroll and unfinished creation survive a section round trip',
    (tester) async {
      await openMemoryStudio(tester, memoryIndex(unrelated: 100));
      await openHistoire(tester);
      final list = find.byKey(const ValueKey('memory-fact-list'));
      await tester.drag(list, const Offset(0, -900));
      await tester.pumpAndSettle();
      final scroll = tester.state<ScrollableState>(
        find.descendant(of: list, matching: find.byType(Scrollable)),
      );
      final before = scroll.position.pixels;
      expect(before, greaterThan(0));
      await tester.tap(find.byKey(const ValueKey('memory-new-fact')));
      await settleMemory(tester);
      await tester.enterText(
        find.byKey(const ValueKey('memory-new-fact-name')),
        'Clef en cours',
      );
      await section(tester, 'scenes');
      await section(tester, 'facts');
      expect(
        find.byKey(const ValueKey('memory-new-fact-name')),
        findsOneWidget,
      );
      expect(find.text('Clef en cours'), findsOneWidget);
      expect(
        tester
            .state<ScrollableState>(
              find.descendant(of: list, matching: find.byType(Scrollable)),
            )
            .position
            .pixels,
        before,
      );
    },
  );

  testWidgets(
    'a fact edit is undoable in Histoire and another selected fact blocks it',
    (tester) async {
      await openMemoryStudio(tester, memoryIndex());
      await openHistoire(tester);
      await tester.tap(find.byKey(const ValueKey('memory-fact-coins')));
      await settleMemory(tester);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('memory-fact-name-coins')),
          matching: find.byType(TextField),
        ),
        'Or',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settleMemory(tester);
      final undo = find.widgetWithIcon(IconButton, Icons.undo);
      expect(tester.widget<IconButton>(undo).onPressed, isNotNull);
      await tester.tap(find.byKey(const ValueKey('memory-fact-met')));
      await settleMemory(tester);
      expect(tester.widget<IconButton>(undo).onPressed, isNull);
      expect(
        find.byTooltip(
          'La prochaine modification concerne un autre contexte. Retrouvez-le pour l’annuler ou la rétablir.',
        ),
        findsOneWidget,
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await settleMemory(tester);
      expect(
        tester
            .widget<StudioChoice>(
              find.byKey(const ValueKey('memory-fact-coins')),
            )
            .label,
        'Or',
      );
      await tester.tap(find.byKey(const ValueKey('memory-fact-coins')));
      await settleMemory(tester);
      await tester.tap(undo);
      await settleMemory(tester);
      expect(
        tester
            .widget<StudioChoice>(
              find.byKey(const ValueKey('memory-fact-coins')),
            )
            .label,
        'Pièces',
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await settleMemory(tester);
      expect(
        tester
            .widget<StudioChoice>(
              find.byKey(const ValueKey('memory-fact-coins')),
            )
            .label,
        'Or',
      );
    },
  );
}
