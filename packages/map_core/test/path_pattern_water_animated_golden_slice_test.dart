import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('PathPattern water animated golden slice', () {
    test('fixture JSON se décode et reste canonique', () {
      final raw = _fixtureRaw();
      final manifest = ProjectManifest.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      const encoder = JsonEncoder.withIndent('  ');
      final pretty = '${encoder.convert(jsonDecode(raw) as Object?)}\n';

      expect(raw, pretty);
      expect(manifest.pathPresets, hasLength(1));
      expect(manifest.pathPatternPresets, hasLength(1));
    });

    test('roundtrip conserve eau 2x2 animée, variants partiels, cross et override',
        () {
      final manifest = ProjectManifest.fromJson(
        jsonDecode(_fixtureRaw()) as Map<String, dynamic>,
      );
      final roundtripped = ProjectManifest.fromJson(
        jsonDecode(jsonEncode(manifest.toJson())) as Map<String, dynamic>,
      );

      final base = roundtripped.pathPresets.singleWhere(
        (preset) => preset.id == 'water-base',
      );
      expect(base.surfaceKind, PathSurfaceKind.water);
      expect(base.variants, hasLength(2));
      expect(
        base.variants.any((variant) => variant.variant == TerrainPathVariant.endNorth),
        isTrue,
      );
      expect(
        base.variants.any((variant) => variant.variant == TerrainPathVariant.cross),
        isTrue,
      );
      expect(
        base.variants.any((variant) => variant.variant == TerrainPathVariant.cornerNE),
        isFalse,
      );

      final cross = base.variants.singleWhere(
        (variant) => variant.variant == TerrainPathVariant.cross,
      );
      expect(cross.frames.single.source, const TilesetSourceRect(x: 7, y: 7));
      expect(cross.frames.single.durationMs, isNull);

      final pattern = roundtripped.pathPatternPresets.singleWhere(
        (preset) => preset.id == 'water-pattern',
      );
      expect(pattern.basePathPresetId, 'water-base');
      expect(pattern.centerPattern.size, PathCenterPatternSize(width: 2, height: 2));

      final cells = pattern.centerPattern.cells;
      expect(cells.map((cell) => [cell.localX, cell.localY]).toList(), [
        [0, 0],
        [1, 0],
        [0, 1],
        [1, 1],
      ]);
      expect(cells.every((cell) => cell.frames.length >= 2), isTrue);

      expect(cells[0].frames[0].durationMs, 100);
      expect(cells[0].frames[1].durationMs, 150);
      expect(cells[1].frames[0].durationMs, 100);
      expect(cells[1].frames[1].durationMs, 150);
      expect(cells[2].frames[0].durationMs, 200);
      expect(cells[2].frames[1].durationMs, 250);
      expect(cells[3].frames[0].durationMs, 200);
      expect(cells[3].frames[1].durationMs, 250);
      expect(cells[3].frames[1].tilesetId, 'tileset-water-fx');
    });
  });
}

String _fixtureRaw() {
  return File(
    'test/fixtures/path_pattern/project_manifest_pathpattern_animated_2x2.json',
  ).readAsStringSync();
}
