import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/stories/application/story_workspace_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_select.dart';

class StorySceneLinks extends StatelessWidget {
  const StorySceneLinks({
    super.key,
    required this.controller,
    required this.storyId,
    required this.chapterId,
    required this.step,
    required this.onOpenScene,
  });
  final StoryWorkspaceController controller;
  final String storyId, chapterId;
  final StorylineStep step;
  final Future<String?> Function(String) onOpenScene;

  @override
  Widget build(BuildContext context) {
    final scenes = controller.project.scenes;
    final available = scenes.where((s) => !step.sceneLinkIds.contains(s.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Scènes associées',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        for (final id in step.sceneLinkIds) ...[
          Text(
            scenes.where((s) => s.id == id).firstOrNull?.name ??
                'Scène absente : $id',
          ),
          Wrap(
            spacing: 8,
            children: [
              StudioButton(
                label: 'Modifier la scène',
                secondary: true,
                onPressed: scenes.any((s) => s.id == id)
                    ? () async {
                        FocusManager.instance.primaryFocus?.unfocus();
                        final error = await onOpenScene(id);
                        if (error != null && context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(error)));
                        }
                      }
                    : null,
              ),
              StudioButton(
                label: 'Dissocier',
                secondary: true,
                onPressed: () => controller.mutate(
                  (p) => unlinkSceneFromStorylineStep(
                    p,
                    storylineId: storyId,
                    chapterId: chapterId,
                    stepId: step.id,
                    sceneId: id,
                  ).updatedProject,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        if (available.isNotEmpty)
          StudioSelect(
            label: 'Associer une scène',
            value: null,
            options: {
              for (final scene in available)
                scene.id: '${scene.name} · ${scene.id}',
            },
            onChanged: (id) => controller.mutate(
              (p) => linkSceneToStorylineStep(
                p,
                storylineId: storyId,
                chapterId: chapterId,
                stepId: step.id,
                sceneId: id,
              ).updatedProject,
            ),
          ),
        if (scenes.isEmpty)
          const StudioNotice(
            'Aucune scène dans ce projet. Créez-en une dans l’éditeur de scène.',
          ),
        const SizedBox(height: 10),
        const StudioNotice(
          'Une association ouvre la scène complète. Elle ne déclenche pas la scène en jeu et ne crée pas d’effet de résultat.',
        ),
      ],
    );
  }
}
