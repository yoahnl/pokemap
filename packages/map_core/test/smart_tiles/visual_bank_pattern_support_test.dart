import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('visual pattern banks with neutral support', () {
    test('published sparse banks validate without material render rules', () {
      final catalog = _catalog();
      final diagnostics = validateProjectSmartTileCatalog(
        catalog: catalog,
        projectTilesetIds: _tilesetIds,
      );

      expect(diagnostics.where((item) => item.isError), isEmpty);
      for (final preset in catalog.presets.take(2)) {
        expect(preset.status, SmartTilePresetStatus.published);
        expect(preset.topology, SmartTileTopology.uniform);
        expect(preset.templateHint, SmartTileTemplateHint.simple);
        expect(preset.coveragePolicy, SmartTileCoveragePolicy.sparse);
        expect(preset.coverageProfile.mode, SmartTileCoverageMode.template);
        expect(preset.rules, isEmpty);
        expect(preset.allowedMaterialIds, [preset.defaultMaterialId]);
        expect(
          catalog.materials
              .singleWhere(
                (material) => material.id == preset.defaultMaterialId,
              )
              .isEmpty,
          isTrue,
        );
      }
      final decoded = ProjectSmartTileCatalog.fromJson(catalog.toJson());
      expect(decoded, catalog);
      expect(decoded.patterns.map((pattern) => pattern.id), [
        'bank-a:flower',
        'bank-b:stone',
      ]);
      expect(decoded.animations.single.id, 'bank-a:sway');
      expect(
        decoded.animations.single.frames.map((frame) => frame.durationMs),
        [80, 120],
      );
    });

    for (final usage in [SmartTileUsage.terrain, SmartTileUsage.path]) {
      test('native ${usage.name} bank layer starts empty and ready', () {
        final catalog = _catalog(usage: usage);
        final map = _map();
        final result = planNativeSmartTileLayerCreationForMap(
          map: map,
          manifest: _manifest(catalog),
          preset: catalog.presets.first,
          layerId: 'visuals',
          layerName: 'Visuals',
        );

        expect(result, isA<SmartTileLayerCreationSuccess>());
        final success = result as SmartTileLayerCreationSuccess;
        final layer = success.map.layers.single as SmartTileLayer;
        expect(layer.materialPalette, ['', 'bank-a:support']);
        expect(smartTileSemanticCells(layer), [0, 0, 0, 0]);
        expect(layer.patternStrokes, isEmpty);
        expect(layer.animationActivation, SmartTileAnimationActivation.always);
        expect(_visuals(layer, catalog), isEmpty);
        final readiness = analyzeSmartTileLayerReadiness(
          map: success.map,
          layer: layer,
          preset: catalog.presets.first,
          materials: catalog.materials,
        );
        expect(readiness.hasErrors, isFalse);
        expect(readiness.unresolvedCellCount, 0);
        MapValidator.validate(
          success.map,
          projectDialogueContext: success.manifest,
        );
      });
    }

    test('explicit neutral support never invents a background visual', () {
      final catalog = _catalog();
      final layer = applySmartTileMaterialGesture(
        _bankLayer(),
        mapSize: _size,
        cells: const [GridPos(x: 0, y: 0), GridPos(x: 1, y: 0)],
        materialId: 'bank-a:support',
      );
      final readiness = analyzeSmartTileLayerReadiness(
        map: _map(layer),
        layer: layer,
        preset: catalog.presets.first,
        materials: catalog.materials,
      );

      expect(smartTileSemanticCells(layer), [1, 1, 0, 0]);
      expect(_visuals(layer, catalog), isEmpty);
      expect(readiness.intentionalEmptyCellCount, 2);
      expect(readiness.unresolvedCellCount, 0);
      expect(readiness.hasErrors, isFalse);
    });

    test('visual gestures retain semantic ground and inherit collision', () {
      final catalog = _catalog();
      final original = _groundLayer();
      final applied = _stamp(original, catalog.patterns.first, 'flower');

      expect(applied.layer.field, original.field);
      expect(applied.layer.materialPalette, original.materialPalette);
      expect(applied.collisionUpdates, isEmpty);
      expect(applied.affectedCells, const [
        GridPos(x: 0, y: 0),
        GridPos(x: 1, y: 0),
      ]);
      expect(applied.layer.patternStrokes.single.patternId, 'bank-a:flower');
      expect(
        smartTileMaterialIdAt(applied.layer, mapSize: _size, x: 0, y: 0),
        'soil',
      );
      expect(original.patternStrokes, isEmpty);
      MapValidator.validate(
        _map(applied.layer),
        projectDialogueContext: _manifest(catalog),
      );
    });

    test(
      'banks mix with last visual ownership and erase reveals prior ground',
      () {
        final catalog = _catalog();
        final original = _groundLayer();
        final flower = _stamp(original, catalog.patterns.first, 'flower').layer;
        final mixed = _stamp(flower, catalog.patterns.last, 'stone').layer;
        final visuals = _visuals(mixed, catalog);

        expect(mixed.patternStrokes.map((stroke) => stroke.patternId), [
          'bank-a:flower',
          'bank-b:stone',
        ]);
        expect(_patternVisuals(visuals).map((visual) => visual.ruleId), [
          'pattern:bank-a:flower',
          'pattern:bank-b:stone',
        ]);
        expect(_patternVisuals(visuals).map((visual) => visual.tilesetId), [
          'bank-a-tiles',
          'bank-b-tiles',
        ]);
        expect(mixed.field, original.field);
        final revealFlower = eraseSmartTilePatternCells(
          mixed,
          mapSize: _size,
          cells: const [GridPos(x: 0, y: 0)],
          strokeIds: const ['stone'],
        );
        expect(
          _patternVisuals(
            _visuals(revealFlower, catalog),
          ).map((visual) => visual.ruleId).toSet(),
          {'pattern:bank-a:flower'},
        );
        final revealGround = eraseSmartTilePatternCells(
          mixed,
          mapSize: _size,
          cells: const [GridPos(x: 0, y: 0), GridPos(x: 1, y: 0)],
        );
        expect(revealGround.patternStrokes, isEmpty);
        expect(revealGround.field, original.field);
        expect(revealGround.materialPalette, original.materialPalette);
        expect(_visuals(revealGround, catalog).map((visual) => visual.ruleId), [
          'soil-fill',
          'soil-fill',
          'soil-fill',
          'soil-fill',
        ]);
        expect(
          _visuals(revealGround, catalog).map((visual) => visual.sourceRect),
          _visuals(original, catalog).map((visual) => visual.sourceRect),
        );
      },
    );

    test('pattern animation keeps authored timing channels and identities', () {
      final catalog = _catalog();
      final layer = _stamp(
        _bankLayer(),
        catalog.patterns.first,
        'flower',
      ).layer;
      final serialized = MapLayer.fromJson(layer.toJson()) as SmartTileLayer;
      final decoded = ProjectSmartTileCatalog.fromJson(catalog.toJson());
      final plan = buildSmartTileLayerVisualPlan(
        map: _map(serialized),
        layer: serialized,
        catalog: decoded,
        pass: SmartTileVisualPass.background,
        projectSeed: 71,
      );
      for (final seed in [0, 71, 999]) {
        for (final time in [0, 79, 80, 199, 200]) {
          final direct = _visuals(
            serialized,
            decoded,
            elapsedMs: time,
            projectSeed: seed,
          );
          final animated = direct.singleWhere((visual) => visual.isAnimated);
          expect(animated.sourceRect.x, time >= 80 && time < 200 ? 64 : 32);
          expect(animated.channel, SmartTileRenderChannel.understory);
          expect(animated.drawOrder, 29);
          expect(animated.ruleId, 'pattern:bank-a:flower');
          expect(animated.candidateId, 'pattern-cell-0-0');
          expect(direct.map((visual) => visual.drawOrder), [21, 23, 29]);
          expect(direct.map((visual) => visual.channel), [
            SmartTileRenderChannel.ground,
            SmartTileRenderChannel.ground,
            SmartTileRenderChannel.understory,
          ]);
          expect(
            _identity(plan.resolveBatch(elapsedMs: time).visuals),
            _identity(direct),
          );
        }
      }
      expect(serialized.patternStrokes, layer.patternStrokes);
      expect(decoded.patterns.first.cells, catalog.patterns.first.cells);
      expect(decoded.animations, catalog.animations);
    });

    test(
      'per-cell animation is stable for fixed map layer and project seeds',
      () {
        final catalog = _catalog(animationSync: SmartTileAnimationSync.perCell);
        final layer = _stamp(
          _bankLayer().copyWith(layerSeed: 37),
          catalog.patterns.first,
          'flower',
        ).layer;
        final plan = buildSmartTileLayerVisualPlan(
          map: _map(layer),
          layer: layer,
          catalog: catalog,
          pass: SmartTileVisualPass.background,
          projectSeed: 91,
        );
        final before = layer.toJson();
        for (final time in [0, 80, 199, 200, 480]) {
          final direct = _visuals(
            layer,
            catalog,
            elapsedMs: time,
            projectSeed: 91,
          );
          expect(
            _identity(plan.resolveBatch(elapsedMs: time).visuals),
            _identity(direct),
          );
          expect(
            _identity(
              _visuals(layer, catalog, elapsedMs: time + 200, projectSeed: 91),
            ),
            _identity(direct),
          );
        }
        expect(layer.toJson(), before);
      },
    );

    test('usage mismatch rejects a gesture before modifying the layer', () {
      final layer = _bankLayer();
      expect(
        () => _stamp(
          layer,
          _catalog().patterns.first.copyWith(usage: SmartTileUsage.path),
          'wrong',
        ),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.code,
            'code',
            'smart_tile.pattern.usage_mismatch',
          ),
        ),
      );
      expect(layer.patternStrokes, isEmpty);
      expect(smartTileSemanticCells(layer), [0, 0, 0, 0]);
    });

    test('unresolved foreign visual references fail catalog validation', () {
      final original = _catalog();
      final pattern = original.patterns.first.copyWith(
        cells: const [
          SmartTilePatternCell(
            x: 0,
            y: 0,
            parts: [
              SmartTileVisualPart(
                source: SmartTileVisualSource.frame(
                  frame: SmartTileFrameRef(
                    atlasId: 'foreign-atlas',
                    column: 0,
                    row: 0,
                  ),
                ),
              ),
              SmartTileVisualPart(
                source: SmartTileVisualSource.animation(
                  animationId: 'foreign-animation',
                ),
              ),
            ],
          ),
        ],
      );
      final diagnostics = validateProjectSmartTileCatalog(
        catalog: _catalog(patterns: [pattern]),
        projectTilesetIds: _tilesetIds,
      );

      expect(
        diagnostics.where((item) => item.isError).map((item) => item.code),
        containsAll([
          'smart_tiles.reference.atlas_missing',
          'smart_tiles.reference.animation_missing',
        ]),
      );
      expect(
        original.patterns.first.cells.first.parts.first.source,
        isA<SmartTileFrameSource>(),
      );
    });

    test('explicit erase and collision retain their native semantics', () {
      final original = _groundLayer();
      final pattern = _catalog().patterns.last.copyWith(
        cells: [
          SmartTilePatternCell(
            x: 0,
            y: 0,
            eraseMaterial: true,
            collision: SmartTilePatternCollision.blocked,
            parts: _catalog().patterns.last.cells.single.parts,
          ),
        ],
      );
      final applied = _stamp(original, pattern, 'explicit');

      expect(smartTileSemanticCells(applied.layer), [0, 1, 1, 1]);
      expect(applied.layer.materialPalette, original.materialPalette);
      expect(applied.collisionUpdates, const [
        SmartTilePatternCollisionUpdate(
          cell: GridPos(x: 0, y: 0),
          blocked: true,
        ),
      ]);
      final erased = eraseSmartTilePatternCells(
        applied.layer,
        mapSize: _size,
        cells: const [GridPos(x: 0, y: 0)],
      );
      expect(smartTileSemanticCells(erased), [0, 1, 1, 1]);
      expect(smartTileSemanticCells(original), [1, 1, 1, 1]);
    });
  });
}

