import '../exceptions/map_exceptions.dart';
import '../models/map_data.dart';
import '../models/smart_tile_gameplay_zone_provenance.dart';
import 'map_gameplay_zones.dart';

final class SmartTileGameplayZoneSynchronizationResult {
  SmartTileGameplayZoneSynchronizationResult({
    required this.map,
    required Iterable<MapGameplayZone> removedZones,
    required Iterable<MapGameplayZone> generatedZones,
  }) : removedZones = List<MapGameplayZone>.unmodifiable(removedZones),
       generatedZones = List<MapGameplayZone>.unmodifiable(generatedZones);

  final MapData map;
  final List<MapGameplayZone> removedZones;
  final List<MapGameplayZone> generatedZones;

  bool get changed => removedZones.isNotEmpty || generatedZones.isNotEmpty;
}

SmartTileGameplayZoneSynchronizationResult synchronizeSmartTileGameplayZones(
  MapData map, {
  required List<MapGameplayZone> generatedZones,
}) {
  if (generatedZones.isEmpty) {
    throw const ValidationException(
      'Smart Tile gameplay-zone synchronization requires generated zones',
    );
  }
  final binding = generatedZones.first.smartTileProvenance;
  if (binding == null ||
      generatedZones.any(
        (zone) =>
            zone.smartTileProvenance == null ||
            binding != zone.smartTileProvenance,
      )) {
    throw const ValidationException(
      'Generated gameplay zones must share one Smart Tile binding',
    );
  }

  final removed = map.gameplayZones
      .where((zone) => _hasBinding(zone, binding))
      .toList(growable: false);
  var updated = map.copyWith(
    gameplayZones: map.gameplayZones
        .where((zone) => !_hasBinding(zone, binding))
        .toList(growable: false),
  );
  for (final zone in generatedZones) {
    updated = addGameplayZoneToMap(updated, zone: zone);
  }

  final firstRemovedIndex = map.gameplayZones.indexWhere(
    (zone) => _hasBinding(zone, binding),
  );
  if (firstRemovedIndex >= 0) {
    final reordered = List<MapGameplayZone>.from(updated.gameplayZones);
    reordered.removeWhere((zone) => _hasBinding(zone, binding));
    reordered.insertAll(firstRemovedIndex, generatedZones);
    updated = updated.copyWith(gameplayZones: reordered);
  }

  return SmartTileGameplayZoneSynchronizationResult(
    map: updated,
    removedZones: removed,
    generatedZones: generatedZones,
  );
}

List<MapGameplayZone> smartTileGameplayZonesForBinding(
  Iterable<MapGameplayZone> zones,
  SmartTileGameplayZoneProvenance binding,
) {
  return List<MapGameplayZone>.unmodifiable(
    zones.where((zone) => _hasBinding(zone, binding)),
  );
}

bool _hasBinding(
  MapGameplayZone zone,
  SmartTileGameplayZoneProvenance binding,
) {
  return zone.smartTileProvenance?.hasSameBinding(binding) ?? false;
}
