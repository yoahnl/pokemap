import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/cinematics/application/cinematic_workspace_controller.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_tabs.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/feedback/studio_badge.dart';
import 'cinematic_action_palette.dart';
import 'cinematic_labels.dart';
import 'cinematic_map_model.dart';
import 'cinematic_view_state.dart';

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
    required this.onAdd,
    this.previewContent,
  });
  final CinematicWorkspaceController controller;
  final CinematicViewState view;
  final CinematicMapModel? model;
  final VoidCallback changed;
  final ValueChanged<String> onDialogue;
  final Future<String?> Function(String) onLocate;
  final ValueChanged<CinematicTimelineStepKind> onAdd;
  final Widget? previewContent;

  bool _edit(
    CinematicAsset owner,
    CinematicAsset Function(CinematicAsset) transform,
  ) {
    if (controller.active?.asset.id != owner.id) return false;
    final accepted = controller.edit((current) {
      final next = transform(current), context = current.stageContext;
      final result = next.stageContext;
      if (context == null || result == null || context.manualPaths.isEmpty) {
        return next;
      }
      return next.copyWith(
        stageContext: CinematicStageContext(
          backdropMode: result.backdropMode,
          actorBindings: result.actorBindings,
          actorAppearanceBindings: result.actorAppearanceBindings,
          initialPlacements: result.initialPlacements,
          movementTargetBindings: result.movementTargetBindings,
          stagePoints: result.stagePoints,
          manualPaths: context.manualPaths,
        ),
      );
    });
    if (!accepted) {
      view.error = view.inspectorError = controller.error;
    } else if (view.error == view.inspectorError) {
      view.error = view.inspectorError = null;
    }
    changed();
    return accepted;
  }

  ProjectManifest _project(CinematicAsset asset) => controller.project.copyWith(
    cinematics: [
      for (final c in controller.project.cinematics)
        if (c.id != asset.id) c,
      asset,
    ],
  );

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
    final step = asset.timeline.steps
        .where((s) => s.id == view.stepId)
        .firstOrNull;
    return StudioPanel(
      compact: true,
      children: [
        StudioTabs(
          items: const {
            'properties': 'Propriétés',
            'actors': 'Acteurs',
            'document': 'Séquence',
            'preview': 'Aperçu',
          },
          selected: view.inspectorTab,
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
              if (view.inspectorTab == 'preview')
                previewContent ?? const Text('Aperçu en préparation.')
              else if (view.inspectorTab == 'actors')
                ..._actorFields(asset)
              else if (view.inspectorTab == 'document' || step == null)
                ..._documentFields(asset)
              else
                ..._stepFields(asset, step),
              const Divider(),
              Text(
                'Palette d’actions',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              CinematicActionPalette(onAdd: onAdd),
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
    StudioCommitField(
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
            view.error = problem;
            changed();
          }
        },
      ),
    StudioCommitField(
      key: ValueKey('cinematic-notes-${asset.id}'),
      label: 'Notes de mise en scène',
      value: asset.notes ?? '',
      maxLines: 4,
      tryCommit: (value) => _edit(asset, (a) => a.copyWith(notes: value)),
    ),
    Text('${asset.timeline.steps.length} étapes · lecture séquentielle'),
    const Text(
      'Sélectionnez un bloc pour régler son action, ou un acteur pour préparer sa pose.',
    ),
  ];
}
