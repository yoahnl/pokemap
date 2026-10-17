import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('animated native paths require model animation export capability', () {
    final project = ProjectManifest(
      name: 'Grass',
      maps: const [],
      tilesets: const [],
      smartTileCatalog: _catalog(),
    );
    final map = _map();
    expect(
      SpatialGameplayCapabilities.requiresModelAnimation(project),
      isFalse,
    );
    expect(
      SpatialGameplayCapabilities.requiresModelAnimation(project, maps: [map]),
      isTrue,
    );
    final layer = map.layers.single as SmartTileLayer;
    for (final replacement in [
      layer.copyWith(isVisible: false),
      layer.copyWith(opacity: 0),
      layer.copyWith(
        field: const SmartTileField.cell(semanticCells: [0, 0, 0, 0]),
      ),
    ]) {
      expect(
        SpatialGameplayCapabilities.requiresModelAnimation(
          project,
          maps: [
            map.copyWith(layers: [replacement]),
          ],
        ),
        isFalse,
      );
    }
    final plain = project.copyWith(
      smartTileCatalog: _withPart(
        const SmartTileVisualPart(
          source: SmartTileVisualSource.model3d(modelId: 'tall-grass'),
        ),
      ),
    );
    expect(
      SpatialGameplayCapabilities.requiresModelAnimation(plain, maps: [map]),
      isFalse,
    );
  });

  test('ground replacement is an explicit model source declaration', () {
    final source = SmartTileVisualSource.fromJson({
      'kind': 'model3d',
      'modelId': 'cliff-cap',
      'replacesGround': true,
    });
    expect(source.toJson()['replacesGround'], true);
    expect(SmartTileVisualSource.fromJson(source.toJson()), source);
    expect(
      const SmartTileVisualSource.model3d(
        modelId: 'tree',
      ).toJson()['replacesGround'],
      false,
    );
  });

  test('ground replacements follow resolved painted models and visibility', () {
    final part = SmartTileVisualPart(
      source: SmartTileVisualSource.model3d(
        modelId: 'tall-grass',
        replacesGround: true,
      ),
    );
    final catalog = _withPart(part);
    final map = _map();
    final projection = resolveSpatialSmartTileModelProjection(
      map: map,
      catalog: catalog,
    );
    expect(projection.groundReplacements, {
      'grass': {(0, 0), (1, 1)},
    });
    expect(
      projection.instances,
      resolveSpatialSmartTileInstances(map: map, catalog: catalog),
    );
    expect(projection.cellOrigins, {
      projection.instances[0].id: (
        layerId: 'grass',
        cell: const GridPos(x: 0, y: 0),
      ),
      projection.instances[1].id: (
        layerId: 'grass',
        cell: const GridPos(x: 1, y: 1),
      ),
    });
    expect(
      resolveSpatialSmartTileModelProjection(
        map: map,
        catalog: _catalog(),
      ).groundReplacements,
      isEmpty,
    );
    final layer = map.layers.single as SmartTileLayer;
    for (final replacement in [
      layer.copyWith(isVisible: false),
      layer.copyWith(opacity: 0),
      layer.copyWith(
        field: const SmartTileField.cell(semanticCells: [0, 0, 0, 0]),
      ),
    ]) {
      final changed = resolveSpatialSmartTileModelProjection(
        map: map.copyWith(layers: [replacement]),
        catalog: catalog,
      );
      expect(changed.groundReplacements, isEmpty);
      expect(changed.instances, isEmpty);
      expect(changed.cellOrigins, isEmpty);
    }
  });

  test('replacement declaration requires one cell and a ground channel', () {
    for (final part in [
      SmartTileVisualPart(
        source: const SmartTileVisualSource.model3d(
          modelId: 'tall-grass',
          replacesGround: true,
        ),
        footprintWidth: 2,
      ),
      SmartTileVisualPart(
        source: const SmartTileVisualSource.model3d(
          modelId: 'tall-grass',
          replacesGround: true,
        ),
        channel: SmartTileRenderChannel.foreground,
      ),
    ]) {
      final catalog = _withPart(part);
      expect(
        validateProjectSmartTileCatalog(
          catalog: catalog,
          spatial: true,
          projectTilesetIds: const [],
          projectModelIds: const ['tall-grass'],
        ).map((diagnostic) => diagnostic.code),
        contains('smart_tiles.model3d.ground_replacement_invalid'),
      );
      expect(
        () => resolveSpatialSmartTileModelProjection(
          map: _map(),
          catalog: catalog,
        ),
        throwsFormatException,
      );
    }
  });

  test(
    'soil gestures preserve declared replacements in either layer order',
    () {
      for (final frontFirst in [true, false]) {
        for (final replacesGround in [true, false]) {
          final definition = _withPart(
            SmartTileVisualPart(
              source: SmartTileVisualSource.model3d(
                modelId: 'tall-grass',
                replacesGround: replacesGround,
              ),
            ),
          );
          final catalog = ProjectSmartTileCatalog(
            materials: definition.materials,
            presets: [
              definition.presets.single.copyWith(usage: SmartTileUsage.terrain),
            ],
          );
          final replacement = (_map().layers.single as SmartTileLayer).copyWith(
            usage: SmartTileUsage.terrain,
          );
          const soil = SmartTileLayer(
            id: 'soil',
            name: 'Sol',
            presetId: 'soil',
            usage: SmartTileUsage.terrain,
            materialPalette: ['', 'soil'],
            field: SmartTileField.cell(semanticCells: [1, 1, 1, 1]),
          );
          final map = _map().copyWith(
            properties: frontFirst ? {} : {'tileLayerOrder': 'bottom_to_top'},
            layers: frontFirst ? [replacement, soil] : [soil, replacement],
          );
          final painted = applySmartTileMapMaterialGesture(
            map,
            layer: soil,
            catalog: catalog,
            cells: const [GridPos(x: 0, y: 0)],
            materialId: 'soil',
          );
          final higher = painted.layers.whereType<SmartTileLayer>().singleWhere(
            (layer) => layer.id == replacement.id,
          );
          expect(smartTileSemanticCells(higher), [
            replacesGround ? 1 : 0,
            0,
            0,
            1,
          ]);
          expect(painted.spatialScene, map.spatialScene);
          if (!replacesGround) continue;
          final erased = applySmartTileMapMaterialGesture(
            painted,
            layer: higher,
            catalog: catalog,
            cells: const [GridPos(x: 0, y: 0)],
            materialId: null,
          );
          expect(
            erased.layers.singleWhere((layer) => layer.id == soil.id),
            soil,
          );
          expect(
            resolveSpatialSmartTileModelProjection(
              map: erased,
              catalog: catalog,
            ).groundReplacements,
            {
              replacement.id: {(1, 1)},
            },
          );
        }
      }
    },
  );

  test('model visual source round trips local scale and XYZ offsets', () {
    final source = SmartTileVisualSource.fromJson(<String, dynamic>{
      'kind': 'model3d',
      'modelId': 'tall-grass',
      'scale': 0.75,
      'offsetX': 0.09375,
      'offsetY': 0.125,
      'offsetZ': -0.1875,
      'animationIndex': 0,
      'followTerrain': true,
    });

    expect(source.toJson(), <String, dynamic>{
      'kind': 'model3d',
      'modelId': 'tall-grass',
      'scale': 0.75,
      'offsetX': 0.09375,
      'offsetY': 0.125,
      'offsetZ': -0.1875,
      'animationIndex': 0,
      'followTerrain': true,
      'replacesGround': false,
    });
    expect(SmartTileVisualSource.fromJson(source.toJson()), source);
  });

  test(
    'source fractions and pixel offsets rotate together and sample final terrain',
    () {
      final map = _map().copyWith(
        size: const GridSize(width: 3, height: 3),
        layers: [
          (_map().layers.single as SmartTileLayer).copyWith(
            field: SmartTileField.cell(
              semanticCells: [0, 0, 0, 0, 1, 0, 0, 0, 0],
            ),
          ),
        ],
        spatialScene: MapSpatialScene(
          width: 3,
          depth: 3,
          levelHeight: .25,
          heightLevels: [0, 0, 0, 0, 1, 0, 0, 7, 0],
        ),
      );
      final part = SmartTileVisualPart(
        source: SmartTileVisualSource.model3d(
          modelId: 'tall-grass',
          offsetX: .125,
          offsetY: .1875,
          offsetZ: .25,
        ),
        offsetUnit: SmartTileOffsetUnit.pixel,
        offsetX: 8,
        offsetY: -8,
        transform: SmartTileSpriteTransform(quarterTurns: 1),
      );
      final catalog = _withPart(part);
      final instance = resolveSpatialSmartTileInstances(
        map: map,
        catalog: catalog,
        sourceCellWidth: 16,
        sourceCellHeight: 16,
      ).single;
      expect(instance.position.x, closeTo(1.75, 1e-9));
      expect(instance.position.z, closeTo(2.125, 1e-9));
      expect(instance.position.y, 1.9375);
      expect(instance.rotationDegrees, -90);
      final noOffsets = part.copyWith(
        source: SmartTileVisualSource.model3d(modelId: 'tall-grass'),
      );
      expect(
        resolveSpatialSmartTileInstances(
          map: map,
          catalog: _withPart(noOffsets),
          sourceCellWidth: 16,
          sourceCellHeight: 16,
        ).single.id,
        instance.id,
      );
      final absolute = part.copyWith(
        source: (part.source as SmartTileModel3dSource).copyWith(
          followTerrain: false,
        ),
      );
      expect(
        resolveSpatialSmartTileInstances(
          map: map,
          catalog: _withPart(absolute),
          sourceCellWidth: 16,
          sourceCellHeight: 16,
        ).single.position.y,
        .1875,
      );
    },
  );

  test('quarter turns preserve exact valid anchors on the map boundary', () {
    for (var turn = 0; turn < 4; turn++) {
      final offset = switch (turn) {
        0 => (-.5, -.5),
        1 => (-.5, .5),
        2 => (.5, .5),
        _ => (.5, -.5),
      };
      final part = SmartTileVisualPart(
        source: SmartTileVisualSource.model3d(
          modelId: 'tall-grass',
          offsetX: offset.$1,
          offsetZ: offset.$2,
        ),
        transform: SmartTileSpriteTransform(quarterTurns: turn),
      );
      final first = resolveSpatialSmartTileInstances(
        map: _map(),
        catalog: _withPart(part),
      ).first;
      expect(first.position.x, 0);
      expect(first.position.z, 0);
    }
  });

  test(
    'source offsets reject nonfinite values and final anchors outside the map',
    () {
      for (final value in [
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        for (final axis in ['x', 'z']) {
          final source = SmartTileVisualSource.model3d(
            modelId: 'tall-grass',
            offsetX: axis == 'x' ? value : 0,
            offsetZ: axis == 'z' ? value : 0,
          );
          final catalog = _withPart(SmartTileVisualPart(source: source));
          expect(
            validateProjectSmartTileCatalog(
              catalog: catalog,
              spatial: true,
              projectTilesetIds: const [],
              projectModelIds: const ['tall-grass'],
            ).map((diagnostic) => diagnostic.code),
            contains('smart_tiles.model3d.transform_invalid'),
          );
          expect(
            () =>
                resolveSpatialSmartTileInstances(map: _map(), catalog: catalog),
            throwsFormatException,
          );
        }
      }
      final outside = _withPart(
        SmartTileVisualPart(
          source: SmartTileVisualSource.model3d(
            modelId: 'tall-grass',
            offsetX: .75,
          ),
        ),
      );
      expect(
        () => resolveSpatialSmartTileInstances(map: _map(), catalog: outside),
        throwsFormatException,
      );
      final valid = _withPart(
        SmartTileVisualPart(
          source: SmartTileVisualSource.model3d(
            modelId: 'tall-grass',
            offsetX: .125,
            offsetZ: -.125,
          ),
        ),
      );
      expect(
        validateProjectSmartTileCatalog(
          catalog: valid,
          projectTilesetIds: const [],
          projectModelIds: const ['tall-grass'],
        ).map((diagnostic) => diagnostic.code),
        contains('smart_tiles.model3d.dimension_invalid'),
      );
    },
  );

  test(
    'painted models follow terrain and disappear when their cell is erased',
    () {
      final catalog = _catalog();
      final map = _map();
      final projected = projectSpatialSmartTileModels(
        map: map,
        catalog: catalog,
      );
      final instances = projected.spatialScene!.instances;
      expect(instances, hasLength(3));
      expect(instances.first.id, 'authored');
      final grass = instances[1];
      expect(grass.modelId, 'tall-grass');
      expect(grass.position, Model3dVector3(x: .5, y: 2.125, z: .5));
      expect(grass.rotationDegrees, -90);
      expect(grass.scale, .75);
      expect(grass.blocksMovement, false);
      expect(grass.animationIndex, 0);
      expect(
        projectSpatialSmartTileModels(map: projected, catalog: catalog),
        projected,
      );

      final layer = map.layers.single as SmartTileLayer;
      final erased = projected.copyWith(
        layers: <MapLayer>[
          layer.copyWith(
            field: const SmartTileField.cell(semanticCells: <int>[0, 0, 0, 0]),
          ),
        ],
      );
      expect(
        projectSpatialSmartTileModels(
          map: erased,
          catalog: catalog,
        ).spatialScene!.instances,
        <SpatialModelInstance>[instances.first],
      );
      expect(
        resolveSmartTileLayerVisuals(
          map: map,
          layer: layer,
          catalog: catalog,
          pass: SmartTileVisualPass.background,
        ),
        isEmpty,
      );
    },
  );

  test('model references require a 3D project and an existing resource', () {
    final diagnostics = validateProjectSmartTileCatalog(
      catalog: _catalog(),
      projectTilesetIds: const <String>[],
    );
    expect(
      diagnostics.map((item) => item.code),
      containsAll(<String>[
        'smart_tiles.model3d.dimension_invalid',
        'smart_tiles.reference.model_missing',
      ]),
    );
    expect(
      validateProjectSmartTileCatalog(
            catalog: _catalog(),
            projectTilesetIds: const <String>[],
            projectModelIds: const <String>['tall-grass'],
            projectModelAnimationIndices: const {
              'tall-grass': {0},
            },
            spatial: true,
          )
          .where((item) => item.isError)
          .map((item) => '${item.code}: ${item.message}'),
      isEmpty,
    );
  });

  test('absolute model height stays below elevated terrain', () {
    final dynamic json = _catalog().toJson();
    final source =
        json['presets'][0]['rules'][0]['candidates'][0]['parts'][0]['source']
            as Map<String, dynamic>;
    source['offsetY'] = -2.25;
    source['followTerrain'] = false;
    final projected = projectSpatialSmartTileModels(
      map: _map(),
      catalog: ProjectSmartTileCatalog.fromJson(json),
    );
    expect(projected.spatialScene!.instances[1].position.y, -2.25);
  });

  test('generated path models reject ordinary object edits', () {
    final map = projectSpatialSmartTileModels(map: _map(), catalog: _catalog());
    final instance = map.spatialScene!.instances.last;
    const operations = SpatialMapOperations();
    expect(
      () => operations.upsertInstance(map, instance),
      throwsFormatException,
    );
    expect(
      () => operations.deleteInstance(map, instance.id),
      throwsFormatException,
    );
  });

  test('a model pattern replaces its cell rule without erasing semantics', () {
    final catalog = _catalog();
    final pattern = ProjectSmartTilePattern(
      id: 'grass-edge',
      name: 'Grass edge',
      usage: SmartTileUsage.path,
      width: 1,
      height: 1,
      cells: [
        SmartTilePatternCell(
          x: 0,
          y: 0,
          parts: [
            SmartTileVisualPart(
              source: SmartTileVisualSource.model3d(
                modelId: 'tall-grass',
                offsetY: 3,
                followTerrain: false,
              ),
            ),
          ],
        ),
      ],
    );
    final map = _map();
    final layer = map.layers.single as SmartTileLayer;
    final painted = map.copyWith(
      layers: [
        layer.copyWith(
          patternStrokes: [
            SmartTilePatternStroke(
              id: 'edge',
              patternId: pattern.id,
              cells: [GridPos(x: 0, y: 0)],
            ),
          ],
        ),
      ],
    );
    final projected = projectSpatialSmartTileModels(
      map: painted,
      catalog: ProjectSmartTileCatalog(
        materials: catalog.materials,
        presets: catalog.presets,
        patterns: [pattern],
      ),
    );
    expect(projected.spatialScene!.instances, hasLength(3));
    expect(
      projected.spatialScene!.instances
          .singleWhere(
            (instance) =>
                instance.modelId == 'tall-grass' && instance.position.x == .5,
          )
          .position
          .y,
      3,
    );
    expect((projected.layers.single as SmartTileLayer).field, layer.field);
  });

  test('model scale is bounded by the native instance contract', () {
    final catalog = _catalog();
    final preset = catalog.presets.single;
    final rule = preset.rules.single;
    final candidate = rule.candidates.single;
    final invalid = ProjectSmartTileCatalog(
      materials: catalog.materials,
      presets: [
        preset.copyWith(
          rules: [
            rule.copyWith(
              candidates: [
                candidate.copyWith(
                  parts: [
                    candidate.parts.single.copyWith(
                      source: const SmartTileVisualSource.model3d(
                        modelId: 'tall-grass',
                        scale: 1001,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
    expect(
      validateProjectSmartTileCatalog(
        catalog: invalid,
        projectTilesetIds: const [],
        projectModelIds: const ['tall-grass'],
        spatial: true,
      ).map((item) => item.code),
      contains('smart_tiles.model3d.transform_invalid'),
    );
  });
}

ProjectSmartTileCatalog _withPart(SmartTileVisualPart part) {
  final catalog = _catalog();
  final preset = catalog.presets.single;
  final rule = preset.rules.single;
  return ProjectSmartTileCatalog(
    materials: catalog.materials,
    presets: [
      preset.copyWith(
        rules: [
          rule.copyWith(
            candidates: [
              rule.candidates.single.copyWith(parts: [part]),
            ],
          ),
        ],
      ),
    ],
  );
}

ProjectSmartTileCatalog _catalog() => ProjectSmartTileCatalog(
  materials: <ProjectSmartTileMaterial>[
    ProjectSmartTileMaterial(
      id: 'grass',
      name: 'Grass',
      connectionGroupId: 'grass',
    ),
  ],
  presets: <ProjectSmartTilePreset>[
    ProjectSmartTilePreset(
      id: 'grass-path',
      name: 'Grass',
      usage: SmartTileUsage.path,
      coveragePolicy: SmartTileCoveragePolicy.sparse,
      coverageProfile: SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.template,
      ),
      transformPolicy: SmartTileTransformPolicy(),
      topology: SmartTileTopology.uniform,
      defaultMaterialId: 'grass',
      templateHint: SmartTileTemplateHint.simple,
      allowedMaterialIds: <String>['grass'],
      rules: <SmartTileRule>[
        SmartTileRule(
          id: 'grass',
          centerMatch: SmartTileSlotMatch.material('grass'),
          candidates: <SmartTileCandidate>[
            SmartTileCandidate(
              id: 'grass',
              parts: <SmartTileVisualPart>[
                SmartTileVisualPart(
                  source: SmartTileVisualSource.model3d(
                    modelId: 'tall-grass',
                    scale: .75,
                    offsetY: .125,
                    animationIndex: 0,
                  ),
                  transform: SmartTileSpriteTransform(quarterTurns: 1),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

MapData _map() => MapData(
  id: 'map',
  name: 'Map',
  version: ProjectVersion.v9,
  size: const GridSize(width: 2, height: 2),
  layers: const <MapLayer>[
    SmartTileLayer(
      id: 'grass',
      name: 'Grass',
      presetId: 'grass-path',
      usage: SmartTileUsage.path,
      materialPalette: <String>['', 'grass'],
      field: SmartTileField.cell(semanticCells: <int>[1, 0, 0, 1]),
    ),
  ],
  spatialScene: MapSpatialScene(
    width: 2,
    depth: 2,
    heightLevels: const <int>[2, 0, 0, 1],
    navigation: SpatialNavigationProfile(spawn: SpatialSpawn(x: 1.5, z: .5)),
    instances: <SpatialModelInstance>[
      SpatialModelInstance(
        id: 'authored',
        modelId: 'house',
        position: Model3dVector3(x: 1.5, y: 0, z: .5),
      ),
    ],
  ),
);
