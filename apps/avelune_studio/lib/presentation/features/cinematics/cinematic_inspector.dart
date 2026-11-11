import '../project_settings/spatial_visual_controls.dart';

import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/cinematics/application/cinematic_workspace_controller.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'cinematic_commit_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_tabs.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/feedback/studio_badge.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import 'cinematic_labels.dart';

import 'package:avelune_studio/features/cinematics/application/cinematic_actor_choices.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_camera_options.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_inspector_rules.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_map_model.dart';

import 'cinematic_view_state.dart';
import '../../../features/cinematics/application/cinematic_actor_labels.dart';

export '../../../features/cinematics/application/cinematic_actor_labels.dart';

part 'cinematic_inspector_actors.dart';
part 'cinematic_inspector_step.dart';
part 'cinematic_inspector_commands.dart';
part 'cinematic_inspector_camera.dart';
part 'cinematic_inspector_animation.dart';

class CinematicInspector extends StatelessWidget {
  const CinematicInspector({
    super.key,
    required this.controller,
    required this.view,
    required this.changed,
    required this.model,
    required this.onDialogue,
    required this.onLocate,
  });
  final CinematicWorkspaceController controller;
  final CinematicViewState view;
  final CinematicMapModel? model;
  final VoidCallback changed;
  final ValueChanged<String> onDialogue;
  final Future<String?> Function(String) onLocate;

  bool _edit(
    CinematicAsset owner,
    CinematicAsset Function(CinematicAsset) transform,
  ) {
    if (controller.active?.asset.id != owner.id) return false;
    final accepted = controller.editFromInspector(
      owner.id,
      transform,
      view.inputs,
    );
    changed();
    return accepted;
  }

  ProjectManifest _project(CinematicAsset asset) =>
      controller.projectWith(asset);

  void _mode(CinematicMapMode mode) {
    FocusManager.instance.primaryFocus?.unfocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    controller.transport.stop();
    view.mode = mode;
    changed();
  }

  Widget _spaced(List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final child in children) ...[child, const SizedBox(height: 12)],
    ],
  );

  @override
  Widget build(BuildContext context) {
    final session = controller.active;
    if (session == null) return const SizedBox.shrink();
    final asset = session.asset;
    view.inputs = controller.inputsFor(asset.id, initial: view.inputs);
    final step = asset.timeline.steps
        .where((s) => s.id == view.stepId)
        .firstOrNull;
    const tabs = {
      'properties': 'Propriétés',
      'actors': 'Acteurs',
      'document': 'Séquence',
    };
    final selectedTab = cinematicInspectorTab(view.inspectorTab);
    return StudioPanel(
      compact: true,
      children: [
        StudioTabs(
          items: tabs,
          selected: selectedTab,
          onChanged: (tab) {
            FocusManager.instance.primaryFocus?.unfocus();
            FocusManager.instance.applyFocusChangesIfNeeded();
            view.inspectorTab = tab;
            changed();
          },
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: _spaced([
              if (session.readOnlyReason != null) Text(session.readOnlyReason!),
              if (selectedTab == 'actors')
                ..._actorFields(asset)
              else if (selectedTab == 'document') ...[
                ..._documentFields(asset),
                ..._sequenceSteps(context, asset),
              ] else if (step == null) ...[
                const StudioNotice(
                  key: ValueKey('cinematic-no-action-guidance'),
                  'Aucune action sélectionnée. Sélectionnez une action dans la timeline ou dans l’onglet Séquence pour la régler ici. En attendant, voici les réglages de la cinématique.',
                ),
                ..._documentFields(asset),
              ] else
                ..._stepFields(asset, step),
            ]),
          ),
        ),
      ],
    );
  }

  List<Widget> _documentFields(CinematicAsset asset) => [
    const StudioBadge(
      'Cinématique sur carte',
      tone: StudioTone.info,
      icon: Icons.movie_outlined,
    ),
    CinematicCommitField(
      inputs: controller.inputsFor(asset.id),
      changed: changed,
      key: ValueKey('cinematic-title-${asset.id}'),
      label: 'Nom de la cinématique',
      alwaysCommit: true,
      value: asset.title,
      tryCommit: (value) => _edit(asset, (a) => a.copyWith(title: value)),
    ),
    StudioSelect(
      label: 'Carte de contexte',
      value: asset.mapId ?? '',
      options: {
        '': 'Sans carte',
        for (final map in controller.project.maps)
          map.id: '${map.name} · ${map.id}',
      },
      onChanged: (id) => controller.setMap(id.isEmpty ? null : id),
    ),
    if (asset.mapId != null)
      StudioButton(
        label: 'Ouvrir cette carte',
        secondary: true,
        icon: Icons.map_outlined,
        onPressed: () async {
          final id = asset.id, mapId = asset.mapId!;
          final problem = await onLocate(mapId);
          if (controller.active?.asset.id == id && problem != null) {
            view.actionError = problem;
            changed();
          }
        },
      ),
    StudioSelect(
      label: 'À la fin',
      value: asset.actorCompletionPolicy.name,
      options: const {
        'keepFinal': 'Conserver la pose',
        'restoreInitial': 'Restaurer la pose de départ',
      },
      onChanged: (value) => _edit(
        asset,
        (a) => setCinematicActorCompletionPolicy(
          _project(a),
          cinematicId: a.id,
          policy: CinematicActorCompletionPolicy.values.byName(value),
        ).cinematic,
      ),
    ),
    const Text(
      'La pose comprend la position et l’orientation. Une annulation restaure toujours la pose de départ.',
    ),
    if (cinematicCrossingEditable(controller.project))
      StudioToggleRow(
        label: 'Autoriser le croisement des personnages en mouvement',
        description: 'Concerne uniquement les personnages qui se déplacent simultanément. Les obstacles et les positions finales restent vérifiés.',
        value: asset.allowMobileActorCrossing,
        onChanged: (value) =>
            _edit(asset, (a) => a.copyWith(allowMobileActorCrossing: value)),
      ),
    CinematicCommitField(
      inputs: controller.inputsFor(asset.id),
      changed: changed,
      key: ValueKey('cinematic-notes-${asset.id}'),
      label: 'Notes de mise en scène',
      value: asset.notes ?? '',
      maxLines: 4,
      tryCommit: (value) => _edit(asset, (a) => a.copyWith(notes: value)),
    ),
    Text(
      '${asset.timeline.steps.length} étapes · ${asset.timeline.steps.any((step) => step.parallelGroupId != null) ? 'groupes simultanés et étapes séquentielles' : 'lecture séquentielle'}',
    ),
    const Text(
      'Sélectionnez un bloc pour régler son action, ou un acteur pour préparer sa pose.',
    ),
  ];

  List<Widget> _sequenceSteps(BuildContext context, CinematicAsset asset) {
    final steps = asset.timeline.steps;
    return [
      Text(
        'Actions de la séquence',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      if (steps.isEmpty)
        const Text('Aucune action dans cette séquence.')
      else
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, step) in steps.indexed)
              StudioChoice(
                key: ValueKey('cinematic-sequence-step-${step.id}'),
                label: '${index + 1}. ${cinematicActionLabel(step.kind)}',
                subtitle: [
                  if (step.durationMs case final duration?)
                    cinematicTime(duration),
                  if (step.parallelGroupId != null) 'simultanée',
                ].join(' · '),
                selected: view.stepId == step.id,
                onTap: () {
                  view.selection
                    ..clear()
                    ..add(step.id);
                  view.inspectorTab = 'properties';
                  changed();
                },
              ),
          ],
        ),
    ];
  }
}
