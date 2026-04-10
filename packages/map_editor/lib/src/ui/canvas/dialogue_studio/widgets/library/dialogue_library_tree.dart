part of 'package:map_editor/src/ui/canvas/dialogue_studio_workspace.dart';

/// Arbre de bibliothèque du studio dialogue.
/// On garde ici uniquement les widgets de rendu de l'arborescence projet,
/// sans déplacer la logique de sélection ou les appels notifier hors du workspace.
class _StudioDialogueFolderTreeNode extends StatefulWidget {
  const _StudioDialogueFolderTreeNode({
    required this.branch,
    required this.depth,
    required this.project,
    required this.selectedDialogueId,
    required this.targetFolderId,
    required this.filter,
    required this.onDialogueTap,
    required this.onFolderTargetTap,
    required this.onFolderMenu,
    required this.onDialogueEntryMenuButton,
  });

  final DialogueLibraryBranch branch;
  final int depth;
  final ProjectManifest project;
  final String? selectedDialogueId;
  final String? targetFolderId;
  final bool Function(ProjectDialogueEntry) filter;
  final void Function(String dialogueId, String? parentFolderId) onDialogueTap;
  final ValueChanged<String> onFolderTargetTap;
  final void Function(BuildContext buttonContext, ProjectDialogueFolder folder)
      onFolderMenu;
  final void Function(
          ProjectDialogueEntry entry, BuildContext menuButtonContext)
      onDialogueEntryMenuButton;

  @override
  State<_StudioDialogueFolderTreeNode> createState() =>
      _StudioDialogueFolderTreeNodeState();
}

class _StudioDialogueFolderTreeNodeState
    extends State<_StudioDialogueFolderTreeNode> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final f = widget.branch.folder;
    final isTarget = widget.targetFolderId == f.id;
    final left = widget.depth * 12.0 + 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(left: left, top: 4, bottom: 2),
          child: Row(
            children: [
              CupertinoButton(
                padding: const EdgeInsets.all(4),
                minimumSize: Size.zero,
                onPressed: () => setState(() => _expanded = !_expanded),
                child: AnimatedRotation(
                  turns: _expanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 140),
                  child: MacosIcon(
                    CupertinoIcons.chevron_right,
                    size: 14,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ),
              Expanded(
                child: CupertinoButton(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  minimumSize: Size.zero,
                  alignment: Alignment.centerLeft,
                  onPressed: () => widget.onFolderTargetTap(f.id),
                  child: Row(
                    children: [
                      MacosIcon(
                        CupertinoIcons.folder_fill,
                        size: 15,
                        color: isTarget
                            ? EditorChrome.inspectorJoyBlue
                            : CupertinoColors.secondaryLabel
                                .resolveFrom(context),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          f.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: isTarget
                                ? EditorChrome.inspectorJoyBlue
                                : CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Builder(
                builder: (btnContext) => EditorToolbarIconButton(
                  icon: CupertinoIcons.ellipsis_vertical,
                  tooltip: 'Actions dossier',
                  iconSize: 16,
                  onPressed: () => widget.onFolderMenu(btnContext, f),
                ),
              ),
            ],
          ),
        ),
        if (_expanded) ...[
          for (final child in widget.branch.childFolders)
            _StudioDialogueFolderTreeNode(
              branch: child,
              depth: widget.depth + 1,
              project: widget.project,
              selectedDialogueId: widget.selectedDialogueId,
              targetFolderId: widget.targetFolderId,
              filter: widget.filter,
              onDialogueTap: widget.onDialogueTap,
              onFolderTargetTap: widget.onFolderTargetTap,
              onFolderMenu: widget.onFolderMenu,
              onDialogueEntryMenuButton: widget.onDialogueEntryMenuButton,
            ),
          for (final dialogue in widget.branch.dialogues.where(widget.filter))
            _DialogueEntryRow(
              entry: dialogue,
              selected: widget.selectedDialogueId == dialogue.id,
              depth: widget.depth + 1,
              onTap: () => widget.onDialogueTap(dialogue.id, dialogue.folderId),
              onMenuButton: (btnCtx) =>
                  widget.onDialogueEntryMenuButton(dialogue, btnCtx),
            ),
        ],
      ],
    );
  }
}

class _DialogueEntryRow extends StatelessWidget {
  const _DialogueEntryRow({
    required this.entry,
    required this.selected,
    required this.depth,
    required this.onTap,
    this.onMenuButton,
  });

  final ProjectDialogueEntry entry;
  final bool selected;
  final int depth;
  final VoidCallback onTap;
  final void Function(BuildContext menuButtonContext)? onMenuButton;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: depth * 12.0),
      child: Row(
        children: [
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              minimumSize: Size.zero,
              onPressed: onTap,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? EditorChrome.inspectorJoyBlue.withValues(alpha: 0.14)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected
                        ? EditorChrome.inspectorJoyBlue
                        : CupertinoColors.separator
                            .resolveFrom(context)
                            .withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          if (onMenuButton != null)
            Builder(
              builder: (btnContext) => EditorToolbarIconButton(
                icon: CupertinoIcons.ellipsis_vertical,
                tooltip: 'Actions dialogue',
                iconSize: 16,
                onPressed: () => onMenuButton!(btnContext),
              ),
            ),
        ],
      ),
    );
  }
}
