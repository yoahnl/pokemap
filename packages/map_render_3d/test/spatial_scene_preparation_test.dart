import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flame_3d/model.dart';
import 'package:flame_3d/resources.dart';
import 'package:flutter/widgets.dart' hide Texture;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:map_render_3d/src/spatial_scene_preparation.dart';

final project = ProjectManifest(
  name: 'Pilot',
  maps: const [],
  tilesets: const [],
  models3d: [
    ProjectModel3dEntry(
      id: 'tree',
      name: 'Tree',
      sourceAssetId: 'source-tree',
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
);
MapData target() => MapData(
  id: 'target',
  name: 'Target',
  size: GridSize(width: 2, height: 2),
  layers: const [],
  spatialScene: MapSpatialScene(
    width: 2,
    depth: 2,
    instances: [
      SpatialModelInstance(
        id: 'tree-1',
        modelId: 'tree',
        position: Model3dVector3.zero,
      ),
    ],
  ),
);
SpatialSceneView view(
  ProjectManifest manifest,
  RuntimeResourceBudget budget, {
  String? identity,
}) => SpatialSceneView(
  scene: MapSpatialScene(width: 2, depth: 2),
  models: manifest.models3d,
  loadModel: (_) async => _triangle('tree'),
  groundProject: manifest,
  resourceIdentity: identity,
  resourceBudget: budget,
  controller: SpatialSceneController(),
  onCell: (_, __) {},
  background: const Color(0xff000000),
  ground: const Color(0xff000000),
  edge: const Color(0xff000000),
  errorBuilder: (_, __) => const SizedBox(),
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('immutable catalogue scope survives map projection changes only with same budget', () {
    final budget = RuntimeResourceBudget();
    final before = view(project, budget, identity: 'root:sha');
    final after = view(
      project.copyWith(name: 'Projection'),
      budget,
      identity: 'root:sha',
    );
    addTearDown(before.controller.dispose);
    addTearDown(after.controller.dispose);
    addTearDown(budget.dispose);
    expect(after.modelSourcesMatch(before), isTrue);
    expect(after.immutableResourcesMatch(before), isTrue);
    for (final candidate in [
      view(project.copyWith(name: 'Other'), budget, identity: 'other:sha'),
      view(
        project.copyWith(name: 'Other'),
        RuntimeResourceBudget(),
        identity: 'root:sha',
      ),
      view(project.copyWith(name: 'Other'), budget),
    ]) {
      expect(candidate.immutableResourcesMatch(before), isFalse);
      expect(candidate.modelSourcesMatch(before), isFalse);
      candidate.controller.dispose();
    }
  });
  test(
    'unmounted controller declines destination preparation without loading',
    () async {
      final controller = SpatialSceneController();
      addTearDown(controller.dispose);
      final budget = RuntimeResourceBudget();
      addTearDown(budget.dispose);
      var reads = 0;
      expect(
        await controller.prepareDestination(
          SpatialScenePreparation(
            map: target(),
            project: project,
            loadModel: (_) async {
              reads++;
              return _triangle('tree');
            },
            loadGroundImage: (_) async => Uint8List(0),
            resourceIdentity: 'root:sha',
            resourceBudget: budget,
            isCurrent: () => true,
          ),
        ),
        isFalse,
      );
      expect(reads, 0);
    },
  );
  test('prepared models reuse warm entries and transfer their existing budget lease', () async {
    final budget = RuntimeResourceBudget();
    addTearDown(budget.dispose);
    final cache = <String, Future<Model>>{};
    final textures = <String, Future<Texture>>{};
    final modelLeases = <String, RuntimeResourceReservation>{};
    final textureLeases = <String, RuntimeResourceReservation>{};
    var reads = 0;
    SpatialSceneResourcePreparation prepare() =>
        SpatialSceneResourcePreparation(
          SpatialScenePreparation(
            map: target(),
            project: project,
            loadModel: (_) async {
              reads++;
              return _triangle('tree');
            },
            loadGroundImage: (_) async => Uint8List(0),
            resourceIdentity: 'root:sha',
            resourceBudget: budget,
            isCurrent: () => true,
          ),
          modelCache: cache,
          groundTextureCache: textures,
          isCurrent: () => true,
        );
    final first = prepare();
    expect(await first.prepare(), isTrue);
    expect(cache, isEmpty);
    expect(budget.residentBytes, greaterThan(0));
    first.adoptInto(cache, textures, modelLeases, textureLeases);
    final lease = modelLeases['source-tree'];
    final resident = budget.residentBytes;
    first.commit();
    final second = prepare();
    expect(await second.prepare(), isTrue);
    second.adoptInto(cache, textures, modelLeases, textureLeases);
    second.commit();
    expect(reads, 1);
    expect(modelLeases['source-tree'], same(lease));
    expect(budget.residentBytes, resident);
    expect(cache.length, 1);
  });
  test('cancelled preparation releases only new resources and never publishes late', () async {
    final budget = RuntimeResourceBudget();
    addTearDown(budget.dispose);
    final cache = <String, Future<Model>>{};
    final textures = <String, Future<Texture>>{};
    final gate = Completer<Uint8List>();
    var current = true;
    final prep = SpatialSceneResourcePreparation(
      SpatialScenePreparation(
        map: target(),
        project: project,
        loadModel: (_) => gate.future,
        loadGroundImage: (_) async => Uint8List(0),
        resourceIdentity: 'root:sha',
        resourceBudget: budget,
        isCurrent: () => current,
      ),
      modelCache: cache,
      groundTextureCache: textures,
      isCurrent: () => true,
    );
    final loading = prep.prepare();
    await Future<void>.delayed(Duration.zero);
    current = false;
    gate.complete(_triangle('tree'));
    expect(await loading, isFalse);
    expect(cache, isEmpty);
    expect(textures, isEmpty);
    expect(budget.residentBytes, 0);
    expect(budget.transientBytes, 0);
    expect(budget.activeDecodes, 0);
  });
  test('failed preparation releases leases and remains retryable', () async {
    final budget = RuntimeResourceBudget();
    addTearDown(budget.dispose);
    final cache = <String, Future<Model>>{};
    final textures = <String, Future<Texture>>{};
    final prep = SpatialSceneResourcePreparation(
      SpatialScenePreparation(
        map: target(),
        project: project,
        loadModel: (_) async => throw StateError('missing'),
        loadGroundImage: (_) async => Uint8List(0),
        resourceIdentity: 'root:sha',
        resourceBudget: budget,
        isCurrent: () => true,
      ),
      modelCache: cache,
      groundTextureCache: textures,
      isCurrent: () => true,
    );
    await expectLater(prep.prepare(), throwsStateError);
    expect(cache, isEmpty);
    expect(budget.residentBytes, 0);
    expect(budget.transientBytes, 0);
    expect(budget.activeDecodes, 0);
  });
  test(
    'native ground textures preload and remain warm after adoption',
    () async {
      final budget = RuntimeResourceBudget();
      addTearDown(budget.dispose);
      final catalog = ProjectSmartTileCatalog(
        atlases: const [
          ProjectSmartTileAtlas(
            id: 'atlas',
            name: 'Atlas',
            tilesetId: 'ground',
            columns: 1,
            rows: 1,
          ),
        ],
      );
      final groundProject = project.copyWith(smartTileCatalog: catalog);
      final groundMap = target().copyWith(
        spatialScene: target().spatialScene!.copyWith(
          cliffFrame: SmartTileFrameRef(atlasId: 'atlas', column: 0, row: 0),
        ),
      );
      final models = <String, Future<Model>>{};
      final textures = <String, Future<Texture>>{};
      final modelLeases = <String, RuntimeResourceReservation>{};
      final textureLeases = <String, RuntimeResourceReservation>{};
      var reads = 0;
      SpatialSceneResourcePreparation next() => SpatialSceneResourcePreparation(
        SpatialScenePreparation(
          map: groundMap,
          project: groundProject,
          loadModel: (_) async => _triangle('tree'),
          loadGroundImage: (_) async {
            reads++;
            return Uint8List.fromList(
              img.encodePng(img.Image(width: 2, height: 2)),
            );
          },
          resourceIdentity: 'root:sha',
          resourceBudget: budget,
          isCurrent: () => true,
        ),
        modelCache: models,
        groundTextureCache: textures,
        isCurrent: () => true,
      );
      final first = next();
      expect(await first.prepare(), isTrue);
      first.adoptInto(models, textures, modelLeases, textureLeases);
      final original = await textures['ground'];
      final resident = budget.residentBytes;
      first.commit();
      final second = next();
      expect(await second.prepare(), isTrue);
      second.adoptInto(models, textures, modelLeases, textureLeases);
      second.commit();
      expect(reads, 1);
      expect(await textures['ground'], same(original));
      expect(textureLeases.length, 1);
      expect(budget.residentBytes, resident);
    },
  );
  test(
    'partial failure releases completed new model before publication',
    () async {
      final budget = RuntimeResourceBudget();
      addTearDown(budget.dispose);
      final models = <String, Future<Model>>{};
      final textures = <String, Future<Texture>>{};
      final map = target().copyWith(
        spatialScene: target().spatialScene!.copyWith(
          instances: [
            ...target().spatialScene!.instances,
            SpatialModelInstance(
              id: 'missing',
              modelId: 'missing',
              position: Model3dVector3.zero,
            ),
          ],
        ),
      );
      final prep = SpatialSceneResourcePreparation(
        SpatialScenePreparation(
          map: map,
          project: project,
          loadModel: (_) async => _triangle('tree'),
          loadGroundImage: (_) async => Uint8List(0),
          resourceIdentity: 'root:sha',
          resourceBudget: budget,
          isCurrent: () => true,
        ),
        modelCache: models,
        groundTextureCache: textures,
        isCurrent: () => true,
      );
      await expectLater(prep.prepare(), throwsStateError);
      expect(models, isEmpty);
      expect(budget.residentBytes, 0);
      expect(budget.activeDecodes, 0);
    },
  );
  test('cancelling adopted warm preparation releases its entries before map activation', () async {
    final budget = RuntimeResourceBudget();
    addTearDown(budget.dispose);
    final cache = <String, Future<Model>>{};
    final textures = <String, Future<Texture>>{};
    final leases = <String, RuntimeResourceReservation>{};
    final groundLeases = <String, RuntimeResourceReservation>{};
    final prep = SpatialSceneResourcePreparation(
      SpatialScenePreparation(
        map: target(),
        project: project,
        loadModel: (_) async => _triangle('tree'),
        loadGroundImage: (_) async => Uint8List(0),
        resourceIdentity: 'root:sha',
        resourceBudget: budget,
        isCurrent: () => true,
      ),
      modelCache: cache,
      groundTextureCache: textures,
      isCurrent: () => true,
    );
    expect(await prep.prepare(), isTrue);
    prep.adoptInto(cache, textures, leases, groundLeases);
    expect(cache.length, 1);
    prep.discard();
    expect(cache, isEmpty);
    expect(leases, isEmpty);
    expect(budget.residentBytes, 0);
  });
  for (final cancel in [false, true]) {
    test(
      'two preparation workers bound reads and drain cancellation=$cancel',
      () async {
        final budget = RuntimeResourceBudget();
        addTearDown(budget.dispose);
        final definitions = [
          for (var i = 0; i < 6; i++)
            ProjectModel3dEntry(
              id: 'model-$i',
              name: 'Model $i',
              sourceAssetId: 'source-$i',
              relativePath: 'assets/models3d/model-$i.glb',
              inspection: Model3dInspection(
                bounds: Model3dBounds(
                  min: Model3dVector3.zero,
                  max: Model3dVector3(x: 1, y: 1, z: 1),
                ),
                meshCount: 1,
                triangleCount: 1,
              ),
            ),
        ];
        final map = target().copyWith(
          spatialScene: target().spatialScene!.copyWith(
            instances: [
              for (var i = 0; i < 6; i++)
                SpatialModelInstance(
                  id: 'instance-$i',
                  modelId: 'model-$i',
                  position: Model3dVector3.zero,
                ),
            ],
          ),
        );
        final gates = [for (var i = 0; i < 6; i++) Completer<Uint8List>()];
        final started = <int>[];
        var active = 0, maximum = 0;
        var current = true;
        final cache = <String, Future<Model>>{};
        final prep = SpatialSceneResourcePreparation(
          SpatialScenePreparation(
            map: map,
            project: project.copyWith(models3d: definitions),
            loadModel: (id) async {
              final i = int.parse(id.split('-').last);
              started.add(i);
              active++;
              if (active > maximum) maximum = active;
              try {
                return await gates[i].future;
              } finally {
                active--;
              }
            },
            loadGroundImage: (_) async => Uint8List(0),
            resourceIdentity: 'root:sha',
            resourceBudget: budget,
            isCurrent: () => current,
          ),
          modelCache: cache,
          groundTextureCache: <String, Future<Texture>>{},
          isCurrent: () => true,
        );
        final loading = prep.prepare();
        try {
          await Future<void>.delayed(Duration.zero);
          expect(started, [0, 1]);
          if (cancel) current = false;
          for (final gate in gates) {
            if (!gate.isCompleted) gate.complete(_triangle('tree'));
          }
          expect(await loading, !cancel);
          expect(maximum, 2);
          expect(started, cancel ? [0, 1] : [0, 1, 2, 3, 4, 5]);
          expect(cache, isEmpty);
          prep.discard();
          expect(budget.residentBytes, 0);
          expect(budget.transientBytes, 0);
          expect(budget.activeDecodes, 0);
        } finally {
          for (final gate in gates) {
            if (!gate.isCompleted) gate.complete(_triangle('tree'));
          }
          await loading;
          prep.discard();
        }
      },
    );
  }
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
