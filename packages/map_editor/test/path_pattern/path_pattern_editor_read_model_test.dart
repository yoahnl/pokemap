import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/path_studio/path_pattern_editor_read_model.dart';

void main() {
  group('createPathPatternEditorReadModel', () {
    test('empty manifest exposes an empty summary and no cards', () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(),
      );

      expect(readModel.presets, isEmpty);
      expect(readModel.summary.totalCount, 0);
      expect(readModel.summary.readyCount, 0);
      expect(readModel.summary.issueCount, 0);
      expect(readModel.summary.multiCellCenterCount, 0);
      expect(readModel.summary.transparentColorCount, 0);
      expect(readModel.summary.missingBasePathPresetCount, 0);
      expect(readModel.summary.duplicatePathPatternIdCount, 0);
      expect(readModel.summary.duplicateBasePathPresetIdCount, 0);
    });

    test('ready 1x1 preset exposes list card details', () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
          pathPatternPresets: [
            _pathPatternPreset(
              id: 'water-1x1',
              name: 'Water 1x1',
              basePathPresetId: 'legacy-water',
              pattern: _singleCellPattern(),
            ),
          ],
        ),
      );

      expect(readModel.summary.totalCount, 1);
      expect(readModel.summary.readyCount, 1);
      expect(readModel.summary.issueCount, 0);

      final card = readModel.presets.single;
      expect(card.id, 'water-1x1');
      expect(card.name, 'Water 1x1');
      expect(card.basePathPresetId, 'legacy-water');
      expect(card.basePathPresetName, 'Legacy Water');
      expect(card.basePathSurfaceKindLabel, 'Eau');
      expect(card.centerPatternLabel, '1×1');
      expect(card.centerWidth, 1);
      expect(card.centerHeight, 1);
      expect(card.centerCellCount, 1);
      expect(card.centerFrameCount, 1);
      expect(card.animatedCellCount, 0);
      expect(card.transparentColorHex, isNull);
      expect(card.status, PathPatternPresetReadinessStatus.ready);
      expect(card.hasBlockingDiagnostics, isFalse);
      expect(card.warningCount, 0);
    });

    test('ready 2x2 transparent animated preset exposes counts', () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
          pathPatternPresets: [
            _pathPatternPreset(
              id: 'sea-2x2',
              basePathPresetId: 'legacy-water',
              pattern: _twoByTwoPattern(animatedTopLeft: true),
              transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
            ),
          ],
        ),
      );

      final card = readModel.presets.single;
      expect(card.centerPatternLabel, '2×2');
      expect(card.centerWidth, 2);
      expect(card.centerHeight, 2);
      expect(card.centerCellCount, 4);
      expect(card.centerFrameCount, 5);
      expect(card.animatedCellCount, 1);
      expect(card.transparentColorHex, 'f05ba1');
      expect(card.status, PathPatternPresetReadinessStatus.ready);
      expect(readModel.summary.readyCount, 1);
      expect(readModel.summary.multiCellCenterCount, 1);
      expect(readModel.summary.transparentColorCount, 1);
    });

    test('missing basePathPresetId blocks the card', () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
          pathPatternPresets: [
            _pathPatternPreset(
              id: 'missing-base',
              basePathPresetId: 'missing',
            ),
          ],
        ),
      );

      final card = readModel.presets.single;
      expect(card.status, PathPatternPresetReadinessStatus.blocked);
      expect(
        card.issues,
        contains(PathPatternPresetIssueCode.missingBasePathPreset),
      );
      expect(card.basePathPresetName, isNull);
      expect(card.basePathSurfaceKindLabel, isNull);
      expect(readModel.summary.readyCount, 0);
      expect(readModel.summary.issueCount, 1);
      expect(readModel.summary.missingBasePathPresetCount, 1);
    });

    test('duplicate PathPattern ids block every affected card', () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
          pathPatternPresets: [
            _pathPatternPreset(id: 'duplicate'),
            _pathPatternPreset(id: 'duplicate', name: 'Duplicate 2'),
          ],
        ),
      );

      expect(readModel.presets, hasLength(2));
      for (final card in readModel.presets) {
        expect(card.status, PathPatternPresetReadinessStatus.blocked);
        expect(
          card.issues,
          contains(PathPatternPresetIssueCode.duplicatePathPatternId),
        );
      }
      expect(readModel.summary.readyCount, 0);
      expect(readModel.summary.issueCount, 2);
      expect(readModel.summary.duplicatePathPatternIdCount, 2);
    });

    test('duplicate legacy base path preset ids block referencing cards', () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          pathPresets: [
            _legacyPathPreset(id: 'legacy-water', name: 'Water A'),
            _legacyPathPreset(id: 'legacy-water', name: 'Water B'),
          ],
          pathPatternPresets: [
            _pathPatternPreset(
              id: 'ambiguous-base',
              basePathPresetId: 'legacy-water',
            ),
          ],
        ),
      );

      final card = readModel.presets.single;
      expect(card.status, PathPatternPresetReadinessStatus.blocked);
      expect(
        card.issues,
        contains(PathPatternPresetIssueCode.duplicateBasePathPresetId),
      );
      expect(card.basePathPresetName, isNull);
      expect(card.basePathSurfaceKindLabel, isNull);
      expect(readModel.summary.issueCount, 1);
      expect(readModel.summary.duplicateBasePathPresetIdCount, 1);
    });

    test('duplicate path patterns for the same base are blocked as ambiguous',
        () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
          pathPatternPresets: [
            _pathPatternPreset(id: 'water-a', basePathPresetId: 'legacy-water'),
            _pathPatternPreset(id: 'water-b', basePathPresetId: 'legacy-water'),
          ],
        ),
      );

      expect(readModel.summary.blockedCount, 2);
      expect(readModel.summary.ambiguousCount, 2);
      for (final card in readModel.presets) {
        expect(card.status, PathPatternPresetReadinessStatus.blocked);
        expect(
          card.issues,
          contains(PathPatternPresetIssueCode.duplicatePathPatternForBase),
        );
        expect(
          card.issues,
          contains(PathPatternPresetIssueCode.pathPatternRenderAmbiguous),
        );
      }
    });

    test('missing base tileset is blocking', () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          pathPresets: [
            _legacyPathPreset(id: 'legacy-water', tilesetId: 'missing-tileset'),
          ],
          pathPatternPresets: [_pathPatternPreset(id: 'water')],
        ),
      );

      final card = readModel.presets.single;
      expect(card.status, PathPatternPresetReadinessStatus.blocked);
      expect(
        card.issues,
        contains(PathPatternPresetIssueCode.missingBaseTileset),
      );
      expect(card.hasBlockingDiagnostics, isTrue);
    });

    test('missing frame tileset override is blocking', () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          tilesets: [_tileset(id: 'tileset-main')],
          pathPresets: [
            _legacyPathPreset(id: 'legacy-water', tilesetId: 'tileset-main'),
          ],
          pathPatternPresets: [
            _pathPatternPreset(
              id: 'water',
              pattern: _singleCellPattern(frameTilesetId: 'ghost-tileset'),
            ),
          ],
        ),
      );

      final card = readModel.presets.single;
      expect(card.status, PathPatternPresetReadinessStatus.blocked);
      expect(
        card.issues,
        contains(PathPatternPresetIssueCode.missingFrameTileset),
      );
    });

    test('center-only with empty variants stays needsReview and non-blocking',
        () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          tilesets: [_tileset(id: 'tileset-main')],
          pathPresets: [
            _legacyPathPreset(
              id: 'legacy-water',
              tilesetId: 'tileset-main',
              variants: const [],
            ),
          ],
          pathPatternPresets: [_pathPatternPreset(id: 'water')],
        ),
      );

      final card = readModel.presets.single;
      expect(card.status, PathPatternPresetReadinessStatus.needsReview);
      expect(card.hasBlockingDiagnostics, isFalse);
      expect(
        card.issues,
        contains(PathPatternPresetIssueCode.centerOnly),
      );
      expect(
        card.issues,
        contains(PathPatternPresetIssueCode.noVariantCoverage),
      );
    });

    test('partial variants is warning without blocking', () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          tilesets: [_tileset(id: 'tileset-main')],
          pathPresets: [
            _legacyPathPreset(
              id: 'legacy-water',
              tilesetId: 'tileset-main',
              variants: [
                const PathPresetVariantMapping(
                  variant: TerrainPathVariant.isolated,
                  frames: [
                    TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))
                  ],
                ),
              ],
            ),
          ],
          pathPatternPresets: [_pathPatternPreset(id: 'water')],
        ),
      );

      final card = readModel.presets.single;
      expect(card.status, PathPatternPresetReadinessStatus.needsReview);
      expect(card.hasBlockingDiagnostics, isFalse);
      expect(
        card.issues,
        contains(PathPatternPresetIssueCode.partialVariantCoverage),
      );
    });

    test('cross variant emits informational diagnostic', () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          tilesets: [_tileset(id: 'tileset-main')],
          pathPresets: [
            _legacyPathPreset(
              id: 'legacy-water',
              tilesetId: 'tileset-main',
              variants: [
                const PathPresetVariantMapping(
                  variant: TerrainPathVariant.cross,
                  frames: [
                    TilesetVisualFrame(source: TilesetSourceRect(x: 5, y: 5))
                  ],
                ),
              ],
            ),
          ],
          pathPatternPresets: [_pathPatternPreset(id: 'water')],
        ),
      );

      final card = readModel.presets.single;
      expect(
        card.issues,
        contains(PathPatternPresetIssueCode.crossHandledByCenterPattern),
      );
      expect(card.infoCount, greaterThan(0));
    });

    test('fully configured pattern is ready', () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          tilesets: [_tileset(id: 'tileset-main')],
          pathPresets: [
            _legacyPathPreset(
              id: 'legacy-water',
              tilesetId: 'tileset-main',
              variants: [
                for (final variant in TerrainPathVariant.values)
                  PathPresetVariantMapping(
                    variant: variant,
                    frames: const [
                      TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
                    ],
                  ),
              ],
            ),
          ],
          pathPatternPresets: [_pathPatternPreset(id: 'water')],
        ),
      );

      final card = readModel.presets.single;
      expect(card.status, PathPatternPresetReadinessStatus.ready);
      expect(card.hasBlockingDiagnostics, isFalse);
      expect(card.warningCount, 0);
    });

    test('preserves manifest pathPatternPresets order', () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
          pathPatternPresets: [
            _pathPatternPreset(id: 'a'),
            _pathPatternPreset(id: 'b'),
            _pathPatternPreset(id: 'c'),
          ],
        ),
      );

      expect(readModel.presets.map((card) => card.id), ['a', 'b', 'c']);
    });

    test('matches basePathPresetId exactly without trimming', () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
          pathPatternPresets: [
            _pathPatternPreset(
              id: 'whitespace-base',
              basePathPresetId: ' legacy-water ',
            ),
          ],
        ),
      );

      final card = readModel.presets.single;
      expect(card.status, PathPatternPresetReadinessStatus.blocked);
      expect(
        card.issues,
        contains(PathPatternPresetIssueCode.missingBasePathPreset),
      );
      expect(readModel.summary.missingBasePathPresetCount, 1);
    });

    test('ids that differ only by spaces are distinct exact ids', () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          pathPresets: [
            _legacyPathPreset(id: 'legacy-water'),
            _legacyPathPreset(id: ' legacy-water ', name: 'Spaced Water'),
          ],
          pathPatternPresets: [
            _pathPatternPreset(id: 'water', basePathPresetId: 'legacy-water'),
            _pathPatternPreset(
              id: ' water ',
              basePathPresetId: ' legacy-water ',
            ),
          ],
        ),
      );

      expect(readModel.summary.totalCount, 2);
      expect(readModel.summary.readyCount, 2);
      expect(readModel.summary.issueCount, 0);
      expect(readModel.summary.duplicatePathPatternIdCount, 0);
      expect(readModel.summary.duplicateBasePathPresetIdCount, 0);
      expect(readModel.presets.map((card) => card.basePathPresetName), [
        'Legacy Water',
        'Spaced Water',
      ]);
    });

    test('summary counts ready, blocked, duplicates, and multi-cell presets',
        () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
          pathPatternPresets: [
            _pathPatternPreset(id: 'ready', pattern: _twoByTwoPattern()),
            _pathPatternPreset(
              id: 'missing-base',
              basePathPresetId: 'missing',
            ),
            _pathPatternPreset(id: 'duplicate'),
            _pathPatternPreset(id: 'duplicate', name: 'Duplicate 2'),
          ],
        ),
      );

      expect(readModel.summary.totalCount, 4);
      expect(readModel.summary.readyCount, 0);
      expect(readModel.summary.issueCount, 4);
      expect(readModel.summary.multiCellCenterCount, 1);
      expect(readModel.summary.missingBasePathPresetCount, 1);
      expect(readModel.summary.duplicatePathPatternIdCount, 2);
      expect(readModel.summary.duplicateBasePathPresetIdCount, 0);
      expect(readModel.summary.ambiguousCount, 3);
    });

    test('read model and card lists are immutable defensive copies', () {
      final readModel = createPathPatternEditorReadModel(
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
          pathPatternPresets: [_pathPatternPreset(id: 'ready')],
        ),
      );

      expect(
        () => readModel.presets.add(readModel.presets.single),
        throwsUnsupportedError,
      );
      expect(
        () => readModel.presets.single.issues.add(
          PathPatternPresetIssueCode.missingBasePathPreset,
        ),
        throwsUnsupportedError,
      );
    });

    test('read model, summary, and card use value equality', () {
      final manifest = _manifest(
        pathPresets: [_legacyPathPreset(id: 'legacy-water')],
        pathPatternPresets: [
          _pathPatternPreset(
            id: 'sea-2x2',
            pattern: _twoByTwoPattern(animatedTopLeft: true),
            transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
          ),
        ],
      );

      final first = createPathPatternEditorReadModel(manifest: manifest);
      final second = createPathPatternEditorReadModel(manifest: manifest);
      final different = createPathPatternEditorReadModel(
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
          pathPatternPresets: [_pathPatternPreset(id: 'different')],
        ),
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first.summary, second.summary);
      expect(first.summary.hashCode, second.summary.hashCode);
      expect(first.presets.single, second.presets.single);
      expect(first.presets.single.hashCode, second.presets.single.hashCode);
      expect(first, isNot(different));
    });
  });
}

