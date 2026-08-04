import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('visual library contracts', () {
    const atlas = _worldAtlas;

    test('rejects a source rect outside the real atlas bounds', () {
      expect(
        () => const TilesetActions().validateFrame(
          const TilesetVisualFrame(
            source: TilesetSourceRect(x: 3, y: 0, width: 2),
          ),
          owningTilesetId: 'world',
          atlases: const {'world': atlas},
        ),
        throwsA(
          isA<VisualLibraryException>().having(
            (error) => error.code,
            'code',
            'tileset.source_out_of_bounds',
          ),
        ),
      );
    });

    test('tileset upsert supports progressive legacy atlas migration', () {
      const legacyTilesetId = 'tileset_m00_hanazuki_guesthouse_room';
      final legacy = ProjectManifest(
        name: 'Legacy visual fixture',
        maps: const [],
        tilesets: const [
          ProjectTilesetEntry(
            id: legacyTilesetId,
            name: 'M00 Guesthouse',
            relativePath: 'images/m00.png',
          ),
        ],
        elementCategories: const [
          ProjectElementCategory(id: 'legacy', name: 'Legacy'),
        ],
        elements: const [
          ProjectElementEntry(
            id: 'legacy-bed',
            name: 'Legacy Bed',
            tilesetId: legacyTilesetId,
            categoryId: 'legacy',
            frames: [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0),
              ),
            ],
          ),
        ],
      );
      const m02Atlas = ProjectRegularAtlasTilesetSource(
        assetId: 'm02-atlas',
        pixelWidth: 16,
        pixelHeight: 16,
        tileWidth: 16,
        tileHeight: 16,
      );
      const m02 = ProjectTilesetEntry(
        id: 'm02',
        name: 'M02',
        relativePath: 'images/m02.png',
        source: m02Atlas,
        paletteEntries: [
          TilesetPaletteEntry(
            id: 'm02-tile',
            frames: [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0),
              ),
            ],
          ),
        ],
      );

      final migrated = const TilesetActions().upsert(
        legacy,
        tileset: m02,
      );
      final atlases = readTilesetAtlases(migrated);

      expect(atlases.keys, ['m02']);
      expect(
        () => validateManifestFrames(migrated, atlases),
        throwsA(
          isA<VisualLibraryException>()
              .having(
                (error) => error.code,
                'code',
                'tileset.atlas_missing',
              )
              .having(
                (error) => error.details['tilesetId'],
                'tilesetId',
                legacyTilesetId,
              ),
        ),
      );
      expect(
        () => const TilesetActions().upsert(
          legacy,
          tileset: m02.copyWith(
            source: m02Atlas,
            paletteEntries: const [
              TilesetPaletteEntry(
                id: 'invalid',
                frames: [
                  TilesetVisualFrame(
                    source: TilesetSourceRect(x: 1, y: 0),
                  ),
                ],
              ),
            ],
          ),
        ),
        throwsA(
          isA<VisualLibraryException>().having(
            (error) => error.code,
            'code',
            'tileset.source_out_of_bounds',
          ),
        ),
      );
    });

    test('regrid preview reports every affected visual before apply', () {
      final preview = const TilesetActions().previewRegrid(
        _manifest(),
        tilesetId: 'world',
        tileWidth: 8,
        tileHeight: 8,
      );

      expect(preview.canApply, isTrue);
      expect(preview.impacts.map((impact) => impact.ownerKind), [
        'element',
        'paletteEntry',
      ]);
      expect(preview.before.tileWidth, 16);
      expect(preview.after.tileWidth, 8);
    });

    test('element deletion scans every loaded map', () {
      final town = const MapData(
        id: 'town',
        name: 'Town',
        size: GridSize(width: 4, height: 4),
        placedElements: [
          MapPlacedElement(
            id: 'tree-placed',
            layerId: 'objects',
            elementId: 'tree',
            pos: GridPos(x: 1, y: 1),
          ),
        ],
      );

      expect(
        () => const ElementActions().delete(
          _manifest(),
          maps: [town],
          elementId: 'tree',
        ),
        throwsA(
          isA<VisualLibraryException>()
              .having(
                (error) => error.code,
                'code',
                'element.references_blocking',
              )
              .having(
                (error) => error.details['references'],
                'references',
                contains('map:town:placedElement:tree-placed'),
              ),
        ),
      );
    });

    test('dispatcher exposes canonical visual library mutations', () {
      final ids = MapMutationDispatcher.canonical()
          .descriptors
          .map((descriptor) => descriptor.id)
          .toSet();

      expect(
        ids,
        containsAll({
          'tileset_folder.upsert',
          'tileset_folder.delete',
          'tileset.upsert',
          'tileset.delete',
          'palette.upsert',
          'palette.delete',
          'element.upsert',
          'element.delete',
          'element_category.upsert',
          'element_category.delete',
        }),
      );
      expect(ids.where((id) => id.startsWith('preset.')), isEmpty);
    });

    test('visual organization upserts and protects referenced containers', () {
      const actions = VisualOrganizationActions();
      final organized = actions
          .upsertTilesetFolder(
        _manifest(),
        folder: const ProjectTilesetFolder(
          id: 'm02',
          name: 'M02',
          sortOrder: 2,
        ),
      )
          .copyWith(
        tilesets: [
          _manifest().tilesets.single.copyWith(folderId: 'm02'),
        ],
      );

      expect(organized.tilesetFolders.single.id, 'm02');
      expect(
        () => actions.deleteTilesetFolder(
          organized,
          folderId: 'm02',
        ),
        throwsA(
          isA<VisualLibraryException>().having(
            (error) => error.code,
            'code',
            'tileset_folder.references_blocking',
          ),
        ),
      );
      expect(
        () => actions.deleteElementCategory(
          organized,
          categoryId: 'nature',
        ),
        throwsA(
          isA<VisualLibraryException>().having(
            (error) => error.code,
            'code',
            'element_category.references_blocking',
          ),
        ),
      );
    });
  });
}

ProjectManifest _manifest() => ProjectManifest(
      name: 'Visual fixture',
      maps: const [],
      tilesets: const [
        ProjectTilesetEntry(
          id: 'world',
          name: 'World',
          relativePath: 'images/world.png',
          source: _worldAtlas,
          paletteEntries: [
            TilesetPaletteEntry(
              id: 'grass-tile',
              name: 'Grass',
              frames: [
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0),
                ),
              ],
            ),
          ],
        ),
      ],
      elementCategories: const [
        ProjectElementCategory(id: 'nature', name: 'Nature'),
      ],
      elements: const [
        ProjectElementEntry(
          id: 'tree',
          name: 'Tree',
          tilesetId: 'world',
          categoryId: 'nature',
          frames: [
            TilesetVisualFrame(
              source: TilesetSourceRect(x: 1, y: 0),
            ),
          ],
        ),
      ],
    );

const _worldAtlas = ProjectRegularAtlasTilesetSource(
  assetId: 'world-atlas',
  pixelWidth: 64,
  pixelHeight: 48,
  tileWidth: 16,
  tileHeight: 16,
);
