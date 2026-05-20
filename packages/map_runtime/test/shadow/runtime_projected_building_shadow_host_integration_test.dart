import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:map_runtime/src/presentation/flame/playable_map_game.dart';
import 'package:map_runtime/src/presentation/flame/runtime_map_game.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('runtime projected building shadow host integration', () {
    test(
        'PlayableMapGame provides projected building shadows to the background layer',
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

      expect(background.shadowCollectionProvider, isNotNull);
      expect(foreground.shadowCollectionProvider, isNull);
      expect(collection.groundStatic, hasLength(1));
      expect(collection.actorContact, isEmpty);

      final instruction = collection.groundStatic.single;
      _expectProjectedBuildingInstruction(instruction);
    });

    test(
        'PlayableMapGame does not create projected building shadows without projected config',
        () async {
      final game = PlayableMapGame(
        bundle: _bundle(withProjectedConfig: false),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);

      expect(_backgroundLayer(game).shadowCollectionProvider!(), isNull);
    });

    test(
        'PlayableMapGame skips projected building shadow when preset is missing',
        () async {
      final game = PlayableMapGame(
        bundle: _bundle(includeProjectedPreset: false),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);

      expect(_backgroundLayer(game).shadowCollectionProvider!(), isNull);
    });

    test(
        'PlayableMapGame suppresses same-element V1 static shadow when projected building shadow is resolvable',
        () async {
      final game = PlayableMapGame(
        bundle: _bundle(withV1Shadow: true),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);
      final collection = _backgroundLayer(game).shadowCollectionProvider!()!;

      expect(collection.groundStatic, hasLength(1));
      expect(_projectedBuildingInstructions(collection), hasLength(1));
      expect(_legacyStaticInstructions(collection), isEmpty);
    });

    test('PlayableMapGame keeps V1 static shadows for elements without V2',
        () async {
      final game = PlayableMapGame(
        bundle: _bundle(
          withV1Shadow: true,
          includeLegacyOnlyElement: true,
        ),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);
      final groundStatic =
          _backgroundLayer(game).shadowCollectionProvider!()!.groundStatic;

      expect(groundStatic, hasLength(2));
      _expectProjectedBuildingInstruction(groundStatic[0]);
      _expectLegacyStaticInstruction(groundStatic[1]);
    });

    test(
        'PlayableMapGame keeps external shadow provider priority over internal projected shadows',
        () async {
      ShadowRuntimeInstructionCollection? provider() {
        return ShadowRuntimeInstructionCollection(
          instructions: [
            _externalShadow(),
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

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);
      final background = _backgroundLayer(game);
      final foreground = _foregroundLayer(game);
      final collection = background.shadowCollectionProvider!()!;

      expect(background.shadowCollectionProvider, same(provider));
      expect(foreground.shadowCollectionProvider, isNull);
      expect(collection.instructions, [_externalShadow()]);
      expect(_projectedBuildingInstructions(collection), isEmpty);
    });

    test(
        'PlayableMapGame disables projected building ground shadows when static placed shadows are disabled',
        () async {
      final game = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
        enableStaticPlacedElementShadows: false,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);

      expect(_backgroundLayer(game).shadowCollectionProvider, isNull);
    });

    test('RuntimeMapGame remains passive for projected building shadows',
        () async {
      final game = RuntimeMapGame(bundle: _bundle());

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      final layer = game.world.children.whereType<MapLayersComponent>().single;

      expect(game.shadowCollectionProvider, isNull);
      expect(layer.shadowCollectionProvider, isNull);
    });

    test(
        'projected building render integration does not call diagnostics or auto projection',
        () {
      final source = File(
        'lib/src/presentation/flame/playable_map_game.dart',
      ).readAsStringSync();
      final forbiddenSnippets = [
        'diagnoseProjectedBuilding' 'Shadows',
        'applyElementAutoShadow' 'PolicyToProject',
        'generic' 'Projection',
        'resolveProjected' 'StaticShadowGeometry',
        'resolveStaticShadowFamily' 'ProjectionSpec',
        'static_shadow_family' '_projection',
        'element_auto_shadow' '_policy',
      ];

      for (final snippet in forbiddenSnippets) {
        expect(source, isNot(contains(snippet)));
      }
    });
  });
}

