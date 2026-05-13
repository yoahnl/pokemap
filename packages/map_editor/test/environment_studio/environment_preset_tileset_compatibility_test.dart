import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/environment_studio/authoring/environment_preset_tileset_compatibility.dart';

void main() {
  group('buildEnvironmentPresetTilesetCompatibility', () {
    test('preset vide : source inconnue, aucun mélange', () {
      final compatibility = buildEnvironmentPresetTilesetCompatibility(
        paletteElementIds: const [],
        projectElements: [_element(id: 'grass_a', tilesetId: 'grass')],
      );

      expect(compatibility.sourceTilesetId, isNull);
      expect(compatibility.hasSourceTileset, isFalse);
      expect(compatibility.hasMixedTilesets, isFalse);
      expect(compatibility.availableCompatibleElements.map((e) => e.id),
          ['grass_a']);
    });

    test('un élément : source = tileset résolu', () {
      final compatibility = buildEnvironmentPresetTilesetCompatibility(
        paletteElementIds: const ['grass_a'],
        projectElements: [_element(id: 'grass_a', tilesetId: 'grass')],
      );

      expect(compatibility.sourceTilesetId, 'grass');
      expect(compatibility.hasSourceTileset, isTrue);
      expect(compatibility.hasMixedTilesets, isFalse);
      expect(compatibility.compatiblePaletteElementIds, ['grass_a']);
      expect(compatibility.incompatiblePaletteElementIds, isEmpty);
    });

    test('plusieurs éléments du même tileset : compatible', () {
      final compatibility = buildEnvironmentPresetTilesetCompatibility(
        paletteElementIds: const ['grass_a', 'grass_b'],
        projectElements: [
          _element(id: 'grass_a', tilesetId: 'grass'),
          _element(id: 'grass_b', tilesetId: 'grass'),
          _element(id: 'rock_a', tilesetId: 'rocks'),
        ],
      );

      expect(compatibility.sourceTilesetId, 'grass');
      expect(compatibility.hasMixedTilesets, isFalse);
      expect(compatibility.tilesetIds, ['grass']);
      expect(
        compatibility.availableCompatibleElements.map((e) => e.id),
        ['grass_a', 'grass_b'],
      );
    });

    test('frames.primaryFrame.tilesetId surcharge element.tilesetId', () {
      final compatibility = buildEnvironmentPresetTilesetCompatibility(
        paletteElementIds: const ['flower'],
        projectElements: [
          _element(
            id: 'flower',
            tilesetId: 'fallback',
            frameTilesetId: 'frame_tileset',
          ),
        ],
      );

      expect(compatibility.sourceTilesetId, 'frame_tileset');
    });

    test('plusieurs tilesets : warning de mélange et éléments incompatibles',
        () {
      final compatibility = buildEnvironmentPresetTilesetCompatibility(
        paletteElementIds: const ['grass_a', 'rock_a', 'grass_b'],
        projectElements: [
          _element(id: 'grass_a', tilesetId: 'grass'),
          _element(id: 'rock_a', tilesetId: 'rocks'),
          _element(id: 'grass_b', tilesetId: 'grass'),
        ],
      );

      expect(compatibility.sourceTilesetId, 'grass');
      expect(compatibility.hasMixedTilesets, isTrue);
      expect(compatibility.tilesetIds, ['grass', 'rocks']);
      expect(compatibility.compatiblePaletteElementIds, ['grass_a', 'grass_b']);
      expect(compatibility.incompatiblePaletteElementIds, ['rock_a']);
      expect(
        compatibility.availableCompatibleElements.map((e) => e.id),
        ['grass_a', 'grass_b'],
      );
    });

    test('élément palette introuvable : diagnostic sans crash', () {
      final compatibility = buildEnvironmentPresetTilesetCompatibility(
        paletteElementIds: const ['grass_a', 'missing'],
        projectElements: [_element(id: 'grass_a', tilesetId: 'grass')],
      );

      expect(compatibility.sourceTilesetId, 'grass');
      expect(compatibility.missingPaletteElementIds, ['missing']);
      expect(compatibility.hasMixedTilesets, isFalse);
    });

    test('élément sans tileset clair : exclu du picker compatible', () {
      final compatibility = buildEnvironmentPresetTilesetCompatibility(
        paletteElementIds: const ['grass_a', 'unknown_source'],
        projectElements: [
          _element(id: 'grass_a', tilesetId: 'grass'),
          _element(id: 'unknown_source', tilesetId: ''),
        ],
      );

      expect(compatibility.sourceTilesetId, 'grass');
      expect(compatibility.unknownTilesetElementIds, ['unknown_source']);
      expect(
        compatibility.availableCompatibleElements.map((e) => e.id),
        ['grass_a'],
      );
    });
  });
}

ProjectElementEntry _element({
  required String id,
  required String tilesetId,
  String frameTilesetId = '',
}) {
  return ProjectElementEntry(
    id: id,
    name: 'El $id',
    tilesetId: tilesetId,
    categoryId: 'cat',
    frames: [
      TilesetVisualFrame(
        tilesetId: frameTilesetId,
        source: const TilesetSourceRect(x: 0, y: 0),
      ),
    ],
  );
}
