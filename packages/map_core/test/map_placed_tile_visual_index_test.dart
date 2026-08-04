import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../../tools/performance/smart_tiles_rich_map_fixture.dart';

void main() {
  test('spatial index bounds viewport work and visual-definition cache', () {
    final small = generateSmartTilesRichMapFixture(extent: 128);
    final large = generateSmartTilesRichMapFixture(extent: 1024);

    MapPlacedTileVisualBatch resolve(SmartTilesRichMapFixture fixture) {
      final layer = fixture.map.layers.whereType<ObjectLayer>().single;
      final sources = <String, ProjectTilesetSource>{
        for (final tileset in fixture.manifest.tilesets)
          if (tileset.source case final source?) tileset.id: source,
      };
      final index = MapPlacedTileVisualIndex.build(
        layer: layer,
        tilesetsById: sources,
        sourceCellWidth: 32,
        sourceCellHeight: 32,
        destinationCellWidth: 32,
        destinationCellHeight: 32,
      );
      final batch = index.resolve(
        elapsedMs: 0,
        viewport: const SmartTileGeometryRect(
          left: 11 * 32,
          top: 11 * 32,
          width: 3 * 32,
          height: 3 * 32,
        ),
      );
      expect(batch.work.sourceObjectCount, layer.tileObjects.length);
      expect(batch.work.cachedVisualDefinitionCount, lessThanOrEqualTo(4));
      expect(batch.work.resolvedVisualCount, batch.visuals.length);
      return batch;
    }

    final smallBatch = resolve(small);
    final largeBatch = resolve(large);

    expect(largeBatch.work.candidateObjectVisits,
        smallBatch.work.candidateObjectVisits);
    expect(largeBatch.work.candidateObjectVisits, lessThanOrEqualTo(4));
    expect(largeBatch.visuals.map((visual) => visual.objectId),
        smallBatch.visuals.map((visual) => visual.objectId));
  });

  test('legacy resolver preserves indexed visual semantics', () {
    final fixture = generateSmartTilesRichMapFixture(extent: 128);
    final layer = fixture.map.layers.whereType<ObjectLayer>().single;
    final sources = <String, ProjectTilesetSource>{
      for (final tileset in fixture.manifest.tilesets)
        if (tileset.source case final source?) tileset.id: source,
    };
    final index = MapPlacedTileVisualIndex.build(
      layer: layer,
      tilesetsById: sources,
      sourceCellWidth: 32,
      sourceCellHeight: 32,
      destinationCellWidth: 32,
      destinationCellHeight: 32,
    );
    final indexed = index.resolve(elapsedMs: 75).visuals;
    final legacy = resolveMapPlacedTileVisuals(
      layer: layer,
      tilesetsById: sources,
      sourceCellWidth: 32,
      sourceCellHeight: 32,
      destinationCellWidth: 32,
      destinationCellHeight: 32,
      elapsedMs: 75,
    );

    List<Object?> signature(MapPlacedTileVisualInstruction visual) => <Object?>[
          visual.objectId,
          visual.tilesetId,
          visual.assetId,
          visual.sourceRect,
          visual.destinationRect.left,
          visual.destinationRect.top,
          visual.destinationRect.width,
          visual.destinationRect.height,
          visual.transform,
          visual.opacity,
        ];
    expect(legacy.map(signature), indexed.map(signature));
  });
}
