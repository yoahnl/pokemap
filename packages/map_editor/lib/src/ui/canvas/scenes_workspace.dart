import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../features/narrative/application/narrative_workspace_projection.dart';
import '../../theme/theme.dart';
import '../design_system/design_system.dart';
import 'scenes/scene_graph_read_only_view.dart';
import 'scenes/scene_node_read_only_inspector.dart';

typedef SceneDraftCreator = Future<String?> Function({
  required String name,
  String? description,
});

typedef SceneNodeDraftCreator = Future<String?> Function({
  required String sceneId,
  required SceneNodeKind kind,
});

typedef SceneLinkedAssetNodeDraftCreator = Future<String?> Function({
  required String sceneId,
  required SceneNodePayload payload,
  String? title,
});

typedef _SelectedLinkedAssetNodeDraftCreator = Future<void> Function({
  required SceneNodePayload payload,
  String? title,
});

typedef SceneEdgeDraftCreator = Future<String?> Function({
  required String sceneId,
  required String fromNodeId,
  required String fromPortId,
  required String toNodeId,
});

typedef SceneEdgeDraftRemover = Future<bool> Function({
  required String sceneId,
  required String edgeId,
});

typedef SceneNodeDraftRemover = Future<bool> Function({
  required String sceneId,
  required String nodeId,
});

typedef SceneNodeLayoutUpdater = Future<void> Function({
  required String sceneId,
  required String nodeId,
  required double x,
  required double y,
});

typedef SceneConditionSourceUpdater = Future<bool> Function({
  required String sceneId,
  required String nodeId,
  required SceneConditionSource source,
});

typedef SceneYarnDialoguePayloadUpdater = Future<bool> Function({
  required String sceneId,
  required String nodeId,
  required String dialogueId,
  String? yarnNodeName,
});

typedef SceneBattlePayloadUpdater = Future<bool> Function({
  required String sceneId,
  required String nodeId,
  required String trainerId,
});

class ScenesWorkspace extends StatefulWidget {
  const ScenesWorkspace({
    super.key,
    required this.scenes,
    this.linkedAssetContracts,
    this.conditionSourceOptions = const [],
    required this.onCreateSceneDraft,
    required this.onAddNodeDraft,
    required this.onAddLinkedAssetNodeDraft,
    required this.onAddEdgeDraft,
    required this.onRemoveEdgeDraft,
    required this.onRemoveNodeDraft,
    required this.onUpdateNodeLayout,
    required this.onUpdateConditionSource,
    required this.onUpdateYarnDialoguePayload,
    required this.onUpdateBattlePayload,
  });

  final List<NarrativeSceneSummary> scenes;
  final LinkedAssetContractsSnapshot? linkedAssetContracts;
  final List<SceneConditionSourcePickerOption> conditionSourceOptions;
  final SceneDraftCreator onCreateSceneDraft;
  final SceneNodeDraftCreator onAddNodeDraft;
  final SceneLinkedAssetNodeDraftCreator onAddLinkedAssetNodeDraft;
  final SceneEdgeDraftCreator onAddEdgeDraft;
  final SceneEdgeDraftRemover onRemoveEdgeDraft;
  final SceneNodeDraftRemover onRemoveNodeDraft;
  final SceneNodeLayoutUpdater onUpdateNodeLayout;
  final SceneConditionSourceUpdater onUpdateConditionSource;
  final SceneYarnDialoguePayloadUpdater onUpdateYarnDialoguePayload;
  final SceneBattlePayloadUpdater onUpdateBattlePayload;

  @override
  State<ScenesWorkspace> createState() => _ScenesWorkspaceState();
}

class _ScenesWorkspaceState extends State<ScenesWorkspace> {
  String? _selectedSceneId;
  String? _selectedNodeId;
  String? _selectedEdgeId;
  _PendingSceneConnection? _pendingConnection;

  @override
  void initState() {
    super.initState();
    _syncSelection();
  }

  @override
  void didUpdateWidget(covariant ScenesWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSelection();
  }

