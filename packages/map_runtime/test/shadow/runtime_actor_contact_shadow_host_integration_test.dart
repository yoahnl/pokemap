import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:map_runtime/src/presentation/flame/playable_map_game.dart';
import 'package:map_runtime/src/presentation/flame/runtime_map_game.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';

import '../surface/surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('runtime actor contact shadow host integration', () {
    test('PlayableMapGame wires an internal provider to background only',
        () async {
      final game = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
      );

      game.onGameResize(Vector2(96, 96));
      await game.onLoad();
      game.update(0);
      final layers = game.world.children.whereType<MapLayersComponent>();
      final background = layers.singleWhere(
        (layer) => layer.renderPass == MapLayerRenderPass.background,
      );
      final foreground = layers.singleWhere(
        (layer) => layer.renderPass == MapLayerRenderPass.foreground,
      );

      expect(game.shadowCollectionProvider, isNull);
      expect(background.shadowCollectionProvider, isNotNull);
      expect(foreground.shadowCollectionProvider, isNull);
      expect(background.shadowCollectionProvider!(), isNotNull);
      expect(background.shadowCollectionProvider!()!.actorContact, isNotEmpty);
    });

    test('internal provider draws an actor contact shadow under the player',
        () async {
      final game = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
      );

      game.onGameResize(Vector2(96, 96));
      await game.onLoad();
      game.update(0);
      final background =
          game.world.children.whereType<MapLayersComponent>().singleWhere(
                (layer) => layer.renderPass == MapLayerRenderPass.background,
              );
      final collection = background.shadowCollectionProvider!()!;
      final instruction = collection.actorContact.single;
      final image = await _render(background, width: 96, height: 96);
      final centerX = (instruction.worldLeft + instruction.width / 2).round();
      final centerY = (instruction.worldTop + instruction.height / 2).round();

      expect((await pixelAt(image, centerX, centerY))[3], greaterThan(0));
    });

    test('player contact shadow uses rendered actor visual size', () async {
      final game = PlayableMapGame(
        bundle: _bundle(playerFrameWidth: 3, playerFrameHeight: 3),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);
      final provider =
          game.debugShadowCollectionProviderForMap('shadow-actor-test')!;
      final instruction = provider()!.actorContact.single;

      expect(instruction.width, closeTo(57.6, 0.0001));
      expect(instruction.height, closeTo(17.28, 0.0001));
    });

    test('NPC actors are included when present', () async {
      final game = PlayableMapGame(
        bundle: _bundle(includeNpc: true),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);
      final background =
          game.world.children.whereType<MapLayersComponent>().singleWhere(
                (layer) => layer.renderPass == MapLayerRenderPass.background,
              );
      final collection = background.shadowCollectionProvider!()!;

      expect(collection.actorContact, hasLength(2));
    });

    test('external provider stays priority when internal shadows are disabled',
        () async {
      var calls = 0;
      ShadowRuntimeInstructionCollection? provider() {
        calls += 1;
        return ShadowRuntimeInstructionCollection(
          instructions: [
            _shadow(colorHexRgb: 'FF0000'),
          ],
        );
      }

      final game = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        shadowCollectionProvider: provider,
        enableActorContactShadows: false,
      );

      game.onGameResize(Vector2(96, 96));
      await game.onLoad();
      game.update(0);
      final background =
          game.world.children.whereType<MapLayersComponent>().singleWhere(
                (layer) => layer.renderPass == MapLayerRenderPass.background,
              );
      final foreground =
          game.world.children.whereType<MapLayersComponent>().singleWhere(
                (layer) => layer.renderPass == MapLayerRenderPass.foreground,
              );
      final image = await _render(background, width: 96, height: 96);

      expect(background.shadowCollectionProvider, same(provider));
      expect(foreground.shadowCollectionProvider, isNull);
      expect(calls, 1);
      expect(await pixelAt(image, 16, 16), rgba(255, 0, 0, 255));
    });

    test('disabled internal shadows do not install an internal provider',
        () async {
      final game = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
        enableStaticPlacedElementShadows: false,
      );

      game.onGameResize(Vector2(96, 96));
      await game.onLoad();
      game.update(0);
      final background =
          game.world.children.whereType<MapLayersComponent>().singleWhere(
                (layer) => layer.renderPass == MapLayerRenderPass.background,
              );
      final foreground =
          game.world.children.whereType<MapLayersComponent>().singleWhere(
                (layer) => layer.renderPass == MapLayerRenderPass.foreground,
              );

      expect(background.shadowCollectionProvider, isNull);
      expect(foreground.shadowCollectionProvider, isNull);
    });

    test('internal provider is scoped to the active map background', () async {
      final game = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
      );

      game.onGameResize(Vector2(96, 96));
      await game.onLoad();
      game.update(0);
      final activeProvider =
          game.debugShadowCollectionProviderForMap('shadow-actor-test');
      final inactiveProvider =
          game.debugShadowCollectionProviderForMap('connected-map');

      expect(activeProvider, isNotNull);
      expect(inactiveProvider, isNotNull);
      expect(activeProvider!(), isNotNull);
      expect(inactiveProvider!(), isNull);
    });

    test('internal provider can return a different collection after movement',
        () async {
      final game = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
      );

      game.onGameResize(Vector2(96, 96));
      await game.onLoad();
      game.update(0);
      final provider =
          game.debugShadowCollectionProviderForMap('shadow-actor-test')!;
      final first = provider()!.actorContact.single;
      game.debugSetPlayerStateForTest(
        position: const GridPos(x: 1, y: 0),
        facing: Direction.south,
      );
      game.update(0);
      final second = provider()!.actorContact.single;

      expect(second.worldLeft, isNot(first.worldLeft));
    });

    test('RuntimeMapGame remains passive for actor shadows', () async {
      final game = RuntimeMapGame(bundle: _bundle());

      game.onGameResize(Vector2(96, 96));
      await game.onLoad();
      final layer = game.world.children.whereType<MapLayersComponent>().single;

      expect(game.shadowCollectionProvider, isNull);
      expect(layer.shadowCollectionProvider, isNull);
    });
  });
}

