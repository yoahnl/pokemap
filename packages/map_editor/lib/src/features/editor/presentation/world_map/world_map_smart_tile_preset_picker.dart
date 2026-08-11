import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../../theme/theme.dart';
import '../../../../ui/design_system/design_system.dart';
import 'world_map_smart_tile_atlas_preview.dart';

Future<ProjectSmartTilePreset?> showWorldMapSmartTilePresetPicker({
  required BuildContext context,
  required ProjectManifest? project,
  required List<ProjectSmartTilePreset> presets,
  required SmartTileUsage usage,
  required String? projectRootPath,
}) async {
  final searchFocusNode = FocusNode(
    debugLabel: 'world map smart tile preset search',
  );
  final container = ProviderScope.containerOf(context);
  final noun = _usageNoun(usage);
  try {
    return await showPokeMapDesktopSideSheet<ProjectSmartTilePreset>(
      context: context,
      title: 'Ajouter un $noun',
      semanticLabel: 'Bibliothèque de $noun Smart Tiles publiés',
      barrierLabel: 'Fermer le choix de $noun',
      width: 590,
      initialFocusNode: searchFocusNode,
      builder: (_) => UncontrolledProviderScope(
        container: container,
        child: WorldMapSmartTilePresetPicker(
          project: project,
          presets: presets,
          usage: usage,
          projectRootPath: projectRootPath,
          searchFocusNode: searchFocusNode,
        ),
      ),
    );
  } finally {
    searchFocusNode.dispose();
  }
}

class WorldMapSmartTilePresetPicker extends StatefulWidget {
  const WorldMapSmartTilePresetPicker({
    super.key,
    required this.project,
    required this.presets,
    required this.usage,
    required this.projectRootPath,
    this.searchFocusNode,
  });

  final ProjectManifest? project;
  final List<ProjectSmartTilePreset> presets;
  final SmartTileUsage usage;
  final String? projectRootPath;
  final FocusNode? searchFocusNode;

  @override
  State<WorldMapSmartTilePresetPicker> createState() =>
      _WorldMapSmartTilePresetPickerState();
}

