import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('flat raster ground retains its explicit terrain sampling choice', () {
    final raw = _part()..['spatialFollowTerrain'] = false;
    final decoded = SmartTileVisualPart.fromJson(raw);
    expect(decoded.toJson()['spatialFollowTerrain'], false);
    expect(SmartTileVisualPart.fromJson(decoded.toJson()), decoded);
    expect(
      SmartTileVisualPart.fromJson(
        _part(),
      ).toJson().containsKey('spatialFollowTerrain'),
      false,
    );
  });

  test('terrain sampling accepts only a JSON boolean', () {
    for (final value in [null, 0, 'false']) {
      expect(
        () => SmartTileVisualPart.fromJson(
          _part()..['spatialFollowTerrain'] = value,
        ),
        throwsFormatException,
      );
    }
  });

  test(
    'old wire versions reject flat sampling instead of silently draping it',
    () {
      final raw = const ProjectSmartTileCatalog.empty().toJson();
      raw['formatVersion'] = 6;
      raw['patterns'] = [
        _pattern(
          SmartTileVisualPart.fromJson(
            _part()..['spatialFollowTerrain'] = false,
          ),
        ).toJson(),
      ];
      expect(
        () => ProjectSmartTileCatalog.fromJson(raw),
        throwsFormatException,
      );
    },
  );

  test(
    'flat raster semantics require a 3D raster ground channel even at zero height',
    () {
      final part = SmartTileVisualPart.fromJson(
        _part()..['spatialFollowTerrain'] = false,
      );
      List<String> codes(SmartTileVisualPart value, {bool spatial = true}) =>
          validateProjectSmartTileCatalog(
            catalog: ProjectSmartTileCatalog(
              atlases: [
                ProjectSmartTileAtlas(
                  id: 'atlas',
                  name: 'Atlas',
                  tilesetId: 'tiles',
                  columns: 1,
                  rows: 1,
                ),
              ],
              patterns: [_pattern(value)],
            ),
            projectTilesetIds: ['tiles'],
            spatial: spatial,
          ).map((diagnostic) => diagnostic.code).toList();
      expect(
        codes(
          part,
        ).where((code) => code.startsWith('smart_tiles.raster.height_')),
        isEmpty,
      );
      expect(
        codes(part, spatial: false),
        contains('smart_tiles.raster.height_dimension_invalid'),
      );
      expect(
        codes(part.copyWith(channel: SmartTileRenderChannel.foreground)),
        contains('smart_tiles.raster.height_channel_invalid'),
      );
      expect(
        codes(
          part.copyWith(
            source: const SmartTileVisualSource.model3d(modelId: 'model'),
          ),
        ),
        contains('smart_tiles.raster.height_source_invalid'),
      );
    },
  );
}

Map<String, dynamic> _part() => const SmartTileVisualPart(
  source: SmartTileVisualSource.frame(
    frame: SmartTileFrameRef(atlasId: 'atlas', column: 0, row: 0),
  ),
).toJson();

ProjectSmartTilePattern _pattern(SmartTileVisualPart part) =>
    ProjectSmartTilePattern(
      id: 'flat-ground',
      name: 'Flat ground',
      usage: SmartTileUsage.terrain,
      width: 1,
      height: 1,
      cells: [
        SmartTilePatternCell(x: 0, y: 0, parts: [part]),
      ],
    );
