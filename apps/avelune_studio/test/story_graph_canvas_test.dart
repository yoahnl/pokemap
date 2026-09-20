import 'package:avelune_studio/presentation/features/stories/story_graph_geometry.dart';
import 'package:avelune_studio/presentation/features/stories/story_graph_painter.dart';
import 'package:avelune_studio/presentation/features/stories/story_view_state.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'support/story_canvas_test_harness.dart';

void main() {
  test(
    'pending outcome identity avoids another result and preserves source names',
    () {
      final initial = storyCanvasProject();
      final story = initial.storylines.first;
      final link = story.sceneLinks.single;
      final conflict = StorylineSceneLink.fromJson({
        ...link.toJson(),
        'expectedOutcomeIds': ['accepted'],
        'outcomeLinks': [
          {
            ...link.outcomeLinks.single.toJson(),
            'id': 'outcome-accepted',
            'outcomeId': 'other',
          },
        ],
      });
      final project = initial.copyWith(
        storylines: [
          story.copyWith(sceneLinks: [conflict]),
          initial.storylines.last,
        ],
      );
      final state = StoryViewState();
      addTearDown(state.dispose);
      final graph = StoryGraphGeometry(project, 'main', state);
      final source = graph.outcomeSources.values.singleWhere((s) => s.pending);
      expect(source.outcomeLinkId, 'outcome-accepted-2');
      expect(
        graph.nodes['outcome:main:link:outcome-accepted-2']!.label,
        'Rencontre · accepted',
      );
      final result = connectStorylineProgressionEdge(
        project,
        StorylineProgressionConnectRequest.outcomeEffect(
          storylineId: 'main',
          sceneLinkId: 'link',
          outcomeLinkId: source.outcomeLinkId,
          outcomeId: source.outcomeId,
          effectType: StorylineEffectType.activateStep,
          targetStepId: 'step1_1',
        ),
      );
      expect(
        result.disposition,
        StorylineProgressionMutationDisposition.applied,
      );
      expect(
        result.after.storylines.first.sceneLinks.single.outcomeLinks
            .singleWhere((o) => o.id == 'outcome-accepted'),
        conflict.outcomeLinks.single,
      );
      expect(
        result.after.storylines.first.sceneLinks.single.outcomeLinks
            .singleWhere((o) => o.outcomeId == 'accepted')
            .id,
        'outcome-accepted-2',
      );
    },
  );
  testWidgets('first declared outcome connects without a fabricated effect', (
    tester,
  ) async {
    final initial = storyCanvasProject();
    final original = initial.storylines.first;
    final source = StorylineSceneLink.fromJson({
      ...original.sceneLinks.single.toJson(),
      'outcomeLinks': <Object>[],
      'expectedOutcomeIds': ['accepted'],
    });
    final project = initial.copyWith(
      storylines: [
        original.copyWith(sceneLinks: [source]),
        initial.storylines.last,
      ],
    );
    final h = StoryCanvasTestHarness(project: project);
    await h.mount(tester);
    expect(h.project.storylines.first.sceneLinks.single.outcomeLinks, isEmpty);
    await h.connect(
      tester,
      'outcome:main:link:outcome-accepted',
      'step:step1_1',
      'Activer cette étape',
    );
    expect(h.requests.single.outcomeId, 'accepted');
    expect(
      h.results.single.disposition,
      StorylineProgressionMutationDisposition.applied,
    );
    final outcome =
        h.project.storylines.first.sceneLinks.single.outcomeLinks.single;
    expect(outcome.outcomeId, 'accepted');
    expect(outcome.effects, hasLength(1));
    expect(outcome.effects.single.type, StorylineEffectType.activateStep);
    expect(outcome.effects.single.targetId, 'step1_1');
    expect(h.results, hasLength(1));
  });
  testWidgets('outcome pointer uses exact second step after pan and zoom', (
    tester,
  ) async {
    final h = StoryCanvasTestHarness();
    await h.mount(tester);
    h.view.viewport.translate(const Offset(20, -15));
    h.view.viewport.zoomAt(.8, const Offset(400, 320));
    await tester.pump();
    await h.connect(
      tester,
      'outcome:main:link:result',
      'step:step1_1',
      'Terminer cette étape',
    );
    final request = h.requests.single;
    expect(request.storylineId, 'main');
    expect(request.sceneLinkId, 'link');
    expect(request.outcomeLinkId, 'result');
    expect(request.targetStepId, 'step1_1');
    expect(
      h.results.single.disposition,
      StorylineProgressionMutationDisposition.applied,
    );
    final edge = buildStorylineProgressionProjection(
      project: h.project,
      storylineId: 'main',
    ).edgesOfKind(StorylineProgressionEdgeKind.outcomeCompletesStep).single;
    expect(edge.toNodeId, 'step:step1_1');
    expect(edge.source.outcomeLinkId, 'result');
  });
  testWidgets('fact pointer chooses exact completion slot and false value', (
    tester,
  ) async {
    final h = StoryCanvasTestHarness();
    h.view.revealFact('fact');
    await h.mount(tester);
    await h.connect(tester, 'fact:fact', 'step:step1_0', 'Achèvement · faux');
    final request = h.requests.single;
    expect(request.chapterId, 'chapter1');
    expect(request.stepId, 'step1_0');
    expect(request.conditionSlot, StorylineProgressionConditionSlot.completion);
    expect(request.expectedValue, false);
    expect(
      h.results.single.disposition,
      StorylineProgressionMutationDisposition.applied,
    );
  });
  testWidgets(
    'secondary relationship keeps canonical owner outside displayed story',
    (tester) async {
      final h = StoryCanvasTestHarness();
      h.view.revealStory('side0');
      await h.mount(tester);
      await h.connect(
        tester,
        'storyline:side0',
        'storyline:main',
        'Nécessite cette histoire',
      );
      expect(h.requests.single.sourceStorylineId, 'side0');
      expect(h.requests.single.targetStorylineId, 'main');
      expect(h.project.storylines.first.relationships, isEmpty);
      expect(
        h.project.storylines.last.relationships.single.kind,
        StorylineRelationshipKind.requires,
      );
    },
  );
  testWidgets('pointer cancellation and empty drop have zero mutations', (
    tester,
  ) async {
    final h = StoryCanvasTestHarness();
    await h.mount(tester);
    final before = h.project;
    final start = tester.getCenter(
      find.byKey(const ValueKey('story-graph-output-outcome:main:link:result')),
    );
    final end = tester.getCenter(
      find.byKey(const ValueKey('story-graph-input-step:step1_1')),
    );
    final cancelled = await tester.startGesture(start);
    await cancelled.moveTo(end);
    await tester.pump();
    await cancelled.cancel();
    await tester.pump();
    final empty = await tester.startGesture(start);
    await empty.moveTo(const Offset(1100, 600));
    await empty.up();
    await tester.pumpAndSettle();
    expect(h.requests, isEmpty);
    expect(h.project, same(before));
  });
  testWidgets(
    'group drag and view undo preserve canonical order and document',
    (tester) async {
      final h = StoryCanvasTestHarness();
      await h.mount(tester);
      final before = h.project;
      await tester.drag(
        find.byKey(const ValueKey('story-graph-node-chapter:chapter0')),
        const Offset(80, 40),
      );
      await tester.pump();
      expect(h.view.positions.containsKey('chapter:chapter0'), isTrue);
      expect(h.view.canUndo, isTrue);
      expect(h.project, same(before));
      h.view.undo();
      await tester.pump();
      expect(h.view.positions, isEmpty);
      expect(h.view.canRedo, isTrue);
      h.view.redo();
      await tester.pump();
      expect(h.project, same(before));
      expect(h.requests, isEmpty);
    },
  );
  testWidgets('trackpad over chapter and text shortcuts never mutate story', (
    tester,
  ) async {
    final h = StoryCanvasTestHarness();
    await h.mount(tester, textField: true);
    final before = h.project;
    final center = tester.getCenter(
      find.byKey(const ValueKey('story-graph-node-chapter:chapter0')),
    );
    final gesture = await tester.startGesture(
      center,
      kind: PointerDeviceKind.trackpad,
    );
    await gesture.panZoomUpdate(center, pan: const Offset(25, 15), scale: 1.15);
    await tester.pump();
    await gesture.panZoomEnd();
    await tester.pump();
    expect(h.view.positions, isEmpty);
    await tester.enterText(
      find.byKey(const ValueKey('story-test-text')),
      'Titre',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    expect(h.project, same(before));
    expect(h.disconnects, 0);
    expect(h.requests, isEmpty);
  });
  testWidgets('curve hit testing resolves semantic edge away from its label', (
    tester,
  ) async {
    final h = StoryCanvasTestHarness();
    await h.mount(tester);
    await h.connect(
      tester,
      'outcome:main:link:result',
      'step:step1_1',
      'Activer cette étape',
    );
    final graph = StoryGraphGeometry(h.project, 'main', h.view);
    final edge = graph.edges.singleWhere(
      (e) => e.kind == StorylineProgressionEdgeKind.outcomeActivatesStep,
    );
    final path = storyGraphEdgePath(graph, h.view, h.view.positions, edge);
    final metric = path.computeMetrics().single;
    final point = metric.getTangentForOffset(metric.length * .27)!.position;
    expect(
      storyGraphEdgeAt(graph, h.view, h.view.positions, point)?.id,
      edge.id,
    );
  });
}
