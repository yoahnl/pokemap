import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/inspector_embedded_widgets.dart';

class ScriptLibraryPanel extends ConsumerWidget {
  const ScriptLibraryPanel({
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

    final scripts = project.scripts;
    final selectedScriptId = state.selectedProjectScriptId;
    ProjectScriptEntry? selectedScript;
    for (final script in scripts) {
      if (script.id == selectedScriptId) {
        selectedScript = script;
        break;
      }
    }

    final content = ListView(
      padding: embedded
          ? kInspectorTileBodyPadding
          : const EdgeInsets.fromLTRB(8, 8, 8, 8),
      children: [
        _ScriptLibraryHeader(
          scriptsCount: scripts.length,
          onCreateScript: () => _promptCreateScript(context, notifier),
          onClearSelection: selectedScript == null
              ? null
              : () => notifier.selectProjectScript(null),
        ),
        const SizedBox(height: 8),
        if (scripts.isEmpty)
          _ScriptLibraryEmptyState(
            onCreate: () => _promptCreateScript(context, notifier),
          )
        else
          ...scripts.map(
            (script) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _ScriptListRow(
                script: script,
                selected: script.id == selectedScriptId,
                onSelect: () => notifier.selectProjectScript(script.id),
                onRename: () => _promptRenameScript(context, notifier, script),
                onDelete: () => _confirmDeleteScript(
                  context,
                  notifier,
                  script,
                ),
              ),
            ),
          ),
        if (selectedScript != null) ...[
          const SizedBox(height: 10),
          _ScriptDetailCard(
            script: selectedScript,
            onRename: () =>
                _promptRenameScript(context, notifier, selectedScript!),
            onDelete: () => _confirmDeleteScript(
              context,
              notifier,
              selectedScript!,
            ),
            onSetDefaultStartNode: (nodeId) =>
                notifier.setProjectScriptDefaultStartNode(
              scriptId: selectedScript!.id,
              nodeId: nodeId,
            ),
            onAddNode: () => _promptAddScriptNode(
              context,
              notifier,
              selectedScript!,
            ),
            onRenameNode: (node) => _promptRenameScriptNode(
              context,
              notifier,
              selectedScript!,
              node,
            ),
            onDeleteNode: (node) => _confirmDeleteScriptNode(
              context,
              notifier,
              selectedScript!,
              node,
            ),
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

  Future<void> _promptCreateScript(
    BuildContext context,
    EditorNotifier notifier,
  ) async {
    final controller = TextEditingController();
    final ok = await showMacosEditorPromptSheet(
      context,
      title: 'New scenario script',
      controller: controller,
      confirmLabel: 'Create',
      placeholder: 'Display name',
    );
    if (!ok || !context.mounted) return;
    final name = controller.text.trim();
    if (name.isEmpty) return;
    await notifier.createProjectScript(name: name);
  }

  Future<void> _promptRenameScript(
    BuildContext context,
    EditorNotifier notifier,
    ProjectScriptEntry script,
  ) async {
    final controller = TextEditingController(text: script.name);
    final ok = await showMacosEditorPromptSheet(
      context,
      title: 'Rename script',
      controller: controller,
      confirmLabel: 'Save',
      placeholder: 'Display name',
    );
    if (!ok || !context.mounted) return;
    final name = controller.text.trim();
    if (name.isEmpty) return;
    await notifier.renameProjectScript(
      scriptId: script.id,
      name: name,
    );
  }

  Future<void> _confirmDeleteScript(
    BuildContext context,
    EditorNotifier notifier,
    ProjectScriptEntry script,
  ) async {
    final confirm = await showMacosEditorTwoChoiceAlert(
      context,
      title: 'Delete script?',
      message:
          'This removes "${script.name}" from the project. Deletion is blocked while map events still reference it.',
      primaryLabel: 'Delete',
      primaryIsDestructive: true,
    );
    if (!confirm || !context.mounted) return;
    await notifier.deleteProjectScript(script.id);
  }

  Future<void> _promptAddScriptNode(
    BuildContext context,
    EditorNotifier notifier,
    ProjectScriptEntry script,
  ) async {
    final controller = TextEditingController();
    final ok = await showMacosEditorPromptSheet(
      context,
      title: 'Add node',
      controller: controller,
      confirmLabel: 'Add',
      placeholder: 'Node title',
      compact: true,
    );
    if (!ok || !context.mounted) return;
    final title = controller.text.trim();
    if (title.isEmpty) return;
    await notifier.addProjectScriptNode(
      scriptId: script.id,
      title: title,
    );
  }

  Future<void> _promptRenameScriptNode(
    BuildContext context,
    EditorNotifier notifier,
    ProjectScriptEntry script,
    ScriptNode node,
  ) async {
    final currentTitle = node.title.trim().isEmpty ? node.id : node.title;
    final controller = TextEditingController(text: currentTitle);
    final ok = await showMacosEditorPromptSheet(
      context,
      title: 'Rename node',
      controller: controller,
      confirmLabel: 'Save',
      placeholder: 'Node title',
      compact: true,
    );
    if (!ok || !context.mounted) return;
    final title = controller.text.trim();
    if (title.isEmpty) return;
    await notifier.renameProjectScriptNode(
      scriptId: script.id,
      nodeId: node.id,
      title: title,
    );
  }

  Future<void> _confirmDeleteScriptNode(
    BuildContext context,
    EditorNotifier notifier,
    ProjectScriptEntry script,
    ScriptNode node,
  ) async {
    final confirm = await showMacosEditorTwoChoiceAlert(
      context,
      title: 'Delete node?',
      message:
          'Node "${node.id}" will be removed only if it is not the default start and not referenced by transitions.',
      primaryLabel: 'Delete',
      primaryIsDestructive: true,
    );
    if (!confirm || !context.mounted) return;
    await notifier.deleteProjectScriptNode(
      scriptId: script.id,
      nodeId: node.id,
    );
  }
}

class _ScriptLibraryHeader extends StatelessWidget {
  const _ScriptLibraryHeader({
    required this.scriptsCount,
    required this.onCreateScript,
    required this.onClearSelection,
  });

  final int scriptsCount;
  final VoidCallback onCreateScript;
  final VoidCallback? onClearSelection;

  @override
  Widget build(BuildContext context) {
    const accent = EditorChrome.inspectorJoyLilac;
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
                const InspectorEmbeddedSectionLabel('SCENARIO SCRIPTS'),
                const SizedBox(height: 2),
                Text(
                  '$scriptsCount script(s)',
                  style: TextStyle(
                    fontSize: 11,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
          EditorToolbarIconButton(
            icon: CupertinoIcons.plus,
            tooltip: 'Create script',
            onPressed: onCreateScript,
          ),
          if (onClearSelection != null)
            EditorToolbarIconButton(
              icon: CupertinoIcons.clear,
              tooltip: 'Clear selection',
              onPressed: onClearSelection!,
            ),
        ],
      ),
    );
  }
}

class _ScriptLibraryEmptyState extends StatelessWidget {
  const _ScriptLibraryEmptyState({
    required this.onCreate,
  });

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    const accent = EditorChrome.inspectorJoyLilac;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const InspectorEmbeddedFootnote(
          accent: accent,
          text:
              'Aucun script scénario. Crée un script ici pour le référencer ensuite depuis les pages d’events.',
        ),
        const SizedBox(height: 8),
        CupertinoButton.filled(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: const Size(0, 28),
          onPressed: onCreate,
          child: const Text(
            'Create first script',
            style: TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _ScriptListRow extends StatelessWidget {
  const _ScriptListRow({
    required this.script,
    required this.selected,
    required this.onSelect,
    required this.onRename,
    required this.onDelete,
  });

  final ProjectScriptEntry script;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return EditorSidebarListRow(
      selected: selected,
      onTap: onSelect,
      leading: const Icon(CupertinoIcons.chevron_left_slash_chevron_right),
      title: Text(script.name),
      subtitle: Text(
        '${script.id} · ${script.asset.nodes.length} node(s)',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Builder(
        builder: (buttonContext) => EditorToolbarIconButton(
          icon: CupertinoIcons.ellipsis_vertical,
          tooltip: 'Script actions',
          iconSize: 16,
          color: selected ? CupertinoColors.white : null,
          onPressed: () => _showScriptContextMenu(
            context,
            anchorGlobal: editorMenuAnchorBelowWidget(buttonContext),
            onRename: onRename,
            onDelete: onDelete,
          ),
        ),
      ),
      onSecondaryTapDown: (details) => _showScriptContextMenu(
        context,
        anchorGlobal: details.globalPosition,
        onRename: onRename,
        onDelete: onDelete,
      ),
      leftIndent: 8,
    );
  }

  Future<void> _showScriptContextMenu(
    BuildContext context, {
    required Offset anchorGlobal,
    required VoidCallback onRename,
    required VoidCallback onDelete,
  }) async {
    final action = await showMacosEditorContextMenu<String>(
      context: context,
      globalPosition: anchorGlobal,
      actions: const [
        MacosEditorSheetAction(label: 'Rename', value: 'rename'),
        MacosEditorSheetAction(
          label: 'Delete',
          value: 'delete',
          isDestructive: true,
        ),
      ],
    );
    if (!context.mounted || action == null) return;
    switch (action) {
      case 'rename':
        onRename();
      case 'delete':
        onDelete();
    }
  }
}

class _ScriptDetailCard extends StatelessWidget {
  const _ScriptDetailCard({
    required this.script,
    required this.onRename,
    required this.onDelete,
    required this.onSetDefaultStartNode,
    required this.onAddNode,
    required this.onRenameNode,
    required this.onDeleteNode,
  });

  final ProjectScriptEntry script;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final ValueChanged<String> onSetDefaultStartNode;
  final VoidCallback onAddNode;
  final ValueChanged<ScriptNode> onRenameNode;
  final ValueChanged<ScriptNode> onDeleteNode;

  @override
  Widget build(BuildContext context) {
    const accent = EditorChrome.inspectorJoyCyan;
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final defaultNodeId = script.asset.defaultStartNode.trim();
    final nodeIds = <String>[for (final node in script.asset.nodes) node.id];
    final selectedNodeId = nodeIds.contains(defaultNodeId)
        ? defaultNodeId
        : (nodeIds.isEmpty ? '' : nodeIds.first);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: accent.withValues(alpha: 0.07),
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const InspectorEmbeddedSectionLabel('SELECTED SCRIPT'),
                    const SizedBox(height: 2),
                    Text(
                      script.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      script.id,
                      style: TextStyle(fontSize: 11, color: subtle),
                    ),
                  ],
                ),
              ),
              EditorToolbarIconButton(
                icon: CupertinoIcons.pencil,
                tooltip: 'Rename script',
                onPressed: onRename,
              ),
              EditorToolbarIconButton(
                icon: CupertinoIcons.trash,
                tooltip: 'Delete script',
                iconSize: 16,
                color: CupertinoColors.destructiveRed.resolveFrom(context),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (nodeIds.isNotEmpty)
            InspectorEmbeddedDropdown(
              accent: accent,
              fieldLabel: 'Default start node',
              valueLabel: selectedNodeId,
              orderedIds: nodeIds,
              selectedMenuValue: selectedNodeId,
              selectedIdForCheck: selectedNodeId,
              idToLabel: (id) => id,
              onSelected: onSetDefaultStartNode,
              tooltip: 'Default script start node',
            )
          else
            Text(
              'No nodes available',
              style: TextStyle(fontSize: 11, color: subtle),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(child: InspectorEmbeddedSectionLabel('NODES')),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 26),
                onPressed: onAddNode,
                child: const Text('Add node', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (script.asset.nodes.isEmpty)
            Text(
              'No node yet.',
              style: TextStyle(fontSize: 11, color: subtle),
            )
          else
            ...script.asset.nodes.map(
              (node) {
                final isDefault = node.id == selectedNodeId;
                final title =
                    node.title.trim().isEmpty ? '(untitled)' : node.title;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
                    decoration: BoxDecoration(
                      color: EditorChrome.largeIslandSurfaceColor(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDefault
                            ? accent.withValues(alpha: 0.65)
                            : CupertinoColors.separator.resolveFrom(context),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: labelColor,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '${node.id} · ${node.commands.length} command(s)'
                                '${isDefault ? ' · default start' : ''}',
                                style: TextStyle(fontSize: 10, color: subtle),
                              ),
                            ],
                          ),
                        ),
                        EditorToolbarIconButton(
                          icon: CupertinoIcons.pencil,
                          tooltip: 'Rename node',
                          iconSize: 14,
                          onPressed: () => onRenameNode(node),
                        ),
                        EditorToolbarIconButton(
                          icon: CupertinoIcons.trash,
                          tooltip: 'Delete node',
                          iconSize: 14,
                          color: CupertinoColors.destructiveRed
                              .resolveFrom(context),
                          onPressed: () => onDeleteNode(node),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 6),
          const InspectorEmbeddedFootnote(
            accent: accent,
            text:
                'MapPlaced Events référencent ces scripts via scriptId. Ce panneau couvre le MVP bibliothèque + structure de nœuds (pas encore d’éditeur graphe).',
          ),
        ],
      ),
    );
  }
}