const _size = GridSize(width: 4, height: 1);
const _tilesetIds = ['bank-a-tiles', 'bank-b-tiles', 'soil-tiles'];

MapData _map([SmartTileLayer? layer]) => MapData(
  id: 'map',
  name: 'Map',
  version: ProjectVersion.v8,
  size: _size,
  layers: [?layer],
);

ProjectManifest _manifest(ProjectSmartTileCatalog catalog) => ProjectManifest(
  name: 'Visual banks',
  version: ProjectVersion.v8,
  maps: const [
    ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
  ],
  tilesets: [
    for (final id in _tilesetIds)
      ProjectTilesetEntry(id: id, name: id, relativePath: 'tilesets/$id.json'),
  ],
  smartTileCatalog: catalog,
);

SmartTileLayer _bankLayer() => const SmartTileLayer(
  id: 'visuals',
  name: 'Visuals',
  presetId: 'bank-a',
  usage: SmartTileUsage.terrain,
  materialPalette: ['', 'bank-a:support'],
  field: SmartTileField.cell(semanticCells: [0, 0, 0, 0]),
);

SmartTileLayer _groundLayer() => const SmartTileLayer(
  id: 'ground',
  name: 'Ground',
  presetId: 'soil',
  usage: SmartTileUsage.terrain,
  materialPalette: ['', 'soil'],
  field: SmartTileField.cell(semanticCells: [1, 1, 1, 1]),
);

