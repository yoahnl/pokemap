import 'package:avelune_studio/features/terrains/application/terrain_scratch_editing_session.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/terrains/application/terrain_draft_controller.dart';
import '../../../features/terrains/domain/terrain_spatial_preview_map.dart';
import '../../shared/widgets/feedback/studio_notice.dart';

import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';

import 'terrain_spatial_preview.dart';

typedef TerrainFrameBuilder = Widget Function(
  SmartTileFrameRef frame,
  double size,
);

class TerrainScratchView extends StatefulWidget {
  const TerrainScratchView({
    super.key,
    required this.controller,
    required this.frameBuilder,
    required this.onChanged,
    required this.tool,
    this.visuals,
  });
  final TerrainDraftController controller;
  final TerrainFrameBuilder frameBuilder;
  final VoidCallback onChanged;
  final String tool;
  final MapWorkspaceVisuals? visuals;

  @override
  State<TerrainScratchView> createState() => _TerrainScratchViewState();
}

class _TerrainScratchViewState extends State<TerrainScratchView> {
  late final editing = TerrainScratchEditingSession(() => controller);
  TerrainDraftController get controller => widget.controller;

  TerrainScratchTool get tool => switch (widget.tool) {
    'Examiner' => TerrainScratchTool.inspect,
    'Gommer' => TerrainScratchTool.erase,
    _ => TerrainScratchTool.paint,
  };

  void _act(GridPos point) {
    editing.update(point, tool);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    if (controller.spatial) {
      try {
        final preview = terrainSpatialPreviewMap(
          project: controller.manifest,
          preset: controller.previewPreset,
          size: TerrainDraftController.scratchSize,
          cells: controller.scratch,
          materials: controller.draft.materials,
        );
        return AspectRatio(
          aspectRatio: 1,
          child: widget.visuals == null
              ? const StudioNotice('Aperçu 3D indisponible')
              : TerrainSpatialPreview(
                  key: const ValueKey('terrain-scratch'),
                  map: preview.map,
                  project: preview.project,
                  visuals: widget.visuals!,
                  onCell: (x, z) {
                    editing.end();
                    _act(GridPos(x: x, y: z));
                    editing.end();
                  },
                  onDragStart: (x, z, _) {
                    editing.end();
                    _act(GridPos(x: x, y: z));
                    return true;
                  },
                  onDragUpdate: (cell) => _act(GridPos(x: cell.$1, y: cell.$2)),
                  onDragEnd: () => editing.end(),
                  onDragCancel: () => editing.end(),
                ),
        );
      } on FormatException {
        return const StudioNotice(
          'Une pièce dépasse le terrain d’essai. Vérifiez ses points d’appui et ses décalages.',
        );
      }
    }
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.clamp(170.0, 408.0);
        final cell = width / TerrainDraftController.scratchSize;
        void act(Offset position) {
          final point = GridPos(
            x: (position.dx / cell).floor(),
            y: (position.dy / cell).floor(),
          );
          if (point.x < 0 || point.y < 0 || point.x >= 17 || point.y >= 17) {
            return;
          }
          _act(point);
        }

        return Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            height: width,
            child: Listener(
              key: const ValueKey('terrain-scratch'),
              behavior: HitTestBehavior.opaque,
              onPointerDown: (event) {
                editing.end();
                act(event.localPosition);
              },
              onPointerUp: (_) => editing.end(),
              onPointerCancel: (_) => editing.end(),
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
                          ? widget.frameBuilder(source.frame, cell)
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
