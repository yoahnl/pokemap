part of 'verification_workspace_page.dart';

const _nodeSize = Size(164, 72);
const _columnGap = 84.0;
const _rowGap = 18.0;

extension _VerificationGraphView on _VerificationWorkspacePageState {
  Widget _graphPanel() {
    final graph = controller.graph;
    return StudioPanel(
      title: 'Carte de progression narrative',
      actions: [
        StudioTool(
          label: 'Réduire',
          icon: Icons.remove,
          onPressed: () => _zoom(1 / 1.2),
        ),
        StudioTool(
          label: 'Agrandir',
          icon: Icons.add,
          onPressed: () => _zoom(1.2),
        ),
        StudioTool(
          label: 'Ajuster à la vue',
          icon: Icons.fit_screen_outlined,
          onPressed: () {
            view.graphTransform.value = Matrix4.identity();
            refresh();
          },
        ),
      ],
      children: [
        Text(graph.title, style: _labelStyle),
        const SizedBox(height: 6),
        Expanded(
          child: graph.isEmpty
              ? const StudioEmptyState(
                  title: 'Aucun contexte à dessiner',
                  description:
                      'Le graphe montre les dépendances réelles du rapport. '
                      'Il n’en invente aucune et ne modifie rien.',
                  icon: Icons.hub_outlined,
                )
              : ClipRect(
                  child: InteractiveViewer(
                    key: const ValueKey('verification-graph-viewport'),
                    transformationController: view.graphTransform,
                    constrained: false,
                    alignment: Alignment.topLeft,
                    minScale: .3,
                    maxScale: 3,
                    boundaryMargin: const EdgeInsets.all(240),
                    child: _canvas(graph),
                  ),
                ),
        ),
        if (graph.hiddenCount > 0)
          Text(
            '${graph.hiddenCount} voisin(s) replié(s) pour garder le dessin '
            'lisible.',
            style: _labelStyle,
          ),
      ],
    );
  }

  void _zoom(double factor) {
    view.graphTransform.value = view.graphTransform.value.clone()
      ..scaleByDouble(factor, factor, 1, 1);
    refresh();
  }

  Widget _canvas(VerificationGraph graph) {
    final placed = _layout(graph);
    var width = 0.0, height = 0.0;
    for (final offset in placed.values) {
      width = width < offset.dx + _nodeSize.width
          ? offset.dx + _nodeSize.width
          : width;
      height = height < offset.dy + _nodeSize.height
          ? offset.dy + _nodeSize.height
          : height;
    }
    return SizedBox(
      width: width + 24,
      height: height + 24,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _EdgePainter(
                graph: graph,
                positions: placed,
                colour: Theme.of(context).colorScheme.outline,
                unresolvedColour: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
          for (final node in graph.nodes)
            if (placed[node.id] case final offset?)
              Positioned(
                left: offset.dx,
                top: offset.dy,
                width: _nodeSize.width,
                height: _nodeSize.height,
                child: _node(node),
              ),
        ],
      ),
    );
  }

  /// Owners on the left, the selected element in the middle, what it points at
  /// on the right. An overview simply flows in rows.
  Map<String, Offset> _layout(VerificationGraph graph) {
    final positions = <String, Offset>{};
    if (graph.focusId == null) {
      const perRow = 3;
      for (var index = 0; index < graph.nodes.length; index++) {
        positions[graph.nodes[index].id] = Offset(
          12 + (index % perRow) * (_nodeSize.width + _columnGap),
          12 + (index ~/ perRow) * (_nodeSize.height + _rowGap),
        );
      }
      return positions;
    }
    final columns = <VerificationNodeRole, List<VerificationGraphNode>>{
      VerificationNodeRole.owner: [],
      VerificationNodeRole.focus: [],
      VerificationNodeRole.target: [],
    };
    for (final node in graph.nodes) {
      (columns[node.role] ?? columns[VerificationNodeRole.target]!).add(node);
    }
    var column = 0;
    for (final role in [
      VerificationNodeRole.owner,
      VerificationNodeRole.focus,
      VerificationNodeRole.target,
    ]) {
      final nodes = columns[role]!;
      for (var index = 0; index < nodes.length; index++) {
        positions[nodes[index].id] = Offset(
          12 + column * (_nodeSize.width + _columnGap),
          12 + index * (_nodeSize.height + _rowGap),
        );
      }
      column++;
    }
    return positions;
  }

  Widget _node(VerificationGraphNode node) {
    final focus = node.id == controller.graph.focusId;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: node.missing
              ? scheme.error
              : focus
              ? scheme.primary
              : scheme.outlineVariant,
          width: focus ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            node.missing
                ? '${verificationKindLabel(node.kind)} · introuvable'
                : verificationKindLabel(node.kind),
            style: TextStyle(
              fontSize: 11,
              color: node.missing ? scheme.error : scheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              node.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _EdgePainter extends CustomPainter {
  const _EdgePainter({
    required this.graph,
    required this.positions,
    required this.colour,
    required this.unresolvedColour,
  });

  final VerificationGraph graph;
  final Map<String, Offset> positions;
  final Color colour;
  final Color unresolvedColour;

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in graph.edges) {
      final from = positions[edge.from], to = positions[edge.to];
      if (from == null || to == null) continue;
      final paint = Paint()
        ..color = edge.unresolved ? unresolvedColour : colour
        ..strokeWidth = edge.unresolved ? 1.6 : 1
        ..style = PaintingStyle.stroke;
      final start = Offset(
        from.dx + _nodeSize.width,
        from.dy + _nodeSize.height / 2,
      );
      final end = Offset(to.dx, to.dy + _nodeSize.height / 2);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(
          start.dx + _columnGap / 2,
          start.dy,
          end.dx - _columnGap / 2,
          end.dy,
          end.dx,
          end.dy,
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_EdgePainter oldDelegate) =>
      oldDelegate.graph != graph || oldDelegate.positions != positions;
}
