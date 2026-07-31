import 'package:map_core/map_core.dart';

enum StorylineInspectionSeverity { error, warning, info }

final class StorylineInspectionDiagnostic {
  const StorylineInspectionDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    required this.storylineId,
    this.nodeId,
    this.edgeId,
  });

  final String code;
  final StorylineInspectionSeverity severity;
  final String message;
  final String storylineId;
  final String? nodeId;
  final String? edgeId;

  Map<String, Object?> toJson() => {
        'code': code,
        'severity': severity.name,
        'message': message,
        'storylineId': storylineId,
        if (nodeId != null) 'nodeId': nodeId,
        if (edgeId != null) 'edgeId': edgeId,
      };
}

final class StorylineInspectionReport {
  StorylineInspectionReport({
    required Iterable<StorylineInspectionDiagnostic> diagnostics,
    required Map<String, Map<String, Object?>> progression,
  })  : diagnostics = List.unmodifiable(diagnostics),
        progression = Map.unmodifiable(progression);

  final List<StorylineInspectionDiagnostic> diagnostics;
  final Map<String, Map<String, Object?>> progression;

  bool get canPublish => diagnostics.every(
        (item) => item.severity != StorylineInspectionSeverity.error,
      );

  Map<String, Object?> toJson() => {
        'canPublish': canPublish,
        'diagnostics': [for (final item in diagnostics) item.toJson()],
        'progression': progression,
      };
}

/// Read-only Storyline graph inspection backed by the canonical projection.
final class StorylineInspector {
  const StorylineInspector();

  StorylineInspectionReport inspect(ProjectManifest project) {
    final diagnostics = <StorylineInspectionDiagnostic>[];
    final progression = <String, Map<String, Object?>>{};
    for (final storyline in project.storylines) {
      final projection = buildStorylineProgressionProjection(
        project: project,
        storylineId: storyline.id,
      );
      for (final item in projection.diagnostics) {
        diagnostics.add(
          StorylineInspectionDiagnostic(
            code: item.code.name,
            severity: StorylineInspectionSeverity.error,
            message: item.message,
            storylineId: storyline.id,
            nodeId: item.nodeId,
            edgeId: item.edgeId,
          ),
        );
      }
      final unreachable = _unreachableStepIds(storyline, projection);
      for (final stepId in unreachable) {
        diagnostics.add(
          StorylineInspectionDiagnostic(
            code: 'unreachableStep',
            severity: StorylineInspectionSeverity.warning,
            message: 'The Step is not reachable from the first authored Step.',
            storylineId: storyline.id,
            nodeId: 'step:$stepId',
          ),
        );
      }
      progression[storyline.id] = {
        'status': storyline.status.name,
        'available': storyline.status == StorylineStatus.active,
        'chapterCount': storyline.chapters.length,
        'stepCount': storyline.chapters
            .fold<int>(0, (count, chapter) => count + chapter.steps.length),
        'edgeCount': projection.edges.length,
        'unreachableStepIds': unreachable,
        'completionPreview': {
          'hasCompletionConditions': storyline.chapters.any(
            (chapter) => chapter.steps.any(
              (step) => step.completionCondition != null,
            ),
          ),
          'requiresRuntimeState': true,
        },
      };
    }
    diagnostics.sort((left, right) {
      final story = left.storylineId.compareTo(right.storylineId);
      if (story != 0) return story;
      return left.code.compareTo(right.code);
    });
    return StorylineInspectionReport(
      diagnostics: diagnostics,
      progression: progression,
    );
  }
}

List<String> _unreachableStepIds(
  StorylineAsset storyline,
  StorylineProgressionProjection projection,
) {
  final chapters = storyline.chapters.toList()
    ..sort((left, right) {
      final order = left.order.compareTo(right.order);
      return order != 0 ? order : left.id.compareTo(right.id);
    });
  final firstChapterWithSteps = chapters.where((item) => item.steps.isNotEmpty);
  if (firstChapterWithSteps.isEmpty) return const [];
  final firstSteps = firstChapterWithSteps.first.steps.toList()
    ..sort((left, right) {
      final order = left.order.compareTo(right.order);
      return order != 0 ? order : left.id.compareTo(right.id);
    });
  final reachable = <String>{'step:${firstSteps.first.id}'};
  var changed = true;
  while (changed) {
    changed = false;
    for (final edge in projection.edges) {
      if (!reachable.contains(edge.fromNodeId) ||
          !edge.toNodeId.startsWith('step:')) {
        continue;
      }
      if (reachable.add(edge.toNodeId)) changed = true;
    }
  }
  final ids = <String>[
    for (final chapter in chapters)
      for (final step in chapter.steps)
        if (!reachable.contains('step:${step.id}')) step.id,
  ]..sort();
  return ids;
}
