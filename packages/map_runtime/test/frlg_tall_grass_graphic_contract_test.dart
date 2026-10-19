import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:map_runtime/src/presentation/flame/smart_tile_actor_occlusion_component.dart';
import 'package:map_runtime/src/presentation/flame/smart_tile_animation_activation_controller.dart';

import 'surface/surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'FRLG grass holds its final entry frame while the player occupies it',
    () async {
      final image = await runtimeTilesetImage(_colors);
      addTearDown(image.dispose);
      final map = MapData.fromJson(_map.toJson());
      final manifest = ProjectManifest.fromJson(_manifest.toJson());
      final controller = SmartTileAnimationActivationController(
        map: map,
        catalog: manifest.smartTileCatalog,
      );
      final bundle = _bundle(map, manifest);
      final ground = MapLayersComponent(
        bundle: bundle,
        tileImagesByTilesetId: {'atlas': image},
        smartTileAnimationController: controller,
      );
      final occlusion = SmartTileActorOcclusionLayerCollection(
        bundle: bundle,
        tileImagesByTilesetId: {'atlas': image},
        smartTileAnimationController: controller,
      );

      Future<void> expectPixels(Color first, Color second) async {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        ground.render(canvas);
        for (final row in occlusion.rows) {
          row.render(canvas);
        }
        final picture = recorder.endRecording();
        final rendered = await picture.toImage(64, 32);
        picture.dispose();
        try {
          expect(await pixelAt(rendered, 16, 16), _rgba(first));
          expect(await pixelAt(rendered, 48, 16), _rgba(second));
        } finally {
          rendered.dispose();
        }
      }

      void advance(int milliseconds) {
        final dt = milliseconds / 1000;
        controller.update(dt);
        ground.update(dt);
        occlusion.update(dt);
      }

      await expectPixels(_colors[5], _colors[5]);
      controller.resetPlayerOccupancy(const GridPos(x: 0, y: 0));
      advance(1);
      await expectPixels(_colors[0], _colors[5]);
      controller.resetPlayerOccupancy(null);
      advance(1);
      await expectPixels(_colors[5], _colors[5]);
      controller.onPlayerEnteredCell(const GridPos(x: 0, y: 0));
      advance(1);
      await expectPixels(_colors[1], _colors[5]);
      for (final step in <({int milliseconds, int column})>[
        (milliseconds: 167, column: 2),
        (milliseconds: 166, column: 3),
        (milliseconds: 167, column: 4),
        (milliseconds: 167, column: 0),
      ]) {
        advance(step.milliseconds);
        await expectPixels(_colors[step.column], _colors[5]);
      }
      advance(166);
      await expectPixels(_colors[0], _colors[5]);
      advance(1000);
      await expectPixels(_colors[0], _colors[5]);
      controller.onPlayerEnteredCell(const GridPos(x: 0, y: 0));
      advance(1);
      await expectPixels(_colors[1], _colors[5]);

      final grass = map.layers.first as SmartTileLayer;
      final erased = applySmartTileMapMaterialGesture(
        map,
        layer: grass,
        catalog: manifest.smartTileCatalog,
        cells: const [GridPos(x: 0, y: 0)],
        materialId: null,
      );
      final reopened = MapData.fromJson(erased.toJson());
      expect(reopened.layers.last, map.layers.last);
      expect(
        (reopened.layers.first as SmartTileLayer).encounterBehavior,
        isNull,
      );
      final erasedGround = MapLayersComponent(
        bundle: _bundle(reopened, manifest),
        tileImagesByTilesetId: {'atlas': image},
      );
      final recorder = ui.PictureRecorder();
      erasedGround.render(Canvas(recorder));
      final picture = recorder.endRecording();
      final rendered = await picture.toImage(64, 32);
      picture.dispose();
      try {
        expect(await pixelAt(rendered, 16, 16), _rgba(_colors[6]));
        expect(await pixelAt(rendered, 48, 16), _rgba(_colors[5]));
      } finally {
        rendered.dispose();
      }
    },
  );
}

List<int> _rgba(Color color) => [
  (color.r * 255).round(),
  (color.g * 255).round(),
  (color.b * 255).round(),
  (color.a * 255).round(),
];

const _colors = <Color>[
  Color(0xFFFF0000),
  Color(0xFFFF8000),
  Color(0xFFFFFF00),
  Color(0xFF00FFFF),
  Color(0xFF8000FF),
  Color(0xFF00A000),
  Color(0xFF000080),
];

