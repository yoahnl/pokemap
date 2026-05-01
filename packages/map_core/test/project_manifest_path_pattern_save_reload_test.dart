import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectManifest PathPattern save/reload JSON regression', () {
    test('roundtrip conserve path presets, patterns, frames et variantes', () {
      final manifest = _buildManifest();
      final encodedJson = jsonEncode(manifest.toJson());
      final decoded = ProjectManifest.fromJson(
        jsonDecode(encodedJson) as Map<String, dynamic>,
      );

      expect(decoded.pathPresets, hasLength(1));
      expect(decoded.pathPatternPresets, hasLength(1));

      final base = decoded.pathPresets.single;
      expect(base.id, 'water-base');
      expect(base.name, 'Water Base');
      expect(base.tilesetId, 'tileset-main');
      expect(base.surfaceKind, PathSurfaceKind.water);
      expect(base.categoryId, 'water-category');
      expect(base.sortOrder, 8);

      expect(base.variants, hasLength(2));
      final endNorth = base.variants.singleWhere(
        (mapping) => mapping.variant == TerrainPathVariant.endNorth,
      );
      expect(endNorth.frames, hasLength(1));
      expect(endNorth.frames.single.source, const TilesetSourceRect(x: 9, y: 4));
      expect(endNorth.frames.single.durationMs, 120);

      final cross = base.variants.singleWhere(
        (mapping) => mapping.variant == TerrainPathVariant.cross,
      );
      expect(cross.frames, hasLength(1));
      expect(cross.frames.single.source, const TilesetSourceRect(x: 7, y: 7));
      expect(cross.frames.single.durationMs, isNull);
      expect(
        base.variants.any((mapping) => mapping.variant == TerrainPathVariant.cornerNE),
        isFalse,
      );

      final pattern = decoded.pathPatternPresets.single;
      expect(pattern.id, 'water-pattern');
      expect(pattern.name, 'Water Pattern');
      expect(pattern.basePathPresetId, 'water-base');
      expect(pattern.transparentColor, TilesetTransparentColor.fromHexRgb('102a4f'));
      expect(pattern.categoryId, 'water-category');
      expect(pattern.sortOrder, 21);
      expect(pattern.centerPattern.size, PathCenterPatternSize(width: 2, height: 2));

      final cells = pattern.centerPattern.cells;
      expect(cells.map((cell) => [cell.localX, cell.localY]).toList(), [
        [0, 0],
        [1, 0],
        [0, 1],
        [1, 1],
      ]);
      for (final cell in cells) {
        expect(cell.frames, hasLength(2));
      }

      expect(cells[0].frames[0].source, const TilesetSourceRect(x: 0, y: 0));
      expect(cells[0].frames[0].durationMs, 100);
      expect(cells[0].frames[0].tilesetId, '');
      expect(cells[0].frames[1].source, const TilesetSourceRect(x: 0, y: 1));
      expect(cells[0].frames[1].durationMs, 150);
      expect(cells[0].frames[1].tilesetId, '');

      expect(cells[1].frames[0].source, const TilesetSourceRect(x: 1, y: 0));
      expect(cells[1].frames[0].durationMs, 100);
      expect(cells[1].frames[1].source, const TilesetSourceRect(x: 1, y: 1));
      expect(cells[1].frames[1].durationMs, 150);

      expect(cells[2].frames[0].source, const TilesetSourceRect(x: 2, y: 0));
      expect(cells[2].frames[0].durationMs, 200);
      expect(cells[2].frames[1].source, const TilesetSourceRect(x: 2, y: 1));
      expect(cells[2].frames[1].durationMs, 250);

      expect(cells[3].frames[0].source, const TilesetSourceRect(x: 3, y: 0));
      expect(cells[3].frames[0].durationMs, 200);
      expect(cells[3].frames[1].source, const TilesetSourceRect(x: 3, y: 1));
      expect(cells[3].frames[1].durationMs, 250);
      expect(cells[3].frames[1].tilesetId, 'tileset-water-fx');

      final asJson =
          jsonDecode(jsonEncode(decoded.toJson())) as Map<String, dynamic>;
      final encodedPattern = (asJson['pathPatternPresets'] as List<dynamic>).single
          as Map<String, dynamic>;
      final encodedCells =
          ((encodedPattern['centerPattern'] as Map<String, dynamic>)['cells'] as List<dynamic>);
      final encodedFrames =
          (encodedCells[3] as Map<String, dynamic>)['frames'] as List<dynamic>;
      expect(encodedFrames[0], containsPair('durationMs', 200));
      expect(encodedFrames[1], containsPair('durationMs', 250));

      final encodedBase = (asJson['pathPresets'] as List<dynamic>).single as Map<String, dynamic>;
      final encodedVariants = encodedBase['variants'] as List<dynamic>;
      final encodedCross = encodedVariants
          .cast<Map<String, dynamic>>()
          .singleWhere((variant) => variant['variant'] == 'cross');
      expect(encodedCross['frames'], [
        {
          'tilesetId': '',
          'source': {'x': 7, 'y': 7, 'width': 1, 'height': 1},
          'durationMs': null,
        },
      ]);
    });

    test('fixture golden 2x2 animé se décode avec les données attendues', () {
      final fixture = File(
        'test/fixtures/path_pattern/project_manifest_pathpattern_animated_2x2.json',
      ).readAsStringSync();
      const encoder = JsonEncoder.withIndent('  ');
      final fixturePretty =
          '${encoder.convert(jsonDecode(fixture) as Object?)}\n';
      final manifest = ProjectManifest.fromJson(
        jsonDecode(fixture) as Map<String, dynamic>,
      );

      expect(fixturePretty, fixture);
      expect(manifest.pathPresets.single.id, 'water-base');
      expect(manifest.pathPatternPresets.single.id, 'water-pattern');
      expect(
        manifest.pathPatternPresets.single.centerPattern.cellAt(1, 1).frames[1].tilesetId,
        'tileset-water-fx',
      );
    });

    test('manifest sans pathPatternPresets reste compatible', () {
      final manifest = ProjectManifest.fromJson({
        'name': 'Legacy',
        'maps': <Object?>[],
        'tilesets': <Object?>[],
      });

      expect(manifest.pathPatternPresets, isEmpty);
    });
  });
}

