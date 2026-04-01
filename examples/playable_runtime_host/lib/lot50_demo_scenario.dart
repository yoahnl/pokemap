import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

const String lot50DemoEventId = 'lot50_demo_event';
const String lot50DemoScriptId = 'lot50_demo_script';
const String lot50DemoFlagName = 'lot50.demo.completed';
const String lot50DemoVariableName = 'lot50_demo_interactions';
const String lot50DemoConsumedEventId = 'lot50.demo.event_consumed';

class Lot50ScenarioSetup {
  const Lot50ScenarioSetup({
    required this.mapId,
    required this.eventId,
    required this.scriptId,
    required this.flagName,
    required this.variableName,
    required this.consumedEventId,
    required this.eventPos,
  });

  final String mapId;
  final String eventId;
  final String scriptId;
  final String flagName;
  final String variableName;
  final String consumedEventId;
  final GridPos eventPos;
}

class Lot50ScenarioResult {
  const Lot50ScenarioResult({
    required this.bundle,
    this.setup,
    this.warning,
  });

  final RuntimeMapBundle bundle;
  final Lot50ScenarioSetup? setup;
  final String? warning;
}

Lot50ScenarioResult injectLot50DemoScenario(RuntimeMapBundle bundle) {
  final spawnState = _resolveSpawnState(bundle.map);
  final eventPos = _findScenarioEventPos(bundle.map, spawnState);
  if (eventPos == null) {
    return Lot50ScenarioResult(
      bundle: bundle,
      warning:
          'Scénario démo non injecté: aucune case libre proche du spawn pour l’event.',
    );
  }

  final layerId = _resolveScenarioLayerId(bundle.map);
  final event = MapEventDefinition(
    id: lot50DemoEventId,
    title: 'LOT 50 Demo Event',
    position: EventPosition(layerId: layerId, x: eventPos.x, y: eventPos.y),
    pages: [
      MapEventPage(
        pageNumber: 0,
        condition: ScriptConditionFactory.not(
          ScriptConditionFactory.eventIsConsumed(lot50DemoConsumedEventId),
        ),
        script:
            const ScriptRef(scriptId: lot50DemoScriptId, startNode: 'start'),
        message: 'Le professeur te confie un colis.',
      ),
      MapEventPage(
        pageNumber: 1,
        condition:
            ScriptConditionFactory.eventIsConsumed(lot50DemoConsumedEventId),
        message: 'Tu as déjà reçu le colis. Merci.',
      ),
    ],
    type: MapEventType.object,
  );

  const script = ProjectScriptEntry(
    id: lot50DemoScriptId,
    name: 'LOT 50 Demo Script',
    asset: ScriptAsset(
      id: lot50DemoScriptId,
      defaultStartNode: 'start',
      nodes: [
        ScriptNode(
          id: 'start',
          commands: [
            ScriptCommand(
              type: ScriptCommandType.setFlag,
              params: {'flagName': lot50DemoFlagName},
            ),
            ScriptCommand(
              type: ScriptCommandType.incrementVariable,
              params: {
                'variableName': lot50DemoVariableName,
                'delta': '1',
              },
            ),
            ScriptCommand(
              type: ScriptCommandType.markEventConsumed,
              params: {'eventId': lot50DemoConsumedEventId},
            ),
            ScriptCommand(type: ScriptCommandType.end),
          ],
        ),
      ],
    ),
  );

  final nextScripts = [
    ...bundle.manifest.scripts.where((entry) => entry.id != lot50DemoScriptId),
    script,
  ];
  final nextEvents = [
    ...bundle.map.events.where((entry) => entry.id != lot50DemoEventId),
    event,
  ];

  final nextBundle = RuntimeMapBundle(
    manifest: bundle.manifest.copyWith(scripts: nextScripts),
    map: bundle.map.copyWith(events: nextEvents),
    projectRootDirectory: bundle.projectRootDirectory,
    tilesetAbsolutePathsById: bundle.tilesetAbsolutePathsById,
  );

  return Lot50ScenarioResult(
    bundle: nextBundle,
    setup: Lot50ScenarioSetup(
      mapId: bundle.map.id,
      eventId: lot50DemoEventId,
      scriptId: lot50DemoScriptId,
      flagName: lot50DemoFlagName,
      variableName: lot50DemoVariableName,
      consumedEventId: lot50DemoConsumedEventId,
      eventPos: eventPos,
    ),
  );
}