RuntimeMapBundle _bundle(MapData map, ProjectManifest manifest) =>
    RuntimeMapBundle(
      manifest: manifest,
      map: map,
      projectRootDirectory: '/tmp/frlg-tall-grass-graphic-contract',
      tilesetAbsolutePathsById: const {},
    );

const _map = MapData(
  id: 'map',
  name: 'Graphic contract',
  version: ProjectVersion.v8,
  size: GridSize(width: 2, height: 1),
  layers: [
    SmartTileLayer(
      id: 'grass',
      name: 'Hautes herbes',
      presetId: 'grass',
      usage: SmartTileUsage.path,
      animationActivation: SmartTileAnimationActivation.onEnter,
      materialPalette: ['', 'grass'],
      field: SmartTileField.cell(semanticCells: [1, 1]),
    ),
    SmartTileLayer(
      id: 'terrain',
      name: 'Terrain conservé',
      presetId: 'terrain',
      usage: SmartTileUsage.terrain,
      materialPalette: ['', 'terrain'],
      field: SmartTileField.cell(semanticCells: [1, 1]),
    ),
  ],
);

final _manifest = ProjectManifest(
  name: 'FRLG grass graphic contract',
  version: ProjectVersion.v8,
  maps: const [],
  tilesets: const [
    ProjectTilesetEntry(
      id: 'atlas',
      name: 'Synthetic test colors',
      relativePath: 'atlas.png',
    ),
  ],
  settings: const ProjectSettings(
    tileWidth: 32,
    tileHeight: 32,
    displayScale: 1,
  ),
  smartTileCatalog: ProjectSmartTileCatalog(
    atlases: const [
      ProjectSmartTileAtlas(
        id: 'atlas',
        name: 'Atlas',
        tilesetId: 'atlas',
        columns: 7,
        rows: 1,
      ),
    ],
    materials: const [
      ProjectSmartTileMaterial(
        id: 'grass',
        name: 'Hautes herbes',
        connectionGroupId: 'grass',
        pathSurfaceKind: PathSurfaceKind.tallGrass,
      ),
      ProjectSmartTileMaterial(
        id: 'terrain',
        name: 'Terrain',
        connectionGroupId: 'terrain',
      ),
    ],
    animations: [
      ProjectSmartTileAnimation(
        id: 'entry',
        name: 'Herbe au passage',
        loop: SmartTileAnimationLoop.once,
        frames: [
          for (final frame in <({int column, int duration})>[
            (column: 1, duration: 167),
            (column: 2, duration: 166),
            (column: 3, duration: 167),
            (column: 4, duration: 167),
            (column: 0, duration: 166),
          ])
            ProjectSmartTileAnimationFrame(
              frame: SmartTileFrameRef(
                atlasId: 'atlas',
                column: frame.column,
                row: 0,
              ),
              durationMs: frame.duration,
            ),
        ],
      ),
    ],
    presets: [
      _preset('grass', SmartTileUsage.path, const [
        SmartTileVisualPart(
          source: SmartTileVisualSource.frame(
            frame: SmartTileFrameRef(atlasId: 'atlas', column: 5, row: 0),
          ),
        ),
        SmartTileVisualPart(
          source: SmartTileVisualSource.animation(animationId: 'entry'),
          channel: SmartTileRenderChannel.actorOcclusion,
        ),
      ]),
      _preset('terrain', SmartTileUsage.terrain, const [
        SmartTileVisualPart(
          source: SmartTileVisualSource.frame(
            frame: SmartTileFrameRef(atlasId: 'atlas', column: 6, row: 0),
          ),
        ),
      ]),
    ],
  ),
);

ProjectSmartTilePreset _preset(
  String id,
  SmartTileUsage usage,
  List<SmartTileVisualPart> parts,
) => ProjectSmartTilePreset(
  id: id,
  name: id,
  usage: usage,
  topology: SmartTileTopology.uniform,
  coveragePolicy: SmartTileCoveragePolicy.sparse,
  coverageProfile: const SmartTileCoverageProfile(
    mode: SmartTileCoverageMode.template,
  ),
  transformPolicy: const SmartTileTransformPolicy(),
  defaultMaterialId: id,
  allowedMaterialIds: [id],
  rules: [
    SmartTileRule(
      id: id,
      centerMatch: SmartTileSlotMatch.material(id),
      candidates: [SmartTileCandidate(id: id, parts: parts)],
    ),
  ],
);
