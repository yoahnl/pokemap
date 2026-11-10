import 'package:map_authoring/map_authoring_dialogue.dart';

final class DialogueStructureRow {
  const DialogueStructureRow(this.step, {this.branch, this.depth = 0});

  final DialogueEditorStep step;
  final DeChoiceBranch? branch;
  final int depth;

  String get id => branch?.id ?? step.id;
  bool get hasPort => branch != null || step is DeJumpStep;
}

List<DialogueStructureRow> dialogueStructureRows(
  List<DialogueEditorStep> steps, [
  int depth = 0,
]) => [
  for (final step in steps)
    if (step is DeChoiceStep) ...[
      DialogueStructureRow(step, depth: depth),
      for (final branch in step.branches) ...[
        DialogueStructureRow(step, branch: branch, depth: depth),
        ...dialogueStructureRows(
          branch.steps.where((step) => step is! DeJumpStep).toList(),
          depth + 1,
        ),
      ],
    ] else if (step is! DeStartStep && step is! DeEndStep)
      DialogueStructureRow(step, depth: depth),
];

final class DialogueStructureWire {
  const DialogueStructureWire(this.id, this.source, this.target, this.row);

  final String id, source, target;
  final int row;
}

final class DialogueStructureProjection {
  DialogueStructureProjection(DialogueEditorDocument document) {
    final projectedRows = <String, List<DialogueStructureRow>>{};
    final projectedWires = <DialogueStructureWire>[];
    for (final node in document.nodes) {
      final nodeRows = dialogueStructureRows(node.steps);
      projectedRows[node.id] = List.unmodifiable(nodeRows);
      for (var index = 0; index < nodeRows.length; index++) {
        final row = nodeRows[index];
        final jumps = row.branch == null
            ? (row.step is DeJumpStep
                  ? [row.step as DeJumpStep]
                  : <DeJumpStep>[])
            : row.branch!.steps.whereType<DeJumpStep>();
        for (final jump in jumps) {
          final target = document.nodes
              .where((node) => node.title == jump.targetTitle)
              .firstOrNull;
          if (target != null) {
            projectedWires.add(
              DialogueStructureWire(row.id, node.id, target.id, index),
            );
          }
        }
      }
    }
    rows = Map.unmodifiable(projectedRows);
    wires = List.unmodifiable(projectedWires);
  }

  late final Map<String, List<DialogueStructureRow>> rows;
  late final List<DialogueStructureWire> wires;

  String? portIdAt(String nodeId, int rowIndex) {
    final nodeRows = rows[nodeId];
    if (nodeRows == null || rowIndex < 0 || rowIndex >= nodeRows.length) {
      return null;
    }
    final row = nodeRows[rowIndex];
    return row.hasPort ? row.id : null;
  }
}
