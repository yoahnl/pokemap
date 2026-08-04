import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectSmartTilePattern', () {
    test('round-trips anchor, repetition, visuals, erase, and collision', () {
      final pattern = _pattern();

      final decoded = ProjectSmartTilePattern.fromJson(pattern.toJson());

      expect(decoded, pattern);
      expect(decoded.width, 2);
      expect(decoded.height, 2);
      expect(decoded.anchorX, 0);
      expect(decoded.anchorY, 1);
      expect(decoded.repeatMode, SmartTilePatternRepeatMode.tiled);
      expect(
        decoded.cells.last.collision,
        SmartTilePatternCollision.blocked,
      );
      expect(decoded.cells.last.eraseMaterial, isTrue);
    });

    test('catalog v4 reads v3 with no patterns and writes patterns', () {
      final legacy = ProjectSmartTileCatalog.fromJson(
        <String, dynamic>{
          'formatVersion': 3,
          'categories': <Object?>[],
          'atlases': <Object?>[],
          'materials': <Object?>[],
          'animations': <Object?>[],
          'presets': <Object?>[],
          'drafts': <Object?>[],
        },
      );
      final current =
          ProjectSmartTileCatalog(patterns: <ProjectSmartTilePattern>[
        _pattern(),
      ]);

      expect(legacy.patterns, isEmpty);
      expect(legacy.formatVersion, 4);
      expect(current.toJson()['formatVersion'], 4);
      expect(
        ProjectSmartTileCatalog.fromJson(current.toJson()).patterns,
        current.patterns,
      );
    });

    test('catalog validation rejects duplicate cells and missing sources', () {
      final base = _pattern();
      final diagnostics = validateProjectSmartTileCatalog(
        catalog: ProjectSmartTileCatalog(
          patterns: <ProjectSmartTilePattern>[
            base.copyWith(
              cells: <SmartTilePatternCell>[
                base.cells.first,
                base.cells.first,
              ],
            ),
          ],
        ),
        projectTilesetIds: const <String>[],
      );
      final codes = diagnostics.map((diagnostic) => diagnostic.code).toSet();

      expect(codes, contains('smart_tiles.pattern.cell_duplicate'));
      expect(codes, contains('smart_tiles.reference.atlas_missing'));
    });
  });

  group('Smart Tile pattern gestures', () {
    test('stamp aligns the authored anchor and reports collision updates', () {
      final result = applySmartTilePatternGesture(
        _layer(),
        pattern: _pattern(),
        mapSize: const GridSize(width: 5, height: 4),
        selection: const SmartTilePatternSelection.stamp(
          anchor: GridPos(x: 2, y: 2),
        ),
        strokeId: 'stamp-1',
      );

      expect(
        result.affectedCells,
        const <GridPos>[
          GridPos(x: 2, y: 1),
          GridPos(x: 3, y: 1),
          GridPos(x: 2, y: 2),
          GridPos(x: 3, y: 2),
        ],
      );
      final stroke = result.layer.patternStrokes.single;
      expect(stroke.phaseX, -2);
      expect(stroke.phaseY, -1);
      expect(
        smartTilePatternCellAt(
          pattern: _pattern(),
          stroke: stroke,
          cell: const GridPos(x: 2, y: 2),
        )?.y,
        1,
      );
      expect(
        result.collisionUpdates,
        contains(
          const SmartTilePatternCollisionUpdate(
            cell: GridPos(x: 3, y: 2),
            blocked: true,
          ),
        ),
      );
      expect(
        smartTileMaterialIdAt(
          result.layer,
          mapSize: const GridSize(width: 5, height: 4),
          x: 3,
          y: 2,
        ),
        isNull,
      );
    });

    test('line and rectangle repeat deterministically and erase by cell', () {
      final line = applySmartTilePatternGesture(
        _layer(),
        pattern: _pattern(),
        mapSize: const GridSize(width: 5, height: 4),
        selection: const SmartTilePatternSelection.line(
          start: GridPos(x: 0, y: 0),
          end: GridPos(x: 3, y: 0),
        ),
        strokeId: 'line-1',
      );
      final rectangle = applySmartTilePatternGesture(
        line.layer,
        pattern: _pattern(),
        mapSize: const GridSize(width: 5, height: 4),
        selection: const SmartTilePatternSelection.rectangle(
          start: GridPos(x: 0, y: 1),
          end: GridPos(x: 1, y: 2),
        ),
        strokeId: 'rectangle-1',
        phaseX: 1,
      );

      expect(line.affectedCells, hasLength(4));
      expect(rectangle.affectedCells, hasLength(4));
      expect(rectangle.layer.patternStrokes, hasLength(2));
      expect(
        smartTilePatternCellAt(
          pattern: _pattern(),
          stroke: line.layer.patternStrokes.single,
          cell: const GridPos(x: 0, y: 0),
        )?.x,
        0,
      );
      expect(
        smartTilePatternCellAt(
          pattern: _pattern(),
          stroke: line.layer.patternStrokes.single,
          cell: const GridPos(x: 1, y: 0),
        )?.x,
        1,
      );

      final erased = eraseSmartTilePatternCells(
        rectangle.layer,
        mapSize: const GridSize(width: 5, height: 4),
        cells: const <GridPos>[
          GridPos(x: 1, y: 0),
          GridPos(x: 0, y: 1),
        ],
      );
      expect(erased.patternStrokes, hasLength(2));
      expect(
        erased.patternStrokes.first.cells,
        isNot(contains(const GridPos(x: 1, y: 0))),
      );
      expect(
        erased.patternStrokes.last.cells,
        isNot(contains(const GridPos(x: 0, y: 1))),
      );
    });
  });

  test('shared resolver overlays the last periodic pattern stroke', () {
    final applied = applySmartTilePatternGesture(
      _layer(cellCount: 4),
      pattern: _pattern(),
      mapSize: const GridSize(width: 2, height: 2),
      selection: const SmartTilePatternSelection.rectangle(
        start: GridPos(x: 0, y: 0),
        end: GridPos(x: 1, y: 1),
      ),
      strokeId: 'fill',
    );
    final map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v6,
      size: const GridSize(width: 2, height: 2),
      layers: <MapLayer>[applied.layer],
    );
    final visuals = resolveSmartTileLayerVisuals(
      map: map,
      layer: applied.layer,
      catalog: _catalog(),
      pass: SmartTileVisualPass.background,
      destinationCellWidth: 32,
      destinationCellHeight: 32,
      sourceCellWidth: 32,
      sourceCellHeight: 32,
    );
    final patternVisuals = visuals
        .where((visual) => visual.ruleId == 'pattern:checker')
        .toList(growable: false);

    expect(patternVisuals, hasLength(4));
    expect(patternVisuals[0].sourceRect.x, 0);
    expect(patternVisuals[1].sourceRect.x, 32);
    expect(patternVisuals[2].sourceRect.y, 32);
    expect(patternVisuals[3].drawOrder, 50);
  });

  test('map validation checks pattern stroke structure and bounds', () {
    final applied = applySmartTilePatternGesture(
      _layer(cellCount: 4),
      pattern: _pattern(),
      mapSize: const GridSize(width: 2, height: 2),
      selection: const SmartTilePatternSelection.rectangle(
        start: GridPos(x: 0, y: 0),
        end: GridPos(x: 1, y: 1),
      ),
      strokeId: 'fill',
    );
    final validMap = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v6,
      size: const GridSize(width: 2, height: 2),
      layers: <MapLayer>[applied.layer],
    );
    final invalidMap = validMap.copyWith(
      layers: <MapLayer>[
        applied.layer.copyWith(
          patternStrokes: <SmartTilePatternStroke>[
            applied.layer.patternStrokes.single.copyWith(
              cells: const <GridPos>[GridPos(x: 2, y: 0)],
            ),
          ],
        ),
      ],
    );

    expect(() => MapValidator.validate(validMap), returnsNormally);
    expect(
      () => MapValidator.validate(invalidMap),
      throwsA(
        isA<ValidationException>().having(
          (error) => error.code,
          'code',
          'smart_tile_pattern_stroke_cell_out_of_bounds',
        ),
      ),
    );
  });

  test('resize planning and layer union retain explicit pattern ownership', () {
    final patterned = applySmartTilePatternGesture(
      _layer(cellCount: 4),
      pattern: _pattern(),
      mapSize: const GridSize(width: 2, height: 2),
      selection: const SmartTilePatternSelection.stamp(
        anchor: GridPos(x: 1, y: 1),
      ),
      strokeId: 'same',
    ).layer;
    final map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v6,
      size: const GridSize(width: 2, height: 2),
      layers: <MapLayer>[patterned],
    );
    final plan = planMapResize(map, width: 1, height: 1);
    final union = unionSmartTileLayers(
      target: patterned,
      sources: <SmartTileLayer>[patterned.copyWith(id: 'source')],
    );

    expect(plan.canApply, isFalse);
    expect(
      plan.impacts.single.positions,
      contains(const GridPos(x: 1, y: 1)),
    );
    expect(union.layer.patternStrokes, hasLength(2));
    expect(
      union.layer.patternStrokes.map((stroke) => stroke.id).toSet(),
      hasLength(2),
    );
  });
}

