import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../shared/cupertino_editor_widgets.dart';

class ScenarioInspectorPanel extends ConsumerStatefulWidget {
  const ScenarioInspectorPanel({super.key});

  @override
  ConsumerState<ScenarioInspectorPanel> createState() =>
      _ScenarioInspectorPanelState();
}

class _ScenarioInspectorPanelState
    extends ConsumerState<ScenarioInspectorPanel> {
  final _scenarioNameController = TextEditingController();
  final _scenarioDescriptionController = TextEditingController();
  final _nodeTitleController = TextEditingController();
  final _nodeDescriptionController = TextEditingController();
  final _nodeActionKindController = TextEditingController();
  final _nodeMessageController = TextEditingController();
  final _nodeConditionJsonController = TextEditingController();
  final _nodeEventIdController = TextEditingController();
  final _nodeEntityIdController = TextEditingController();
  final _nodeWarpIdController = TextEditingController();
  final _nodeTriggerIdController = TextEditingController();
  final _nodeTrainerIdController = TextEditingController();
  final _nodeFlagNameController = TextEditingController();
  final _nodeVariableNameController = TextEditingController();

  String? _boundScenarioFingerprint;
  String? _boundNodeFingerprint;

  @override
  void dispose() {
    _scenarioNameController.dispose();
    _scenarioDescriptionController.dispose();
    _nodeTitleController.dispose();
    _nodeDescriptionController.dispose();
    _nodeActionKindController.dispose();
    _nodeMessageController.dispose();
    _nodeConditionJsonController.dispose();
    _nodeEventIdController.dispose();
    _nodeEntityIdController.dispose();
    _nodeWarpIdController.dispose();
    _nodeTriggerIdController.dispose();
    _nodeTrainerIdController.dispose();
    _nodeFlagNameController.dispose();
    _nodeVariableNameController.dispose();
    super.dispose();
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
      return Center(
        child: Text(
          'Create and select a scenario graph from the left panel.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: CupertinoColors.placeholderText.resolveFrom(context),
          ),
        ),
      );
    }
    _syncScenarioControllers(scenario);

    ScenarioNode? selectedNode;
    if (state.selectedScenarioNodeId != null &&
        state.selectedScenarioNodeId!.trim().isNotEmpty) {
      for (final node in scenario.nodes) {
        if (node.id == state.selectedScenarioNodeId) {
          selectedNode = node;
          break;
        }
      }
    }
    _syncNodeControllers(selectedNode);

    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      children: [
        _buildScenarioHeader(
          context,
          project: project,
          scenario: scenario,
          notifier: notifier,
        ),
        const SizedBox(height: 10),
        _buildScenarioBasics(context, notifier, scenario),
        const SizedBox(height: 10),
        _buildScenarioNodesList(
          context,
          notifier: notifier,
          scenario: scenario,
          selectedNodeId: state.selectedScenarioNodeId,
        ),
        const SizedBox(height: 10),
        if (selectedNode == null)
          _buildNoNodeSelectedCard(context)
        else ...[
          _buildNodeInspector(
            context,
            notifier: notifier,
            project: project,
            scenario: scenario,
            node: selectedNode,
          ),
          const SizedBox(height: 10),
          _buildOutgoingEdges(
            context,
            notifier: notifier,
            scenario: scenario,
            node: selectedNode,
          ),
        ],
      ],
    );
  }

  Widget _buildScenarioHeader(
    BuildContext context, {
    required ProjectManifest project,
    required ScenarioAsset scenario,
    required EditorNotifier notifier,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyMint.withValues(alpha: 0.1),
        ),
        border: Border.all(
          color: EditorChrome.inspectorJoyMint.withValues(alpha: 0.55),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Scenario Inspector',
                    style: TextStyle(
                      color: CupertinoColors.label.resolveFrom(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                EditorToolbarIconButton(
                  icon: CupertinoIcons.add,
                  tooltip: 'Create scenario',
                  onPressed: () => _promptCreateScenario(context, notifier),
                ),
                EditorToolbarIconButton(
                  icon: CupertinoIcons.pencil,
                  tooltip: 'Rename scenario',
                  onPressed: () => _promptRenameScenario(
                    context,
                    notifier,
                    scenario,
                  ),
                ),
                EditorToolbarIconButton(
                  icon: CupertinoIcons.delete,
                  tooltip: 'Delete scenario',
                  onPressed: () => _confirmDeleteScenario(
                    context,
                    notifier,
                    scenario,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Selected: ${scenario.name} (${scenario.id})',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 30),
              color: EditorChrome.largeIslandSurfaceColor(
                context,
                tint: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.1),
              ),
              onPressed: () async {
                final picked = await showCupertinoListPicker<ScenarioAsset>(
                  context: context,
                  title: 'Select scenario',
                  items: project.scenarios,
                  labelOf: (value) => '${value.name} (${value.id})',
                );
                if (picked == null || !context.mounted) return;
                notifier.selectProjectScenario(picked.id);
                notifier.selectScenarioWorkspace(picked.id);
              },
              child: const Text('Switch scenario'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioBasics(
    BuildContext context,
    EditorNotifier notifier,
    ScenarioAsset scenario,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.06),
        ),
        border: Border.all(
          color: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.38),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scenario metadata',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            CupertinoTextField(
              controller: _scenarioNameController,
              placeholder: 'Scenario name',
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            ),
            const SizedBox(height: 6),
            CupertinoTextField(
              controller: _scenarioDescriptionController,
              placeholder: 'Scenario description',
              minLines: 2,
              maxLines: 4,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    minimumSize: const Size(0, 32),
                    onPressed: () => notifier.renameProjectScenario(
                      scenarioId: scenario.id,
                      name: _scenarioNameController.text.trim(),
                    ),
                    child: const Text('Apply name'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Entry node: ${scenario.entryNodeId}',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioNodesList(
    BuildContext context, {
    required EditorNotifier notifier,
    required ScenarioAsset scenario,
    required String? selectedNodeId,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyLilac.withValues(alpha: 0.06),
        ),
        border: Border.all(
          color: EditorChrome.inspectorJoyLilac.withValues(alpha: 0.34),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Scenario nodes',
                    style: TextStyle(
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                EditorToolbarIconButton(
                  icon: CupertinoIcons.plus_circle,
                  tooltip: 'Add node',
                  onPressed: () => _promptAddNode(context, notifier, scenario),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (scenario.nodes.isEmpty)
              Text(
                'No nodes',
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontSize: 11,
                ),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final node in scenario.nodes)
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      minimumSize: const Size(0, 26),
                      color: node.id == selectedNodeId
                          ? EditorChrome.inspectorJoyCyan.withValues(alpha: 0.3)
                          : EditorChrome.largeIslandSurfaceColor(
                              context,
                              tint: EditorChrome.inspectorJoyBlue
                                  .withValues(alpha: 0.12),
                            ),
                      onPressed: () => notifier.selectScenarioNode(node.id),
                      child: Text(
                        '${_scenarioNodeTypeLabel(node.type)} · ${node.id}',
                        style: TextStyle(
                          fontSize: 11,
                          color: CupertinoColors.label.resolveFrom(context),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoNodeSelectedCard(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.06),
        ),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Text(
          'Select a node in the graph or list to edit its payload and world bindings.',
          style: TextStyle(
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildNodeInspector(
    BuildContext context, {
    required EditorNotifier notifier,
    required ProjectManifest project,
    required ScenarioAsset scenario,
    required ScenarioNode node,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyCyan.withValues(alpha: 0.08),
        ),
        border: Border.all(
          color: EditorChrome.inspectorJoyCyan.withValues(alpha: 0.42),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Node inspector · ${node.id}',
                    style: TextStyle(
                      color: CupertinoColors.label.resolveFrom(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                EditorToolbarIconButton(
                  icon: CupertinoIcons.play_fill,
                  tooltip: 'Set as entry node',
                  onPressed: () => notifier.setScenarioEntryNode(
                    scenarioId: scenario.id,
                    nodeId: node.id,
                  ),
                ),
                EditorToolbarIconButton(
                  icon: CupertinoIcons.delete,
                  tooltip: 'Delete node',
                  onPressed: () => notifier.deleteScenarioNode(
                    scenarioId: scenario.id,
                    nodeId: node.id,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _readonlyLine(
                context, 'Node type', _scenarioNodeTypeLabel(node.type)),
            const SizedBox(height: 6),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 30),
              color: EditorChrome.largeIslandSurfaceColor(
                context,
                tint: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.1),
              ),
              onPressed: () => _pickNodeType(context, notifier, scenario, node),
              child: const Text('Change node type'),
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: _nodeTitleController,
              placeholder: 'Node title',
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            ),
            const SizedBox(height: 6),
            CupertinoTextField(
              controller: _nodeDescriptionController,
              placeholder: 'Node description',
              minLines: 2,
              maxLines: 4,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            ),
            const SizedBox(height: 6),
            _bindingPickerRow(
              context,
              title: 'Script',
              value: node.binding.scriptId,
              onPick: () => _pickScriptBinding(
                  context, project, notifier, scenario, node),
            ),
            const SizedBox(height: 6),
            _bindingPickerRow(
              context,
              title: 'Dialogue',
              value: node.binding.dialogueId,
              onPick: () => _pickDialogueBinding(
                  context, project, notifier, scenario, node),
            ),
            const SizedBox(height: 6),
            _bindingPickerRow(
              context,
              title: 'Map',
              value: node.binding.mapId,
              onPick: () =>
                  _pickMapBinding(context, project, notifier, scenario, node),
            ),
            const SizedBox(height: 6),
            _labeledField(
              context,
              label: 'Event ID',
              controller: _nodeEventIdController,
            ),
            const SizedBox(height: 6),
            _labeledField(
              context,
              label: 'Entity ID',
              controller: _nodeEntityIdController,
            ),
            const SizedBox(height: 6),
            _labeledField(
              context,
              label: 'Warp ID',
              controller: _nodeWarpIdController,
            ),
            const SizedBox(height: 6),
            _labeledField(
              context,
              label: 'Trigger ID',
              controller: _nodeTriggerIdController,
            ),
            const SizedBox(height: 6),
            _labeledField(
              context,
              label: 'Trainer ID',
              controller: _nodeTrainerIdController,
            ),
            const SizedBox(height: 6),
            _labeledField(
              context,
              label: 'Flag Name',
              controller: _nodeFlagNameController,
            ),
            const SizedBox(height: 6),
            _labeledField(
              context,
              label: 'Variable Name',
              controller: _nodeVariableNameController,
            ),
            const SizedBox(height: 6),
            _labeledField(
              context,
              label: 'Action Kind',
              controller: _nodeActionKindController,
            ),
            const SizedBox(height: 6),
            _labeledField(
              context,
              label: 'Message',
              controller: _nodeMessageController,
              minLines: 2,
              maxLines: 4,
            ),
            if (node.type == ScenarioNodeType.condition) ...[
              const SizedBox(height: 6),
              Text(
                'Condition JSON',
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              CupertinoTextField(
                controller: _nodeConditionJsonController,
                placeholder:
                    '{"type":"flagIsSet","params":{"flagName":"story.got_starter"}}',
                minLines: 4,
                maxLines: 8,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                inputFormatters: const [],
              ),
            ],
            const SizedBox(height: 8),
            CupertinoButton.filled(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: const Size(0, 34),
              onPressed: () => _applyNodeChanges(
                context,
                notifier: notifier,
                scenario: scenario,
                node: node,
              ),
              child: const Text('Apply node changes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutgoingEdges(
    BuildContext context, {
    required EditorNotifier notifier,
    required ScenarioAsset scenario,
    required ScenarioNode node,
  }) {
    final outgoing = scenario.edges
        .where((edge) => edge.fromNodeId == node.id)
        .toList(growable: false);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.08),
        ),
        border: Border.all(
          color: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Outgoing links',
                    style: TextStyle(
                      color: CupertinoColors.label.resolveFrom(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                EditorToolbarIconButton(
                  icon: CupertinoIcons.link,
                  tooltip: 'Create connection',
                  onPressed: () =>
                      _pickTargetNodeForLink(context, notifier, scenario, node),
                ),
              ],
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
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: EditorChrome.largeIslandSurfaceColor(
                        context,
                        tint: EditorChrome.inspectorJoyBlue
                            .withValues(alpha: 0.07),
                      ),
                      border: Border.all(
                        color: EditorChrome.editorIslandRim(context),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${edge.id} → ${edge.toNodeId}${edge.label.trim().isEmpty ? '' : ' · ${edge.label}'}',
                              style: TextStyle(
                                color:
                                    CupertinoColors.label.resolveFrom(context),
                                fontSize: 11,
                              ),
                            ),
                          ),
                          EditorToolbarIconButton(
                            icon: CupertinoIcons.delete,
                            tooltip: 'Delete link',
                            onPressed: () => notifier.deleteScenarioEdge(
                              scenarioId: scenario.id,
                              edgeId: edge.id,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _readonlyLine(BuildContext context, String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: CupertinoColors.label.resolveFrom(context),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _bindingPickerRow(
    BuildContext context, {
    required String title,
    required String? value,
    required VoidCallback onPick,
  }) {
    final effective = value == null || value.trim().isEmpty ? 'None' : value;
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            title,
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            minimumSize: const Size(0, 28),
            color: EditorChrome.largeIslandSurfaceColor(
              context,
              tint: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.12),
            ),
            onPressed: onPick,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                effective,
                style: TextStyle(
                  color: CupertinoColors.label.resolveFrom(context),
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _labeledField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        CupertinoTextField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          inputFormatters: const [],
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
    await notifier.renameProjectScenario(scenarioId: scenario.id, name: name);
  }

  Future<void> _confirmDeleteScenario(
    BuildContext context,
    EditorNotifier notifier,
    ScenarioAsset scenario,
  ) async {
    final confirm = await showMacosEditorTwoChoiceAlert(
      context,
      title: 'Delete scenario?',
      message: 'This will remove "${scenario.name}" and all its graph data.',
      primaryLabel: 'Delete',
      primaryIsDestructive: true,
    );
    if (!confirm || !context.mounted) return;
    await notifier.deleteProjectScenario(scenario.id);
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
      labelOf: _scenarioNodeTypeLabel,
    );
    if (type == null || !context.mounted) return;
    final titleController =
        TextEditingController(text: _defaultNodeTitleForType(type));
    final ok = await showMacosEditorPromptSheet(
      context,
      title: 'Add ${_scenarioNodeTypeLabel(type)} node',
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
    );
  }

  Future<void> _pickNodeType(
    BuildContext context,
    EditorNotifier notifier,
    ScenarioAsset scenario,
    ScenarioNode node,
  ) async {
    final type = await showCupertinoListPicker<ScenarioNodeType>(
      context: context,
      title: 'Node type',
      items: ScenarioNodeType.values,
      labelOf: _scenarioNodeTypeLabel,
    );
    if (type == null || !context.mounted) return;
    await notifier.updateScenarioNode(
      scenarioId: scenario.id,
      node: node.copyWith(type: type),
    );
  }

  Future<void> _pickScriptBinding(
    BuildContext context,
    ProjectManifest project,
    EditorNotifier notifier,
    ScenarioAsset scenario,
    ScenarioNode node,
  ) async {
    final items = <ProjectScriptEntry?>[null, ...project.scripts];
    final picked = await showCupertinoListPicker<ProjectScriptEntry?>(
      context: context,
      title: 'Script binding',
      items: items,
      labelOf: (value) =>
          value == null ? 'None' : '${value.name} (${value.id})',
    );
    if (!context.mounted) return;
    await notifier.updateScenarioNode(
      scenarioId: scenario.id,
      node: node.copyWith(
        binding: node.binding.copyWith(scriptId: picked?.id),
      ),
    );
  }

  Future<void> _pickDialogueBinding(
    BuildContext context,
    ProjectManifest project,
    EditorNotifier notifier,
    ScenarioAsset scenario,
    ScenarioNode node,
  ) async {
    final items = <ProjectDialogueEntry?>[null, ...project.dialogues];
    final picked = await showCupertinoListPicker<ProjectDialogueEntry?>(
      context: context,
      title: 'Dialogue binding',
      items: items,
      labelOf: (value) =>
          value == null ? 'None' : '${value.name} (${value.id})',
    );
    if (!context.mounted) return;
    await notifier.updateScenarioNode(
      scenarioId: scenario.id,
      node: node.copyWith(
        binding: node.binding.copyWith(dialogueId: picked?.id),
      ),
    );
  }

  Future<void> _pickMapBinding(
    BuildContext context,
    ProjectManifest project,
    EditorNotifier notifier,
    ScenarioAsset scenario,
    ScenarioNode node,
  ) async {
    final items = <ProjectMapEntry?>[null, ...project.maps];
    final picked = await showCupertinoListPicker<ProjectMapEntry?>(
      context: context,
      title: 'Map binding',
      items: items,
      labelOf: (value) =>
          value == null ? 'None' : '${value.name} (${value.id})',
    );
    if (!context.mounted) return;
    await notifier.updateScenarioNode(
      scenarioId: scenario.id,
      node: node.copyWith(
        binding: node.binding.copyWith(mapId: picked?.id),
      ),
    );
  }

  Future<void> _pickTargetNodeForLink(
    BuildContext context,
    EditorNotifier notifier,
    ScenarioAsset scenario,
    ScenarioNode node,
  ) async {
    final targets = scenario.nodes
        .where((candidate) => candidate.id != node.id)
        .toList(growable: false);
    if (targets.isEmpty) {
      return;
    }
    final picked = await showCupertinoListPicker<ScenarioNode>(
      context: context,
      title: 'Connect to node',
      items: targets,
      labelOf: (value) => '${_scenarioNodeTypeLabel(value.type)} · ${value.id}',
    );
    if (picked == null || !context.mounted) return;
    final labelController = TextEditingController();
    final ok = await showMacosEditorPromptSheet(
      context,
      title: 'Link label (optional)',
      controller: labelController,
      confirmLabel: 'Create',
      placeholder: 'next / yes / no ...',
      compact: true,
    );
    if (!ok || !context.mounted) return;
    await notifier.addScenarioEdge(
      scenarioId: scenario.id,
      fromNodeId: node.id,
      toNodeId: picked.id,
      label: labelController.text.trim(),
    );
  }

  Future<void> _applyNodeChanges(
    BuildContext context, {
    required EditorNotifier notifier,
    required ScenarioAsset scenario,
    required ScenarioNode node,
  }) async {
    ScriptCondition? parsedCondition;
    final rawCondition = _nodeConditionJsonController.text.trim();
    if (rawCondition.isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(rawCondition);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Condition JSON must be an object');
        }
        parsedCondition = ScriptCondition.fromJson(decoded);
      } catch (e) {
        await showCupertinoEditorAlert(
          context,
          title: 'Invalid condition JSON',
          message: '$e',
        );
        return;
      }
    }

    final updatedNode = node.copyWith(
      title: _nodeTitleController.text.trim(),
      description: _nodeDescriptionController.text.trim(),
      binding: node.binding.copyWith(
        eventId: _normalizeOptional(_nodeEventIdController.text),
        entityId: _normalizeOptional(_nodeEntityIdController.text),
        warpId: _normalizeOptional(_nodeWarpIdController.text),
        triggerId: _normalizeOptional(_nodeTriggerIdController.text),
        trainerId: _normalizeOptional(_nodeTrainerIdController.text),
        flagName: _normalizeOptional(_nodeFlagNameController.text),
        variableName: _normalizeOptional(_nodeVariableNameController.text),
      ),
      payload: node.payload.copyWith(
        actionKind: _normalizeOptional(_nodeActionKindController.text),
        message: _normalizeOptional(_nodeMessageController.text),
        condition: parsedCondition,
      ),
    );
    await notifier.updateScenarioNode(
      scenarioId: scenario.id,
      node: updatedNode,
    );
  }

  String? _normalizeOptional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _syncScenarioControllers(ScenarioAsset scenario) {
    final fingerprint =
        '${scenario.id}|${scenario.name}|${scenario.description}';
    if (_boundScenarioFingerprint == fingerprint) {
      return;
    }
    _boundScenarioFingerprint = fingerprint;
    _scenarioNameController.text = scenario.name;
    _scenarioDescriptionController.text = scenario.description;
  }

  void _syncNodeControllers(ScenarioNode? node) {
    if (node == null) {
      _boundNodeFingerprint = null;
      _nodeTitleController.clear();
      _nodeDescriptionController.clear();
      _nodeActionKindController.clear();
      _nodeMessageController.clear();
      _nodeConditionJsonController.clear();
      _nodeEventIdController.clear();
      _nodeEntityIdController.clear();
      _nodeWarpIdController.clear();
      _nodeTriggerIdController.clear();
      _nodeTrainerIdController.clear();
      _nodeFlagNameController.clear();
      _nodeVariableNameController.clear();
      return;
    }
    final fingerprint = [
      node.id,
      node.type.name,
      node.title,
      node.description,
      node.binding.scriptId ?? '',
      node.binding.dialogueId ?? '',
      node.binding.mapId ?? '',
      node.binding.eventId ?? '',
      node.binding.entityId ?? '',
      node.binding.warpId ?? '',
      node.binding.triggerId ?? '',
      node.binding.trainerId ?? '',
      node.binding.flagName ?? '',
      node.binding.variableName ?? '',
      node.payload.actionKind ?? '',
      node.payload.message ?? '',
      node.payload.condition?.toJson().toString() ?? '',
    ].join('|');
    if (_boundNodeFingerprint == fingerprint) {
      return;
    }
    _boundNodeFingerprint = fingerprint;
    _nodeTitleController.text = node.title;
    _nodeDescriptionController.text = node.description;
    _nodeActionKindController.text = node.payload.actionKind ?? '';
    _nodeMessageController.text = node.payload.message ?? '';
    _nodeConditionJsonController.text = node.payload.condition == null
        ? ''
        : const JsonEncoder.withIndent('  ')
            .convert(node.payload.condition!.toJson());
    _nodeEventIdController.text = node.binding.eventId ?? '';
    _nodeEntityIdController.text = node.binding.entityId ?? '';
    _nodeWarpIdController.text = node.binding.warpId ?? '';
    _nodeTriggerIdController.text = node.binding.triggerId ?? '';
    _nodeTrainerIdController.text = node.binding.trainerId ?? '';
    _nodeFlagNameController.text = node.binding.flagName ?? '';
    _nodeVariableNameController.text = node.binding.variableName ?? '';
  }
}

String _scenarioNodeTypeLabel(ScenarioNodeType type) {
  return switch (type) {
    ScenarioNodeType.start => 'Start',
    ScenarioNodeType.dialogue => 'Dialogue',
    ScenarioNodeType.action => 'Action',
    ScenarioNodeType.condition => 'Condition',
    ScenarioNodeType.choice => 'Choice',
    ScenarioNodeType.reference => 'World Link',
    ScenarioNodeType.end => 'End',
  };
}

String _defaultNodeTitleForType(ScenarioNodeType type) {
  return switch (type) {
    ScenarioNodeType.start => 'Start',
    ScenarioNodeType.dialogue => 'Dialogue node',
    ScenarioNodeType.action => 'Action node',
    ScenarioNodeType.condition => 'Condition node',
    ScenarioNodeType.choice => 'Choice node',
    ScenarioNodeType.reference => 'World link node',
    ScenarioNodeType.end => 'End',
  };
}
