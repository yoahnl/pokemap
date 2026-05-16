import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
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

  group('runtime static placed element shadow host integration', () {
    test('PlayableMapGame builds static shadows for configured placed elements',
        () async {
      final game = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);
      final background = _backgroundLayer(game);
      final foreground = _foregroundLayer(game);
      final collection = background.shadowCollectionProvider!()!;

      expect(foreground.shadowCollectionProvider, isNull);
      expect(collection.groundStatic, hasLength(1));
      expect(collection.actorContact, isEmpty);
      expect(collection.groundStatic.single.renderPass,
          ShadowRenderPass.groundStatic);
    });

    test('static shadow is visible in the background render when configured',
        () async {
      final game = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);
      final background = _backgroundLayer(game);
      final instruction =
          background.shadowCollectionProvider!()!.groundStatic.single;
      final image = await _render(background, width: 160, height: 160);
      final centerX = (instruction.worldLeft + instruction.width / 2).round();
      final centerY = (instruction.worldTop + instruction.height / 2).round();

      expect((await pixelAt(image, centerX, centerY))[3], greaterThan(0));
    });

    test('empty catalog or missing profile creates no static shadow', () async {
      final game = PlayableMapGame(
        bundle: _bundle(shadowCatalog: const ProjectShadowCatalog.empty()),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);
      final collection = _backgroundLayer(game).shadowCollectionProvider!();

      expect(collection, isNull);
    });

    test('element without shadow config creates no static shadow', () async {
      final game = PlayableMapGame(
        bundle: _bundle(elementShadow: null),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);
      final collection = _backgroundLayer(game).shadowCollectionProvider!();

      expect(collection, isNull);
    });

    test('disabled placed override creates no static shadow', () async {
      final game = PlayableMapGame(
        bundle: _bundle(
          placedOverride: MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.disabled,
          ),
        ),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);
      final collection = _backgroundLayer(game).shadowCollectionProvider!();

      expect(collection, isNull);
    });

    test('custom placed override modifies the static shadow instruction',
        () async {
      final baselineGame = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
      );
      baselineGame.onGameResize(Vector2(160, 160));
      await baselineGame.onLoad();
      baselineGame.update(0);
      final baselineInstruction = _backgroundLayer(baselineGame)
          .shadowCollectionProvider!()!
          .groundStatic
          .single;

      final game = PlayableMapGame(
        bundle: _bundle(
          placedOverride: MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
            offsetX: 8,
            scaleX: 2,
            opacity: 0.2,
          ),
        ),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);
      final instruction = _backgroundLayer(game)
          .shadowCollectionProvider!()!
          .groundStatic
          .single;

      expect(instruction.shape, ShadowRuntimeShapeKind.projectedPolygon);
      expect(instruction.polygonPoints, hasLength(4));
      expect(
        _hasDifferentPolygonPoints(instruction, baselineInstruction),
        isTrue,
      );
      expect(instruction.opacity, 0.2);
    });

    test('internal static and actor shadows are merged for the active map',
        () async {
      final game = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);
      final collection = _backgroundLayer(game).shadowCollectionProvider!()!;

      expect(collection.groundStatic, hasLength(1));
      expect(collection.actorContact, hasLength(1));
      expect(collection.instructions.first.renderPass,
          ShadowRenderPass.groundStatic);
      expect(collection.instructions.last.renderPass,
          ShadowRenderPass.actorContact);
    });

    test('static and actor flags affect only their internal collections',
        () async {
      final staticOnly = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
      );
      staticOnly.onGameResize(Vector2(160, 160));
      await staticOnly.onLoad();
      staticOnly.update(0);

      final actorOnly = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableStaticPlacedElementShadows: false,
      );
      actorOnly.onGameResize(Vector2(160, 160));
      await actorOnly.onLoad();
      actorOnly.update(0);

      final disabled = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
        enableStaticPlacedElementShadows: false,
      );
      disabled.onGameResize(Vector2(160, 160));
      await disabled.onLoad();
      disabled.update(0);

      expect(
        _backgroundLayer(staticOnly).shadowCollectionProvider!()!.groundStatic,
        hasLength(1),
      );
      expect(
        _backgroundLayer(staticOnly).shadowCollectionProvider!()!.actorContact,
        isEmpty,
      );
      expect(
        _backgroundLayer(actorOnly).shadowCollectionProvider!()!.groundStatic,
        isEmpty,
      );
      expect(
        _backgroundLayer(actorOnly).shadowCollectionProvider!()!.actorContact,
        hasLength(1),
      );
      expect(_backgroundLayer(disabled).shadowCollectionProvider, isNull);
    });

    test('external provider remains priority even when internal flags are off',
        () async {
      ShadowRuntimeInstructionCollection? provider() {
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
        enableStaticPlacedElementShadows: false,
      );

      game.onGameResize(Vector2(64, 64));
      await game.onLoad();
      game.update(0);
      final background = _backgroundLayer(game);
      final foreground = _foregroundLayer(game);

      expect(background.shadowCollectionProvider, same(provider));
      expect(foreground.shadowCollectionProvider, isNull);
      expect(
          background.shadowCollectionProvider!()!.groundStatic, hasLength(1));
    });

    test(
        'connected map background receives static shadows but no actor shadows',
        () async {
      final connected = _bundle(mapId: 'connected-static-map');
      final game = PlayableMapGame(
        bundle: _bundle(
          mapId: 'active-static-map',
          connectionTargetMapId: 'connected-static-map',
        ),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        runtimeMapBundleLoader: ({required projectFilePath, required mapId}) {
          expect(mapId, 'connected-static-map');
          return Future.value(connected);
        },
      );

      game.onGameResize(Vector2(320, 160));
      await game.onLoad();
      await _pumpUntil(
          game, () => game.debugIsMapLoaded('connected-static-map'));
      game.update(0);
      final activeProvider =
          game.debugShadowCollectionProviderForMap('active-static-map')!;
      final connectedProvider =
          game.debugShadowCollectionProviderForMap('connected-static-map')!;

      expect(activeProvider()!.groundStatic, hasLength(1));
      expect(activeProvider()!.actorContact, hasLength(1));
      expect(connectedProvider()!.groundStatic, hasLength(1));
      expect(connectedProvider()!.actorContact, isEmpty);
    });

    test('RuntimeMapGame remains passive for static placed element shadows',
        () async {
      final game = RuntimeMapGame(bundle: _bundle());

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      final layer = game.world.children.whereType<MapLayersComponent>().single;

      expect(game.shadowCollectionProvider, isNull);
      expect(layer.shadowCollectionProvider, isNull);
    });
  });
}

