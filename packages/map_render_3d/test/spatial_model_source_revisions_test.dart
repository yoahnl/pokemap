import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:flame_3d/core.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart';
import 'package:map_render_3d/src/spatial_scene_decoration.dart';

import '../../map_authoring/test/support/glb_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final unrelated in [0, 2000]) {
    test(
      'revision replaces only its resident source with $unrelated unrelated definitions',
      () async {
        final fixture = _Fixture(unrelated: unrelated);
        addTearDown(fixture.dispose);
        final game = fixture.game;
        expect(await game.refresh(), isTrue);
        final beforeTree = game.modelComponents['tree-instance']!.component;
        final beforeHouse = game.modelComponents['house-instance']!.component;
        final beforeChunk = game.sceneChunks['active'];
        final beforeTerrain = List.of(beforeChunk!.terrain);
        final houseLease = game.modelReservations['house-source'];
        final houseCache = game.cache['house-source'];
        fixture.revision = 'blue';
        game.configuration = fixture.configuration();
        expect(await game.refresh(), isTrue);
        expect(fixture.reads, {'tree': 2, 'house': 1});
        expect(
          game.modelComponents['tree-instance']!.component,
          same(beforeTree),
        );
        expect(
          game.modelComponents['house-instance']!.component,
          same(beforeHouse),
        );
        expect(game.sceneChunks['active'], same(beforeChunk));
        expect(
          game.sceneChunks['active']!.terrain,
          orderedEquals(beforeTerrain),
        );
        expect(game.modelReservations['house-source'], same(houseLease));
        expect(game.cache['house-source'], same(houseCache));
        expect(
          game.loadedModelSources['tree-source']!.nodes.values.single.name,
          'blue',
        );
        expect(fixture.budget.activeDecodes, 0);
        expect(fixture.budget.transientBytes, 0);
      },
    );
  }

  test('a superseded revision never replaces the current source or releases its lease', () async {
    final fixture = _Fixture();
    addTearDown(fixture.dispose);
    expect(await fixture.game.refresh(), isTrue);
    final pending = Completer<Uint8List>();
    final started = Completer<void>();
    fixture.pending = pending;
    fixture.started = started;
    fixture.revision = 'blue';
    fixture.game.configuration = fixture.configuration();
    final stale = fixture.game.refresh();
    await started.future;
    fixture.pending = null;
    fixture.revision = 'green';
    fixture.game.configuration = fixture.configuration();
    final current = fixture.game.refresh();
    pending.complete(_bytes('blue'));
    expect(await current, isTrue);
    expect(await stale, isFalse);
    expect(
      fixture.game.loadedModelSources['tree-source']!.nodes.values.single.name,
      'green',
    );
    expect(
      fixture.game.modelReservations.keys,
      unorderedEquals(['tree-source', 'house-source']),
    );
    expect(fixture.budget.activeDecodes, 0);
    expect(fixture.budget.transientBytes, 0);
    fixture.game.onRemove();
    expect(fixture.budget.residentBytes, 0);
  });

  for (final unrelated in [0, 2000]) {
    test(
      'controller replacement visits one source with $unrelated unrelated instances',
      () async {
        final fixture = _Fixture(
          unrelated: unrelated,
          extraInstances: unrelated,
          useUpdates: true,
        );
        addTearDown(fixture.dispose);
        expect(await fixture.game.refresh(), isTrue);
        fixture.modelList.reads = 0;
        final runtimeIndex = fixture.game.runtimeModelIndex;
        final beforeVisits = fixture.game.modelSourceCandidatesVisited;
        final beforeBuilds = fixture.game.modelSourceComponentBuilds;
        fixture.revision = 'blue';
        fixture.updates.publish(
          revisions: {'tree-source': 'blue'},
          definitions: {'tree': _definition('tree')},
        );
        fixture.game.configuration = fixture.configuration();
        expect(await fixture.game.refresh(), isTrue);
        expect(fixture.game.modelSourceCandidatesVisited - beforeVisits, 1);
        expect(fixture.game.modelSourceComponentBuilds - beforeBuilds, 1);
        expect(fixture.modelList.reads, 0);
        expect(fixture.game.runtimeModelIndex, same(runtimeIndex));
        expect(fixture.reads, {'tree': 2, 'house': 1});
      },
    );
  }

  test(
    'synchronous source notifications preserve A and B before a widget frame',
    () async {
      final fixture = _Fixture(useUpdates: true);
      addTearDown(fixture.dispose);
      expect(await fixture.game.refresh(), isTrue);
      final tree = fixture.game.modelComponents['tree-instance']!.component;
      final house = fixture.game.modelComponents['house-instance']!.component;
      fixture.revision = 'blue';
      fixture.updates.publish(revisions: {'tree-source': 'blue'});
      fixture.houseRevision = 'gold';
      fixture.updates.publish(revisions: {'house-source': 'gold'});
      fixture.game.configuration = fixture.configuration();
      expect(await fixture.game.refresh(), isTrue);
      expect(fixture.reads, {'tree': 2, 'house': 2});
      expect(tree.model.nodes.values.single.name, 'blue');
      expect(house.model.nodes.values.single.name, 'gold');
      expect(fixture.game.modelSourceCandidatesVisited, 2);
    },
  );

  test(
    'controller revision during a pending decode keeps both source updates',
    () async {
      final fixture = _Fixture(useUpdates: true);
      addTearDown(fixture.dispose);
      expect(await fixture.game.refresh(), isTrue);
      fixture.pending = Completer<Uint8List>();
      fixture.started = Completer<void>();
      fixture.revision = 'blue';
      fixture.updates.publish(revisions: {'tree-source': 'blue'});
      final stale = fixture.game.refresh();
      await fixture.started!.future;
      final pending = fixture.pending!;
      fixture.pending = null;
      fixture.houseRevision = 'gold';
      fixture.updates.publish(revisions: {'house-source': 'gold'});
      final latest = fixture.game.refresh();
      pending.complete(_bytes('blue'));
      expect(await stale, isFalse);
      expect(await latest, isTrue);
      expect(
        fixture
            .game
            .loadedModelSources['tree-source']!
            .nodes
            .values
            .single
            .name,
        'blue',
      );
      expect(
        fixture
            .game
            .loadedModelSources['house-source']!
            .nodes
            .values
            .single
            .name,
        'gold',
      );
      expect(fixture.budget.transientBytes, 0);
      expect(fixture.budget.activeDecodes, 0);
    },
  );

  test(
    'controller uses updated definition without traversing the model catalog',
    () async {
      final fixture = _Fixture(useUpdates: true);
      addTearDown(fixture.dispose);
      expect(await fixture.game.refresh(), isTrue);
      final component =
          fixture.game.modelComponents['tree-instance']!.component;
      fixture.revision = 'blue';
      final definition = _definition('tree').copyWith(scale: 2);
      fixture.updates.publish(
        revisions: {'tree-source': 'blue'},
        definitions: {'tree': definition},
      );
      fixture.modelList.reads = 0;
      expect(await fixture.game.refresh(), isTrue);
      expect(component.definition, same(definition));
      expect(component.scale.x, 2);
      expect(fixture.modelList.reads, 0);
    },
  );

  test('replacement materializes a previously excluded decoration without rebuilding its chunk', () async {
    final fixture = _Fixture(useUpdates: true);
    addTearDown(fixture.dispose);
    final narrow = _definition('tree').copyWith(castsShadowsByDefault: true);
    final wide = _definition(
      'tree',
      width: 4,
    ).copyWith(castsShadowsByDefault: true);
    fixture.project = fixture.project.copyWith(
      models3d: [wide, _definition('house')],
    );
    fixture.modelList = _ReadTrackedList(fixture.project.models3d);
    fixture.map = fixture.map.copyWith(
      spatialScene: fixture.map.spatialScene!.copyWith(
        instances: [fixture.map.spatialScene!.instances.last],
      ),
    );
    final decoration = MapExteriorDecoration(
      mapId: 'active',
      playableWidth: 2,
      playableDepth: 2,
      west: 2,
      sectors: [
        ExteriorDecorationSector(
          id: 'west',
          originX: -2,
          originZ: 0,
          scene: MapSpatialScene(
            width: 2,
            depth: 2,
            instances: [
              SpatialModelInstance(
                id: 'margin-tree',
                modelId: 'tree',
                position: Model3dVector3.zero,
              ),
            ],
          ),
        ),
      ],
    );
    SpatialSceneDecoration source() => SpatialSceneDecoration(
      ownerMapId: 'active',
      decoration: decoration,
      offset: Offset.zero,
      project: fixture.project,
      loadGroundImage: fixture.load,
      loadModel: fixture.load,
    );
    fixture.decorations = [source()];
    fixture.game.configuration = fixture.configuration();
    expect(await fixture.game.refresh(), isTrue);
    final chunk = fixture.game.decorationChunks.values.single;
    final component = chunk.models['margin-tree']!.component;
    expect(component.sourceGeometryVisible, isFalse);
    expect(fixture.reads, {'house': 1});
    expect(fixture.game.decorationShadowCasters, isEmpty);
    fixture.revision = 'blue';
    fixture.project = fixture.project.copyWith(
      models3d: [narrow, _definition('house')],
    );
    fixture.modelList = _ReadTrackedList(fixture.project.models3d);
    fixture.decorations = [source()];
    fixture.updates.publish(
      revisions: {'tree-source': 'blue'},
      definitions: {'tree': narrow},
    );
    fixture.game.configuration = fixture.configuration();
    final builds = fixture.game.decorationSectorBuilds;
    expect(await fixture.game.refresh(), isTrue);
    expect(fixture.game.decorationChunks.values.single, same(chunk));
    expect(fixture.game.decorationSectorBuilds, builds);
    expect(component.sourceGeometryVisible, isTrue);
    expect(component.model.nodes.values.single.name, 'blue');
    expect(fixture.game.decorationShadowCasters, hasLength(1));
    expect(fixture.modelList.reads, 0);
    expect(fixture.reads, {'house': 1, 'tree': 1});
  });

  test('coalesced replace and undo keep the already resident source', () async {
    final fixture = _Fixture(useUpdates: true);
    addTearDown(fixture.dispose);
    expect(await fixture.game.refresh(), isTrue);
    final lease = fixture.game.modelReservations['tree-source'];
    final model = fixture.game.loadedModelSources['tree-source'];
    fixture.updates.publish(revisions: {'tree-source': 'blue'});
    fixture.updates.publish(revisions: {'tree-source': 'red'});
    expect(await fixture.game.refresh(), isTrue);
    expect(fixture.reads, {'tree': 1, 'house': 1});
    expect(fixture.game.modelReservations['tree-source'], same(lease));
    expect(fixture.game.loadedModelSources['tree-source'], same(model));
    expect(fixture.game.modelSourceComponentBuilds, 0);
    fixture.game.onRemove();
    final generation = fixture.game.generation;
    fixture.updates.publish(revisions: {'tree-source': 'after-dispose'});
    expect(fixture.game.generation, generation);
    expect(fixture.budget.residentBytes, 0);
  });

  test(
    'undo switches back source bytes without redecoding unrelated models',
    () async {
      final fixture = _Fixture();
      addTearDown(fixture.dispose);
      expect(await fixture.game.refresh(), isTrue);
      final residents = {'red': fixture.budget.residentBytes};
      for (final revision in ['blue', 'red', 'blue', 'red']) {
        fixture.revision = revision;
        fixture.game.configuration = fixture.configuration();
        expect(await fixture.game.refresh(), isTrue);
        expect(
          fixture
              .game
              .loadedModelSources['tree-source']!
              .nodes
              .values
              .single
              .name,
          revision,
        );
        final resident = residents.putIfAbsent(
          revision,
          () => fixture.budget.residentBytes,
        );
        expect(fixture.budget.residentBytes, resident);
      }
      expect(fixture.reads, {'tree': 5, 'house': 1});
    },
  );

  test('failed source decode keeps the visible model and its reservation recoverable', () async {
    final fixture = _Fixture();
    addTearDown(fixture.dispose);
    expect(await fixture.game.refresh(), isTrue);
    final oldModel = fixture.game.modelComponents['tree-instance'];
    final oldLease = fixture.game.modelReservations['tree-source'];
    final resident = fixture.budget.residentBytes;
    fixture.pending = Completer<Uint8List>()..complete(Uint8List(0));
    fixture.revision = 'broken';
    fixture.game.configuration = fixture.configuration();
    await expectLater(fixture.game.refresh(), throwsA(isA<FormatException>()));
    expect(fixture.game.modelComponents['tree-instance'], same(oldModel));
    expect(fixture.game.modelReservations['tree-source'], same(oldLease));
    expect(fixture.budget.residentBytes, resident);
    expect(fixture.budget.transientBytes, 0);
    fixture.pending = null;
    expect(await fixture.game.refresh(), isTrue);
    expect(
      fixture.game.loadedModelSources['tree-source']!.nodes.values.single.name,
      'broken',
    );
  });

  test('source revision during a geometric refresh still invalidates only changed bytes', () async {
    final fixture = _Fixture();
    addTearDown(fixture.dispose);
    expect(await fixture.game.refresh(), isTrue);
    final houseCache = fixture.game.cache['house-source'];
    fixture.revision = 'blue';
    fixture.map = fixture.map.copyWith(
      spatialScene: fixture.map.spatialScene!.copyWith(
        heightLevels: [1, 0, 0, 0],
      ),
    );
    fixture.game.configuration = fixture.configuration();
    expect(await fixture.game.refresh(), isTrue);
    expect(fixture.reads, {'tree': 2, 'house': 1});
    expect(fixture.game.cache['house-source'], same(houseCache));
    expect(
      fixture.game.loadedModelSources['tree-source']!.nodes.values.single.name,
      'blue',
    );
  });

  test(
    'removing a model instance releases only its no longer resident source',
    () async {
      final fixture = _Fixture();
      addTearDown(fixture.dispose);
      expect(await fixture.game.refresh(), isTrue);
      final houseCache = fixture.game.cache['house-source'];
      fixture.map = fixture.map.copyWith(
        spatialScene: fixture.map.spatialScene!.copyWith(
          instances: [fixture.map.spatialScene!.instances.last],
        ),
      );
      fixture.game.configuration = fixture.configuration();
      expect(await fixture.game.refresh(), isTrue);
      expect(fixture.game.cache.keys, ['house-source']);
      expect(fixture.game.modelReservations.keys, ['house-source']);
      expect(fixture.game.cache['house-source'], same(houseCache));
      expect(fixture.reads, {'tree': 1, 'house': 1});
    },
  );
  test('source clipping can become empty and visible again without replacing unrelated geometry', () async {
    final fixture = _Fixture();
    addTearDown(fixture.dispose);
    fixture.translateTree = true;
    fixture.map = fixture.map.copyWith(
      spatialScene: fixture.map.spatialScene!.copyWith(
        instances: [
          fixture.map.spatialScene!.instances.first.copyWith(
            blocksMovement: false,
            clip: SpatialModelClip(left: 0, top: 0, right: 1, bottom: 1),
          ),
          fixture.map.spatialScene!.instances.last,
        ],
      ),
    );
    fixture.game.configuration = fixture.configuration();
    expect(await fixture.game.refresh(), isTrue);
    final house = fixture.game.modelComponents['house-instance'];
    expect(fixture.game.modelComponents, contains('tree-instance'));
    fixture.revision = 'blue';
    fixture.game.configuration = fixture.configuration();
    expect(await fixture.game.refresh(), isTrue);
    expect(
      fixture
          .game
          .modelComponents['tree-instance']!
          .component
          .sourceGeometryVisible,
      isFalse,
    );
    expect(fixture.game.modelComponents['house-instance'], same(house));
    fixture.revision = 'red';
    fixture.game.configuration = fixture.configuration();
    expect(await fixture.game.refresh(), isTrue);
    expect(fixture.game.modelComponents, contains('tree-instance'));
    expect(fixture.game.modelComponents['house-instance'], same(house));
    expect(fixture.game.clippedModelCache.entryCount, 1);
    expect(fixture.reads, {'tree': 3, 'house': 1});
  });
}

