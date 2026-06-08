import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/path_studio/path_studio_new_path_draft.dart';

void main() {
  group('PathStudioNewPathDraft', () {
    test('creates an initial draft without a legacy ProjectPathPreset', () {
      final draft = createInitialPathStudioNewPathDraft();

      expect(draft.id, 'draft-new-path');
      expect(draft.name, 'Nouveau chemin');
      expect(draft.centerWidth, 1);
      expect(draft.centerHeight, 1);
      expect(draft.centerPatternLabel, '1×1');
      expect(draft.centerCellCount, 1);
      expect(draft.tilesetId, isNull);
      expect(draft.selectedCellX, 0);
      expect(draft.selectedCellY, 0);
      expect(draft.surfaceKind, PathSurfaceKind.path);
      // Lot PathPattern-40 : dirty uniquement après une action utilisateur.
      expect(draft.isDirty, isFalse);
      expect(draft.cells.map((cell) => cell.label), ['A']);
      expect(draft.issues, [
        PathStudioNewPathDraftIssueCode.tilesetNotConfigured,
        PathStudioNewPathDraftIssueCode.cellsNotConfigured,
      ]);
      expect(
        PathStudioNewPathDraft.requiredVariants.contains(
          TerrainPathVariant.cross,
        ),
        isFalse,
      );
    });

    test('selects a tileset while preserving center size and selection', () {
      final draft = createInitialPathStudioNewPathDraft();

      final selected = selectPathStudioNewPathDraftTileset(
        draft,
        'tileset-main',
      );

      expect(selected.tilesetId, 'tileset-main');
      expect(selected.issues, [
        PathStudioNewPathDraftIssueCode.cellsNotConfigured,
      ]);
      expect(selected.centerPatternLabel, '1×1');
      expect(selected.selectedCellX, 0);
      expect(selected.selectedCellY, 0);
      expect(selected.isDirty, isTrue);
    });

    test('assigns one V0 tile to the 1x1 cell and clears cell issue', () {
      final draft = selectPathStudioNewPathDraftTileset(
        createInitialPathStudioNewPathDraft(),
        'tileset-main',
      );

      final assigned = assignPathStudioNewPathDraftCellTile(
        draft: draft,
        localX: 0,
        localY: 0,
        sourceX: 2,
        sourceY: 3,
      );

      expect(assigned.configuredCellCount, 1);
      expect(assigned.issues, isEmpty);
      expect(
        assigned.selectedCell.tile,
        const PathStudioNewPathDraftTile(
          tilesetId: 'tileset-main',
          sourceX: 2,
          sourceY: 3,
        ),
      );
      expect(
        assigned.selectedCell.tile!.toFrame(),
        const TilesetVisualFrame(
          tilesetId: 'tileset-main',
          source: TilesetSourceRect(x: 2, y: 3),
        ),
      );
    });

    test('keeps cells issue until every 2x2 cell has one tile', () {
      var draft = resizePathStudioNewPathDraftCenter(
        draft: selectPathStudioNewPathDraftTileset(
          createInitialPathStudioNewPathDraft(),
          'tileset-main',
        ),
        width: 2,
        height: 2,
      );

      draft = assignPathStudioNewPathDraftCellTile(
        draft: draft,
        localX: 0,
        localY: 0,
        sourceX: 0,
        sourceY: 0,
      );
      expect(draft.configuredCellCount, 1);
      expect(
        draft.issues,
        contains(PathStudioNewPathDraftIssueCode.cellsNotConfigured),
      );

      draft = assignPathStudioNewPathDraftCellTile(
        draft: draft,
        localX: 1,
        localY: 0,
        sourceX: 1,
        sourceY: 0,
      );
      draft = assignPathStudioNewPathDraftCellTile(
        draft: draft,
        localX: 0,
        localY: 1,
        sourceX: 0,
        sourceY: 1,
      );
      draft = assignPathStudioNewPathDraftCellTile(
        draft: draft,
        localX: 1,
        localY: 1,
        sourceX: 1,
        sourceY: 1,
      );

      expect(draft.configuredCellCount, 4);
      expect(
        draft.issues,
        isNot(contains(PathStudioNewPathDraftIssueCode.cellsNotConfigured)),
      );
      expect(draft.issues, isEmpty);
    });

    test('replaces a configured cell instead of adding a second frame', () {
      final draft = selectPathStudioNewPathDraftTileset(
        createInitialPathStudioNewPathDraft(),
        'tileset-main',
      );
      final first = assignPathStudioNewPathDraftCellTile(
        draft: draft,
        localX: 0,
        localY: 0,
        sourceX: 0,
        sourceY: 0,
      );

      final replaced = assignPathStudioNewPathDraftCellTile(
        draft: first,
        localX: 0,
        localY: 0,
        sourceX: 4,
        sourceY: 2,
      );

      expect(replaced.configuredCellCount, 1);
      expect(
        replaced.selectedCell.tile,
        const PathStudioNewPathDraftTile(
          tilesetId: 'tileset-main',
          sourceX: 4,
          sourceY: 2,
        ),
      );
    });

    test('clears a configured required cell and restores cell issue', () {
      final assigned = assignPathStudioNewPathDraftCellTile(
        draft: selectPathStudioNewPathDraftTileset(
          createInitialPathStudioNewPathDraft(),
          'tileset-main',
        ),
        localX: 0,
        localY: 0,
        sourceX: 2,
        sourceY: 3,
      );

      final cleared = clearPathStudioNewPathDraftCell(
        draft: assigned,
        localX: 0,
        localY: 0,
      );

      expect(cleared.configuredCellCount, 0);
      expect(cleared.selectedCell.tile, isNull);
      expect(
        cleared.issues,
        contains(PathStudioNewPathDraftIssueCode.cellsNotConfigured),
      );
    });

    test('resizes a 1x1 draft to 2x2 while preserving cell A only', () {
      final draft = assignPathStudioNewPathDraftCellTile(
        draft: selectPathStudioNewPathDraftTileset(
          createInitialPathStudioNewPathDraft(),
          'tileset-main',
        ),
        localX: 0,
        localY: 0,
        sourceX: 2,
        sourceY: 3,
      );

      final resized = resizePathStudioNewPathDraftCenter(
        draft: draft,
        width: 2,
        height: 2,
      );

      expect(resized.tilesetId, 'tileset-main');
      expect(resized.centerPatternLabel, '2×2');
      expect(resized.centerCellCount, 4);
      expect(
        resized.cells.map((cell) => (cell.localX, cell.localY, cell.label)),
        [
          (0, 0, 'A'),
          (1, 0, 'B'),
          (0, 1, 'C'),
          (1, 1, 'D'),
        ],
      );
      expect(
        resized.cells.first.tile,
        const PathStudioNewPathDraftTile(
          tilesetId: 'tileset-main',
          sourceX: 2,
          sourceY: 3,
        ),
      );
      expect(resized.cells.skip(1).every((cell) => cell.tile == null), isTrue);
      expect(resized.selectedCellX, 0);
      expect(resized.selectedCellY, 0);
    });

    test('resizes a 2x2 draft back to 1x1 and keeps only cell A', () {
      var twoByTwo = resizePathStudioNewPathDraftCenter(
        draft: selectPathStudioNewPathDraftTileset(
          createInitialPathStudioNewPathDraft(),
          'tileset-main',
        ),
        width: 2,
        height: 2,
      );
      twoByTwo = assignPathStudioNewPathDraftCellTile(
        draft: twoByTwo,
        localX: 0,
        localY: 0,
        sourceX: 0,
        sourceY: 0,
      );
      twoByTwo = assignPathStudioNewPathDraftCellTile(
        draft: twoByTwo,
        localX: 1,
        localY: 1,
        sourceX: 4,
        sourceY: 4,
      );
      final selected = selectPathStudioNewPathDraftCell(
        draft: twoByTwo,
        localX: 1,
        localY: 1,
      );

      final resized = resizePathStudioNewPathDraftCenter(
        draft: selected,
        width: 1,
        height: 1,
      );

      expect(resized.centerWidth, 1);
      expect(resized.centerHeight, 1);
      expect(resized.centerCellCount, 1);
      expect(resized.selectedCellX, 0);
      expect(resized.selectedCellY, 0);
      expect(
        resized.selectedCell.tile,
        const PathStudioNewPathDraftTile(
          tilesetId: 'tileset-main',
          sourceX: 0,
          sourceY: 0,
        ),
      );
      expect(resized.configuredCellCount, 1);
    });

    test('selecting another tileset clears cell assignments deterministically',
        () {
      final assigned = assignPathStudioNewPathDraftCellTile(
        draft: selectPathStudioNewPathDraftTileset(
          createInitialPathStudioNewPathDraft(),
          'tileset-main',
        ),
        localX: 0,
        localY: 0,
        sourceX: 2,
        sourceY: 3,
      );

      final changed = selectPathStudioNewPathDraftTileset(
        assigned,
        'tileset-extra',
      );

      expect(changed.tilesetId, 'tileset-extra');
      expect(changed.configuredCellCount, 0);
      expect(changed.selectedCell.tile, isNull);
      expect(changed.issues, [
        PathStudioNewPathDraftIssueCode.cellsNotConfigured,
      ]);
    });

    test('renames the draft locally', () {
      final draft = renamePathStudioNewPathDraft(
        selectPathStudioNewPathDraftTileset(
          createInitialPathStudioNewPathDraft(),
          'tileset-main',
        ),
        'Route claire',
      );

      expect(draft.name, 'Route claire');
      expect(draft.tilesetId, 'tileset-main');
      expect(draft.isDirty, isTrue);
    });

    test('empty name after tileset selection exposes only remaining issues',
        () {
      final draft = renamePathStudioNewPathDraft(
        selectPathStudioNewPathDraftTileset(
          createInitialPathStudioNewPathDraft(),
          'tileset-main',
        ),
        '   ',
      );

      expect(draft.issues, [
        PathStudioNewPathDraftIssueCode.nameRequired,
        PathStudioNewPathDraftIssueCode.cellsNotConfigured,
      ]);
    });

    test('selects a placeholder cell by exact local coordinates', () {
      final draft = resizePathStudioNewPathDraftCenter(
        draft: createInitialPathStudioNewPathDraft(),
        width: 2,
        height: 2,
      );

      final selected = selectPathStudioNewPathDraftCell(
        draft: draft,
        localX: 1,
        localY: 0,
      );

      expect(selected.selectedCellX, 1);
      expect(selected.selectedCellY, 0);
      expect(selected.selectedCell.label, 'B');
    });

    test('assigns, replaces and clears variant mappings with progression', () {
      final draft = selectPathStudioNewPathDraftTileset(
        createInitialPathStudioNewPathDraft(),
        'tileset-main',
      );
      final variant = PathStudioNewPathDraft.requiredVariants.first;

      final assigned = assignPathStudioNewPathDraftVariantTile(
        draft: draft,
        variant: variant,
        sourceX: 6,
        sourceY: 2,
      );
      expect(assigned.configuredVariantCount, 1);
      expect(assigned.variantCellFrames[variant]?.firstOrNull?.tile.coordinateLabel, '6,2');

      final replaced = assignPathStudioNewPathDraftVariantTile(
        draft: assigned,
        variant: variant,
        sourceX: 1,
        sourceY: 7,
      );
      expect(replaced.configuredVariantCount, 1);
      expect(replaced.variantCellFrames[variant]?.firstOrNull?.tile.coordinateLabel, '1,7');

      final cleared = clearPathStudioNewPathDraftVariant(
        draft: replaced,
        variant: variant,
      );
      expect(cleared.configuredVariantCount, 0);
      expect(cleared.variantCellFrames[variant], isNull);
    });

    test('resize keeps variants, tileset change clears center and variants',
        () {
      final variant = PathStudioNewPathDraft.requiredVariants.first;
      final withVariant = assignPathStudioNewPathDraftVariantTile(
        draft: assignPathStudioNewPathDraftCellTile(
          draft: selectPathStudioNewPathDraftTileset(
            createInitialPathStudioNewPathDraft(),
            'tileset-main',
          ),
          localX: 0,
          localY: 0,
          sourceX: 2,
          sourceY: 3,
        ),
        variant: variant,
        sourceX: 8,
        sourceY: 1,
      );

      final resized = resizePathStudioNewPathDraftCenter(
        draft: withVariant,
        width: 2,
        height: 2,
      );
      expect(resized.variantCellFrames[variant]?.firstOrNull?.tile.coordinateLabel, '8,1');

      final changedTileset = selectPathStudioNewPathDraftTileset(
        resized,
        'tileset-extra',
      );
      expect(changedTileset.configuredCellCount, 0);
      expect(changedTileset.configuredVariantCount, 0);
    });

    test('surface kind can be selected locally', () {
      final draft = selectPathStudioNewPathDraftSurfaceKind(
        draft: createInitialPathStudioNewPathDraft(),
        surfaceKind: PathSurfaceKind.road,
      );
      expect(draft.surfaceKind, PathSurfaceKind.road);
    });

    test('variant mapping is optional for draft blocking diagnostics', () {
      var draft = assignPathStudioNewPathDraftCellTile(
        draft: selectPathStudioNewPathDraftTileset(
          createInitialPathStudioNewPathDraft(),
          'tileset-main',
        ),
        localX: 0,
        localY: 0,
        sourceX: 0,
        sourceY: 0,
      );
      for (var i = 0;
          i < PathStudioNewPathDraft.requiredVariants.length;
          i += 1) {
        draft = assignPathStudioNewPathDraftVariantTile(
          draft: draft,
          variant: PathStudioNewPathDraft.requiredVariants[i],
          sourceX: i % 8,
          sourceY: i ~/ 8,
        );
      }
      expect(draft.issues, isEmpty);
    });

    test('append center frame duplicates selected frame tile and duration', () {
      var draft = assignPathStudioNewPathDraftCellTile(
        draft: selectPathStudioNewPathDraftTileset(
          createInitialPathStudioNewPathDraft(),
          'tileset-main',
        ),
        localX: 0,
        localY: 0,
        sourceX: 2,
        sourceY: 3,
      );
      draft = updatePathStudioNewPathDraftCenterFrameDuration(
        draft: draft,
        localX: 0,
        localY: 0,
        frameIndex: 0,
        durationMs: 120,
      );

      final appended = appendPathStudioNewPathDraftCenterFrame(
        draft: draft,
        localX: 0,
        localY: 0,
      );

      expect(appended.selectedCell.frames.length, 2);
      expect(appended.selectedCell.frames[1].tile.coordinateLabel, '2,3');
      expect(appended.selectedCell.frames[1].durationMs, 120);
      expect(appended.totalCenterFrameCount, 2);
      expect(appended.animatedCenterCellCount, 1);
    });

    test('remove center frame can make cell non configured', () {
      final draft = assignPathStudioNewPathDraftCellTile(
        draft: selectPathStudioNewPathDraftTileset(
          createInitialPathStudioNewPathDraft(),
          'tileset-main',
        ),
        localX: 0,
        localY: 0,
        sourceX: 2,
        sourceY: 3,
      );

      final removed = removePathStudioNewPathDraftCenterFrame(
        draft: draft,
        localX: 0,
        localY: 0,
        frameIndex: 0,
      );

      expect(removed.selectedCell.frames, isEmpty);
      expect(removed.configuredCellCount, 0);
      expect(
        removed.issues,
        contains(PathStudioNewPathDraftIssueCode.cellsNotConfigured),
      );
    });

    test('update center frame duration only updates targeted frame', () {
      var draft = assignPathStudioNewPathDraftCellTile(
        draft: selectPathStudioNewPathDraftTileset(
          createInitialPathStudioNewPathDraft(),
          'tileset-main',
        ),
        localX: 0,
        localY: 0,
        sourceX: 1,
        sourceY: 1,
      );
      draft = appendPathStudioNewPathDraftCenterFrame(
        draft: draft,
        localX: 0,
        localY: 0,
      );
      draft = assignPathStudioNewPathDraftCellTile(
        draft: draft,
        localX: 0,
        localY: 0,
        sourceX: 4,
        sourceY: 4,
      );

      final updated = updatePathStudioNewPathDraftCenterFrameDuration(
        draft: draft,
        localX: 0,
        localY: 0,
        frameIndex: 1,
        durationMs: 333,
      );

      expect(updated.selectedCell.frames[0].durationMs, 200);
      expect(updated.selectedCell.frames[1].durationMs, 333);
      expect(updated.selectedCell.frames[1].tile.coordinateLabel, '4,4');
    });

    test('update center frame duration rejects non-positive values', () {
      final draft = assignPathStudioNewPathDraftCellTile(
        draft: selectPathStudioNewPathDraftTileset(
          createInitialPathStudioNewPathDraft(),
          'tileset-main',
        ),
        localX: 0,
        localY: 0,
        sourceX: 1,
        sourceY: 1,
      );

      expect(
        () => updatePathStudioNewPathDraftCenterFrameDuration(
          draft: draft,
          localX: 0,
          localY: 0,
          frameIndex: 0,
          durationMs: 0,
        ),
        throwsArgumentError,
      );
    });

    test('resize keeps multi-frame cell A when switching 1x1 and 2x2', () {
      var draft = assignPathStudioNewPathDraftCellTile(
        draft: selectPathStudioNewPathDraftTileset(
          createInitialPathStudioNewPathDraft(),
          'tileset-main',
        ),
        localX: 0,
        localY: 0,
        sourceX: 1,
        sourceY: 1,
      );
      draft = appendPathStudioNewPathDraftCenterFrame(
        draft: draft,
        localX: 0,
        localY: 0,
      );
      draft = assignPathStudioNewPathDraftCellTile(
        draft: draft,
        localX: 0,
        localY: 0,
        sourceX: 2,
        sourceY: 2,
      );
      final expanded = resizePathStudioNewPathDraftCenter(
        draft: draft,
        width: 2,
        height: 2,
      );
      expect(expanded.cells.first.frames.length, 2);
      final reduced = resizePathStudioNewPathDraftCenter(
        draft: expanded,
        width: 1,
        height: 1,
      );
      expect(reduced.cells.single.frames.length, 2);
    });

    test('convertit un path pattern 1x1 existant en brouillon edit', () {
      const base = ProjectPathPreset(
        id: 'base-water',
        name: 'Base water',
        tilesetId: 'tileset-main',
        surfaceKind: PathSurfaceKind.water,
        variants: [
          PathPresetVariantMapping(
            variant: TerrainPathVariant.cross,
            frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 9, y: 9))],
          ),
          PathPresetVariantMapping(
            variant: TerrainPathVariant.endNorth,
            frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 2))],
          ),
        ],
      );
      final pattern = ProjectPathPatternPreset(
        id: 'water-pattern',
        name: 'Water pattern',
        basePathPresetId: 'base-water',
        centerPattern: PathCenterPattern(
          size: PathCenterPatternSize(width: 1, height: 1),
          cells: [
            PathCenterPatternCell(
              localX: 0,
              localY: 0,
              frames: [
                const TilesetVisualFrame(
                  source: TilesetSourceRect(x: 3, y: 4),
                  durationMs: 150,
                ),
                const TilesetVisualFrame(
                  tilesetId: 'tileset-alt',
                  source: TilesetSourceRect(x: 5, y: 6),
                  durationMs: 220,
                ),
              ],
            ),
          ],
        ),
      );

      final draft = createPathStudioEditDraftFromExistingPathPattern(
        pathPatternPreset: pattern,
        basePathPreset: base,
      );

      expect(draft.isEditMode, isTrue);
      expect(draft.isDirty, isFalse);
      expect(draft.id, 'base-water');
      expect(draft.pathPatternPresetId, 'water-pattern');
      expect(draft.name, 'Water pattern');
      expect(draft.surfaceKind, PathSurfaceKind.water);
      expect(draft.cells.single.frames.length, 2);
      expect(draft.cells.single.frames[0].tile.tilesetId, 'tileset-main');
      expect(draft.cells.single.frames[0].durationMs, 150);
      expect(draft.cells.single.frames[1].tile.tilesetId, 'tileset-alt');
      expect(draft.cells.single.frames[1].durationMs, 220);
      expect(
        draft.variantCellFrames[TerrainPathVariant.endNorth]?.firstOrNull?.tile.coordinateLabel,
        '1,2',
      );
      expect(
        draft.preservedVariantMappings
            .any((mapping) => mapping.variant == TerrainPathVariant.cross),
        isTrue,
      );
    });

    test('convertit un path pattern 2x2 existant en brouillon edit', () {
      const base = ProjectPathPreset(
        id: 'base-road',
        name: 'Base road',
        tilesetId: 'tileset-main',
      );
      final pattern = ProjectPathPatternPreset(
        id: 'road-pattern',
        name: 'Road pattern',
        basePathPresetId: 'base-road',
        centerPattern: PathCenterPattern(
          size: PathCenterPatternSize(width: 2, height: 2),
          cells: [
            PathCenterPatternCell(
              localX: 0,
              localY: 0,
              frames: [
                const TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))
              ],
            ),
            PathCenterPatternCell(
              localX: 1,
              localY: 0,
              frames: [
                const TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 0))
              ],
            ),
            PathCenterPatternCell(
              localX: 0,
              localY: 1,
              frames: [
                const TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 1))
              ],
            ),
            PathCenterPatternCell(
              localX: 1,
              localY: 1,
              frames: [
                const TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 1))
              ],
            ),
          ],
        ),
      );

      final draft = createPathStudioEditDraftFromExistingPathPattern(
        pathPatternPreset: pattern,
        basePathPreset: base,
      );

      expect(draft.centerPatternLabel, '2×2');
      expect(draft.centerCellCount, 4);
      expect(draft.configuredCellCount, 4);
      expect(draft.issues, isEmpty);
    });

    group('Lot PathPattern-40 edit draft dirty', () {
      PathStudioNewPathDraft sampleEditDraft() {
        const base = ProjectPathPreset(
          id: 'base-water',
          name: 'Base water',
          tilesetId: 'tileset-main',
          surfaceKind: PathSurfaceKind.water,
          variants: [
            PathPresetVariantMapping(
              variant: TerrainPathVariant.cross,
              frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 9, y: 9))],
            ),
          ],
        );
        final pattern = ProjectPathPatternPreset(
          id: 'water-pattern',
          name: 'Water pattern',
          basePathPresetId: 'base-water',
          centerPattern: PathCenterPattern(
            size: PathCenterPatternSize(width: 1, height: 1),
            cells: [
              PathCenterPatternCell(
                localX: 0,
                localY: 0,
                frames: [
                  const TilesetVisualFrame(
                    source: TilesetSourceRect(x: 3, y: 4),
                    durationMs: 150,
                  ),
                ],
              ),
            ],
          ),
        );
        return createPathStudioEditDraftFromExistingPathPattern(
          pathPatternPreset: pattern,
          basePathPreset: base,
        );
      }

      test('rename marks dirty', () {
        final renamed =
            renamePathStudioNewPathDraft(sampleEditDraft(), 'Autre nom');
        expect(renamed.isDirty, isTrue);
      });

      test('assign cell tile marks dirty', () {
        final touched = assignPathStudioNewPathDraftCellTile(
          draft: sampleEditDraft(),
          localX: 0,
          localY: 0,
          sourceX: 9,
          sourceY: 9,
        );
        expect(touched.isDirty, isTrue);
      });

      test('update frame duration marks dirty', () {
        final touched = updatePathStudioNewPathDraftCenterFrameDuration(
          draft: sampleEditDraft(),
          localX: 0,
          localY: 0,
          frameIndex: 0,
          durationMs: 400,
        );
        expect(touched.isDirty, isTrue);
        expect(touched.cells.single.frames.single.durationMs, 400);
      });

      test('sequence assistant marks dirty', () {
        final ok = generatePathStudioCenterAnimationSequence(
          draft: sampleEditDraft(),
          target: PathStudioCenterAnimationSequenceTarget.selectedCell,
          frameCount: 2,
          stepX: 1,
          stepY: 0,
          durationMs: 90,
        );
        expect(ok, isA<PathStudioCenterAnimationSequenceSuccess>());
        expect((ok as PathStudioCenterAnimationSequenceSuccess).draft.isDirty,
            isTrue);
      });

      test('clear cell marks dirty', () {
        final cleared = clearPathStudioNewPathDraftCell(
          draft: sampleEditDraft(),
          localX: 0,
          localY: 0,
        );
        expect(cleared.isDirty, isTrue);
      });

      test('remove frame marks dirty', () {
        final twoFrames = appendPathStudioNewPathDraftCenterFrame(
          draft: sampleEditDraft(),
          localX: 0,
          localY: 0,
        );
        expect(twoFrames.cells.single.frames.length, 2);
        final removed = removePathStudioNewPathDraftCenterFrame(
          draft: twoFrames,
          localX: 0,
          localY: 0,
          frameIndex: 1,
        );
        expect(removed.isDirty, isTrue);
      });
    });
  });

  group('generatePathStudioCenterAnimationSequence', () {
    PathStudioNewPathDraft withTileset(PathStudioNewPathDraft d) =>
        selectPathStudioNewPathDraftTileset(d, 'tileset-main');

    PathStudioNewPathDraft assignCell(
      PathStudioNewPathDraft draft,
      int lx,
      int ly,
      int sx,
      int sy,
    ) {
      return assignPathStudioNewPathDraftCellTile(
        draft: draft,
        localX: lx,
        localY: ly,
        sourceX: sx,
        sourceY: sy,
      );
    }

    PathStudioNewPathDraft deepWaterStarts2x2() {
      var d = withTileset(createInitialPathStudioNewPathDraft());
      d = resizePathStudioNewPathDraftCenter(draft: d, width: 2, height: 2);
      d = selectPathStudioNewPathDraftCell(draft: d, localX: 0, localY: 0);
      d = assignCell(d, 0, 0, 0, 0);
      d = assignCell(d, 1, 0, 1, 0);
      d = assignCell(d, 0, 1, 0, 1);
      d = assignCell(d, 1, 1, 1, 1);
      return d;
    }

    test('génère une séquence pour la cellule active uniquement', () {
      final base =
          assignCell(withTileset(createInitialPathStudioNewPathDraft()), 0, 0, 5, 1);
      final result = generatePathStudioCenterAnimationSequence(
        draft: base,
        target: PathStudioCenterAnimationSequenceTarget.selectedCell,
        frameCount: 2,
        stepX: 1,
        stepY: -1,
        durationMs: 50,
      );
      expect(result, isA<PathStudioCenterAnimationSequenceSuccess>());
      final ok = result as PathStudioCenterAnimationSequenceSuccess;
      expect(ok.message, 'Animation générée pour la cellule A.');
      final cell = ok.draft.cells.single;
      expect(cell.frames.length, 2);
      expect(cell.frames[0].tile.sourceX, 5);
      expect(cell.frames[0].tile.sourceY, 1);
      expect(cell.frames[1].tile.sourceX, 6);
      expect(cell.frames[1].tile.sourceY, 0);
      expect(cell.frames.every((f) => f.durationMs == 50), isTrue);
    });

    test('génère pour toutes les cellules du centre', () {
      final base = deepWaterStarts2x2();
      final result = generatePathStudioCenterAnimationSequence(
        draft: base,
        target: PathStudioCenterAnimationSequenceTarget.allCenterCells,
        frameCount: 3,
        stepX: 1,
        stepY: 0,
        durationMs: 111,
      );
      expect(result, isA<PathStudioCenterAnimationSequenceSuccess>());
      final ok = result as PathStudioCenterAnimationSequenceSuccess;
      expect(ok.message, 'Animation générée pour les 4 cellules du centre.');
      for (final cell in ok.draft.cells) {
        expect(cell.frames.length, 3);
        expect(cell.frames.every((f) => f.durationMs == 111), isTrue);
        expect(cell.frames.map((f) => f.tile.sourceX),
            equals([cell.localX, cell.localX + 1, cell.localX + 2]));
      }
    });

    test('deep_water 2×2 : stepX=3, stepY=0 reproduit colonnes régulières', () {
      final base = deepWaterStarts2x2();
      final result = generatePathStudioCenterAnimationSequence(
        draft: base,
        target: PathStudioCenterAnimationSequenceTarget.allCenterCells,
        frameCount: 4,
        stepX: 3,
        stepY: 0,
        durationMs: 200,
      );
      expect(result, isA<PathStudioCenterAnimationSequenceSuccess>());
      final ok = result as PathStudioCenterAnimationSequenceSuccess;

      Iterable<int> sourcesX(PathStudioNewPathDraftCell c) =>
          c.frames.map((f) => f.tile.sourceX);

      final a = ok.draft.cells[0];
      final b = ok.draft.cells[1];
      final cCell = ok.draft.cells[2];
      final dCell = ok.draft.cells[3];
      expect(sourcesX(a), equals([0, 3, 6, 9]));
      expect(sourcesX(b), equals([1, 4, 7, 10]));
      expect(sourcesX(cCell), equals([0, 3, 6, 9]));
      expect(sourcesX(dCell), equals([1, 4, 7, 10]));
      expect(ok.draft.cells.every(
        (cell) =>
            cell.frames.every(
              (f) => f.tile.sourceY == cell.localY && f.durationMs == 200,
            ),
      ), isTrue);
    });

    test('conserve tilesetId de la première frame pour chaque cellule', () {
      var base = resizePathStudioNewPathDraftCenter(
        draft: withTileset(createInitialPathStudioNewPathDraft()),
        width: 1,
        height: 2,
      );
      base = assignCell(base, 0, 0, 0, 0);
      base = assignCell(base, 0, 1, 0, 1);
      final result = generatePathStudioCenterAnimationSequence(
        draft: base,
        target: PathStudioCenterAnimationSequenceTarget.allCenterCells,
        frameCount: 2,
        stepX: 0,
        stepY: 1,
        durationMs: 120,
      );
      expect(result, isA<PathStudioCenterAnimationSequenceSuccess>());
      final ok = result as PathStudioCenterAnimationSequenceSuccess;
      for (final cell in ok.draft.cells) {
        for (final f in cell.frames) {
          expect(f.tile.tilesetId, 'tileset-main');
        }
      }
    });

    test('rejette frameCount < 2', () {
      final base = assignCell(withTileset(createInitialPathStudioNewPathDraft()), 0, 0, 0, 0);
      final r = generatePathStudioCenterAnimationSequence(
        draft: base,
        target: PathStudioCenterAnimationSequenceTarget.selectedCell,
        frameCount: 1,
        stepX: 1,
        stepY: 0,
        durationMs: 10,
      );
      expect(r, isA<PathStudioCenterAnimationSequenceFailure>());
    });

    test('rejette durationMs <= 0', () {
      final base = assignCell(withTileset(createInitialPathStudioNewPathDraft()), 0, 0, 0, 0);
      final r = generatePathStudioCenterAnimationSequence(
        draft: base,
        target: PathStudioCenterAnimationSequenceTarget.selectedCell,
        frameCount: 2,
        stepX: 1,
        stepY: 0,
        durationMs: 0,
      );
      expect(r, isA<PathStudioCenterAnimationSequenceFailure>());
    });

    test('rejette pasX=0 et pasY=0', () {
      final base = assignCell(withTileset(createInitialPathStudioNewPathDraft()), 0, 0, 0, 0);
      final r = generatePathStudioCenterAnimationSequence(
        draft: base,
        target: PathStudioCenterAnimationSequenceTarget.selectedCell,
        frameCount: 2,
        stepX: 0,
        stepY: 0,
        durationMs: 80,
      );
      expect(r, isA<PathStudioCenterAnimationSequenceFailure>());
      expect(
        (r as PathStudioCenterAnimationSequenceFailure).message,
        contains('pas X et pas Y'),
      );
    });

    test('rejette coordonnées négatives projetées par le pas', () {
      final base =
          assignCell(withTileset(createInitialPathStudioNewPathDraft()), 0, 0, 0, 1);
      final r = generatePathStudioCenterAnimationSequence(
        draft: base,
        target: PathStudioCenterAnimationSequenceTarget.selectedCell,
        frameCount: 3,
        stepX: 0,
        stepY: -1,
        durationMs: 50,
      );
      expect(r, isA<PathStudioCenterAnimationSequenceFailure>());
    });

    test('rejette cellule sans frame de départ (active)', () {
      final base = withTileset(
        resizePathStudioNewPathDraftCenter(
          draft: createInitialPathStudioNewPathDraft(),
          width: 2,
          height: 1,
        ),
      );
      expect(base.centerCellFrames.isEmpty, isTrue);
      final r = generatePathStudioCenterAnimationSequence(
        draft: base,
        target: PathStudioCenterAnimationSequenceTarget.selectedCell,
        frameCount: 2,
        stepX: 1,
        stepY: 0,
        durationMs: 10,
      );
      expect(r, isA<PathStudioCenterAnimationSequenceFailure>());
      expect(
        (r as PathStudioCenterAnimationSequenceFailure).message,
        contains('cellule active'),
      );
    });

    test('ne mute pas le brouillon source', () {
      final base =
          assignCell(withTileset(createInitialPathStudioNewPathDraft()), 0, 0, 1, 1);
      final beforeFrames = base.centerCellFrames['0,0'];
      final r = generatePathStudioCenterAnimationSequence(
        draft: base,
        target: PathStudioCenterAnimationSequenceTarget.selectedCell,
        frameCount: 2,
        stepX: 4,
        stepY: -1,
        durationMs: 99,
      );
      expect(base.centerCellFrames['0,0'], same(beforeFrames));
      expect(r, isA<PathStudioCenterAnimationSequenceSuccess>());
    });

    test('après agrandissement 2×2, tout le centre exige une frame par cellule', () {
      var d = assignCell(withTileset(createInitialPathStudioNewPathDraft()), 0, 0, 0, 0);
      d = resizePathStudioNewPathDraftCenter(draft: d, width: 2, height: 2);
      expect(
        generatePathStudioCenterAnimationSequence(
          draft: d,
          target: PathStudioCenterAnimationSequenceTarget.allCenterCells,
          frameCount: 2,
          stepX: 1,
          stepY: 0,
          durationMs: 90,
        ),
        isA<PathStudioCenterAnimationSequenceFailure>(),
      );
      d = assignCell(d, 1, 0, 10, 0);
      d = assignCell(d, 0, 1, 0, 3);
      d = assignCell(d, 1, 1, 2, 2);
      expect(
        generatePathStudioCenterAnimationSequence(
          draft: d,
          target: PathStudioCenterAnimationSequenceTarget.allCenterCells,
          frameCount: 2,
          stepX: 1,
          stepY: 0,
          durationMs: 40,
        ),
        isA<PathStudioCenterAnimationSequenceSuccess>(),
      );
    });

    test('réinitialise l’index de frame active sur la première après succès', () {
      var d = assignCell(withTileset(createInitialPathStudioNewPathDraft()), 0, 0, 2, 2);
      d = appendPathStudioNewPathDraftCenterFrame(draft: d, localX: 0, localY: 0);
      d = selectPathStudioNewPathDraftCenterFrame(
        draft: d,
        localX: 0,
        localY: 0,
        frameIndex: 1,
      );
      expect(d.selectedCenterFrameIndex, 1);
      final ok = generatePathStudioCenterAnimationSequence(
        draft: d,
        target: PathStudioCenterAnimationSequenceTarget.selectedCell,
        frameCount: 2,
        stepX: 2,
        stepY: 0,
        durationMs: 10,
      ) as PathStudioCenterAnimationSequenceSuccess;
      expect(ok.draft.selectedCenterFrameIndex, 0);
    });
  });
}
