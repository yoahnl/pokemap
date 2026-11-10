import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/project_cs/application/project_cs_controller.dart';
import '../../../features/project_settings/application/project_settings_drafts.dart';
import '../../../features/project_cs/application/field_ability_support.dart';

export '../../../features/project_cs/application/field_ability_support.dart';
import '../../../features/project_surf/application/project_surf_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'project_surf_panel.dart';

class ProjectCsPanel extends StatefulWidget {
  const ProjectCsPanel({
    super.key,
    required this.owner,
    required this.surf,
    required this.settings,
    this.loadItems,
    this.showActions = true,
  });
  final bool showActions;
  final ProjectCsController owner;
  final ProjectSurfController surf;
  final ProjectSettings settings;
  final Future<Map<String, String>> Function()? loadItems;
  @override
  State<ProjectCsPanel> createState() => _ProjectCsPanelState();
}

class _ProjectCsPanelState extends State<ProjectCsPanel> {
  String _examined = 'surf';

  Widget _summary(ProjectSettings settings, ProjectSurfSettings surf) {
    final ability = ProjectFieldAbilityRegistry.find(_examined)!;
    final enabled = isProjectFieldAbilityIdEnabled(settings, ability.id);
    final lines = <String>[
      enabled ? 'Autorisée dans ce jeu.' : 'Non autorisée dans ce jeu.',
      if (ability.id == 'surf') ...[
        surf.requiresKnownMove
            ? 'Connaissance : un Pokémon de l’équipe doit connaître Surf.'
            : 'Connaissance : aucun Pokémon n’est exigé.',
        switch (surf.accessMode) {
          ProjectSurfAccessMode.progression =>
            'Débloquée pour le joueur : par la progression du jeu.',
          ProjectSurfAccessMode.always =>
            'Débloquée pour le joueur : toujours, sans condition.',
          ProjectSurfAccessMode.condition =>
            surf.condition == null
                ? 'Débloquée pour le joueur : selon une condition, encore à '
                      'choisir.'
                : 'Débloquée pour le joueur : selon une condition.',
        },
        'Réglages détaillés : panneau Surf ci-dessous.',
      ] else if (ability.activationOnly)
        'Activation seule : l’exécution de cette capacité sur la carte '
            'n’existe pas encore. L’activer ne débloque rien en jeu.'
      else
        'Déblocage pour le joueur : décidé par la progression du jeu (badges, '
            'objets ou événements). Cette capacité n’a pas d’autre réglage.',
    ];
    return StudioPanel(
      key: ValueKey('cs-summary-${ability.id}'),
      title: 'Résumé · ${ability.label}',
      icon: Icons.fact_check_outlined,
      children: [for (final line in lines) Text(line)],
    );
  }

  @override
  void initState() {
    super.initState();
    unawaited(widget.owner.open());
    unawaited(widget.surf.open());
  }

  Future<void> save() async {
    await FieldAbilitySettingsDraft(widget.owner, widget.surf).save();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([widget.owner, widget.surf]),
    builder: (context, _) {
      final owner = widget.owner, surf = widget.surf;
      final settings = widget.settings.copyWith(
        surf: surf.preview.value,
        fieldAbilities: owner.preview.value,
      );
      final enabled =
          !owner.loading &&
          !owner.saving &&
          !surf.loading &&
          !surf.saving &&
          owner.saved != null &&
          surf.saved != null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StudioPanel(
            title: 'CS du projet',
            icon: Icons.explore_outlined,
            children: [
              const Text(
                'Choisissez les capacités de terrain autorisées dans ce jeu. Leur activation ne les débloque pas pour le joueur : les badges, la progression et les conditions restent applicables.',
              ),
              const SizedBox(height: 12),
              for (final ability in ProjectFieldAbilityRegistry.entries)
                StudioChoice(
                  key: ValueKey('cs-${ability.id}'),
                  label: ability.label,
                  trailing: Text(
                    fieldAbilitySupport(ability, settings.dimension),
                    key: ValueKey('cs-support-${ability.id}'),
                  ),
                  selected: isProjectFieldAbilityIdEnabled(
                    settings,
                    ability.id,
                  ),
                  subtitle: ability.activationOnly
                      ? 'Activation du projet · mécanique à implémenter en 2D et 3D'
                      : settings.dimension == ProjectDimension.twoD
                      ? 'Mécanique disponible en 2D · déblocage du joueur séparé'
                      : ability.id == 'surf'
                      ? 'Disponible dans le profil 3D · déblocage du joueur séparé'
                      : 'Activation du projet · mécanique non certifiée dans ce profil 3D',
                  onTap: enabled
                      ? () {
                          final next = !isProjectFieldAbilityIdEnabled(
                            settings,
                            ability.id,
                          );
                          if (ability.id == 'surf') {
                            surf.change(enabled: next);
                          } else {
                            owner.setEnabledId(ability.id, next);
                          }
                        }
                      : null,
                ),
              const SizedBox(height: 12),
              if (widget.showActions)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StudioButton(
                      key: const ValueKey('save-project-cs'),
                      label: 'Enregistrer les CS',
                      icon: Icons.save_outlined,
                      onPressed:
                          enabled &&
                              surf.inputError == null &&
                              surf.speedInputError == null &&
                              (owner.dirty || surf.dirty)
                          ? save
                          : null,
                    ),
                    StudioButton(
                      label: 'Annuler les modifications des CS',
                      secondary: true,
                      onPressed: enabled && (owner.dirty || surf.dirty)
                          ? () {
                              owner.discard();
                              surf.discard();
                            }
                          : null,
                    ),
                    StudioButton(
                      label: 'Annuler une activation',
                      icon: Icons.undo,
                      secondary: true,
                      onPressed: enabled && owner.canUndo ? owner.undo : null,
                    ),
                    StudioButton(
                      label: 'Rétablir une activation',
                      icon: Icons.redo,
                      secondary: true,
                      onPressed: enabled && owner.canRedo ? owner.redo : null,
                    ),
                  ],
                ),
              if (owner.error case final error?)
                Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
          const SizedBox(height: 12),
          StudioSelect(
            key: const ValueKey('cs-examined'),
            label: 'Capacité à examiner',
            value: _examined,
            options: {
              for (final ability in ProjectFieldAbilityRegistry.entries)
                ability.id: ability.label,
            },
            onChanged: (value) => setState(() => _examined = value),
          ),
          const SizedBox(height: 8),
          _summary(settings, surf.preview.value),
          const SizedBox(height: 12),
          ProjectSurfPanel(
            owner: surf,
            showActivation: false,
            showActions: widget.showActions,
            loadItems: widget.loadItems,
          ),
        ],
      );
    },
  );
}
