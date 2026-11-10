import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';
import '../../../features/narrative/application/narrative_interaction.dart';
import '../../../features/narrative/application/narrative_editing.dart';
import '../../../features/narrative/application/narrative_workspace_controller.dart';

class NarrativeSequenceEditor extends StatelessWidget {
  const NarrativeSequenceEditor({
    super.key,
    required this.controller,
    required this.steps,
    required this.onChanged,
  });
  final NarrativeWorkspaceController controller;
  final List<NarrativeSequenceStep> steps;
  final ValueChanged<List<NarrativeSequenceStep>> onChanged;
  static const labels = narrativeSequenceLabels;

  Map<String, String> targets(NarrativeSequenceKind kind) =>
      narrativeSequenceTargets(
        kind,
        project: controller.project,
        map: controller.active?.document.current,
        stories: controller.stories,
        facts: controller.facts,
      );

  @override
  Widget build(BuildContext context) {
    void replace(int i, NarrativeSequenceStep step) {
      final next = [...steps];
      next[i] = step;
      onChanged(next);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final indexed in steps.indexed)
          Builder(
            builder: (context) {
              final i = indexed.$1, step = indexed.$2;
              final choices = targets(step.kind);
              void update({
                String? target,
                bool? value,
                EntityFacing? facing,
                int? ms,
              }) => replace(
                i,
                step.revise(
                  target: target,
                  value: value,
                  facing: facing,
                  milliseconds: ms,
                ),
              );
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: StudioPanel(
                  compact: true,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('${i + 1}. ${labels[step.kind]}')),
                        IconButton(
                          tooltip: 'Monter l’action',
                          onPressed: i == 0
                              ? null
                              : () {
                                  final next = [...steps];
                                  next[i] = next[i - 1];
                                  next[i - 1] = step;
                                  onChanged(next);
                                },
                          icon: const Icon(Icons.arrow_upward),
                        ),
                        IconButton(
                          tooltip: 'Descendre l’action',
                          onPressed: i + 1 == steps.length
                              ? null
                              : () {
                                  final next = [...steps];
                                  next[i] = next[i + 1];
                                  next[i + 1] = step;
                                  onChanged(next);
                                },
                          icon: const Icon(Icons.arrow_downward),
                        ),
                        IconButton(
                          tooltip: 'Retirer l’action',
                          onPressed: () => onChanged([...steps]..removeAt(i)),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    if (step.kind != NarrativeSequenceKind.wait)
                      DropdownButton<String>(
                        isExpanded: true,
                        value: choices.containsKey(step.targetId)
                            ? step.targetId
                            : null,
                        hint: const Text('Choisir la cible'),
                        items: [
                          for (final item in choices.entries)
                            DropdownMenuItem(
                              value: item.key,
                              child: Text(
                                item.value,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (v) {
                          if (v != null) update(target: v);
                        },
                      ),
                    if (step.kind == NarrativeSequenceKind.setFact)
                      StudioToggleRow(
                        label: step.value ? 'État activé' : 'État désactivé',
                        value: step.value,
                        onChanged: (v) => update(value: v),
                      ),
                    if (step.kind == NarrativeSequenceKind.facing)
                      DropdownButton<EntityFacing>(
                        value: step.facing,
                        items: [
                          for (final f in EntityFacing.values)
                            DropdownMenuItem(
                              value: f,
                              child: Text(switch (f) {
                                EntityFacing.north => 'Vers le haut',
                                EntityFacing.south => 'Vers le bas',
                                EntityFacing.east => 'Vers la droite',
                                EntityFacing.west => 'Vers la gauche',
                              }),
                            ),
                        ],
                        onChanged: (v) => update(facing: v),
                      ),
                    if (step.kind == NarrativeSequenceKind.wait)
                      StudioDraftField(
                        value: '${step.milliseconds}',
                        label: 'Attente en millisecondes',
                        onChanged: (v) {
                          final ms = int.tryParse(v);
                          if (ms != null && ms >= 0) update(ms: ms);
                        },
                      ),
                  ],
                ),
              );
            },
          ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final kind in NarrativeSequenceKind.values)
              StudioButton(
                label: '+ ${labels[kind]}',
                secondary: true,
                onPressed: () => onChanged([
                  ...steps,
                  NarrativeSequenceStep(
                    kind: kind,
                    targetId: targets(kind).keys.firstOrNull ?? '',
                  ),
                ]),
              ),
          ],
        ),
      ],
    );
  }
}
