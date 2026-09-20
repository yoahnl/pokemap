import 'package:flutter/material.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import '../../shared/widgets/layout/studio_graph_card.dart';
import '../../shared/widgets/feedback/studio_badge.dart';
import 'dialogue_graph_geometry.dart';

class DialogueGraphNode extends StatelessWidget {
  const DialogueGraphNode({
    super.key,
    required this.node,
    required this.geometry,
    required this.onSelect,
    required this.onMove,
    required this.onWireStart,
    required this.onWireMove,
    required this.onWireEnd,
    this.target = false,
    this.portrait,
    this.outcomes = const {},
  });
  final DialogueEditorNode node;
  final DialogueGraphGeometry geometry;
  final void Function({String? step, String? branch}) onSelect;
  final ValueChanged<Offset> onMove;
  final ValueChanged<int> onWireStart;
  final ValueChanged<Offset> onWireMove;
  final VoidCallback onWireEnd;
  final bool target;
  final Widget Function(String?, String?, double)? portrait;
  final Map<String, String> outcomes;
  @override
  Widget build(BuildContext context) {
    final selected = geometry.view.nodeId == node.id;
    final entry = geometry.document.effectiveEntryNodeId == node.id;
    final colors = Theme.of(context).colorScheme;
    final color = entry ? colors.primary : StudioTone.feature.color(context);
    final rows = geometry.rows[node.id]!;
    return StudioGraphCard(
      selected: selected || target,
      accent: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            key: ValueKey('dialogue-node-${node.id}'),
            onTap: () => onSelect(),
            onPanStart: (_) => onSelect(),
            onPanUpdate: (event) =>
                onMove(event.delta / geometry.view.viewport.zoom),
            child: Container(
              height: geometry.headerHeight,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: .72),
                    color.withValues(alpha: .32),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    entry ? Icons.play_circle_outline : Icons.forum_outlined,
                    color: colors.onSurface,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      node.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (var i = 0; i < rows.length; i++)
            SizedBox(
              height: geometry.rowHeight(rows[i]),
              child: _row(context, rows[i], i),
            ),
          SizedBox(
            height: 36 * geometry.scale,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  entry ? 'Point de départ' : 'Suite de conversation',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, DialogueGraphRow row, int index) {
    final state = geometry.view;
    final selected = row.branch == null
        ? state.stepId == row.id
        : state.branchId == row.id;
    final tone = row.branch != null ? StudioTone.feature : StudioTone.info;
    final color = tone.color(context);
    final hasPort = row.branch != null || row.step is DeJumpStep;
    final label =
        row.branch?.label ??
        switch (row.step) {
          DeLineStep(:final body) => body,
          DeNarrationStep(:final text) => text,
          DeChoiceStep() => 'Le joueur répond…',
          DeJumpStep(:final targetTitle) => 'Continuer vers $targetTitle',
          DeCommandStep(:final raw) => _commandLabel(raw),
          DeConditionStep(:final raw) => raw,
          _ => '',
        };
    return InkWell(
      key: ValueKey('dialogue-row-${row.id}'),
      onTap: () => onSelect(step: row.step.id, branch: row.branch?.id),
      child: Container(
        color: color.withValues(
          alpha: selected
              ? .24
              : hasPort
              ? .1
              : .03,
        ),
        padding: EdgeInsets.only(
          left: 10 + row.depth * 8,
          right: hasPort ? 0 : 10,
        ),
        child: Row(
          children: [
            if (row.branch == null &&
                row.step is DeLineStep &&
                portrait != null) ...[
              portrait!(
                (row.step as DeLineStep).characterId,
                (row.step as DeLineStep).portraitStateId,
                28,
              ),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (row.step is DeLineStep &&
                      row.branch == null &&
                      (row.step as DeLineStep).speaker?.isNotEmpty == true)
                    Text(
                      (row.step as DeLineStep).speaker!,
                      maxLines: 1,
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: color),
                    ),
                  Text(
                    label,
                    maxLines: row.branch == null ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (row.branch?.outcomeId case final result?)
                    Text(
                      'Résultat : ${outcomes[result] ?? result}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: StudioTone.success.color(context),
                      ),
                    ),
                ],
              ),
            ),
            if (hasPort)
              GestureDetector(
                key: ValueKey('dialogue-port-${row.id}'),
                behavior: HitTestBehavior.opaque,
                onPanStart: (_) => onWireStart(index),
                onPanUpdate: (event) => onWireMove(event.globalPosition),
                onPanEnd: (_) => onWireEnd(),
                child: Tooltip(
                  message: 'Relier à une suite',
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.circle, size: 12, color: color),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _commandLabel(String raw) {
    final match = RegExp(r'^<<outcome\s+([^>]+)>>$').firstMatch(raw.trim());
    if (match != null) return 'Résultat : ${outcomes[match[1]] ?? match[1]}';
    return 'Contenu conservé · consulter Yarn';
  }
}