GameplayPlayerState _resolveSpawnState(MapData map) {
  try {
    return resolveInitialPlayerSpawn(map);
  } catch (_) {
    return const GameplayPlayerState(
      pos: GridPos(x: 0, y: 0),
      facing: Direction.south,
    );
  }
}

GridPos? _findScenarioEventPos(MapData map, GameplayPlayerState spawnState) {
  final spawnPos = spawnState.pos;
  final occupied = map.events
      .map((event) => '${event.position.x}:${event.position.y}')
      .toSet();
  final preferred = _preferredNeighborOrder(spawnState);
  for (final pos in preferred) {
    if (_isCandidatePosValid(map, pos, occupied, spawnPos: spawnPos)) {
      return pos;
    }
  }

  for (var radius = 1; radius <= 6; radius++) {
    for (var dx = -radius; dx <= radius; dx++) {
      final absDx = dx.abs();
      final dy = radius - absDx;
      final first = GridPos(x: spawnPos.x + dx, y: spawnPos.y + dy);
      if (_isCandidatePosValid(
        map,
        first,
        occupied,
        spawnPos: spawnPos,
      )) {
        return first;
      }
      if (dy != 0) {
        final second = GridPos(x: spawnPos.x + dx, y: spawnPos.y - dy);
        if (_isCandidatePosValid(
          map,
          second,
          occupied,
          spawnPos: spawnPos,
        )) {
          return second;
        }
      }
    }
  }

  for (var y = 0; y < map.size.height; y++) {
    for (var x = 0; x < map.size.width; x++) {
      final pos = GridPos(x: x, y: y);
      if (_isCandidatePosValid(
        map,
        pos,
        occupied,
        spawnPos: spawnPos,
      )) {
        return pos;
      }
    }
  }

  return null;
}

bool _isCandidatePosValid(
  MapData map,
  GridPos pos,
  Set<String> occupied, {
  required GridPos spawnPos,
}) {
  if (pos.x < 0 ||
      pos.y < 0 ||
      pos.x >= map.size.width ||
      pos.y >= map.size.height) {
    return false;
  }
  if (pos.x == spawnPos.x && pos.y == spawnPos.y) {
    return false;
  }
  final key = '${pos.x}:${pos.y}';
  return !occupied.contains(key);
}

List<GridPos> _preferredNeighborOrder(GameplayPlayerState spawnState) {
  final pos = spawnState.pos;
  final (fx, fy) = _deltaFor(spawnState.facing);
  final rightDir = switch (spawnState.facing) {
    Direction.north => Direction.east,
    Direction.east => Direction.south,
    Direction.south => Direction.west,
    Direction.west => Direction.north,
  };
  final leftDir = switch (spawnState.facing) {
    Direction.north => Direction.west,
    Direction.west => Direction.south,
    Direction.south => Direction.east,
    Direction.east => Direction.north,
  };
  final backDir = switch (spawnState.facing) {
    Direction.north => Direction.south,
    Direction.south => Direction.north,
    Direction.east => Direction.west,
    Direction.west => Direction.east,
  };
  final (rx, ry) = _deltaFor(rightDir);
  final (lx, ly) = _deltaFor(leftDir);
  final (bx, by) = _deltaFor(backDir);
  return [
    GridPos(x: pos.x + fx, y: pos.y + fy),
    GridPos(x: pos.x + rx, y: pos.y + ry),
    GridPos(x: pos.x + lx, y: pos.y + ly),
    GridPos(x: pos.x + bx, y: pos.y + by),
  ];
}

(int, int) _deltaFor(Direction direction) {
  return switch (direction) {
    Direction.north => (0, -1),
    Direction.south => (0, 1),
    Direction.east => (1, 0),
    Direction.west => (-1, 0),
  };
}

String _resolveScenarioLayerId(MapData map) {
  for (final layer in map.layers) {
    final id = layer.id.trim();
    if (id.isNotEmpty) {
      return id;
    }
  }
  return 'base';
}
