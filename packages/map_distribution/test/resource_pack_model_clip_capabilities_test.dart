import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

void main() {
  test('portable clipped models declare their precise native capability', () {
    final clipped = _catalog(model: true, clipped: true);
    expect(ResourcePackCapabilities.supported, contains('models.static-clip'));
    expect(ResourcePackCapabilities.requiredFor(clipped, []),
        contains('models.static-clip'));
    for (final catalog in [
      _catalog(model: true, clipped: false),
      _catalog(model: false, clipped: true)
    ]) {
      expect(ResourcePackCapabilities.requiredFor(catalog, []),
          isNot(contains('models.static-clip')));
    }
  });
}

ResourcePackCatalog _catalog({required bool model, required bool clipped}) =>
    ResourcePackCatalog(
      smartTilePatternIds: ['sample'],
      smartTileCatalog: ProjectSmartTileCatalog(patterns: [
        ProjectSmartTilePattern(
          id: 'sample',
          name: 'Sample',
          usage: SmartTileUsage.path,
          width: 1,
          height: 1,
          cells: [
            SmartTilePatternCell(x: 0, y: 0, parts: [
              SmartTileVisualPart(
                source: model
                    ? const SmartTileVisualSource.model3d(modelId: 'unit')
                    : const SmartTileVisualSource.frame(
                        frame: SmartTileFrameRef(
                            atlasId: 'sheet', column: 0, row: 0)),
                spatialClip: clipped
                    ? SmartTileSpatialClip(
                        left: 0, top: 0, right: .5, bottom: 1)
                    : null,
              )
            ])
          ],
        )
      ]),
    );
