import '../diagnostics/scene_diagnostics.dart';
import '../diagnostics/storyline_scene_link_diagnostics.dart';
import '../models/project_manifest.dart';
import '../models/storyline_asset.dart';
import '../runtime/scene_runtime_plan_builder.dart';

final class StorylineStepSceneLinksReadModel {
  StorylineStepSceneLinksReadModel({
    required this.storylineId,
    required this.chapterId,
    required this.stepId,
    required List<StorylineStepSceneLinkView> linkedScenes,
    required List<StorylineStepScenePickerOption> availableScenes,
    required List<StorylineSceneLinkDiagnostic> diagnostics,
  })  : linkedScenes =
            List<StorylineStepSceneLinkView>.unmodifiable(linkedScenes),
        availableScenes =
            List<StorylineStepScenePickerOption>.unmodifiable(availableScenes),
        diagnostics =
            List<StorylineSceneLinkDiagnostic>.unmodifiable(diagnostics);

  static const authoringOnlyMessage =
      'Lien authoring/progression uniquement: le déclenchement runtime reste côté Event -> Scene.';

  final String storylineId;
  final String chapterId;
  final String stepId;
  final List<StorylineStepSceneLinkView> linkedScenes;
  final List<StorylineStepScenePickerOption> availableScenes;
  final List<StorylineSceneLinkDiagnostic> diagnostics;

  int get linkedSceneCount => linkedScenes.length;

  bool get hasMissingScene => linkedScenes.any((scene) => !scene.exists);

  String get authoringOnlyMessageText => authoringOnlyMessage;
}

final class StorylineStepSceneLinkView {
  const StorylineStepSceneLinkView({
    required this.sceneId,
    required this.label,
    required this.exists,
    required this.hasSceneErrors,
    required this.isRuntimeBuildable,
    required this.diagnostics,
  });

  final String sceneId;
  final String label;
  final bool exists;
  final bool hasSceneErrors;
  final bool isRuntimeBuildable;
  final List<StorylineSceneLinkDiagnostic> diagnostics;
}

final class StorylineStepScenePickerOption {
  const StorylineStepScenePickerOption({
    required this.sceneId,
    required this.label,
    required this.description,
    required this.isLinked,
  });

  final String sceneId;
  final String label;
  final String description;
  final bool isLinked;
}

StorylineStepSceneLinksReadModel buildStorylineStepSceneLinksReadModel({
  required ProjectManifest project,
  required StorylineAsset storyline,
  required StorylineChapter chapter,
  required StorylineStep step,
}) {
  final sceneById = {
    for (final scene in project.scenes) scene.id: scene,
  };
  final diagnostics = diagnoseStorylineSceneLinks(project: project)
      .diagnostics
      .where((diagnostic) =>
          diagnostic.storylineId == storyline.id &&
          diagnostic.chapterId == chapter.id &&
          diagnostic.stepId == step.id)
      .toList(growable: false);

  final linkedScenes = [
    for (final sceneId in step.sceneLinkIds)
      () {
        final scene = sceneById[sceneId];
        final sceneDiagnostics = scene == null ? null : diagnoseScene(scene);
        final planResult = scene == null ? null : buildSceneRuntimePlan(scene);
        return StorylineStepSceneLinkView(
          sceneId: sceneId,
          label: scene?.name ?? 'Scene introuvable',
          exists: scene != null,
          hasSceneErrors: sceneDiagnostics?.hasErrors ?? false,
          isRuntimeBuildable: planResult?.canBuild ?? false,
          diagnostics: List<StorylineSceneLinkDiagnostic>.unmodifiable(
            diagnostics.where((diagnostic) => diagnostic.sceneId == sceneId),
          ),
        );
      }(),
  ];

  final linkedSceneIds = step.sceneLinkIds.toSet();
  final availableScenes = [
    for (final scene in project.scenes)
      StorylineStepScenePickerOption(
        sceneId: scene.id,
        label: scene.name,
        description: scene.description ?? scene.id,
        isLinked: linkedSceneIds.contains(scene.id),
      ),
  ]..sort((left, right) {
      final label = left.label.compareTo(right.label);
      if (label != 0) return label;
      return left.sceneId.compareTo(right.sceneId);
    });

  return StorylineStepSceneLinksReadModel(
    storylineId: storyline.id,
    chapterId: chapter.id,
    stepId: step.id,
    linkedScenes: linkedScenes,
    availableScenes: availableScenes,
    diagnostics: diagnostics,
  );
}
