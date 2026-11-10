import 'dart:convert';

import 'package:avelune_studio/features/stories/application/story_progression_sources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'support/story_graph_project_fixture.dart';

void main() {
  test(
    '200 steps and 100 semantic links survive read-only source projection',
    () {
      final project = storyCanvasProject(
        chapterCount: 20,
        stepsPerChapter: 10,
        volume: true,
      );
      final before = jsonEncode(project.toJson());
      final sources = StoryProgressionSources(project, 'main');
      expect(project.storylines, hasLength(10));
      expect(project.storylines.first.chapters, hasLength(20));
      expect(
        sources.nodes.values.where(
          (node) => node.kind == StorylineProgressionNodeKind.step,
        ),
        hasLength(200),
      );
      expect(
        sources.projection.edgesOfKind(
          StorylineProgressionEdgeKind.entryCondition,
        ),
        hasLength(100),
      );
      expect(jsonEncode(project.toJson()), before);
    },
  );
}
