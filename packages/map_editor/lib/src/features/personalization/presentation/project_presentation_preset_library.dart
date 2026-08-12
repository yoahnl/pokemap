import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/pokemap_badge.dart';
import '../../../ui/design_system/pokemap_button.dart';
import '../../../ui/design_system/pokemap_card.dart';
import '../../../ui/design_system/pokemap_section_header.dart';

class ProjectPresentationPresetLibrary extends StatelessWidget {
  const ProjectPresentationPresetLibrary({
    super.key,
    required this.presets,
    required this.canManage,
    required this.onApply,
    required this.onDelete,
    required this.onImport,
    required this.onExport,
  });

  final List<ProjectPresentationPresetRecord> presets;
  final bool canManage;
  final ValueChanged<ProjectPresentationPresetRecord> onApply;
  final ValueChanged<ProjectPresentationPresetRecord> onDelete;
  final VoidCallback onImport;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey<String>('project-presentation-preset-library'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      const PokeMapSectionHeader(
        title: 'Bibliothèque de profils',
        description:
            'Réutilisez une identité complète ou échangez-la avec un autre '
            'projet au format sécurisé .pokemapstyle. Les médias partagés '
            'demandent une licence TXT de redistribution.',
      ),
      const SizedBox(height: 8),
      PokeMapCard(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            PokeMapButton(
              key: const ValueKey<String>('preset-library-import'),
              size: PokeMapButtonSize.compact,
              leading: const Icon(Icons.file_download_outlined),
              onPressed: canManage ? onImport : null,
              disabledReason: canManage
                  ? null
                  : 'Enregistrez le brouillon avant de gérer les profils.',
              child: const Text('Importer'),
            ),
            PokeMapButton(
              key: const ValueKey<String>('preset-library-export'),
              variant: PokeMapButtonVariant.secondary,
              size: PokeMapButtonSize.compact,
              leading: const Icon(Icons.file_upload_outlined),
              onPressed: canManage ? onExport : null,
              disabledReason: canManage
                  ? null
                  : 'Enregistrez le brouillon avant de gérer les profils.',
              child: const Text('Exporter ce profil'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      if (presets.isEmpty)
        const PokeMapCard(
          child: Text(
            'Aucun profil enregistré dans ce projet. Exporte le profil '
            'actuel pour créer le premier.',
          ),
        )
      else
        for (final preset in presets) ...<Widget>[
          _PresetCard(
            preset: preset,
            canManage: canManage,
            onApply: () => onApply(preset),
            onDelete: () => onDelete(preset),
          ),
          if (preset != presets.last) const SizedBox(height: 8),
        ],
    ],
  );
}

class _PresetCard extends StatelessWidget {
  const _PresetCard({
    required this.preset,
    required this.canManage,
    required this.onApply,
    required this.onDelete,
  });

  final ProjectPresentationPresetRecord preset;
  final bool canManage;
  final VoidCallback onApply;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => PokeMapCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                preset.label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            PokeMapBadge(
              label: 'v${preset.profile.schemaVersion}',
              variant: PokeMapBadgeVariant.info,
            ),
          ],
        ),
        if (preset.description.isNotEmpty) ...<Widget>[
          const SizedBox(height: 4),
          Text(preset.description),
        ],
        const SizedBox(height: 4),
        Text(
          '${preset.scope == ProjectPresentationPresetScope.complete ? 'Profil complet' : 'Portée ${preset.scope.name}'} • '
          '${preset.replacedSections.isEmpty ? preset.configuredCategories.length : preset.replacedSections.length} sections • '
          '${preset.assets.length} assets avec licence',
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            PokeMapButton(
              key: ValueKey<String>('preset-apply-${preset.id}'),
              size: PokeMapButtonSize.compact,
              leading: const Icon(Icons.auto_awesome_outlined),
              onPressed: onApply,
              child: const Text('Appliquer au brouillon'),
            ),
            PokeMapButton(
              key: ValueKey<String>('preset-delete-${preset.id}'),
              variant: PokeMapButtonVariant.danger,
              size: PokeMapButtonSize.compact,
              leading: const Icon(Icons.delete_outline_rounded),
              onPressed: canManage ? onDelete : null,
              child: const Text('Supprimer'),
            ),
          ],
        ),
      ],
    ),
  );
}
