part of 'package:map_editor/src/ui/canvas/dialogue_studio_workspace.dart';

/// Cartes visuelles du canvas de dialogue et helpers purement présentations.
class _NodeCanvasCard extends StatelessWidget {
  const _NodeCanvasCard({
    required this.node,
    required this.selection,
    required this.onSelectStep,
    required this.onDeleteStep,
  });

  final DialogueEditorNode node;
  final _StepSelection? selection;
  final void Function(_StepSelection sel) onSelectStep;
  final void Function(_StepSelection sel) onDeleteStep;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: CupertinoColors.separator.resolveFrom(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: Text(
                'Nœud : ${node.title}',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final step in node.steps) ...[
                    _StepBlockTile(
                      step: step,
                      nodeId: node.id,
                      branchId: null,
                      selected: selection?.nodeId == node.id &&
                          selection?.branchId == null &&
                          selection?.stepId == step.id,
                      onTap: () => onSelectStep(
                        _StepSelection(nodeId: node.id, stepId: step.id),
                      ),
                      onDelete: () => onDeleteStep(
                        _StepSelection(nodeId: node.id, stepId: step.id),
                      ),
                    ),
                    if (step is DeChoiceStep)
                      for (final branch in step.branches)
                        Padding(
                          padding: const EdgeInsets.only(left: 12, top: 8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: EditorChrome.inspectorJoyMint
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Branche : ${branch.label}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                for (final inner in branch.steps)
                                  _StepBlockTile(
                                    step: inner,
                                    nodeId: node.id,
                                    branchId: branch.id,
                                    selected: selection?.nodeId == node.id &&
                                        selection?.branchId == branch.id &&
                                        selection?.stepId == inner.id,
                                    onTap: () => onSelectStep(
                                      _StepSelection(
                                        nodeId: node.id,
                                        branchId: branch.id,
                                        stepId: inner.id,
                                      ),
                                    ),
                                    onDelete: () => onDeleteStep(
                                      _StepSelection(
                                        nodeId: node.id,
                                        branchId: branch.id,
                                        stepId: inner.id,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBlockTile extends StatelessWidget {
  const _StepBlockTile({
    required this.step,
    required this.nodeId,
    required this.branchId,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  final DialogueEditorStep step;
  final String nodeId;
  final String? branchId;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final (String title, String subtitle) = switch (step) {
      DeStartStep() => ('Début', 'Point d’entrée visuel'),
      DeLineStep(:final speaker, :final body) => (
          'Réplique',
          '${speaker ?? '?'}: $body',
        ),
      DeNarrationStep(:final text) => ('Narration', text),
      DeChoiceStep() => ('Choix joueur', 'Plusieurs branches'),
      DeJumpStep(:final targetTitle) => ('Jump', '→ $targetTitle'),
      DeConditionStep(:final raw) => ('Condition', raw),
      DeCommandStep(:final raw) => ('Commande', raw),
      DeEndStep() => ('Fin', 'Termine ici'),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected
                ? EditorChrome.inspectorJoyBlue.withValues(alpha: 0.12)
                : CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? EditorChrome.inspectorJoyBlue
                  : CupertinoColors.separator.resolveFrom(context),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        color: EditorChrome.inspectorJoyBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, height: 1.25),
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(28, 28),
                onPressed: onDelete,
                child: const Icon(
                  CupertinoIcons.trash,
                  size: 16,
                  color: EditorChrome.inspectorJoyCoral,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

({int nodes, int choices, int ends}) _docStats(DialogueEditorDocument? doc) {
  if (doc == null) return (nodes: 0, choices: 0, ends: 0);
  var choices = 0;
  var ends = 0;

  void walk(List<DialogueEditorStep> list) {
    for (final step in list) {
      if (step is DeChoiceStep) {
        choices++;
        for (final branch in step.branches) {
          walk(branch.steps);
        }
      }
      if (step is DeEndStep) {
        ends++;
      }
    }
  }

  for (final node in doc.nodes) {
    walk(node.steps);
  }
  return (nodes: doc.nodes.length, choices: choices, ends: ends);
}

String _dialogueName(ProjectManifest project, String id) {
  for (final dialogue in project.dialogues) {
    if (dialogue.id == id) return dialogue.name;
  }
  return id;
}
