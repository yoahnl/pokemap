import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_groups.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/features/scenes/domain/scene_document.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avelune_studio/presentation/features/story/story_page.dart';

import '../game_memory/game_memory_fakes.dart';
import '../storyline/storyline_widget_support.dart';
import 'story_memory_harness.dart';

FakeNarrativeIndex routesIndex() =>
    memoryIndex()
      ..documents['gate'] = SceneDocument(
        scene: trameProject.scenes.last,
        dialogues: const [],
        missingDialogueIds: const [],
        events: [trameRecords.last],
        maps: const {},
        mapReads: 0,
      );

void main() {
  testWidgets(
    'closing a retained scene by keyboard removes its visible tooltip',
    (tester) async {
      final index = routesIndex();
      await openTrameStudio(tester, index: index);
      tester.widget<StoryPage>(find.byType(StoryPage)).openScene!('gate', null);
      await settleMemory(tester);
      final tooltip = find.byWidgetPredicate(
        (widget) => widget is Tooltip && widget.message == 'Fermer la scène',
      );
      expect(tooltip, findsOneWidget);
      final tooltipState = tester.state<TooltipState>(tooltip);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(
        tester.getCenter(find.byKey(const ValueKey('scene-focus-close'))),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Fermer la scène'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump(const Duration(seconds: 2));
      await settleMemory(tester);
      expect(find.byKey(const ValueKey('scene-focus')), findsNothing);
      expect(find.text('Fermer la scène'), findsNothing);
      expect(tooltipState.ensureTooltipVisible(), isFalse);
    },
  );

  testWidgets(
    'a scene deleted during loading returns to its known parent without discarding a draft',
    (tester) async {
      final gate = Completer<SceneDocument>();
      final index = routesIndex()..documentLoader = (_) => gate.future;
      await openMemoryStudio(tester, index);
      await openHistoire(tester);
      await tester.tap(find.byKey(const ValueKey('memory-new-fact')));
      await settleMemory(tester);
      await tester.enterText(
        find.byKey(const ValueKey('memory-new-fact-name')),
        'Brouillon gardé',
      );
      await settleMemory(tester);
      await tester.tap(find.byKey(const ValueKey('memory-new-fact-create')));
      await settleMemory(tester);
      expect(find.byKey(const ValueKey('memory-fact-discard')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('story-section-scenes')));
      await settleMemory(tester);
      await tester.tap(find.byKey(const ValueKey('story-scene-gate')));
      await settleMemory(tester);
      await tester.tap(find.byKey(const ValueKey('story-scene-open')));
      await settleMemory(tester);
      index.titlesByKind[NarrativeTitleKind.scenes] = const [];
      gate.completeError(StateError('Scène retirée'));
      await settleMemory(tester);
      expect(find.byKey(const ValueKey('scene-focus')), findsNothing);
      expect(
        find.text(
          'Cet élément n’est plus disponible. Votre brouillon est conservé.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('story-section-facts')));
      await settleMemory(tester);
      expect(find.text('Brouillon gardé'), findsWidgets);
    },
  );

  testWidgets('an older scene load cannot replace a newer target', (
    tester,
  ) async {
    final first = Completer<SceneDocument>();
    final second = Completer<SceneDocument>();
    final index = routesIndex()
      ..documentLoader = (id) => id == 'gate' ? first.future : second.future;
    await openTrameStudio(tester, index: index);
    final open = tester.widget<StoryPage>(find.byType(StoryPage)).openScene!;
    open('gate', null);
    await settleMemory(tester);
    open('talk', null);
    await settleMemory(tester);
    second.complete(
      SceneDocument(
        scene: trameProject.scenes.first,
        dialogues: const [],
        missingDialogueIds: const [],
        events: const [],
        maps: const {},
        mapReads: 0,
      ),
    );
    await settleMemory(tester);
    expect(
      find.byKey(const ValueKey('scene-focus-graph-talk')),
      findsOneWidget,
    );
    first.complete(index.documents['gate']!);
    await settleMemory(tester);
    expect(
      find.byKey(const ValueKey('scene-focus-graph-talk')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('scene-focus-graph-gate')), findsNothing);
  });

  testWidgets(
    'a nested scene and map round trip restores the graph and the plot selection',
    (tester) async {
      final index = routesIndex();
      await openTrameStudio(tester, index: index);
      await tester.tap(find.byKey(const ValueKey('trame-milestone-meet')));
      await settleMemory(tester);
      await tester.tap(find.byKey(const ValueKey('story-section-scenes')));
      await settleMemory(tester);
      await tester.tap(find.byKey(const ValueKey('story-scene-gate')));
      await settleMemory(tester);
      await tester.tap(find.byKey(const ValueKey('story-scene-open')));
      await settleMemory(tester);
      final graph = tester.state<SceneGraphCanvasState>(
        find.byType(SceneGraphCanvas),
      );
      graph.show('end');
      await settleMemory(tester);
      final launcher = find.byKey(
        ValueKey('scene-focus-open-behaviour-${trameRecords.last.id}'),
      );
      await tester.ensureVisible(launcher);
      await settleMemory(tester);
      await tester.tap(launcher);
      await settleMemory(tester);
      expect(find.byKey(const ValueKey('scene-focus')), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settleMemory(tester);
      expect(find.byKey(const ValueKey('scene-focus')), findsNothing);
      expect(
        find.byKey(const ValueKey('map-story-inspector-map:a')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('story-return')));
      await settleMemory(tester);
      expect(
        tester.state<SceneGraphCanvasState>(find.byType(SceneGraphCanvas)),
        same(graph),
      );
      expect(graph.selection, {'end'});
      await tester.tap(find.byKey(const ValueKey('scene-focus-close')));
      await settleMemory(tester);
      expect(
        tester
            .widget<StudioChoice>(
              find.byKey(const ValueKey('story-scene-gate')),
            )
            .selected,
        isTrue,
      );
      await tester.tap(find.byKey(const ValueKey('story-section-trame')));
      await settleMemory(tester);
      expect(
        tester
            .widget<StudioChoice>(
              find.byKey(const ValueKey('trame-milestone-meet')),
            )
            .selected,
        isTrue,
      );
      expect(index.documentRequests, ['gate']);
    },
  );

  testWidgets(
    'a behaviour destination offers an explicit return with its query and grouping intact',
    (tester) async {
      final index = memoryIndex();
      await openMemoryStudio(tester, index);
      await openWholeGame(tester);
      await tester.tap(find.text('Par état'));
      await settleMemory(tester);
      final search = find.descendant(
        of: find.byKey(const ValueKey('behaviours-search')),
        matching: find.byType(TextField),
      );
      await tester.enterText(search, 'guide');
      await settleMemory(tester);
      await tester.tap(find.text('Parler au guide'));
      await settleMemory(tester);
      expect(find.byKey(const ValueKey('studio-story')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('story-return')));
      await settleMemory(tester);
      expect(tester.widget<TextField>(search).controller!.text, 'guide');
      expect(
        tester
            .widget<SegmentedButton<GameBehaviourGrouping>>(
              find.byKey(const ValueKey('behaviours-grouping')),
            )
            .selected,
        {GameBehaviourGrouping.fact},
      );
      expect(find.byKey(const ValueKey('behaviours-view')), findsOneWidget);
      expect(index.documentRequests, isEmpty);
    },
  );
}
