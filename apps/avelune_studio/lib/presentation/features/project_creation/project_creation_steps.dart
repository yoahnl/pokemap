import 'package:flutter/material.dart';
import 'package:map_authoring/map_authoring_project_creation.dart';
import 'package:map_core/map_core_domain.dart';

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
    final playable = state.template == ProjectCreationTemplate.playable;
    final selected = state.selectedTemplate;
    final spatial = state.dimension == ProjectDimension.threeD;
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
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final dimension in ProjectDimension.values)
                SizedBox(
                  width: 240,
                  child: StudioChoiceCard(
                    key: ValueKey('creation-dimension-${dimension.name}'),
                    title: dimension == ProjectDimension.twoD
                        ? 'Jeu 2D'
                        : 'Jeu 3D',
                    description: dimension == ProjectDimension.twoD
                        ? 'Cartes et décors en deux dimensions.'
                        : 'Relief, modèles et caméra en trois dimensions.',
                    icon: dimension == ProjectDimension.twoD
                        ? Icons.grid_on
                        : Icons.view_in_ar,
                    selected: state.dimension == dimension,
                    onPressed: () => state.setDimension(dimension),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Ce choix s’applique à toutes les cartes du projet.'),
          const SizedBox(height: 20),
          if (spatial)
            const StudioPanel(
              title: 'Projet 3D vide',
              children: [
                Text(
                  'Une première carte de terrain plat, prête à construire. Importez ensuite vos modèles dans les ressources. Aucun personnage n’est inclus.',
                ),
              ],
            ),
          if (!spatial)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 280,
                  child: StudioChoiceCard(
                    key: const ValueKey('creation-template-playable'),
                    title: 'Petit projet jouable',
                    description: 'Une carte simple, un personnage et un point de départ pour construire votre aventure.',
                    icon: Icons.landscape_outlined,
                    selected: playable,
                    onPressed: () =>
                        state.setTemplate(ProjectCreationTemplate.playable),
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: StudioChoiceCard(
                    key: const ValueKey('creation-template-empty'),
                    title: 'Projet vide',
                    description: 'Un manifeste et une structure propres, sans carte ni personnage. À compléter avant de jouer.',
                    icon: Icons.grid_on_outlined,
                    selected: state.template == ProjectCreationTemplate.empty,
                    onPressed: () =>
                        state.setTemplate(ProjectCreationTemplate.empty),
                  ),
                ),
                for (final descriptor in state.port.templateCatalog.templates)
                  SizedBox(
                    width: 280,
                    child: StudioChoiceCard(
                      key: ValueKey(
                        'creation-template-catalogue-${descriptor.id}',
                      ),
                      title: descriptor.label,
                      description: descriptor.description,
                      icon: Icons.download_outlined,
                      selected: state.templateId == descriptor.id,
                      onPressed: () =>
                          state.setCatalogueTemplate(descriptor.id),
                    ),
                  ),
              ],
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
                spatial
                    ? 'Projet 3D · terrain par paliers · caméra fixe'
                    : '${selected?.label ?? (playable ? 'Petit projet jouable' : 'Projet vide')} · ${state.tileSize} × ${state.tileSize} px par case',
              ),
              Text(
                selected != null
                    ? 'Géométrie du modèle : ${state.width} × ${state.height} cases. Son contenu est fourni par le catalogue.'
                    : '${state.width} × ${state.height} cases · ${playable ? 'Personnage inclus' : 'Sans personnage'} · Pokémon désactivés',
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