class _WorldMapSmartTilePresetPickerState
    extends State<WorldMapSmartTilePresetPicker> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final noun = _usageNoun(widget.usage);
    final catalog =
        widget.project?.smartTileCatalog ??
        const ProjectSmartTileCatalog.empty();
    final tilesets = widget.project?.tilesets ?? const <ProjectTilesetEntry>[];
    final normalizedQuery = _query.trim().toLowerCase();
    final visiblePresets = widget.presets
        .where((preset) {
          if (normalizedQuery.isEmpty) return true;
          final usages = collectWorldMapSmartTileAtlasUsages(preset, catalog);
          return preset.name.toLowerCase().contains(normalizedQuery) ||
              usages.any(
                (usage) =>
                    usage.atlas.name.toLowerCase().contains(normalizedQuery),
              );
        })
        .toList(growable: false);

    return KeyedSubtree(
      key: const ValueKey<String>('world-map-smart-tile-preset-picker-sheet'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.presets.isEmpty
                  ? 'Aucun $noun publié. Créez-en un dans Smart Tiles Studio '
                        'puis publiez-le pour le rendre disponible ici.'
                  : 'Choisissez un $noun publié. Le calque sera créé, '
                        'sélectionné et prêt à peindre.',
              style: TextStyle(
                color: context.pokeMapColors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            if (widget.presets.isNotEmpty) ...[
              const SizedBox(height: 14),
              PokeMapSearchField(
                key: const ValueKey<String>(
                  'world-map-smart-tile-preset-picker-search',
                ),
                controller: _searchController,
                focusNode: widget.searchFocusNode,
                hintText: 'Rechercher un preset ou un atlas…',
                semanticLabel: 'Rechercher un preset Smart Tile publié',
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 12),
              Text(
                '${visiblePresets.length} $noun${visiblePresets.length > 1 ? 's' : ''}',
                style: TextStyle(
                  color: context.pokeMapColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Expanded(
              child: visiblePresets.isEmpty
                  ? PokeMapEmptyState(
                      icon: const Icon(Icons.auto_awesome_mosaic_outlined),
                      title: widget.presets.isEmpty
                          ? 'Aucun preset publié'
                          : 'Aucun résultat',
                      description: widget.presets.isEmpty
                          ? 'Créez et publiez d’abord votre preset dans Smart '
                                'Tiles Studio.'
                          : 'Aucun preset ne correspond à votre recherche.',
                    )
                  : ListView.separated(
                      itemCount: visiblePresets.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final preset = visiblePresets[index];
                        final usages = collectWorldMapSmartTileAtlasUsages(
                          preset,
                          catalog,
                        );
                        return _PresetCard(
                          preset: preset,
                          usage: widget.usage,
                          atlasUsages: usages,
                          tilesets: tilesets,
                          projectRootPath: widget.projectRootPath,
                          onSelected: () => Navigator.of(context).pop(preset),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  const _PresetCard({
    required this.preset,
    required this.usage,
    required this.atlasUsages,
    required this.tilesets,
    required this.projectRootPath,
    required this.onSelected,
  });

  final ProjectSmartTilePreset preset;
  final SmartTileUsage usage;
  final List<WorldMapSmartTileAtlasUsage> atlasUsages;
  final List<ProjectTilesetEntry> tilesets;
  final String? projectRootPath;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final primaryAtlas = atlasUsages.firstOrNull;
    final zoneCount = atlasUsages.fold<int>(
      0,
      (total, usage) => total + usage.frames.length,
    );
    final atlasSummary = switch (atlasUsages.length) {
      0 => 'Aucun atlas résolu',
      1 => primaryAtlas!.atlas.name,
      _ => '${primaryAtlas!.atlas.name} + ${atlasUsages.length - 1}',
    };

    return PokeMapCard(
      key: ValueKey<String>(
        'world-map-smart-${usage.name}-preset-${preset.id}',
      ),
      onTap: onSelected,
      keyboardInteractive: true,
      semanticLabel: 'Choisir ${preset.name}',
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          if (primaryAtlas == null)
            _MissingAtlasThumbnail(usage: usage, presetId: preset.id)
          else
            WorldMapSmartTileAtlasThumbnail(
              usage: usage,
              preset: preset,
              atlasUsage: primaryAtlas,
              tilesets: tilesets,
              projectRootPath: projectRootPath,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  preset.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.pokeMapColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  atlasSummary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.pokeMapColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  zoneCount == 0
                      ? _topologyLabel(preset.topology)
                      : '$zoneCount zone${zoneCount > 1 ? 's' : ''} utilisée${zoneCount > 1 ? 's' : ''} · '
                            '${_topologyLabel(preset.topology)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.pokeMapColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            color: context.pokeMapColors.textMuted,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _MissingAtlasThumbnail extends StatelessWidget {
  const _MissingAtlasThumbnail({required this.usage, required this.presetId});

  final SmartTileUsage usage;
  final String presetId;

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey<String>(
      'world-map-smart-${usage.name}-preset-$presetId-atlas-thumbnail',
    ),
    width: 58,
    height: 58,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: context.pokeMapColors.controlSurface,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: context.pokeMapColors.borderSubtle),
    ),
    child: Icon(
      Icons.image_not_supported_outlined,
      color: context.pokeMapColors.textMuted,
      size: 20,
    ),
  );
}

String _usageNoun(SmartTileUsage usage) => switch (usage) {
  SmartTileUsage.terrain => 'terrain',
  SmartTileUsage.path => 'chemin',
  SmartTileUsage.forestSurface => 'surface forestière',
};

String _topologyLabel(SmartTileTopology topology) => switch (topology) {
  SmartTileTopology.uniform => 'Surface simple',
  SmartTileTopology.cardinal4 => 'Raccords à 4 directions',
  SmartTileTopology.blob8 => 'Raccords organiques',
  SmartTileTopology.wangEdge4 => 'Wang par arêtes',
  SmartTileTopology.wangCorner4 => 'Wang par coins',
  SmartTileTopology.wang8 => 'Wang complet',
};
