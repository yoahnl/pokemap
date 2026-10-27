import 'dart:typed_data';
import 'dart:convert';

import 'package:flame_3d/core.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_scene_decoration.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart';

import '../../map_authoring/test/support/glb_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('raster ground edits retain all 128 exterior model components and their batches', () async {
    _UnusedBackend();
    final tree = ProjectModel3dEntry(
      id: 'oak',
      name: 'Oak',
      sourceAssetId: 'oak-source',
      relativePath: 'assets/models3d/oak.glb',
      castsShadowsByDefault: true,
      light: Model3dPointLight(localPosition: Model3dVector3.zero),
      inspection: Model3dInspection(
        bounds: Model3dBounds(
          min: Model3dVector3(x: -.4, y: 0, z: -.4),
          max: Model3dVector3(x: .4, y: 2, z: .4),
        ),
        meshCount: 1,
        triangleCount: 1,
      ),
    );
    final project = ProjectManifest(
      name: 'Test',
      maps: const [],
      tilesets: const [
        ProjectTilesetEntry(
          id: 'grass',
          name: 'Grass',
          relativePath: 'grass.png',
        ),
      ],
      models3d: [tree],
      smartTileCatalog: ProjectSmartTileCatalog.fromJson(
        jsonDecode(
          jsonEncode({
            'formatVersion': 8,
            'atlases': [
              {
                'id': 'grass',
                'name': 'Grass',
                'tilesetId': 'grass',
                'cellWidth': 32,
                'cellHeight': 32,
                'columns': 1,
                'rows': 1,
              },
            ],
            'materials': [
              {'id': 'grass', 'name': 'Grass', 'connectionGroupId': 'grass'},
            ],
            'presets': [
              {
                'id': 'grass',
                'name': 'Grass',
                'usage': 'path',
                'topology': 'uniform',
                'status': 'published',
                'coveragePolicy': 'sparse',
                'coverageProfile': {'mode': 'template'},
                'transformPolicy': {},
                'defaultMaterialId': 'grass',
                'allowedMaterialIds': ['grass'],
                'rules': [
                  {
                    'id': 'all',
                    'centerMatch': {'kind': 'material', 'materialId': 'grass'},
                    'candidates': [
                      {
                        'id': 'frame',
                        'parts': [
                          {
                            'source': {
                              'kind': 'frame',
                              'frame': {
                                'atlasId': 'grass',
                                'column': 0,
                                'row': 0,
                              },
                            },
                          },
                        ],
                      },
                    ],
                  },
                ],
              },
            ],
          }),
        ) as Map<String, dynamic>,
      ),
    );
    final controller = SpatialSceneController();
    final budget = RuntimeResourceBudget();
    final map = MapData(
      id: 'active',
      name: 'Active',
      size: const GridSize(width: 16, height: 16),
      version: ProjectVersion.v9,
      spatialScene: MapSpatialScene(width: 16, depth: 16),
    );
    final scene = MapSpatialScene(
      width: 16,
      depth: 16,
      generateCliffs: false,
      instances: [
        for (var i = 0; i < 128; i++)
          SpatialModelInstance(
            id: 'tree-$i',
            modelId: 'oak',
            position: Model3dVector3(x: i % 16 + .5, y: 0, z: i ~/ 16 + .5),
          ),
      ],
    );
    var modelReads = 0, groundReads = 0;
    Future<Uint8List> models(String _) async {
      modelReads++;
      return Uint8List.fromList(triangleGlb());
    }

    Future<Uint8List> ground(String _) async {
      groundReads++;
      return Uint8List.fromList(
        img.encodePng(img.Image(width: 32, height: 32)),
      );
    }

    SpatialSceneView configuration(
      int painted, {
      MapSpatialScene? changedScene,
    }) => SpatialSceneView(
      scene: map.spatialScene!,
      groundMap: map,
      groundProject: project,
      models: project.models3d,
      loadModel: models,
      loadGroundImage: ground,
      controller: controller,
      resourceBudget: budget,
      resourceIdentity: 'stable',
      onCell: (_, _) {},
      background: const Color(0xff000000),
      ground: const Color(0xff224422),
      edge: const Color(0xff111111),
      errorBuilder: (_, _) => const SizedBox(),
      decorations: [
        SpatialSceneDecoration(
          ownerMapId: 'active',
          offset: Offset.zero,
          project: project,
          loadGroundImage: ground,
          loadModel: models,
          decoration: MapExteriorDecoration(
            mapId: 'active',
            playableWidth: 16,
            playableDepth: 16,
            west: 16,
            sectors: [
              ExteriorDecorationSector(
                id: 'west',
                originX: -16,
                originZ: 0,
                scene: changedScene ?? scene,
                layers: [
                  SmartTileLayer(
                    id: 'grass',
                    name: 'Grass',
                    presetId: 'grass',
                    usage: SmartTileUsage.path,
                    materialPalette: const ['', 'grass'],
                    field: SmartTileField.cell(
                      semanticCells: [
                        for (var i = 0; i < 256; i++) i <= painted ? 1 : 0,
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
    final game =
        SpatialSceneGame(
            configuration(0),
            onPreviewStatus: (_) {},
            onSurfaceChanged: () {},
          )
          ..onGameResize(Vector2(200, 200))
          ..sceneReady = true;
    addTearDown(() {
      game.onRemove();
      controller.dispose();
      budget.dispose();
    });
    expect(await game.refresh(), isTrue);
    const key = 'exterior:active:west';
    final before = game.decorationChunks[key]!;
    final components = {
      for (final entry in before.models.entries)
        entry.key: entry.value.component,
    };
    final parents = {
      for (final entry in components.entries) entry.key: entry.value.parent,
    };
    final casters = List.of(game.decorationShadowCasters);
    final lights = List.of(game.decorationPointLights);
    final active = game.sceneChunks['active'];
    final generation = game.generation;
    expect(components.length, 128);
    expect(parents.values, everyElement(isNotNull));
    expect(parents.values.toSet().length, 1);
    game.configuration = configuration(1);
    expect(await game.syncDecorations(), isTrue);
    final after = game.decorationChunks[key]!;
    expect(after.ground, isNot(same(before.ground)));
    for (final entry in components.entries) {
      expect(after.models[entry.key]!.component, same(entry.value));
      expect(
        after.models[entry.key]!.component.parent,
        same(parents[entry.key]),
      );
    }
    expect(game.decorationShadowCasters.length, 128);
    for (var i = 0; i < casters.length; i++) {
      expect(game.decorationShadowCasters[i], same(casters[i]));
    }
    expect(game.decorationPointLights.length, 128);
    for (var i = 0; i < lights.length; i++) {
      expect(
        game.decorationPointLights[i].component,
        same(lights[i].component),
      );
      expect(
        game.decorationPointLights[i].definition,
        same(lights[i].definition),
      );
    }
    expect(modelReads, 1);
    expect(groundReads, 1);
    expect(game.sceneChunks['active'], same(active));
    expect(game.generation, generation);
    game.configuration = configuration(
      2,
      changedScene: scene.copyWith(
        instances: [
          for (final instance in scene.instances)
            instance.id == 'tree-0'
                ? instance.copyWith(
                    position: Model3dVector3(x: .75, y: 0, z: .5),
                  )
                : instance,
        ],
      ),
    );
    expect(await game.syncDecorations(), isTrue);
    expect(
      game.decorationChunks[key]!.models['tree-0']!.component,
      isNot(same(components['tree-0'])),
    );
  });
}

final class _UnusedBackend extends GpuBackend {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}