ProjectManifest _manifest({
  List<ProjectTilesetEntry> tilesets = const [],
  List<ProjectPathPreset> pathPresets = const [],
  List<ProjectPathPatternPreset> pathPatternPresets = const [],
}) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: tilesets,
    pathPresets: pathPresets,
    pathPatternPresets: pathPatternPresets,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

ProjectPathPreset _legacyPathPreset({
  required String id,
  String name = 'Legacy Water',
  PathSurfaceKind surfaceKind = PathSurfaceKind.water,
  String tilesetId = '',
  List<PathPresetVariantMapping>? variants,
}) {
  return ProjectPathPreset(
    id: id,
    name: name,
    surfaceKind: surfaceKind,
    tilesetId: tilesetId,
    variants: variants ?? _allVariantMappings(),
  );
}

ProjectPathPatternPreset _pathPatternPreset({
  required String id,
  String? name,
  String basePathPresetId = 'legacy-water',
  PathCenterPattern? pattern,
  TilesetTransparentColor? transparentColor,
}) {
  return ProjectPathPatternPreset(
    id: id,
    name: name ?? id,
    basePathPresetId: basePathPresetId,
    centerPattern: pattern ?? _singleCellPattern(),
    transparentColor: transparentColor,
  );
}

PathCenterPattern _singleCellPattern({String frameTilesetId = ''}) {
  return PathCenterPattern(
    size: PathCenterPatternSize(width: 1, height: 1),
    cells: [
      PathCenterPatternCell(
        localX: 0,
        localY: 0,
        frames: [_frame(0, tilesetId: frameTilesetId)],
      ),
    ],
  );
}

