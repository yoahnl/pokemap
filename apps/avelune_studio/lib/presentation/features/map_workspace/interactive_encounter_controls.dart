import 'package:flutter/material.dart';

import '../../../features/map_workspace/application/map_interactive_encounter_draft.dart';

import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/inputs/studio_choice.dart';

class InteractiveEncounterControls extends StatelessWidget {
  const InteractiveEncounterControls({
    super.key,
    required this.entity,
    required this.project,
    required this.onChanged,
  });
  final MapEntity entity;
  final ProjectManifest project;
  final ValueChanged<MapEntityInteractiveEncounterData?> onChanged;

  @override
  Widget build(BuildContext context) {
    final draft = MapInteractiveEncounterDraft(entity, project);
    final payload = draft.payload;
    final trigger = draft.trigger;
    final tables = draft.tables;
    void change({
      String? tableId,
      InteractiveEncounterReusePolicy? reuse,
      List<ScriptCondition>? conditions,
    }) => onChanged(
      draft.change(tableId: tableId, reuse: reuse, conditions: conditions),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioChoice(
          key: const ValueKey('interactive-encounter-enable'),
          label: trigger == InteractiveEncounterTrigger.headbutt
              ? 'Rencontre avec Coud’Boule'
              : 'Rencontre après Éclate-Roc',
          subtitle: tables.isEmpty
              ? 'Créez une table de rencontres ${trigger == InteractiveEncounterTrigger.headbutt ? 'Coud’Boule' : 'spéciale'} pour activer cette interaction.'
              : trigger == InteractiveEncounterTrigger.headbutt
              ? 'Requiert un Pokémon non K.O. connaissant Coud’Boule. Utilisation à pied.'
              : 'La rencontre est tentée après avoir brisé le rocher.',
          selected: payload != null,
          onTap: payload != null
              ? () => onChanged(null)
              : tables.isEmpty
              ? null
              : () => change(),
        ),
        if (payload != null) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey(
              'interactive-encounter-table-${entity.id}-${payload.encounterTableId}',
            ),
            initialValue:
                tables.any((table) => table.id == payload.encounterTableId)
                ? payload.encounterTableId
                : null,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Table de rencontres'),
            items: [
              for (final table in tables)
                DropdownMenuItem(
                  value: table.id,
                  child: Text(table.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (id) {
              if (id != null) change(tableId: id);
            },
          ),
          const SizedBox(height: 8),
          StudioChoice(
            key: const ValueKey('interactive-encounter-once'),
            label: 'Une rencontre par apparition de cet objet',
            subtitle: 'La rencontre est consommée quand le combat est prêt. Réinitialisation avec la carte.',
            selected:
                payload.reusePolicy ==
                InteractiveEncounterReusePolicy.oncePerMapInstance,
            onTap: () => change(
              reuse:
                  payload.reusePolicy ==
                      InteractiveEncounterReusePolicy.oncePerMapInstance
                  ? InteractiveEncounterReusePolicy.repeatable
                  : InteractiveEncounterReusePolicy.oncePerMapInstance,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Conditions supplémentaires'),
          for (final fact in project.facts.where(
            (fact) => fact.valueKind == NarrativeValueKind.boolean,
          ))
            Builder(
              builder: (context) {
                final condition = ScriptConditionFactory.factEquals(
                  fact.id,
                  const NarrativeValue.boolean(true),
                );
                final selected = payload.conditions.contains(condition);
                return StudioChoice(
                  key: ValueKey('interactive-encounter-fact-${fact.id}'),
                  label: fact.label,
                  subtitle: 'Doit être activé.',
                  selected: selected,
                  onTap: () => change(
                    conditions: selected
                        ? payload.conditions
                              .where((entry) => entry != condition)
                              .toList()
                        : [...payload.conditions, condition],
                  ),
                );
              },
            ),
          for (final badge in project.badges)
            Builder(
              builder: (context) {
                final condition = ScriptConditionFactory.badgeOwned(badge.id);
                final selected = payload.conditions.contains(condition);
                return StudioChoice(
                  key: ValueKey('interactive-encounter-badge-${badge.id}'),
                  label: badge.label,
                  subtitle: 'Badge requis.',
                  selected: selected,
                  onTap: () => change(
                    conditions: selected
                        ? payload.conditions
                              .where((entry) => entry != condition)
                              .toList()
                        : [...payload.conditions, condition],
                  ),
                );
              },
            ),
          if (project.facts.isEmpty && project.badges.isEmpty)
            const Text('Aucun fait ni badge du projet à sélectionner.'),
        ],
      ],
    );
  }
}
