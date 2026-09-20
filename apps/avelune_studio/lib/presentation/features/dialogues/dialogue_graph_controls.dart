import 'package:flutter/material.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/layout/studio_graph_card.dart';
import '../../shared/widgets/feedback/studio_badge.dart';
import 'dialogue_graph_geometry.dart';

class DialogueGraphControls extends StatelessWidget {
  const DialogueGraphControls({super.key, required this.geometry});
  final DialogueGraphGeometry geometry;
  @override
  Widget build(BuildContext context) {
    final view = geometry.view.viewport;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StudioTool(
          label: 'Réduire le dialogue',
          icon: Icons.remove,
          onPressed: () =>
              view.zoomAt(view.zoom * .9, view.size.center(Offset.zero)),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text('${(view.zoom * 100).round()} %'),
        ),
        StudioTool(
          label: 'Agrandir le dialogue',
          icon: Icons.add,
          onPressed: () =>
              view.zoomAt(view.zoom * 1.1, view.size.center(Offset.zero)),
        ),
        StudioTool(
          label: 'Cadrer le dialogue',
          icon: Icons.fit_screen,
          onPressed: () => view.fit(geometry.bounds),
        ),
      ],
    );
  }
}

class DialogueMinimap extends StatelessWidget {
  const DialogueMinimap({super.key, required this.geometry});
  final DialogueGraphGeometry geometry;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Vue d’ensemble · cliquer pour se déplacer',
    child: StudioGraphCard(
      child: SizedBox(
        width: 148,
        height: 86,
        child: LayoutBuilder(
          builder: (context, size) {
            final bounds = geometry.bounds.inflate(50);
            Offset local(Offset point) => Offset(
              (point.dx - bounds.left) / bounds.width * size.maxWidth,
              (point.dy - bounds.top) / bounds.height * size.maxHeight,
            );
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) => geometry.view.viewport.centerOn(
                Offset(
                  bounds.left +
                      details.localPosition.dx / size.maxWidth * bounds.width,
                  bounds.top +
                      details.localPosition.dy / size.maxHeight * bounds.height,
                ),
              ),
              child: Stack(
                children: [
                  for (final node in geometry.document.nodes)
                    Positioned(
                      left: local(geometry.rect(node.id).topLeft).dx,
                      top: local(geometry.rect(node.id).topLeft).dy,
                      width:
                          geometry.rect(node.id).width /
                          bounds.width *
                          size.maxWidth,
                      height:
                          geometry.rect(node.id).height /
                          bounds.height *
                          size.maxHeight,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: StudioTone.feature
                              .color(context)
                              .withValues(alpha: .4),
                          border: Border.all(
                            color: node.id == geometry.view.nodeId
                                ? StudioTone.info.color(context)
                                : Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}
