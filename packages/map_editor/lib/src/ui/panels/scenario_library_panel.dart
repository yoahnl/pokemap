import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_state.dart';
import '../../features/scenario/scenario_authoring_ux.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/inspector_embedded_widgets.dart';

class ScenarioLibraryPanel extends ConsumerWidget {
  const ScenarioLibraryPanel({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final scenarios = project.scenarios;
    final selectedScenarioId = state.selectedScenarioId;
    ScenarioAsset? selectedScenario;
    if (selectedScenarioId != null && selectedScenarioId.trim().isNotEmpty) {
      for (final scenario in scenarios) {
        if (scenario.id == selectedScenarioId) {
          selectedScenario = scenario;
          break;
        }
      }
    }

    final content = ListView(
      padding: embedded
          ? kInspectorTileBodyPadding
          : const EdgeInsets.fromLTRB(8, 8, 8, 8),
      children: [
        _ScenarioLibraryHeader(
          count: scenarios.length,
          onCreate: () => _promptCreateScenario(context, notifier),
          onSwitchToMap: state.workspaceMode == EditorWorkspaceMode.map
              ? null
              : notifier.selectMapWorkspace,
        ),
        const SizedBox(height: 8),
        if (scenarios.isEmpty)
          _ScenarioLibraryEmptyState(
            onCreate: () => _promptCreateScenario(context, notifier),
          )
        else
          ...scenarios.map(
            (scenario) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _ScenarioListRow(
                scenario: scenario,
                selected: scenario.id == selectedScenarioId,
                isScenarioWorkspace:
                    state.workspaceMode == EditorWorkspaceMode.scenario &&
                        scenario.id == selectedScenarioId,
                onSelect: () {
                  notifier.selectProjectScenario(scenario.id);
                  notifier.selectScenarioWorkspace(scenario.id);
                },
                onRename: () =>
                    _promptRenameScenario(context, notifier, scenario),
                onDelete: () =>
                    _confirmDeleteScenario(context, notifier, scenario),
              ),
            ),
          ),
        if (selectedScenario != null) ...[
          const SizedBox(height: 10),
          _ScenarioDetailCard(
            scenario: selectedScenario,
            onOpenWorkspace: () =>
                notifier.selectScenarioWorkspace(selectedScenario!.id),
            onRename: () =>
                _promptRenameScenario(context, notifier, selectedScenario!),
            onDelete: () =>
                _confirmDeleteScenario(context, notifier, selectedScenario!),
          ),
        ],
      ],
    );

    if (embedded) {
      return content;
    }
    return ColoredBox(
      color: EditorChrome.largeIslandSurfaceColor(context),
      child: content,
    );
  }

  Future<void> _promptCreateScenario(
    BuildContext context,
    EditorNotifier notifier,
  ) async {
    final controller = TextEditingController();
    final ok = await showMacosEditorPromptSheet(
      context,
      title: 'New scenario graph',
      controller: controller,
      confirmLabel: 'Create',
      placeholder: 'Display name',
    );
    if (!ok || !context.mounted) return;
    final name = controller.text.trim();
    if (name.isEmpty) return;
    await notifier.createProjectScenario(name: name);
  }

  Future<void> _promptRenameScenario(
    BuildContext context,
    EditorNotifier notifier,
    ScenarioAsset scenario,
  ) async {
    final controller = TextEditingController(text: scenario.name);
    final ok = await showMacosEditorPromptSheet(
      context,
      title: 'Rename scenario',
      controller: controller,
      confirmLabel: 'Save',
      placeholder: 'Display name',
    );
    if (!ok || !context.mounted) return;
    final name = controller.text.trim();
    if (name.isEmpty) return;
    await notifier.renameProjectScenario(
      scenarioId: scenario.id,
      name: name,
    );
  }

  Future<void> _confirmDeleteScenario(
    BuildContext context,
    EditorNotifier notifier,
    ScenarioAsset scenario,
  ) async {
    final confirm = await showMacosEditorTwoChoiceAlert(
      context,
      title: 'Delete scenario?',
      message:
          'This removes "${scenario.name}" and all of its nodes/connections.',
      primaryLabel: 'Delete',
      primaryIsDestructive: true,
    );
    if (!confirm || !context.mounted) return;
    await notifier.deleteProjectScenario(scenario.id);
  }
}

class _ScenarioLibraryHeader extends StatelessWidget {
  const _ScenarioLibraryHeader({
    required this.count,
    required this.onCreate,
    required this.onSwitchToMap,
  });

  final int count;
  final VoidCallback onCreate;
  final VoidCallback? onSwitchToMap;

