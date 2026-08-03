import 'dart:async';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/application/runtime_player_pokemon_progression_hydrator.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/playable_map_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('removal waits for the onLoad image handoff before disposal', () async {
    final imagesReady = Completer<void>();
    final releaseLoad = Completer<void>();
    RuntimeTilesetImage? loadedTileset;
    final game = PlayableMapGame(
      bundle: _bundle(),
      projectFilePath: '/tmp/tileset-lifecycle/project.json',
      runtimePlayerPokemonProgressionCatalogLoader: ({
        required gameState,
        required projectRootDirectory,
        required pokemonConfig,
      }) async {
        return const RuntimePlayerPokemonProgressionCatalogs(
          growthRateIdBySpeciesId: <String, String>{},
          maxPpByMoveId: <String, int>{},
        );
      },
      runtimeTilesetImageLoader: (
        absolutePathByTilesetId, {
        transparentColorByTilesetId = const <String, TilesetTransparentColor>{},
      }) async {
        final image = await _runtimeTilesetImage();
        loadedTileset = image;
        return <String, RuntimeTilesetImage>{'player': image};
      },
      afterInitialTilesetImagesLoaded: () async {
        imagesReady.complete();
        await releaseLoad.future;
      },
    );

    game.onGameResize(Vector2(128, 96));
    final load = game.onLoad();
    await imagesReady.future;

    game.onRemove();

    expect(loadedTileset!.debugDisposed, isFalse);
    releaseLoad.complete();
    await load;

    expect(loadedTileset!.debugDisposed, isTrue);
    expect(game.world.children, isEmpty);
  });
}

RuntimeMapBundle _bundle() {
  return RuntimeMapBundle(
    manifest: const ProjectManifest(
      name: 'Tileset lifecycle test',
      maps: <ProjectMapEntry>[],
      tilesets: <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'player',
          name: 'Player',
          relativePath: 'tilesets/player.png',
        ),
      ],
      settings: ProjectSettings(
        tileWidth: 16,
        tileHeight: 16,
        displayScale: 2,
        defaultPlayerCharacterId: 'player',
      ),
      characters: <ProjectCharacterEntry>[
        ProjectCharacterEntry(
          id: 'player',
          name: 'Player',
          tilesetId: 'player',
          frameWidth: 1,
          frameHeight: 2,
        ),
      ],
    ),
    map: const MapData(
      id: 'tileset-lifecycle-map',
      name: 'Tileset lifecycle map',
      size: GridSize(width: 4, height: 4),
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn'),
    ),
    projectRootDirectory: '/tmp/tileset-lifecycle',
    tilesetAbsolutePathsById: const <String, String>{
      'player': '/tmp/tileset-lifecycle/player.png',
    },
  );
}

Future<RuntimeTilesetImage> _runtimeTilesetImage() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    const ui.Rect.fromLTWH(0, 0, 16, 32),
    ui.Paint()..color = const ui.Color(0xFF4060FF),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(16, 32);
  picture.dispose();
  return RuntimeTilesetImage(
    images: <ui.Image>[image],
    chunks: const <RuntimeTilesetChunk>[
      RuntimeTilesetChunk(top: 0, height: 32, width: 16),
    ],
    width: 16,
    height: 32,
  );
}
