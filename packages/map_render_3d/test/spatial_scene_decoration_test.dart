import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';

import 'package:flame_3d/core.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flutter/widgets.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_scene_decoration.dart';
import 'package:map_render_3d/src/spatial_scene_authoring_target.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart';
import 'package:map_render_3d/src/spatial_terrain_geometry.dart';

void main() {
  test(
    'an off-center exterior visual never admits an interior Environment root',
    () {
      final fixture = _canopyFixture(interiorRoot: true);
      final projection = projectSpatialDecorations(
        decorations: [fixture.decoration],
        playableBounds: const [Rect.fromLTWH(0, 0, 4, 8)],
        nativeMaps: [(map: fixture.map, offset: Offset.zero)],
      ).single;
      expect(projection.allowsModel(fixture.tree, fixture.model), isFalse);
    },
  );
  test(
    'Environment roots stay outside while crowns can cover their own map edge',
    () {
      final fixture = _canopyFixture();
      final projection = projectSpatialDecorations(
        decorations: [fixture.decoration],
        playableBounds: const [Rect.fromLTWH(0, 0, 4, 8)],
        nativeMaps: [(map: fixture.map, offset: Offset.zero)],
      ).single;
      expect(projection.allowsModel(fixture.tree, fixture.model), isTrue);
      expect(projection.excludedCells, isEmpty);
      expect(
        projection.allowsModel(
          fixture.tree.copyWith(position: Model3dVector3(x: 4.1, y: 0, z: 3.5)),
          fixture.model,
        ),
        isFalse,
      );
    },
  );

  test(
    'canopy overhang never covers a connected approach or a neighboring map',
    () {
      final fixture = _canopyFixture();
      final north = MapData(
        id: 'north',
        name: 'North',
        size: const GridSize(width: 4, height: 8),
        version: ProjectVersion.v9,
        spatialScene: MapSpatialScene(width: 4, depth: 8),
      );
      final map = fixture.map.copyWith(
        connections: const [
          MapConnection(
            direction: MapConnectionDirection.north,
            targetMapId: 'north',
          ),
        ],
      );
      final projection = projectSpatialDecorations(
        decorations: [fixture.decoration],
        playableBounds: const [
          Rect.fromLTWH(0, 0, 4, 8),
          Rect.fromLTWH(0, -8, 4, 8),
        ],
        nativeMaps: [
          (map: map, offset: Offset.zero),
          (map: north, offset: const Offset(0, -8)),
        ],
      ).single;
      expect(projection.allowsModel(fixture.tree, fixture.model), isFalse);
    },
  );

  test('an explicit trunk collider cannot cross the playable boundary', () {
    final fixture = _canopyFixture();
    final projection = projectSpatialDecorations(
      decorations: [fixture.decoration],
      playableBounds: const [Rect.fromLTWH(0, 0, 4, 8)],
      nativeMaps: [(map: fixture.map, offset: Offset.zero)],
    ).single;
    final model = fixture.model.copyWith(
      collisionBounds: Model3dBounds(
        min: Model3dVector3(x: -.2, y: 0, z: -.2),
        max: Model3dVector3(x: 1.1, y: .4, z: .2),
      ),
    );
    expect(projection.allowsModel(fixture.tree, model), isFalse);
    expect(
      projection.allowsModel(
        fixture.tree,
        model.copyWith(
          collisionBounds: Model3dBounds(
            min: Model3dVector3(x: -.2, y: 0, z: -.2),
            max: Model3dVector3(x: .2, y: .4, z: .2),
          ),
        ),
      ),
      isTrue,
    );
  });

  test('a fully exterior visual still respects the connection clearance and its physical bounds', () {
    final fixture = _canopyFixture();
    final map = fixture.map.copyWith(
      connections: const [
        MapConnection(
          direction: MapConnectionDirection.north,
          targetMapId: 'unloaded',
        ),
      ],
    );
    final projection = projectSpatialDecorations(
      decorations: [fixture.decoration],
      playableBounds: const [Rect.fromLTWH(0, 0, 4, 8)],
      nativeMaps: [(map: map, offset: Offset.zero)],
    ).single;
    final model = ProjectModel3dEntry(
      id: 'tree',
      name: 'Tree',
      sourceAssetId: 'tree',
      relativePath: 'assets/models3d/tree.glb',
      inspection: Model3dInspection(
        bounds: Model3dBounds(
          min: Model3dVector3(x: -.1, y: 0, z: -.1),
          max: Model3dVector3(x: .1, y: 1, z: .1),
        ),
        meshCount: 1,
        triangleCount: 2,
      ),
    );
    final inApproach = SpatialModelInstance(
      id: 'manual',
      modelId: 'tree',
      position: Model3dVector3(x: 3.25, y: 0, z: .5),
    );
    expect(projection.allowsModel(inApproach, model), isFalse);
    final outside = inApproach.copyWith(
      position: Model3dVector3(x: 3.25, y: 0, z: 3),
    );
    expect(projection.allowsModel(outside, model), isTrue);
    expect(
      projection.allowsModel(
        outside,
        model.copyWith(
          collisionBounds: Model3dBounds(
            min: Model3dVector3(x: -.1, y: 0, z: -.1),
            max: Model3dVector3(x: 1, y: .5, z: .1),
          ),
        ),
      ),
      isFalse,
    );
  });

  test(
    'connection clearance selects the matching placement of a repeated target',
    () {
      final fixture = _canopyFixture();
      final target = fixture.map.copyWith(id: 'neighbor', name: 'Neighbor');
      final map = fixture.map.copyWith(
        connections: const [
          MapConnection(
            direction: MapConnectionDirection.north,
            targetMapId: 'neighbor',
          ),
        ],
      );
      final model = ProjectModel3dEntry(
        id: 'small',
        name: 'Small',
        sourceAssetId: 'small',
        relativePath: 'assets/models3d/small.glb',
        inspection: Model3dInspection(
          bounds: Model3dBounds(
            min: Model3dVector3(x: -.1, y: 0, z: -.1),
            max: Model3dVector3(x: .1, y: 1, z: .1),
          ),
          meshCount: 1,
          triangleCount: 2,
        ),
      );
      final root = SpatialModelInstance(
        id: 'manual',
        modelId: 'small',
        position: Model3dVector3(x: 3.25, y: 0, z: .5),
      );
      for (final targets in [
        [
          (map: target, offset: const Offset(0, 8)),
          (map: target, offset: const Offset(0, -8)),
        ],
        [
          (map: target, offset: const Offset(0, -8)),
          (map: target, offset: const Offset(0, 8)),
        ],
      ]) {
        final projection = projectSpatialDecorations(
          decorations: [fixture.decoration],
          playableBounds: const [
            Rect.fromLTWH(0, 0, 4, 8),
            Rect.fromLTWH(0, -8, 4, 8),
            Rect.fromLTWH(0, 8, 4, 8),
          ],
          nativeMaps: [(map: map, offset: Offset.zero), ...targets],
        ).single;
        expect(projection.allowsModel(root, model), isFalse);
      }
    },
  );

  test(
    'a missing connected map conservatively protects its whole approach edge',
    () {
      final fixture = _canopyFixture();
      final map = fixture.map.copyWith(
        connections: const [
          MapConnection(
            direction: MapConnectionDirection.north,
            targetMapId: 'unloaded',
          ),
        ],
      );
      final projection = projectSpatialDecorations(
        decorations: [fixture.decoration],
        playableBounds: const [Rect.fromLTWH(0, 0, 4, 8)],
        nativeMaps: [(map: map, offset: Offset.zero)],
      ).single;
      expect(projection.allowsModel(fixture.tree, fixture.model), isFalse);
    },
  );

  test(
    'unowned and uncontextualized models retain complete visual exclusion',
    () {
      final fixture = _canopyFixture();
      final projection = projectSpatialDecorations(
        decorations: [fixture.decoration],
        playableBounds: const [Rect.fromLTWH(0, 0, 4, 8)],
      ).single;
      expect(projection.allowsModel(fixture.tree, fixture.model), isFalse);
      final contextual = projectSpatialDecorations(
        decorations: [fixture.decoration],
        playableBounds: const [Rect.fromLTWH(0, 0, 4, 8)],
        nativeMaps: [(map: fixture.map, offset: Offset.zero)],
      ).single;
      final unowned = SpatialModelInstance(
        id: 'manual',
        modelId: fixture.tree.modelId,
        position: fixture.tree.position,
      );
      expect(contextual.allowsModel(unowned, fixture.model), isFalse);
    },
  );

  final project = ProjectManifest(
    name: 'Test',
    maps: const [],
    tilesets: const [],
  );
  Future<Uint8List> load(String _) async => Uint8List(0);

  SpatialSceneDecoration decoration(String owner, Offset offset) =>
      SpatialSceneDecoration(
        ownerMapId: owner,
        offset: offset,
        project: project,
        loadGroundImage: load,
        loadModel: load,
        decoration: MapExteriorDecoration(
          mapId: owner,
          playableWidth: 2,
          playableDepth: 2,
          west: 2,
          north: 2,
          sectors: [
            ExteriorDecorationSector(
              id: 'north-west',
              originX: -2,
              originZ: -2,
              scene: MapSpatialScene(width: 4, depth: 4),
            ),
          ],
        ),
      );

  test(
    'authoring surface uses sector-local coordinates at negative origins',
    () {
      final target = SpatialSceneAuthoringTarget(
        map: decoration(
          'a',
          Offset.zero,
        ).decoration.sectors.single.asVisualMap(),
        offset: const Offset(-2, -2),
      );
      final hit = pickSpatialAuthoringSurface(
        target,
        Vector3(-1.5, 10, -1.5),
        Vector3(0, -1, 0),
      );
      expect(hit?.cell, (0, 0));
      expect(hit?.position, Model3dVector3(x: .5, y: 0, z: .5));
    },
  );

  test('negative sector origins exclude playable ground before geometry', () {
    final projected = projectSpatialDecorations(
      decorations: [decoration('a', Offset.zero)],
      playableBounds: const [Rect.fromLTWH(0, 0, 2, 2)],
    ).single;
    expect(projected.offset, const Offset(-2, -2));
    expect(projected.excludedCells, {(2, 2), (3, 2), (2, 3), (3, 3)});
    final faces = spatialTerrainFaces(
      projected.map.spatialScene!,
      excludedCells: projected.excludedCells,
    ).toList();
    expect(faces.where((face) => face.isTop).length, 12);
    expect(
      faces.any((face) => projected.excludedCells.contains(face.cell)),
      isFalse,
    );
  });

  test('overlap priority stays attached to persistent owners when active map changes', () {
    final a = decoration('a', Offset.zero),
        b = decoration('b', const Offset(1, 0));
    final before = projectSpatialDecorations(
      decorations: [b, a],
      playableBounds: const [],
    );
    final after = projectSpatialDecorations(
      decorations: [a, b],
      playableBounds: const [],
      sceneOffset: const Offset(-1, 0),
    );
    expect(before.map((p) => p.key), after.map((p) => p.key));
    for (var i = 0; i < before.length; i++) {
      expect(before[i].excludedCells, after[i].excludedCells);
      expect(before[i].offset - const Offset(1, 0), after[i].offset);
    }
    expect(before.last.excludedCells.length, greaterThan(4));
  });

  test(
    'native cell stencil reads only the matching logical layer across sectors',
    () {
      const layer = SmartTileLayer(
        id: 'terrain',
        name: 'Terrain',
        presetId: 'grass',
        usage: SmartTileUsage.terrain,
        materialPalette: ['', 'grass'],
        field: SmartTileField.cell(semanticCells: [1, 1]),
      );
      final preset = ProjectSmartTilePreset(
        id: 'grass',
        name: 'Grass',
        usage: SmartTileUsage.terrain,
        topology: SmartTileTopology.cardinal4,
        templateHint: SmartTileTemplateHint.simple,
        coveragePolicy: SmartTileCoveragePolicy.sparse,
        coverageProfile: const SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.template,
        ),
        transformPolicy: const SmartTileTransformPolicy(),
        defaultMaterialId: 'grass',
        allowedMaterialIds: const ['grass'],
        rules: const [],
      );
      final source = SpatialSceneDecoration(
        ownerMapId: 'a',
        offset: Offset.zero,
        project: project,
        loadGroundImage: load,
        loadModel: load,
        decoration: MapExteriorDecoration(
          mapId: 'a',
          playableWidth: 2,
          playableDepth: 2,
          west: 2,
          north: 2,
          sectors: [
            ExteriorDecorationSector(
              id: 'left',
              originX: -2,
              originZ: -1,
              scene: MapSpatialScene(width: 1, depth: 2),
              layers: const [layer],
            ),
            ExteriorDecorationSector(
              id: 'right',
              originX: -1,
              originZ: -1,
              scene: MapSpatialScene(width: 1, depth: 2),
              layers: const [layer],
            ),
          ],
        ),
      );
      final projected = projectSpatialDecorations(
        decorations: [source],
        playableBounds: const [],
      );
      final context = projected.first.cellContextResolvers['terrain']!(
        preset: preset,
        x: 0,
        y: 0,
      );
      expect(context.observed.eastEdge.materialId, 'grass');
      expect(context.observed.eastEdge.isInsideMap, isTrue);
      expect(context.observed.westEdge.isInsideMap, isFalse);
      final cached = projectSpatialDecorations(
        decorations: [source],
        playableBounds: const [],
        previous: {for (final p in projected) p.key: p},
      );
      expect(
        cached.first.cellContextResolvers['terrain'],
        same(projected.first.cellContextResolvers['terrain']),
      );
    },
  );

  test('whole canopy footprint is excluded before models materialize', () {
    final projection = projectSpatialDecorations(
      decorations: [decoration('a', Offset.zero)],
      playableBounds: const [],
    ).single;
    final tree = ProjectModel3dEntry(
      id: 'tree',
      name: 'Tree',
      sourceAssetId: 'tree-source',
      relativePath: 'assets/models3d/tree.glb',
      inspection: Model3dInspection(
        bounds: Model3dBounds(
          min: Model3dVector3(x: -.5, y: 0, z: -.5),
          max: Model3dVector3(x: .5, y: 2, z: .5),
        ),
        meshCount: 1,
        triangleCount: 1,
      ),
    );
    expect(
      projection.allowsModel(
        SpatialModelInstance(
          id: 'tree',
          modelId: 'tree',
          position: Model3dVector3(x: 1.8, y: 0, z: 2.5),
        ),
        tree,
      ),
      isFalse,
    );
    expect(
      projection.allowsModel(
        SpatialModelInstance(
          id: 'tree',
          modelId: 'tree',
          position: Model3dVector3(x: .5, y: 0, z: .5),
        ),
        tree,
      ),
      isTrue,
    );
  });

  test(
    'native clips constrain the full visible object footprint at passages',
    () {
      final projection = projectSpatialDecorations(
        decorations: [decoration('a', Offset.zero)],
        playableBounds: const [],
      ).single;
      final model = ProjectModel3dEntry(
        id: 'carrier',
        name: 'Carrier',
        sourceAssetId: 'carrier',
        relativePath: 'assets/models3d/carrier.glb',
        inspection: Model3dInspection(
          bounds: Model3dBounds(
            min: Model3dVector3(x: -50, y: 0, z: -50),
            max: Model3dVector3(x: 50, y: 1, z: 50),
          ),
          meshCount: 1,
          triangleCount: 1,
        ),
      );
      final clipped = SpatialModelInstance(
        id: 'clipped',
        modelId: 'carrier',
        position: Model3dVector3(x: 1, y: 0, z: 1),
        blocksMovement: false,
        clip: SpatialModelClip(left: -.4, top: -.4, right: .4, bottom: .4),
      );
      expect(projection.allowsModel(clipped, model), isTrue);
    },
  );

  test(
    'sector edits keep playable chunks and decoded resources intact',
    () async {
      _UnusedBackend();
      var reads = 0;
      var paused = false;
      final runtimeQueries = <String>[];
      final budget = RuntimeResourceBudget();
      final controller = SpatialSceneController();
      final tree = ProjectModel3dEntry(
        id: 'tree',
        name: 'Tree',
        sourceAssetId: 'tree-source',
        relativePath: 'assets/models3d/tree.glb',
        castsShadowsByDefault: true,
        inspection: Model3dInspection(
          bounds: Model3dBounds(
            min: Model3dVector3.zero,
            max: Model3dVector3(x: .5, y: 1, z: .5),
          ),
          meshCount: 1,
          triangleCount: 1,
        ),
      );
      final manifest = ProjectManifest(
        name: 'Test',
        maps: const [],
        tilesets: const [],
        models3d: [tree],
      );
      Future<Uint8List> modelLoader(String _) async {
        reads++;
        return _triangle('Tree');
      }

      final active = MapData(
        id: 'active',
        name: 'Active',
        size: GridSize(width: 2, height: 2),
        spatialScene: MapSpatialScene(
          width: 2,
          depth: 2,
          instances: [
            SpatialModelInstance(
              id: 'main-tree',
              modelId: 'tree',
              position: Model3dVector3.zero,
            ),
          ],
        ),
      );
      final untouched = ExteriorDecorationSector(
        id: 'north',
        originX: 0,
        originZ: -2,
        scene: MapSpatialScene(width: 2, depth: 2),
      );
      SpatialSceneView configuration(double x) => SpatialSceneView(
        scene: active.spatialScene!,
        groundMap: active,
        groundProject: manifest,
        models: manifest.models3d,
        loadModel: modelLoader,
        loadGroundImage: load,
        controller: controller,
        resourceBudget: budget,
        resourceIdentity: 'project',
        presentationPaused: () => paused,
        modelRuntimeState: (mapId, instanceId) {
          runtimeQueries.add(mapId);
          return null;
        },
        decorations: [
          SpatialSceneDecoration(
            ownerMapId: 'active',
            offset: Offset.zero,
            project: manifest,
            loadGroundImage: load,
            loadModel: modelLoader,
            decoration: MapExteriorDecoration(
              mapId: 'active',
              playableWidth: 2,
              playableDepth: 2,
              west: 2,
              north: 2,
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
                        position: Model3dVector3(x: x, y: 0, z: .5),
                      ),
                    ],
                  ),
                ),
                untouched,
              ],
            ),
          ),
        ],
        onCell: (_, _) {},
        background: const Color(0xff000000),
        ground: const Color(0xff224422),
        edge: const Color(0xff111111),
        errorBuilder: (_, _) => const SizedBox(),
      );
      final game =
          SpatialSceneGame(
              configuration(.25),
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
      expect(reads, 1);
      final activeChunk = game.sceneChunks['active'];
      final northChunk = game.decorationChunks['exterior:active:north'];
      final modelCache = game.cache['tree-source'];
      final generation = game.generation;
      final builds = game.decorationSectorBuilds;
      final residents = budget.residentBytes;
      game.configuration = configuration(.75);
      expect(await game.syncDecorations(), isTrue);
      expect(game.generation, generation);
      expect(game.sceneChunks['active'], same(activeChunk));
      expect(game.decorationChunks['exterior:active:north'], same(northChunk));
      expect(game.decorationSectorBuilds, builds + 1);
      expect(game.cache['tree-source'], same(modelCache));
      expect(reads, 1);
      expect(budget.residentBytes, residents);
      expect(game.decorationShadowCasters.length, 1);
      expect(
        game.runtimeModelIndex.instance('exterior:active:west', 'margin-tree'),
        isNull,
      );
      runtimeQueries.clear();
      paused = true;
      game.syncRuntimeModels();
      expect(runtimeQueries, ['active']);
      expect(
        game.decorationAnimationModels.values.single.playback.paused,
        isTrue,
      );
    },
  );

  test('removing decoration releases its unshared model without retiring playable assets', () async {
    _UnusedBackend();
    final budget = RuntimeResourceBudget();
    final controller = SpatialSceneController();
    ProjectModel3dEntry model(String id) => ProjectModel3dEntry(
      id: id,
      name: id,
      sourceAssetId: '$id-source',
      relativePath: 'assets/models3d/$id.glb',
      inspection: Model3dInspection(
        bounds: Model3dBounds(
          min: Model3dVector3.zero,
          max: Model3dVector3(x: 1, y: 1, z: 1),
        ),
        meshCount: 1,
        triangleCount: 1,
      ),
    );
    final project = ProjectManifest(
      name: 'Test',
      maps: const [],
      tilesets: const [],
      models3d: [model('main'), model('margin')],
    );
    final reads = <String, int>{};
    Completer<Uint8List>? gate;
    Completer<void>? started;
    Future<Uint8List> models(String id) async {
      reads[id] = (reads[id] ?? 0) + 1;
      if (id == 'margin' && gate != null) {
        started!.complete();
        return gate.future;
      }
      return _triangle(id);
    }

    final map = MapData(
      id: 'active',
      name: 'Active',
      size: const GridSize(width: 2, height: 2),
      spatialScene: MapSpatialScene(
        width: 2,
        depth: 2,
        instances: [
          SpatialModelInstance(
            id: 'main',
            modelId: 'main',
            position: Model3dVector3.zero,
          ),
        ],
      ),
    );
    SpatialSceneView configuration(bool show) => SpatialSceneView(
      scene: map.spatialScene!,
      groundMap: map,
      groundProject: project,
      models: project.models3d,
      loadModel: models,
      loadGroundImage: load,
      controller: controller,
      resourceBudget: budget,
      resourceIdentity: 'project',
      decorations: [
        if (show)
          SpatialSceneDecoration(
            ownerMapId: 'active',
            offset: Offset.zero,
            project: project,
            loadGroundImage: load,
            loadModel: models,
            decoration: MapExteriorDecoration(
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
                        id: 'margin',
                        modelId: 'margin',
                        position: Model3dVector3(x: .5, y: 0, z: .5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
      onCell: (_, _) {},
      background: const Color(0xff000000),
      ground: const Color(0xff224422),
      edge: const Color(0xff111111),
      errorBuilder: (_, _) => const SizedBox(),
    );
    final game =
        SpatialSceneGame(
            configuration(true),
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
    expect(game.cache.keys, containsAll(['main-source', 'margin-source']));
    final before = budget.residentBytes;
    final main = game.sceneChunks['active'];
    final generation = game.generation;
    game.configuration = configuration(false);
    expect(await game.syncDecorations(), isTrue);
    expect(game.generation, generation);
    expect(game.sceneChunks['active'], same(main));
    expect(game.cache.keys, ['main-source']);
    expect(game.modelReservations.keys, ['main-source']);
    expect(budget.residentBytes, lessThan(before));
    expect(reads, {'main': 1, 'margin': 1});
    gate = Completer<Uint8List>();
    started = Completer<void>();
    game.configuration = configuration(true);
    final pending = game.syncDecorations();
    await started.future;
    expect(game.decorationStats.pending, isTrue);
    expect(game.decorationStats.ready, isFalse);
    game.configuration = configuration(false);
    expect(await game.syncDecorations(), isTrue);
    final committed = game.decorationStats.committedRevision;
    expect(game.decorationStats.ready, isTrue);
    gate.complete(_triangle('margin'));
    expect(await pending, isFalse);
    expect(game.decorationStats.committedRevision, committed);
    expect(game.decorationChunks, isEmpty);
    expect(game.cache.keys, ['main-source']);
    expect(game.modelReservations.keys, ['main-source']);
    expect(budget.activeDecodes, 0);
  });

  test('adjacent sector heights suppress their shared artificial wall', () {
    final scene = MapSpatialScene(width: 1, depth: 1, heightLevels: const [2]);
    final faces = spatialTerrainFaces(
      scene,
      adjacentHeightAt: (x, z) =>
          x >= 1 && z >= 0 && z < 1 ? scene.levelHeight * 2 : null,
    ).toList();
    expect(
      faces.where(
        (face) => !face.isTop && face.positions.every((p) => p.x == 1),
      ),
      isEmpty,
    );
  });

  test('masked hole creates no vertical wall against the excluded cell', () {
    final scene = MapSpatialScene(
      width: 2,
      depth: 1,
      heightLevels: const [2, 0],
    );
    final faces = spatialTerrainFaces(
      scene,
      excludedCells: const {(1, 0)},
    ).toList();
    expect(
      faces.where(
        (face) => !face.isTop && face.positions.every((p) => p.x == 1),
      ),
      isEmpty,
    );
  });
}

({
  SpatialSceneDecoration decoration,
  MapData map,
  SpatialModelInstance tree,
  ProjectModel3dEntry model,
})
_canopyFixture({bool interiorRoot = false}) {
  final width = interiorRoot ? 8 : 4;
  final anchor = interiorRoot
      ? const GridPos(x: 4, y: 3)
      : const GridPos(x: 3, y: 2);
  final id = environmentSpatialPlacementId(
    layerId: 'trees',
    areaId: 'edge',
    modelId: 'tree',
    anchor: anchor,
  );
  final tree = SpatialModelInstance(
    id: id,
    modelId: 'tree',
    position: Model3dVector3(
      x: interiorRoot ? 4.5 : 3,
      y: 0,
      z: interiorRoot ? 3.5 : 2.5,
    ),
  );
  final model = ProjectModel3dEntry(
    id: 'tree',
    name: 'Tree',
    sourceAssetId: 'tree',
    relativePath: 'assets/models3d/tree.glb',
    inspection: Model3dInspection(
      bounds: Model3dBounds(
        min: Model3dVector3(
          x: interiorRoot ? -3 : -2,
          y: 0,
          z: interiorRoot ? -.1 : -2,
        ),
        max: Model3dVector3(
          x: interiorRoot ? -2 : 2,
          y: 3,
          z: interiorRoot ? .1 : 2,
        ),
      ),
      meshCount: 1,
      triangleCount: 2,
    ),
  );
  final map = MapData(
    id: 'owner',
    name: 'Owner',
    size: const GridSize(width: 4, height: 8),
    version: ProjectVersion.v9,
    spatialScene: MapSpatialScene(width: 4, depth: 8),
  );
  final decoration = SpatialSceneDecoration(
    ownerMapId: 'owner',
    offset: Offset.zero,
    project: ProjectManifest(
      name: 'Test',
      maps: const [],
      tilesets: const [],
      models3d: [model],
    ),
    loadGroundImage: (_) async => Uint8List(0),
    loadModel: (_) async => Uint8List(0),
    decoration: MapExteriorDecoration(
      mapId: 'owner',
      playableWidth: 4,
      playableDepth: 8,
      west: 4,
      sectors: [
        ExteriorDecorationSector(
          id: 'west',
          originX: -4,
          originZ: 0,
          scene: MapSpatialScene(width: width, depth: 8, instances: [tree]),
          layers: [
            EnvironmentLayer(
              id: 'trees',
              name: 'Trees',
              content: EnvironmentLayerContent(
                targetsSpatialTerrain: true,
                areas: [
                  EnvironmentArea(
                    id: 'edge',
                    name: 'Edge',
                    presetId: 'forest',
                    mask: EnvironmentAreaMask(
                      width: width,
                      height: 8,
                      cells: [
                        for (var z = 0; z < 8; z++)
                          for (var x = 0; x < width; x++)
                            x == anchor.x && z == anchor.y,
                      ],
                    ),
                    seed: 1,
                    generatedPlacementIds: [id],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
  return (decoration: decoration, map: map, tree: tree, model: model);
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
