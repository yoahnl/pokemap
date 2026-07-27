import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/pokemap_button.dart';
import '../../../ui/design_system/pokemap_card.dart';
import '../../../ui/design_system/pokemap_section_header.dart';
import '../application/project_branding_image_import_service.dart';

class ProjectBrandingEditor extends StatelessWidget {
  const ProjectBrandingEditor({
    super.key,
    required this.profile,
    required this.onImportImage,
    required this.onRemoveImage,
  });

  final ProjectBrandingProfile profile;
  final ValueChanged<ProjectBrandingImageRole> onImportImage;
  final ValueChanged<ProjectBrandingImageRole> onRemoveImage;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('project-branding-editor'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const PokeMapSectionHeader(
          title: 'Images de marque',
          description:
              'Importez des fichiers appartenant au projet. Le logo du titre '
              'utilise le rôle hero.',
        ),
        const SizedBox(height: 8),
        for (final role in ProjectBrandingImageRole.values) ...<Widget>[
          _BrandingImageRoleCard(
            role: role,
            path: _pathForRole(profile, role),
            onImport: () => onImportImage(role),
            onRemove: _pathForRole(profile, role) == null
                ? null
                : () => onRemoveImage(role),
          ),
          if (role != ProjectBrandingImageRole.values.last)
            const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _BrandingImageRoleCard extends StatelessWidget {
  const _BrandingImageRoleCard({
    required this.role,
    required this.path,
    required this.onImport,
    required this.onRemove,
  });

  final ProjectBrandingImageRole role;
  final String? path;
  final VoidCallback onImport;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            _roleLabel(role),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(path ?? 'Aucun fichier importé'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              PokeMapButton(
                key: ValueKey<String>('branding-import-${role.name}'),
                size: PokeMapButtonSize.compact,
                leading: const Icon(Icons.upload_file_outlined),
                onPressed: onImport,
                child: Text(path == null ? 'Importer' : 'Remplacer'),
              ),
              PokeMapButton(
                key: ValueKey<String>('branding-remove-${role.name}'),
                variant: PokeMapButtonVariant.ghost,
                size: PokeMapButtonSize.compact,
                leading: const Icon(Icons.delete_outline_rounded),
                onPressed: onRemove,
                child: const Text('Retirer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String? _pathForRole(
  ProjectBrandingProfile profile,
  ProjectBrandingImageRole role,
) =>
    switch (role) {
      ProjectBrandingImageRole.icon => profile.iconPath,
      ProjectBrandingImageRole.cover => profile.coverPath,
      ProjectBrandingImageRole.hero => profile.heroPath,
    };

String _roleLabel(ProjectBrandingImageRole role) => switch (role) {
      ProjectBrandingImageRole.icon => 'Icône du jeu',
      ProjectBrandingImageRole.cover => 'Cover de bibliothèque',
      ProjectBrandingImageRole.hero => 'Logo / hero du titre',
    };
