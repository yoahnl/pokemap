// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('createPathVariantMappingsFromVerticalAtlas', () {
    group('simple mapping', () {
      test('generates single mapping with correct variant', () {
        final mappings = createPathVariantMappingsFromVerticalAtlas(
          columns: [
            PathVariantVerticalAtlasColumn(
              variant: TerrainPathVariant.isolated,
              column: 3,
            ),
          ],
          frameCount: 4,
        );

        expect(mappings, hasLength(1));
        final mapping = mappings[0];
        expect(mapping.variant, TerrainPathVariant.isolated);
        expect(mapping.frames, hasLength(4));
        expect(mapping.frames[0].source.x, 3);
        expect(mapping.frames[0].source.y, 0);
        expect(mapping.frames[1].source.y, 1);
        expect(mapping.frames[2].source.y, 2);
        expect(mapping.frames[3].source.y, 3);
      });

      test('preserves input order of columns', () {
        final mappings = createPathVariantMappingsFromVerticalAtlas(
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

        expect(mappings, hasLength(4));
        expect(mappings[0].variant, TerrainPathVariant.cross);
        expect(mappings[1].variant, TerrainPathVariant.isolated);
        expect(mappings[2].variant, TerrainPathVariant.cornerNE);
        expect(mappings[3].variant, TerrainPathVariant.horizontal);
      });

      test('respects startRow per column', () {
        final mappings = createPathVariantMappingsFromVerticalAtlas(
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

        expect(mappings, hasLength(2));
        expect(mappings[0].frames[0].source.y, 0);
        expect(mappings[0].frames[1].source.y, 1);
        expect(mappings[0].frames[2].source.y, 2);

        expect(mappings[1].frames[0].source.y, 10);
        expect(mappings[1].frames[1].source.y, 11);
        expect(mappings[1].frames[2].source.y, 12);
      });

      test('respects sourceWidth and sourceHeight', () {
        final mappings = createPathVariantMappingsFromVerticalAtlas(
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

        expect(mappings[0].frames[0].source.width, 2);
        expect(mappings[0].frames[0].source.height, 3);
        expect(mappings[0].frames[1].source.width, 2);
        expect(mappings[0].frames[1].source.height, 3);
      });

      test('preserves tilesetId', () {
        final mappings = createPathVariantMappingsFromVerticalAtlas(
          columns: [
            PathVariantVerticalAtlasColumn(
              variant: TerrainPathVariant.isolated,
              column: 0,
            ),
          ],
          frameCount: 2,
          tilesetId: 'animated-water-atlas',
        );

        expect(mappings[0].frames[0].tilesetId, 'animated-water-atlas');
        expect(mappings[0].frames[1].tilesetId, 'animated-water-atlas');
      });
    });

    group('frame durations', () {
      test('applies common duration to all frames', () {
        final mappings = createPathVariantMappingsFromVerticalAtlas(
          columns: [
            PathVariantVerticalAtlasColumn(
              variant: TerrainPathVariant.isolated,
              column: 0,
            ),
          ],
          frameCount: 3,
          defaultDurationMs: 80,
          frameDurationsMs: null,
        );

        expect(mappings[0].frames[0].durationMs, 80);
        expect(mappings[0].frames[1].durationMs, 80);
        expect(mappings[0].frames[2].durationMs, 80);
      });

      test('applies per-frame durations', () {
        final mappings = createPathVariantMappingsFromVerticalAtlas(
          columns: [
            PathVariantVerticalAtlasColumn(
              variant: TerrainPathVariant.isolated,
              column: 0,
            ),
          ],
          frameCount: 3,
          frameDurationsMs: [50, 100, 150],
        );

        expect(mappings[0].frames[0].durationMs, 50);
        expect(mappings[0].frames[1].durationMs, 100);
        expect(mappings[0].frames[2].durationMs, 150);
      });

      test('replaces null durations with default', () {
        final mappings = createPathVariantMappingsFromVerticalAtlas(
          columns: [
            PathVariantVerticalAtlasColumn(
              variant: TerrainPathVariant.isolated,
              column: 0,
            ),
          ],
          frameCount: 3,
          defaultDurationMs: 90,
          frameDurationsMs: [50, null, 150],
        );

        expect(mappings[0].frames[0].durationMs, 50);
        expect(mappings[0].frames[1].durationMs, 90);
        expect(mappings[0].frames[2].durationMs, 150);
      });
    });

    group('immutability', () {
      test('returns unmodifiable list', () {
        final mappings = createPathVariantMappingsFromVerticalAtlas(
          columns: [
            PathVariantVerticalAtlasColumn(
              variant: TerrainPathVariant.isolated,
              column: 0,
            ),
          ],
          frameCount: 2,
        );

        expect(() => mappings.add(mappings[0]), throwsUnsupportedError);
      });

      test('frames list is unmodifiable', () {
        final mappings = createPathVariantMappingsFromVerticalAtlas(
          columns: [
            PathVariantVerticalAtlasColumn(
              variant: TerrainPathVariant.isolated,
              column: 0,
            ),
          ],
          frameCount: 2,
        );

        expect(() => mappings[0].frames.add(mappings[0].frames[0]), throwsUnsupportedError);
      });

      test('does not mutate input columns list', () {
        final columns = [
          PathVariantVerticalAtlasColumn(
            variant: TerrainPathVariant.isolated,
            column: 0,
          ),
        ];
        final originalColumns = List.of(columns);

        createPathVariantMappingsFromVerticalAtlas(
          columns: columns,
          frameCount: 2,
        );

        expect(columns, originalColumns);
      });

      test('does not mutate input frameDurationsMs', () {
        final durations = <int?>[50, null, 150];
        final originalDurations = List.of(durations);

        createPathVariantMappingsFromVerticalAtlas(
          columns: [
            PathVariantVerticalAtlasColumn(
              variant: TerrainPathVariant.isolated,
              column: 0,
            ),
          ],
          frameCount: 3,
          frameDurationsMs: durations,
        );

        expect(durations, originalDurations);
      });
    });

    group('compatibility', () {
      test('generated mappings work with ProjectPathPreset', () {
        final mappings = createPathVariantMappingsFromVerticalAtlas(
          columns: [
            PathVariantVerticalAtlasColumn(
              variant: TerrainPathVariant.isolated,
              column: 5,
            ),
            PathVariantVerticalAtlasColumn(
              variant: TerrainPathVariant.horizontal,
              column: 3,
            ),
          ],
          frameCount: 2,
        );

        final preset = ProjectPathPreset(
          id: 'test-water',
          name: 'Test Water',
          surfaceKind: PathSurfaceKind.water,
          variants: mappings,
        );

        expect(preset.variants.length, 2);
        expect(preset.variants[0].variant, TerrainPathVariant.isolated);
        expect(preset.variants[0].frames.length, 2);
        expect(preset.variants[1].variant, TerrainPathVariant.horizontal);
        expect(preset.variants[1].frames.length, 2);
      });

      test('generated frames work with resolveTileVisualFrameTimeline', () {
        final mappings = createPathVariantMappingsFromVerticalAtlas(
          columns: [
            PathVariantVerticalAtlasColumn(
              variant: TerrainPathVariant.isolated,
              column: 5,
            ),
          ],
          frameCount: 3,
          frameDurationsMs: [100, 100, 100],
        );

        final resolution = resolveTileVisualFrameTimeline(
          frames: mappings[0].frames,
          elapsedMs: 100,
          mode: TileVisualFrameTimelinePlaybackMode.loop,
        );

        expect(resolution.frameIndex, 1);
        expect(resolution.frame, mappings[0].frames[1]);
        expect(resolution.frame?.source.x, 5);
        expect(resolution.frame?.source.y, 1);
      });
    });

    group('validation', () {
      test('throws ValidationException for empty columns', () {
        expect(
          () => createPathVariantMappingsFromVerticalAtlas(
            columns: [],
            frameCount: 1,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('throws ValidationException for negative column', () {
        expect(
          () => createPathVariantMappingsFromVerticalAtlas(
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

      test('throws ValidationException for negative startRow', () {
        expect(
          () => createPathVariantMappingsFromVerticalAtlas(
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

      test('throws ValidationException for duplicate variants', () {
        expect(
          () => createPathVariantMappingsFromVerticalAtlas(
            columns: [
              PathVariantVerticalAtlasColumn(
                variant: TerrainPathVariant.cross,
                column: 0,
              ),
              PathVariantVerticalAtlasColumn(
                variant: TerrainPathVariant.cross,
                column: 1,
              ),
            ],
            frameCount: 1,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('throws ValidationException for non-positive frameCount', () {
        expect(
          () => createPathVariantMappingsFromVerticalAtlas(
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

        expect(
          () => createPathVariantMappingsFromVerticalAtlas(
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

      test('throws ValidationException for non-positive sourceWidth', () {
        expect(
          () => createPathVariantMappingsFromVerticalAtlas(
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

        expect(
          () => createPathVariantMappingsFromVerticalAtlas(
            columns: [
              PathVariantVerticalAtlasColumn(
                variant: TerrainPathVariant.isolated,
                column: 0,
              ),
            ],
            frameCount: 1,
            sourceWidth: -1,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('throws ValidationException for non-positive sourceHeight', () {
        expect(
          () => createPathVariantMappingsFromVerticalAtlas(
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

        expect(
          () => createPathVariantMappingsFromVerticalAtlas(
            columns: [
              PathVariantVerticalAtlasColumn(
                variant: TerrainPathVariant.isolated,
                column: 0,
              ),
            ],
            frameCount: 1,
            sourceHeight: -1,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('throws ValidationException for non-positive defaultDurationMs', () {
        expect(
          () => createPathVariantMappingsFromVerticalAtlas(
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

        expect(
          () => createPathVariantMappingsFromVerticalAtlas(
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

      test('throws ValidationException when frameDurationsMs length mismatches', () {
        expect(
          () => createPathVariantMappingsFromVerticalAtlas(
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

        expect(
          () => createPathVariantMappingsFromVerticalAtlas(
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

      test('throws ValidationException for non-positive frame durations', () {
        expect(
          () => createPathVariantMappingsFromVerticalAtlas(
            columns: [
              PathVariantVerticalAtlasColumn(
                variant: TerrainPathVariant.isolated,
                column: 0,
              ),
            ],
            frameCount: 3,
            frameDurationsMs: [100, 0, 100],
          ),
          throwsA(isA<ValidationException>()),
        );

        expect(
          () => createPathVariantMappingsFromVerticalAtlas(
            columns: [
              PathVariantVerticalAtlasColumn(
                variant: TerrainPathVariant.isolated,
                column: 0,
              ),
            ],
            frameCount: 3,
            frameDurationsMs: [100, -10, 100],
          ),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('edge cases', () {
      test('handles single mapping', () {
        final mappings = createPathVariantMappingsFromVerticalAtlas(
          columns: [
            PathVariantVerticalAtlasColumn(
              variant: TerrainPathVariant.isolated,
              column: 5,
            ),
          ],
          frameCount: 1,
        );

        expect(mappings, hasLength(1));
        expect(mappings[0].variant, TerrainPathVariant.isolated);
        expect(mappings[0].frames, hasLength(1));
      });

      test('handles multiple variants', () {
        final mappings = createPathVariantMappingsFromVerticalAtlas(
          columns: [
            PathVariantVerticalAtlasColumn(
              variant: TerrainPathVariant.isolated,
              column: 0,
            ),
            PathVariantVerticalAtlasColumn(
              variant: TerrainPathVariant.horizontal,
              column: 1,
            ),
            PathVariantVerticalAtlasColumn(
              variant: TerrainPathVariant.vertical,
              column: 2,
            ),
          ],
          frameCount: 2,
        );

        expect(mappings, hasLength(3));
        expect(mappings[0].variant, TerrainPathVariant.isolated);
        expect(mappings[1].variant, TerrainPathVariant.horizontal);
        expect(mappings[2].variant, TerrainPathVariant.vertical);
      });

      test('handles large frame counts', () {
        final mappings = createPathVariantMappingsFromVerticalAtlas(
          columns: [
            PathVariantVerticalAtlasColumn(
              variant: TerrainPathVariant.isolated,
              column: 0,
            ),
          ],
          frameCount: 100,
        );

        expect(mappings, hasLength(1));
        expect(mappings[0].frames, hasLength(100));
        expect(mappings[0].frames[0].source.y, 0);
        expect(mappings[0].frames[99].source.y, 99);
      });

      test('preserves empty tilesetId', () {
        final mappings = createPathVariantMappingsFromVerticalAtlas(
          columns: [
            PathVariantVerticalAtlasColumn(
              variant: TerrainPathVariant.isolated,
              column: 0,
            ),
          ],
          frameCount: 1,
          tilesetId: '',
        );

        expect(mappings[0].frames[0].tilesetId, '');
      });
    });
  });
}
