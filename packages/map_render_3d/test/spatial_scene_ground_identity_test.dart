import 'dart:typed_data';

import 'package:flame_3d/core.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/resources.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_ground.dart';
import 'package:map_render_3d/src/spatial_pixel_material.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final animated in [false, true]) {
    for (final cells in [4, 256]) {
      test(
        'cached ground skips visual comparisons: $cells cells, animated=$animated',
        () async {
          final fixture = _Fixture(cells: cells, animated: animated);
          await fixture.load();
          addTearDown(fixture.dispose);
          final ground = fixture.game.grounds.single;
          final visuals = ground.visuals;
          final components = List.of(ground.components);
          final comparisons = ground.debugVisualComparisons;
          expect(visuals, hasLength(cells));
          for (var sample = 0; sample < 300; sample++) {
            expect(ground.resolve(sample % 30), isFalse);
            expect(ground.visuals, same(visuals));
          }
          expect(ground.components, orderedEquals(components));
          expect(ground.debugVisualComparisons - comparisons, 0);
        },
      );
    }
  }

  test(
    'same cached visuals still rebuild for forced geometry and initialization',
    () async {
      final fixture = _Fixture();
      await fixture.load();
      addTearDown(fixture.dispose);
      final ground = fixture.game.grounds.single;
      final visuals = ground.visuals;
      final first = List.of(ground.components);
      final colors = [
        for (final component in ground.underlays)
          for (final surface in component.mesh.surfaces)
            (surface.material as UnlitMaterial).albedoColor,
      ];
      expect(colors, isNotEmpty);
      expect(ground.resolve(0, forceGeometry: true), isTrue);
      expect(ground.visuals, same(visuals));
      expect(ground.components.first, isNot(same(first.first)));
      expect([
        for (final component in ground.underlays)
          for (final surface in component.mesh.surfaces)
            (surface.material as UnlitMaterial).albedoColor,
      ], colors);
      final forced = List.of(ground.components);
      ground.initialized = false;
      expect(ground.resolve(0), isTrue);
      expect(ground.initialized, isTrue);
      expect(ground.visuals, same(visuals));
      expect(ground.components.first, isNot(same(forced.first)));
      expect(ground.debugVisualComparisons, 0);
    },
  );

  test(
    'missing textures block cached forced rebuild until they are restored',
    () async {
      final fixture = _Fixture();
      await fixture.load();
      addTearDown(fixture.dispose);
      final ground = fixture.game.grounds.single;
      final components = List.of(ground.components);
      final texture = ground.textures.remove('ground')!;
      ground.initialized = false;
      expect(ground.resolve(0, forceGeometry: true), isFalse);
      expect(ground.initialized, isFalse);
      expect(ground.components, orderedEquals(components));
      ground.textures['ground'] = texture;
      expect(ground.resolve(0, forceGeometry: true), isTrue);
      expect(ground.initialized, isTrue);
      expect(ground.components.first, isNot(same(components.first)));
    },
  );

  for (final changedImage in [false, true]) {
    test(
      'new frame keeps UV and image changes live: image change=$changedImage',
      () async {
        final fixture = _Fixture(changedImage: changedImage);
        await fixture.load();
        addTearDown(fixture.dispose);
        final ground = fixture.game.grounds.single;
        await fixture.game.groundTextureCache[changedImage
            ? 'other'
            : 'ground'];
        final visuals = ground.visuals;
        final component = ground.components.first;
        final surface = component.mesh.surfaces.single;
        final positions = List.of(surface.positions);
        expect(ground.resolve(33), isTrue);
        expect(ground.visuals, isNot(same(visuals)));
        expect(ground.visuals.first.visual.sourceRect.x, 32);
        expect(
          ground.visuals.first.visual.tilesetId,
          changedImage ? 'other' : 'ground',
        );
        expect(ground.debugVisualComparisons, fixture.cells);
        expect(ground.components.first, same(component));
        expect(surface.positions, positions);
        final material = surface.material as SpatialPixelMaterial;
        expect(material.uvTransformU.z, .5);
        expect(
          material.albedoTexture,
          same(ground.textures[changedImage ? 'other' : 'ground']),
        );
        expect(ground.resolve(34), isFalse);
        expect(ground.debugVisualComparisons, fixture.cells);
      },
    );
  }

  test('changed visual bounds rebuild geometry and a new opacity plan updates materials', () async {
    final fixture = _Fixture(pixelOffset: 8);
    await fixture.load();
    addTearDown(fixture.dispose);
    final ground = fixture.game.grounds.single;
    final visual = ground.visuals.first.visual;
    final component = ground.components.first;
    expect(ground.resolve(33), isTrue);
    expect(
      ground.visuals.first.visual.geometry.visualBounds.left,
      visual.geometry.visualBounds.left + .25,
    );
    expect(ground.components.first, isNot(same(component)));
    expect(ground.components.first.mesh.surfaces.single.positions.first, .25);
    final map = fixture.map.copyWith(
      layers: [
        (fixture.map.layers.single as SmartTileLayer).copyWith(opacity: .25),
      ],
    );
    ground.plan = SpatialGroundPlan(map, fixture.project);
    expect(ground.resolve(33), isTrue);
    expect(ground.visuals.every((item) => item.opacity == .25), isTrue);
    expect(
      (ground.components.first.mesh.surfaces.single.material
              as SpatialPixelMaterial)
          .albedoColor
          .a,
      .25,
    );
  });
}

