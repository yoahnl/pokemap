import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../../features/narrative/application/narrative_interaction_edits.dart';
import '../../../features/narrative/application/narrative_workspace_controller.dart';
import 'narrative_name_dialog.dart';

class NarrativeConditionsEditor extends StatelessWidget {
  const NarrativeConditionsEditor({
    super.key,
    required this.controller,
    required this.conditions,
    required this.onChanged,
  });
  final NarrativeWorkspaceController controller;
  final List<NarrativeEventCondition> conditions;
  final ValueChanged<List<NarrativeEventCondition>> onChanged;
  @override
  Widget build(BuildContext context) {
    final facts = narrativeConditionFacts(controller.facts);
    final added = addedNarrativeCondition(conditions, controller.facts);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Toutes ces conditions doivent être remplies.'),
        for (final indexed in conditions.indexed)
          Builder(
            builder: (context) {
              final target = narrativeConditionTarget(indexed.$2);
              final id = target.factId;
              final expected = target.expected;
              final toggled = toggledNarrativeCondition(conditions, indexed.$1);
              void update(String fact, bool value) => onChanged(
                withNarrativeCondition(conditions, indexed.$1, fact, value),
              );

              return Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: facts.any((f) => f.id == id) ? id : null,
                      items: [
                        for (final f in facts)
                          DropdownMenuItem(
                            value: f.id,
                            child: Text(
                              f.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) {
                        if (v != null) update(v, expected);
                      },
                    ),
                  ),
                  TextButton(
                    onPressed: toggled == null
                        ? null
                        : () => onChanged(toggled),
                    child: Text(expected ? 'est activé' : 'est désactivé'),
                  ),
                  IconButton(
                    tooltip: 'Retirer la condition',
                    onPressed: () =>
                        onChanged(withoutNarrativeItem(conditions, indexed.$1)),
                    icon: const Icon(Icons.close),
                  ),
                ],
              );
            },
          ),
        Wrap(
          spacing: 8,
          children: [
            StudioButton(
              label: 'Ajouter une condition',
              secondary: true,
              onPressed: added == null ? null : () => onChanged(added),
            ),
            StudioButton(
              label: 'Créer un état',
              secondary: true,
              onPressed: () async {
                final name = await askNarrativeName(context, 'Nom de l’état');
                if (name != null) controller.addFact(name);
              },
            ),
          ],
        ),
      ],
    );
  }
}
