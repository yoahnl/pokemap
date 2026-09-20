import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/stories/application/story_workspace_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'story_document_commands.dart';
import 'story_metadata_fields.dart';
import 'story_relation_details.dart';
import 'story_scene_links.dart';
import 'story_scenario_links.dart';
import 'story_reload_dialog.dart';
import 'story_view_state.dart';

class StoryInspector extends StatelessWidget {
  const StoryInspector({
    super.key,
    required this.controller,
    required this.selection,
    required this.onStructure,
    required this.onOpenScene,
    required this.onAddStep,
  });
  final StoryWorkspaceController controller;
  final StoryGraphSelection? selection;
  final VoidCallback onStructure;
  final Future<String?> Function(String) onOpenScene;
  final ValueChanged<String> onAddStep;

  @override
  Widget build(BuildContext context) {
    final active = controller.active!;
    final project = controller.project;
    final projection = buildStorylineProgressionProjection(
      project: project,
      storylineId: active.id,
    );
    final edgeId = selection?.edge?.id;
    final edge = projection.edges.where((e) => e.id == edgeId).firstOrNull;
    final node = selection?.node;
    final story =
        controller.stories
            .where((s) => s.id == node?.storylineId)
            .firstOrNull ??
        active;
    final chapter = story.chapters
        .where((c) => c.id == node?.chapterId)
        .firstOrNull;
    final step = chapter?.steps.where((s) => s.id == node?.stepId).firstOrNull;
    final missing =
        node != null &&
        (node.isMissing ||
            (node.kind == StorylineProgressionNodeKind.storyline &&
                !controller.stories.any((s) => s.id == node.canonicalId)) ||
            (node.chapterId != null && chapter == null) ||
            (node.stepId != null && step == null));
    if (missing || (edgeId != null && edge == null)) {
      return StudioPanel(
        title: 'Sélection indisponible',
        children: [
          const StudioNotice(
            'Cette référence a disparu ou a été supprimée. Les autres documents sont conservés.',
          ),
          SelectableText(node?.canonicalId ?? edgeId!),
        ],
      );
    }
    final editable =
        node == null ||
        {
          StorylineProgressionNodeKind.storyline,
          StorylineProgressionNodeKind.chapter,
          StorylineProgressionNodeKind.step,
        }.contains(node.kind);
    final commands = StoryDocumentCommands(controller);
    return StudioPanel(
      title: 'Inspecteur',
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (edge != null)
                  StoryRelationDetails(
                    project: project,
                    projection: projection,
                    edge: edge,
                    onDisconnect: () => controller.disconnect(edge.id),
                    onStructure: onStructure,
                  )
                else if (!editable) ...[
                  Text(
                    node.label,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 14),
                  const StudioNotice(
                    'Cette donnée provient du catalogue du projet. Utilisez son port pour la relier à une étape ; le catalogue source est conservé.',
                  ),
                  SelectableText(node.canonicalId),
                ] else ...[
                  Text(
                    step != null
                        ? 'Étape'
                        : chapter != null
                        ? 'Chapitre'
                        : 'Histoire',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  StoryMetadataFields(
                    identity: '${story.id}/${chapter?.id}/${step?.id}',
                    title: step?.title ?? chapter?.title ?? story.title,
                    description: step != null
                        ? step.description
                        : chapter != null
                        ? chapter.description
                        : story.description,
                    notes: step != null
                        ? step.authorNotes
                        : chapter != null
                        ? chapter.authorNotes
                        : story.authorNotes,
                    status: step != null
                        ? step.status
                        : chapter != null
                        ? chapter.status
                        : story.status,
                    type: chapter == null ? story.type : null,
                    onCommit: (field, value) => commands.metadata(
                      story.id,
                      chapter?.id,
                      step?.id,
                      field,
                      value,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (step != null) ...[
                    Text(
                      'Conditions de progression',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Entrée : ${storyConditionText(step.entryCondition, project)}',
                    ),
                    Text(
                      'Achèvement : ${storyConditionText(step.completionCondition, project)}',
                    ),
                    if (step.expectedOutcomeIds.isNotEmpty)
                      Text(
                        'Résultats attendus : ${step.expectedOutcomeIds.join(', ')}',
                      ),
                    const SizedBox(height: 20),
                    StorySceneLinks(
                      controller: controller,
                      storyId: story.id,
                      chapterId: chapter!.id,
                      step: step,
                      onOpenScene: onOpenScene,
                    ),
                  ],
                  if (chapter != null && step == null)
                    StudioButton(
                      label: 'Ajouter une étape',
                      onPressed: () => onAddStep(chapter.id),
                    ),
                  if (chapter != null) ...[
                    const SizedBox(height: 20),
                    StoryScenarioLinks(
                      controller: controller,
                      storyId: story.id,
                      chapterId: chapter.id,
                      stepId: step?.id,
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (chapter == null) ...[
                    StudioButton(
                      label: 'Recharger cette histoire',
                      secondary: true,
                      onPressed: controller.busy
                          ? null
                          : () => reloadStory(context, controller, story.id),
                    ),
                    const SizedBox(height: 8),
                  ],
                  StudioButton(
                    label: 'Dupliquer',
                    secondary: true,
                    onPressed: () =>
                        commands.duplicate(story.id, chapter?.id, step?.id),
                  ),
                  const SizedBox(height: 8),
                  StudioButton(
                    label: step != null
                        ? 'Supprimer cette étape'
                        : chapter != null
                        ? 'Supprimer ce chapitre'
                        : 'Supprimer cette histoire',
                    secondary: true,
                    onPressed: () =>
                        commands.remove(story.id, chapter?.id, step?.id),
                  ),
                  const SizedBox(height: 12),
                  const StudioNotice(
                    'La suppression respecte les références existantes. Annuler restaure le document avant enregistrement.',
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    'Identifiant : ${step?.id ?? chapter?.id ?? story.id}',
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
