import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../shared/widgets/buttons/studio_button.dart';
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
    final facts = controller.facts
        .where((f) => f.valueKind == NarrativeValueKind.boolean)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Toutes ces conditions doivent être remplies.'),
        for (final indexed in conditions.indexed)
          Builder(
            builder: (context) {
              final data = indexed.$2.toJson();
              final id = data['factId'] as String?;
              final expected = data['expectedValue'] == true;
              void update(String fact, bool value) {
                final next = [...conditions];
                next[indexed.$1] = NarrativeEventCondition.fact(fact, value);
                onChanged(next);
              }

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
                    onPressed: id == null ? null : () => update(id, !expected),
                    child: Text(expected ? 'est activé' : 'est désactivé'),
                  ),
                  IconButton(
                    tooltip: 'Retirer la condition',
                    onPressed: () =>
                        onChanged([...conditions]..removeAt(indexed.$1)),
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
              onPressed: facts.isEmpty
                  ? null
                  : () => onChanged([
                      ...conditions,
                      NarrativeEventCondition.fact(facts.first.id, true),
                    ]),
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
