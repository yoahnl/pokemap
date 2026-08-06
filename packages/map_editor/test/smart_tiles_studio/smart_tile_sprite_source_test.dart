import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_sprite_source.dart';

void main() {
  test('resolves the tileset path and the atlas cell rect for a frame', () {
    final source = resolveSmartTileSpriteSource(
      frame: const SmartTileFrameRef(atlasId: 'atlas', column: 2, row: 1),
      atlases: const <ProjectSmartTileAtlas>[_atlas],
      tilesets: const <ProjectTilesetEntry>[_tileset],
      projectRootPath: '/projects/demo',
    );

    expect(source, isNotNull);
    expect(source!.absolutePath, '/projects/demo/assets/tileset_01.png');
    expect(source.sourceRect.x, 64);
    expect(source.sourceRect.y, 32);
    expect(source.sourceRect.width, 32);
    expect(source.sourceRect.height, 32);
  });

  test('honours atlas origin, margin and spacing', () {
    final source = resolveSmartTileSpriteSource(
      frame: const SmartTileFrameRef(atlasId: 'atlas', column: 2, row: 1),
      atlases: const <ProjectSmartTileAtlas>[
        ProjectSmartTileAtlas(
          id: 'atlas',
          name: 'Atlas',
          tilesetId: 'tileset-01',
          columns: 8,
          rows: 8,
          originX: 3,
          originY: 5,
          marginX: 1,
          marginY: 2,
          spacingX: 4,
          spacingY: 6,
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[_tileset],
      projectRootPath: '/projects/demo',
    );

    expect(source, isNotNull);
    // origin + margin + column * (cellWidth + spacingX)
    expect(source!.sourceRect.x, 3 + 1 + 2 * (32 + 4));
    expect(source.sourceRect.y, 5 + 2 + 1 * (32 + 6));
  });

  test('spans several cells for a multi-cell frame', () {
    final source = resolveSmartTileSpriteSource(
      frame: const SmartTileFrameRef(
        atlasId: 'atlas',
        column: 0,
        row: 0,
        columnSpan: 2,
        rowSpan: 3,
      ),
      atlases: const <ProjectSmartTileAtlas>[_atlas],
      tilesets: const <ProjectTilesetEntry>[_tileset],
      projectRootPath: '/projects/demo',
    );

    expect(source, isNotNull);
    expect(source!.sourceRect.width, 64);
    expect(source.sourceRect.height, 96);
  });

  test('returns null when the project root is unknown', () {
    expect(
      resolveSmartTileSpriteSource(
        frame: const SmartTileFrameRef(atlasId: 'atlas', column: 0, row: 0),
        atlases: const <ProjectSmartTileAtlas>[_atlas],
        tilesets: const <ProjectTilesetEntry>[_tileset],
        projectRootPath: null,
      ),
      isNull,
    );
    expect(
      resolveSmartTileSpriteSource(
        frame: const SmartTileFrameRef(atlasId: 'atlas', column: 0, row: 0),
        atlases: const <ProjectSmartTileAtlas>[_atlas],
        tilesets: const <ProjectTilesetEntry>[_tileset],
        projectRootPath: '   ',
      ),
      isNull,
    );
  });

  test('returns null when the frame references an unknown atlas', () {
    expect(
      resolveSmartTileSpriteSource(
        frame: const SmartTileFrameRef(atlasId: 'ghost', column: 0, row: 0),
        atlases: const <ProjectSmartTileAtlas>[_atlas],
        tilesets: const <ProjectTilesetEntry>[_tileset],
        projectRootPath: '/projects/demo',
      ),
      isNull,
    );
  });

  test('returns null when the atlas references an unregistered tileset', () {
    expect(
      resolveSmartTileSpriteSource(
        frame: const SmartTileFrameRef(atlasId: 'atlas', column: 0, row: 0),
        atlases: const <ProjectSmartTileAtlas>[_atlas],
        tilesets: const <ProjectTilesetEntry>[],
        projectRootPath: '/projects/demo',
      ),
      isNull,
    );
  });

  test('returns null when the frame falls outside the atlas grid', () {
    expect(
      resolveSmartTileSpriteSource(
        frame: const SmartTileFrameRef(atlasId: 'atlas', column: 8, row: 0),
        atlases: const <ProjectSmartTileAtlas>[_atlas],
        tilesets: const <ProjectTilesetEntry>[_tileset],
        projectRootPath: '/projects/demo',
      ),
      isNull,
    );
  });

  test('returns null when the tileset escapes the project root', () {
    expect(
      resolveSmartTileSpriteSource(
        frame: const SmartTileFrameRef(atlasId: 'atlas', column: 0, row: 0),
        atlases: const <ProjectSmartTileAtlas>[_atlas],
        tilesets: const <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'tileset-01',
            name: 'Escaping',
            relativePath: '../../etc/passwd.png',
          ),
        ],
        projectRootPath: '/projects/demo',
      ),
      isNull,
    );
  });

  test('returns null when the tileset path is absolute or blank', () {
    expect(
      resolveSmartTileSpriteSource(
        frame: const SmartTileFrameRef(atlasId: 'atlas', column: 0, row: 0),
        atlases: const <ProjectSmartTileAtlas>[_atlas],
        tilesets: const <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'tileset-01',
            name: 'Absolute',
            relativePath: '/elsewhere/tileset.png',
          ),
        ],
        projectRootPath: '/projects/demo',
      ),
      isNull,
    );
    expect(
      resolveSmartTileSpriteSource(
        frame: const SmartTileFrameRef(atlasId: 'atlas', column: 0, row: 0),
        atlases: const <ProjectSmartTileAtlas>[_atlas],
        tilesets: const <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'tileset-01',
            name: 'Blank',
            relativePath: '  ',
          ),
        ],
        projectRootPath: '/projects/demo',
      ),
      isNull,
    );
  });
}

const _atlas = ProjectSmartTileAtlas(
  id: 'atlas',
  name: 'Atlas',
  tilesetId: 'tileset-01',
  columns: 8,
  rows: 8,
);

const _tileset = ProjectTilesetEntry(
  id: 'tileset-01',
  name: 'Tileset 01',
  relativePath: 'assets/tileset_01.png',
);
