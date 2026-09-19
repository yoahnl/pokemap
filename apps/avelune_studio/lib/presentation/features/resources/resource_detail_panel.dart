import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/decors/application/decor_source_support.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_badge.dart';
import '../../shared/widgets/feedback/studio_empty_state.dart';
import '../../shared/widgets/layout/studio_asset_preview.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'resource_catalog.dart';

class ResourceDetailPanel extends StatelessWidget {
  const ResourceDetailPanel({
    super.key,
    required this.item,
    required this.project,
    required this.preview,
    required this.onUse,
    required this.onEdit,
    required this.onTerrain,
    this.openUsage = 0,
    this.targetMapName,
    this.canUse = true,
  });
  final ResourceItem? item;
  final int openUsage;
  final ProjectManifest project;
  final Widget preview;
  final ValueChanged<ResourceItem> onUse;
  final ValueChanged<ResourceItem> onEdit;
  final ValueChanged<ResourceItem> onTerrain;
  final String? targetMapName;
  final bool canUse;

  @override
  Widget build(BuildContext context) {
    final entry = item;
    if (entry == null) {
      return const StudioEmptyState(
        title: 'Aucune ressource sélectionnée',
        description: 'Choisissez un aperçu pour examiner la ressource.',
        icon: Icons.image_outlined,
      );
    }
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            key: ValueKey('resource-detail-${entry.kind.name}-${entry.id}'),
            padding: const EdgeInsets.all(12),
            child: StudioPanel(
              compact: true,
              children: [
                StudioAssetPreview(height: 208, child: preview),
                const SizedBox(height: 16),
                SelectableText(entry.name, style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                StudioBadge(switch (entry.kind) {
                  ResourceKind.decors => 'Décor',
                  ResourceKind.terrains => 'Terrain automatique',
                  ResourceKind.images => 'Image et tuiles',
                }),
                const SizedBox(height: 16),
                ..._metadata(context, entry),
                const SizedBox(height: 12),
                ..._preparation(entry),
                const SizedBox(height: 16),
                Text(
                  'Usages dans les cartes ouvertes',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Text('$openUsage occurrence(s)'),
                const SizedBox(height: 4),
                Text(
                  'Les autres cartes du projet ne sont pas comptées.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!canUse || project.maps.isEmpty) ...[
                Text(
                  project.maps.isEmpty
                      ? 'Ce projet ne contient aucune carte. Les ressources restent consultables.'
                      : 'L’utilisation sur la carte est momentanément indisponible.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
              ],
              StudioButton(
                key: const ValueKey('resource-use'),
                label: targetMapName == null
                    ? 'Choisir une carte'
                    : 'Utiliser sur « $targetMapName »',
                icon: Icons.map_outlined,
                onPressed: canUse && project.maps.isNotEmpty
                    ? () => onUse(entry)
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _metadata(BuildContext context, ResourceItem entry) {
    final frame = entry.element?.frames.firstOrNull;
    final sourceId = frame != null && frame.tilesetId.isNotEmpty
        ? frame.tilesetId
        : entry.element?.tilesetId;
    final tileset =
        entry.tileset ??
        project.tilesets.where((value) => value.id == sourceId).firstOrNull;
    final source = entry.tileset?.source;
    final category = switch (entry.kind) {
      ResourceKind.decors =>
        project.elementCategories
            .where((value) => value.id == entry.category)
            .firstOrNull
            ?.name,
      ResourceKind.terrains =>
        project.smartTileCatalog.categories
            .where((value) => value.id == entry.category)
            .firstOrNull
            ?.name,
      ResourceKind.images =>
        project.tilesetFolders
            .where((value) => value.id == entry.category)
            .firstOrNull
            ?.name,
    };
    final terrainAtlases = {
      for (final rule in entry.terrain?.rules ?? <SmartTileRule>[])
        for (final candidate in rule.candidates)
          for (final part in candidate.parts)
            if (part.source case SmartTileFrameSource(:final frame))
              frame.atlasId,
    };
    final terrainSources = {
      for (final atlas in project.smartTileCatalog.atlases)
        if (terrainAtlases.contains(atlas.id)) atlas.tilesetId,
    };
    final rows = <(String, String)>[
      if (tileset != null) ('Source', tileset.name),
      if (terrainSources.isNotEmpty)
        (
          'Source',
          project.tilesets
              .where((value) => terrainSources.contains(value.id))
              .map((value) => value.name)
              .join(' · '),
        ),
      if (source is ProjectRegularAtlasTilesetSource) ...[
        ('Image', '${source.pixelWidth} × ${source.pixelHeight} px'),
        ('Grille', '${source.columns} × ${source.rows} tuiles'),
        ('Tuile', '${source.tileWidth} × ${source.tileHeight} px'),
      ],
      if (entry.tileset != null && source == null)
        ('Grille', 'Métadonnées non préparées — accès aux tuiles conservé'),
      if (source is ProjectImageCollectionTilesetSource)
        ('Collection', '${source.tileDefinitions.length} tuiles'),
      if (frame != null)
        ('Dimensions', '${frame.source.width} × ${frame.source.height} cases'),
      if (category != null && category.isNotEmpty) ('Catégorie', category),
      if (entry.tags.isNotEmpty) ('Tags', entry.tags.join(' · ')),
      if (entry.element case final element?) ...[
        ('Définition', 'Partagée par ses instances sur les cartes'),
        if (element.frames.length > 1)
          ('Animation', '${element.frames.length} images'),
        if (element.collisionProfile case final collision?)
          ('Collision', '${collision.cells.length} case(s) bloquée(s)'),
      ],
      if (entry.terrain case final terrain?)
        ('Raccords', '${terrain.rules.length} règles'),
    ];
    return [
      for (final (label, value) in rows)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: MediaQuery.textScalerOf(context).scale(76),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(value)),
            ],
          ),
        ),
    ];
  }

  List<Widget> _preparation(ResourceItem entry) => [
    if (entry.element != null)
      StudioButton(
        label: 'Modifier le décor',
        icon: Icons.edit_outlined,
        secondary: true,
        onPressed: () => onEdit(entry),
      ),
    if (entry.tileset case final tileset?) ...[
      StudioButton(
        label: 'Créer un décor',
        secondary: true,
        onPressed: canCreateDecor(tileset, project)
            ? () => onEdit(entry)
            : null,
      ),
      const SizedBox(height: 8),
      StudioButton(
        label: 'Créer un terrain automatique',
        secondary: true,
        onPressed: tileset.source is ProjectRegularAtlasTilesetSource
            ? () => onTerrain(entry)
            : null,
      ),
      if (decorConversionProblem(tileset, project) case final String message)
        Padding(padding: const EdgeInsets.only(top: 8), child: Text(message)),
    ],
  ];
}
