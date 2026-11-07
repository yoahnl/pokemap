import 'package:map_authoring/map_authoring_project_creation.dart';
import 'package:map_core/map_core_domain.dart';

final class ProjectTemplateContents {
  const ProjectTemplateContents(this.rows, this.beforeTest);
  final Map<String, String> rows;
  final String beforeTest;
}

ProjectTemplateContents projectTemplateContents({
  required ProjectDimension dimension,
  required ProjectCreationTemplate template,
  required String width,
  required String height,
  String? catalogueLabel,
}) {
  const pokemon = 'Désactivés, activables ensuite';
  const missing =
      'Ajouter une carte, un personnage et un départ, puis lancer « Tester la carte ».';
  if (dimension == ProjectDimension.threeD) {
    return ProjectTemplateContents(
      {
        'Carte': 'Première carte 3D, terrain plat de $width × $height cases',
        'Personnage joueur': 'Aucun',
        'Départ du joueur': 'Aucun',
        'Ressources': 'Aucun modèle 3D, à importer dans Ressources',
        'Pokémon': pokemon,
      },
      'Construire le sol, importer un personnage et placer le départ, puis lancer « Tester la carte ».',
    );
  }
  return switch (template) {
    ProjectCreationTemplate.playable => ProjectTemplateContents(
      {
        'Carte': 'Première carte, $width × $height cases',
        'Personnage joueur': 'Inclus',
        'Départ du joueur': 'Inclus sur la première carte',
        'Ressources': 'Kit original Avelune',
        'Pokémon': pokemon,
      },
      'Carte, personnage et départ sont fournis : lancez « Tester la carte » après création pour le confirmer.',
    ),
    ProjectCreationTemplate.empty => const ProjectTemplateContents({
      'Carte': 'Aucune',
      'Personnage joueur': 'Aucun',
      'Départ du joueur': 'Aucun',
      'Ressources': 'Aucune',
      'Pokémon': pokemon,
    }, missing),
    ProjectCreationTemplate.catalogue => ProjectTemplateContents(
      {
        'Carte':
            'Fournie par ${catalogueLabel ?? 'le modèle'}, $width × $height cases',
        'Personnage joueur':
            'Fourni par ${catalogueLabel ?? 'le modèle'}, détaillé après création',
        'Départ du joueur': 'Détaillé après création',
        'Ressources': 'Fournies par le catalogue',
        'Pokémon': 'Selon le modèle',
      },
      'Le contenu exact se lit après création ; lancez « Tester la carte » pour confirmer qu’il se joue.',
    ),
  };
}