final class _Fixture {
  _Fixture({
    int unrelated = 0,
    int extraInstances = 0,
    this.useUpdates = false,
  }) {
    _UnusedBackend();
    project = ProjectManifest(
      name: 'Test',
      maps: const [],
      tilesets: const [],
      models3d: [
        _definition('tree'),
        _definition('house'),
        for (var index = 0; index < unrelated; index++)
          _definition('unused$index'),
      ],
    );
    modelList = _ReadTrackedList(project.models3d);
    if (extraInstances > 0) {
      map = map.copyWith(
        spatialScene: map.spatialScene!.copyWith(
          instances: [
            ...map.spatialScene!.instances,
            for (var i = 0; i < extraInstances; i++)
              SpatialModelInstance(
                id: 'other-$i',
                modelId: 'house',
                position: Model3dVector3.zero,
              ),
          ],
        ),
      );
    }
    game =
        SpatialSceneGame(
            configuration(),
            onPreviewStatus: (_) {},
            onSurfaceChanged: () {},
          )
          ..onGameResize(Vector2(200, 200))
          ..sceneReady = true;
  }
  final controller = SpatialSceneController();
  final updates = SpatialModelSourceUpdates();
  final bool useUpdates;
  late _ReadTrackedList<ProjectModel3dEntry> modelList;
  List<SpatialSceneDecoration> decorations = const [];
  final budget = RuntimeResourceBudget();
  final reads = <String, int>{};
  MapData map = MapData(
    id: 'active',
    name: 'Active',
    size: GridSize(width: 2, height: 2),
    spatialScene: MapSpatialScene(
      width: 2,
      depth: 2,
      instances: [
        for (final id in ['tree', 'house'])
          SpatialModelInstance(
            id: '$id-instance',
            modelId: id,
            position: Model3dVector3.zero,
          ),
      ],
    ),
  );
  late ProjectManifest project;
  late final SpatialSceneGame game;
  String revision = 'red';
  String houseRevision = 'house';
  bool translateTree = false;
  Completer<Uint8List>? pending;
  Completer<void>? started;
  Future<Uint8List> load(String id) {
    reads.update(id, (value) => value + 1, ifAbsent: () => 1);
    if (id == 'tree' && pending != null) {
      if (started?.isCompleted == false) started!.complete();
      return pending!.future;
    }
    return Future.value(
      translateTree && id == 'tree'
          ? Uint8List.fromList(
              triangleGlb(
                edit: (json) {
                  json['nodes'][0]['name'] = revision;
                  json['nodes'][0]['scale'] = [0.5, 0.25, 1];
                  json['nodes'][0]['translation'] = [
                    revision == 'blue' ? 20 : 0,
                    0,
                    0.5,
                  ];
                },
              ),
            )
          : _bytes(id == 'tree' ? revision : houseRevision),
    );
  }

