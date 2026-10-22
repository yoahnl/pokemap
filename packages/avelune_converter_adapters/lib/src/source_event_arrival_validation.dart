import 'dart:math' as math;

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'native_project_writer.dart';
import 'source_connection_study_composer.dart';

final class SourceEventArrivalValidator {
  const SourceEventArrivalValidator();

  void validateConnections({
    required ProjectManifest manifest,
    required List<MapData> maps,
    required NormalizedSourceProject source,
    required Iterable<NativeMutation> connectionMutations,
    ScanCancellation? cancellation,
  }) {
    cancellation?.check();
    final mutations = connectionMutations.toList();
    if (mutations.isEmpty) return;
    final nativeMaps = <int, MapData>{};
    final byId = {for (final map in maps) map.id: map};
    if (byId.length != maps.length) {
      throw const NativeWriteException('connections.arrival_binding',
          'Connection arrival maps must have unique native identities');
    }
    final sourceRows = <NativeMutation, NormalizedMapConnection>{};
    for (final mutation in mutations) {
      cancellation?.check();
      final rows = source.connections
          .where((row) => mutation.sourceEntityIds.contains(row.identity))
          .toList();
      if (mutation.actionId != 'connection.create_bidirectional_apply' ||
          rows.length != 1) {
        throw const NativeWriteException('connections.arrival_binding',
            'Connection arrival admission requires one exact compiled source row');
      }
      final row = rows.single;
      sourceRows[mutation] = row;
      for (final binding in [
        (row.sourceMapId, mutation.parameters['mapId']),
        (row.targetSourceMapId, mutation.parameters['targetMapId'])
      ]) {
        final map = byId[binding.$2];
        final original = source.maps
            .where((value) => value.map.sourceMapId == binding.$1)
            .firstOrNull;
        if (map == null ||
            original == null ||
            map.size.width != original.map.width ||
            map.size.height != original.map.height ||
            !mutation.sourceEntityIds
                .contains(source.mapIdentity(binding.$1)) ||
            (nativeMaps[binding.$1] != null &&
                nativeMaps[binding.$1]!.id != map.id)) {
          throw const NativeWriteException('connections.arrival_binding',
              'Connection arrival maps require consistent source identities and geometry');
        }
        nativeMaps[binding.$1] = map;
      }
    }
    final worlds = <String, GameplayWorldState>{};
    for (final mutation in mutations) {
      cancellation?.check();
      final row = sourceRows[mutation]!;
      final from = nativeMaps[row.sourceMapId],
          to = nativeMaps[row.targetSourceMapId];
      final direction = MapConnectionDirection.values
          .singleWhere((value) => value.name == row.sourceDirection.name);
      if (from == null ||
          to == null ||
          mutation.parameters['mapId'] != from.id ||
          mutation.parameters['targetMapId'] != to.id ||
          mutation.parameters['offset'] != row.nativeOffset ||
          mutation.parameters['direction'] != direction.name ||
          findMapConnection(from, direction, targetMapId: to.id)?.offset !=
              row.nativeOffset ||
          findMapConnection(to, direction.opposite, targetMapId: from.id)
                  ?.offset !=
              -row.nativeOffset ||
          sourceConnectionHasBorderEvents(
              source: source,
              connection: row,
              nativeMaps: nativeMaps,
              cancellation: cancellation)) {
        throw const NativeWriteException('connections.arrival_binding',
            'Connection admission requires exact reciprocal geometry without unqualified source border events');
      }
      final arrivals = sourceConnectionArrivals(
          source: source,
          connection: row,
          nativeMaps: nativeMaps,
          cancellation: cancellation);
      for (final arrival in arrivals) {
        cancellation?.check();
        if (arrival.passage.isPassable == null) {
          throw const NativeWriteException('connections.arrival_unqualified',
              'Every connection destination requires a qualified source d0 passage');
        }
        final map = nativeMaps[arrival.targetSourceMapId]!;
        final pos = arrival.targetPosition;
        final world = worlds.putIfAbsent(
            map.id,
            () => GameplayWorldState.initial(
                map: _arrivalValidationMap(map, manifest),
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
        final targetWorld = world.withPlayer(player);
        final allowed =
            !targetWorld.worldStaticObstaclesCollidePlayerCollisionRect() &&
                !(targetWorld.isWaterCell(pos.x, pos.y) &&
                    targetWorld.player.movementMode != MovementMode.surf);
        if (allowed != arrival.passage.isPassable) {
          throw NativeWriteException('connections.arrival_mismatch',
              'Source d0 ${arrival.passage.status.name} differs from native initial walk rectangle/water admission at map ${arrival.targetSourceMapId} (${pos.x},${pos.y})');
        }
      }
    }
  }

  void validate({
    required ProjectManifest manifest,
    required List<MapData> maps,
    required Iterable<String> arrivalAnchorIds,
    Map<String, String> arrivalCollisionOwners = const {},
    ScanCancellation? cancellation,
  }) {
    cancellation?.check();
    final anchorSet = arrivalAnchorIds.toSet();
    final anchors = anchorSet.toList()..sort();
    if (!anchorSet.containsAll(arrivalCollisionOwners.keys)) {
      throw const NativeWriteException('events.arrival.binding',
          'Every collision owner requires its exact arrival marker');
    }
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
    final worlds = <(String, String?), GameplayWorldState>{};
    for (final id in anchors) {
      cancellation?.check();
      final matches = locations[id];
      if (matches == null || matches.length != 1) {
        throw NativeWriteException('events.arrival.binding',
            'Arrival anchor $id must resolve exactly once in the final maps');
      }
      final (map, warp) = matches.single;
      if (warp.triggerMode != MapWarpTriggerMode.sceneOnly ||
          warp.targetMapId != map.id ||
          warp.targetPos != warp.pos) {
        throw const NativeWriteException('events.arrival.binding',
            'A Scene destination must be one inert local arrival marker');
      }
      final pos = warp.pos;
      if (pos.x < 0 ||
          pos.y < 0 ||
          pos.x >= map.size.width ||
          pos.y >= map.size.height) {
        throw NativeWriteException('events.arrival.bounds',
            'Arrival anchor $id lies outside its final native map');
      }
      final world = worlds.putIfAbsent(
          (map.id, arrivalCollisionOwners[id]),
          () => GameplayWorldState.initial(
              map: _arrivalValidationMap(map, manifest,
                  collisionOwnerId: arrivalCollisionOwners[id]),
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
      final bool allowed;
      try {
        allowed = isSceneWarpArrivalAllowed(
            world: world.withPlayer(player),
            project: manifest,
            arrivalCollisionOwnerEntityId: arrivalCollisionOwners[id]);
      } on StateError catch (error) {
        throw NativeWriteException('events.arrival.binding',
            'Arrival map=${map.id} warp=$id position=(${pos.x},${pos.y}) owner=${arrivalCollisionOwners[id] ?? '<none>'}: ${error.message}');
      }
      if (!allowed) {
        throw NativeWriteException('events.arrival.blocked',
            'Arrival anchor $id overlaps a native static collision or a potentially present blocking entity');
      }
    }
  }
}

MapData _arrivalValidationMap(MapData map, ProjectManifest manifest,
    {String? collisionOwnerId}) => map.copyWith(entities: [
      for (final entity in map.entities)
        entity.presentation == null ? entity : _arrivalValidationEntity(entity, manifest,
            collisionOwner: entity.id == collisionOwnerId),
    ]);

MapEntity _arrivalValidationEntity(MapEntity entity, ProjectManifest manifest,
    {required bool collisionOwner}) {
  final footprints = [
    if (entity.blocksMovement) resolveEntityCollisionFootprint(entity),
    for (final variant in entity.presentation!.variants)
      if (variant.blocksMovement) MapRect(pos: entity.pos, size: variant.size),
  ];
  var authored = entity.copyWith(presentation: null);
  if (collisionOwner && authored.npc == null &&
      isSceneActorEntityReferenceAvailable(manifest, entity)) {
    authored = authored.copyWith(kind: MapEntityKind.npc,
        npc: MapEntityNpcData(characterId: entity.presentation!.variants
            .map((variant) => variant.characterId).whereType<String>().first));
  }
  if (footprints.isEmpty) return authored;
  final left = footprints.map((rect) => rect.pos.x).reduce(math.min);
  final top = footprints.map((rect) => rect.pos.y).reduce(math.min);
  final right =
      footprints.map((rect) => rect.pos.x + rect.size.width).reduce(math.max);
  final bottom =
      footprints.map((rect) => rect.pos.y + rect.size.height).reduce(math.max);
  return authored.copyWith(
      blocksMovement: true,
      size: GridSize(
          width: math.max(entity.size.width, right - entity.pos.x),
          height: math.max(entity.size.height, bottom - entity.pos.y)),
      properties: {
        ...entity.properties,
        mapEntityCollisionWidthProperty: '${right - left}',
        mapEntityCollisionHeightProperty: '${bottom - top}',
        mapEntityCollisionOffsetXProperty: '${left - entity.pos.x}',
        mapEntityCollisionOffsetYProperty: '${top - entity.pos.y}',
      });
}