final class _Fixture {
  _Fixture({
    this.cells = 4,
    bool animated = true,
    bool changedImage = false,
    int pixelOffset = 0,
  }) {
    final source = animated
        ? const SmartTileVisualSource.animation(animationId: 'wave')
        : const SmartTileVisualSource.frame(
            frame: SmartTileFrameRef(atlasId: 'frame-0', column: 0, row: 0),
          );
    map = MapData(
      id: 'map',
      name: 'Map',
      size: GridSize(width: cells, height: 1),
      spatialScene: MapSpatialScene(width: cells, depth: 1),
      layers: [
        SmartTileLayer(
          id: 'ground',
          name: 'Ground',
          presetId: 'ground',
          opacity: .6,
          usage: SmartTileUsage.terrain,
          materialPalette: const ['', 'ground'],
          field: SmartTileField.cell(semanticCells: List.filled(cells, 1)),
        ),
      ],
    );
    project = ProjectManifest(
      name: 'Ground identity',
      maps: const [],
      settings: const ProjectSettings(tileWidth: 32, tileHeight: 32),
      tilesets: const [
        ProjectTilesetEntry(
          id: 'ground',
          name: 'Ground',
          relativePath: 'ground.png',
        ),
        ProjectTilesetEntry(
          id: 'other',
          name: 'Other',
          relativePath: 'other.png',
        ),
      ],
      smartTileCatalog: ProjectSmartTileCatalog(
        materials: const [
          ProjectSmartTileMaterial(
            id: 'ground',
            name: 'Ground',
            connectionGroupId: 'ground',
          ),
        ],
        atlases: [
          for (var frame = 0; frame < 2; frame++)
            ProjectSmartTileAtlas(
              id: 'frame-$frame',
              name: 'Frame $frame',
              tilesetId: changedImage && frame == 1 ? 'other' : 'ground',
              originX: frame * 32,
              pixelOffsetX: frame * pixelOffset,
              columns: 1,
              rows: 1,
            ),
        ],
        animations: [
          ProjectSmartTileAnimation(
            id: 'wave',
            name: 'Wave',
            frames: [
              for (var frame = 0; frame < 2; frame++)
                ProjectSmartTileAnimationFrame(
                  frame: SmartTileFrameRef(
                    atlasId: 'frame-$frame',
                    column: 0,
                    row: 0,
                  ),
                  durationMs: 33,
                ),
            ],
          ),
        ],
        presets: [
          ProjectSmartTilePreset(
            id: 'ground',
            name: 'Ground',
            usage: SmartTileUsage.terrain,
            topology: SmartTileTopology.uniform,
            templateHint: SmartTileTemplateHint.simple,
            coveragePolicy: SmartTileCoveragePolicy.sparse,
            coverageProfile: const SmartTileCoverageProfile(
              mode: SmartTileCoverageMode.template,
            ),
            transformPolicy: const SmartTileTransformPolicy(),
            defaultMaterialId: 'ground',
            allowedMaterialIds: const ['ground'],
            rules: [
              SmartTileRule(
                id: 'ground',
                centerMatch: const SmartTileSlotMatch.material('ground'),
                candidates: [
                  SmartTileCandidate(
                    id: 'ground',
                    parts: [SmartTileVisualPart(source: source)],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  final int cells;
  late final MapData map;
  late final ProjectManifest project;
  final controller = SpatialSceneController();
  late final SpatialSceneGame game;

  Future<void> load() async {
    _UnusedBackend();
    final image = Uint8List.fromList(
      img.encodePng(img.Image(width: 64, height: 32)),
    );
    game =
        SpatialSceneGame(
            SpatialSceneView(
              scene: map.spatialScene!,
              groundMap: map,
              groundProject: project,
              models: const [],
              loadModel: (_) async => throw StateError('Unexpected model load'),
              loadGroundImage: (_) async => image,
              controller: controller,
              onCell: (_, _) {},
              background: const Color(0xff000000),
              ground: const Color(0xff224422),
              edge: const Color(0xff111111),
              errorBuilder: (_, _) => const SizedBox(),
            ),
            onPreviewStatus: (_) {},
            onSurfaceChanged: () {},
          )
          ..onGameResize(Vector2(200, 200))
          ..sceneReady = true;
    expect(await game.refresh(), isTrue);
  }

  void dispose() {
    game.onRemove();
    controller.dispose();
  }
}

final class _UnusedBackend extends GpuBackend {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}
