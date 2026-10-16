import '../exceptions/map_exceptions.dart';
import '../models/enums.dart';
import '../models/map_data.dart';
import 'map_gameplay_zones.dart';

bool isDiveZone(MapGameplayZone zone) =>
    zone.kind == GameplayZoneKind.fieldAction &&
    zone.fieldAction?.actionKind == FieldActionZoneKind.dive;

void validateDiveZonePair({
  required MapData sourceMap,
  required String sourceZoneId,
  required MapData targetMap,
  required String targetZoneId,
}) {
  MapGameplayZone endpoint(MapData map, String id) {
    final zones = map.gameplayZones.where((zone) => zone.id == id).toList();
    if (zones.length != 1 || !isDiveZone(zones.single)) {
      throw const ValidationException('Dive endpoint is missing or ambiguous.');
    }
    validateFieldActionZone(map, zones.single);
    if (findAllGameplayZonesAtPos(
          map,
          zones.single.area.pos,
        ).where(isDiveZone).length !=
        1) {
      throw const ValidationException(
        'Plusieurs points de Plongée occupent la même case : gardez un seul point par case avant de lier, lancer le playtest ou exporter.',
      );
    }
    return zones.single;
  }

  final source = endpoint(sourceMap, sourceZoneId);
  final target = endpoint(targetMap, targetZoneId);
  final a = source.fieldAction!.dive!;
  final b = target.fieldAction!.dive!;
  if (sourceMap.id == targetMap.id ||
      a.role == b.role ||
      a.link?.mapId != targetMap.id ||
      a.link?.zoneId != target.id ||
      b.link?.mapId != sourceMap.id ||
      b.link?.zoneId != source.id) {
    throw const ValidationException(
      'Dive requires an exact reciprocal pair on distinct maps with opposite roles.',
    );
  }
}

List<({String mapId, String zoneId, String message})> diveZonePairDiagnostics(
  Iterable<MapData> maps,
) {
  final all = maps.toList();
  final problems = <({String mapId, String zoneId, String message})>[];
  for (final map in all) {
    for (final zone in map.gameplayZones.where(isDiveZone)) {
      try {
        final link = zone.fieldAction?.dive?.link;
        final targets = all
            .where((candidate) => candidate.id == link?.mapId)
            .toList();
        if (link == null || targets.length != 1) {
          throw const ValidationException(
            'Point de Plongée en préparation : liez deux points avant le playtest ou l’export.',
          );
        }
        validateDiveZonePair(
          sourceMap: map,
          sourceZoneId: zone.id,
          targetMap: targets.single,
          targetZoneId: link.zoneId,
        );
      } on Object catch (error) {
        problems.add((mapId: map.id, zoneId: zone.id, message: '$error'));
      }
    }
  }
  return List.unmodifiable(problems);
}
