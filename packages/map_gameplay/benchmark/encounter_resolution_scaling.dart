import 'dart:math';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

void main(List<String> args) {
  if (args.contains('--help') || args.contains('-h')) {
    print(
      'Usage: dart run benchmark/encounter_resolution_scaling.dart '
      '[--entries=480] [--zones=12] [--warmup=20] '
      '[--iterations=100] [--seed=8122026]',
    );
    return;
  }
  final entries = _positiveOption(args, 'entries', 480);
  final zones = _positiveOption(args, 'zones', 12);
  final warmup = _nonNegativeOption(args, 'warmup', 20);
  final iterations = _positiveOption(args, 'iterations', 100);
  final seed = _integerOption(args, 'seed', 8122026);
  final fixture = _fixture(entries: entries, zones: zones);
  for (var index = 0; index < warmup; index++) {
    _runIteration(fixture, seed + index);
  }
  final samples = <int>[];
  var resolved = 0;
  for (var index = 0; index < iterations; index++) {
    final stopwatch = Stopwatch()..start();
    resolved += _runIteration(fixture, seed + index + warmup);
    stopwatch.stop();
    samples.add(stopwatch.elapsedMicroseconds);
  }
  samples.sort();
  final median = samples[samples.length ~/ 2];
  final p95 = samples[((samples.length - 1) * 0.95).ceil()];
  print(
    'entries=$entries zones=$zones warmup=$warmup iterations=$iterations '
    'seed=$seed median_us=$median p95_us=$p95 resolved=$resolved '
    'candidates_per_position_min=${fixture.candidatesPerPositionMin}',
  );
}

int _runIteration(_Fixture fixture, int seed) {
  final restored = ProjectManifest.fromJson(fixture.project.toJson());
  ProjectValidator.validate(restored);
  var resolved = 0;
  for (var position = 0; position < fixture.positions.length; position++) {
    final world = GameplayWorldState.initial(
      map: fixture.map,
      playerPos: fixture.positions[position],
      project: restored,
    );
    final result = checkEncounterAtPlayerPosition(
      world: world,
      project: restored,
      encounterKind: EncounterKind.walk,
      gameState: fixture.gameState,
      random: Random(seed + position),
    );
    if (result.triggered &&
        result.encounter!.level >= result.encounter!.minLevel &&
        result.encounter!.level <= result.encounter!.maxLevel) {
      resolved++;
    }
  }
  return resolved;
}

_Fixture _fixture({required int entries, required int zones}) {
  final entryList = <ProjectEncounterEntry>[
    for (var index = 0; index < entries; index++)
      ProjectEncounterEntry(
        speciesId: 'species_${index.toString().padLeft(4, '0')}',
        minLevel: 2 + index % 30,
        maxLevel: 4 + index % 30,
        weight: 1 + index % 17,
      ),
  ];
  final tables = <ProjectEncounterTable>[
    for (var index = 0; index < zones; index++)
      ProjectEncounterTable(
        id: 'table_$index',
        name: 'Table $index',
        encounterKind: EncounterKind.walk,
        chancePerStep: 1,
        conditions: <ScriptCondition>[
          ScriptConditionFactory.flagIsSet('benchmark_open'),
          ScriptConditionFactory.variableGreaterThan('chapter', 0),
        ],
        entries: entryList,
      ),
  ];
  final project = ProjectManifest(
    name: 'BETA-ENC-001 benchmark',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    encounterTables: tables,
  );
  final positions = <GridPos>[
    for (var index = 0; index < zones; index++) GridPos(x: index * 4 + 1, y: 1),
  ];
  final gameplayZones = <MapGameplayZone>[
    MapGameplayZone(
      id: 'fallback_zone',
      name: 'Fallback zone',
      kind: GameplayZoneKind.encounter,
      area: MapRect(
        pos: const GridPos(x: 0, y: 0),
        size: GridSize(width: zones * 4, height: 4),
      ),
      priority: 0,
      encounter: const EncounterZonePayload(
        encounterTableId: 'table_0',
        encounterKind: EncounterKind.walk,
      ),
    ),
    MapGameplayZone(
      id: 'regional_zone',
      name: 'Regional zone',
      kind: GameplayZoneKind.encounter,
      area: MapRect(
        pos: const GridPos(x: 0, y: 0),
        size: GridSize(width: zones * 4, height: 4),
      ),
      priority: 1,
      encounter: EncounterZonePayload(
        encounterTableId: 'table_${zones > 1 ? 1 : 0}',
        encounterKind: EncounterKind.walk,
      ),
    ),
    for (var index = 0; index < zones; index++)
      MapGameplayZone(
        id: 'zone_$index',
        name: 'Zone $index',
        kind: GameplayZoneKind.encounter,
        area: MapRect(
          pos: GridPos(x: index * 4, y: 0),
          size: const GridSize(width: 4, height: 4),
        ),
        priority: 2,
        encounter: EncounterZonePayload(
          encounterTableId: 'table_$index',
          encounterKind: EncounterKind.walk,
        ),
      ),
  ];
  final map = MapData(
    id: 'benchmark_map',
    name: 'Benchmark map',
    version: ProjectVersion.v6,
    size: GridSize(width: zones * 4, height: 4),
    gameplayZones: gameplayZones,
  );
  MapValidator.validate(map, projectDialogueContext: project);
  final candidatesPerPositionMin = positions
      .map(
        (position) => gameplayZones
            .where((zone) => _contains(zone.area, position))
            .length,
      )
      .reduce(min);
  if (candidatesPerPositionMin < 3) {
    throw StateError('Encounter benchmark candidate workload is incomplete.');
  }
  return _Fixture(
    project: project,
    map: map,
    positions: positions,
    candidatesPerPositionMin: candidatesPerPositionMin,
    gameState: const GameState(
      saveId: 'benchmark',
      storyFlags: StoryFlags(activeFlags: <String>{'benchmark_open'}),
      scriptVariables: ScriptVariables(
        values: <String, ScriptVariableValue>{
          'chapter': ScriptVariableValue.int(2),
        },
      ),
    ),
  );
}

bool _contains(MapRect area, GridPos position) {
  return position.x >= area.pos.x &&
      position.x < area.pos.x + area.size.width &&
      position.y >= area.pos.y &&
      position.y < area.pos.y + area.size.height;
}

int _positiveOption(List<String> args, String name, int fallback) {
  final value = _integerOption(args, name, fallback);
  if (value <= 0) {
    throw FormatException('--$name must be positive');
  }
  return value;
}

int _nonNegativeOption(List<String> args, String name, int fallback) {
  final value = _integerOption(args, name, fallback);
  if (value < 0) {
    throw FormatException('--$name must be non-negative');
  }
  return value;
}

int _integerOption(List<String> args, String name, int fallback) {
  final prefix = '--$name=';
  final raw = args.where((arg) => arg.startsWith(prefix));
  if (raw.isEmpty) return fallback;
  final parsed = int.tryParse(raw.last.substring(prefix.length));
  if (parsed == null) {
    throw FormatException('--$name must be an integer');
  }
  return parsed;
}

class _Fixture {
  const _Fixture({
    required this.project,
    required this.map,
    required this.positions,
    required this.candidatesPerPositionMin,
    required this.gameState,
  });

  final ProjectManifest project;
  final MapData map;
  final List<GridPos> positions;
  final int candidatesPerPositionMin;
  final GameState gameState;
}
