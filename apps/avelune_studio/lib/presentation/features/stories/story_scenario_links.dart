import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/stories/application/story_workspace_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_select.dart';

class StoryScenarioLinks extends StatelessWidget {
  const StoryScenarioLinks({
    super.key,
    required this.controller,
    required this.storyId,
    required this.chapterId,
    this.stepId,
  });
  final StoryWorkspaceController controller;
  final String storyId, chapterId;
  final String? stepId;
  StorylineAsset? get _story =>
      controller.stories.where((s) => s.id == storyId).firstOrNull;
  @override
  Widget build(BuildContext context) {
    final story = _story;
    if (story == null) return const SizedBox.shrink();
    final scenarios = controller.project.scenarios;
    final links = story.sceneLinks.where(
      (l) => l.chapterId == chapterId && l.stepId == stepId,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Résultats de scénarios',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        const StudioNotice(
          'Les scénarios historiques possèdent leurs propres résultats. Ils restent distincts des scènes de l’éditeur visuel.',
        ),
        for (final link in links) ...[
          const SizedBox(height: 12),
          Text(link.label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          StudioSelect(
            label: 'Scénario associé',
            value: link.sceneRef?.targetId,
            options: {for (final s in scenarios) s.id: '${s.name} · ${s.id}'},
            onChanged: (id) => _patch(
              link.id,
              (latest) => {
                'sceneRef': {'kind': 'scenario', 'targetId': id},
                'state': StorylineSceneLinkState.linkedScenario.name,
              },
            ),
          ),
          const SizedBox(height: 8),
          StudioSelect(
            label: 'Rôle du scénario',
            value: link.role.name,
            options: {
              for (final role in StorylineSceneLinkRole.values)
                role.name: _roleLabel(role),
            },
            onChanged: (role) => _patch(link.id, (_) => {'role': role}),
          ),
          ..._outcomes(link, scenarios),
          if (link.outcomeLinks.isNotEmpty)
            const StudioNotice(
              'Les effets déjà reliés sont conservés. Déconnectez-les dans le graphe avant de retirer cette association.',
            ),
          StudioButton(
            label: 'Retirer cette association',
            secondary: true,
            onPressed: link.outcomeLinks.isEmpty && !_referenced(story, link.id)
                ? () => _remove(link.id)
                : null,
          ),
        ],
        const SizedBox(height: 12),
        if (scenarios.isNotEmpty)
          StudioSelect(
            label: 'Associer un scénario existant',
            value: null,
            options: {for (final s in scenarios) s.id: '${s.name} · ${s.id}'},
            onChanged: _add,
          )
        else
          const StudioNotice(
            'Aucun scénario historique dans ce projet. Les scènes visuelles restent disponibles dans la section Scènes associées.',
          ),
      ],
    );
  }

  List<Widget> _outcomes(
    StorylineSceneLink link,
    List<ScenarioAsset> scenarios,
  ) {
    final scenario = scenarios
        .where((s) => s.id == link.sceneRef?.targetId)
        .firstOrNull;
    if (scenario == null) {
      return [
        const StudioNotice(
          'Référence absente : choisissez le scénario à utiliser. Les résultats et effets existants sont conservés.',
        ),
      ];
    }
    final ids = {...scenario.declaredOutcomes, ...link.expectedOutcomeIds};
    return [
      const SizedBox(height: 8),
      const Text('Résultats proposés sur le graphe'),
      for (final id in ids)
        CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(
            scenario.declaredOutcomes.contains(id)
                ? id
                : '$id · résultat absent',
          ),
          value: link.expectedOutcomeIds.contains(id),
          onChanged: (checked) => _patch(
            link.id,
            (latest) => {
              'expectedOutcomeIds': checked == true
                  ? {...latest.expectedOutcomeIds, id}.toList()
                  : latest.expectedOutcomeIds
                        .where((value) => value != id)
                        .toList(),
            },
          ),
        ),
      if (ids.isEmpty)
        const StudioNotice(
          'Ce scénario ne déclare aucun résultat exploitable.',
        ),
    ];
  }

  void _patch(
    String id,
    Map<String, dynamic> Function(StorylineSceneLink) fields,
  ) {
    final story = _story;
    final link = story?.sceneLinks.where((l) => l.id == id).firstOrNull;
    if (story == null || link == null) return;
    final next = StorylineSceneLink.fromJson({
      ...link.toJson(),
      ...fields(link),
    });
    controller.apply(
      updateStoryline(
        controller.project,
        storylineId: storyId,
        storyline: story.copyWith(
          sceneLinks: [
            for (final candidate in story.sceneLinks)
              candidate.id == id ? next : candidate,
          ],
        ),
      ),
    );
  }

  void _add(String id) {
    final story = _story;
    final scenario = controller.project.scenarios
        .where((s) => s.id == id)
        .firstOrNull;
    if (story == null ||
        scenario == null ||
        !story.chapters.any(
          (c) =>
              c.id == chapterId &&
              (stepId == null || c.steps.any((s) => s.id == stepId)),
        )) {
      return;
    }
    final link = StorylineSceneLink(
      id: controller.narrative.identity('scenario-link'),
      chapterId: chapterId,
      stepId: stepId,
      label: scenario.name,
      state: StorylineSceneLinkState.linkedScenario,
      role: StorylineSceneLinkRole.primary,
      sceneRef: StorylineSceneRef(
        kind: StorylineSceneRefKind.scenario,
        targetId: id,
      ),
      order:
          story.sceneLinks.fold<int>(
            -1,
            (max, link) => link.order > max ? link.order : max,
          ) +
          1,
      expectedOutcomeIds: scenario.declaredOutcomes,
    );
    controller.apply(
      updateStoryline(
        controller.project,
        storylineId: storyId,
        storyline: story.copyWith(sceneLinks: [...story.sceneLinks, link]),
      ),
    );
  }

  void _remove(String id) {
    final story = _story;
    final link = story?.sceneLinks.where((l) => l.id == id).firstOrNull;
    if (story == null ||
        link == null ||
        link.outcomeLinks.isNotEmpty ||
        _referenced(story, id)) {
      return;
    }
    controller.apply(
      updateStoryline(
        controller.project,
        storylineId: storyId,
        storyline: story.copyWith(
          sceneLinks: story.sceneLinks.where((l) => l.id != id).toList(),
        ),
      ),
    );
  }

  bool _referenced(StorylineAsset story, String id) => story.chapters.any(
    (c) =>
        c.directSceneLinkIds.contains(id) ||
        c.steps.any((s) => s.sceneLinkIds.contains(id)),
  );
  String _roleLabel(StorylineSceneLinkRole role) => switch (role) {
    StorylineSceneLinkRole.primary => 'Principal',
    StorylineSceneLinkRole.optional => 'Optionnel',
    StorylineSceneLinkRole.branch => 'Branche',
    StorylineSceneLinkRole.convergence => 'Convergence',
    StorylineSceneLinkRole.setup => 'Préparation',
    StorylineSceneLinkRole.payoff => 'Résolution',
  };
}