SmartTilePatternApplication _stamp(
  SmartTileLayer layer,
  ProjectSmartTilePattern pattern,
  String id,
) => applySmartTilePatternGesture(
  layer,
  pattern: pattern,
  mapSize: _size,
  selection: const SmartTilePatternSelection.stamp(anchor: GridPos(x: 0, y: 0)),
  strokeId: id,
);

List<SmartTileLayerVisual> _visuals(
  SmartTileLayer layer,
  ProjectSmartTileCatalog catalog, {
  int elapsedMs = 0,
  int projectSeed = 0,
}) => resolveSmartTileLayerVisuals(
  map: _map(layer),
  layer: layer,
  catalog: catalog,
  pass: SmartTileVisualPass.background,
  elapsedMs: elapsedMs,
  projectSeed: projectSeed,
  destinationCellWidth: 32,
  destinationCellHeight: 32,
  sourceCellWidth: 32,
  sourceCellHeight: 32,
);

Iterable<SmartTileLayerVisual> _patternVisuals(
  Iterable<SmartTileLayerVisual> visuals,
) => visuals.where((visual) => visual.ruleId.startsWith('pattern:'));

List<Object> _identity(Iterable<SmartTileLayerVisual> visuals) => [
  for (final visual in visuals)
    (
      visual.cellX,
      visual.cellY,
      visual.ruleId,
      visual.candidateId,
      visual.tilesetId,
      visual.channel,
      visual.drawOrder,
      visual.sourceRect,
    ),
];

