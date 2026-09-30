import 'package:flutter/material.dart';
import 'package:map_authoring/map_authoring_project_creation.dart';
import '../../../features/project_creation/application/project_creation_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_choice_card.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../../theme/studio_tokens.dart';
import 'project_creation_progress.dart';

class ProjectCreationSteps extends StatelessWidget {
  const ProjectCreationSteps({
    super.key,
    required this.controller,
    required this.chooseParent,
  });
  final ProjectCreationController controller;
  final Future<void> Function() chooseParent;

  @override
  Widget build(BuildContext context) {
    final state = controller;
    final playable = state.template == ProjectCreationTemplate.playable;
    Widget field(String label, String value, ValueChanged<String> changed) =>
        StudioDraftField(
          key: ValueKey(label),
          label: label,
          value: value,
          onChanged: changed,
          errorText:
              state.step == 0 &&
                  state.errorField ==
                      (label == 'Nom du projet' ? 'name' : 'folderName')
              ? state.error
              : null,
        );
    Widget intro(String title, String text) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(text),
        const SizedBox(height: 24),
      ],
    );
    return switch (state.step) {
      0 => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          intro(
            'Informations du projet',
            'Donnez un nom à votre projet et choisissez le nom de son dossier.',
          ),
          field('Nom du projet', state.name, state.setName),
          const SizedBox(height: 24),
          field('Nom du dossier', state.folderName, state.setFolder),
          const SizedBox(height: 8),
          const Text('Suggéré automatiquement. Vous pouvez le personnaliser.'),
        ],
      ),
      1 => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          intro(
            'Choisissez un modèle',
            'Une aventure prête à explorer, ou une base à construire à votre rythme.',
          ),
          LayoutBuilder(
            builder: (context, bounds) {
              Widget card(
                bool selected,
                ProjectCreationTemplate template,
                String title,
                String description,
                IconData icon,
              ) => StudioChoiceCard(
                title: title,
                description: description,
                icon: icon,
                selected: selected,
                onPressed: () =>
                    state.changePreview(() => state.template = template),
              );
              final cards = [
                card(
                  playable,
                  ProjectCreationTemplate.playable,
                  'Petit projet jouable',
                  'Une clairière, un sol, un personnage et un départ configuré.\n'
                      'Ressources originales incluses. Prêt à explorer dans le Player.',
                  Icons.landscape_outlined,
                ),
                card(
                  !playable,
                  ProjectCreationTemplate.empty,
                  'Projet vide',
                  'Un manifeste et une structure propres, sans carte ni personnage.\n'
                      'À compléter avant de jouer.',
                  Icons.grid_on_outlined,
                ),
              ];
              if (bounds.maxWidth < 550) {
                return Column(
                  children: [cards[0], const SizedBox(height: 12), cards[1]],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[1]),
                ],
              );
            },
          ),
        ],
      ),
      2 => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          intro(
            'Paramètres du projet',
            'Configurez les bases de votre aventure.',
          ),
          const Text(
            'Taille des cases',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Dimensions d’une case en pixels dans les cartes et les ressources du projet.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final size in [16, 32, 48])
                SizedBox(
                  width: 180,
                  child: StudioChoiceCard(
                    key: ValueKey('creation-grid-$size'),
                    title: '$size × $size px',
                    description: 'Pixels par case',
                    icon: Icons.grid_4x4,
                    selected: state.tileSize == size,
                    onPressed: () =>
                        state.changePreview(() => state.tileSize = size),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          StudioPanel(
            compact: true,
            title: 'Options',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  playable ? Icons.check_circle : Icons.remove_circle_outline,
                ),
                title: const Text('Inclure un personnage de base'),
                subtitle: Text(
                  playable
                      ? 'Inclus et requis pour ce modèle jouable.'
                      : 'Aucun personnage ni point de départ dans le projet vide.',
                ),
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.lock_outline),
                title: Text('Activer les Pokémon — indisponible'),
                subtitle: Text(
                  'L’amorçage des catalogues et d’une équipe valide n’est pas '
                  'encore proposé par ce modèle. Exploration sans Pokémon.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ExpansionTile(
            key: const ValueKey('creation-map-settings'),
            title: const Text('Réglages de la carte'),
            initiallyExpanded: true,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 220,
                    child: field(
                      'Largeur en cases',
                      state.width,
                      (value) => state.changePreview(() => state.width = value),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: field(
                      'Hauteur en cases',
                      state.height,
                      (value) =>
                          state.changePreview(() => state.height = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${playable ? 'Carte initiale' : 'Défauts des futures cartes'} : '
                '${int.tryParse(state.width) ?? 0} × ${int.tryParse(state.height) ?? 0} cases · '
                '${(int.tryParse(state.width) ?? 0) * state.tileSize} × '
                '${(int.tryParse(state.height) ?? 0) * state.tileSize} px, hors zoom.',
              ),
              const SizedBox(height: 12),
            ],
          ),
        ],
      ),
      3 => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          intro(
            'Choisissez l’emplacement',
            'Le projet sera créé dans un nouveau sous-dossier. Aucun dossier existant ne sera remplacé.',
          ),
          const Text(
            'Dossier parent',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SelectionArea(
            child: Text(
              state.parentPath.isEmpty
                  ? 'Aucun dossier choisi'
                  : state.parentPath,
            ),
          ),
          const SizedBox(height: 12),
          StudioButton(
            key: const ValueKey('creation-choose-parent'),
            label: 'Parcourir…',
            icon: Icons.folder_open,
            secondary: true,
            onPressed: state.checking ? null : chooseParent,
          ),
          const SizedBox(height: 24),
          StudioPanel(
            title: 'Votre nouveau projet',
            children: [
              Text(state.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                '${playable ? 'Petit projet jouable' : 'Projet vide'} · '
                '${state.tileSize} × ${state.tileSize} px par case',
              ),
              Text(
                '${state.width} × ${state.height} cases · '
                '${playable ? 'Personnage inclus' : 'Sans personnage'} · Pokémon désactivés',
              ),
              const SizedBox(height: 12),
              const Text(
                'Chemin final',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SelectionArea(
                child: Text(
                  state.destination ??
                      'Choisissez un dossier pour vérifier la destination.',
                ),
              ),
              if (state.destination != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Destination disponible — vérifiée avant la création.',
                    style: TextStyle(color: StudioColors.of(context).success),
                  ),
                ),
            ],
          ),
        ],
      ),
      _ => ProjectCreationProgress(controller: state),
    };
  }
}
