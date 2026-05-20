import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:map_runtime/src/presentation/flame/playable_map_game.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('runtime projected building shadow visual POC', () {
    test(
        'runtime projected building visual POC renders host-provided V2 polygon pixels',
        () async {
      final collection = await _hostShadowCollection();

      expect(collection, isNotNull);
      final v2Instructions = _projectedBuildingInstructions(collection!);
      expect(v2Instructions, hasLength(1));
      final instruction = v2Instructions.single;
      _expectProjectedBuildingInstruction(instruction);

      final image = await _renderGroundStaticShadows(
        collection,
        width: 160,
        height: 224,
      );

      expect(await _alphaAt(image, 80, 150), greaterThan(0));
      expect(await _alphaAt(image, 10, 10), 0);
    });

    test(
        'runtime projected building visual POC suppresses same-element V1 when V2 is resolvable',
        () async {
      final collection = await _hostShadowCollection(withV1Shadow: true);
      final groundStatic = collection!.groundStatic;

      expect(groundStatic, hasLength(1));
      _expectProjectedBuildingInstruction(groundStatic.single);
      expect(_legacyStaticInstructions(collection), isEmpty);
    });

    test(
        'runtime projected building visual POC does not use screenshots '
        'base'
        'lines or auto projection', () {
      final source = File(
        'test/shadow/runtime_projected_building_shadow_visual_poc_test.dart',
      ).readAsStringSync();
      final forbiddenSnippets = [
        'matches' 'GoldenFile',
        'SHADOW_' 'SCREENSHOT',
        'sel' 'brume',
        'base' 'line_manifest' '.json',
        'reports/shadows/base' 'lines',
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

Future<ShadowRuntimeInstructionCollection?> _hostShadowCollection({
  bool withV1Shadow = false,
}) async {
  final game = PlayableMapGame(
    bundle: _bundle(withV1Shadow: withV1Shadow),
    projectFilePath: '/tmp/project.json',
    runtimeTilesetImageLoader: _emptyImageLoader,
    enableActorContactShadows: false,
  );

  game.onGameResize(Vector2(160, 224));
  await game.onLoad();
  game.update(0);
  final background = _backgroundLayer(game);

  expect(background.shadowCollectionProvider, isNotNull);
  return background.shadowCollectionProvider!();
}

RuntimeMapBundle _bundle({
  bool withV1Shadow = false,
}) {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Runtime Projected Building Shadow Visual POC',
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
          projectedBuildingShadow: _projectedConfig(),
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
      shadowCatalog: withV1Shadow
          ? _legacyShadowCatalog()
          : const ProjectShadowCatalog.empty(),
      projectedBuildingShadowCatalog: ProjectBuildingShadowPresetCatalog(
        presets: [_preset()],
      ),
    ),
    map: const MapData(
      id: 'projected-building-shadow-visual-poc',
      name: 'Projected Building Shadow Visual POC',
      size: GridSize(width: 4, height: 4),
      layers: [
        MapLayer.tile(
          id: 'objects',
          name: 'Objects',
          tilesetId: 'props',
          tiles: <int>[],
        ),
      ],
      placedElements: [
        MapPlacedElement(
          id: 'building-1',
          layerId: 'objects',
          elementId: 'building',
          pos: GridPos(x: 1, y: 2),
        ),
      ],
      entities: [
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
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn'),
    ),
    projectRootDirectory: '/tmp/runtime-projected-building-shadow-visual-poc',
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

List<ShadowRuntimeRenderInstruction> _projectedBuildingInstructions(
  ShadowRuntimeInstructionCollection collection,
) {
  return collection.groundStatic
      .where(
        (instruction) =>
            instruction.shape == ShadowRuntimeShapeKind.projectedPolygon &&
            instruction.renderPass == ShadowRenderPass.groundStatic &&
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

void _expectPointClose(
  ShadowRuntimePoint point, {
  required double x,
  required double y,
}) {
  expect(point.worldX, closeTo(x, 0.000001));
  expect(point.worldY, closeTo(y, 0.000001));
}

Future<int> _alphaAt(ui.Image image, int x, int y) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final offset = (y * image.width + x) * 4;
  return data!.getUint8(offset + 3);
}

Future<ui.Image> _renderGroundStaticShadows(
  ShadowRuntimeInstructionCollection collection, {
  required int width,
  required int height,
}) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  const ShadowRuntimeRenderer().renderCollectionPass(
    canvas,
    collection,
    ShadowRenderPass.groundStatic,
  );
  return recorder.endRecording().toImage(width, height);
}