ProjectSmartTileCatalog _catalog({
  SmartTileUsage usage = SmartTileUsage.terrain,
  SmartTileAnimationSync animationSync = SmartTileAnimationSync.global,
  List<ProjectSmartTilePattern>? patterns,
}) => ProjectSmartTileCatalog(
  atlases: [
    for (final id in ['bank-a', 'bank-b', 'soil'])
      ProjectSmartTileAtlas(
        id: '$id-atlas',
        name: id,
        tilesetId: '$id-tiles',
        columns: 4,
        rows: 1,
      ),
  ],
  materials: const [
    ProjectSmartTileMaterial(
      id: 'bank-a:support',
      name: 'Neutral A',
      connectionGroupId: 'bank-a:support',
      isEmpty: true,
    ),
    ProjectSmartTileMaterial(
      id: 'bank-b:support',
      name: 'Neutral B',
      connectionGroupId: 'bank-b:support',
      isEmpty: true,
    ),
    ProjectSmartTileMaterial(
      id: 'soil',
      name: 'Soil',
      connectionGroupId: 'soil',
    ),
  ],
  presets: [
    for (final id in ['bank-a', 'bank-b'])
      ProjectSmartTilePreset(
        id: id,
        name: id,
        usage: usage,
        topology: SmartTileTopology.uniform,
        templateHint: SmartTileTemplateHint.simple,
        status: SmartTilePresetStatus.published,
        coveragePolicy: SmartTileCoveragePolicy.sparse,
        coverageProfile: const SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.template,
        ),
        transformPolicy: const SmartTileTransformPolicy(),
        defaultMaterialId: '$id:support',
        allowedMaterialIds: ['$id:support'],
        rules: [],
      ),
    ProjectSmartTilePreset(
      id: 'soil',
      name: 'Soil',
      usage: usage,
      topology: SmartTileTopology.uniform,
      templateHint: SmartTileTemplateHint.simple,
      status: SmartTilePresetStatus.published,
      coveragePolicy: SmartTileCoveragePolicy.sparse,
      coverageProfile: const SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.template,
      ),
      transformPolicy: const SmartTileTransformPolicy(),
      defaultMaterialId: 'soil',
      allowedMaterialIds: ['soil'],
      rules: const [
        SmartTileRule(
          id: 'soil-fill',
          centerMatch: SmartTileSlotMatch.material('soil'),
          candidates: [
            SmartTileCandidate(
              id: 'soil-frame',
              parts: [
                SmartTileVisualPart(
                  source: SmartTileVisualSource.frame(
                    frame: SmartTileFrameRef(
                      atlasId: 'soil-atlas',
                      column: 0,
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
  animations: [
    ProjectSmartTileAnimation(
      id: 'bank-a:sway',
      name: 'Sway',
      sync: animationSync,
      frames: const [
        ProjectSmartTileAnimationFrame(
          frame: SmartTileFrameRef(atlasId: 'bank-a-atlas', column: 1, row: 0),
          durationMs: 80,
        ),
        ProjectSmartTileAnimationFrame(
          frame: SmartTileFrameRef(atlasId: 'bank-a-atlas', column: 2, row: 0),
          durationMs: 120,
        ),
      ],
    ),
  ],
  patterns:
      patterns ??
      [
        ProjectSmartTilePattern(
          id: 'bank-a:flower',
          name: 'Flower',
          usage: usage,
          width: 2,
          height: 1,
          drawOrder: 20,
          cells: const [
            SmartTilePatternCell(
              x: 0,
              y: 0,
              parts: [
                SmartTileVisualPart(
                  source: SmartTileVisualSource.frame(
                    frame: SmartTileFrameRef(
                      atlasId: 'bank-a-atlas',
                      column: 0,
                      row: 0,
                    ),
                  ),
                  drawOrder: 3,
                ),
                SmartTileVisualPart(
                  source: SmartTileVisualSource.animation(
                    animationId: 'bank-a:sway',
                  ),
                  channel: SmartTileRenderChannel.understory,
                  drawOrder: 9,
                ),
              ],
            ),
            SmartTilePatternCell(
              x: 1,
              y: 0,
              parts: [
                SmartTileVisualPart(
                  source: SmartTileVisualSource.frame(
                    frame: SmartTileFrameRef(
                      atlasId: 'bank-a-atlas',
                      column: 3,
                      row: 0,
                    ),
                  ),
                  drawOrder: 1,
                ),
              ],
            ),
          ],
        ),
        ProjectSmartTilePattern(
          id: 'bank-b:stone',
          name: 'Stone',
          usage: usage,
          width: 1,
          height: 1,
          drawOrder: 30,
          cells: const [
            SmartTilePatternCell(
              x: 0,
              y: 0,
              parts: [
                SmartTileVisualPart(
                  source: SmartTileVisualSource.frame(
                    frame: SmartTileFrameRef(
                      atlasId: 'bank-b-atlas',
                      column: 2,
                      row: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
);
