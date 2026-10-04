import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'map_workspace_visuals.dart';

class MapResizePreview extends StatelessWidget {
  const MapResizePreview({
    super.key,
    required this.map,
    required this.project,
    required this.visuals,
    required this.proposedWidth,
    required this.proposedHeight,
  });
  final MapData map;
  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final int proposedWidth, proposedHeight;

  @override
  Widget build(BuildContext context) {
    final factory = visuals;
    if (factory is! MapWorkspacePreviewVisuals) {
      return const Text(
        'Aperçu visuel indisponible ; les conséquences sont analysées ci-dessus.',
      );
    }
    final cellWidth =
        project.settings.tileWidth * project.settings.displayScale.toDouble();
    final cellHeight =
        project.settings.tileHeight * project.settings.displayScale.toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Aperçu des limites proposées'),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: math.max(map.size.width, proposedWidth) * cellWidth,
              height: math.max(map.size.height, proposedHeight) * cellHeight,
              child: Stack(
                children: [
                  SizedBox(
                    width: map.size.width * cellWidth,
                    height: map.size.height * cellHeight,
                    child: (factory as MapWorkspacePreviewVisuals)
                        .previewCanvas(map),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    width: proposedWidth * cellWidth,
                    height: proposedHeight * cellHeight,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Text('$proposedWidth × $proposedHeight cases · contour bleu'),
      ],
    );
  }
}
