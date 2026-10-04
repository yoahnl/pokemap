import 'package:map_core/map_core.dart';

import '../../workspace/project_snapshot.dart';

List<Map<String, Object?>> mapResizeDependencyImpacts(
    ProjectSnapshot snapshot, MapData target, GridSize size) {
  if (size == target.size) return const [];
  final impacts = <Map<String, Object?>>[];
  bool outside(num x, num y) =>
      x < 0 || y < 0 || x >= size.width || y >= size.height;
  void add(String kind, String owner, String subject,
          {String? ownerMapId, GridPos? position}) =>
      impacts.add({
        'kind': kind,
        'reason': 'externalReferenceOutside',
        'subjectId': subject,
        'subjectLabel': subject,
        'ownerId': owner,
        if (ownerMapId != null) 'ownerMapId': ownerMapId,
        'affectedCount': 1,
        'relatedIds': [target.id],
        'positions': [
          if (position != null) {'x': position.x, 'y': position.y}
        ],
      });
  for (final owner in snapshot.maps) {
    for (final warp in owner.warps) {
      if (owner.id != target.id &&
          warp.targetMapId == target.id &&
          outside(warp.targetPos.x, warp.targetPos.y)) {
        add('warp', owner.id, warp.id,
            ownerMapId: owner.id, position: warp.targetPos);
      }
    }
    for (final element in owner.placedElements) {
      for (final behavior in element.behaviors) {
        final effect = behavior.effect;
        final position = effect.targetPos;
        if (effect.type == MapPlacedElementEffectType.traverseWarp &&
            effect.targetMapId == target.id &&
            position != null &&
            outside(position.x, position.y)) {
          add('placedElementWarp', owner.id, element.id,
              ownerMapId: owner.id, position: position);
        }
      }
    }
    if (owner.id != target.id &&
        (size.width < target.size.width || size.height < target.size.height)) {
      for (final connection in owner.connections
          .where((connection) => connection.targetMapId == target.id)) {
        add('connection', owner.id, connection.direction.name,
            ownerMapId: owner.id);
      }
    }
  }
  for (final script in snapshot.manifest.scripts) {
    for (final node in script.asset.nodes) {
      for (var index = 0; index < node.commands.length; index++) {
        final command = node.commands[index];
        if (command.type != ScriptCommandType.warpPlayer ||
            command.params['mapId'] != target.id) {
          continue;
        }
        final x = int.tryParse(command.params['x'] ?? '0');
        final y = int.tryParse(command.params['y'] ?? '0');
        if (x == null || y == null || outside(x, y)) {
          add('scriptWarp', script.id, '${node.id}/$index',
              position: x == null || y == null ? null : GridPos(x: x, y: y));
        }
      }
    }
  }
  for (final journey in snapshot.manifest.railJourneyCatalog?.journeys ??
      const <RailJourneyDefinition>[]) {
    for (final endpoint in [journey.origin, journey.destination]) {
      if (endpoint.stationMapId == target.id) {
        final area = endpoint.boardingArea;
        if (outside(area.pos.x, area.pos.y) ||
            outside(area.pos.x + area.size.width - 1,
                area.pos.y + area.size.height - 1)) {
          add('railBoardingArea', journey.id, endpoint.stationMapId);
        }
        if (outside(
            endpoint.stationArrivalPos.x, endpoint.stationArrivalPos.y)) {
          add('railArrival', journey.id, endpoint.stationMapId,
              position: endpoint.stationArrivalPos);
        }
      }
      if (journey.vehicleMapId == target.id &&
          outside(endpoint.trainEntryPos.x, endpoint.trainEntryPos.y)) {
        add('railEntry', journey.id, endpoint.stationMapId,
            position: endpoint.trainEntryPos);
      }
    }
  }
  for (final cinematic in snapshot.manifest.cinematics
      .where((cinematic) => cinematic.mapId == target.id)) {
    for (final point in cinematic.stageContext?.stagePoints ??
        const <CinematicStagePoint>[]) {
      if (outside(point.x, point.y)) {
        add('cinematicPoint', cinematic.id, point.label);
      }
    }
  }
  return impacts;
}
