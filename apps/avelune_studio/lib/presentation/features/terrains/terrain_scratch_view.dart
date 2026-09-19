import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/terrains/application/terrain_draft_controller.dart';

typedef TerrainFrameBuilder =
    Widget Function(SmartTileFrameRef frame, double size);

class TerrainScratchView extends StatelessWidget {
  const TerrainScratchView({
    super.key,
    required this.controller,
    required this.frameBuilder,
    required this.onChanged,
    required this.tool,
  });
  final TerrainDraftController controller;
  final TerrainFrameBuilder frameBuilder;
  final VoidCallback onChanged;
  final String tool;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.clamp(170.0, 408.0);
        final cell = width / TerrainDraftController.scratchSize;
        void act(Offset position) {
          final point = GridPos(x: position.dx ~/ cell, y: position.dy ~/ cell);
          if (point.x < 0 || point.y < 0 || point.x >= 17 || point.y >= 17) {
            return;
          }
          if (tool == 'Corriger') {
            controller.inspect(point);
          } else {
            controller.paint(point, erase: tool == 'Gommer');
          }
          onChanged();
        }

        return Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            height: width,
            child: Listener(
              key: const ValueKey('terrain-scratch'),
              behavior: HitTestBehavior.opaque,
              onPointerDown: (event) => act(event.localPosition),
              onPointerMove: (event) {
                if (event.buttons != 0) act(event.localPosition);
              },
              child: IgnorePointer(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 17,
                  ),
                  itemCount: controller.resolved.length,
                  itemBuilder: (context, index) {
                    final resolution = controller.resolved[index];
                    final source = resolution.parts.firstOrNull?.source;
                    final missing =
                        resolution.status !=
                            SmartTileResolutionStatus.resolved &&
                        resolution.status != SmartTileResolutionStatus.noIntent;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: missing
                            ? colors.errorContainer
                            : colors.surfaceContainerLowest,
                        border: Border.all(
                          color: colors.outlineVariant,
                          width: .35,
                        ),
                      ),
                      child: source is SmartTileFrameSource
                          ? frameBuilder(source.frame, cell)
                          : missing
                          ? Icon(
                              Icons.close,
                              size: cell * .65,
                              color: colors.error,
                            )
                          : null,
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
