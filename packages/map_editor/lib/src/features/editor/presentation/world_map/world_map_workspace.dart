import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../ui/design_system/design_system.dart';
import 'world_map_canvas_region.dart';
import 'world_map_workspace_session.dart';

typedef WorldMapExplorerBuilder = Widget Function(
  BuildContext context,
  VoidCallback onCollapse,
);

typedef WorldMapExplorerRailBuilder = Widget Function(
  BuildContext context,
  VoidCallback onReopen,
);

/// Structural, map-only workspace composition.
///
/// Tool behavior and inspector behavior remain injected while this shell owns
/// only transient chrome layout and the existing canvas/explorer boundaries.
class WorldMapWorkspace extends ConsumerWidget {
  const WorldMapWorkspace({
    Key? key,
    required this.toolSlot,
    required this.inspectorSlot,
    required this.stageHeaderSlot,
    required this.explorerBuilder,
    required this.explorerRailBuilder,
  }) : super(
          key: key ?? const ValueKey<String>('world-map-workspace'),
        );

  static const minInspectorWidth = 280.0;
  static const maxInspectorWidth = 560.0;

  final Widget toolSlot;
  final Widget inspectorSlot;
  final Widget stageHeaderSlot;
  final WorldMapExplorerBuilder explorerBuilder;
  final WorldMapExplorerRailBuilder explorerRailBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(worldMapWorkspaceSessionProvider);
    final controller = ref.read(worldMapWorkspaceSessionProvider.notifier);
    final appWindow = MediaQuery.sizeOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final budget = PokeMapDesktopLayout.resolve(
          Size(constraints.maxWidth, appWindow.height),
          explorerExpanded: session.explorerExpanded,
          inspectorVisible: session.inspectorVisible,
        );
        final compactExplorerOverlay =
            budget.windowClass == PokeMapDesktopWindowClass.compact &&
                session.explorerExpanded &&
                !session.inspectorVisible;
        final explorerIsExpanded =
            budget.explorerIsExpanded || compactExplorerOverlay;
        final explorerWidth = explorerIsExpanded
            ? PokeMapDesktopLayoutTokens.explorerExpandedWidth
            : PokeMapDesktopLayoutTokens.explorerRailWidth;
        final inspectorIsOverlay =
            session.inspectorVisible && budget.inspectorIsOverlay;
        final inspectorIsDocked =
            session.inspectorVisible && !budget.inspectorIsOverlay;
        final inspectorMaxWidth = math.max(
          minInspectorWidth,
          math.min(
            maxInspectorWidth,
            constraints.maxWidth -
                explorerWidth -
                PokeMapDesktopLayoutTokens.inspectorResizeHandleWidth -
                PokeMapDesktopLayoutTokens.minCanvasWidth -
                36,
          ),
        );
        final inspectorWidth = session.inspectorWidth
            .clamp(minInspectorWidth, inspectorMaxWidth)
            .toDouble();

        void collapseExplorer() {
          controller
            ..setExplorerExpanded(false)
            ..setInspectorWidth(maxInspectorWidth);
        }

        void reopenExplorer() {
          if (!budget.explorerIsExpanded && session.inspectorVisible) {
            controller.setInspectorVisible(false);
          }
          controller.setExplorerExpanded(true);
        }

        void resizeInspector(double delta) {
          controller.setInspectorWidth(
            (inspectorWidth - delta)
                .clamp(minInspectorWidth, inspectorMaxWidth)
                .toDouble(),
          );
        }

        final explorer = _WorldMapExplorerRegion(
          width: explorerWidth,
          expanded: explorerIsExpanded,
          expandedChild: explorerBuilder(context, collapseExplorer),
          reducedChild: explorerRailBuilder(context, reopenExplorer),
        );
        final canvas = Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                stageHeaderSlot,
                const SizedBox(height: 18),
                const Expanded(
                  child: WorldMapCanvasRegion(
                    key: ValueKey<String>('world-map-canvas-region'),
                  ),
                ),
              ],
            ),
          ),
        );
        final inspector = _WorldMapInspectorRegion(
          width: inspectorWidth,
          child: inspectorSlot,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KeyedSubtree(
              key: const ValueKey<String>('world-map-tool-slot'),
              child: toolSlot,
            ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      explorer,
                      canvas,
                      if (inspectorIsDocked) ...[
                        PokeMapHorizontalResizeHandle(
                          key: const ValueKey<String>(
                            'right-inspector-resize-handle',
                          ),
                          tooltip: 'Redimensionner le panneau droit',
                          width: PokeMapDesktopLayoutTokens
                              .inspectorResizeHandleWidth,
                          onDrag: resizeInspector,
                        ),
                        KeyedSubtree(
                          key: const ValueKey<String>(
                            'world-map-inspector-dock',
                          ),
                          child: inspector,
                        ),
                      ],
                    ],
                  ),
                  if (inspectorIsOverlay)
                    Positioned(
                      key: const ValueKey<String>(
                        'world-map-inspector-overlay',
                      ),
                      top: 0,
                      right: 0,
                      bottom: 0,
                      child: inspector,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WorldMapExplorerRegion extends StatelessWidget {
  const _WorldMapExplorerRegion({
    required this.width,
    required this.expanded,
    required this.expandedChild,
    required this.reducedChild,
  });

  final double width;
  final bool expanded;
  final Widget expandedChild;
  final Widget reducedChild;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: KeyedSubtree(
        key: const ValueKey<String>('project-explorer-region'),
        child: OverflowBox(
          minWidth: PokeMapDesktopLayoutTokens.explorerRailWidth,
          maxWidth: 520,
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: PokeMapDesktopLayoutTokens.explorerExpandedWidth,
                  child: AnimatedOpacity(
                    key: const ValueKey<String>(
                      'project-explorer-expanded-state',
                    ),
                    duration: const Duration(milliseconds: 100),
                    opacity: expanded ? 1 : 0,
                    child: IgnorePointer(
                      ignoring: !expanded,
                      child: KeyedSubtree(
                        key: const ValueKey<String>(
                          'project-explorer-expanded',
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 18, 12, 18),
                          child: expandedChild,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 14,
                  child: AnimatedOpacity(
                    key: const ValueKey<String>(
                      'project-explorer-reduced-state',
                    ),
                    duration: const Duration(milliseconds: 100),
                    opacity: expanded ? 0 : 1,
                    child: IgnorePointer(
                      ignoring: expanded,
                      child: KeyedSubtree(
                        key: const ValueKey<String>(
                          'project-explorer-reduced',
                        ),
                        child: Center(child: reducedChild),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorldMapInspectorRegion extends StatelessWidget {
  const _WorldMapInspectorRegion({
    required this.width,
    required this.child,
  });

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey<String>('right-inspector-region'),
      width: width,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 18, 16, 18),
        child: PokeMapPanel(
          padding: EdgeInsets.zero,
          expandChild: true,
          borderRadius: 32,
          child: KeyedSubtree(
            key: const ValueKey<String>('world-map-inspector-slot'),
            child: child,
          ),
        ),
      ),
    );
  }
}
