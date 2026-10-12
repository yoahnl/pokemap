import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'native_project_writer.dart';

final class SourceEventArrivalValidator {
  const SourceEventArrivalValidator();

  void validate({
    required ProjectManifest manifest,
    required List<MapData> maps,
    required Iterable<String> arrivalAnchorIds,
    ScanCancellation? cancellation,
  }) {
    cancellation?.check();
    final anchorSet = arrivalAnchorIds.toSet();
    final anchors = anchorSet.toList()..sort();
    if (anchors.isEmpty) return;
    if (maps.map((map) => map.id).toSet().length != maps.length) {
      throw const NativeWriteException('events.arrival.binding',
          'Arrival validation requires unique final native maps');
    }
    final locations = <String, List<(MapData, MapWarp)>>{};
    for (final map in maps) {
      cancellation?.check();
      for (final warp in map.warps) {
        if (anchorSet.contains(warp.id)) {
          locations.putIfAbsent(warp.id, () => []).add((map, warp));
        }
      }
    }
    final worlds = <String, GameplayWorldState>{};
    for (final id in anchors) {
      cancellation?.check();
      final matches = locations[id];
      if (matches == null || matches.length != 1) {
        throw NativeWriteException('events.arrival.binding',
            'Arrival anchor $id must resolve exactly once in the final maps');
      }
      final (map, warp) = matches.single;
      final pos = warp.pos;
      if (pos.x < 0 ||
          pos.y < 0 ||
          pos.x >= map.size.width ||
          pos.y >= map.size.height) {
        throw NativeWriteException('events.arrival.bounds',
            'Arrival anchor $id lies outside its final native map');
      }
      final world = worlds.putIfAbsent(
          map.id,
          () => GameplayWorldState.initial(
              map: map,
              playerPos: pos,
              project: manifest,
              tileWidth: manifest.settings.tileWidth,
              tileHeight: manifest.settings.tileHeight));
      final player = GameplayPlayerState.fromGridSpawn(
          cell: pos,
          facing: Direction.south,
          tileWidthPx: manifest.settings.tileWidth,
          tileHeightPx: manifest.settings.tileHeight,
          mapWidthCells: map.size.width,
          mapHeightCells: map.size.height);
      if (world
          .withPlayer(player)
          .worldStaticObstaclesCollidePlayerCollisionRect()) {
        throw NativeWriteException('events.arrival.blocked',
            'Arrival anchor $id overlaps a native static collision or a potentially present blocking entity');
      }
    }
  }
}