PathCenterPattern _twoByTwoPattern({bool animatedTopLeft = false}) {
  return PathCenterPattern(
    size: PathCenterPatternSize(width: 2, height: 2),
    cells: [
      PathCenterPatternCell(
        localX: 0,
        localY: 0,
        frames: animatedTopLeft ? [_frame(0), _frame(1)] : [_frame(0)],
      ),
      PathCenterPatternCell(
        localX: 1,
        localY: 0,
        frames: [_frame(2)],
      ),
      PathCenterPatternCell(
        localX: 0,
        localY: 1,
        frames: [_frame(3)],
      ),
      PathCenterPatternCell(
        localX: 1,
        localY: 1,
        frames: [_frame(4)],
      ),
    ],
  );
}

TilesetVisualFrame _frame(int sourceX, {String tilesetId = ''}) {
  return TilesetVisualFrame(
    source: TilesetSourceRect(x: sourceX, y: 0),
    tilesetId: tilesetId,
  );
}

ProjectTilesetEntry _tileset({required String id}) {
  return ProjectTilesetEntry(
      id: id, name: id, relativePath: 'tilesets/$id.png');
}

List<PathPresetVariantMapping> _allVariantMappings() {
  return [
    for (final variant in TerrainPathVariant.values)
      PathPresetVariantMapping(
        variant: variant,
        frames: const [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
        ],
      ),
  ];
}
