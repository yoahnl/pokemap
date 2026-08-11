import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('no-save boot uses the project newGame contract through onLoad',
      () async {
    final game = PlayableMapGame(
      bundle: _bundle(),
      projectFilePath: '/tmp/project_new_game/project.json',
    );

    expect(game.gameStateSnapshot.currentMapId, 'new_game_map');
    expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 5, y: 6));
    expect(game.gameStateSnapshot.playerFacing, EntityFacing.north);
    expect(game.gameStateSnapshot.trainerProfile.money, 420);
    expect(game.gameStateSnapshot.bag.entries.single.itemId, 'potion');
    expect(
      game.gameStateSnapshot.narrativeFactRuntimeState
          .overridesByFactId['fact_existing_party'],
      isFalse,
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad();

    expect(game.gameStateSnapshot.currentMapId, 'new_game_map');
    expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 5, y: 6));
    expect(game.gameStateSnapshot.playerFacing, EntityFacing.north);
  });

  test('an explicit save remains authoritative over newGame config', () {
    const saved = GameState(
      saveId: 'existing_save',
      currentMapId: 'new_game_map',
      playerPosition: GridPos(x: 2, y: 3),
      playerFacing: EntityFacing.west,
      trainerProfile: TrainerProfile(name: 'Sauvegarde', money: 999),
    );
    final game = PlayableMapGame(
      bundle: _bundle(),
      projectFilePath: '/tmp/project_new_game/project.json',
      saveData: saveDataFromGameState(saved),
      initialMapActivationReason: MapActivationReason.saveRestore,
    );

    expect(game.gameStateSnapshot.saveId, 'existing_save');
    expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 2, y: 3));
    expect(game.gameStateSnapshot.trainerProfile.money, 999);
    expect(
      game.gameStateSnapshot.scriptVariables.values['player_name'],
      const ScriptVariableValue.string('Sauvegarde'),
    );
  });

  test('guided identity overrides authored defaults only for a new game', () {
    final game = PlayableMapGame(
      bundle: _bundle(),
      projectFilePath: '/tmp/project_new_game/project.json',
      runtimeLocale: 'fr-FR',
      initialPlayerName: 'Camille',
      initialPlayerAvatarCharacterId: 'hero_b',
      initialPlayerPronounSet: PlayerPronounSet.feminine,
    );

    expect(game.gameStateSnapshot.trainerProfile.name, 'Camille');
    expect(
      game.gameStateSnapshot.trainerProfile.avatarCharacterId,
      'hero_b',
    );
    expect(
      game.gameStateSnapshot.trainerProfile.pronounSet,
      PlayerPronounSet.feminine,
    );
    expect(
      game.gameStateSnapshot.scriptVariables.values['player_pronoun_subject'],
      const ScriptVariableValue.string('elle'),
    );
  });
}

RuntimeMapBundle _bundle() {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'New Game Project',
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'new_game_map',
          name: 'New game map',
          relativePath: 'maps/new_game_map.json',
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'characters',
          name: 'Personnages',
          relativePath: 'assets/characters.png',
        ),
      ],
      characters: const <ProjectCharacterEntry>[
        ProjectCharacterEntry(
          id: 'hero_a',
          name: 'Héroïne A',
          tilesetId: 'characters',
        ),
        ProjectCharacterEntry(
          id: 'hero_b',
          name: 'Héros B',
          tilesetId: 'characters',
        ),
      ],
      settings: const ProjectSettings(defaultPlayerCharacterId: 'hero_a'),
      facts: <NarrativeFactDefinition>[
        NarrativeFactDefinition(
          id: 'fact_existing_party',
          label: 'Équipe existante',
        ),
      ],
      newGame: const ProjectNewGameConfig(
        enabled: true,
        startMapId: 'new_game_map',
        startSpawnId: 'spawn_new_game',
        playerName: 'Joueur',
        playerAvatarCharacterIds: <String>['hero_a', 'hero_b'],
        startingMoney: 420,
        initialBag: <BagEntry>[
          BagEntry(itemId: 'potion', quantity: 1),
        ],
        existingPartyFactId: 'fact_existing_party',
      ),
    ),
    map: const MapData(
      id: 'new_game_map',
      name: 'New game map',
      size: GridSize(width: 10, height: 10),
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn_default'),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn_default',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          spawn: MapEntitySpawnData(
            spawnKey: 'spawn_default',
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
        MapEntity(
          id: 'spawn_new_game',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 5, y: 6),
          spawn: MapEntitySpawnData(
            spawnKey: 'spawn_new_game',
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.north,
          ),
        ),
      ],
    ),
    projectRootDirectory: '/tmp/project_new_game',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}
