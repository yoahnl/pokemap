import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/rendering/contracts/map_workspace_visuals.dart';
import '../../../features/rendering/contracts/scoped_resource_preview_visuals.dart';
import '../../../features/resources/application/resource_preview_source.dart';

class ProjectCharacterPoseSheet extends StatelessWidget {
  const ProjectCharacterPoseSheet({
    super.key,
    required this.atlas,
    required this.width,
    required this.height,
    required this.project,
    required this.tilesetId,
    required this.visuals,
    required this.onPick,
  });

  final ProjectRegularAtlasTilesetSource atlas;
  final int width;
  final int height;
  final ProjectManifest project;
  final String tilesetId;
  final MapWorkspaceVisuals? visuals;
  final ValueChanged<TilesetSourceRect>? onPick;

  @override
  Widget build(BuildContext context) {
    final provider = visuals;
    final columns = atlas.pixelWidth ~/ width;
    final rows = atlas.pixelHeight ~/ height;
    return StudioPanel(
      title: 'Planche du personnage',
      icon: Icons.grid_on_outlined,
      children: [
        if (provider is! ScopedResourcePreviewVisuals ||
            columns == 0 ||
            rows == 0)
          const Text('Planche indisponible.')
        else ...[
          const Text(
            'Cliquez sur une case pour l’affecter à la pose sélectionnée.',
          ),
          const SizedBox(height: StudioSpacing.m),
          SizedBox(
            height: 240,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final pixels = Size(
                  atlas.pixelWidth.toDouble(),
                  atlas.pixelHeight.toDouble(),
                );
                final fit = applyBoxFit(
                  BoxFit.contain,
                  pixels,
                  constraints.biggest,
                );
                final bounds = Alignment.center.inscribe(
                  fit.destination,
                  Offset.zero & constraints.biggest,
                );
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: onPick == null
                      ? null
                      : (event) {
                          if (!bounds.contains(event.localPosition)) return;
                          final point = event.localPosition - bounds.topLeft;
                          final column =
                              (point.dx * pixels.width / bounds.width / width)
                                  .floor();
                          final row =
                              (point.dy *
                                      pixels.height /
                                      bounds.height /
                                      height)
                                  .floor();
                          if (column < columns && row < rows) {
                            onPick!(TilesetSourceRect(x: column, y: row));
                          }
                        },
                  child: (provider as ScopedResourcePreviewVisuals)
                      .scopedResourcePreview(
                        AtlasPreviewSource(
                          tilesetId,
                          showGrid: true,
                          gridOverride: ProjectRegularAtlasTilesetSource(
                            assetId: atlas.assetId,
                            pixelWidth: atlas.pixelWidth,
                            pixelHeight: atlas.pixelHeight,
                            tileWidth: width,
                            tileHeight: height,
                          ),
                        ),
                        project,
                        size: 240,
                      ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
