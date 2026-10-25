import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame_3d/core.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flutter/widgets.dart' hide Matrix4;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_actor_visual.dart';
import 'package:map_render_3d/src/adaptive_camera.dart';
import 'package:map_render_3d/src/spatial_scene_neighbor.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'visual order changes replace active raster only and retain scene state',
    () async {
      final h = await _Harness.create();
      addTearDown(h.dispose);
      final game = h.game;
      final model = game.modelComponents['lamp']!.component;
      model.playback.clock = .375;
      final playback = model.playback;
      final actor = game.actors['hero']!.mesh;
      final lights = game.pointLightBindings;
      final lighting = game.authoredLighting;
      final neighbor = game.sceneChunks['neighbor'];
      final generation = game.generation;
      final reads = h.reads;
      final initialRaster = game.grounds.single.components.toList();
      final initialOrder = game.grounds.single.visuals
          .map((v) => v.visual.sourceRect.x)
          .toList();
      final reordered = h.map.copyWith(layers: h.map.layers.reversed.toList());
      game.configuration = h.configuration(reordered);
      expect(await game.refresh(), isTrue);
      expect(game.generation, generation);
      expect(game.visualOrderUpdates, 1);
      expect(game.visualGroundRebuilds, 1);
      expect(
        game.grounds.single.visuals.map((v) => v.visual.sourceRect.x),
        initialOrder.reversed,
      );
      expect(
        game.grounds.single.components.first,
        isNot(same(initialRaster.first)),
      );
      expect(game.modelComponents['lamp']!.component, same(model));
      expect(game.modelComponents['lamp']!.component.playback, same(playback));
      expect(playback.clock, .375);
      expect(game.actors['hero']!.mesh, same(actor));
      expect(game.pointLightBindings, same(lights));
      expect(game.authoredLighting, same(lighting));
      expect(game.sceneChunks['neighbor'], same(neighbor));
      expect(h.reads, reads);
      final ground = game.grounds.single;
      final afterRaster = ground.components;
      final decorReordered = reordered.copyWith(
        placedElements: [
          for (final placed in reordered.placedElements)
            placed.copyWith(visualOrder: 20),
        ],
      );
      game.configuration = h.configuration(decorReordered);
      expect(await game.refresh(), isTrue);
      expect(game.generation, generation);
      expect(game.grounds.single, same(ground));
      expect(game.grounds.single.components, same(afterRaster));
      expect(game.visualOrderUpdates, 2);
      expect(game.visualGroundRebuilds, 1);
      expect(game.modelComponents['lamp']!.component, same(model));
      expect(h.reads, reads);
      expect(game.visibleConfiguration.groundMap, same(decorReordered));
      expect(await game.refresh(), isTrue);
      expect(game.modelComponents['lamp']!.component, same(model));
      expect(game.sceneChunks['neighbor'], same(neighbor));
      expect(h.reads, reads);
    },
  );

  test(
    'locked source layer lets picking pass materialized Smart Tile models',
    () async {
      final h = await _Harness.create(generated: true, materialized: true);
      addTearDown(h.dispose);
      final game = h.game;
      (game.camera as AdaptiveCamera3D).frame(
        Vector3(1, 1, .5),
        pitch: 0,
        yaw: 0,
        distance: 10,
        viewportAspectRatio: 1,
      );
      const pointer = Offset(100, 100);
      final generated = h.map.spatialScene!.instances.singleWhere(
        (instance) => instance.id.startsWith('smt_'),
      );
      expect(game.pickModel(pointer)?.id, generated.id);
      final generation = game.generation;
      final reads = h.reads;
      final component = game.modelComponents[generated.id]!.component;
      final locked = h.configuration(
        h.map,
        canSelectLayer: (id) => id != 'red',
      );
      game.configuration = locked;
      game.renderedConfiguration = locked;
      expect(game.pickContent(pointer)?.id, 'lamp');
      expect(game.pickModel(pointer)?.id, 'lamp');
      final unlocked = h.configuration(h.map);
      game.configuration = unlocked;
      game.renderedConfiguration = unlocked;
      expect(game.pickModel(pointer)?.id, generated.id);
      expect(game.modelComponents[generated.id]!.component, same(component));
      expect(game.generation, generation);
      expect(h.reads, reads);
    },
  );

  test('layer order updates generated paint bias without replacing generated models', () async {
    final h = await _Harness.create(generated: true);
    addTearDown(h.dispose);
    final game = h.game;
    final generated = game.modelComponents.entries
        .where((entry) => entry.key.startsWith('smt_'))
        .single;
    final component = generated.value.component;
    final y = component.position.y;
    final lightBindings = game.pointLightBindings;
    component.playback.clock = .625;
    final generation = game.generation;
    final reads = h.reads;
    final reordered = h.map.copyWith(layers: h.map.layers.reversed.toList());
    game.configuration = h.configuration(reordered);
    expect(await game.refresh(), isTrue);
    expect(game.modelComponents[generated.key]!.component, same(component));
    expect((component.position.y - y).abs(), closeTo(.001, .0000001));
    expect(component.playback.clock, .625);
    expect(game.visualOrderUpdates, 1);
    expect(game.visualGroundRebuilds, 1);
    expect(game.pointLightBindings, same(lightBindings));
    final caster = game.authoredShadowCasters.singleWhere(
      (caster) => caster.id == 'active:${generated.key}',
    );
    expect(
      caster.worldCorners.map((point) => point.y).reduce(math.min),
      closeTo(component.position.y, .0000001),
    );
    expect(
      game.runtimeModelIndex.instance('active', generated.key)!.position.y,
      closeTo(component.position.y, .0000001),
    );
    expect(game.generation, generation);
    expect(h.reads, reads);
  });

  test('a reorder queued during refresh applies the latest order without replacing models', () async {
    final h = await _Harness.create();
    addTearDown(h.dispose);
    final model = h.game.modelComponents['lamp']!.component;
    final generation = h.game.generation;
    final reads = h.reads;
    final refreshing = h.game.refresh();
    expect(h.game.refreshing, isTrue);
    h.game.configuration = h.configuration(
      h.map.copyWith(layers: h.map.layers.reversed.toList()),
    );
    final first = h.game.refresh();
    final latest = h.map.copyWith(
      placedElements: [
        for (final placed in h.map.placedElements)
          placed.copyWith(visualOrder: 5),
      ],
    );
    h.game.configuration = h.configuration(latest);
    final last = h.game.refresh();
    await refreshing;
    expect(await first, isTrue);
    expect(await last, isTrue);
    expect(h.game.visibleConfiguration.groundMap, same(latest));
    expect(h.game.generation, generation + 1);
    expect(h.game.modelComponents['lamp']!.component, same(model));
    expect(h.reads, reads);
  });
}

