// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('createProjectPathPresetFromVerticalAtlas', () {
    group('preset generation', () {
      test('generates simple water ProjectPathPreset', () {
        final preset = createProjectPathPresetFromVerticalAtlas(
          id: 'animated-water',
          name: 'Animated Water',
          surfaceKind: PathSurfaceKind.water,
          tilesetId: 'outdoor-water',
          columns: [
            PathVariantVerticalAtlasColumn(
              variant: TerrainPathVariant.isolated,
              column: 3,
            ),
          ],
          frameCount: 4,
        );

        expect(preset.id, 'animated-water');
        expect(preset.name, 'Animated Water');
        expect(preset.surfaceKind, PathSurfaceKind.water);
        expect(preset.tilesetId, 'outdoor-water');
        expect(preset.variants, hasLength(1));
        expect(preset.variants[0].variant, TerrainPathVariant.isolated);
        expect(preset.variants[0].frames, hasLength(4));
        expect(preset.variants[0].frames[0].source.x, 3);
        expect(preset.variants[0].frames[0].source.y, 0);
        expect(preset.variants[0].frames[1].source.y, 1);
        expect(preset.variants[0].frames[2].source.y, 2);
        expect(preset.variants[0].frames[3].source.y, 3);
      });

      test('generates tallGrass ProjectPathPreset', () {
        final preset = createProjectPathPresetFromVerticalAtlas(
          id: 'animated-grass',
          name: 'Animated Grass',
          surfaceKind: PathSurfaceKind.tallGrass,
          tilesetId: 'field-tileset',
          columns: [
            PathVariantVerticalAtlasColumn(
              variant: TerrainPathVariant.isolated,
              column: 1,
            ),
          ],
          frameCount: 3,
        );

        expect(preset.surfaceKind, PathSurfaceKind.tallGrass);
        expect(preset.id, 'animated-grass');
        expect(preset.tilesetId, 'field-tileset');
      });

      test('preserves categoryId and sortOrder', () {
        final preset = createProjectPathPresetFromVerticalAtlas(
          id: 'water-preset',
          name: 'Water Preset',
          surfaceKind: PathSurfaceKind.water,
          tilesetId: 'water-tileset',
          categoryId: 'water-category',
          sortOrder: 42,
          columns: [
            PathVariantVerticalAtlasColumn(
              variant: TerrainPathVariant.isolated,
              column: 0,
            ),
          ],
          frameCount: 2,
        );

        expect(preset.categoryId, 'water-category');
        expect(preset.sortOrder, 42);
      });

      test('preserves input order of variants', () {
        final preset = createProjectPathPresetFromVerticalAtlas(
          id: 'multi-variant',
          name: 'Multi Variant',
          surfaceKind: PathSurfaceKind.water,
          tilesetId: 'tileset',
          columns: [
            PathVariantVerticalAtlasColumn(
              variant: TerrainPathVariant.cross,
              column: 9,
            ),
            PathVariantVerticalAtlasColumn(
              variant: TerrainPathVariant.isolated,
              column: 0,
            ),
            PathVariantVerticalAtlasColumn(
              variant: TerrainPathVariant.cornerNE,
              column: 5,
            ),
            PathVariantVerticalAtlasColumn(
              variant: TerrainPathVariant.horizontal,
              column: 2,
            ),
          ],
          frameCount: 2,
        );

        expect(preset.variants, hasLength(4));
        expect(preset.variants[0].variant, TerrainPathVariant.cross);
        expect(preset.variants[1].variant, TerrainPathVariant.isolated);
        expect(preset.variants[2].variant, TerrainPathVariant.cornerNE);
        expect(preset.variants[3].variant, TerrainPathVariant.horizontal);
      });

      test('respects startRow per column', () {
        final preset = createProjectPathPresetFromVerticalAtlas(
          id: 'start-row-test',
          name: 'Start Row Test',
          surfaceKind: PathSurfaceKind.water,
          tilesetId: 'tileset',
          columns: [
            PathVariantVerticalAtlasColumn(
              variant: TerrainPathVariant.isolated,
              column: 1,
              startRow: 0,
            ),
            PathVariantVerticalAtlasColumn(
              variant: TerrainPathVariant.horizontal,
              column: 2,
              startRow: 10,
            ),
          ],
          frameCount: 3,
        );

        expect(preset.variants, hasLength(2));
        expect(preset.variants[0].frames[0].source.y, 0);
        expect(preset.variants[0].frames[1].source.y, 1);
        expect(preset.variants[0].frames[2].source.y, 2);

        expect(preset.variants[1].frames[0].source.y, 10);
        expect(preset.variants[1].frames[1].source.y, 11);
        expect(preset.variants[1].frames[2].source.y, 12);
      });

      test('respects sourceWidth and sourceHeight', () {
        final preset = createProjectPathPresetFromVerticalAtlas(
          id: 'source-size-test',
          name: 'Source Size Test',
          surfaceKind: PathSurfaceKind.water,
          tilesetId: 'tileset',
          columns: [
            PathVariantVerticalAtlasColumn(
              variant: TerrainPathVariant.isolated,
              column: 1,
            ),
          ],
          frameCount: 2,
          sourceWidth: 2,
          sourceHeight: 3,
        );

        expect(preset.variants[0].frames[0].source.width, 2);
        expect(preset.variants[0].frames[0].source.height, 3);
        expect(preset.variants[0].frames[1].source.width, 2);
        expect(preset.variants[0].frames[1].source.height, 3);
      });

      test('distinguishes preset tilesetId from frame tilesetId', () {
        final preset = createProjectPathPresetFromVerticalAtlas(
          id: 'tileset-test',
          name: 'Tileset Test',
          surfaceKind: PathSurfaceKind.water,
          tilesetId: 'main-water-tileset',
          frameTilesetId: 'animated-water-atlas',
          columns: [
            PathVariantVerticalAtlasColumn(
              variant: TerrainPathVariant.isolated,
              column: 0,
            ),
          ],
          frameCount: 2,
        );

        expect(preset.tilesetId, 'main-water-tileset');
        expect(preset.variants[0].frames[0].tilesetId, 'animated-water-atlas');
        expect(preset.variants[0].frames[1].tilesetId, 'animated-water-atlas');
      });

      test('preserves empty frameTilesetId', () {
        final preset = createProjectPathPresetFromVerticalAtlas(
          id: 'empty-frame-tileset',
          name: 'Empty Frame Tileset',
          surfaceKind: PathSurfaceKind.water,
          tilesetId: 'main-tileset',
          frameTilesetId: '',
          columns: [
            PathVariantVerticalAtlasColumn(
              variant: TerrainPathVariant.isolated,
              column: 0,
            ),
          ],
          frameCount: 2,
        );

        expect(preset.tilesetId, 'main-tileset');
        expect(preset.variants[0].frames[0].tilesetId, '');
        expect(preset.variants[0].frames[1].tilesetId, '');
      });

      test('applies custom default duration', () {
        final preset = createProjectPathPresetFromVerticalAtlas(
          id: 'duration-test',
          name: 'Duration Test',
          surfaceKind: PathSurfaceKind.water,
          tilesetId: 'tileset',
          defaultDurationMs: 80,
          columns: [
            PathVariantVerticalAtlasColumn(
              variant: TerrainPathVariant.isolated,
              column: 0,
            ),
          ],
          frameCount: 3,
        );

        expect(preset.variants[0].frames[0].durationMs, 80);
        expect(preset.variants[0].frames[1].durationMs, 80);
        expect(preset.variants[0].frames[2].durationMs, 80);
      });

      test('applies per-frame durations', () {
        final preset = createProjectPathPresetFromVerticalAtlas(
          id: 'per-frame-duration',
          name: 'Per Frame Duration',
          surfaceKind: PathSurfaceKind.water,
          tilesetId: 'tileset',
          frameDurationsMs: [50, 100, 150],
          columns: [
            PathVariantVerticalAtlasColumn(
              variant: TerrainPathVariant.isolated,
              column: 0,
            ),
          ],
          frameCount: 3,
        );

        expect(preset.variants[0].frames[0].durationMs, 50);
        expect(preset.variants[0].frames[1].durationMs, 100);
        expect(preset.variants[0].frames[2].durationMs, 150);
      });

      test('replaces null durations with default', () {
        final preset = createProjectPathPresetFromVerticalAtlas(
          id: 'null-duration-test',
          name: 'Null Duration Test',
          surfaceKind: PathSurfaceKind.water,
          tilesetId: 'tileset',
          defaultDurationMs: 90,
          frameDurationsMs: [50, null, 150],
          columns: [
            PathVariantVerticalAtlasColumn(
              variant: TerrainPathVariant.isolated,
              column: 0,
            ),
          ],
          frameCount: 3,
        );

        expect(preset.variants[0].frames[0].durationMs, 50);
        expect(preset.variants[0].frames[1].durationMs, 90);
        expect(preset.variants[0].frames[2].durationMs, 150);
      });
    });

    group('compatibility', () {
      test('is compatible with LegacyPathSurfaceView', () {
        final preset = createProjectPathPresetFromVerticalAtlas(
          id: 'view-compat-test',
          name: 'View Compat Test',
          surfaceKind: PathSurfaceKind.water,
          tilesetId: 'water-tileset',
          categoryId: 'liquids',
          sortOrder: 5,
          columns: [
            PathVariantVerticalAtlasColumn(
              variant: TerrainPathVariant.isolated,
              column: 2,
            ),
          ],
          frameCount: 4,
        );

        final view = createLegacyPathSurfaceView(preset);

        expect(view.id, 'view-compat-test');
        expect(view.name, 'View Compat Test');
        expect(view.surfaceKind, PathSurfaceKind.water);
        expect(view.tilesetId, 'water-tileset');
        expect(view.categoryId, 'liquids');
        expect(view.sortOrder, 5);
        expect(view.hasVariants, isTrue);
        expect(view.framesForVariant(TerrainPathVariant.isolated), hasLength(4));
      });

      test('is compatible with LegacyProjectSurfaceCatalogView', () {
        final preset = createProjectPathPresetFromVerticalAtlas(
          id: 'catalog-compat-test',
          name: 'Catalog Compat Test',
          surfaceKind: PathSurfaceKind.tallGrass,
          tilesetId: 'grass-tileset',
          columns: [
            PathVariantVerticalAtlasColumn(
              variant: TerrainPathVariant.isolated,
              column: 1,
            ),
          ],
          frameCount: 3,
        );

        final manifest = ProjectManifest(
          name: 'Test Project',
          maps: [],
          tilesets: [],
          pathPresets: [preset],
        surfaceCatalog: ProjectSurfaceCatalog(),);

        final catalog = createLegacyProjectSurfaceCatalogView(manifest);

        expect(catalog.pathSurfaces, hasLength(1));
        expect(catalog.pathSurfaces[0].id, 'catalog-compat-test');
        expect(catalog.pathSurfaceById('catalog-compat-test'), isNotNull);
        expect(catalog.pathSurfacesByKind(PathSurfaceKind.tallGrass), hasLength(1));
      });

      test('frames compatible with resolveTileVisualFrameTimeline', () {
        final preset = createProjectPathPresetFromVerticalAtlas(
          id: 'timeline-test',
          name: 'Timeline Test',
          surfaceKind: PathSurfaceKind.water,
          tilesetId: 'tileset',
          frameDurationsMs: [100, 100, 100],
          columns: [
            PathVariantVerticalAtlasColumn(
              variant: TerrainPathVariant.isolated,
              column: 0,
            ),
          ],
          frameCount: 3,
        );

        final frames = preset.variants[0].frames;
        final timeline = resolveTileVisualFrameTimeline(
          frames: frames,
          elapsedMs: 100,
          mode: TileVisualFrameTimelinePlaybackMode.loop,
        );

        expect(timeline.frameIndex, 1);
      });
    });

    group('validation', () {
      test('rejects empty id', () {
        expect(
          () => createProjectPathPresetFromVerticalAtlas(
            id: '',
            name: 'Test',
            surfaceKind: PathSurfaceKind.water,
            tilesetId: 'tileset',
            columns: [
              PathVariantVerticalAtlasColumn(
                variant: TerrainPathVariant.isolated,
                column: 0,
              ),
            ],
            frameCount: 1,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('rejects whitespace-only id', () {
        expect(
          () => createProjectPathPresetFromVerticalAtlas(
            id: '   ',
            name: 'Test',
            surfaceKind: PathSurfaceKind.water,
            tilesetId: 'tileset',
            columns: [
              PathVariantVerticalAtlasColumn(
                variant: TerrainPathVariant.isolated,
                column: 0,
              ),
            ],
            frameCount: 1,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('rejects empty name', () {
        expect(
          () => createProjectPathPresetFromVerticalAtlas(
            id: 'test',
            name: '',
            surfaceKind: PathSurfaceKind.water,
            tilesetId: 'tileset',
            columns: [
              PathVariantVerticalAtlasColumn(
                variant: TerrainPathVariant.isolated,
                column: 0,
              ),
            ],
            frameCount: 1,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('rejects whitespace-only name', () {
        expect(
          () => createProjectPathPresetFromVerticalAtlas(
            id: 'test',
            name: '   ',
            surfaceKind: PathSurfaceKind.water,
            tilesetId: 'tileset',
            columns: [
              PathVariantVerticalAtlasColumn(
                variant: TerrainPathVariant.isolated,
                column: 0,
              ),
            ],
            frameCount: 1,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('rejects empty tilesetId', () {
        expect(
          () => createProjectPathPresetFromVerticalAtlas(
            id: 'test',
            name: 'Test',
            surfaceKind: PathSurfaceKind.water,
            tilesetId: '',
            columns: [
              PathVariantVerticalAtlasColumn(
                variant: TerrainPathVariant.isolated,
                column: 0,
              ),
            ],
            frameCount: 1,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('rejects whitespace-only tilesetId', () {
        expect(
          () => createProjectPathPresetFromVerticalAtlas(
            id: 'test',
            name: 'Test',
            surfaceKind: PathSurfaceKind.water,
            tilesetId: '   ',
            columns: [
              PathVariantVerticalAtlasColumn(
                variant: TerrainPathVariant.isolated,
                column: 0,
              ),
            ],
            frameCount: 1,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('rejects empty columns', () {
        expect(
          () => createProjectPathPresetFromVerticalAtlas(
            id: 'test',
            name: 'Test',
            surfaceKind: PathSurfaceKind.water,
            tilesetId: 'tileset',
            columns: [],
            frameCount: 1,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('rejects negative column', () {
        expect(
          () => createProjectPathPresetFromVerticalAtlas(
            id: 'test',
            name: 'Test',
            surfaceKind: PathSurfaceKind.water,
            tilesetId: 'tileset',
            columns: [
              PathVariantVerticalAtlasColumn(
                variant: TerrainPathVariant.isolated,
                column: -1,
              ),
            ],
            frameCount: 1,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('rejects negative startRow', () {
        expect(
          () => createProjectPathPresetFromVerticalAtlas(
            id: 'test',
            name: 'Test',
            surfaceKind: PathSurfaceKind.water,
            tilesetId: 'tileset',
            columns: [
              PathVariantVerticalAtlasColumn(
                variant: TerrainPathVariant.isolated,
                column: 0,
                startRow: -1,
              ),
            ],
            frameCount: 1,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('rejects duplicate variants', () {
        expect(
          () => createProjectPathPresetFromVerticalAtlas(
            id: 'test',
            name: 'Test',
            surfaceKind: PathSurfaceKind.water,
            tilesetId: 'tileset',
            columns: [
              PathVariantVerticalAtlasColumn(
                variant: TerrainPathVariant.isolated,
                column: 0,
              ),
              PathVariantVerticalAtlasColumn(
                variant: TerrainPathVariant.isolated,
                column: 1,
              ),
            ],
            frameCount: 1,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('rejects zero frameCount', () {
        expect(
          () => createProjectPathPresetFromVerticalAtlas(
            id: 'test',
            name: 'Test',
            surfaceKind: PathSurfaceKind.water,
            tilesetId: 'tileset',
            columns: [
              PathVariantVerticalAtlasColumn(
                variant: TerrainPathVariant.isolated,
                column: 0,
              ),
            ],
            frameCount: 0,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('rejects negative frameCount', () {
        expect(
          () => createProjectPathPresetFromVerticalAtlas(
            id: 'test',
            name: 'Test',
            surfaceKind: PathSurfaceKind.water,
            tilesetId: 'tileset',
            columns: [
              PathVariantVerticalAtlasColumn(
                variant: TerrainPathVariant.isolated,
                column: 0,
              ),
            ],
            frameCount: -1,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('rejects zero sourceWidth', () {
        expect(
          () => createProjectPathPresetFromVerticalAtlas(
            id: 'test',
            name: 'Test',
            surfaceKind: PathSurfaceKind.water,
            tilesetId: 'tileset',
            columns: [
              PathVariantVerticalAtlasColumn(
                variant: TerrainPathVariant.isolated,
                column: 0,
              ),
            ],
            frameCount: 1,
            sourceWidth: 0,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('rejects zero sourceHeight', () {
        expect(
          () => createProjectPathPresetFromVerticalAtlas(
            id: 'test',
            name: 'Test',
            surfaceKind: PathSurfaceKind.water,
            tilesetId: 'tileset',
            columns: [
              PathVariantVerticalAtlasColumn(
                variant: TerrainPathVariant.isolated,
                column: 0,
              ),
            ],
            frameCount: 1,
            sourceHeight: 0,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('rejects zero defaultDurationMs', () {
        expect(
          () => createProjectPathPresetFromVerticalAtlas(
            id: 'test',
            name: 'Test',
            surfaceKind: PathSurfaceKind.water,
            tilesetId: 'tileset',
            columns: [
              PathVariantVerticalAtlasColumn(
                variant: TerrainPathVariant.isolated,
                column: 0,
              ),
            ],
            frameCount: 1,
            defaultDurationMs: 0,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('rejects negative defaultDurationMs', () {
        expect(
          () => createProjectPathPresetFromVerticalAtlas(
            id: 'test',
            name: 'Test',
            surfaceKind: PathSurfaceKind.water,
            tilesetId: 'tileset',
            columns: [
              PathVariantVerticalAtlasColumn(
                variant: TerrainPathVariant.isolated,
                column: 0,
              ),
            ],
            frameCount: 1,
            defaultDurationMs: -10,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('rejects frameDurationsMs length mismatch (too short)', () {
        expect(
          () => createProjectPathPresetFromVerticalAtlas(
            id: 'test',
            name: 'Test',
            surfaceKind: PathSurfaceKind.water,
            tilesetId: 'tileset',
            columns: [
              PathVariantVerticalAtlasColumn(
                variant: TerrainPathVariant.isolated,
                column: 0,
              ),
            ],
            frameCount: 3,
            frameDurationsMs: [100, 100],
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('rejects frameDurationsMs length mismatch (too long)', () {
        expect(
          () => createProjectPathPresetFromVerticalAtlas(
            id: 'test',
            name: 'Test',
            surfaceKind: PathSurfaceKind.water,
            tilesetId: 'tileset',
            columns: [
              PathVariantVerticalAtlasColumn(
                variant: TerrainPathVariant.isolated,
                column: 0,
              ),
            ],
            frameCount: 2,
            frameDurationsMs: [100, 100, 100],
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('rejects zero frame duration', () {
        expect(
          () => createProjectPathPresetFromVerticalAtlas(
            id: 'test',
            name: 'Test',
            surfaceKind: PathSurfaceKind.water,
            tilesetId: 'tileset',
            columns: [
              PathVariantVerticalAtlasColumn(
                variant: TerrainPathVariant.isolated,
                column: 0,
              ),
            ],
            frameCount: 2,
            frameDurationsMs: [100, 0],
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('rejects negative frame duration', () {
        expect(
          () => createProjectPathPresetFromVerticalAtlas(
            id: 'test',
            name: 'Test',
            surfaceKind: PathSurfaceKind.water,
            tilesetId: 'tileset',
            columns: [
              PathVariantVerticalAtlasColumn(
                variant: TerrainPathVariant.isolated,
                column: 0,
              ),
            ],
            frameCount: 2,
            frameDurationsMs: [100, -50],
          ),
          throwsA(isA<ValidationException>()),
        );
      });
    });
  });
}
