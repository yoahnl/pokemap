import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'resource_catalog.dart';
import '../../shared/widgets/layout/studio_asset_preview.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../../shared/widgets/feedback/studio_empty_state.dart';
import 'package:avelune_studio/features/decors/application/decor_source_support.dart';

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
  });
  final ResourceItem? item;
  final int openUsage;
  final ProjectManifest project;
  final Widget preview;
  final ValueChanged<ResourceItem> onUse;
  final ValueChanged<ResourceItem> onEdit;
  final ValueChanged<ResourceItem> onTerrain;
  @override
  Widget build(BuildContext context) {
    final entry = item;
    if (entry == null) {
      return const StudioEmptyState(
        title: 'Sélectionnez une ressource.',
        description: 'Son aperçu et ses usages apparaîtront ici.',
        icon: Icons.image_outlined,
      );
    }
    final source = entry.tileset?.source;
    final tileset =
        entry.tileset ??
        project.tilesets
            .where((t) => t.id == entry.element?.tilesetId)
            .firstOrNull;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: StudioPanel(
        compact: true,
        children: [
          StudioAssetPreview(height: 180, child: preview),
          const SizedBox(height: 16),
          Text('$openUsage usage(s) dans les cartes ouvertes'),
          const SizedBox(height: 8),
          Text(entry.name, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (tileset != null) Text('Source : ${tileset.name}'),
          if (source is ProjectRegularAtlasTilesetSource)
            Text(
              '${source.pixelWidth} × ${source.pixelHeight} px · ${source.columns} × ${source.rows} tuiles',
            ),
          if (entry.element != null)
            Text(
              'Définition partagée · ${entry.element!.frames.first.source.width} × ${entry.element!.frames.first.source.height} cases',
            ),
          if (entry.terrain != null)
            Text(
              'Terrain automatique · ${entry.terrain!.rules.length} raccords',
            ),
          const SizedBox(height: 16),
          StudioButton(
            label: 'Utiliser sur la carte',
            icon: Icons.arrow_back,
            onPressed: () => onUse(entry),
          ),
          const SizedBox(height: 8),
          if (entry.element != null)
            StudioButton(
              label: 'Modifier le décor',
              secondary: true,
              onPressed: () => onEdit(entry),
            ),
          if (entry.tileset != null) ...[
            StudioButton(
              label: 'Créer un décor',
              secondary: true,
              onPressed: canCreateDecor(entry.tileset!, project)
                  ? () => onEdit(entry)
                  : null,
            ),
            const SizedBox(height: 8),
            StudioButton(
              label: 'Créer un terrain automatique',
              secondary: true,
              onPressed: source is ProjectRegularAtlasTilesetSource
                  ? () => onTerrain(entry)
                  : null,
            ),
            if (decorConversionProblem(entry.tileset!, project)
                case final String message)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(message),
              ),
          ],
        ],
      ),
    );
  }
}
