import 'package:flutter/cupertino.dart';

import '../../features/narrative/application/narrative_workspace_projection.dart';
import '../../theme/theme.dart';
import '../design_system/design_system.dart';
import 'scenes/scene_graph_read_only_view.dart';
import 'scenes/scene_node_read_only_inspector.dart';

class ScenesWorkspace extends StatefulWidget {
  const ScenesWorkspace({
    super.key,
    required this.scenes,
  });

  final List<NarrativeSceneSummary> scenes;

  @override
  State<ScenesWorkspace> createState() => _ScenesWorkspaceState();
}

class _ScenesWorkspaceState extends State<ScenesWorkspace> {
  String? _selectedSceneId;
  String? _selectedNodeId;

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
      return;
    }
    final selectedStillExists =
        widget.scenes.any((scene) => scene.id == _selectedSceneId);
    if (!selectedStillExists) {
      _selectedSceneId = widget.scenes.first.id;
      _selectedNodeId = _preferredNodeId(widget.scenes.first);
      return;
    }
    final selected = _selectedScene;
    if (selected == null || selected.graph.nodes.isEmpty) {
      _selectedNodeId = null;
      return;
    }
    final nodeStillExists =
        selected.graph.nodes.any((node) => node.id == _selectedNodeId);
    if (!nodeStillExists) {
      _selectedNodeId = _preferredNodeId(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalNodes =
        widget.scenes.fold<int>(0, (sum, scene) => sum + scene.nodeCount);
    final totalOutcomes = widget.scenes.fold<int>(
      0,
      (sum, scene) => sum + scene.declaredOutcomeCount,
    );
    final selectedScene = _selectedScene;

    return PokeMapPageSurface(
      key: const ValueKey('scenes-workspace-shell'),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ScenesHeader(
            sceneCount: widget.scenes.length,
            totalNodes: totalNodes,
            totalOutcomes: totalOutcomes,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 300,
                  child: _SceneTreePanel(
                    scenes: widget.scenes,
                    selectedSceneId: selectedScene?.id,
                    onSelectScene: (sceneId) {
                      setState(() {
                        _selectedSceneId = sceneId;
                        _selectedNodeId = _preferredNodeId(_sceneById(sceneId));
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SceneReadOnlySummary(
                    scene: selectedScene,
                    selectedNodeId: _selectedNodeId,
                    onSelectNode: (nodeId) {
                      setState(() => _selectedNodeId = nodeId);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
}

class _ScenesHeader extends StatelessWidget {
  const _ScenesHeader({
    required this.sceneCount,
    required this.totalNodes,
    required this.totalOutcomes,
  });

  final int sceneCount;
  final int totalNodes;
  final int totalOutcomes;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const PokeMapIconTile(
            icon: CupertinoIcons.square_stack_3d_up,
            tone: PokeMapTone.narrative,
            size: 36,
            iconSize: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Scènes',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const _SceneFactChip(label: 'Read-only V0'),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Arborescence read-only depuis ProjectManifest.scenes. '
                  'Le graph arrive au lot suivant.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 8,
            children: [
              _SceneFactChip(
                key: const ValueKey('scenes-metric-scenes'),
                label: '$sceneCount ${_plural(sceneCount, 'scène', 'scènes')}',
              ),
              _SceneFactChip(
                key: const ValueKey('scenes-metric-nodes'),
                label: '$totalNodes ${_plural(totalNodes, 'node', 'nodes')}',
              ),
              _SceneFactChip(
                key: const ValueKey('scenes-metric-outcomes'),
                label:
                    '$totalOutcomes ${_plural(totalOutcomes, 'outcome', 'outcomes')}',
              ),
            ],
          ),
          const SizedBox(width: 12),
          const PokeMapButton(
            key: ValueKey('scenes-create-scene-disabled'),
            onPressed: null,
            variant: PokeMapButtonVariant.primary,
            size: PokeMapButtonSize.small,
            leading: Icon(CupertinoIcons.plus),
            child: Text('Créer — bientôt'),
          ),
        ],
      ),
    );
  }
}

class _SceneTreePanel extends StatelessWidget {
  const _SceneTreePanel({
    required this.scenes,
    required this.selectedSceneId,
    required this.onSelectScene,
  });

  final List<NarrativeSceneSummary> scenes;
  final String? selectedSceneId;
  final ValueChanged<String> onSelectScene;

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      key: const ValueKey('scenes-tree-panel'),
      expandChild: true,
      padding: EdgeInsets.zero,
      header: const _SceneTreeHeader(),
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
  const _SceneTreeHeader();

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 9),
      child: Row(
        children: [
          const Icon(CupertinoIcons.list_bullet_indent, size: 16),
          const SizedBox(width: 8),
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
          const _SceneFactChip(label: 'Read-only'),
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
      trailing: const Icon(CupertinoIcons.chevron_right, size: 14),
      selected: selected,
      onTap: onTap,
    );
  }
}

class _SceneReadOnlySummary extends StatelessWidget {
  const _SceneReadOnlySummary({
    required this.scene,
    required this.selectedNodeId,
    required this.onSelectNode,
  });

  final NarrativeSceneSummary? scene;
  final String? selectedNodeId;
  final ValueChanged<String> onSelectNode;

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
              onSelectNode: onSelectNode,
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
      action: PokeMapButton(
        key: ValueKey('scenes-open-graph-disabled'),
        onPressed: null,
        variant: PokeMapButtonVariant.secondary,
        leading: Icon(CupertinoIcons.flowchart),
        child: Text('Ouvrir le graph — bientôt'),
      ),
    );
  }
}

class _SelectedSceneSummary extends StatelessWidget {
  const _SelectedSceneSummary({
    required this.scene,
    required this.selectedNodeId,
    required this.onSelectNode,
  });

  final NarrativeSceneSummary scene;
  final String? selectedNodeId;
  final ValueChanged<String> onSelectNode;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return SingleChildScrollView(
      key: ValueKey('scenes-selected-summary-${scene.id}'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PokeMapIconTile(
                icon: CupertinoIcons.flowchart,
                tone: PokeMapTone.narrative,
                size: 42,
                iconSize: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scene.name,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scene.description ?? 'Aucune description.',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              PokeMapButton(
                key: ValueKey('scenes-open-graph-disabled-${scene.id}'),
                onPressed: null,
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.flowchart),
                child: const Text('Lecture seule'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              PokeMapStatusTile(
                label: 'Nodes',
                value: '${scene.nodeCount}',
                icon: CupertinoIcons.circle_grid_3x3,
              ),
              PokeMapStatusTile(
                label: 'Edges',
                value: '${scene.edgeCount}',
                icon: CupertinoIcons.arrow_right,
              ),
              PokeMapStatusTile(
                label: 'Outcomes',
                value: '${scene.declaredOutcomeCount}',
                icon: CupertinoIcons.arrow_branch,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SceneGraphReadOnlyView(
                      scene: scene,
                      selectedNodeId: selectedNodeId,
                      onSelectNode: onSelectNode,
                    ),
                    const SizedBox(height: 16),
                    _SceneDetailsSection(scene: scene),
                    const SizedBox(height: 16),
                    _SceneOutcomeSection(scene: scene),
                    const SizedBox(height: 16),
                    _SceneTagSection(scene: scene),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 320,
                child: SceneNodeReadOnlyInspector(
                  scene: scene,
                  selectedNodeId: selectedNodeId,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SceneDetailsSection extends StatelessWidget {
  const _SceneDetailsSection({required this.scene});

  final NarrativeSceneSummary scene;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle('Références'),
          const SizedBox(height: 10),
          _DetailRow(label: 'Scene ID', value: scene.id),
          _DetailRow(
            label: 'Storyline',
            value: scene.storylineId ?? 'Sans storyline',
          ),
          _DetailRow(
            label: 'Chapter',
            value: scene.chapterId ?? 'Sans chapitre',
          ),
        ],
      ),
    );
  }
}

class _SceneOutcomeSection extends StatelessWidget {
  const _SceneOutcomeSection({required this.scene});

  final NarrativeSceneSummary scene;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle('Outcomes déclarés'),
          const SizedBox(height: 10),
          if (scene.declaredOutcomes.isEmpty)
            const _SceneFactChip(label: 'Aucun outcome déclaré')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final outcome in scene.declaredOutcomes)
                  _SceneFactChip(label: outcome),
              ],
            ),
        ],
      ),
    );
  }
}

class _SceneTagSection extends StatelessWidget {
  const _SceneTagSection({required this.scene});

  final NarrativeSceneSummary scene;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle('Tags'),
          const SizedBox(height: 10),
          if (scene.tags.isEmpty)
            const _SceneFactChip(label: 'Aucun tag')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in scene.tags) _SceneFactChip(label: tag),
              ],
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Text(
      label,
      style: TextStyle(
        color: colors.textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SceneFactChip extends StatelessWidget {
  const _SceneFactChip({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.controlSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
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

String _plural(int count, String singular, String plural) {
  return count == 1 ? singular : plural;
}
