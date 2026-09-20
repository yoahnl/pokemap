import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import 'dialogue_view_state.dart';

class DialogueGraphRow {
  const DialogueGraphRow(this.step, {this.branch, this.depth = 0});
  final DialogueEditorStep step;
  final DeChoiceBranch? branch;
  final int depth;
  String get id => branch?.id ?? step.id;
  double get height => branch != null
      ? branch!.outcomeId == null
            ? 44
            : 64
      : switch (step) {
          DeLineStep() || DeNarrationStep() => 84,
          _ => 36,
        };
}

List<DialogueGraphRow> dialogueRows(
  List<DialogueEditorStep> steps, [
  int depth = 0,
]) => [
  for (final step in steps)
    if (step is DeChoiceStep) ...[
      DialogueGraphRow(step, depth: depth),
      for (final branch in step.branches) ...[
        DialogueGraphRow(step, branch: branch, depth: depth),
        ...dialogueRows(
          branch.steps.where((s) => s is! DeJumpStep).toList(),
          depth + 1,
        ),
      ],
    ] else if (step is! DeStartStep && step is! DeEndStep)
      DialogueGraphRow(step, depth: depth),
];

class DialogueGraphWire {
  const DialogueGraphWire(this.id, this.source, this.target, this.row);
  final String id, source, target;
  final int row;
}

class DialogueGraphGeometry {
  DialogueGraphGeometry(this.document, this.view, this.scale) {
    view.reconcile(document);
    for (final node in document.nodes) {
      rows[node.id] = dialogueRows(node.steps);
      for (var i = 0; i < rows[node.id]!.length; i++) {
        final row = rows[node.id]![i];
        final jumps = row.branch == null
            ? (row.step is DeJumpStep
                  ? [row.step as DeJumpStep]
                  : <DeJumpStep>[])
            : row.branch!.steps.whereType<DeJumpStep>();
        for (final jump in jumps) {
          final target = document.nodes
              .where((n) => n.title == jump.targetTitle)
              .firstOrNull;
          if (target != null) {
            wires.add(DialogueGraphWire(row.id, node.id, target.id, i));
          }
        }
      }
    }
  }
  final DialogueEditorDocument document;
  final DialogueViewState view;
  final double scale;
  final rows = <String, List<DialogueGraphRow>>{};
  final wires = <DialogueGraphWire>[];
  double rowHeight(DialogueGraphRow row) => row.height * scale;
  double get headerHeight => 42 * scale;
  double get width => 242 * math.max(1, scale * .85);
  Rect rect(String id) =>
      view.positions[id]! &
      Size(
        width,
        headerHeight +
            rows[id]!.fold<double>(0, (sum, r) => sum + rowHeight(r)) +
            36 * scale,
      );
  Offset input(String id) => rect(id).topLeft + Offset(0, headerHeight / 2);
  Offset output(String id, int row) =>
      rect(id).topRight +
      Offset(
        0,
        headerHeight +
            rows[id]!
                .take(row)
                .fold<double>(0, (sum, r) => sum + rowHeight(r)) +
            rowHeight(rows[id]![row]) / 2,
      );
  Rect get bounds => document.nodes.isEmpty
      ? const Rect.fromLTWH(0, 0, 600, 400)
      : document.nodes
            .map((n) => rect(n.id))
            .reduce((a, b) => a.expandToInclude(b));
}
