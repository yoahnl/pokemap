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

    test('preserves regular atlas margins spacing and drawing offsets', () {
      const source = ProjectTilesetSource.regularAtlas(
        assetId: 'asset-spaced',
        pixelWidth: 68,
        pixelHeight: 68,
        tileWidth: 32,
        tileHeight: 32,
        marginX: 1,
        marginY: 1,
        spacingX: 2,
        spacingY: 2,
        pixelOffsetX: -3,
        pixelOffsetY: 5,
      );
      const tileset = ProjectTilesetEntry(
        id: 'spaced',
        name: 'Spaced',
        relativePath: 'assets/spaced.png',
        source: source,
      );

      final decoded = ProjectTilesetEntry.fromJson(tileset.toJson());
      final decodedSource = decoded.source! as ProjectRegularAtlasTilesetSource;
      expect(decodedSource, source);
      expect((decodedSource.columns, decodedSource.rows), (2, 2));
      expect(decodedSource.marginX, 1);
      expect(decodedSource.spacingY, 2);
      expect((decodedSource.pixelOffsetX, decodedSource.pixelOffsetY), (-3, 5));
      expect(
        () => ProjectValidator.validate(
          const ProjectManifest(
            name: 'Spaced atlas project',
            maps: <ProjectMapEntry>[],
            tilesets: <ProjectTilesetEntry>[tileset],
          ),
        ),
        returnsNormally,
      );
    });

    test('migrates legacy atlas metadata into the canonical source', () {
      final manifest = ProjectManifest.fromJsonPokeMapBetaV1ForTest(
        <String, Object?>{
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
        },
      );

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
      expect(manifest.toJson()['globalProperties'], <String, Object?>{
        'keep': 'value',
      });
    });

    test('rejects simultaneous legacy and canonical source data', () {
      expect(
        () => ProjectManifest.fromJsonPokeMapBetaV1ForTest(<String, Object?>{
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
              pixelWidth: 15,
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

    test(
      'project validation rejects a spaced atlas without a complete cell',
      () {
        const manifest = ProjectManifest(
          name: 'Invalid spaced atlas project',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[
            ProjectTilesetEntry(
              id: 'world',
              name: 'World',
              relativePath: 'assets/world.png',
              source: ProjectTilesetSource.regularAtlas(
                assetId: 'asset-world',
                pixelWidth: 32,
                pixelHeight: 68,
                tileWidth: 32,
                tileHeight: 32,
                marginX: 1,
                marginY: 1,
                spacingX: 2,
                spacingY: 2,
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
      },
    );

    test(
      'serializes a sparse image collection with variable visuals and metadata',
      () {
        const source = ProjectTilesetSource.imageCollection(
          pages: <ProjectImageCollectionPage>[
            ProjectImageCollectionPage(
              id: 'page-main',
              assetId: 'asset-page-main',
              pixelWidth: 512,
              pixelHeight: 256,
            ),
          ],
          properties: <ProjectTilesetProperty>[
            ProjectTilesetProperty(
              name: 'generation',
              type: ProjectTilesetPropertyType.structured,
              value: <String, Object?>{'density': 0.8},
              customType: 'vegetation_settings',
            ),
          ],
          tileDefinitions: <ProjectImageCollectionTileDefinition>[
            ProjectImageCollectionTileDefinition(
              tileId: 2,
              pageId: 'page-main',
              sourceRect: ProjectTilesetPixelRect(
                x: 0,
                y: 0,
                width: 32,
                height: 48,
              ),
              offsetX: -8,
              offsetY: -16,
              properties: <ProjectTilesetProperty>[
                ProjectTilesetProperty(
                  name: 'passable',
                  type: ProjectTilesetPropertyType.boolean,
                  value: false,
                ),
                ProjectTilesetProperty(
                  name: 'biome',
                  type: ProjectTilesetPropertyType.string,
                  value: 'forest',
                ),
              ],
              collisionObjects: <ProjectTilesetCollisionObject>[
                ProjectTilesetCollisionObject(
                  id: 1,
                  shape: ProjectTilesetCollisionShape.rectangle,
                  x: 4,
                  y: 24,
                  width: 24,
                  height: 16,
                ),
                ProjectTilesetCollisionObject(
                  id: 2,
                  shape: ProjectTilesetCollisionShape.polygon,
                  x: 0,
                  y: 0,
                  points: <ProjectTilesetPixelPoint>[
                    ProjectTilesetPixelPoint(x: 0, y: 16),
                    ProjectTilesetPixelPoint(x: 16, y: 0),
                    ProjectTilesetPixelPoint(x: 32, y: 16),
                  ],
                ),
              ],
            ),
            ProjectImageCollectionTileDefinition(
              tileId: 9,
              pageId: 'page-main',
              sourceRect: ProjectTilesetPixelRect(
                x: 64,
                y: 0,
                width: 96,
                height: 128,
              ),
              animation: <ProjectImageCollectionAnimationFrame>[
                ProjectImageCollectionAnimationFrame(
                  tileId: 2,
                  durationMs: 120,
                ),
                ProjectImageCollectionAnimationFrame(tileId: 9, durationMs: 80),
              ],
            ),
          ],
        );
        const tileset = ProjectTilesetEntry(
          id: 'props',
          name: 'Props',
          relativePath: 'assets/generated/props-page-main.png',
          source: source,
        );

        expect(ProjectTilesetEntry.fromJson(tileset.toJson()), tileset);
        expect(
          (tileset.toJson()['source']! as Map<String, dynamic>)['kind'],
          'image_collection',
        );
        expect(
          (ProjectTilesetEntry.fromJson(tileset.toJson()).source!
                  as ProjectImageCollectionTilesetSource)
              .tileDefinitions
              .map((tile) => tile.tileId),
          <int>[2, 9],
        );
        expect(
          () => ProjectValidator.validate(
            const ProjectManifest(
              name: 'Image collection project',
              maps: <ProjectMapEntry>[],
              tilesets: <ProjectTilesetEntry>[tileset],
            ),
          ),
          returnsNormally,
        );
      },
    );

    test('rejects invalid image collection references and bounds', () {
      const source = ProjectTilesetSource.imageCollection(
        pages: <ProjectImageCollectionPage>[
          ProjectImageCollectionPage(
            id: 'page-main',
            assetId: 'asset-page-main',
            pixelWidth: 64,
            pixelHeight: 64,
          ),
        ],
        tileDefinitions: <ProjectImageCollectionTileDefinition>[
          ProjectImageCollectionTileDefinition(
            tileId: 3,
            pageId: 'page-main',
            sourceRect: ProjectTilesetPixelRect(
              x: 48,
              y: 48,
              width: 32,
              height: 32,
            ),
            animation: <ProjectImageCollectionAnimationFrame>[
              ProjectImageCollectionAnimationFrame(tileId: 99, durationMs: 0),
            ],
          ),
        ],
      );

      expect(
        () => ProjectValidator.validate(
          const ProjectManifest(
            name: 'Invalid image collection project',
            maps: <ProjectMapEntry>[],
            tilesets: <ProjectTilesetEntry>[
              ProjectTilesetEntry(
                id: 'props',
                name: 'Props',
                relativePath: 'assets/generated/props.png',
                source: source,
              ),
            ],
          ),
        ),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            contains('invalid image collection source'),
          ),
        ),
      );
    });

    test('rejects image collection property values with the wrong type', () {
      const source = ProjectTilesetSource.imageCollection(
        pages: <ProjectImageCollectionPage>[
          ProjectImageCollectionPage(
            id: 'page-main',
            assetId: 'asset-page-main',
            pixelWidth: 32,
            pixelHeight: 32,
          ),
        ],
        tileDefinitions: <ProjectImageCollectionTileDefinition>[
          ProjectImageCollectionTileDefinition(
            tileId: 0,
            pageId: 'page-main',
            sourceRect: ProjectTilesetPixelRect(
              x: 0,
              y: 0,
              width: 32,
              height: 32,
            ),
            properties: <ProjectTilesetProperty>[
              ProjectTilesetProperty(
                name: 'priority',
                type: ProjectTilesetPropertyType.integer,
                value: 'high',
              ),
            ],
          ),
        ],
      );

      expect(
        () => ProjectValidator.validate(
          const ProjectManifest(
            name: 'Invalid property project',
            maps: <ProjectMapEntry>[],
            tilesets: <ProjectTilesetEntry>[
              ProjectTilesetEntry(
                id: 'props',
                name: 'Props',
                relativePath: 'assets/generated/props.png',
                source: source,
              ),
            ],
          ),
        ),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            contains('property priority'),
          ),
        ),
      );
    });

    test('rejects duplicate identities and missing image collection links', () {
      const page = ProjectImageCollectionPage(
        id: 'page-main',
        assetId: 'asset-page-main',
        pixelWidth: 32,
        pixelHeight: 32,
      );
      const tile = ProjectImageCollectionTileDefinition(
        tileId: 0,
        pageId: 'page-main',
        sourceRect: ProjectTilesetPixelRect(x: 0, y: 0, width: 32, height: 32),
      );
      const invalidSources = <ProjectTilesetSource>[
        ProjectTilesetSource.imageCollection(
          pages: <ProjectImageCollectionPage>[page, page],
          tileDefinitions: <ProjectImageCollectionTileDefinition>[tile],
        ),
        ProjectTilesetSource.imageCollection(
          pages: <ProjectImageCollectionPage>[page],
          tileDefinitions: <ProjectImageCollectionTileDefinition>[tile, tile],
        ),
        ProjectTilesetSource.imageCollection(
          pages: <ProjectImageCollectionPage>[page],
          tileDefinitions: <ProjectImageCollectionTileDefinition>[
            ProjectImageCollectionTileDefinition(
              tileId: 0,
              pageId: 'page-missing',
              sourceRect: ProjectTilesetPixelRect(
                x: 0,
                y: 0,
                width: 32,
                height: 32,
              ),
            ),
          ],
        ),
        ProjectTilesetSource.imageCollection(
          pages: <ProjectImageCollectionPage>[page],
          tileDefinitions: <ProjectImageCollectionTileDefinition>[
            ProjectImageCollectionTileDefinition(
              tileId: 0,
              pageId: 'page-main',
              sourceRect: ProjectTilesetPixelRect(
                x: 0,
                y: 0,
                width: 32,
                height: 32,
              ),
              animation: <ProjectImageCollectionAnimationFrame>[
                ProjectImageCollectionAnimationFrame(
                  tileId: 99,
                  durationMs: 100,
                ),
              ],
            ),
          ],
        ),
      ];

      for (final source in invalidSources) {
        expect(
          () => ProjectValidator.validate(
            ProjectManifest(
              name: 'Invalid linked image collection',
              maps: const <ProjectMapEntry>[],
              tilesets: <ProjectTilesetEntry>[
                ProjectTilesetEntry(
                  id: 'props',
                  name: 'Props',
                  relativePath: 'assets/generated/props.png',
                  source: source,
                ),
              ],
            ),
          ),
          throwsA(
            isA<ValidationException>().having(
              (error) => error.message,
              'message',
              contains('invalid image collection source'),
            ),
          ),
        );
      }
    });

    test('round-trips regular atlas tile animations canonically', () {
      const source = ProjectTilesetSource.regularAtlas(
        assetId: 'animated-atlas',
        pixelWidth: 64,
        pixelHeight: 32,
        tileWidth: 16,
        tileHeight: 16,
        tileAnimations: <ProjectRegularAtlasTileAnimation>[
          ProjectRegularAtlasTileAnimation(
            tileId: 1,
            frames: <ProjectImageCollectionAnimationFrame>[
              ProjectImageCollectionAnimationFrame(tileId: 1, durationMs: 100),
              ProjectImageCollectionAnimationFrame(tileId: 2, durationMs: 300),
            ],
          ),
        ],
      );

      expect(source.toJson()['tileAnimations'], <Object?>[
        <String, Object?>{
          'tileId': 1,
          'frames': <Object?>[
            <String, Object?>{'tileId': 1, 'durationMs': 100},
            <String, Object?>{'tileId': 2, 'durationMs': 300},
          ],
        },
      ]);
      expect(ProjectTilesetSource.fromJson(source.toJson()), source);
    });

    test('keeps legacy regular atlases animation-free by default', () {
      final source =
          ProjectTilesetSource.fromJson(<String, Object?>{
                'kind': 'regular_atlas',
                'assetId': 'legacy-atlas',
                'pixelWidth': 32,
                'pixelHeight': 32,
                'tileWidth': 16,
                'tileHeight': 16,
                'tileProperties': <Object?>[],
              })
              as ProjectRegularAtlasTilesetSource;

      expect(source.tileAnimations, isEmpty);
    });
  });
}
