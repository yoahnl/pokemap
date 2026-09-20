import 'dart:convert';
import 'package:avelune_studio/presentation/features/stories/story_graph_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'support/story_canvas_test_harness.dart';

void main() {
  testWidgets(
    '200 steps and 100 semantic links retain projection during viewport gestures',
    (tester) async {
      final project = storyCanvasProject(
        chapterCount: 20,
        stepsPerChapter: 10,
        volume: true,
      );
      final bytes = jsonEncode(project.toJson());
      final h = StoryCanvasTestHarness(project: project);
      final firstFrame = Stopwatch()..start();
      await h.mount(tester);
      firstFrame.stop();
      StoryGraphPainter painter() => tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((w) => w.painter)
          .whereType<StoryGraphPainter>()
          .single;
      final graph = painter().graph;
      expect(project.storylines, hasLength(10));
      expect(graph.steps, hasLength(20));
      expect(
        graph.nodes.values.where(
          (n) => n.kind == StorylineProgressionNodeKind.step,
        ),
        hasLength(200),
      );
      expect(
        graph.edges.where(
          (e) => e.kind == StorylineProgressionEdgeKind.entryCondition,
        ),
        hasLength(100),
      );
      var viewUpdates = 0;
      h.view.viewport.addListener(() => viewUpdates++);
      final gestures = Stopwatch()..start();
      for (var i = 0; i < 4; i++) {
        await tester.dragFrom(const Offset(1000, 250), const Offset(-60, 40));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('story-graph-zoom-in')));
        await tester.pump();
        expect(painter().graph, same(graph));
      }
      gestures.stop();
      expect(viewUpdates, greaterThanOrEqualTo(8));
      expect(h.project, same(project));
      expect(jsonEncode(h.project.toJson()), bytes);
      expect(h.requests, isEmpty);
      expect(h.results, isEmpty);
      expect(h.view.positions, isEmpty);
      expect(tester.takeException(), isNull);
      debugPrint(
        'UI07 volume stories=10 chapters=20 steps=200 semanticLinks=100 gestures=8 viewportUpdates=$viewUpdates projectionRebuilt=false documentMutations=0 firstFrameUs=${firstFrame.elapsedMicroseconds} gesturesUs=${gestures.elapsedMicroseconds}; no I/O adapter instantiated',
      );
    },
  );
}
