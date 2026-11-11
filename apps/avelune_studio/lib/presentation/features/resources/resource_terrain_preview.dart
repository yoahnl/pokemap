import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/resources/application/resource_terrain_example.dart';
import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';
import '../../../features/terrains/domain/terrain_spatial_preview_map.dart';
import '../terrains/terrain_spatial_preview.dart';
import '../../shared/widgets/feedback/studio_notice.dart';

class ResourceTerrainPreview extends StatelessWidget {
  const ResourceTerrainPreview({
    super.key,
    required this.preset,
    required this.project,
    required this.visuals,
    required this.size,
  });
  final ProjectSmartTilePreset preset;
  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (preset.rules.any(
      (rule) => rule.candidates.any(
        (candidate) => candidate.parts.any(
          (part) => part.source is SmartTileModel3dSource,
        ),
      ),
    )) {
      try {
        final preview = terrainSpatialPreviewMap(
          project: project,
          preset: preset,
          size: 3,
          cells: {
            for (var index = 0; index < 9; index++)
              GridPos(x: index % 3, y: index ~/ 3),
          },
        );
        return TerrainSpatialPreview(
          map: preview.map,
          project: preview.project,
          visuals: visuals,
        );
      } on FormatException {
        return const StudioNotice(
          'Cette pièce dépasse le terrain d’aperçu. Vérifiez ses points d’appui et ses décalages.',
        );
      }
    }
    final tiles = terrainConnectionExample(project, preset);
    if (tiles == null) {
      return const Center(
        child: Text(
          'Aperçu du raccord non préparé',
          textAlign: TextAlign.center,
        ),
      );
    }
    return Tooltip(
      message: 'Exemple de raccord',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: AspectRatio(
              aspectRatio: 1,
              child: Column(
                children: [
                  for (var row = 0; row < 3; row++)
                    Expanded(
                      child: Row(
                        children: [
                          for (var column = 0; column < 3; column++)
                            Expanded(
                              child: visuals.tileThumbnail(
                                tiles[row * 3 + column],
                                size: size / 3,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (size >= 100) ...[
            const SizedBox(height: 4),
            Text(
              'Exemple de raccord',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
