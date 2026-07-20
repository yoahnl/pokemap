import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../features/narrative/application/narrative_workspace_projection.dart';
import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';
import 'scene_graph_read_only_view.dart';

typedef SceneGraphNodeDuplicator = Future<String?> Function(String nodeId);

class SceneGraphEditor extends StatefulWidget {
  const SceneGraphEditor({
    super.key,
    required this.scene,
    this.selectedNodeId,
    this.selectedEdgeId,
    this.onSelectNode,
    this.onSelectEdge,
    this.onUpdateNodeLayout,
    this.onCreateEdgeDraft,
    this.onDuplicateNode,
    this.focusNodeForNodeId,
    this.canDragNodes = true,
  });

  final NarrativeSceneSummary scene;
  final String? selectedNodeId;
  final String? selectedEdgeId;
  final ValueChanged<String>? onSelectNode;
  final ValueChanged<String>? onSelectEdge;
  final SceneNodeLayoutChanged? onUpdateNodeLayout;
  final SceneVisualEdgeDraftCreator? onCreateEdgeDraft;
  final SceneGraphNodeDuplicator? onDuplicateNode;
  final FocusNode Function(String nodeId)? focusNodeForNodeId;
  final bool canDragNodes;

  @override
  State<SceneGraphEditor> createState() => _SceneGraphEditorState();
}

class _SceneGraphEditorState extends State<SceneGraphEditor> {
  final Map<String, String> _outputPortByNodeId = {};
  bool _previewOpen = false;
  SceneDryRunPreviewResult? _preview;

  @override
  void didUpdateWidget(covariant SceneGraphEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scene.id != widget.scene.id ||
        oldWidget.scene.graph != widget.scene.graph) {
      _outputPortByNodeId.clear();
      _preview = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('scene-graph-editor'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildToolbar(),
        if (_previewOpen) ...[
          const SizedBox(height: 8),
          _buildDryRunPanel(context),
        ],
        const SizedBox(height: 8),
        Expanded(
          child: SceneGraphReadOnlyView(
            scene: widget.scene,
            selectedNodeId: widget.selectedNodeId,
            selectedEdgeId: widget.selectedEdgeId,
            focusNodeForNodeId: widget.focusNodeForNodeId,
            onSelectNode: widget.onSelectNode,
            onSelectEdge: widget.onSelectEdge,
            canDragNodes: widget.canDragNodes,
            onCreateEdgeDraft: widget.onCreateEdgeDraft,
            onUpdateNodeLayout: widget.onUpdateNodeLayout,
            expandToFill: true,
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    final selectedNode = _selectedNode;
    final canDuplicate = selectedNode != null &&
        selectedNode.kind != SceneNodeKind.start &&
        selectedNode.kind != SceneNodeKind.branchByOutcome &&
        widget.onDuplicateNode != null;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        PokeMapButton(
          key: const ValueKey('scene-graph-duplicate-node'),
          onPressed: canDuplicate ? _duplicateSelectedNode : null,
          variant: PokeMapButtonVariant.secondary,
          size: PokeMapButtonSize.small,
          leading: const Icon(CupertinoIcons.doc_on_doc, size: 14),
          child: const Text('Dupliquer le nœud'),
        ),
        PokeMapButton(
          key: const ValueKey('scene-graph-toggle-dry-run'),
          onPressed: () => setState(() => _previewOpen = !_previewOpen),
          variant: _previewOpen
              ? PokeMapButtonVariant.primary
              : PokeMapButtonVariant.secondary,
          size: PokeMapButtonSize.small,
          leading: const Icon(CupertinoIcons.play_arrow_solid, size: 14),
          child: const Text('Prévisualiser le chemin'),
        ),
      ],
    );
  }

  Widget _buildDryRunPanel(BuildContext context) {
    final colors = context.pokeMapColors;
    final decisionNodes = widget.scene.graph.nodes.where(
      (node) =>
          node.kind == SceneNodeKind.condition ||
          node.kind == SceneNodeKind.yarnDialogue ||
          node.kind == SceneNodeKind.battle,
    );
    return PokeMapPanel(
      key: const ValueKey('scene-graph-dry-run-panel'),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'État d’entrée explicite',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          for (final node in decisionNodes) ...[
            Text(
              node.title ?? node.id,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final port in authorableSceneOutputPortsForNode(node))
                  PokeMapButton(
                    key: ValueKey(
                      'scene-graph-preview-input-${node.id}-${port.id}',
                    ),
                    onPressed: () => setState(() {
                      _outputPortByNodeId[node.id] = port.id;
                      _preview = null;
                    }),
                    variant: PokeMapButtonVariant.ghost,
                    size: PokeMapButtonSize.small,
                    isSelected: _outputPortByNodeId[node.id] == port.id,
                    child: Text(port.label),
                  ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: PokeMapButton(
              key: const ValueKey('scene-graph-run-dry-run'),
              onPressed: _runDryPreview,
              variant: PokeMapButtonVariant.successOutline,
              size: PokeMapButtonSize.small,
              child: const Text('Calculer le chemin'),
            ),
          ),
          if (_preview case final preview?) ...[
            const SizedBox(height: 8),
            Text(
              _previewMessage(preview),
              key: const ValueKey('scene-graph-dry-run-result'),
              style: TextStyle(
                color: preview.status == SceneDryRunPreviewStatus.failed
                    ? colors.error
                    : colors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  SceneNode? get _selectedNode {
    for (final node in widget.scene.graph.nodes) {
      if (node.id == widget.selectedNodeId) return node;
    }
    return null;
  }

  Future<void> _duplicateSelectedNode() async {
    final node = _selectedNode;
    final duplicate = widget.onDuplicateNode;
    if (node == null || duplicate == null) return;
    final createdId = await duplicate(node.id);
    if (createdId != null) widget.onSelectNode?.call(createdId);
  }

  void _runDryPreview() {
    final scene = SceneAsset(
      id: widget.scene.id,
      name: widget.scene.name,
      description: widget.scene.description,
      storylineId: widget.scene.storylineId,
      chapterId: widget.scene.chapterId,
      tags: widget.scene.tags,
      graph: widget.scene.graph,
      layout: widget.scene.layout,
      declaredOutcomes: widget.scene.outcomeDefinitions,
      metadata: widget.scene.metadata,
    );
    final build = buildSceneRuntimePlan(scene);
    setState(() {
      _preview = build.plan == null
          ? SceneDryRunPreviewResult(
              status: SceneDryRunPreviewStatus.failed,
              trace: const [],
              message: build.diagnostics.isEmpty
                  ? 'La scène ne peut pas être planifiée.'
                  : build.diagnostics.first.message,
            )
          : previewSceneRuntimePath(
              build.plan!,
              input: SceneDryRunInputState(
                outputPortByNodeId: Map.unmodifiable(_outputPortByNodeId),
              ),
            );
    });
  }
}

String _previewMessage(SceneDryRunPreviewResult preview) {
  final path = preview.trace.map((entry) => entry.nodeId).join(' → ');
  return switch (preview.status) {
    SceneDryRunPreviewStatus.completed =>
      'Chemin : $path · outcome : ${preview.sceneOutcomeId ?? 'aucun'}',
    SceneDryRunPreviewStatus.awaitingInput =>
      'Entrée requise pour ${preview.awaitingNodeId}. Chemin : $path',
    SceneDryRunPreviewStatus.failed => preview.message ?? 'Preview impossible.',
  };
}