  void _syncSelection() {
    if (widget.scenes.isEmpty) {
      _selectedSceneId = null;
      _selectedNodeId = null;
      _selectedEdgeId = null;
      _pendingConnection = null;
      return;
    }
    final selectedStillExists =
        widget.scenes.any((scene) => scene.id == _selectedSceneId);
    if (!selectedStillExists) {
      _selectedSceneId = widget.scenes.first.id;
      _selectedNodeId = _preferredNodeId(widget.scenes.first);
      _selectedEdgeId = null;
      _pendingConnection = null;
      return;
    }
    final selected = _selectedScene;
    if (selected == null || selected.graph.nodes.isEmpty) {
      _selectedNodeId = null;
      _selectedEdgeId = null;
      _pendingConnection = null;
      return;
    }
    final nodeStillExists =
        selected.graph.nodes.any((node) => node.id == _selectedNodeId);
    if (!nodeStillExists) {
      _selectedNodeId = _preferredNodeId(selected);
    }
    final edgeStillExists =
        selected.graph.edges.any((edge) => edge.id == _selectedEdgeId);
    if (!edgeStillExists) {
      _selectedEdgeId = null;
    }
    final pending = _pendingConnection;
    if (pending != null &&
        !selected.graph.nodes.any((node) => node.id == pending.fromNodeId)) {
      _pendingConnection = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedScene = _selectedScene;

    return PokeMapPageSurface(
      key: const ValueKey('scenes-workspace-shell'),
      padding: const EdgeInsets.all(8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 1120;
          final treeWidth = compact ? 220.0 : 244.0;
          final inspectorWidth = compact ? 300.0 : 320.0;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                key: const ValueKey('scenes-tree-column'),
                width: treeWidth,
                child: _SceneTreePanel(
                  scenes: widget.scenes,
                  selectedSceneId: selectedScene?.id,
                  onCreateSceneDraft: _createSceneDraft,
                  onSelectScene: (sceneId) {
                    setState(() {
                      _selectedSceneId = sceneId;
                      _selectedNodeId = _preferredNodeId(_sceneById(sceneId));
                      _selectedEdgeId = null;
                      _pendingConnection = null;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox.expand(
                  key: const ValueKey('scenes-graph-column'),
                  child: _SceneReadOnlySummary(
                    scene: selectedScene,
                    selectedNodeId: _selectedNodeId,
                    selectedEdgeId: _selectedEdgeId,
                    pendingConnection: _pendingConnection,
                    onSelectNode: _handleGraphNodeTap,
                    onSelectEdge: _handleGraphEdgeTap,
                    onAddNodeDraft: _addNodeDraft,
                    onAddLinkedAssetNodeDraft: _addLinkedAssetNodeDraft,
                    linkedAssetContracts: widget.linkedAssetContracts,
                    onAddEdgeDraft: _addEdgeDraft,
                    onStartConnection: _startConnection,
                    onCancelConnection: _cancelConnection,
                    onUpdateNodeLayout: _updateNodeLayout,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                key: const ValueKey('scenes-inspector-column'),
                width: inspectorWidth,
                child: LayoutBuilder(
                  builder: (context, inspectorConstraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: inspectorConstraints.maxHeight,
                        ),
                        child: selectedScene == null
                            ? const _SceneInspectorEmptyPanel()
                            : SceneNodeReadOnlyInspector(
                                scene: selectedScene,
                                selectedNodeId: _selectedNodeId,
                                selectedEdgeId: _selectedEdgeId,
                                onRemoveEdgeDraft: _removeSelectedEdgeDraft,
                                onRemoveNodeDraft: _removeSelectedNodeDraft,
                                conditionSourceOptions:
                                    widget.conditionSourceOptions,
                                onUpdateConditionSource: _updateConditionSource,
                                linkedAssetContracts:
                                    widget.linkedAssetContracts,
                                onUpdateYarnDialoguePayload:
                                    _updateYarnDialoguePayload,
                                onUpdateBattlePayload: _updateBattlePayload,
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createSceneDraft() async {
    final draft = await showCupertinoDialog<_SceneDraftDialogResult>(
      context: context,
      builder: (context) => const _CreateSceneDraftDialog(),
    );
    if (draft == null) {
      return;
    }

    final createdSceneId = await widget.onCreateSceneDraft(
      name: draft.name,
      description: draft.description,
    );
    if (!mounted || createdSceneId == null) {
      return;
    }
    setState(() {
      _selectedSceneId = createdSceneId;
      _selectedNodeId = 'node_start';
      _selectedEdgeId = null;
      _pendingConnection = null;
    });
  }

  Future<void> _addNodeDraft(SceneNodeKind kind) async {
    final selected = _selectedScene;
    if (selected == null) {
      return;
    }
    final createdNodeId = await widget.onAddNodeDraft(
      sceneId: selected.id,
      kind: kind,
    );
    if (!mounted || createdNodeId == null) {
      return;
    }
    setState(() {
      _selectedSceneId = selected.id;
      _selectedNodeId = createdNodeId;
      _selectedEdgeId = null;
      _pendingConnection = null;
    });
  }

  Future<void> _addLinkedAssetNodeDraft({
    required SceneNodePayload payload,
    String? title,
  }) async {
    final selected = _selectedScene;
    if (selected == null) {
      return;
    }
    final createdNodeId = await widget.onAddLinkedAssetNodeDraft(
      sceneId: selected.id,
      payload: payload,
      title: title,
    );
    if (!mounted || createdNodeId == null) {
      return;
    }
    setState(() {
      _selectedSceneId = selected.id;
      _selectedNodeId = createdNodeId;
      _selectedEdgeId = null;
      _pendingConnection = null;
    });
  }

  void _startConnection(SceneAuthorableOutputPort port) {
    final nodeId = _selectedNodeId;
    if (nodeId == null) {
      return;
    }
    setState(() {
      _pendingConnection = _PendingSceneConnection(
        fromNodeId: nodeId,
        fromPortId: port.id,
      );
      _selectedEdgeId = null;
    });
  }

  void _cancelConnection() {
    setState(() => _pendingConnection = null);
  }

  Future<void> _handleGraphNodeTap(String nodeId) async {
    final pending = _pendingConnection;
    if (pending == null) {
      setState(() {
        _selectedNodeId = nodeId;
        _selectedEdgeId = null;
      });
      return;
    }
    if (nodeId == pending.fromNodeId) {
      return;
    }
    await _addEdgeDraft(
      fromNodeId: pending.fromNodeId,
      fromPortId: pending.fromPortId,
      toNodeId: nodeId,
    );
  }

  Future<void> _addEdgeDraft({
    required String fromNodeId,
    required String fromPortId,
    required String toNodeId,
  }) async {
    final selected = _selectedScene;
    if (selected == null) {
      return;
    }
    final createdEdgeId = await widget.onAddEdgeDraft(
      sceneId: selected.id,
      fromNodeId: fromNodeId,
      fromPortId: fromPortId,
      toNodeId: toNodeId,
    );
    if (!mounted || createdEdgeId == null) {
      return;
    }
    setState(() {
      _selectedSceneId = selected.id;
      _selectedNodeId = fromNodeId;
      _selectedEdgeId = null;
      _pendingConnection = null;
    });
  }

  void _handleGraphEdgeTap(String edgeId) {
    setState(() {
      _selectedEdgeId = edgeId;
      _selectedNodeId = null;
      _pendingConnection = null;
    });
  }

  Future<void> _removeSelectedEdgeDraft(String edgeId) async {
    final selected = _selectedScene;
    if (selected == null) {
      return;
    }
    final removed = await widget.onRemoveEdgeDraft(
      sceneId: selected.id,
      edgeId: edgeId,
    );
    if (!mounted || !removed) {
      return;
    }
    setState(() {
      _selectedSceneId = selected.id;
      _selectedEdgeId = null;
      _selectedNodeId = _preferredNodeId(selected);
      _pendingConnection = null;
    });
  }

  Future<void> _removeSelectedNodeDraft(String nodeId) async {
    final selected = _selectedScene;
    if (selected == null) {
      return;
    }
    final removed = await widget.onRemoveNodeDraft(
      sceneId: selected.id,
      nodeId: nodeId,
    );
    if (!mounted || !removed) {
      return;
    }
    setState(() {
      _selectedSceneId = selected.id;
      _selectedEdgeId = null;
      _selectedNodeId = _preferredNodeIdAfterRemoving(selected, nodeId);
      _pendingConnection = null;
    });
  }

  Future<void> _updateNodeLayout({
    required String sceneId,
    required String nodeId,
    required double x,
    required double y,
  }) async {
    final scene = _sceneById(sceneId);
    if (scene == null) {
      return;
    }
    await widget.onUpdateNodeLayout(
      sceneId: scene.id,
      nodeId: nodeId,
      x: x,
      y: y,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedSceneId = scene.id;
      _selectedNodeId = nodeId;
      _selectedEdgeId = null;
    });
  }

  Future<bool> _updateConditionSource({
    required String nodeId,
    required SceneConditionSource source,
  }) async {
    final selected = _selectedScene;
    if (selected == null) {
      return false;
    }
    final updated = await widget.onUpdateConditionSource(
      sceneId: selected.id,
      nodeId: nodeId,
      source: source,
    );
    if (!mounted || !updated) {
      return false;
    }
    setState(() {
      _selectedSceneId = selected.id;
      _selectedNodeId = nodeId;
      _selectedEdgeId = null;
      _pendingConnection = null;
    });
    return true;
  }

  Future<bool> _updateYarnDialoguePayload({
    required String nodeId,
    required String dialogueId,
    String? yarnNodeName,
  }) async {
    final selected = _selectedScene;
    if (selected == null) {
      return false;
    }
    final updated = await widget.onUpdateYarnDialoguePayload(
      sceneId: selected.id,
      nodeId: nodeId,
      dialogueId: dialogueId,
      yarnNodeName: yarnNodeName,
    );
    if (!mounted || !updated) {
      return false;
    }
    setState(() {
      _selectedSceneId = selected.id;
      _selectedNodeId = nodeId;
      _selectedEdgeId = null;
      _pendingConnection = null;
    });
    return true;
  }

  Future<bool> _updateBattlePayload({
    required String nodeId,
    required String trainerId,
  }) async {
    final selected = _selectedScene;
    if (selected == null) {
      return false;
    }
    final updated = await widget.onUpdateBattlePayload(
      sceneId: selected.id,
      nodeId: nodeId,
      trainerId: trainerId,
    );
    if (!mounted || !updated) {
      return false;
    }
    setState(() {
      _selectedSceneId = selected.id;
      _selectedNodeId = nodeId;
      _selectedEdgeId = null;
      _pendingConnection = null;
    });
    return true;
  }

  NarrativeSceneSummary? get _selectedScene {
    for (final scene in widget.scenes) {
      if (scene.id == _selectedSceneId) {
        return scene;
      }
    }
    return widget.scenes.isEmpty ? null : widget.scenes.first;
  }

  NarrativeSceneSummary? _sceneById(String sceneId) {
    for (final scene in widget.scenes) {
      if (scene.id == sceneId) {
        return scene;
      }
    }
    return null;
  }

  String? _preferredNodeId(NarrativeSceneSummary? scene) {
    if (scene == null || scene.graph.nodes.isEmpty) {
      return null;
    }
    final startNodeExists =
        scene.graph.nodes.any((node) => node.id == scene.graph.startNodeId);
    return startNodeExists
        ? scene.graph.startNodeId
        : scene.graph.nodes.first.id;
  }

  String? _preferredNodeIdAfterRemoving(
    NarrativeSceneSummary scene,
    String removedNodeId,
  ) {
    if (scene.graph.startNodeId != removedNodeId &&
        scene.graph.nodes.any((node) => node.id == scene.graph.startNodeId)) {
      return scene.graph.startNodeId;
    }
    for (final node in scene.graph.nodes) {
      if (node.id != removedNodeId) {
        return node.id;
      }
    }
    return null;
  }
}

class _PendingSceneConnection {
  const _PendingSceneConnection({
    required this.fromNodeId,
    required this.fromPortId,
  });

  final String fromNodeId;
  final String fromPortId;
}

class _SceneDraftDialogResult {
  const _SceneDraftDialogResult({
    required this.name,
    this.description,
  });

  final String name;
  final String? description;
}

class _CreateSceneDraftDialog extends StatefulWidget {
  const _CreateSceneDraftDialog();

  @override
  State<_CreateSceneDraftDialog> createState() =>
      _CreateSceneDraftDialogState();
}

class _CreateSceneDraftDialogState extends State<_CreateSceneDraftDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _showNameError = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return CupertinoAlertDialog(
      key: const ValueKey('scenes-create-scene-dialog'),
      title: const Text('Créer une scène'),
      content: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          children: [
            CupertinoTextField(
              key: const ValueKey('scenes-create-scene-name-field'),
              controller: _nameController,
              placeholder: 'Nom de la scène',
              onChanged: (_) {
                if (_showNameError) {
                  setState(() => _showNameError = false);
                }
              },
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              key: const ValueKey('scenes-create-scene-description-field'),
              controller: _descriptionController,
              placeholder: 'Description optionnelle',
              minLines: 2,
              maxLines: 3,
            ),
            if (_showNameError) ...[
              const SizedBox(height: 8),
              Text(
                'Nom requis.',
                key: const ValueKey('scenes-create-scene-name-error'),
                style: TextStyle(
                  color: colors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        CupertinoDialogAction(
          key: const ValueKey('scenes-create-scene-cancel'),
          child: const Text('Annuler'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        CupertinoDialogAction(
          key: const ValueKey('scenes-create-scene-submit'),
          isDefaultAction: true,
          child: const Text('Créer la scène'),
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) {
              setState(() => _showNameError = true);
              return;
            }
            Navigator.of(context).pop(
              _SceneDraftDialogResult(
                name: name,
                description: _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SceneTreePanel extends StatelessWidget {
  const _SceneTreePanel({
    required this.scenes,
    required this.selectedSceneId,
    required this.onCreateSceneDraft,
    required this.onSelectScene,
  });

  final List<NarrativeSceneSummary> scenes;
  final String? selectedSceneId;
  final VoidCallback onCreateSceneDraft;
  final ValueChanged<String> onSelectScene;

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      key: const ValueKey('scenes-tree-panel'),
      expandChild: true,
      padding: EdgeInsets.zero,
      header: _SceneTreeHeader(onCreateSceneDraft: onCreateSceneDraft),
      child: scenes.isEmpty
          ? const _SceneTreeEmptyState()
          : _SceneTreeList(
              scenes: scenes,
              selectedSceneId: selectedSceneId,
              onSelectScene: onSelectScene,
            ),
    );
  }
}

class _SceneTreeHeader extends StatelessWidget {
  const _SceneTreeHeader({required this.onCreateSceneDraft});

  final VoidCallback onCreateSceneDraft;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 7),
      child: Row(
        children: [
          const Icon(CupertinoIcons.list_bullet_indent, size: 16),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              'Arborescence des scènes',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          PokeMapButton(
            key: const ValueKey('scenes-create-scene-action'),
            onPressed: onCreateSceneDraft,
            variant: PokeMapButtonVariant.secondary,
            size: PokeMapButtonSize.small,
            leading: const Icon(CupertinoIcons.plus),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }
}

class _SceneTreeEmptyState extends StatelessWidget {
  const _SceneTreeEmptyState();

  @override
  Widget build(BuildContext context) {
    return const PokeMapEmptyState(
      key: ValueKey('scenes-tree-empty-state'),
      icon: Icon(CupertinoIcons.square_stack_3d_up),
      title: 'Liste vide',
      description: 'Aucune scène réelle dans ProjectManifest.scenes.',
    );
  }
}

class _SceneTreeList extends StatelessWidget {
  const _SceneTreeList({
    required this.scenes,
    required this.selectedSceneId,
    required this.onSelectScene,
  });

  final List<NarrativeSceneSummary> scenes;
  final String? selectedSceneId;
  final ValueChanged<String> onSelectScene;

  @override
  Widget build(BuildContext context) {
    final grouped = _groupScenes(scenes);
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        for (final storylineEntry in grouped.entries) ...[
          _SceneTreeGroupLabel(
            icon: CupertinoIcons.book,
            label: storylineEntry.key,
          ),
          for (final chapterEntry in storylineEntry.value.entries) ...[
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 8, bottom: 4),
              child: _SceneTreeGroupLabel(
                icon: CupertinoIcons.rectangle_stack,
                label: chapterEntry.key,
              ),
            ),
            for (final scene in chapterEntry.value) ...[
              _SceneTreeItem(
                scene: scene,
                selected: scene.id == selectedSceneId,
                onTap: () => onSelectScene(scene.id),
              ),
              const SizedBox(height: 6),
            ],
          ],
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

class _SceneTreeGroupLabel extends StatelessWidget {
  const _SceneTreeGroupLabel({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Row(
      children: [
        Icon(icon, size: 13, color: colors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _SceneTreeItem extends StatelessWidget {
  const _SceneTreeItem({
    required this.scene,
    required this.selected,
    required this.onTap,
  });

  final NarrativeSceneSummary scene;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PokeMapSidebarItem(
      key: ValueKey('scenes-tree-item-${scene.id}'),
      icon: const Icon(CupertinoIcons.flowchart),
      label: scene.name,
      subtitle:
          '${scene.nodeCount} nodes • ${scene.edgeCount} edges • ${scene.declaredOutcomeCount} outcomes',
      trailing: scene.hasDiagnostics
          ? _SceneDiagnosticBadge(scene: scene)
          : const Icon(CupertinoIcons.chevron_right, size: 14),
      selected: selected,
      onTap: onTap,
    );
  }
}

class _SceneDiagnosticBadge extends StatelessWidget {
  const _SceneDiagnosticBadge({required this.scene});

  final NarrativeSceneSummary scene;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final hasErrors = scene.diagnosticErrorCount > 0;
    final foreground = hasErrors ? colors.error : colors.warning;
    final background = hasErrors ? colors.errorSoft : colors.warningSoft;
    final border = hasErrors ? colors.errorBorder : colors.warningBorder;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          scene.diagnosticSummaryLabel,
          style: TextStyle(
            color: foreground,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SceneReadOnlySummary extends StatelessWidget {
  const _SceneReadOnlySummary({
    required this.scene,
    required this.selectedNodeId,
    required this.selectedEdgeId,
    required this.pendingConnection,
    required this.onSelectNode,
    required this.onSelectEdge,
    required this.onAddNodeDraft,
    required this.onAddLinkedAssetNodeDraft,
    required this.linkedAssetContracts,
    required this.onAddEdgeDraft,
    required this.onStartConnection,
    required this.onCancelConnection,
    required this.onUpdateNodeLayout,
  });

  final NarrativeSceneSummary? scene;
  final String? selectedNodeId;
  final String? selectedEdgeId;
  final _PendingSceneConnection? pendingConnection;
  final ValueChanged<String> onSelectNode;
  final ValueChanged<String> onSelectEdge;
  final ValueChanged<SceneNodeKind> onAddNodeDraft;
  final _SelectedLinkedAssetNodeDraftCreator onAddLinkedAssetNodeDraft;
  final LinkedAssetContractsSnapshot? linkedAssetContracts;
  final SceneVisualEdgeDraftCreator onAddEdgeDraft;
  final ValueChanged<SceneAuthorableOutputPort> onStartConnection;
  final VoidCallback onCancelConnection;
  final SceneNodeLayoutUpdater onUpdateNodeLayout;

  @override
  Widget build(BuildContext context) {
    final current = scene;
    return PokeMapPanel(
      expandChild: true,
      padding: EdgeInsets.zero,
      child: current == null
          ? const _SceneSummaryEmptyState()
          : _SelectedSceneSummary(
              scene: current,
              selectedNodeId: selectedNodeId,
              selectedEdgeId: selectedEdgeId,
              pendingConnection: pendingConnection,
              onSelectNode: onSelectNode,
              onSelectEdge: onSelectEdge,
              onAddNodeDraft: onAddNodeDraft,
              onAddLinkedAssetNodeDraft: onAddLinkedAssetNodeDraft,
              linkedAssetContracts: linkedAssetContracts,
              onAddEdgeDraft: onAddEdgeDraft,
              onStartConnection: onStartConnection,
              onCancelConnection: onCancelConnection,
              onUpdateNodeLayout: onUpdateNodeLayout,
            ),
    );
  }
}

class _SceneSummaryEmptyState extends StatelessWidget {
  const _SceneSummaryEmptyState();

  @override
  Widget build(BuildContext context) {
    return const PokeMapEmptyState(
      key: ValueKey('scenes-summary-empty-state'),
      icon: Icon(CupertinoIcons.flowchart),
      title: 'Aucune scène créée',
      description: 'Créez bientôt vos scènes sous forme de graph '
          'd’orchestration : dialogue, condition, combat, cinématique, action.',
    );
  }
}

class _SelectedSceneSummary extends StatelessWidget {
  const _SelectedSceneSummary({
    required this.scene,
    required this.selectedNodeId,
    required this.selectedEdgeId,
    required this.pendingConnection,
    required this.onSelectNode,
    required this.onSelectEdge,
    required this.onAddNodeDraft,
    required this.onAddLinkedAssetNodeDraft,
    required this.linkedAssetContracts,
    required this.onAddEdgeDraft,
    required this.onStartConnection,
    required this.onCancelConnection,
    required this.onUpdateNodeLayout,
  });

  final NarrativeSceneSummary scene;
  final String? selectedNodeId;
  final String? selectedEdgeId;
  final _PendingSceneConnection? pendingConnection;
  final ValueChanged<String> onSelectNode;
  final ValueChanged<String> onSelectEdge;
  final ValueChanged<SceneNodeKind> onAddNodeDraft;
  final _SelectedLinkedAssetNodeDraftCreator onAddLinkedAssetNodeDraft;
  final LinkedAssetContractsSnapshot? linkedAssetContracts;
  final SceneVisualEdgeDraftCreator onAddEdgeDraft;
  final ValueChanged<SceneAuthorableOutputPort> onStartConnection;
  final VoidCallback onCancelConnection;
  final SceneNodeLayoutUpdater onUpdateNodeLayout;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      key: ValueKey('scenes-selected-summary-${scene.id}'),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            scene.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            scene.description ?? 'Aucune description.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          _SceneNodeDraftPalette(
            linkedAssetContracts: linkedAssetContracts,
            onAddNodeDraft: onAddNodeDraft,
            onAddLinkedAssetNodeDraft: onAddLinkedAssetNodeDraft,
          ),
          const SizedBox(height: 8),
          _SceneEdgeDraftToolbar(
            scene: scene,
            selectedNodeId: selectedNodeId,
            pendingConnection: pendingConnection,
            onStartConnection: onStartConnection,
            onCancelConnection: onCancelConnection,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SceneGraphReadOnlyView(
              scene: scene,
              selectedNodeId: selectedNodeId,
              selectedEdgeId: selectedEdgeId,
              onSelectNode: onSelectNode,
              onSelectEdge: onSelectEdge,
              canDragNodes: pendingConnection == null,
              onCreateEdgeDraft: ({
                required fromNodeId,
                required fromPortId,
                required toNodeId,
              }) =>
                  onAddEdgeDraft(
                fromNodeId: fromNodeId,
                fromPortId: fromPortId,
                toNodeId: toNodeId,
              ),
              onUpdateNodeLayout: ({
                required nodeId,
                required x,
                required y,
              }) =>
                  onUpdateNodeLayout(
                sceneId: scene.id,
                nodeId: nodeId,
                x: x,
                y: y,
              ),
              expandToFill: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _SceneNodeDraftPalette extends StatelessWidget {
  const _SceneNodeDraftPalette({
    required this.linkedAssetContracts,
    required this.onAddNodeDraft,
    required this.onAddLinkedAssetNodeDraft,
  });

  final LinkedAssetContractsSnapshot? linkedAssetContracts;
  final ValueChanged<SceneNodeKind> onAddNodeDraft;
  final _SelectedLinkedAssetNodeDraftCreator onAddLinkedAssetNodeDraft;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final contracts = linkedAssetContracts;
    final hasDialogues = contracts?.dialogues.isNotEmpty ?? false;
    final hasBattles = contracts?.battles.isNotEmpty ?? false;
    final cinematicReason = (contracts?.cinematics.isNotEmpty ?? false)
        ? 'bridge Scenario uniquement'
        : 'bridge absent';
    return SizedBox(
      key: const ValueKey('scenes-add-node-palette'),
      height: 34,
      child: Row(
        children: [
          Text(
            'Ajouter un nœud',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _NodeDraftButton(
                    buttonKey: const ValueKey('scenes-add-node-condition'),
                    label: 'Condition',
                    icon: CupertinoIcons.check_mark_circled,
                    onPressed: () => onAddNodeDraft(SceneNodeKind.condition),
                  ),
                  _NodeDraftButton(
                    buttonKey: const ValueKey('scenes-add-node-merge'),
                    label: 'Merge',
                    icon: CupertinoIcons.arrow_merge,
                    onPressed: () => onAddNodeDraft(SceneNodeKind.merge),
                  ),
                  _NodeDraftButton(
                    buttonKey: const ValueKey('scenes-add-node-end'),
                    label: 'Fin',
                    icon: CupertinoIcons.flag,
                    onPressed: () => onAddNodeDraft(SceneNodeKind.end),
                  ),
                  _NodeDraftButton(
                    buttonKey: hasDialogues
                        ? const ValueKey('scenes-add-node-yarn')
                        : const ValueKey('scenes-add-node-yarn-disabled'),
                    label: 'Dialogue',
                    icon: CupertinoIcons.text_bubble,
                    disabledReason: hasDialogues ? null : 'contrat absent',
                    onPressed: hasDialogues
                        ? () => _pickDialogueAndAddNode(
                              context,
                              contracts!.dialogues,
                            )
                        : null,
                  ),
                  _NodeDraftButton(
                    buttonKey: hasBattles
                        ? const ValueKey('scenes-add-node-battle')
                        : const ValueKey('scenes-add-node-battle-disabled'),
                    label: 'Combat',
                    icon: CupertinoIcons.asterisk_circle,
                    disabledReason: hasBattles ? null : 'contrat absent',
                    onPressed: hasBattles
                        ? () => _pickBattleAndAddNode(
                              context,
                              contracts!.battles,
                            )
                        : null,
                  ),
                  const _NodeDraftButton(
                    buttonKey: ValueKey('scenes-add-node-start-disabled'),
                    label: 'Début',
                    icon: CupertinoIcons.play_circle,
                    disabledReason: 'déjà unique',
                  ),
                  const _NodeDraftButton(
                    buttonKey: ValueKey('scenes-add-node-action-disabled'),
                    label: 'Action',
                    icon: CupertinoIcons.bolt,
                    disabledReason: 'contrat futur requis',
                  ),
                  _NodeDraftButton(
                    buttonKey:
                        const ValueKey('scenes-add-node-cinematic-disabled'),
                    label: 'Cinématique',
                    icon: CupertinoIcons.film,
                    disabledReason: cinematicReason,
                  ),
                  const _NodeDraftButton(
                    buttonKey: ValueKey('scenes-add-node-branch-disabled'),
                    label: 'Branche',
                    icon: CupertinoIcons.arrow_branch,
                    disabledReason: 'mapping futur requis',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDialogueAndAddNode(
    BuildContext context,
    List<DialoguePublicContract> dialogues,
  ) async {
    final contract = await showCupertinoDialog<DialoguePublicContract>(
      context: context,
      builder: (context) => _DialoguePayloadPickerDialog(dialogues: dialogues),
    );
    if (contract == null) {
      return;
    }
    await onAddLinkedAssetNodeDraft(
      payload: SceneYarnDialoguePayload(
        dialogueId: contract.id,
        yarnNodeName: contract.defaultStartNode,
        expectedOutcomes: [
          for (final outcome in contract.declaredOutcomes) outcome.id,
        ],
      ),
      title: contract.label,
    );
  }

  Future<void> _pickBattleAndAddNode(
    BuildContext context,
    List<BattlePublicContract> battles,
  ) async {
    final contract = await showCupertinoDialog<BattlePublicContract>(
      context: context,
      builder: (context) => _BattlePayloadPickerDialog(battles: battles),
    );
    if (contract == null) {
      return;
    }
    await onAddLinkedAssetNodeDraft(
      payload: SceneBattlePayload(
        battleKind: contract.battleKind.name,
        trainerId: contract.trainerId,
        declaredOutcomes: [
          for (final outcome in contract.possibleOutcomes) outcome.id,
        ],
      ),
      title: contract.label,
    );
  }
}

class _DialoguePayloadPickerDialog extends StatelessWidget {
  const _DialoguePayloadPickerDialog({required this.dialogues});

  final List<DialoguePublicContract> dialogues;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      key: const ValueKey('scene-dialogue-picker-dialog'),
      title: const Text('Choisir un dialogue'),
      content: _PayloadPickerContent(
        children: [
          for (final dialogue in dialogues)
            _PayloadPickerOptionButton(
              key: ValueKey('scene-dialogue-picker-option-${dialogue.id}'),
              title: dialogue.label,
              subtitle: dialogue.id,
              details: [
                dialogue.sourceRef,
                if (dialogue.defaultStartNode != null)
                  'Start: ${dialogue.defaultStartNode}',
              ],
              diagnostics: dialogue.diagnostics,
              onPressed: () => Navigator.of(context).pop(dialogue),
            ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('Annuler'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _BattlePayloadPickerDialog extends StatelessWidget {
  const _BattlePayloadPickerDialog({required this.battles});

  final List<BattlePublicContract> battles;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      key: const ValueKey('scene-battle-picker-dialog'),
      title: const Text('Choisir un combat'),
      content: _PayloadPickerContent(
        children: [
          for (final battle in battles)
            _PayloadPickerOptionButton(
              key: ValueKey(
                'scene-battle-picker-option-${_pickerKeyPart(battle.id)}',
              ),
              title: battle.label,
              subtitle: battle.trainerId,
              details: [
                battle.battleKind.name,
                battle.trainerLabel,
                battle.possibleOutcomes
                    .map((outcome) => outcome.id)
                    .join(' / '),
              ],
              diagnostics: battle.diagnostics,
              onPressed: () => Navigator.of(context).pop(battle),
            ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('Annuler'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _PayloadPickerContent extends StatelessWidget {
  const _PayloadPickerContent({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _PayloadPickerOptionButton extends StatelessWidget {
  const _PayloadPickerOptionButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.details,
    required this.diagnostics,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final List<String> details;
  final List<LinkedAssetContractDiagnostic> diagnostics;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PokeMapCard(
        onTap: onPressed,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            for (final detail in details.where((value) => value.isNotEmpty))
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            for (final diagnostic in diagnostics)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  diagnostic.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _diagnosticColor(context, diagnostic.severity),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Color _diagnosticColor(
  BuildContext context,
  LinkedAssetContractDiagnosticSeverity severity,
) {
  final colors = context.pokeMapColors;
  return switch (severity) {
    LinkedAssetContractDiagnosticSeverity.error => colors.error,
    LinkedAssetContractDiagnosticSeverity.warning => colors.warning,
    LinkedAssetContractDiagnosticSeverity.info => colors.textMuted,
  };
}

String _pickerKeyPart(String value) {
  final buffer = StringBuffer();
  var wroteSeparator = false;
  for (final codeUnit in value.trim().toLowerCase().codeUnits) {
    final isDigit = codeUnit >= 48 && codeUnit <= 57;
    final isAsciiLetter = codeUnit >= 97 && codeUnit <= 122;
    if (isDigit || isAsciiLetter) {
      buffer.writeCharCode(codeUnit);
      wroteSeparator = false;
    } else if (!wroteSeparator && buffer.isNotEmpty) {
      buffer.write('_');
      wroteSeparator = true;
    }
  }
  final slug = buffer.toString();
  return slug.endsWith('_') ? slug.substring(0, slug.length - 1) : slug;
}

class _SceneEdgeDraftToolbar extends StatelessWidget {
  const _SceneEdgeDraftToolbar({
    required this.scene,
    required this.selectedNodeId,
    required this.pendingConnection,
    required this.onStartConnection,
    required this.onCancelConnection,
  });

  final NarrativeSceneSummary scene;
  final String? selectedNodeId;
  final _PendingSceneConnection? pendingConnection;
  final ValueChanged<SceneAuthorableOutputPort> onStartConnection;
  final VoidCallback onCancelConnection;

  @override
  Widget build(BuildContext context) {
    final pending = pendingConnection;
    if (pending != null) {
      return _PendingConnectionBar(
        pending: pending,
        onCancelConnection: onCancelConnection,
      );
    }

    final node = _selectedNode;
    if (node == null) {
      return const SizedBox(
        key: ValueKey('scenes-edge-no-outputs'),
        height: 34,
      );
    }
    final ports = authorableSceneOutputPortsForNode(node);
    if (ports.isEmpty) {
      return const _NoOutputPortsBar();
    }

    final usedPorts = {
      for (final edge in scene.graph.edges)
        if (edge.fromNodeId == node.id) edge.fromPortId,
    };
    final colors = context.pokeMapColors;
    return SizedBox(
      key: const ValueKey('scenes-edge-authoring-toolbar'),
      height: 34,
      child: Row(
        children: [
          Text(
            'Connexions',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final port in ports)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: PokeMapButton(
                        key: ValueKey('scenes-connect-port-${port.id}'),
                        onPressed: usedPorts.contains(port.id)
                            ? null
                            : () => onStartConnection(port),
                        variant: usedPorts.contains(port.id)
                            ? PokeMapButtonVariant.ghost
                            : PokeMapButtonVariant.secondary,
                        size: PokeMapButtonSize.small,
                        leading: const Icon(CupertinoIcons.link),
                        child: Text(
                          usedPorts.contains(port.id)
                              ? '${port.label} · connecté'
                              : 'Connecter ${port.label}',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  SceneNode? get _selectedNode {
    final id = selectedNodeId;
    if (id == null) {
      return null;
    }
    for (final node in scene.graph.nodes) {
      if (node.id == id) {
        return node;
      }
    }
    return null;
  }
}

class _PendingConnectionBar extends StatelessWidget {
  const _PendingConnectionBar({
    required this.pending,
    required this.onCancelConnection,
  });

  final _PendingSceneConnection pending;
  final VoidCallback onCancelConnection;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return SizedBox(
      key: const ValueKey('scenes-edge-connection-pending'),
      height: 34,
      child: Row(
        children: [
          const Icon(CupertinoIcons.link, size: 15),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              'Connexion en cours depuis '
              '${pending.fromNodeId} / ${pending.fromPortId}. '
              'Cliquez un nœud cible.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          PokeMapButton(
            key: const ValueKey('scenes-edge-connection-cancel'),
            onPressed: onCancelConnection,
            variant: PokeMapButtonVariant.ghost,
            size: PokeMapButtonSize.small,
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }
}

class _NoOutputPortsBar extends StatelessWidget {
  const _NoOutputPortsBar();

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return SizedBox(
      key: const ValueKey('scenes-edge-no-outputs'),
      height: 34,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Aucune sortie connectable V0.',
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _NodeDraftButton extends StatelessWidget {
  const _NodeDraftButton({
    required this.buttonKey,
    required this.label,
    required this.icon,
    this.onPressed,
    this.disabledReason,
  });

  final Key buttonKey;
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final reason = disabledReason;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: PokeMapButton(
        key: buttonKey,
        onPressed: onPressed,
        variant: onPressed == null
            ? PokeMapButtonVariant.ghost
            : PokeMapButtonVariant.secondary,
        size: PokeMapButtonSize.small,
        leading: Icon(icon),
        child: Text(reason == null ? label : '$label · $reason'),
      ),
    );
  }
}

class _SceneInspectorEmptyPanel extends StatelessWidget {
  const _SceneInspectorEmptyPanel();

  @override
  Widget build(BuildContext context) {
    return const PokeMapInspectorPanel(
      padding: EdgeInsets.all(12),
      header: Padding(
        padding: EdgeInsets.fromLTRB(12, 11, 12, 9),
        child: Row(
          children: [
            PokeMapIconTile(
              icon: CupertinoIcons.sidebar_right,
              tone: PokeMapTone.narrative,
              size: 30,
              iconSize: 15,
            ),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'Détails du nœud',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      child: PokeMapEmptyState(
        icon: Icon(CupertinoIcons.sidebar_right),
        title: 'Aucun nœud',
        description: 'Sélectionnez une scène pour inspecter son graph.',
      ),
    );
  }
}

Map<String, Map<String, List<NarrativeSceneSummary>>> _groupScenes(
  List<NarrativeSceneSummary> scenes,
) {
  final grouped = <String, Map<String, List<NarrativeSceneSummary>>>{};
  for (final scene in scenes) {
    final storylineKey = scene.storylineId ?? 'Sans storyline';
    final chapterKey = scene.chapterId ?? 'Sans chapitre';
    final chapters = grouped.putIfAbsent(storylineKey, () => {});
    chapters.putIfAbsent(chapterKey, () => []).add(scene);
  }
  return grouped;
}
