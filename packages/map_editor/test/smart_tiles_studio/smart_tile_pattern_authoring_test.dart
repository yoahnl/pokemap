import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_pattern_authoring.dart';

void main() {
  const atlas = ProjectSmartTileAtlas(
    id: 'atlas',
    name: 'Atlas',
    tilesetId: 'tileset',
    columns: 4,
    rows: 3,
  );

  test('compiles a no-code atlas rectangle into canonical pattern cells', () {
    final pattern = compileSmartTileAtlasPattern(
      id: 'stone_patch',
      name: '  Pierre claire  ',
      usage: SmartTileUsage.path,
      atlas: atlas,
      selection: const SmartTilePatternAtlasSelection(
        startColumn: 1,
        startRow: 0,
        endColumn: 2,
        endRow: 1,
      ),
      anchorColumn: 2,
      anchorRow: 1,
      repeatMode: SmartTilePatternRepeatMode.tiled,
    );

    expect(pattern.name, 'Pierre claire');
    expect(pattern.width, 2);
    expect(pattern.height, 2);
    expect(pattern.anchorX, 1);
    expect(pattern.anchorY, 1);
    expect(pattern.cells, hasLength(4));
    expect(pattern.cells.first.x, 0);
    expect(pattern.cells.first.y, 0);
    final source = pattern.cells.first.parts.single.source;
    expect(source, isA<SmartTileFrameSource>());
    expect((source as SmartTileFrameSource).frame.atlasId, 'atlas');
    expect(source.frame.column, 1);
    expect(source.frame.row, 0);
  });

  test('normalizes reverse corner selection without changing atlas order', () {
    const selection = SmartTilePatternAtlasSelection(
      startColumn: 3,
      startRow: 2,
      endColumn: 1,
      endRow: 1,
    );

    expect(selection.left, 1);
    expect(selection.top, 1);
    expect(selection.width, 3);
    expect(selection.height, 2);
    expect(selection.contains(column: 2, row: 2), isTrue);
  });

  test('rejects an anchor outside the selected atlas rectangle', () {
    expect(
      () => compileSmartTileAtlasPattern(
        id: 'invalid',
        name: 'Invalide',
        usage: SmartTileUsage.terrain,
        atlas: atlas,
        selection: const SmartTilePatternAtlasSelection(
          startColumn: 1,
          startRow: 1,
          endColumn: 2,
          endRow: 2,
        ),
        anchorColumn: 0,
        anchorRow: 0,
        repeatMode: SmartTilePatternRepeatMode.stamp,
      ),
      throwsA(
        isA<SmartTilePatternAuthoringException>().having(
          (error) => error.code,
          'code',
          'smart_tile.pattern.anchor_outside_selection',
        ),
      ),
    );
  });

  test('round-trips an editor-compatible pattern back to atlas selection', () {
    final pattern = compileSmartTileAtlasPattern(
      id: 'round_trip',
      name: 'Round trip',
      usage: SmartTileUsage.terrain,
      atlas: atlas,
      selection: const SmartTilePatternAtlasSelection(
        startColumn: 1,
        startRow: 1,
        endColumn: 2,
        endRow: 2,
      ),
      anchorColumn: 1,
      anchorRow: 2,
      repeatMode: SmartTilePatternRepeatMode.stamp,
    );

    final projection = projectSmartTilePatternAtlasSelection(pattern);

    expect(projection, isNotNull);
    expect(projection!.atlasId, 'atlas');
    expect(projection.selection.left, 1);
    expect(projection.selection.top, 1);
    expect(projection.anchorColumn, 1);
    expect(projection.anchorRow, 2);
  });

  test('compiles an organic forest mask with render and collision semantics',
      () {
    final pattern = compileSmartTileAtlasPattern(
      id: 'organic_forest',
      name: 'Lisière organique',
      usage: SmartTileUsage.forestSurface,
      atlas: atlas,
      selection: const SmartTilePatternAtlasSelection(
        startColumn: 1,
        startRow: 0,
        endColumn: 2,
        endRow: 1,
      ),
      anchorColumn: 1,
      anchorRow: 1,
      repeatMode: SmartTilePatternRepeatMode.stamp,
      cellProfiles: <GridPos, SmartTilePatternCellProfile>{
        const GridPos(x: 0, y: 0): const SmartTilePatternCellProfile(
          channel: SmartTileRenderChannel.canopy,
        ),
        const GridPos(x: 1, y: 0): const SmartTilePatternCellProfile(
          channel: SmartTileRenderChannel.canopy,
        ),
        const GridPos(x: 0, y: 1): const SmartTilePatternCellProfile(
          channel: SmartTileRenderChannel.understory,
          collision: SmartTilePatternCollision.blocked,
        ),
        const GridPos(x: 1, y: 1): const SmartTilePatternCellProfile(
          channel: SmartTileRenderChannel.shadow,
          collision: SmartTilePatternCollision.passable,
          eraseMaterial: true,
        ),
      },
    );

    expect(
      pattern.cells.take(2).map((cell) => cell.parts.single.channel),
      everyElement(SmartTileRenderChannel.canopy),
    );
    expect(pattern.cells[2].parts.single.channel,
        SmartTileRenderChannel.understory);
    expect(pattern.cells[2].collision, SmartTilePatternCollision.blocked);
    expect(
        pattern.cells[3].parts.single.channel, SmartTileRenderChannel.shadow);
    expect(pattern.cells[3].collision, SmartTilePatternCollision.passable);
    expect(pattern.cells[3].eraseMaterial, isTrue);
  });

  test('round-trips organic forest cell profiles without flattening them', () {
    final pattern = compileSmartTileAtlasPattern(
      id: 'organic_round_trip',
      name: 'Bosquet',
      usage: SmartTileUsage.forestSurface,
      atlas: atlas,
      selection: const SmartTilePatternAtlasSelection(
        startColumn: 1,
        startRow: 1,
        endColumn: 2,
        endRow: 2,
      ),
      anchorColumn: 1,
      anchorRow: 2,
      repeatMode: SmartTilePatternRepeatMode.stamp,
      cellProfiles: <GridPos, SmartTilePatternCellProfile>{
        const GridPos(x: 1, y: 0): const SmartTilePatternCellProfile(
          channel: SmartTileRenderChannel.canopy,
          collision: SmartTilePatternCollision.blocked,
        ),
      },
    );

    final projection = projectSmartTilePatternAtlasSelection(pattern);

    expect(projection, isNotNull);
    expect(
      projection!.cellProfiles[const GridPos(x: 1, y: 0)],
      const SmartTilePatternCellProfile(
        channel: SmartTileRenderChannel.canopy,
        collision: SmartTilePatternCollision.blocked,
      ),
    );
  });

  test('rejects an organic profile outside the selected rectangle', () {
    expect(
      () => compileSmartTileAtlasPattern(
        id: 'invalid_profile',
        name: 'Invalide',
        usage: SmartTileUsage.forestSurface,
        atlas: atlas,
        selection: const SmartTilePatternAtlasSelection(
          startColumn: 0,
          startRow: 0,
          endColumn: 0,
          endRow: 0,
        ),
        anchorColumn: 0,
        anchorRow: 0,
        repeatMode: SmartTilePatternRepeatMode.stamp,
        cellProfiles: <GridPos, SmartTilePatternCellProfile>{
          const GridPos(x: 1, y: 0): const SmartTilePatternCellProfile(
            channel: SmartTileRenderChannel.canopy,
          ),
        },
      ),
      throwsA(
        isA<SmartTilePatternAuthoringException>().having(
          (error) => error.code,
          'code',
          'smart_tile.pattern.profile_outside_selection',
        ),
      ),
    );
  });

  test('refuses to flatten an advanced multi-part pattern', () {
    const pattern = ProjectSmartTilePattern(
      id: 'advanced',
      name: 'Advanced',
      usage: SmartTileUsage.terrain,
      width: 1,
      height: 1,
      cells: <SmartTilePatternCell>[
        SmartTilePatternCell(
          x: 0,
          y: 0,
          parts: <SmartTileVisualPart>[
            SmartTileVisualPart(
              source: SmartTileVisualSource.animation(animationId: 'wind'),
            ),
          ],
        ),
      ],
    );

    expect(projectSmartTilePatternAtlasSelection(pattern), isNull);
  });
}
