import 'package:map_core/map_core_domain.dart';

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

class MapFieldTraversalChoices {
  MapFieldTraversalChoices(this.zone);
  final MapGameplayZone zone;
  MapConnectionDirection get direction =>
      zone.fieldAction!.waterfall?.direction ??
      zone.fieldAction!.whirlpool!.direction;
  GridPos get entry =>
      zone.fieldAction!.waterfall?.entry ?? zone.fieldAction!.whirlpool!.entry;
  GridPos get exit =>
      zone.fieldAction!.waterfall?.exit ?? zone.fieldAction!.whirlpool!.exit;
  bool get vertical =>
      direction == MapConnectionDirection.north ||
      direction == MapConnectionDirection.south;
  bool get forward =>
      direction == MapConnectionDirection.south ||
      direction == MapConnectionDirection.east;
  int get start => vertical ? entry.y : entry.x;
  int get end => vertical ? exit.y : exit.x;
  int get length => vertical ? zone.area.size.height : zone.area.size.width;
  List<int> get entryIndices => [
    for (var i = 0; i < length; i++)
      if ((end - i) * (forward ? 1 : -1) >= 2 && (end - i).abs() <= 257) i,
  ];
  List<int> get exitIndices => [
    for (var i = 0; i < length; i++)
      if ((i - start) * (forward ? 1 : -1) >= 2 && (i - start).abs() <= 257) i,
  ];
}
