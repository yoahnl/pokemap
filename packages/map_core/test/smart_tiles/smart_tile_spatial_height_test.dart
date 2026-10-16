import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'raster parts retain a physical height distinct from their canvas offset',
    () {
      final raw = rasterPartJson()..['spatialHeightOffset'] = -2.5;
      final part = SmartTileVisualPart.fromJson(raw);
      expect(part.toJson()['spatialHeightOffset'], -2.5);
      expect(part.offsetX, 0);
      expect(part.offsetY, 0);
      expect(SmartTileVisualPart.fromJson(part.toJson()), part);
      expect(
        SmartTileVisualPart.fromJson(
          rasterPartJson(),
        ).toJson().containsKey('spatialHeightOffset'),
        isFalse,
      );
    },
  );

  test('raster physical heights reject non-finite and non-numeric values', () {
    for (final value in [double.nan, double.infinity, '2.5']) {
      expect(
        () => SmartTileVisualPart.fromJson(
          rasterPartJson()..['spatialHeightOffset'] = value,
        ),
        throwsA(isA<FormatException>()),
      );
    }
  });

  test(
    'catalogs declaring an older wire version reject raster physical heights',
    () {
      final part = rasterPartJson()..['spatialHeightOffset'] = -1.0;
      final raw = const ProjectSmartTileCatalog.empty().toJson();
      raw['formatVersion'] = 4;
      raw['patterns'] = [
        {
          'id': 'support',
          'name': 'Support',
          'usage': 'terrain',
          'width': 1,
          'height': 1,
          'cells': [
            {
              'x': 0,
              'y': 0,
              'parts': [part],
            },
          ],
        },
      ];
      expect(
        () => ProjectSmartTileCatalog.fromJson(Map<String, dynamic>.from(raw)),
        throwsA(isA<FormatException>()),
      );
    },
  );

  test('height offsets are validated as spatial raster ground semantics', () {
    final part = SmartTileVisualPart.fromJson(
      rasterPartJson()..['spatialHeightOffset'] = -1.0,
    );
    List<SmartTileDiagnostic> validate(
      SmartTileVisualPart visual, {
      bool spatial = true,
    }) => validateProjectSmartTileCatalog(
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
        patterns: [
          ProjectSmartTilePattern(
            id: 'support',
            name: 'Support',
            usage: SmartTileUsage.terrain,
            width: 1,
            height: 1,
            cells: [
              SmartTilePatternCell(x: 0, y: 0, parts: [visual]),
            ],
          ),
        ],
      ),
      projectTilesetIds: ['tiles'],
      spatial: spatial,
    );
    expect(validate(part).where((diagnostic) => diagnostic.isError), isEmpty);
    expect(
      validate(part, spatial: false).map((diagnostic) => diagnostic.code),
      contains('smart_tiles.raster.height_dimension_invalid'),
    );
    expect(
      validate(
        part.copyWith(source: SmartTileVisualSource.model3d(modelId: 'unit')),
      ).map((diagnostic) => diagnostic.code),
      contains('smart_tiles.raster.height_source_invalid'),
    );
    expect(
      validate(
        part.copyWith(channel: SmartTileRenderChannel.foreground),
      ).map((diagnostic) => diagnostic.code),
      contains('smart_tiles.raster.height_channel_invalid'),
    );
  });

  test('draft raster heights obey the spatial source and channel rules', () {
    final part = SmartTileVisualPart.fromJson(
      rasterPartJson()..['spatialHeightOffset'] = -1.0,
    );
    List<String> codes(SmartTileVisualPart visual, {bool spatial = true}) =>
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
            drafts: [
              ProjectSmartTileAuthoringDraft(
                id: 'draft-support',
                targetPresetId: 'support',
                name: 'Support',
                usage: SmartTileUsage.terrain,
                lastStage: SmartTileAuthoringStage.forms,
                rules: [
                  SmartTileRule(
                    id: 'base',
                    centerMatch: SmartTileSlotMatch.material('grass'),
                    candidates: [
                      SmartTileCandidate(id: 'support', parts: [visual]),
                    ],
                  ),
                ],
              ),
            ],
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
        part.copyWith(source: SmartTileVisualSource.model3d(modelId: 'unit')),
      ),
      contains('smart_tiles.raster.height_source_invalid'),
    );
  });
}

Map<String, dynamic> rasterPartJson() => const SmartTileVisualPart(
  source: SmartTileVisualSource.frame(
    frame: SmartTileFrameRef(atlasId: 'atlas', column: 0, row: 0),
  ),
).toJson();