RuntimeMapBundle _bundle({
  String mapId = 'static-shadow-test',
  ProjectShadowCatalog? shadowCatalog,
  Object? elementShadow = _defaultElementShadow,
  MapPlacedElementShadowOverride? placedOverride,
  String? connectionTargetMapId,
}) {
  final tileLayer = List<int>.filled(16, 0);
  final connections = <MapConnection>[
    if (connectionTargetMapId != null)
      MapConnection(
        direction: MapConnectionDirection.east,
        targetMapId: connectionTargetMapId,
      ),
  ];
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Runtime Static Shadow Test',
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      settings: const ProjectSettings(
        tileWidth: 16,
        tileHeight: 16,
        displayScale: 2,
        defaultPlayerCharacterId: 'player',
      ),
      elements: [
        ProjectElementEntry(
          id: 'tree',
          name: 'Tree',
          tilesetId: 'props',
          categoryId: 'nature',
          frames: const [
            TilesetVisualFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 3),
            ),
          ],
          shadow: identical(elementShadow, _defaultElementShadow)
              ? ProjectElementShadowConfig(
                  castsShadow: true,
                  shadowProfileId: 'soft-tree',
                )
              : elementShadow as ProjectElementShadowConfig?,
        ),
      ],
      characters: const [
        ProjectCharacterEntry(
          id: 'player',
          name: 'Player',
          tilesetId: 'player',
          frameWidth: 2,
          frameHeight: 2,
        ),
      ],
      surfaceCatalog: ProjectSurfaceCatalog(),
      shadowCatalog: shadowCatalog ?? _shadowCatalog(),
    ),
    map: MapData(
      id: mapId,
      name: mapId,
      size: const GridSize(width: 4, height: 4),
      layers: [
        MapLayer.tile(
          id: 'decor',
          name: 'Decor',
          tilesetId: 'base',
          tiles: tileLayer,
        ),
      ],
      placedElements: [
        MapPlacedElement(
          id: 'tree-1',
          layerId: 'decor',
          elementId: 'tree',
          pos: const GridPos(x: 1, y: 1),
          shadowOverride: placedOverride,
        ),
      ],
      entities: const [
        MapEntity(
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
      ],
      connections: connections,
      mapMetadata: const MapMetadata(defaultSpawnId: 'spawn'),
    ),
    projectRootDirectory: '/tmp/runtime-static-shadow-test',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

const Object _defaultElementShadow = Object();

ProjectShadowCatalog _shadowCatalog() {
  return ProjectShadowCatalog(
    profiles: [
      ProjectShadowProfile(
        id: 'soft-tree',
        name: 'Soft Tree',
        mode: ShadowCasterMode.ellipse,
        renderPass: ShadowRenderPass.groundStatic,
        opacity: 0.35,
      ),
    ],
  );
}

Future<Map<String, RuntimeTilesetImage>> _emptyImageLoader(
  Map<String, String> absolutePathByTilesetId, {
  Map<String, TilesetTransparentColor> transparentColorByTilesetId =
      const <String, TilesetTransparentColor>{},
}) async {
  return const <String, RuntimeTilesetImage>{};
}

MapLayersComponent _backgroundLayer(PlayableMapGame game) {
  return game.world.children.whereType<MapLayersComponent>().singleWhere(
        (layer) => layer.renderPass == MapLayerRenderPass.background,
      );
}

MapLayersComponent _foregroundLayer(PlayableMapGame game) {
  return game.world.children.whereType<MapLayersComponent>().singleWhere(
        (layer) => layer.renderPass == MapLayerRenderPass.foreground,
      );
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

Future<void> _pumpUntil(
  PlayableMapGame game,
  bool Function() condition,
) async {
  for (var i = 0; i < 20; i += 1) {
    if (condition()) {
      return;
    }
    game.update(0);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Condition was not met');
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

bool _hasDifferentPolygonPoints(
  ShadowRuntimeRenderInstruction actual,
  ShadowRuntimeRenderInstruction baseline,
) {
  if (actual.polygonPoints.length != baseline.polygonPoints.length) {
    return true;
  }
  for (var i = 0; i < actual.polygonPoints.length; i += 1) {
    final actualPoint = actual.polygonPoints[i];
    final baselinePoint = baseline.polygonPoints[i];
    if (actualPoint.worldX != baselinePoint.worldX ||
        actualPoint.worldY != baselinePoint.worldY) {
      return true;
    }
  }
  return false;
}
