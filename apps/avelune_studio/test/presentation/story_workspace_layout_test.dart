import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../storyline/storyline_fakes.dart';
import '../verification/verification_fakes.dart';
import 'story_memory_harness.dart';

const _sections = [
  'trame',
  'behaviours',
  'scenes',
  'dialogues',
  'facts',
  'rules',
  'verification',
];

void main() {
  testWidgets('Histoire exposes seven keyboard-accessible sections', (
    tester,
  ) async {
    final verification = FakeVerificationPort();
    await openMemoryStudio(
      tester,
      memoryIndex(),
      storylines: FakeStorylineRead(),
      verification: verification,
    );
    await openTrame(tester);
    final navigation = find.byKey(const ValueKey('story-navigation'));
    expect(navigation, findsOneWidget);
    expect(
      find.descendant(
        of: navigation,
        matching: find.byType(StudioNavigationEntry),
      ),
      findsNWidgets(7),
    );
    expect(find.text('Cinématiques'), findsNothing);
    final first = find.byKey(const ValueKey('story-section-trame'));
    for (var step = 0; step < 30 && !_focusedWithin(tester, first); step++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await settleMemory(tester);
    }
    for (final section in _sections) {
      final entry = find.byKey(ValueKey('story-section-$section'));
      expect(_focusedWithin(tester, entry), isTrue, reason: section);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settleMemory(tester);
      expect(tester.widget<StudioNavigationEntry>(entry).selected, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await settleMemory(tester);
    }
    expect(tester.takeException(), isNull);
    expect(verification.analyses, 0);
    expect(verification.dialogueReads, isEmpty);
  });

  testWidgets('the Trame header opens Verification with the keyboard', (
    tester,
  ) async {
    final verification = FakeVerificationPort();
    await openMemoryStudio(
      tester,
      memoryIndex(),
      storylines: FakeStorylineRead(),
      verification: verification,
    );
    await openTrame(tester);
    final header = find.byKey(const ValueKey('story-section-header'));
    final action = find.descendant(
      of: header,
      matching: find.widgetWithText(StudioButton, 'Vérifier'),
    );
    expect(action, findsOneWidget);
    for (var step = 0; step < 50 && !_focusedWithin(tester, action); step++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await settleMemory(tester);
    }
    expect(_focusedWithin(tester, action), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settleMemory(tester);
    final selected = find.byKey(const ValueKey('story-section-verification'));
    expect(tester.widget<StudioNavigationEntry>(selected).selected, isTrue);
    expect(find.byKey(const ValueKey('verification-start')), findsOneWidget);
    expect(verification.analyses, 0);
    expect(action, findsNothing);
  });

  testWidgets(
    'opening Trame does not load other narrative directories or documents',
    (tester) async {
      final index = memoryIndex();
      final stories = FakeStorylineRead();
      await openMemoryStudio(tester, index, storylines: stories);
      await openTrame(tester);
      expect(stories.outlines, 1);
      expect(stories.storylineReads, 0);
      expect(stories.proposals, 0);
      expect(index.titleRequests, isEmpty);
      expect(index.documentRequests, isEmpty);
      await tester.tap(find.byKey(const ValueKey('story-section-scenes')));
      await settleMemory(tester);
      expect(index.titleRequests, [NarrativeTitleKind.scenes]);
      expect(index.documentRequests, isEmpty);
      expect(find.text('Ouverture de la porte'), findsOneWidget);
    },
  );

  for (final size in [
    const Size(1280, 720),
    const Size(1280, 800),
    const Size(1440, 900),
    const Size(1920, 1080),
  ]) {
    testWidgets('the workspace fits ${size.width} by ${size.height}', (
      tester,
    ) async {
      await openMemoryStudio(
        tester,
        memoryIndex(),
        storylines: FakeStorylineRead(stories: [mainStoryline()]),
      );
      tester.view.physicalSize = size;
      await openTrame(tester);
      expect(find.byKey(const ValueKey('story-navigation')), findsOneWidget);
      expect(find.byKey(const ValueKey('story-inspector')), findsOneWidget);
      for (final section in _sections) {
        final entry = find.byKey(ValueKey('story-section-$section'));
        await tester.ensureVisible(entry);
        await tester.tap(entry);
        await settleMemory(tester);
        expect(tester.widget<StudioNavigationEntry>(entry).selected, isTrue);
        final error = tester.takeException();
        if (error is FlutterError) {
          debugPrint(
            error.diagnostics.map((item) => item.toStringDeep()).join('\n'),
          );
          for (final render
              in tester.allRenderObjects.whereType<RenderFlex>()) {
            if (render.toString().contains('OVERFLOWING')) {
              debugPrint('Overflow owner: ${render.debugCreator}');
              debugPrint(render.toStringShallow());
            }
          }
        }
        expect(error, isNull, reason: section);
      }
    });
  }
}

bool _focusedWithin(WidgetTester tester, Finder finder) {
  final target = tester.element(finder);
  final focused = FocusManager.instance.primaryFocus?.context;
  var found = identical(focused, target);
  focused?.visitAncestorElements((element) {
    found |= identical(element, target);
    return !found;
  });
  return found;
}