ProjectSmartTilePattern _pattern() => const ProjectSmartTilePattern(
      id: 'checker',
      name: 'Checker',
      usage: SmartTileUsage.path,
      width: 2,
      height: 2,
      anchorX: 0,
      anchorY: 1,
      repeatMode: SmartTilePatternRepeatMode.tiled,
      drawOrder: 50,
      cells: <SmartTilePatternCell>[
        SmartTilePatternCell(
          x: 0,
          y: 0,
          parts: <SmartTileVisualPart>[
            SmartTileVisualPart(
              source: SmartTileVisualSource.frame(
                frame: SmartTileFrameRef(
                  atlasId: 'atlas',
                  column: 0,
                  row: 0,
                ),
              ),
            ),
          ],
        ),
        SmartTilePatternCell(
          x: 1,
          y: 0,
          collision: SmartTilePatternCollision.passable,
          parts: <SmartTileVisualPart>[
            SmartTileVisualPart(
              source: SmartTileVisualSource.frame(
                frame: SmartTileFrameRef(
                  atlasId: 'atlas',
                  column: 1,
                  row: 0,
                ),
              ),
            ),
          ],
        ),
        SmartTilePatternCell(
          x: 0,
          y: 1,
          parts: <SmartTileVisualPart>[
            SmartTileVisualPart(
              source: SmartTileVisualSource.frame(
                frame: SmartTileFrameRef(
                  atlasId: 'atlas',
                  column: 0,
                  row: 1,
                ),
              ),
            ),
          ],
        ),
        SmartTilePatternCell(
          x: 1,
          y: 1,
          eraseMaterial: true,
          collision: SmartTilePatternCollision.blocked,
          parts: <SmartTileVisualPart>[
            SmartTileVisualPart(
              source: SmartTileVisualSource.frame(
                frame: SmartTileFrameRef(
                  atlasId: 'atlas',
                  column: 1,
                  row: 1,
                ),
              ),
            ),
          ],
        ),
      ],
    );