ProjectManifest _buildManifest() {
  return ProjectManifest(
    name: 'PathPattern Save Reload',
    maps: const [],
    tilesets: const [
      ProjectTilesetEntry(
        id: 'tileset-main',
        name: 'Main',
        relativePath: 'tilesets/main.png',
      ),
      ProjectTilesetEntry(
        id: 'tileset-water-fx',
        name: 'Water FX',
        relativePath: 'tilesets/water_fx.png',
      ),
    ],
    pathPresets: [
      ProjectPathPreset(
        id: 'water-base',
        name: 'Water Base',
        surfaceKind: PathSurfaceKind.water,
        categoryId: 'water-category',
        tilesetId: 'tileset-main',
        variants: [
          const PathPresetVariantMapping(
            variant: TerrainPathVariant.endNorth,
            frames: [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 9, y: 4),
                durationMs: 120,
              ),
            ],
          ),
          const PathPresetVariantMapping(
            variant: TerrainPathVariant.cross,
            frames: [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 7, y: 7),
                durationMs: null,
              ),
            ],
          ),
        ],
        sortOrder: 8,
      ),
    ],
    pathPatternPresets: [
      ProjectPathPatternPreset(
        id: 'water-pattern',
        name: 'Water Pattern',
        basePathPresetId: 'water-base',
        centerPattern: PathCenterPattern(
          size: PathCenterPatternSize(width: 2, height: 2),
          cells: [
            PathCenterPatternCell(
              localX: 0,
              localY: 0,
              frames: const [
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0),
                  durationMs: 100,
                ),
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 1),
                  durationMs: 150,
                ),
              ],
            ),
            PathCenterPatternCell(
              localX: 1,
              localY: 0,
              frames: const [
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 1, y: 0),
                  durationMs: 100,
                ),
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 1, y: 1),
                  durationMs: 150,
                ),
              ],
            ),
            PathCenterPatternCell(
              localX: 0,
              localY: 1,
              frames: const [
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 2, y: 0),
                  durationMs: 200,
                ),
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 2, y: 1),
                  durationMs: 250,
                ),
              ],
            ),
            PathCenterPatternCell(
              localX: 1,
              localY: 1,
              frames: const [
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 3, y: 0),
                  durationMs: 200,
                ),
                TilesetVisualFrame(
                  tilesetId: 'tileset-water-fx',
                  source: TilesetSourceRect(x: 3, y: 1),
                  durationMs: 250,
                ),
              ],
            ),
          ],
        ),
        transparentColor: TilesetTransparentColor.fromHexRgb('102a4f'),
        categoryId: 'water-category',
        sortOrder: 21,
      ),
    ],
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}
