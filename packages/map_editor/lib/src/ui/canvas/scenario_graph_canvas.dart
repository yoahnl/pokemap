import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/scenario/scenario_authoring_ux.dart';
import '../../features/scenario/scenario_flow_diagnostics.dart';
import '../shared/cupertino_editor_widgets.dart';

const double _kScenarioCanvasWidth = 3800;
const double _kScenarioCanvasHeight = 2600;
const double _kNodeWidth = 220;
const double _kNodeHeight = 132;

class ScenarioGraphCanvas extends ConsumerStatefulWidget {
  const ScenarioGraphCanvas({super.key});

  @override
  ConsumerState<ScenarioGraphCanvas> createState() =>
      _ScenarioGraphCanvasState();
}

class _ScenarioGraphCanvasState extends ConsumerState<ScenarioGraphCanvas> {
  final TransformationController _transformController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _resetViewport();
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _resetViewport() {
    _transformController.value = Matrix4.identity()
      ..translateByDouble(420.0, 220.0, 0.0, 1.0)
      ..scaleByDouble(0.9, 0.9, 0.9, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final project = state.project;
    if (project == null) {
      return Center(
        child: Text(
          'No project loaded',
          style: TextStyle(
            color: CupertinoColors.placeholderText.resolveFrom(context),
          ),
        ),
      );
    }

    final scenario = notifier.getSelectedScenario();
    if (scenario == null) {
      return _ScenarioEmptyWorkspace(
        onCreate: () => _promptCreateScenario(context, notifier),
      );
    }

    final nodesById = <String, ScenarioNode>{
      for (final node in scenario.nodes) node.id: node,
    };
    final selectedNodeId = state.selectedScenarioNodeId;
    final pendingFromNodeId = state.pendingScenarioEdgeFromNodeId;
    final selectedNode =
        selectedNodeId == null ? null : nodesById[selectedNodeId];
    final diagnostics = analyzeScenarioFlow(
      scenario,
      graphRuntimeConnected: kScenarioGraphRuntimeExecutionConnected,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  EditorChrome.largeIslandSurfaceColor(context),
                  Color.lerp(
                    EditorChrome.largeIslandSurfaceColor(context),
                    EditorChrome.inspectorJoyMint,
                    0.08,
                  )!,
                ],
              ),
            ),
            child: InteractiveViewer(
              constrained: false,
              minScale: 0.35,
              maxScale: 2.2,
              boundaryMargin: const EdgeInsets.all(2400),
              transformationController: _transformController,
              child: SizedBox(
                width: _kScenarioCanvasWidth,
                height: _kScenarioCanvasHeight,
                child: Stack(
                  children: [
                    CustomPaint(
                      size: const Size(
                          _kScenarioCanvasWidth, _kScenarioCanvasHeight),
                      painter: _ScenarioEdgesPainter(
                        scenario: scenario,
                        nodesById: nodesById,
                        selectedNodeId: selectedNodeId,
                      ),
                    ),
                    for (final node in scenario.nodes)
                      Positioned(
                        left: node.position.x,
                        top: node.position.y,
                        child: _ScenarioNodeCard(
                          node: node,
                          isEntry: scenario.entryNodeId == node.id,
                          isSelected: selectedNodeId == node.id,
                          isPendingFrom: pendingFromNodeId == node.id,
                          onTap: () => _handleNodeTap(
                            notifier: notifier,
                            scenario: scenario,
                            node: node,
                            pendingFromNodeId: pendingFromNodeId,
                          ),
                          onStartLink: () =>
                              notifier.beginScenarioEdgeFromNode(node.id),
                          onSetEntry: () => notifier.setScenarioEntryNode(
                            scenarioId: scenario.id,
                            nodeId: node.id,
                          ),
                          onDelete: () => notifier.deleteScenarioNode(
                            scenarioId: scenario.id,
                            nodeId: node.id,
                          ),
                          onMoveBy: (delta) => _moveNode(
                            notifier: notifier,
                            scenario: scenario,
                            node: node,
                            delta: delta,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 14,
          top: 14,
          child: _ScenarioGraphToolbar(
            scenario: scenario,
            diagnostics: diagnostics,
            pendingFromNodeId: pendingFromNodeId,
            onAddNode: () => _promptAddNode(context, notifier, scenario),
            onClearLinkDraft: pendingFromNodeId == null
                ? null
                : () => notifier.beginScenarioEdgeFromNode(null),
            onAutoLayout: () => _autoLayoutScenario(notifier, scenario),
            onResetViewport: _resetViewport,
          ),
        ),
        Positioned(
          right: 14,
          top: 14,
          child: _ScenarioSelectionOverlay(
            scenario: scenario,
            selectedNode: selectedNode,
            onDeleteEdge: (edgeId) => notifier.deleteScenarioEdge(
              scenarioId: scenario.id,
              edgeId: edgeId,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _promptCreateScenario(
    BuildContext context,
    EditorNotifier notifier,
  ) async {
    final controller = TextEditingController();
    final ok = await showMacosEditorPromptSheet(
      context,
      title: 'Create first scenario',
      controller: controller,
      confirmLabel: 'Create',
      placeholder: 'Scenario name',
    );
    if (!ok || !context.mounted) return;
    final name = controller.text.trim();
    if (name.isEmpty) return;
    await notifier.createProjectScenario(name: name);
  }

  Future<void> _promptAddNode(
    BuildContext context,
    EditorNotifier notifier,
    ScenarioAsset scenario,
  ) async {
    final type = await showCupertinoListPicker<ScenarioNodeType>(
      context: context,
      title: 'Node type',
      items: ScenarioNodeType.values,
      labelOf: scenarioNodeTypePickerLabel,
    );
    if (type == null || !context.mounted) return;
    final titleController = TextEditingController(
      text: defaultScenarioNodeTitle(type),
    );
    final ok = await showMacosEditorPromptSheet(
      context,
      title: 'New ${scenarioNodeTypeLabel(type)} node',
      controller: titleController,
      confirmLabel: 'Add',
      placeholder: 'Node title',
    );
    if (!ok || !context.mounted) return;
    final title = titleController.text.trim();
    if (title.isEmpty) return;
    await notifier.addScenarioNode(
      scenarioId: scenario.id,
      type: type,
      title: title,
      position: _nextNodePosition(scenario),
    );
  }

  void _handleNodeTap({
    required EditorNotifier notifier,
    required ScenarioAsset scenario,
    required ScenarioNode node,
    required String? pendingFromNodeId,
  }) {
    if (pendingFromNodeId != null && pendingFromNodeId != node.id) {
      notifier.addScenarioEdge(
        scenarioId: scenario.id,
        fromNodeId: pendingFromNodeId,
        toNodeId: node.id,
      );
    }
    notifier.selectScenarioNode(node.id);
  }

  void _moveNode({
    required EditorNotifier notifier,
    required ScenarioAsset scenario,
    required ScenarioNode node,
    required Offset delta,
  }) {
    final scale = _transformController.value.getMaxScaleOnAxis();
    final localDelta = delta / (scale <= 0 ? 1 : scale);
    final nextX = (node.position.x + localDelta.dx)
        .clamp(0, _kScenarioCanvasWidth - _kNodeWidth);
    final nextY = (node.position.y + localDelta.dy)
        .clamp(0, _kScenarioCanvasHeight - _kNodeHeight);
    notifier.moveScenarioNode(
      scenarioId: scenario.id,
      nodeId: node.id,
      position: ScenarioNodePosition(
        x: nextX.toDouble(),
        y: nextY.toDouble(),
      ),
    );
  }

  ScenarioNodePosition _nextNodePosition(ScenarioAsset scenario) {
    if (scenario.nodes.isEmpty) {
      return const ScenarioNodePosition(x: 240, y: 220);
    }
    final base = scenario.nodes.last.position;
    return ScenarioNodePosition(
      x: (base.x + 260).clamp(80, _kScenarioCanvasWidth - _kNodeWidth - 80),
      y: (base.y + 40).clamp(80, _kScenarioCanvasHeight - _kNodeHeight - 80),
    );
  }

  Future<void> _autoLayoutScenario(
    EditorNotifier notifier,
    ScenarioAsset scenario,
  ) async {
    var x = 220.0;
    var y = 160.0;
    const maxColumns = 4;
    var index = 0;
    for (final node in scenario.nodes) {
      await notifier.moveScenarioNode(
        scenarioId: scenario.id,
        nodeId: node.id,
        position: ScenarioNodePosition(x: x, y: y),
      );
      index++;
      if (index % maxColumns == 0) {
        x = 220.0;
        y += 210;
      } else {
        x += 290;
      }
    }
  }
}

class _ScenarioEmptyWorkspace extends StatelessWidget {
  const _ScenarioEmptyWorkspace({
    required this.onCreate,
  });

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: EditorChrome.largeIslandSurfaceColor(
              context,
              tint: EditorChrome.inspectorJoyMint.withValues(alpha: 0.08),
            ),
            border: Border.all(
              color: EditorChrome.inspectorJoyMint.withValues(alpha: 0.52),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scenario Workspace',
                  style: TextStyle(
                    color: CupertinoColors.label.resolveFrom(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Crée un premier scénario pour organiser visuellement la progression narrative, les scripts, les dialogues et les liens vers le monde.',
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),
                CupertinoButton.filled(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: const Size(0, 34),
                  onPressed: onCreate,
                  child: const Text('Create scenario graph'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScenarioGraphToolbar extends StatelessWidget {
  const _ScenarioGraphToolbar({
    required this.scenario,
    required this.diagnostics,
    required this.pendingFromNodeId,
    required this.onAddNode,
    required this.onClearLinkDraft,
    required this.onAutoLayout,
    required this.onResetViewport,
  });

  final ScenarioAsset scenario;
  final ScenarioFlowReport diagnostics;
  final String? pendingFromNodeId;
  final VoidCallback onAddNode;
  final VoidCallback? onClearLinkDraft;
  final VoidCallback onAutoLayout;
  final VoidCallback onResetViewport;

  @override
  Widget build(BuildContext context) {
    final errorCount = diagnostics.issues
        .where((issue) => issue.severity == ScenarioFlowIssueSeverity.error)
        .length;
    final warningCount = diagnostics.issues
        .where((issue) => issue.severity == ScenarioFlowIssueSeverity.warning)
        .length;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.1),
        ),
        border: Border.all(
          color: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.48),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${scenario.name} · ${scenarioScopeLabel(scenario.scope)} · ${scenario.nodes.length} nodes · ${scenario.edges.length} links',
              style: TextStyle(
                color: CupertinoColors.label.resolveFrom(context),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Diag: $errorCount erreur(s) · $warningCount avertissement(s) · ${diagnostics.summary.unreachableNodes} non atteignable(s)',
              style: TextStyle(
                color: errorCount > 0
                    ? EditorChrome.inspectorJoyCoral
                    : CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _TinyActionButton(
                  label: 'Add node',
                  icon: CupertinoIcons.plus,
                  onPressed: onAddNode,
                ),
                _TinyActionButton(
                  label: 'Auto-layout',
                  icon: CupertinoIcons.square_grid_3x2,
                  onPressed: onAutoLayout,
                ),
                _TinyActionButton(
                  label: 'Center view',
                  icon: CupertinoIcons.scope,
                  onPressed: onResetViewport,
                ),
                if (onClearLinkDraft != null)
                  _TinyActionButton(
                    label: 'Cancel link',
                    icon: CupertinoIcons.clear,
                    onPressed: onClearLinkDraft!,
                  ),
              ],
            ),
            if (pendingFromNodeId != null) ...[
              const SizedBox(height: 6),
              Text(
                'Link draft from: $pendingFromNodeId · click target node',
                style: const TextStyle(
                  color: EditorChrome.inspectorJoyCyan,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScenarioSelectionOverlay extends StatelessWidget {
  const _ScenarioSelectionOverlay({
    required this.scenario,
    required this.selectedNode,
    required this.onDeleteEdge,
  });

  final ScenarioAsset scenario;
  final ScenarioNode? selectedNode;
  final ValueChanged<String> onDeleteEdge;

  @override
  Widget build(BuildContext context) {
    if (selectedNode == null) {
      return const SizedBox.shrink();
    }
    final outgoing = scenario.edges
        .where((edge) => edge.fromNodeId == selectedNode!.id)
        .toList(growable: false)
      ..sort((a, b) => a.order.compareTo(b.order));
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: EditorChrome.largeIslandSurfaceColor(
            context,
            tint: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.08),
          ),
          border: Border.all(
            color: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.44),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Outgoing links · ${selectedNode!.id}',
                style: TextStyle(
                  color: CupertinoColors.label.resolveFrom(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              if (outgoing.isEmpty)
                Text(
                  'No outgoing links',
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    fontSize: 11,
                  ),
                )
              else
                ...outgoing.map(
                  (edge) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${edge.id}: ${edge.toNodeId}${edge.label.trim().isEmpty ? '' : ' · ${edge.label}'}',
                            style: TextStyle(
                              color: CupertinoColors.secondaryLabel
                                  .resolveFrom(context),
                              fontSize: 11,
                            ),
                          ),
                        ),
                        _TinyActionButton(
                          label: 'Remove',
                          icon: CupertinoIcons.delete,
                          onPressed: () => onDeleteEdge(edge.id),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScenarioNodeCard extends StatelessWidget {
  const _ScenarioNodeCard({
    required this.node,
    required this.isEntry,
    required this.isSelected,
    required this.isPendingFrom,
    required this.onTap,
    required this.onStartLink,
    required this.onSetEntry,
    required this.onDelete,
    required this.onMoveBy,
  });

  final ScenarioNode node;
  final bool isEntry;
  final bool isSelected;
  final bool isPendingFrom;
  final VoidCallback onTap;
  final VoidCallback onStartLink;
  final VoidCallback onSetEntry;
  final VoidCallback onDelete;
  final ValueChanged<Offset> onMoveBy;

  @override
  Widget build(BuildContext context) {
    final accent = _colorForNodeType(node.type);
    final displayTitle = node.title.trim().isEmpty
        ? scenarioNodeTypeLabel(node.type)
        : node.title.trim();
    return GestureDetector(
      onTap: onTap,
      onPanUpdate: (details) => onMoveBy(details.delta),
      child: SizedBox(
        width: _kNodeWidth,
        height: _kNodeHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Color.lerp(
              EditorChrome.largeIslandSurfaceColor(context),
              accent,
              isSelected ? 0.2 : 0.1,
            ),
            border: Border.all(
              color: isPendingFrom
                  ? EditorChrome.inspectorJoyCyan
                  : (isSelected
                      ? accent.withValues(alpha: 0.9)
                      : accent.withValues(alpha: 0.48)),
              width: isSelected ? 1.8 : 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: isSelected ? 0.22 : 0.12),
                blurRadius: isSelected ? 22 : 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _iconForNodeType(node.type),
                      size: 14,
                      color: accent,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        scenarioNodeTypeLabel(node.type),
                        style: TextStyle(
                          color: accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    if (isEntry)
                      const Icon(
                        CupertinoIcons.play_circle_fill,
                        size: 14,
                        color: EditorChrome.inspectorJoyMint,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  displayTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: CupertinoColors.label.resolveFrom(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const Spacer(),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    _TinyActionButton(
                      label: 'Link',
                      icon: CupertinoIcons.link,
                      onPressed: onStartLink,
                    ),
                    _TinyActionButton(
                      label: 'Entry',
                      icon: CupertinoIcons.play,
                      onPressed: onSetEntry,
                    ),
                    _TinyActionButton(
                      label: 'Delete',
                      icon: CupertinoIcons.delete,
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TinyActionButton extends StatelessWidget {
  const _TinyActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      minimumSize: const Size(0, 22),
      color: EditorChrome.largeIslandSurfaceColor(
        context,
        tint: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.08),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenarioEdgesPainter extends CustomPainter {
  _ScenarioEdgesPainter({
    required this.scenario,
    required this.nodesById,
    required this.selectedNodeId,
  });

  final ScenarioAsset scenario;
  final Map<String, ScenarioNode> nodesById;
  final String? selectedNodeId;

  @override
  void paint(Canvas canvas, Size size) {
    final defaultPaint = Paint()
      ..color = const Color(0x88989EB0)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    final selectedPaint = Paint()
      ..color = EditorChrome.inspectorJoyCyan.withValues(alpha: 0.9)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    for (final edge in scenario.edges) {
      final from = nodesById[edge.fromNodeId];
      final to = nodesById[edge.toNodeId];
      if (from == null || to == null) {
        continue;
      }
      final fromCenter = Offset(
        from.position.x + _kNodeWidth,
        from.position.y + _kNodeHeight * 0.5,
      );
      final toCenter = Offset(
        to.position.x,
        to.position.y + _kNodeHeight * 0.5,
      );
      final controlDx =
          math.max(56.0, (toCenter.dx - fromCenter.dx).abs() * 0.38);
      final path = Path()
        ..moveTo(fromCenter.dx, fromCenter.dy)
        ..cubicTo(
          fromCenter.dx + controlDx,
          fromCenter.dy,
          toCenter.dx - controlDx,
          toCenter.dy,
          toCenter.dx,
          toCenter.dy,
        );

      final isSelected =
          selectedNodeId == edge.fromNodeId || selectedNodeId == edge.toNodeId;
      final edgePaint = isSelected ? selectedPaint : defaultPaint;
      canvas.drawPath(path, edgePaint);
      canvas.drawCircle(
        toCenter,
        3.5,
        Paint()..color = edgePaint.color,
      );

      final label = edge.label.trim();
      if (label.isNotEmpty) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 10,
              color: edgePaint.color,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 160);
        final mid = Offset(
          (fromCenter.dx + toCenter.dx) * 0.5,
          (fromCenter.dy + toCenter.dy) * 0.5 - 10,
        );
        final bgRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            mid.dx - 4,
            mid.dy - 2,
            textPainter.width + 8,
            textPainter.height + 4,
          ),
          const Radius.circular(6),
        );
        canvas.drawRRect(
          bgRect,
          Paint()..color = const Color(0xCC11131A),
        );
        textPainter.paint(canvas, Offset(mid.dx, mid.dy));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ScenarioEdgesPainter oldDelegate) {
    return oldDelegate.scenario != scenario ||
        oldDelegate.selectedNodeId != selectedNodeId;
  }
}

Color _colorForNodeType(ScenarioNodeType type) {
  return switch (type) {
    ScenarioNodeType.start => EditorChrome.inspectorJoyMint,
    ScenarioNodeType.dialogue => EditorChrome.inspectorJoyLilac,
    ScenarioNodeType.action => EditorChrome.inspectorJoyCyan,
    ScenarioNodeType.condition => EditorChrome.inspectorJoyAmber,
    ScenarioNodeType.choice => EditorChrome.inspectorJoyHoney,
    ScenarioNodeType.reference => EditorChrome.inspectorJoyBlue,
    ScenarioNodeType.end => EditorChrome.inspectorJoyCoral,
  };
}

IconData _iconForNodeType(ScenarioNodeType type) {
  return switch (type) {
    ScenarioNodeType.start => CupertinoIcons.play_fill,
    ScenarioNodeType.dialogue => CupertinoIcons.chat_bubble_text_fill,
    ScenarioNodeType.action => CupertinoIcons.bolt_fill,
    ScenarioNodeType.condition => CupertinoIcons.question_circle_fill,
    ScenarioNodeType.choice => CupertinoIcons.arrow_branch,
    ScenarioNodeType.reference => CupertinoIcons.link,
    ScenarioNodeType.end => CupertinoIcons.stop_circle_fill,
  };
}
