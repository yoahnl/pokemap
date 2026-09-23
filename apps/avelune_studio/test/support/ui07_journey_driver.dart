import 'package:avelune_studio/presentation/features/stories/story_graph_canvas.dart';
import 'package:avelune_studio/presentation/features/stories/story_graph_geometry.dart';
import 'package:avelune_studio/presentation/features/stories/story_graph_painter.dart';
import 'package:avelune_studio/presentation/features/stories/story_inspector.dart';
import 'package:avelune_studio/presentation/features/stories/story_progression_page.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_primary_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

StoryProgressionPage storyPage(WidgetTester tester) =>
    tester.widget<StoryProgressionPage>(find.byType(StoryProgressionPage));

Future<void> openStoryPage(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(StudioPrimaryNavigation),
      matching: find.byTooltip('Histoire'),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Voir tous les documents').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Histoires et progression').first);
  await tester.pumpAndSettle();
}

Future<void> storyNode(WidgetTester tester, String id) async {
  await tester.tap(find.byKey(ValueKey('story-graph-node-$id')));
  await tester.pumpAndSettle();
}

Future<void> storyInspectorAction(WidgetTester tester, String label) async {
  final action = find.descendant(
    of: find.byType(StoryInspector),
    matching: find.text(label),
  );
  await tester.scrollUntilVisible(
    action,
    160,
    scrollable: find
        .descendant(
          of: find.byType(StoryInspector),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.tap(action);
  await tester.pumpAndSettle();
}

Future<void> storyEdge(
  WidgetTester tester,
  StorylineProgressionEdge edge,
) async {
  final canvas = tester.widget<StoryGraphCanvas>(find.byType(StoryGraphCanvas));
  final graph = StoryGraphGeometry(
    canvas.project,
    canvas.storyId,
    canvas.viewState,
  );
  final state = canvas.viewState;
  final path = storyGraphEdgePath(graph, state, state.positions, edge);
  final surface = find.byKey(const ValueKey('story-graph-pan-surface'));
  for (final metric in path.computeMetrics()) {
    for (
      var distance = metric.length * .15;
      distance < metric.length * .85;
      distance += 8
    ) {
      final point = metric.getTangentForOffset(distance)!.position;
      final world = state.viewport.localToWorld(point);
      if (!(Offset.zero & tester.getSize(surface)).contains(point)) continue;
      if (graph.nodes.keys.any(
        (id) => graph.rect(id, state.positions).inflate(8).contains(world),
      )) {
        continue;
      }
      if (storyGraphEdgeAt(graph, state, state.positions, point)?.id !=
          edge.id) {
        continue;
      }
      await tester.tapAt(tester.getTopLeft(surface) + point);
      await tester.pumpAndSettle();
      expect(
        storyPage(tester).views
            .forStory(storyPage(tester).controller.workspace, canvas.storyId)
            .selection
            ?.id,
        edge.id,
      );
      return;
    }
  }
  throw StateError('No exposed hit point for ${edge.id}');
}

Future<void> storyNameDialog(WidgetTester tester, String name) async {
  await tester.enterText(
    find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    ),
    name,
  );
  await tester.pump();
  await tester.tap(
    find.descendant(of: find.byType(AlertDialog), matching: find.text('Créer')),
  );
  await tester.pumpAndSettle();
}
