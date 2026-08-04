import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectTilesetSource', () {
    test('serializes one canonical regular atlas on the tileset entry', () {
      const source = ProjectTilesetSource.regularAtlas(
        assetId: 'asset-world',
        pixelWidth: 64,
        pixelHeight: 48,
        tileWidth: 16,
        tileHeight: 16,
        tileProperties: <VisualTileProperty>[
          VisualTileProperty(
            tileId: 1,
            passable: false,
            tags: <String>['water'],
          ),
        ],
      );
      const tileset = ProjectTilesetEntry(
        id: 'world',
        name: 'World',
        relativePath: 'assets/world.png',
        source: source,
      );

      expect(tileset.toJson()['source'], <String, Object?>{
        'kind': 'regular_atlas',
        'assetId': 'asset-world',
        'pixelWidth': 64,
        'pixelHeight': 48,
        'tileWidth': 16,
        'tileHeight': 16,
        'tileProperties': <Object?>[
          <String, Object?>{
            'tileId': 1,
            'passable': false,
            'tags': <String>['water'],
          },
        ],
      });
      expect(ProjectTilesetEntry.fromJson(tileset.toJson()), tileset);
    });

    test('migrates legacy atlas metadata into the canonical source', () {
      final manifest = ProjectManifest.fromJson(<String, Object?>{
        'name': 'Legacy atlas project',
        'version': 'v6',
        'maps': <Object?>[],
        'tilesets': <Object?>[
          <String, Object?>{
            'id': 'world',
            'name': 'World',
            'relativePath': 'assets/world.png',
          },
        ],
        'globalProperties': <String, Object?>{
          'keep': 'value',
          'pokemapAuthoringVisualLibrary': <String, Object?>{
            'schemaVersion': 1,
            'tilesets': <Object?>[
              <String, Object?>{
                'tilesetId': 'world',
                'assetId': 'asset-world',
                'pixelWidth': 64,
                'pixelHeight': 48,
                'tileWidth': 16,
                'tileHeight': 16,
                'tileProperties': <Object?>[],
              },
            ],
          },
        },
      });

      expect(manifest.tilesets.single.source?.toJson(), <String, Object?>{
        'kind': 'regular_atlas',
        'assetId': 'asset-world',
        'pixelWidth': 64,
        'pixelHeight': 48,
        'tileWidth': 16,
        'tileHeight': 16,
        'tileProperties': <Object?>[],
      });
      expect(manifest.globalProperties, <String, Object?>{'keep': 'value'});
      expect(
        manifest.toJson()['globalProperties'],
        <String, Object?>{'keep': 'value'},
      );
    });

    test('rejects simultaneous legacy and canonical source data', () {
      expect(
        () => ProjectManifest.fromJson(<String, Object?>{
          'name': 'Ambiguous project',
          'version': 'v6',
          'maps': <Object?>[],
          'tilesets': <Object?>[
            <String, Object?>{
              'id': 'world',
              'name': 'World',
              'relativePath': 'assets/world.png',
              'source': <String, Object?>{
                'kind': 'regular_atlas',
                'assetId': 'asset-world',
                'pixelWidth': 16,
                'pixelHeight': 16,
                'tileWidth': 16,
                'tileHeight': 16,
                'tileProperties': <Object?>[],
              },
            },
          ],
          'globalProperties': <String, Object?>{
            'pokemapAuthoringVisualLibrary': <String, Object?>{
              'schemaVersion': 1,
              'tilesets': <Object?>[
                <String, Object?>{
                  'tilesetId': 'world',
                  'assetId': 'asset-world',
                  'pixelWidth': 16,
                  'pixelHeight': 16,
                  'tileWidth': 16,
                  'tileHeight': 16,
                  'tileProperties': <Object?>[],
                },
              ],
            },
          },
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('duplicate_tileset_source_representation'),
          ),
        ),
      );
    });

    test('project validation rejects an invalid canonical atlas grid', () {
      const manifest = ProjectManifest(
        name: 'Invalid atlas project',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'world',
            name: 'World',
            relativePath: 'assets/world.png',
            source: ProjectTilesetSource.regularAtlas(
              assetId: 'asset-world',
              pixelWidth: 63,
              pixelHeight: 48,
              tileWidth: 16,
              tileHeight: 16,
            ),
          ),
        ],
      );

      expect(
        () => ProjectValidator.validate(manifest),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            contains('invalid regular atlas source'),
          ),
        ),
      );
    });
  });
}
