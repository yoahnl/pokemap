import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_scene_neighbor.dart';
import 'package:map_render_3d/src/spatial_scene_preparation.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final count in [1, 1000]) {
    for (final preparation in ['compatible', 'different project', 'none']) {
      test(
        'activation $preparation constructs plans once with $count materials',
        () async {
          _UnusedBackend();
          final materials = _CountingMaterials(count);
          final project = ProjectManifest(
            name: 'Plans',
            maps: const [],
            tilesets: const [],
            smartTileCatalog: ProjectSmartTileCatalog(materials: materials),
          );
          final source = MapData(
            id: 'source',
            name: 'Source',
            size: const GridSize(width: 2, height: 2),
            spatialScene: MapSpatialScene(width: 2, depth: 2),
          );
          final destination = source.copyWith(
            id: 'destination',
            layers: [MapLayer.tile(id: 'ordinary', name: 'Ordinary')],
          );
          final budget = RuntimeResourceBudget();
          final controller = SpatialSceneController();
          SpatialSceneView configuration(
            MapData map,
            ProjectManifest manifest,
          ) => SpatialSceneView(
            scene: map.spatialScene!,
            groundMap: map,
            groundProject: manifest,
            models: const [],
            loadModel: (_) async => throw StateError('No models'),
            loadGroundImage: (_) async => throw StateError('No raster'),
            controller: controller,
            resourceIdentity: 'project',
            resourceBudget: budget,
            onCell: (_, _) {},
            background: const Color(0xff000000),
            ground: const Color(0xff224422),
            edge: const Color(0xff111111),
            errorBuilder: (_, _) => const SizedBox(),
          );
          final game =
              SpatialSceneGame(
                  configuration(source, project),
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
          if (preparation != 'none') {
            expect(
              await game.prepareDestination(
                SpatialScenePreparation(
                  map: destination,
                  project: project,
                  loadModel: (_) async => throw StateError('No models'),
                  loadGroundImage: (_) async => throw StateError('No raster'),
                  resourceIdentity: 'project',
                  resourceBudget: budget,
                  isCurrent: () => true,
                ),
              ),
              isTrue,
            );
            expect(materials.reads, greaterThan(0));
          }
          materials.reads = 0;
          game.configuration = configuration(
            destination,
            preparation == 'different project' ? project.copyWith() : project,
          );
          expect(await game.refresh(), isTrue);
          expect(
            materials.reads,
            preparation == 'compatible' ? 0 : greaterThan(0),
          );
        },
      );
    }
  }

  test('ten prepared ABA cycles retain shared resources and release every lease on removal', () async {
    final f = _PreparedTransition();
    addTearDown(f.dispose);
    expect(await f.game.refresh(), isTrue);
    final model = f.game.cache['tree-source'];
    final texture = f.game.groundTextureCache['ground'];
    final modelLease = f.game.modelReservations['tree-source'];
    final textureLease = f.game.groundReservations['ground'];
    final resident = f.budget.residentBytes;
    for (var cycle = 0; cycle < 10; cycle++) {
      for (final destination in [f.b, f.a]) {
        expect(await f.game.prepareDestination(f.request(destination)), isTrue);
        f.materials.reads = 0;
        f.game.configuration = f.configuration(destination);
        expect(await f.game.refresh(), isTrue);
        expect(f.materials.reads, 0);
        expect(f.game.cache['tree-source'], same(model));
        expect(f.game.groundTextureCache['ground'], same(texture));
        expect(f.game.modelReservations['tree-source'], same(modelLease));
        expect(f.game.groundReservations['ground'], same(textureLease));
        expect(f.budget.residentBytes, resident);
        expect(f.budget.transientBytes, 0);
        expect(f.budget.pendingDecodes, 0);
      }
    }
    expect(f.modelReads, 1);
    expect(f.imageReads, 1);
    f.game.onRemove();
    expect(f.budget.residentBytes, 0);
    expect(f.budget.transientBytes, 0);
    expect(f.budget.activeDecodes, 0);
  });

  for (final interruption in [
    'cancelled',
    'supplanted',
    'failed',
    'reused chunk',
    'project changed',
    'generation changed',
  ]) {
    test(
      'prepared activation keeps fallback and resource ownership after $interruption',
      () async {
        final f = _PreparedTransition();
        addTearDown(f.dispose);
        expect(await f.game.refresh(), isTrue);
        final model = f.game.cache['tree-source'];
        final texture = f.game.groundTextureCache['ground'];
        final modelLease = f.game.modelReservations['tree-source'];
        final textureLease = f.game.groundReservations['ground'];
        final resident = f.budget.residentBytes;
        var current = true;
        if (interruption == 'failed') {
          await expectLater(
            f.game.prepareDestination(
              f.request(
                f.b.copyWith(
                  spatialScene: f.b.spatialScene!.copyWith(
                    instances: [
                      SpatialModelInstance(
                        id: 'missing',
                        modelId: 'missing',
                        position: Model3dVector3.zero,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            throwsStateError,
          );
        } else {
          expect(
            await f.game.prepareDestination(
              f.request(
                interruption == 'reused chunk' ? f.a : f.b,
                isCurrent: () => current,
              ),
            ),
            isTrue,
          );
        }
        if (interruption == 'cancelled') current = false;
        if (interruption == 'generation changed') f.game.generation++;
        if (interruption == 'supplanted') {
          expect(
            await f.game.prepareDestination(f.request(f.b.copyWith(id: 'c'))),
            isTrue,
          );
        }
        if (interruption == 'reused chunk') {
          f.materials.reads = 0;
          expect(await f.game.refresh(), isTrue);
          expect(f.materials.reads, 0);
        }
        f.materials.reads = 0;
        f.game.configuration = f.configuration(
          f.b,
          project: interruption == 'project changed'
              ? f.project.copyWith()
              : null,
        );
        expect(await f.game.refresh(), isTrue);
        expect(f.materials.reads, greaterThan(0));
        expect(f.game.cache['tree-source'], same(model));
        expect(f.game.groundTextureCache['ground'], same(texture));
        expect(f.game.modelReservations['tree-source'], same(modelLease));
        expect(f.game.groundReservations['ground'], same(textureLease));
        expect(f.budget.residentBytes, resident);
        expect(await f.game.prepareDestination(f.request(f.a)), isTrue);
        f.materials.reads = 0;
        f.game.configuration = f.configuration(f.a);
        expect(await f.game.refresh(), isTrue);
        expect(f.materials.reads, 0);
      },
    );
  }

  for (final ground in [false, true]) {
    test(
      'neighbor refresh replaces an invalidated pending ${ground ? 'ground texture' : 'model'} without losing its admission',
      () async {
        _UnusedBackend();
        final budget = RuntimeResourceBudget();
        final controller = SpatialSceneController();
        final source = Completer<Uint8List>();
        final started = Completer<void>();
        final visible = <Set<String>>[];
        var reads = 0;
        final model = ProjectModel3dEntry(
          id: 'tree',
          name: 'Tree',
          sourceAssetId: 'tree-source',
          relativePath: 'assets/models3d/tree.glb',
          inspection: Model3dInspection(
            bounds: Model3dBounds(
              min: Model3dVector3.zero,
              max: Model3dVector3(x: 1, y: 1, z: 1),
            ),
            meshCount: 1,
            triangleCount: 1,
          ),
        );
        final map = MapData(
          id: 'active',
          name: 'Active',
          size: GridSize(width: 2, height: 2),
          spatialScene: MapSpatialScene(
            width: 2,
            depth: 2,
            cliffFrame: ground
                ? SmartTileFrameRef(atlasId: 'atlas', column: 0, row: 0)
                : null,
            instances: [
              if (!ground)
                SpatialModelInstance(
                  id: 'tree-instance',
                  modelId: 'tree',
                  position: Model3dVector3.zero,
                ),
            ],
          ),
        );
        final neighbor = MapData(
          id: 'neighbor',
          name: 'Neighbor',
          size: GridSize(width: 2, height: 2),
          spatialScene: MapSpatialScene(width: 2, depth: 2),
        );
        final project = ProjectManifest(
          name: 'Test',
          maps: const [],
          tilesets: const [],
          models3d: [model],
          smartTileCatalog: ProjectSmartTileCatalog(
            atlases: const [
              ProjectSmartTileAtlas(
                id: 'atlas',
                name: 'Atlas',
                tilesetId: 'ground',
                columns: 1,
                rows: 1,
              ),
            ],
          ),
        );
        final bytes = ground
            ? Uint8List.fromList(
                img.encodePng(img.Image(width: 32, height: 32)),
              )
            : _triangle('Tree');
        Future<Uint8List> load(String _) {
          reads++;
          if (reads == 1) {
            started.complete();
            return source.future;
          }
          return Future.value(bytes);
        }

        SpatialSceneView configuration(List<SpatialSceneNeighbor> neighbors) =>
            SpatialSceneView(
              scene: map.spatialScene!,
              groundMap: map,
              groundProject: project,
              models: project.models3d,
              loadModel: load,
              loadGroundImage: load,
              controller: controller,
              neighbors: neighbors,
              resourceBudget: budget,
              resourceIdentity: 'project',
              onCell: (_, _) {},
              onVisibleMapsChanged: visible.add,
              background: const Color(0xff000000),
              ground: const Color(0xff224422),
              edge: const Color(0xff111111),
              errorBuilder: (_, _) => const SizedBox(),
            );
        final game =
            SpatialSceneGame(
                configuration(const []),
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
        final stale = game.refresh();
        await started.future;
        game.configuration = configuration([
          SpatialSceneNeighbor(
            map: neighbor,
            offset: const Offset(2, 0),
            loadGroundImage: (_) async => Uint8List(0),
          ),
        ]);
        final current = game.refresh();
        final accepted = expectLater(current, completion(isTrue));
        source.complete(bytes);
        await accepted;
        expect(await stale, isFalse);
        expect(reads, 2);
        final cache = ground ? game.groundTextureCache : game.cache;
        final reservations = ground
            ? game.groundReservations
            : game.modelReservations;
        final key = ground ? 'ground' : 'tree-source';
        expect(cache, contains(key));
        expect(reservations, contains(key));
        final admitted = cache[key];
        final admission = reservations[key];
        expect(visible, [
          {'active', 'neighbor'},
        ]);
        expect(budget.isDisposed, isFalse);
        expect(budget.residentBytes, greaterThan(0));
        expect(budget.transientBytes, 0);
        expect(budget.activeDecodes, 0);
        final residentBytes = budget.residentBytes;
        expect(await game.refresh(), isTrue);
        expect(reads, 2);
        expect(cache[key], same(admitted));
        expect(reservations[key], same(admission));
        expect(budget.residentBytes, residentBytes);
        game.onRemove();
        expect(budget.residentBytes, 0);
        expect(budget.transientBytes, 0);
        expect(budget.pendingDecodes, 0);
      },
    );
  }
}

final class _CountingMaterials extends ListBase<ProjectSmartTileMaterial> {
  _CountingMaterials(int count) {
    _values = [
      for (var i = 0; i < count; i++)
        _CountingMaterial('material-$i', () => reads++),
    ];
  }
  late final List<ProjectSmartTileMaterial> _values;
  var reads = 0;
  @override
  int get length => _values.length;
  @override
  set length(int value) => throw UnsupportedError('Immutable materials');
  @override
  ProjectSmartTileMaterial operator [](int index) => _values[index];
  @override
  void operator []=(int index, ProjectSmartTileMaterial value) =>
      throw UnsupportedError('Immutable materials');
}

final class _CountingMaterial implements ProjectSmartTileMaterial {
  _CountingMaterial(String id, this.onRead)
    : _value = ProjectSmartTileMaterial(
        id: id,
        name: id,
        connectionGroupId: id,
      );
  final ProjectSmartTileMaterial _value;
  final void Function() onRead;
  @override
  String get id {
    onRead();
    return _value.id;
  }

  @override
  String get name => _value.name;
  @override
  String get connectionGroupId => _value.connectionGroupId;
  @override
  String get categoryId => _value.categoryId;
  @override
  TerrainType? get terrainType => _value.terrainType;
  @override
  PathSurfaceKind? get pathSurfaceKind => _value.pathSurfaceKind;
  @override
  bool get isEmpty => _value.isEmpty;
  @override
  int get sortOrder => _value.sortOrder;
  @override
  int? get editorColorArgb => _value.editorColorArgb;
  @override
  Map<String, dynamic> toJson() => _value.toJson();
  @override
  $ProjectSmartTileMaterialCopyWith<ProjectSmartTileMaterial> get copyWith =>
      _value.copyWith;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

final class _PreparedTransition {
  _PreparedTransition() {
    _UnusedBackend();
    project = ProjectManifest(
      name: 'Transition',
      maps: const [],
      tilesets: const [],
      models3d: [
        ProjectModel3dEntry(
          id: 'tree',
          name: 'Tree',
          sourceAssetId: 'tree-source',
          relativePath: 'assets/models3d/tree.glb',
          inspection: Model3dInspection(
            bounds: Model3dBounds(
              min: Model3dVector3.zero,
              max: Model3dVector3(x: 1, y: 1, z: 1),
            ),
            meshCount: 1,
            triangleCount: 1,
          ),
        ),
      ],
      smartTileCatalog: ProjectSmartTileCatalog(
        materials: materials,
        atlases: const [
          ProjectSmartTileAtlas(
            id: 'atlas',
            name: 'Atlas',
            tilesetId: 'ground',
            columns: 1,
            rows: 1,
          ),
        ],
      ),
    );
    a = MapData(
      id: 'a',
      name: 'A',
      size: const GridSize(width: 2, height: 2),
      layers: [MapLayer.tile(id: 'ordinary', name: 'Ordinary')],
      spatialScene: MapSpatialScene(
        width: 2,
        depth: 2,
        cliffFrame: const SmartTileFrameRef(
          atlasId: 'atlas',
          column: 0,
          row: 0,
        ),
        instances: [
          SpatialModelInstance(
            id: 'tree',
            modelId: 'tree',
            position: Model3dVector3.zero,
          ),
        ],
      ),
    );
    b = a.copyWith(id: 'b', name: 'B');
    game =
        SpatialSceneGame(
            configuration(a),
            onPreviewStatus: (_) {},
            onSurfaceChanged: () {},
          )
          ..onGameResize(Vector2(200, 200))
          ..sceneReady = true;
  }
  final materials = _CountingMaterials(1);
  final budget = RuntimeResourceBudget();
  final controller = SpatialSceneController();
  late final ProjectManifest project;
  late final MapData a, b;
  late final SpatialSceneGame game;
  final png = Uint8List.fromList(
    img.encodePng(img.Image(width: 32, height: 32)),
  );
  var modelReads = 0, imageReads = 0;
  Future<Uint8List> loadModel(String _) async {
    modelReads++;
    return _triangle('Tree');
  }

  Future<Uint8List> loadImage(String _) async {
    imageReads++;
    return png;
  }

  SpatialScenePreparation request(MapData map, {bool Function()? isCurrent}) =>
      SpatialScenePreparation(
        map: map,
        project: project,
        loadModel: loadModel,
        loadGroundImage: loadImage,
        resourceIdentity: 'project',
        resourceBudget: budget,
        isCurrent: isCurrent ?? () => true,
      );
  SpatialSceneView configuration(MapData map, {ProjectManifest? project}) =>
      SpatialSceneView(
        scene: map.spatialScene!,
        groundMap: map,
        groundProject: project ?? this.project,
        models: this.project.models3d,
        loadModel: loadModel,
        loadGroundImage: loadImage,
        controller: controller,
        resourceIdentity: 'project',
        resourceBudget: budget,
        onCell: (_, _) {},
        background: const Color(0xff000000),
        ground: const Color(0xff224422),
        edge: const Color(0xff111111),
        errorBuilder: (_, _) => const SizedBox(),
      );
  void dispose() {
    game.onRemove();
    controller.dispose();
    budget.dispose();
  }
}

final class _UnusedBackend extends GpuBackend {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

Uint8List _triangle(String name) {
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
        {'name': name, 'mesh': 0},
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
