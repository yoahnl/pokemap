import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';

enum ItemCapabilityRequirement {
  any,
  overworld,
  battle,
  capture,
  machine,
  held,
}

class ItemCapabilityPicker extends StatelessWidget {
  const ItemCapabilityPicker({
    super.key,
    required this.fieldKey,
    required this.label,
    required this.definitions,
    required this.requirement,
    required this.value,
    required this.onChanged,
    this.readinessByItemId = const <String, bool>{},
    this.allowEmpty = false,
    this.enabled = true,
    this.emptyLabel = 'Aucun objet',
  });

  final Key fieldKey;
  final String label;
  final List<ProjectItemDefinition> definitions;
  final Map<String, bool> readinessByItemId;
  final ItemCapabilityRequirement requirement;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool allowEmpty;
  final bool enabled;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final normalizedValue = value?.trim() ?? '';
    final compatible =
        definitions
            .where(
              (definition) =>
                  readinessByItemId[definition.id] != false &&
                  _supports(definition, requirement),
            )
            .toList(growable: false)
          ..sort(
            (left, right) => left.displayName.toLowerCase().compareTo(
              right.displayName.toLowerCase(),
            ),
          );
    final selectedDefinition = definitions
        .where((definition) => definition.id == normalizedValue)
        .firstOrNull;
    final hasCompatibleSelection = compatible.any(
      (definition) => definition.id == normalizedValue,
    );
    final items = <PokeMapDropdownItem<String>>[
      if (allowEmpty) PokeMapDropdownItem<String>(value: '', label: emptyLabel),
      for (final definition in compatible)
        PokeMapDropdownItem<String>(
          value: definition.id,
          label: definition.displayName,
        ),
      if (normalizedValue.isNotEmpty && !hasCompatibleSelection)
        PokeMapDropdownItem<String>(
          value: normalizedValue,
          label: selectedDefinition == null
              ? 'Référence indisponible'
              : '${selectedDefinition.displayName} · incompatible',
        ),
    ];
    if (items.isEmpty) {
      items.add(
        const PokeMapDropdownItem<String>(
          value: '',
          label: 'Aucun objet compatible',
        ),
      );
    }
    final selectedValue = items.any((item) => item.value == normalizedValue)
        ? normalizedValue
        : items.first.value;

    return PokeMapDropdownField<String>(
      key: fieldKey,
      label: label,
      value: selectedValue,
      items: items,
      enabled: enabled && (compatible.isNotEmpty || normalizedValue.isNotEmpty),
      onChanged: (next) => onChanged(next.isEmpty ? null : next),
    );
  }
}

bool _supports(
  ProjectItemDefinition definition,
  ItemCapabilityRequirement requirement,
) {
  return switch (requirement) {
    ItemCapabilityRequirement.any => true,
    ItemCapabilityRequirement.overworld => definition.uses.any(
      (use) => use.contexts.contains(ProjectItemUseContext.overworld),
    ),
    ItemCapabilityRequirement.battle => definition.uses.any(
      (use) => use.contexts.contains(ProjectItemUseContext.battle),
    ),
    ItemCapabilityRequirement.capture => definition.capture != null,
    ItemCapabilityRequirement.machine => definition.machine != null,
    ItemCapabilityRequirement.held => definition.heldEffectId != null,
  };
}
