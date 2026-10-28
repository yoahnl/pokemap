import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/project_surf/application/project_surf_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'project_surf_condition_editor.dart';

class ProjectSurfPanel extends StatefulWidget {
  const ProjectSurfPanel({super.key, required this.owner, this.loadItems, this.showActivation = true});
  final ProjectSurfController owner;
  final bool showActivation;
  final Future<Map<String, String>> Function()? loadItems;
  @override
  State<ProjectSurfPanel> createState() => _ProjectSurfPanelState();
}

class _ProjectSurfPanelState extends State<ProjectSurfPanel> {
  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  Future<void> _open() async {
    await widget.owner.open();
    if (mounted &&
        widget.owner.preview.value.accessMode ==
            ProjectSurfAccessMode.condition) {
      await widget.owner.loadReferences();
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.owner,
    builder: (context, _) {
      final owner = widget.owner;
      final configuration = owner.preview.value;
      final available = !owner.loading && !owner.saving && owner.saved != null;
      return StudioPanel(
        title: 'Surf',
        icon: Icons.waves,
        children: [
          const Text(
            'Traversez les zones d’eau avec les animations Surf du personnage. Réglez ici les conditions d’accès pour tout le projet.',
          ),
          const SizedBox(height: 12),
          if (widget.showActivation) StudioChoice(
            key: const ValueKey('surf-enabled'),
            label: 'Activer Surf',
            subtitle: configuration.enabled
                ? 'Le joueur peut entrer dans une zone d’eau navigable.'
                : 'Le joueur reste sur la terre ferme.',
            selected: configuration.enabled,
            onTap: available
                ? () => owner.change(enabled: !configuration.enabled)
                : null,
          ),
          StudioChoice(
            key: const ValueKey('surf-requires-move'),
            label: 'Exiger un Pokémon connaissant Surf',
            subtitle:
                'Un Pokémon de l’équipe doit être apte à utiliser la capacité.',
            selected: configuration.requiresKnownMove,
            onTap: available
                ? () => owner.change(
                    requiresKnownMove: !configuration.requiresKnownMove,
                  )
                : null,
          ),
          const SizedBox(height: 12),
          StudioDraftField(
            key: const ValueKey('surf-speed'),
            label: 'Vitesse de Surf (cases par seconde)',
            value:
                owner.speedInput ??
                configuration.speedCellsPerSecond.toString(),
            errorText: owner.speedInputError,
            helperText: 'La course ne modifie pas cette vitesse sur l’eau.',
            enabled: available,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: owner.editSpeed,
          ),
          const SizedBox(height: 12),
          StudioSelect(
            key: const ValueKey('surf-access'),
            label: 'Autorisation d’utiliser Surf',
            value: configuration.accessMode.name,
            options: const {
              'progression': 'Déblocage par la progression',
              'always': 'Toujours autorisé',
              'condition': 'Selon une condition',
            },
            onChanged: available
                ? (value) {
                    owner.change(
                      accessMode: ProjectSurfAccessMode.values.byName(value),
                    );
                    if (value == 'condition') unawaited(owner.loadReferences());
                  }
                : null,
          ),
          const SizedBox(height: 8),
          Text(switch (configuration.accessMode) {
            ProjectSurfAccessMode.progression =>
              'La progression du jeu doit avoir débloqué Surf.',
            ProjectSurfAccessMode.always =>
              'Aucun déblocage de progression supplémentaire n’est demandé.',
            ProjectSurfAccessMode.condition => 'La condition choisie doit être remplie avant d’entrer dans l’eau.',
          }),
          if (configuration.accessMode == ProjectSurfAccessMode.condition) ...[
            const SizedBox(height: 12),
            ProjectSurfConditionEditor(
              owner: owner,
              loadItems: widget.loadItems,
              enabled: available,
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StudioButton(
                key: const ValueKey('save-project-surf'),
                label: owner.saving ? 'Enregistrement…' : 'Enregistrer Surf',
                icon: Icons.save_outlined,
                loading: owner.saving,
                onPressed:
                    available &&
                        owner.dirty &&
                        owner.inputError == null &&
                        owner.speedInputError == null &&
                        (configuration.accessMode !=
                                ProjectSurfAccessMode.condition ||
                            configuration.condition != null)
                    ? owner.save
                    : null,
              ),
              StudioButton(
                label: 'Annuler les modifications',
                secondary: true,
                onPressed: available && owner.dirty ? owner.discard : null,
              ),
              StudioButton(
                label: 'Annuler',
                icon: Icons.undo,
                secondary: true,
                onPressed: available && owner.canUndo ? owner.undo : null,
              ),
              StudioButton(
                label: 'Rétablir',
                icon: Icons.redo,
                secondary: true,
                onPressed: available && owner.canRedo ? owner.redo : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            owner.dirty
                ? 'Réglages Surf non enregistrés'
                : 'Réglages Surf enregistrés',
          ),
          if (owner.loading) const Text('Chargement des réglages Surf…'),
          if (owner.error case final error?)
            Text(
              error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      );
    },
  );
}
