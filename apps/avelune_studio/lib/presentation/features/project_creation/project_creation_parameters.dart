import 'package:flutter/material.dart';
import 'package:map_authoring/map_authoring_project_creation.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/project_creation/application/project_creation_controller.dart';
import '../../shared/widgets/buttons/studio_choice_card.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/layout/studio_panel.dart';

class ProjectCreationParameters extends StatelessWidget {
  const ProjectCreationParameters({super.key, required this.controller});
  final ProjectCreationController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller;
    if (state.dimension == ProjectDimension.threeD) {
      return _spatialParameters(context);
    }
    final clairbois = state.template == ProjectCreationTemplate.clairbois;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paramètres du projet',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          clairbois
              ? 'Clairbois est prêt à explorer. Ses cartes et ses ressources utilisent une grille native de 32 × 32 pixels.'
              : 'Configurez les bases de votre aventure.',
        ),
        const SizedBox(height: 24),
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
            for (final size in clairbois ? [32] : [16, 32, 48])
              SizedBox(
                width: 180,
                child: StudioChoiceCard(
                  key: ValueKey('creation-grid-$size'),
                  title: '$size × $size px',
                  description: clairbois
                      ? 'Grille du modèle'
                      : 'Pixels par case',
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
          title: clairbois ? 'Votre copie de Clairbois' : 'Options',
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                clairbois ? Icons.check_circle : Icons.remove_circle_outline,
              ),
              title: const Text('Personnage et point de départ'),
              subtitle: Text(
                clairbois
                    ? 'Inclus avec un dialogue et les passages entre les deux cartes.'
                    : 'Aucun personnage ni point de départ dans le projet vide.',
              ),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.lock_outline),
              title: Text('Pokémon désactivés'),
              subtitle: Text(
                'Exploration sans équipe ni catalogue Pokémon initialisé.',
              ),
            ),
            if (clairbois)
              const Text(
                'Village : 32 × 26 cases · Maison : 12 × 10 cases.\nLes cartes restent éditables après création.',
              ),
          ],
        ),
        if (!clairbois) ...[
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
                  for (final width in [true, false])
                    SizedBox(
                      width: 220,
                      child: StudioDraftField(
                        key: ValueKey(
                          width ? 'Largeur en cases' : 'Hauteur en cases',
                        ),
                        label: width ? 'Largeur en cases' : 'Hauteur en cases',
                        value: width ? state.width : state.height,
                        onChanged: (value) => state.changePreview(() {
                          if (width) {
                            state.width = value;
                          } else {
                            state.height = value;
                          }
                        }),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Défauts des futures cartes : ${int.tryParse(state.width) ?? 0} × '
                '${int.tryParse(state.height) ?? 0} cases · '
                '${(int.tryParse(state.width) ?? 0) * state.tileSize} × '
                '${(int.tryParse(state.height) ?? 0) * state.tileSize} px, hors zoom.',
              ),
              const SizedBox(height: 12),
            ],
          ),
        ],
      ],
    );
  }

  Widget _spatialParameters(BuildContext context) {
    final state = controller;
    Widget field(String label, String value, ValueChanged<String> change) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: StudioDraftField(
            key: ValueKey(label),
            label: label,
            value: value,
            onChanged: (value) => state.changePreview(() => change(value)),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Votre première carte 3D',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        const Text(
          'La taille se mesure en cases. Le relief se construit ensuite par paliers de hauteur fixe.',
        ),
        const SizedBox(height: 20),
        field('Largeur en cases · X', state.width, (v) => state.width = v),
        field('Profondeur en cases · Z', state.height, (v) => state.height = v),
        const SizedBox(height: 12),
        StudioPanel(
          title: 'Caméra du jeu · angle fixe',
          children: [
            const Text(
              'Le cadrage initial rappelle les jeux DS. Vous pourrez ajuster la caméra sur chaque carte. La vue libre de l’éditeur reste indépendante.',
            ),
            const SizedBox(height: 12),
            field(
              'Inclinaison en degrés',
              state.cameraPitch,
              (v) => state.cameraPitch = v,
            ),
            field(
              'Orientation en degrés',
              state.cameraYaw,
              (v) => state.cameraYaw = v,
            ),
            field(
              'Champ de vision en degrés',
              state.cameraFov,
              (v) => state.cameraFov = v,
            ),
            field(
              'Distance en cases',
              state.cameraDistance,
              (v) => state.cameraDistance = v,
            ),
          ],
        ),
      ],
    );
  }
}
