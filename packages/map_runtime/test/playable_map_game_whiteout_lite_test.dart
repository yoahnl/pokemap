import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';

const _whiteoutTestStats = BattleStatsSnapshot(
  attack: 10,
  defense: 10,
  specialAttack: 10,
  specialDefense: 10,
  speed: 10,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayableMapGame whiteout-lite lot 15', () {
    test(
        'defeat recovery returns to the current map spawn, revives one pokemon when needed, and restores overworld flow',
        () async {
      final game = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        saveData: saveDataFromGameState(
          const GameState(
            saveId: 'whiteout-save',
            party: PlayerParty(
              members: <PlayerPokemon>[
                PlayerPokemon(
                  speciesId: 'sproutle',
                  natureId: 'bold',
                  abilityId: 'overgrow',
                  level: 10,
                  knownMoveIds: <String>['tackle'],
                  currentHp: 12,
                ),
              ],
            ),
          ),
        ),
      );

      game.onGameResize(Vector2(640, 480));
      await game.onLoad();

      // On place volontairement le joueur loin du spawn pour prouver que le
      // whiteout-lite ne "reprend" pas juste sur la dernière case du combat.
      game.debugSetPlayerStateForTest(
        position: const GridPos(x: 2, y: 1),
        facing: Direction.west,
      );

      game.debugApplyBattleOutcomeForTest(
        context: _wildContext(),
        outcome: _defeatOutcome(playerCurrentHp: 0),
      );

      final snapshot = game.gameStateSnapshot;
      expect(snapshot.currentMapId, equals('test_field'));
      expect(snapshot.playerPosition, equals(const GridPos(x: 0, y: 0)));
      expect(snapshot.playerFacing, equals(EntityFacing.east));
      expect(snapshot.playerMovementMode, equals(MovementMode.walk));
      expect(snapshot.party.members.single.currentHp, equals(1));
      expect(game.debugFlowPhaseName, equals('overworld'));
    });
  });
}

RuntimeMapBundle _bundle() {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Whiteout Lite Runtime Test',
      maps: <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'test_field',
          name: 'Test Field',
          relativePath: 'maps/test_field.json',
        ),
      ],
      tilesets: <ProjectTilesetEntry>[],
      surfaceCatalog: ProjectSurfaceCatalog(),
    ),
    map: const MapData(
      id: 'test_field',
      name: 'Test Field',
      size: GridSize(width: 4, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn_start',
          name: 'Spawn Start',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 0),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.east,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn_start'),
    ),
    projectRootDirectory: '/tmp/project',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

RuntimeActiveBattleContext _wildContext() {
  return const RuntimeActiveBattleContext(
    request: WildBattleStartRequest(
      requestId: 'wild-defeat',
      createdAtEpochMs: 1,
      returnContext: OverworldReturnContext(
        mapId: 'test_field',
        playerPos: GridPos(x: 2, y: 1),
        playerFacing: Direction.west,
      ),
      mapId: 'test_field',
      zoneId: 'grass',
      tableId: 'field_grass',
      encounterKind: EncounterKind.walk,
      speciesId: 'wildmon',
      level: 7,
      minLevel: 7,
      maxLevel: 7,
      weight: 1,
      playerPos: GridPos(x: 2, y: 1),
    ),
    playerPartyIndex: 0,
  );
}

BattleOutcome _defeatOutcome({
  required int playerCurrentHp,
}) {
  return BattleOutcome(
    type: BattleOutcomeType.defeat,
    finalState: BattleState(
      phase: BattlePhase.finished,
      player: BattleCombatant(
        speciesId: 'sproutle',
        level: 10,
        currentHp: playerCurrentHp,
        maxHp: 24,
        stats: _whiteoutTestStats,
        moves: const <BattleMove>[
          BattleMove(id: 'tackle', name: 'Tackle', power: 10),
        ],
      ),
      enemy: const BattleCombatant(
        speciesId: 'wildmon',
        level: 7,
        currentHp: 9,
        maxHp: 18,
        stats: _whiteoutTestStats,
        moves: <BattleMove>[
          BattleMove(id: 'scratch', name: 'Scratch', power: 10),
        ],
      ),
      currentTurn: null,
      outcome: null,
    ),
  );
}