  SpatialSceneView configuration() => SpatialSceneView(
    scene: map.spatialScene!,
    groundMap: map,
    decorations: decorations,
    groundProject: project,
    models: modelList,
    modelSourceUpdates: useUpdates ? updates : null,
    loadModel: load,
    controller: controller,
    resourceBudget: budget,
    resourceIdentity: 'project',
    modelSourceRevisions: {'tree-source': revision, 'house-source': 'house'},
    onCell: (_, _) {},
    background: const Color(0xff000000),
    ground: const Color(0xff224422),
    edge: const Color(0xff111111),
    errorBuilder: (_, _) => const SizedBox(),
  );
  void dispose() {
    game.onRemove();
    controller.dispose();
    updates.dispose();
    budget.dispose();
  }
}

ProjectModel3dEntry _definition(String id, {double width = 1}) =>
    ProjectModel3dEntry(
      id: id,
      name: id,
      sourceAssetId: '$id-source',
      relativePath: 'assets/models3d/$id.glb',
      inspection: Model3dInspection(
        bounds: Model3dBounds(
          min: Model3dVector3.zero,
          max: Model3dVector3(x: width, y: 1, z: 1),
        ),
        meshCount: 1,
        triangleCount: 1,
      ),
    );
Uint8List _bytes(String name) => Uint8List.fromList(
  triangleGlb(edit: (json) => json['nodes'][0]['name'] = name),
);

final class _UnusedBackend extends GpuBackend {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

final class _ReadTrackedList<T> extends ListBase<T> {
  _ReadTrackedList(this.values);
  final List<T> values;
  int reads = 0;
  @override
  int get length => values.length;
  @override
  set length(int value) => throw UnsupportedError('read only');
  @override
  T operator [](int index) {
    reads++;
    return values[index];
  }

  @override
  void operator []=(int index, T value) => throw UnsupportedError('read only');
}