  @override
  Widget build(BuildContext context) {
    const accent = EditorChrome.inspectorJoyMint;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: accent.withValues(alpha: 0.08),
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const InspectorEmbeddedSectionLabel('SCENARIO GRAPHS'),
                const SizedBox(height: 2),
                Text(
                  '$count scenario(s)',
                  style: TextStyle(
                    fontSize: 11,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
          if (onSwitchToMap != null)
            EditorToolbarIconButton(
              icon: CupertinoIcons.map,
              tooltip: 'Return to map workspace',
              onPressed: onSwitchToMap!,
            ),
          EditorToolbarIconButton(
            icon: CupertinoIcons.plus,
            tooltip: 'Create scenario graph',
            onPressed: onCreate,
          ),
        ],
      ),
    );
  }
}

class _ScenarioLibraryEmptyState extends StatelessWidget {
  const _ScenarioLibraryEmptyState({
    required this.onCreate,
  });

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    const accent = EditorChrome.inspectorJoyMint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const InspectorEmbeddedFootnote(
          accent: accent,
          text:
              'Aucun scénario central. Crée un graphe pour orchestrer tes scènes, scripts et liens monde.',
        ),
        const SizedBox(height: 8),
        CupertinoButton.filled(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: const Size(0, 28),
          onPressed: onCreate,
          child: const Text(
            'Create first scenario',
            style: TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _ScenarioListRow extends StatelessWidget {
  const _ScenarioListRow({
    required this.scenario,
    required this.selected,
    required this.isScenarioWorkspace,
    required this.onSelect,
    required this.onRename,
    required this.onDelete,
  });

  final ScenarioAsset scenario;
  final bool selected;
  final bool isScenarioWorkspace;
  final VoidCallback onSelect;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final accent = isScenarioWorkspace
        ? EditorChrome.inspectorJoyMint
        : EditorChrome.inspectorJoyBlue;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected
            ? Color.lerp(
                EditorChrome.largeIslandSurfaceColor(context),
                accent,
                0.16,
              )!
            : EditorChrome.largeIslandSurfaceColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected
              ? accent.withValues(alpha: 0.76)
              : EditorChrome.editorIslandRim(context),
        ),
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        onPressed: onSelect,
        child: Row(
          children: [
            Icon(
              CupertinoIcons.share_solid,
              size: 16,
              color: selected
                  ? accent
                  : CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scenario.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${scenario.id} · ${scenarioScopeLabel(scenario.scope)} · ${scenario.nodes.length} nodes · ${scenario.edges.length} links',
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ],
              ),
            ),
            EditorToolbarIconButton(
              icon: CupertinoIcons.pencil,
              tooltip: 'Rename',
              onPressed: onRename,
            ),
            EditorToolbarIconButton(
              icon: CupertinoIcons.delete,
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScenarioDetailCard extends StatelessWidget {
  const _ScenarioDetailCard({
    required this.scenario,
    required this.onOpenWorkspace,
    required this.onRename,
    required this.onDelete,
  });

  final ScenarioAsset scenario;
  final VoidCallback onOpenWorkspace;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    const accent = EditorChrome.inspectorJoyMint;
    ScenarioNode? entryNode;
    for (final node in scenario.nodes) {
      if (node.id == scenario.entryNodeId) {
        entryNode = node;
        break;
      }
    }
    final edgeCount = scenario.edges.length;
    final choiceNodes = scenario.nodes
        .where((node) => node.type == ScenarioNodeType.choice)
        .length;
    final conditionNodes = scenario.nodes
        .where((node) => node.type == ScenarioNodeType.condition)
        .length;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: accent.withValues(alpha: 0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected Scenario',
              style: TextStyle(
                fontSize: 11,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              scenario.name,
              style: TextStyle(
                fontSize: 13,
                color: CupertinoColors.label.resolveFrom(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Entry: ${entryNode != null && entryNode.title.trim().isNotEmpty ? entryNode.title : scenario.entryNodeId}',
              style: TextStyle(
                fontSize: 11,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            Text(
              'Nodes: ${scenario.nodes.length} · Links: $edgeCount · Choices: $choiceNodes · Conditions: $conditionNodes',
              style: TextStyle(
                fontSize: 11,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                CupertinoButton.filled(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(0, 30),
                  onPressed: onOpenWorkspace,
                  child: const Text('Open workspace'),
                ),
                CupertinoButton(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(0, 30),
                  onPressed: onRename,
                  child: const Text('Rename'),
                ),
                CupertinoButton(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(0, 30),
                  onPressed: onDelete,
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