SmartTileLayer _layer({int cellCount = 20}) => SmartTileLayer(
      id: 'path',
      name: 'Path',
      presetId: 'path',
      usage: SmartTileUsage.path,
      materialPalette: const <String>['', 'dirt'],
      field: SmartTileField.cell(
        semanticCells: List<int>.filled(cellCount, 1),
      ),
    );

ProjectSmartTileCatalog _catalog() => ProjectSmartTileCatalog(
      atlases: const <ProjectSmartTileAtlas>[
        ProjectSmartTileAtlas(
          id: 'atlas',
          name: 'Atlas',
          tilesetId: 'tiles',
          columns: 2,
          rows: 2,
        ),
      ],
      materials: const <ProjectSmartTileMaterial>[
        ProjectSmartTileMaterial(
          id: 'dirt',
          name: 'Dirt',
          connectionGroupId: 'dirt',
        ),
      ],
      presets: const <ProjectSmartTilePreset>[
        ProjectSmartTilePreset(
          id: 'path',
          name: 'Path',
          usage: SmartTileUsage.path,
          topology: SmartTileTopology.uniform,
          coveragePolicy: SmartTileCoveragePolicy.sparse,
          coverageProfile: SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.explicit,
          ),
          transformPolicy: SmartTileTransformPolicy(),
          defaultMaterialId: 'dirt',
          allowedMaterialIds: <String>['dirt'],
          rules: <SmartTileRule>[
            SmartTileRule(
              id: 'base',
              centerMatch: SmartTileSlotMatch.material('dirt'),
            ),
          ],
        ),
      ],
      patterns: <ProjectSmartTilePattern>[_pattern()],
    );
