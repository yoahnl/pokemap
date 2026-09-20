import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'event_condition_dialog.dart';
import 'event_condition_labels.dart';

class EventConditions extends StatelessWidget {
  const EventConditions({
    super.key,
    required this.expression,
    required this.facts,
    required this.records,
    required this.onChanged,
  });
  final NarrativeEventConditionExpression expression;
  final List<NarrativeFactDefinition> facts;
  final List<NarrativeEventRecord> records;
  final ValueChanged<NarrativeEventConditionExpression> onChanged;

  @override
  Widget build(BuildContext context) =>
      SingleChildScrollView(child: _node(context, expression, onChanged, null));

  Widget _node(
    BuildContext context,
    NarrativeEventConditionExpression value,
    ValueChanged<NarrativeEventConditionExpression> replace,
    VoidCallback? remove,
  ) {
    final children = switch (value) {
      NarrativeEventConditionAll(:final children) => children,
      NarrativeEventConditionAny(:final children) => children,
      _ => <NarrativeEventConditionExpression>[],
    };
    NarrativeEventConditionExpression group(
      List<NarrativeEventConditionExpression> items,
    ) => value is NarrativeEventConditionAny
        ? NarrativeEventConditionExpression.any(items)
        : NarrativeEventConditionExpression.all(items);
    final title = switch (value) {
      NarrativeEventConditionLeaf(:final condition) => eventConditionLabel(
        condition,
        facts,
        records,
      ),
      NarrativeEventConditionAll() =>
        children.isEmpty ? 'Sans condition' : 'Toutes ces conditions',
      NarrativeEventConditionAny() => 'Au moins une condition',
      NarrativeEventConditionNot() => 'Inverser cette condition',
    };
    Future<void> add({NarrativeEventCondition? initial}) async {
      final selected = await chooseEventCondition(
        context,
        facts: facts,
        records: records,
        initial: initial,
      );
      if (selected == null || !context.mounted) return;
      final leaf = NarrativeEventConditionExpression.leaf(selected);
      if (value is NarrativeEventConditionLeaf) {
        replace(leaf);
      } else {
        replace(group([...children, leaf]));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: StudioPanel(
        compact: true,
        title: title,
        actions: [
          if (value is NarrativeEventConditionLeaf)
            StudioTool(
              label: 'Modifier la condition',
              icon: Icons.edit_outlined,
              onPressed: () => add(initial: value.condition),
            ),
          if (value is! NarrativeEventConditionNot && children.isNotEmpty ||
              value is NarrativeEventConditionLeaf)
            StudioTool(
              label: 'Inverser',
              icon: Icons.swap_horiz,
              onPressed: () =>
                  replace(NarrativeEventConditionExpression.not(value)),
            ),
          if (value is NarrativeEventConditionAll && children.isNotEmpty)
            StudioTool(
              label: 'Au moins une',
              icon: Icons.call_split,
              onPressed: () =>
                  replace(NarrativeEventConditionExpression.any(children)),
            ),
          if (value is NarrativeEventConditionAny)
            StudioTool(
              label: 'Toutes',
              icon: Icons.merge,
              onPressed: () =>
                  replace(NarrativeEventConditionExpression.all(children)),
            ),
          if (remove != null)
            StudioTool(
              label: 'Retirer la condition',
              icon: Icons.close,
              onPressed: remove,
            ),
        ],
        children: [
          if (value is NarrativeEventConditionNot) ...[
            StudioButton(
              label: 'Retirer l’inversion',
              secondary: true,
              onPressed: () => replace(value.child),
            ),
            const SizedBox(height: 8),
            _node(
              context,
              value.child,
              (child) => replace(NarrativeEventConditionExpression.not(child)),
              null,
            ),
          ],
          for (var i = 0; i < children.length; i++)
            _node(
              context,
              children[i],
              (child) => replace(group([...children]..[i] = child)),
              () => replace(group([...children]..removeAt(i))),
            ),
          if (value is NarrativeEventConditionAll ||
              value is NarrativeEventConditionAny)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StudioButton(
                  label: 'Ajouter une condition',
                  icon: Icons.add,
                  secondary: true,
                  onPressed: add,
                ),
                StudioButton(
                  label: 'Ajouter un groupe',
                  secondary: true,
                  onPressed: () async {
                    final condition = await chooseEventCondition(
                      context,
                      facts: facts,
                      records: records,
                    );
                    if (condition != null && context.mounted) {
                      replace(
                        group([
                          ...children,
                          NarrativeEventConditionExpression.all([
                            NarrativeEventConditionExpression.leaf(condition),
                          ]),
                        ]),
                      );
                    }
                  },
                ),
              ],
            ),
          if (value is NarrativeEventConditionLeaf)
            StudioButton(
              label: 'Grouper avec une autre condition',
              secondary: true,
              onPressed: () async {
                final condition = await chooseEventCondition(
                  context,
                  facts: facts,
                  records: records,
                );
                if (condition != null && context.mounted) {
                  replace(
                    NarrativeEventConditionExpression.all([
                      value,
                      NarrativeEventConditionExpression.leaf(condition),
                    ]),
                  );
                }
              },
            ),
        ],
      ),
    );
  }
}
