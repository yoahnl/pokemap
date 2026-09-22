import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/gameplay_zone_editing_commands.dart';

String zoneKindLabel(GameplayZoneKind kind) => switch (kind) {
  GameplayZoneKind.encounter => 'Rencontres',
  GameplayZoneKind.movement => 'Déplacement requis',
  GameplayZoneKind.movementEffect => 'Effet de surface',
  GameplayZoneKind.hazard => 'Danger',
  GameplayZoneKind.special => 'Spéciale',
  GameplayZoneKind.custom => 'Héritée',
};

List<Widget> zonePayloadFields({
  required BuildContext context,
  required MapGameplayZone zone,
  required GameplayZoneEditingCommands commands,
  required void Function(VoidCallback) onChanged,
}) {
  final encounter = zone.encounter;
  if (encounter != null) {
    final tables = commands.encounterTables();
    final known = tables.any((t) => t.id == encounter.encounterTableId);
    return [
      DropdownButtonFormField<String>(
        key: ValueKey('zone-table-${zone.id}'),
        initialValue: known ? encounter.encounterTableId : null,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Table de rencontres'),
        items: [
          for (final table in tables)
            DropdownMenuItem(
              value: table.id,
              child: Text(
                table.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: (id) => id == null
            ? null
            : onChanged(() => commands.updateEncounter(zone.id, tableId: id)),
      ),
      if (tables.isEmpty) ...[
        const SizedBox(height: 6),
        Text(
          'Le projet ne contient aucune table de rencontres.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ];
  }

  final movement = zone.movement;
  if (movement != null) {
    return [
      DropdownButtonFormField<MovementMode>(
        key: ValueKey('zone-mode-${zone.id}-${movement.requiredMode.name}'),
        initialValue: movement.requiredMode,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Déplacement requis'),
        items: [
          for (final mode in MovementMode.values)
            DropdownMenuItem(
              value: mode,
              child: Text(
                movementModeLabel(mode),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: (mode) => mode == null
            ? null
            : onChanged(
                () => commands.updateMovement(zone.id, requiredMode: mode),
              ),
      ),
    ];
  }

  final effect = zone.movementEffect;
  if (effect != null) {
    return [
      DropdownButtonFormField<MovementEffectZoneKind>(
        key: ValueKey('zone-effect-${zone.id}-${effect.effectKind.name}'),
        initialValue: effect.effectKind,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Effet'),
        items: [
          for (final kind in MovementEffectZoneKind.values)
            DropdownMenuItem(
              value: kind,
              child: Text(
                kind.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: (kind) => kind == null
            ? null
            : onChanged(
                () => commands.updateMovementEffect(zone.id, effectKind: kind),
              ),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<int>(
        key: ValueKey('zone-cost-${zone.id}-${effect.movementCost}'),
        initialValue: effect.movementCost.clamp(1, 4),
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Coût par pas'),
        items: const [
          DropdownMenuItem(value: 1, child: Text('1 (normal)')),
          DropdownMenuItem(value: 2, child: Text('2')),
          DropdownMenuItem(value: 3, child: Text('3')),
          DropdownMenuItem(value: 4, child: Text('4')),
        ],
        onChanged: (cost) => cost == null
            ? null
            : onChanged(
                () =>
                    commands.updateMovementEffect(zone.id, movementCost: cost),
              ),
      ),
    ];
  }

  final hazard = zone.hazard;
  if (hazard != null) {
    return [
      DropdownButtonFormField<HazardKind>(
        key: ValueKey('zone-hazard-${zone.id}-${hazard.hazardKind.name}'),
        initialValue: hazard.hazardKind,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Danger'),
        items: [
          for (final kind in HazardKind.values)
            DropdownMenuItem(
              value: kind,
              child: Text(
                kind.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: (kind) => kind == null
            ? null
            : onChanged(() => commands.updateHazard(zone.id, hazardKind: kind)),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<int>(
        key: ValueKey('zone-damage-${zone.id}-${hazard.damagePerStep}'),
        initialValue: hazard.damagePerStep.clamp(0, 3),
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Dégâts par pas'),
        items: const [
          DropdownMenuItem(value: 0, child: Text('Aucun')),
          DropdownMenuItem(value: 1, child: Text('1')),
          DropdownMenuItem(value: 2, child: Text('2')),
          DropdownMenuItem(value: 3, child: Text('3')),
        ],
        onChanged: (damage) => damage == null
            ? null
            : onChanged(
                () => commands.updateHazard(zone.id, damagePerStep: damage),
              ),
      ),
    ];
  }

  return [
    Text(
      'Les propriétés libres d’une zone spéciale ne sont pas éditables ici.',
      style: Theme.of(context).textTheme.bodySmall,
    ),
  ];
}

String movementModeLabel(MovementMode mode) => switch (mode) {
  MovementMode.walk => 'À pied',
  MovementMode.surf => 'En surf',
  MovementMode.fly => 'En vol',
  MovementMode.cut => 'Après avoir coupé',
  MovementMode.strength => 'Avec la force',
  MovementMode.rockSmash => 'Après avoir brisé',
};
