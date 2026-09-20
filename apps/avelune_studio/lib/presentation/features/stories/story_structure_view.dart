import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/stories/application/story_workspace_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'story_labels.dart';
import 'story_view_state.dart';

class StoryStructureView extends StatelessWidget {
  const StoryStructureView({
    super.key,
    required this.controller,
    required this.story,
    required this.scroll,
    required this.selection,
    required this.onSelect,
    required this.onAddStep,
    required this.onGraph,
  });
  final StoryWorkspaceController controller;
  final StorylineAsset story;
  final ScrollController scroll;
  final StoryGraphSelection? selection;
  final ValueChanged<StoryGraphSelection> onSelect;
  final ValueChanged<String> onAddStep;
  final VoidCallback onGraph;

  @override
  Widget build(BuildContext context) {
    final chapters = orderedStoryChapters(story);
    final projection = buildStorylineProgressionProjection(
      project: controller.project,
      storylineId: story.id,
    );
    void select(String id) {
      final node = projection.nodes.where((n) => n.id == id).firstOrNull;
      if (node != null) onSelect(StoryGraphSelection.node(node));
    }

    return ListView(
      controller: scroll,
      padding: const EdgeInsets.all(16),
      children: [
        const StudioNotice(
          'Ordre d’auteur : ce classement ne crée aucune dépendance et ne décrit pas la progression d’une partie.',
        ),
        const SizedBox(height: 12),
        for (var ci = 0; ci < chapters.length; ci++) ...[
          StudioPanel(
            children: [
              StudioChoice(
                label: '${ci + 1}. ${chapters[ci].title}',
                subtitle:
                    '${chapters[ci].steps.length} étapes · ${chapters[ci].id}',
                selected: selection?.id == 'chapter:${chapters[ci].id}',
                onTap: () => select('chapter:${chapters[ci].id}'),
              ),
              Wrap(
                spacing: 8,
                children: [
                  StudioButton(
                    label: 'Monter le chapitre',
                    secondary: true,
                    onPressed: ci == 0 ? null : () => _chapters(ci, -1),
                  ),
                  StudioButton(
                    label: 'Descendre le chapitre',
                    secondary: true,
                    onPressed: ci == chapters.length - 1
                        ? null
                        : () => _chapters(ci, 1),
                  ),
                  StudioButton(
                    label: 'Ajouter une étape',
                    secondary: true,
                    onPressed: () => onAddStep(chapters[ci].id),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._steps(chapters[ci], select),
            ],
          ),
          const SizedBox(height: 14),
        ],
        StudioButton(
          label: 'Retrouver la sélection dans le graphe',
          onPressed: onGraph,
        ),
      ],
    );
  }

  List<Widget> _steps(StorylineChapter chapter, ValueChanged<String> select) {
    final steps = orderedStorySteps(chapter);
    return [
      for (var i = 0; i < steps.length; i++)
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StudioChoice(
                label: '${i + 1}. ${steps[i].title}',
                subtitle:
                    '${steps[i].sceneLinkIds.length} scènes associées · ${steps[i].id}',
                selected: selection?.id == 'step:${steps[i].id}',
                onTap: () => select('step:${steps[i].id}'),
              ),
              Wrap(
                spacing: 8,
                children: [
                  StudioButton(
                    label: 'Monter l’étape',
                    secondary: true,
                    onPressed: i == 0
                        ? null
                        : () => _stepsOrder(chapter, i, -1),
                  ),
                  StudioButton(
                    label: 'Descendre l’étape',
                    secondary: true,
                    onPressed: i == steps.length - 1
                        ? null
                        : () => _stepsOrder(chapter, i, 1),
                  ),
                ],
              ),
            ],
          ),
        ),
    ];
  }

  void _chapters(int index, int delta) {
    final ids = orderedStoryChapters(story).map((c) => c.id).toList();
    ids.insert(index + delta, ids.removeAt(index));
    controller.apply(
      reorderStorylineChapters(
        controller.project,
        storylineId: story.id,
        orderedChapterIds: ids,
      ),
    );
  }

  void _stepsOrder(StorylineChapter chapter, int index, int delta) {
    final ids = orderedStorySteps(chapter).map((s) => s.id).toList();
    ids.insert(index + delta, ids.removeAt(index));
    controller.apply(
      reorderStorylineSteps(
        controller.project,
        storylineId: story.id,
        chapterId: chapter.id,
        orderedStepIds: ids,
      ),
    );
  }
}
