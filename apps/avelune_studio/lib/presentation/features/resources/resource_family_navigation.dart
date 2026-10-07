import 'package:flutter/material.dart';

import '../../shared/widgets/inputs/studio_choice.dart';
import 'resource_catalog.dart';

extension ResourceLibraryFamilyLabels on ResourceLibraryFamily {
  String get label => switch (this) {
    ResourceLibraryFamily.decors => 'Décors',
    ResourceLibraryFamily.terrains => 'Terrains',
    ResourceLibraryFamily.borders => 'Bordures',
    ResourceLibraryFamily.environments => 'Environnements',
    ResourceLibraryFamily.images => 'Images et tuiles',
    ResourceLibraryFamily.models3d => 'Modèles 3D',
  };

  String get purpose => switch (this) {
    ResourceLibraryFamily.decors => 'Poser un objet',
    ResourceLibraryFamily.terrains => 'Peindre le sol',
    ResourceLibraryFamily.borders => 'Tracer un contour',
    ResourceLibraryFamily.environments => 'Répartir des décors',
    ResourceLibraryFamily.images => 'Découper une planche',
    ResourceLibraryFamily.models3d => 'Préparer un objet en volume',
  };

  IconData get icon => switch (this) {
    ResourceLibraryFamily.decors => Icons.park_outlined,
    ResourceLibraryFamily.terrains => Icons.terrain_outlined,
    ResourceLibraryFamily.borders => Icons.timeline,
    ResourceLibraryFamily.environments => Icons.forest_outlined,
    ResourceLibraryFamily.images => Icons.image_outlined,
    ResourceLibraryFamily.models3d => Icons.view_in_ar_outlined,
  };
}

class ResourceFamilyNavigation extends StatelessWidget {
  const ResourceFamilyNavigation({
    super.key,
    required this.selected,
    required this.onChanged,
    this.onCharacters,
  });
  final ResourceLibraryFamily selected;
  final ValueChanged<ResourceLibraryFamily> onChanged;
  final VoidCallback? onCharacters;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(12),
    children: [
      Text('Bibliothèque', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      for (final family in ResourceLibraryFamily.values)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: StudioChoice(
            key: ValueKey('resource-family-${family.name}'),
            label: family.label,
            subtitle: family.purpose,
            leading: Icon(family.icon, size: 22),
            selected: family == selected,
            onTap: () => onChanged(family),
          ),
        ),
      if (onCharacters != null) ...[
        const Divider(height: 24),
        StudioChoice(
          label: 'Personnages',
          subtitle: 'Ouvrir l’atelier',
          leading: const Icon(Icons.people_outline, size: 22),
          onTap: onCharacters,
        ),
      ],
    ],
  );
}
