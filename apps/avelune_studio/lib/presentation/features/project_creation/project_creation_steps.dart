import 'package:flutter/material.dart';
import 'package:map_authoring/map_authoring_project_creation.dart';
import '../../../features/project_creation/application/project_creation_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_choice_card.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../../theme/studio_tokens.dart';
import 'project_creation_progress.dart';
import 'project_creation_parameters.dart';

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
    final playable = state.template != ProjectCreationTemplate.empty;
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
                onPressed: () => state.setTemplate(template),
              );
              final cards = [
                card(
                  playable,
                  ProjectCreationTemplate.clairbois,
                  'Petit projet jouable',
                  'Clairbois : un village, de l’eau, des falaises et une maison à explorer.\n'
                      'Copie téléchargée depuis GitHub à la création. Grille 32 × 32 · connexion requise.',
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
      2 => ProjectCreationParameters(controller: state),
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