final class _Harness {
  late MapData map;
  late ProjectManifest project;
  late SpatialSceneGame game;
  final controller = SpatialSceneController();
  var reads = 0;
  late Map<String, SpatialActorVisual> frames;
  late List<SpatialSceneNeighbor> neighbors;
  final png = Uint8List.fromList(
    img.encodePng(img.Image(width: 64, height: 32)),
  );

  static Future<_Harness> create({
    bool generated = false,
    bool materialized = false,
  }) async {
    _UnusedBackend();
    final h = _Harness();
    final model = ProjectModel3dEntry(
      id: 'lamp',
      name: 'Lamp',
      sourceAssetId: 'lamp',
      castsShadowsByDefault: generated,
      relativePath: 'assets/models3d/lamp.glb',
      light: Model3dPointLight(localPosition: Model3dVector3(x: 0, y: 1, z: 0)),
      inspection: Model3dInspection(
        bounds: Model3dBounds(
          min: Model3dVector3.zero,
          max: Model3dVector3(x: 1, y: 2, z: 1),
        ),
        meshCount: 1,
        triangleCount: 1,
      ),
    );
    h.project = ProjectManifest(
      name: 'Order',
      maps: const [],
      tilesets: const [],
      models3d: [model],
      smartTileCatalog: ProjectSmartTileCatalog(
        atlases: const [
          ProjectSmartTileAtlas(
            id: 'atlas',
            name: 'Atlas',
            tilesetId: 'tiles',
            columns: 2,
            rows: 1,
          ),
        ],
        materials: [
          for (final id in ['red', 'blue'])
            ProjectSmartTileMaterial(id: id, name: id, connectionGroupId: id),
        ],
        presets: [
          for (final entry in ['red', 'blue'].indexed)
            ProjectSmartTilePreset(
              id: entry.$2,
              name: entry.$2,
              usage: SmartTileUsage.terrain,
              topology: SmartTileTopology.uniform,
              templateHint: SmartTileTemplateHint.simple,
              coveragePolicy: SmartTileCoveragePolicy.sparse,
              coverageProfile: const SmartTileCoverageProfile(
                mode: SmartTileCoverageMode.template,
              ),
              transformPolicy: const SmartTileTransformPolicy(),
              defaultMaterialId: entry.$2,
              allowedMaterialIds: [entry.$2],
              rules: [
                SmartTileRule(
                  id: entry.$2,
                  centerMatch: SmartTileSlotMatch.material(entry.$2),
                  candidates: [
                    SmartTileCandidate(
                      id: 'fill',
                      parts: [
                        if (generated && entry.$1 == 0)
                          const SmartTileVisualPart(
                            source: SmartTileVisualSource.model3d(
                              modelId: 'lamp',
                            ),
                          ),
                        SmartTileVisualPart(
                          source: SmartTileVisualSource.frame(
                            frame: SmartTileFrameRef(
                              atlasId: 'atlas',
                              column: entry.$1,
                              row: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
    h.map = MapData(
      id: 'active',
      name: 'Active',
      size: const GridSize(width: 1, height: 1),
      spatialScene: MapSpatialScene(
        width: 1,
        depth: 1,
        instances: [
          SpatialModelInstance(
            id: 'lamp',
            modelId: 'lamp',
            position: Model3dVector3.zero,
          ),
        ],
      ),
      layers: [
        for (final id in ['red', 'blue'])
          SmartTileLayer(
            id: id,
            name: id,
            presetId: id,
            usage: SmartTileUsage.terrain,
            materialPalette: ['', id],
            field: const SmartTileField.cell(semanticCells: [1]),
          ),
      ],
      placedElements: const [
        MapPlacedElement(
          id: 'decor',
          layerId: 'red',
          elementId: 'unused',
          pos: GridPos(x: 0, y: 0),
        ),
      ],
    );
    if (materialized) {
      h.map = h.map.copyWith(
        spatialScene: h.map.spatialScene!.copyWith(
          instances: [
            h.map.spatialScene!.instances.single.copyWith(
              position: Model3dVector3(x: .5, y: 0, z: 0),
            ),
          ],
        ),
      );
      h.map = projectSpatialSmartTileModels(
        map: h.map,
        catalog: h.project.smartTileCatalog,
      );
    }
    h.neighbors = [
      SpatialSceneNeighbor(
        map: MapData(
          id: 'neighbor',
          name: 'Neighbor',
          size: const GridSize(width: 1, height: 1),
          spatialScene: MapSpatialScene(
            width: 1,
            depth: 1,
            instances: [
              SpatialModelInstance(
                id: 'lamp-next',
                modelId: 'lamp',
                position: Model3dVector3.zero,
              ),
            ],
          ),
        ),
        offset: const Offset(1, 0),
        loadGroundImage: h.loadGround,
      ),
    ];
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawRect(
      const ui.Rect.fromLTWH(0, 0, 1, 1),
      ui.Paint()..color = const Color(0xffffffff),
    );
    final picture = recorder.endRecording();
    final image = picture.toImageSync(1, 1);
    final texture = await SpatialActorTexture.fromImage(image);
    image.dispose();
    picture.dispose();
    h.frames = {
      'hero': SpatialActorVisual(
        x: .5,
        y: 0,
        z: .5,
        texture: texture,
        frame: const ui.Rect.fromLTWH(0, 0, 1, 1),
      ),
    };
    if (materialized) h.frames = const {};
    h.game =
        SpatialSceneGame(
            h.configuration(h.map),
            onPreviewStatus: (_) {},
            onSurfaceChanged: () {},
          )
          ..onGameResize(Vector2(200, 200))
          ..sceneReady = true;
    await h.game.refresh();
    return h;
  }

  Future<Uint8List> loadModel(String _) async {
    reads++;
    return _triangle();
  }

  Future<Uint8List> loadGround(String _) async {
    reads++;
    return png;
  }

  Map<String, SpatialActorVisual> actorFrames(double _) => frames;
  SpatialSceneView configuration(
    MapData value, {
    bool Function(String)? canSelectLayer,
  }) => SpatialSceneView(
    canSelectLayer: canSelectLayer,
    scene: value.spatialScene!,
    groundMap: value,
    groundProject: project,
    models: project.models3d,
    loadModel: loadModel,
    loadGroundImage: loadGround,
    actorFrames: actorFrames,
    neighbors: neighbors,
    controller: controller,
    onCell: (_, _) {},
    background: const Color(0xff000000),
    ground: const Color(0xff224422),
    edge: const Color(0xff111111),
    errorBuilder: (_, _) => const SizedBox(),
  );
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

Uint8List _triangle() {
  final binary = ByteData(36);
  final coordinates = [0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0];
  for (var i = 0; i < coordinates.length; i++) {
    binary.setFloat32(i * 4, coordinates[i], Endian.little);
  }
  final json = utf8.encode(
    jsonEncode({
      'asset': {'version': '2.0'},
      'scene': 0,
      'scenes': [
        {
          'nodes': [0],
        },
      ],
      'nodes': [
        {'name': 'Triangle', 'mesh': 0},
      ],
      'buffers': [
        {'byteLength': 36},
      ],
      'bufferViews': [
        {'buffer': 0, 'byteLength': 36},
      ],
      'accessors': [
        {'bufferView': 0, 'componentType': 5126, 'count': 3, 'type': 'VEC3'},
      ],
      'meshes': [
        {
          'primitives': [
            {
              'attributes': {'POSITION': 0},
            },
          ],
        },
      ],
    }),
  );
  final jsonSize = (json.length + 3) ~/ 4 * 4;
  final bytes = Uint8List(12 + 8 + jsonSize + 8 + 36);
  final data = ByteData.sublistView(bytes);
  data.setUint32(0, 0x46546c67, Endian.little);
  data.setUint32(4, 2, Endian.little);
  data.setUint32(8, bytes.length, Endian.little);
  data.setUint32(12, jsonSize, Endian.little);
  data.setUint32(16, 0x4e4f534a, Endian.little);
  bytes.fillRange(20, 20 + jsonSize, 32);
  bytes.setRange(20, 20 + json.length, json);
  data.setUint32(20 + jsonSize, 36, Endian.little);
  data.setUint32(24 + jsonSize, 0x004e4942, Endian.little);
  bytes.setRange(28 + jsonSize, bytes.length, binary.buffer.asUint8List());
  return bytes;
}
