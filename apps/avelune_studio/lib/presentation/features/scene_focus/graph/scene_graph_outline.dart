import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/scenes/application/scene_changed_facts.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

import 'scene_graph_labels.dart';
import 'scene_graph_palette.dart';

class SceneGraphOutline extends StatelessWidget {
  const SceneGraphOutline({
    super.key,
    required this.scene,
    required this.selection,
    required this.dialogues,
    required this.factNames,
    required this.search,
    required this.searchFocus,
    required this.onShow,
  });

  final SceneAsset scene;
  final Set<String> selection;
  final Map<String, ProjectDialogueEntry> dialogues;
  final Map<String, String> factNames;
  final TextEditingController search;
  final FocusNode searchFocus;
  final ValueChanged<String> onShow;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(StudioSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StudioSearchField(
            key: const ValueKey('scene-graph-outline-search'),
            label: l10n.sceneGraphOutlineSearch,
            controller: search,
            focusNode: searchFocus,
            onChanged: (_) {},
          ),
          const SizedBox(height: StudioSpacing.s),
          Expanded(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: search,
              builder: (context, value, _) {
                final term = value.text.trim().toLowerCase();
                final rows = [
                  for (final node in scene.graph.nodes)
                    (
                      node: node,
                      title: sceneGraphNodeTitle(l10n, node),
                      detail: switch (node.payload) {
                        SceneYarnDialoguePayload(:final dialogueId) =>
                          dialogues[dialogueId]?.name,
                        SceneConditionPayload(:final conditionSource) =>
                          conditionSource?.label,
                        _ => null,
                      },
                    ),
                ];
                final matches = rows.where(
                  (row) => [
                    row.title,
                    ?row.detail,
                  ].any((text) => text.toLowerCase().contains(term)),
                );
                return ListView(
                  key: ValueKey('scene-graph-outline-${scene.id}'),
                  children: [
                    if (matches.isEmpty) Text(l10n.sceneGraphNoMatch),
                    for (final row in matches)
                      StudioChoice(
                        key: ValueKey('scene-graph-outline-${row.node.id}'),
                        label: row.title,
                        leading: Icon(
                          sceneGraphNodeIcon(row.node),
                          size: 15,
                          color: sceneGraphNodeAccent(context, row.node),
                        ),
                        dense: true,
                        selected: selection.contains(row.node.id),
                        onTap: () => onShow(row.node.id),
                      ),
                    if (term.isEmpty) ..._usages(context),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _usages(BuildContext context) {
    final l10n = context.l10n;
    final facts = {
      ...sceneChangedFactIds(scene.graph),
      for (final node in scene.graph.nodes)
        if (node.payload case SceneConditionPayload(:final conditionSource?))
          ...switch (conditionSource.sourceKind) {
            SceneConditionSourceKind.fact => {conditionSource.sourceId},
            SceneConditionSourceKind.integerComparison => {
              ...?conditionSource.integerLeft?.referencedFactIds,
              ...?conditionSource.integerRight?.referencedFactIds,
            },
            _ => const <String>{},
          },
    };
    final known = facts.map((id) => factNames[id]).nonNulls;
    if (known.isEmpty) return const [];
    return [
      const SizedBox(height: StudioSpacing.m),
      Text(
        l10n.sceneGraphKnownFacts,
        style: Theme.of(context).textTheme.labelMedium,
      ),
      for (final name in known)
        Padding(
          padding: const EdgeInsets.only(top: StudioSpacing.xs),
          child: Text(name, style: Theme.of(context).textTheme.bodySmall),
        ),
    ];
  }
}
