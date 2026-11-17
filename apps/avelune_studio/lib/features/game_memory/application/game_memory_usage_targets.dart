import 'package:map_authoring/map_authoring_narrative.dart';
import 'package:map_core/map_core_domain.dart';

import '../domain/narrative_index_port.dart';

typedef GameMemoryUsageTarget = ({String? stepId, String title});

List<GameMemoryUsageTarget> gameMemoryStoryTargets(
  StorylineAsset story,
  String factId,
  NarrativeFactRole? role,
) {
  final index = buildNarrativeDependencyIndex(
    project: ProjectManifest(
      name: 'owner',
      maps: const [],
      tilesets: const [],
      storylines: [story],
    ),
  );
  final targets = <String?, GameMemoryUsageTarget>{};
  final stepPath = RegExp(r'\.chapters\[(\d+)\]\.steps\[(\d+)\]');
  final linkPath = RegExp(r'\.sceneLinks\[(\d+)\]');
  for (final usage in index.usages) {
    if (usage.target.kind != NarrativeDependencyTargetKind.fact ||
        usage.target.id != factId) {
      continue;
    }
    final actualRole = switch (CatalogNarrativeOwnerAnalysis.role(usage.path)) {
      'read' => NarrativeFactRole.read,
      'write' => NarrativeFactRole.write,
      _ => null,
    };
    if (actualRole != role) continue;
    StorylineStep? step;
    if (stepPath.firstMatch(usage.path) case final match?) {
      step = story.chapters[int.parse(match[1]!)].steps[int.parse(match[2]!)];
    } else if (linkPath.firstMatch(usage.path) case final match?) {
      final id = story.sceneLinks[int.parse(match[1]!)].stepId;
      step = story.chapters
          .expand((chapter) => chapter.steps)
          .where((step) => step.id == id)
          .firstOrNull;
    }
    final target = step == null
        ? (stepId: null, title: story.title)
        : (stepId: step.id, title: step.title);
    targets[target.stepId] = target;
  }
  return targets.values.toList();
}