RuntimeMapBundle _bundle({
  bool includeNpc = false,
  int playerFrameWidth = 2,
  int playerFrameHeight = 2,
}) {
  final entities = <MapEntity>[
    const MapEntity(
      id: 'spawn',
      name: 'Spawn',
      kind: MapEntityKind.spawn,
      pos: GridPos(x: 0, y: 0),
      blocksMovement: false,
      spawn: MapEntitySpawnData(
        role: EntitySpawnRole.playerStart,
        facing: EntityFacing.south,
      ),
    ),
    if (includeNpc)
      const MapEntity(
        id: 'npc-one',
        name: 'NPC One',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 2, y: 1),
        npc: MapEntityNpcData(
          characterId: 'npc',
        ),
      ),
  ];
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Runtime Actor Contact Shadow Test',
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      settings: const ProjectSettings(
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
          frameWidth: playerFrameWidth,
          frameHeight: playerFrameHeight,
        ),
        const ProjectCharacterEntry(
          id: 'npc',
          name: 'NPC',
          tilesetId: 'npc',
          frameWidth: 2,
          frameHeight: 2,
        ),
      ],
      surfaceCatalog: ProjectSurfaceCatalog(),
    ),
    map: MapData(
      id: 'shadow-actor-test',
      name: 'Shadow Actor Test',
      size: const GridSize(width: 4, height: 4),
      layers: const [
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: entities,
      mapMetadata: const MapMetadata(defaultSpawnId: 'spawn'),
    ),
    projectRootDirectory: '/tmp/runtime-actor-contact-shadow-test',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

Future<Map<String, RuntimeTilesetImage>> _emptyImageLoader(
  Map<String, String> absolutePathByTilesetId, {
  Map<String, TilesetTransparentColor> transparentColorByTilesetId =
      const <String, TilesetTransparentColor>{},
}) async {
  return const <String, RuntimeTilesetImage>{};
}

Future<ui.Image> _render(
  MapLayersComponent component, {
  required int width,
  required int height,
}) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  component.render(canvas);
  return recorder.endRecording().toImage(width, height);
}

ShadowRuntimeRenderInstruction _shadow({
  String colorHexRgb = '000000',
}) {
  return ShadowRuntimeRenderInstruction(
    shape: ShadowRuntimeShapeKind.ellipse,
    renderPass: ShadowRenderPass.groundStatic,
    worldLeft: 4,
    worldTop: 4,
    width: 24,
    height: 24,
    opacity: 1,
    colorHexRgb: colorHexRgb,
  );
}
