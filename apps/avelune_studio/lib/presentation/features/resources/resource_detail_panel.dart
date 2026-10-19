import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/decors/application/decor_source_support.dart';
import '../../../features/terrains/domain/terrain_draft_compatibility.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_badge.dart';
import '../../shared/widgets/feedback/studio_empty_state.dart';
import '../../shared/widgets/layout/studio_asset_preview.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'resource_catalog.dart';
import 'resource_item_actions.dart';

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
    this.canEditTerrain = false,
    this.onInformation,
    this.onMove,
    this.onUsages,
    this.onReplace,
    this.onRemove,
    this.onDuplicate,
    this.onClassify,
    this.activeMapId,
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
  final bool canEditTerrain;
  final ValueChanged<ResourceItem>? onInformation, onMove, onUsages;
  final ValueChanged<ResourceItem>? onReplace, onRemove, onDuplicate;
  final ValueChanged<ResourceItem>? onClassify;
  final String? activeMapId;

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
    final metadata = entry.metadata(project);
    final mapAvailable =
        activeMapId == null ||
        metadata?.mapId == null ||
        metadata?.mapId == activeMapId;
    final compatible = entry.compatibleWith(project.settings.dimension);
    final prepared =
        entry.border == null ||
        (entry.border!.latestPublished != null && !entry.border!.isDeprecated);
    final usable =
        canUse &&
        project.maps.isNotEmpty &&
        mapAvailable &&
        compatible &&
        prepared;
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StudioBadge(entry.typeLabel),
                    StudioBadge(resourceCatalogScopeLabel(project, entry)),
                    StudioBadge(resourceCatalogContextLabel(project, entry)),
                  ],
                ),
                const SizedBox(height: 16),
                if (metadata?.description case final description?) ...[
                  SelectableText(
                    description,
                    key: const ValueKey('resource-description'),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                ],
                ..._metadata(context, entry),
                if (onClassify != null)
                  StudioButton(
                    key: const ValueKey('resource-classify'),
                    label: 'Ranger la ressource',
                    icon: Icons.folder_outlined,
                    secondary: true,
                    onPressed: () => onClassify!(entry),
                  ),
                const SizedBox(height: 12),
                ..._preparation(entry),
                const SizedBox(height: 12),
                ResourceItemActions(
                  item: entry,
                  buttons: true,
                  onInformation: onInformation,
                  onMove: onMove,
                  onUsages: onUsages,
                  onReplace: onReplace,
                  onRemove: onRemove,
                  onDuplicate: onDuplicate,
                ),
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
              if (!usable) ...[
                Text(
                  project.maps.isEmpty
                      ? 'Ce projet ne contient aucune carte. Les ressources restent consultables.'
                      : !compatible
                      ? 'Cette ressource ne se place pas dans un projet ${project.settings.dimension == ProjectDimension.threeD ? "3D" : "2D"}.'
                      : !mapAvailable
                      ? 'Cette ressource est réservée à « ${project.maps.where((map) => map.id == metadata?.mapId).firstOrNull?.name ?? "sa carte"} ».'
                      : !prepared
                      ? 'Préparez et publiez cette bordure dans son atelier avant de la tracer.'
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
                onPressed: usable ? () => onUse(entry) : null,
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
        : entry.element?.tilesetId ?? entry.character?.tilesetId;
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
      ('Famille', resourceCatalogFamilyLabel(project, entry)),
      ('Portée', resourceCatalogScopeLabel(project, entry)),
      ('Contexte d’usage', resourceCatalogContextLabel(project, entry)),
      if (entry.border != null) ('Aperçu', 'Une pièce de la bordure'),
      if (entry.environment != null) ('Aperçu', 'Un décor de la palette'),
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
    if (entry.terrain != null)
      if (canEditTerrain)
        StudioButton(
          label: 'Modifier les raccords',
          icon: Icons.edit_outlined,
          secondary: true,
          onPressed: () => onTerrain(entry),
        )
      else
        const Text(advancedTerrainPreparationMessage),
    if (entry.element != null)
      StudioButton(
        label: 'Modifier le décor',
        icon: Icons.edit_outlined,
        secondary: true,
        onPressed: () => onEdit(entry),
      ),
    if (entry.model3d != null ||
        entry.border != null ||
        entry.environment != null ||
        entry.character != null)
      StudioButton(
        label: 'Ouvrir l’atelier',
        icon: Icons.edit_outlined,
        secondary: true,
        onPressed: () => onEdit(entry),
      ),
    if (entry.model3d != null &&
        project.settings.dimension == ProjectDimension.threeD &&
        entry.metadata(project)?.mapId == null)
      StudioButton(
        key: const ValueKey('resource-create-path'),
        label: 'Créer un chemin automatique',
        icon: Icons.route_outlined,
        secondary: true,
        onPressed: () => onTerrain(entry),
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
        key: const ValueKey('resource-create-path'),
        label: 'Créer un chemin automatique',
        icon: Icons.route_outlined,
        secondary: true,
        onPressed: terrainSourceCompatibilityProblem(tileset) == null
            ? () => onTerrain(entry)
            : null,
      ),
      if (decorConversionProblem(tileset, project) case final String message)
        Padding(padding: const EdgeInsets.only(top: 8), child: Text(message)),
      if (terrainSourceCompatibilityProblem(tileset) case final String message)
        Padding(padding: const EdgeInsets.only(top: 8), child: Text(message)),
    ],
  ];
}
