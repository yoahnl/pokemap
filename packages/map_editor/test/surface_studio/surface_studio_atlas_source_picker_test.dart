import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_source_picker.dart';

void main() {
  group('suggestInternalAtlasIdFromName', () {
    test('eau animée', () {
      expect(suggestInternalAtlasIdFromName('Eau animée'), 'eau-animee');
    });

    test('vide', () {
      expect(suggestInternalAtlasIdFromName('   '), 'atlas');
    });
  });

  group('sortedTilesetChoices', () {
    test('ordre sortOrder puis nom', () {
      const a = ProjectTilesetEntry(
        id: 'a',
        name: 'B',
        relativePath: 'a.png',
        sortOrder: 1,
      );
      const b = ProjectTilesetEntry(
        id: 'b',
        name: 'A',
        relativePath: 'b.png',
        sortOrder: 0,
      );
      final o = sortedTilesetChoices([a, b]);
      expect(o.map((e) => e.id).toList(), ['b', 'a']);
    });
  });
}
