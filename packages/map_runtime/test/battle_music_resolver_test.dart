import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/presentation/flame/battle_music_resolver.dart';

RuntimeMapBundle _runtimeBundle({
  List<ProjectTrainerEntry> trainers = const <ProjectTrainerEntry>[],
  MapMetadata mapMetadata = const MapMetadata(),
  ProjectBattleAudioConfig? battleAudio,
}) {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'battle_music_resolver_test',
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'field_map',
          name: 'Field Map',
          relativePath: 'maps/field_map.json',
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[],
      trainers: trainers,
      battleAudio: battleAudio,
    ),
    map: MapData(
      id: 'field_map',
      name: 'Field Map',
      size: const GridSize(width: 10, height: 10),
      mapMetadata: mapMetadata,
    ),
    projectRootDirectory: '/tmp/runtime_music_resolver_test_project',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

WildBattleStartRequest _wildRequest() {
  return const WildBattleStartRequest(
    requestId: 'wild-request',
    createdAtEpochMs: 1,
    returnContext: OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 2, y: 2),
      playerFacing: Direction.north,
    ),
    mapId: 'field_map',
    zoneId: 'grass_zone',
    tableId: 'grass_table',
    encounterKind: EncounterKind.walk,
    speciesId: 'sparkitten',
    level: 5,
    minLevel: 5,
    maxLevel: 5,
    weight: 1,
    playerPos: GridPos(x: 2, y: 2),
  );
}

TrainerBattleStartRequest _trainerRequest() {
  return const TrainerBattleStartRequest(
    requestId: 'trainer-request',
    createdAtEpochMs: 1,
    returnContext: OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 2, y: 2),
      playerFacing: Direction.north,
    ),
    trainerId: 'rookie',
    npcEntityId: 'npc_rookie',
    mapId: 'field_map',
    playerPos: GridPos(x: 2, y: 2),
  );
}

const _root = '/tmp/runtime_music_resolver_test_project';

void main() {
  const resolver = BattleMusicResolver();

  const projectDefaults = ProjectBattleAudioConfig(
    wildBattleMusicPath: 'audio/wild_battle.ogg',
    trainerBattleMusicPath: 'audio/trainer_battle.ogg',
    wildVictoryMusicPath: 'audio/wild_victory.ogg',
    trainerVictoryMusicPath: 'audio/trainer_victory.ogg',
    encounterMusicPath: 'audio/encounter.ogg',
  );

  group('BattleMusicResolver — chaîne de précédence en table', () {
    final cases = <String, (BattleMusicSelection Function(), String?, String?)>{
      'sauvage sans rien authored → silence': (
        () => resolver.resolve(
              request: _wildRequest(),
              bundle: _runtimeBundle(),
            ),
        null,
        null,
      ),
      'sauvage avec défauts projet → défauts sauvages': (
        () => resolver.resolve(
              request: _wildRequest(),
              bundle: _runtimeBundle(battleAudio: projectDefaults),
            ),
        '$_root/audio/wild_battle.ogg',
        '$_root/audio/wild_victory.ogg',
      ),
      'sauvage : la carte gagne sur le défaut projet': (
        () => resolver.resolve(
              request: _wildRequest(),
              bundle: _runtimeBundle(
                battleAudio: projectDefaults,
                mapMetadata: const MapMetadata(
                  battleMusicPath: 'audio/cave_battle.ogg',
                ),
              ),
            ),
        '$_root/audio/cave_battle.ogg',
        '$_root/audio/wild_victory.ogg',
      ),
      'dresseur avec défauts projet → défauts dresseur': (
        () => resolver.resolve(
              request: _trainerRequest(),
              bundle: _runtimeBundle(battleAudio: projectDefaults),
            ),
        '$_root/audio/trainer_battle.ogg',
        '$_root/audio/trainer_victory.ogg',
      ),
      'dresseur : le dresseur gagne sur la carte et le projet': (
        () => resolver.resolve(
              request: _trainerRequest(),
              bundle: _runtimeBundle(
                battleAudio: projectDefaults,
                mapMetadata: const MapMetadata(
                  battleMusicPath: 'audio/cave_battle.ogg',
                ),
                trainers: const <ProjectTrainerEntry>[
                  ProjectTrainerEntry(
                    id: 'rookie',
                    name: 'Rookie',
                    trainerClass: 'Youngster',
                    battleMusicPath: 'audio/rival_battle.ogg',
                    victoryMusicPath: 'audio/rival_victory.ogg',
                  ),
                ],
              ),
            ),
        '$_root/audio/rival_battle.ogg',
        '$_root/audio/rival_victory.ogg',
      ),
      'dresseur sans thème propre : la carte gagne sur le défaut projet': (
        () => resolver.resolve(
              request: _trainerRequest(),
              bundle: _runtimeBundle(
                battleAudio: projectDefaults,
                mapMetadata: const MapMetadata(
                  battleMusicPath: 'audio/cave_battle.ogg',
                ),
                trainers: const <ProjectTrainerEntry>[
                  ProjectTrainerEntry(
                    id: 'rookie',
                    name: 'Rookie',
                    trainerClass: 'Youngster',
                  ),
                ],
              ),
            ),
        '$_root/audio/cave_battle.ogg',
        '$_root/audio/trainer_victory.ogg',
      ),
      'chemin blanc = non authored, la chaîne continue': (
        () => resolver.resolve(
              request: _trainerRequest(),
              bundle: _runtimeBundle(
                battleAudio: projectDefaults,
                trainers: const <ProjectTrainerEntry>[
                  ProjectTrainerEntry(
                    id: 'rookie',
                    name: 'Rookie',
                    trainerClass: 'Youngster',
                    battleMusicPath: '   ',
                    victoryMusicPath: '',
                  ),
                ],
              ),
            ),
        '$_root/audio/trainer_battle.ogg',
        '$_root/audio/trainer_victory.ogg',
      ),
    };

    cases.forEach((label, testCase) {
      test(label, () {
        final (resolve, expectedBattle, expectedVictory) = testCase;
        final selection = resolve();
        expect(selection.battleMusicAbsolutePath, expectedBattle);
        expect(selection.victoryMusicAbsolutePath, expectedVictory);
      });
    });
  });

  group('BattleMusicResolver — musiques hors combat', () {
    test('musique de rencontre : défaut projet seul, null sinon', () {
      expect(
        resolver.resolveEncounterMusicAbsolutePath(bundle: _runtimeBundle()),
        isNull,
      );
      expect(
        resolver.resolveEncounterMusicAbsolutePath(
          bundle: _runtimeBundle(battleAudio: projectDefaults),
        ),
        '$_root/audio/encounter.ogg',
      );
    });

    test('musique de carte : metadata.musicPath, null sinon', () {
      expect(
        resolver.resolveMapMusicAbsolutePath(bundle: _runtimeBundle()),
        isNull,
      );
      expect(
        resolver.resolveMapMusicAbsolutePath(
          bundle: _runtimeBundle(
            mapMetadata: const MapMetadata(musicPath: 'audio/town.ogg'),
          ),
        ),
        '$_root/audio/town.ogg',
      );
    });
  });
}
