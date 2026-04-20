import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/presentation/flame/battle_background_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_backdrop_component.dart';

RuntimeMapBundle _runtimeBundle({
  List<MapGameplayZone> gameplayZones = const <MapGameplayZone>[],
  List<ProjectTrainerEntry> trainers = const <ProjectTrainerEntry>[],
  MapMetadata mapMetadata = const MapMetadata(),
}) {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'battle_background_resolver_test',
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'field_map',
          name: 'Field Map',
          relativePath: 'maps/field_map.json',
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[],
      trainers: trainers,
    ),
    map: MapData(
      id: 'field_map',
      name: 'Field Map',
      size: const GridSize(width: 10, height: 10),
      mapMetadata: mapMetadata,
      gameplayZones: gameplayZones,
    ),
    projectRootDirectory: '/tmp/runtime_background_resolver_test_project',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

WildBattleStartRequest _wildRequest({
  String zoneId = 'grass_zone',
  GridPos playerPos = const GridPos(x: 2, y: 2),
}) {
  return WildBattleStartRequest(
    requestId: 'wild-request',
    createdAtEpochMs: 1,
    returnContext: OverworldReturnContext(
      mapId: 'field_map',
      playerPos: playerPos,
      playerFacing: Direction.north,
    ),
    mapId: 'field_map',
    zoneId: zoneId,
    tableId: 'grass_table',
    encounterKind: EncounterKind.walk,
    speciesId: 'sparkitten',
    level: 5,
    minLevel: 5,
    maxLevel: 5,
    weight: 1,
    playerPos: playerPos,
  );
}

TrainerBattleStartRequest _trainerRequest({
  GridPos playerPos = const GridPos(x: 2, y: 2),
}) {
  return TrainerBattleStartRequest(
    requestId: 'trainer-request',
    createdAtEpochMs: 1,
    returnContext: OverworldReturnContext(
      mapId: 'field_map',
      playerPos: playerPos,
      playerFacing: Direction.north,
    ),
    trainerId: 'rookie',
    npcEntityId: 'npc_rookie',
    mapId: 'field_map',
    playerPos: playerPos,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BattleBackgroundResolver', () {
    const resolver = BattleBackgroundResolver();

    test('wild battle uses encounter zone explicit background when authored', () {
      final bundle = _runtimeBundle(
        gameplayZones: const <MapGameplayZone>[
          MapGameplayZone(
            id: 'grass_zone',
            kind: GameplayZoneKind.encounter,
            area: MapRect(
              pos: GridPos(x: 1, y: 1),
              size: GridSize(width: 3, height: 3),
            ),
            encounter: EncounterZonePayload(
              encounterTableId: 'grass_table',
              encounterKind: EncounterKind.walk,
              battleBackgroundRelativePath:
                  'assets/battle_backgrounds/grass_zone.png',
            ),
          ),
        ],
      );

      final spec = resolver.resolve(
        request: _wildRequest(),
        bundle: bundle,
      );

      expect(spec.key, BattleBackgroundKey.wildOutdoor);
      expect(
        spec.explicitImageAbsolutePath,
        '/tmp/runtime_background_resolver_test_project/assets/battle_backgrounds/grass_zone.png',
      );
    });

    test('trainer explicit background wins over encounter zone background', () {
      final bundle = _runtimeBundle(
        trainers: const <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'rookie',
            name: 'Rookie',
            trainerClass: 'Youngster',
            battleBackgroundRelativePath:
                'assets/battle_backgrounds/trainer_rookie.png',
          ),
        ],
        gameplayZones: const <MapGameplayZone>[
          MapGameplayZone(
            id: 'grass_zone',
            kind: GameplayZoneKind.encounter,
            area: MapRect(
              pos: GridPos(x: 1, y: 1),
              size: GridSize(width: 4, height: 4),
            ),
            encounter: EncounterZonePayload(
              encounterTableId: 'grass_table',
              encounterKind: EncounterKind.walk,
              battleBackgroundRelativePath:
                  'assets/battle_backgrounds/grass_zone.png',
            ),
          ),
        ],
      );

      final spec = resolver.resolve(
        request: _trainerRequest(),
        bundle: bundle,
      );

      expect(spec.key, BattleBackgroundKey.trainerOutdoor);
      expect(
        spec.explicitImageAbsolutePath,
        '/tmp/runtime_background_resolver_test_project/assets/battle_backgrounds/trainer_rookie.png',
      );
    });

    test('missing explicit trainer image stays on contextual fallback key', () {
      final bundle = _runtimeBundle(
        trainers: const <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'rookie',
            name: 'Rookie',
            trainerClass: 'Youngster',
            battleBackgroundRelativePath:
                'assets/battle_backgrounds/missing.png',
          ),
        ],
      );

      final spec = resolver.resolve(
        request: _trainerRequest(),
        bundle: bundle,
      );

      expect(spec.key, BattleBackgroundKey.trainerOutdoor);
      expect(
        spec.explicitImageAbsolutePath,
        '/tmp/runtime_background_resolver_test_project/assets/battle_backgrounds/missing.png',
      );
    });
  });

  test(
      'backdrop does not crash when explicit image is missing and keeps fallback key',
      () async {
    final backdrop = BattleSceneBackdropComponent(
      size: Vector2(640, 360),
      backgroundSpec: const BattleBackgroundSpec.explicitImage(
        fallbackKey: BattleBackgroundKey.trainerOutdoor,
        absolutePath: '/tmp/runtime_background_resolver_test_project/missing.png',
      ),
    );

    await backdrop.onLoad();

    expect(backdrop.didExplicitImageLoadFail, isTrue);
    expect(backdrop.hasResolvedExplicitImage, isFalse);
    expect(backdrop.currentBackgroundKey, BattleBackgroundKey.trainerOutdoor);
  });
}