RuntimeMapBundle _bundle({
  bool withProjectedConfig = true,
  bool includeProjectedPreset = true,
  bool withV1Shadow = false,
  bool includeLegacyOnlyElement = false,
}) {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Runtime Projected Building Shadow Test',
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
          id: 'building',
          name: 'Building',
          tilesetId: 'props',
          categoryId: 'building',
          frames: const [
            TilesetVisualFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 3),
            ),
          ],
          shadow: withV1Shadow
              ? ProjectElementShadowConfig(
                  castsShadow: true,
                  shadowProfileId: 'legacy-shadow',
                )
              : null,
          projectedBuildingShadow:
              withProjectedConfig ? _projectedConfig() : null,
        ),
        if (includeLegacyOnlyElement)
          ProjectElementEntry(
            id: 'legacy-building',
            name: 'Legacy Building',
            tilesetId: 'props',
            categoryId: 'building',
            frames: const [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 2),
              ),
            ],
            shadow: ProjectElementShadowConfig(
              castsShadow: true,
              shadowProfileId: 'legacy-shadow',
            ),
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
      shadowCatalog: withV1Shadow || includeLegacyOnlyElement
          ? _legacyShadowCatalog()
          : const ProjectShadowCatalog.empty(),
      projectedBuildingShadowCatalog: includeProjectedPreset
          ? ProjectBuildingShadowPresetCatalog(presets: [_preset()])
          : const ProjectBuildingShadowPresetCatalog.empty(),
    ),
    map: MapData(
      id: 'projected-building-shadow-test',
      name: 'Projected Building Shadow Test',
      size: const GridSize(width: 4, height: 4),
      layers: [
        const MapLayer.tile(
          id: 'objects',
          name: 'Objects',
          tilesetId: 'props',
          tiles: <int>[],
        ),
      ],
      placedElements: [
        const MapPlacedElement(
          id: 'building-1',
          layerId: 'objects',
          elementId: 'building',
          pos: GridPos(x: 1, y: 2),
        ),
        if (includeLegacyOnlyElement)
          const MapPlacedElement(
            id: 'legacy-building-1',
            layerId: 'objects',
            elementId: 'legacy-building',
            pos: GridPos(x: 2, y: 2),
          ),
      ],
      entities: [
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
      ],
      mapMetadata: const MapMetadata(defaultSpawnId: 'spawn'),
    ),
    projectRootDirectory: '/tmp/runtime-projected-building-shadow-test',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

ProjectElementProjectedBuildingShadowConfig _projectedConfig() {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: true,
    presetId: 'shadow-a',
    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
    localOffset: ProjectedShadowOffset(x: 0, y: 0),
  );
}

ProjectBuildingShadowPreset _preset() {
  return ProjectBuildingShadowPreset(
    id: 'shadow-a',
    name: 'Shadow A',
    direction: ProjectedShadowDirection(x: 1, y: 0),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0.5,
      nearWidthRatio: 1,
      farWidthRatio: 0.5,
    ),
    appearance: ProjectedShadowAppearance(
      opacity: 0.18,
      colorHexRgb: '123ABC',
    ),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
  );
}

ProjectShadowCatalog _legacyShadowCatalog() {
  return ProjectShadowCatalog(
    profiles: [
      ProjectShadowProfile(
        id: 'legacy-shadow',
        name: 'Legacy Shadow',
        mode: ShadowCasterMode.ellipse,
        renderPass: ShadowRenderPass.groundStatic,
        opacity: 0.35,
        colorHexRgb: '010203',
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

List<ShadowRuntimeRenderInstruction> _projectedBuildingInstructions(
  ShadowRuntimeInstructionCollection collection,
) {
  return collection.groundStatic
      .where(
        (instruction) =>
            instruction.shape == ShadowRuntimeShapeKind.projectedPolygon &&
            instruction.colorHexRgb == '123ABC' &&
            instruction.opacity == 0.18,
      )
      .toList(growable: false);
}

List<ShadowRuntimeRenderInstruction> _legacyStaticInstructions(
  ShadowRuntimeInstructionCollection collection,
) {
  return collection.groundStatic
      .where(
        (instruction) =>
            instruction.colorHexRgb == '010203' && instruction.opacity == 0.35,
      )
      .toList(growable: false);
}

void _expectProjectedBuildingInstruction(
  ShadowRuntimeRenderInstruction instruction,
) {
  expect(instruction.shape, ShadowRuntimeShapeKind.projectedPolygon);
  expect(instruction.renderPass, ShadowRenderPass.groundStatic);
  expect(instruction.opacity, 0.18);
  expect(instruction.colorHexRgb, '123ABC');
  expect(instruction.polygonPoints, hasLength(4));
  _expectPointClose(instruction.polygonPoints[0], x: 64, y: 128);
  _expectPointClose(instruction.polygonPoints[1], x: 64, y: 192);
  _expectPointClose(instruction.polygonPoints[2], x: 112, y: 176);
  _expectPointClose(instruction.polygonPoints[3], x: 112, y: 144);
}

void _expectLegacyStaticInstruction(
  ShadowRuntimeRenderInstruction instruction,
) {
  expect(instruction.renderPass, ShadowRenderPass.groundStatic);
  expect(instruction.opacity, 0.35);
  expect(instruction.colorHexRgb, '010203');
}

void _expectPointClose(
  ShadowRuntimePoint point, {
  required double x,
  required double y,
}) {
  expect(point.worldX, closeTo(x, 0.000001));
  expect(point.worldY, closeTo(y, 0.000001));
}

ShadowRuntimeRenderInstruction _externalShadow() {
  return ShadowRuntimeRenderInstruction(
    shape: ShadowRuntimeShapeKind.ellipse,
    renderPass: ShadowRenderPass.groundStatic,
    worldLeft: 4,
    worldTop: 4,
    width: 24,
    height: 24,
    opacity: 1,
    colorHexRgb: 'FF0000',
  );
}
