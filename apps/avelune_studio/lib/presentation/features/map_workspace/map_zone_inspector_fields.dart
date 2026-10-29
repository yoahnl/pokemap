import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/gameplay_zone_editing_commands.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import 'map_dive_zone_panel.dart';

String zoneKindLabel(GameplayZoneKind kind, {bool spatial = false}) =>
    switch (kind) {
      GameplayZoneKind.encounter => 'Rencontres',
      GameplayZoneKind.movement => 'Déplacement requis',
      GameplayZoneKind.movementEffect => 'Effet de surface',
      GameplayZoneKind.fieldAction =>
        spatial ? 'Action de terrain' : 'Action de terrain (2D)',
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
  final fieldAction = zone.fieldAction;
  final actionSelector = fieldAction == null
      ? null
      : StudioSelect(
          key: ValueKey(
            'zone-field-action-${zone.id}-${fieldAction.actionKind.name}',
          ),
          label: 'Action de terrain',
          value: fieldAction.actionKind.name,
          options: {
            if (commands.supportsDarkness)
              'darkness': 'Zone sombre (Flash · 2D)',
            if (commands.supportsDarkness &&
                zone.area.size == const GridSize(width: 1, height: 1))
              'dive': 'Plongée · 2D',
            if (commands.fieldTraversalDirections(zone).isNotEmpty) ...{
              'waterfall':
                  'Cascade · ${commands.supportsDarkness ? '2D' : '3D'}',
              'whirlpool':
                  'Tourbillon · ${commands.supportsDarkness ? '2D' : '3D'}',
            },
          },
          onChanged: (kind) => onChanged(
            () => kind == 'dive'
                ? commands.configureDive(zone.id)
                : kind == 'waterfall'
                ? commands.configureWaterfall(zone.id)
                : kind == 'whirlpool'
                ? commands.configureWhirlpool(zone.id)
                : commands.configureDarkness(zone.id),
          ),
        );
  if (fieldAction?.dive != null) {
    return [
      actionSelector!,
      const SizedBox(height: 8),
      MapDiveZonePanel(
        key: ValueKey('dive-${commands.document.current.id}-${zone.id}'),
        zone: zone,
        commands: commands,
        onChanged: onChanged,
      ),
    ];
  }
  final waterfall = fieldAction?.waterfall;
  final whirlpool = fieldAction?.whirlpool;
  if (waterfall != null || whirlpool != null) {
    final direction = waterfall?.direction ?? whirlpool!.direction;
    final entry = waterfall?.entry ?? whirlpool!.entry;
    final exit = waterfall?.exit ?? whirlpool!.exit;
    final path = waterfall?.path ?? whirlpool!.path;
    final actionName = whirlpool != null ? 'Tourbillon' : 'Cascade';
    final vertical =
        direction == MapConnectionDirection.north ||
        direction == MapConnectionDirection.south;
    final forward =
        direction == MapConnectionDirection.south ||
        direction == MapConnectionDirection.east;
    final start = vertical ? entry.y : entry.x;
    final end = vertical ? exit.y : exit.x;
    final length = vertical ? zone.area.size.height : zone.area.size.width;
    void configure({
      MapConnectionDirection? direction,
      int? line,
      int? entryIndex,
      int? exitIndex,
    }) {
      if (whirlpool != null) {
        commands.configureWhirlpool(
          zone.id,
          direction: direction,
          line: line,
          entryIndex: entryIndex,
          exitIndex: exitIndex,
        );
      } else {
        commands.configureWaterfall(
          zone.id,
          direction: direction,
          line: line,
          entryIndex: entryIndex,
          exitIndex: exitIndex,
        );
      }
    }

    String directionName(MapConnectionDirection value) => switch (value) {
      MapConnectionDirection.north => 'Vers le haut',
      MapConnectionDirection.south => 'Vers le bas',
      MapConnectionDirection.east => 'Vers la droite',
      MapConnectionDirection.west => 'Vers la gauche',
    };
    Widget select(
      String label,
      String value,
      Map<String, String> options,
      void Function(String) changed,
    ) => StudioSelect(
      key: ValueKey('${fieldAction!.actionKind.name}-${zone.id}-$label-$value'),
      label: label,
      value: value,
      options: options,
      onChanged: (next) => onChanged(() => changed(next)),
    );
    return [
      actionSelector!,
      const SizedBox(height: 8),
      select(
        'Sens de traversée',
        direction.name,
        {
          for (final d in commands.fieldTraversalDirections(zone))
            d.name: directionName(d),
        },
        (next) =>
            configure(direction: MapConnectionDirection.values.byName(next)),
      ),
      const SizedBox(height: 8),
      select(
        vertical ? 'Colonne du passage' : 'Ligne du passage',
        '${vertical ? entry.x : entry.y}',
        {
          for (
            var i = 0;
            i < (vertical ? zone.area.size.width : zone.area.size.height);
            i++
          )
            '$i': '${i + 1}',
        },
        (next) => configure(line: int.parse(next)),
      ),
      const SizedBox(height: 8),
      select('Entrée (case du rectangle)', '$start', {
        for (var i = 0; i < length; i++)
          if ((end - i) * (forward ? 1 : -1) >= 2 && (end - i).abs() <= 257)
            '$i': '${i + 1}',
      }, (next) => configure(entryIndex: int.parse(next))),
      const SizedBox(height: 8),
      select('Sortie (case du rectangle)', '$end', {
        for (var i = 0; i < length; i++)
          if ((i - start) * (forward ? 1 : -1) >= 2 && (i - start).abs() <= 257)
            '$i': '${i + 1}',
      }, (next) => configure(exitIndex: int.parse(next))),
      const SizedBox(height: 8),
      if (waterfall != null)
        select(
          'Surf requis',
          '${waterfall.requiresSurf}',
          const {'true': 'Oui', 'false': 'Non'},
          (next) => commands.configureWaterfall(
            zone.id,
            requiresSurf: next == 'true',
          ),
        ),
      if (whirlpool != null) const StudioNotice('Surf obligatoire'),
      if (whirlpool != null) ...[
        const SizedBox(height: 8),
        StudioNotice(
          commands.project.badges.any(
                (badge) => badge.fieldAbilityUnlock == FieldAbility.whirlpool,
              )
              ? 'Déblocage Tourbillon : ${commands.project.badges.where((badge) => badge.fieldAbilityUnlock == FieldAbility.whirlpool).map((badge) => badge.label).join(', ')}. Dans Histoire, ajoutez « Donner un badge » et choisissez le badge par son nom. « Débloquer une capacité terrain » permet aussi de choisir Tourbillon directement.'
              : 'Aucun badge ne débloque Tourbillon. Dans Histoire, ajoutez « Débloquer une capacité terrain » et choisissez Tourbillon.',
        ),
      ],
      const SizedBox(height: 8),
      Text(
        'Trajet : ${path.length} cases entre l’entrée et la sortie. Placez le joueur à l’entrée dans le sens indiqué. $actionName exige un Pokémon conscient connaissant l’attaque et son déblocage. Aucun PP dépensé. ${whirlpool != null ? 'Tout le passage doit être sur l’eau. La zone reste présente et le joueur reste en Surf à l’arrivée. ' : ''}Traversée 2D à pas de 0,25 s ; sauvegarde disponible après l’arrivée.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ];
  }
  final darkness = zone.fieldAction?.darkness;
  if (darkness != null) {
    return [
      actionSelector!,
      const SizedBox(height: 8),
      StudioSelect(
        key: ValueKey('zone-darkness-${zone.id}-${darkness.opacity}'),
        label: 'Obscurité avant Flash',
        value: '${darkness.opacity}',
        options: {
          for (final opacity in <double>{
            .35,
            .5,
            .7,
            .85,
            .95,
            darkness.opacity,
          }.toList()..sort())
            '$opacity': '${(opacity * 100).round()} %',
        },
        onChanged: (opacity) => onChanged(
          () =>
              commands.updateDarkness(zone.id, opacity: double.parse(opacity)),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Flash éclaire uniquement ce rectangle. L’éclairage dure jusqu’au renouvellement de l’instance de carte et est conservé dans la sauvegarde. Aucune dépense de PP. Disponible en 2D.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ];
  }
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
                kind == MovementEffectZoneKind.slide ? 'Glissade' : kind.name,
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
      if (effect.effectKind == MovementEffectZoneKind.slide) ...[
        const SizedBox(height: 12),
        const Text(
          'En 2D, le joueur et les rochers poussés avec Force glissent dans leur direction d’entrée jusqu’à un obstacle ou la sortie de la zone. Les commandes reprennent à l’arrêt.',
        ),
      ],
      if (effect.effectKind == MovementEffectZoneKind.movementCost) ...[
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
                  () => commands.updateMovementEffect(
                    zone.id,
                    movementCost: cost,
                  ),
                ),
        ),
      ],
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
  MovementMode.dive => 'Sous l’eau (Plongée)',
  MovementMode.fly => 'En vol',
  MovementMode.cut => 'Après avoir coupé',
  MovementMode.bicycle => 'À vélo',
  MovementMode.strength => 'Avec la force',
  MovementMode.rockSmash => 'Après avoir brisé',
};
