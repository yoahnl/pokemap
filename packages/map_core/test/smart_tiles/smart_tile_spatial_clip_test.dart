import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const clip = {'left': 0.0, 'top': .0625, 'right': 1.0, 'bottom': 1.0};

Map<String, dynamic> partJson() => {
  'source': {
    'kind': 'frame',
    'frame': {'atlasId': 'atlas', 'column': 0, 'row': 0},
  },
  'spatialClip': clip,
};

void main() {
  test('raster clipping retains its normalized rectangle', () {
    final part = SmartTileVisualPart.fromJson(partJson());
    expect(part.toJson()['spatialClip'], clip);
    expect(SmartTileVisualPart.fromJson(part.toJson()), part);
    final plain = partJson()..remove('spatialClip');
    expect(
      SmartTileVisualPart.fromJson(plain).toJson().containsKey('spatialClip'),
      isFalse,
    );
  });

  test('raster clips reject invalid or ambiguous rectangles', () {
    for (final value in [
      {...clip, 'left': -.1},
      {...clip, 'right': 2.0},
      {...clip, 'top': 1.0},
      {...clip, 'left': double.nan},
      {...clip, 'right': double.infinity},
      {...clip, 'left': '0'},
      {...clip, 'unused': 1},
      {'top': 0.0},
      'rectangle',
    ]) {
      expect(
        () => SmartTileVisualPart.fromJson(partJson()..['spatialClip'] = value),
        throwsA(isA<FormatException>()),
      );
    }
  });

  test('catalogs declaring version five reject spatial clipping', () {
    final raw = const ProjectSmartTileCatalog.empty().toJson();
    raw['formatVersion'] = 5;
    raw['patterns'] = [
      {
        'id': 'trim',
        'name': 'Trim',
        'usage': 'terrain',
        'width': 1,
        'height': 1,
        'cells': [
          {
            'x': 0,
            'y': 0,
            'parts': [partJson()],
          },
        ],
      },
    ];
    expect(
      () => ProjectSmartTileCatalog.fromJson(raw),
      throwsA(isA<FormatException>()),
    );
  });

  for (final scope in ['pattern', 'draft', 'preset']) {
    test('$scope clipping requires a spatial raster ground part', () {
      List<String> codes(Map<String, dynamic> raw, {bool spatial = true}) {
        final part = SmartTileVisualPart.fromJson(raw);
        final rule = SmartTileRule(
          id: 'base',
          centerMatch: SmartTileSlotMatch.material('grass'),
          candidates: [
            SmartTileCandidate(id: 'base', parts: [part]),
          ],
        );
        final catalog = ProjectSmartTileCatalog(
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
            if (scope == 'pattern')
              ProjectSmartTilePattern(
                id: 'trim',
                name: 'Trim',
                usage: SmartTileUsage.terrain,
                width: 1,
                height: 1,
                cells: [
                  SmartTilePatternCell(x: 0, y: 0, parts: [part]),
                ],
              ),
          ],
          drafts: [
            if (scope == 'draft')
              ProjectSmartTileAuthoringDraft(
                id: 'draft',
                targetPresetId: 'trim',
                name: 'Trim',
                usage: SmartTileUsage.terrain,
                lastStage: SmartTileAuthoringStage.forms,
                rules: [rule],
              ),
          ],
          presets: [
            if (scope == 'preset')
              ProjectSmartTilePreset(
                id: 'trim',
                name: 'Trim',
                usage: SmartTileUsage.terrain,
                topology: SmartTileTopology.uniform,
                templateHint: SmartTileTemplateHint.simple,
                defaultMaterialId: 'grass',
                allowedMaterialIds: ['grass'],
                coveragePolicy: SmartTileCoveragePolicy.sparse,
                coverageProfile: SmartTileCoverageProfile(
                  mode: SmartTileCoverageMode.template,
                ),
                transformPolicy: SmartTileTransformPolicy(),
                rules: [rule],
              ),
          ],
        );
        return validateProjectSmartTileCatalog(
              catalog: catalog,
              projectTilesetIds: ['tiles'],
              spatial: spatial,
            )
            .map((diagnostic) => diagnostic.code)
            .where((code) => code.startsWith('smart_tiles.raster.clip_'))
            .toList();
      }

      expect(codes(partJson()), isEmpty);
      expect(
        codes(partJson(), spatial: false),
        contains('smart_tiles.raster.clip_dimension_invalid'),
      );
      expect(
        codes(partJson()..['source'] = {'kind': 'model3d', 'modelId': 'unit'}),
        isEmpty,
      );
      expect(
        codes(partJson()..['channel'] = 'foreground'),
        contains('smart_tiles.raster.clip_channel_invalid'),
      );
    });
  }
}
