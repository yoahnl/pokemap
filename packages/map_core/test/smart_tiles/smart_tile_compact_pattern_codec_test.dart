import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final source = const SmartTileVisualSource.frame(
    frame: SmartTileFrameRef(atlasId: 'atlas', column: 2, row: 3),
  );
  final basic = ProjectSmartTilePattern(
    id: 'floor',
    name: 'Floor',
    usage: SmartTileUsage.path,
    width: 1,
    height: 1,
    cells: [
      SmartTilePatternCell(
        x: 0,
        y: 0,
        parts: [SmartTileVisualPart(source: source)],
      ),
    ],
  );
  Map<String, dynamic> wire(Object value) =>
      jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
  test('catalog omits only neutral pattern cell and visual defaults', () {
    final catalog = ProjectSmartTileCatalog(patterns: [basic]);
    final json = wire(catalog.toJson());
    final pattern = (json['patterns'] as List).single as Map;
    expect(pattern.keys.toSet(), {
      'id',
      'name',
      'usage',
      'width',
      'height',
      'cells',
    });
    final cell = (pattern['cells'] as List).single as Map;
    expect(cell.keys.toSet(), {'x', 'y', 'parts'});
    final part = (cell['parts'] as List).single as Map;
    expect(part.keys.toSet(), {'source'});
    expect(part['source']['frame'], {
      'atlasId': 'atlas',
      'column': 2,
      'row': 3,
    });
    expect(ProjectSmartTileCatalog.fromJson(json), catalog);
    expect(
      ProjectSmartTilePattern.fromJson(Map<String, dynamic>.from(pattern)),
      basic,
    );
  });
  test(
    'standalone and expanded encoders retain their complete definitions',
    () {
      final catalog = ProjectSmartTileCatalog(patterns: [basic]);
      final expanded = wire(catalog.toJson(compact: false));
      expect((expanded['patterns'] as List).single, basic.toJson());
      expect(basic.toJson(), containsPair('repeatMode', 'tiled'));
      expect(basic.cells.single.toJson(), containsPair('collision', 'inherit'));
      expect(
        basic.cells.single.parts.single.toJson(),
        containsPair('channel', 'ground'),
      );
      expect(ProjectSmartTileCatalog.fromJson(expanded), catalog);
    },
  );
  test(
    'nondefault geometry clipping height channels and construction survive',
    () {
      final pattern = basic.copyWith(
        categoryId: 'rooms',
        width: 3,
        height: 2,
        anchorX: 1,
        anchorY: 1,
        repeatMode: SmartTilePatternRepeatMode.stamp,
        clippingPolicy: SmartTilePatternClippingPolicy.reject,
        construction: SmartTilePatternConstruction(
          x: SmartTilePatternRepeatAxis(repeatStart: 1, repeatLength: 1),
        ),
        drawOrder: 4,
        tags: ['interior'],
        sortOrder: -2,
        cells: [
          SmartTilePatternCell(
            x: 1,
            y: 1,
            collision: SmartTilePatternCollision.blocked,
            eraseMaterial: true,
            parts: [
              SmartTileVisualPart(
                source: const SmartTileVisualSource.model3d(
                  modelId: 'stairs',
                  scale: .5,
                  offsetX: -2,
                  offsetY: .125,
                  offsetZ: 3,
                  animationIndex: 0,
                  followTerrain: false,
                  replacesGround: true,
                ),
                transform: const SmartTileSpriteTransform(
                  quarterTurns: 1,
                  flipX: true,
                ),
                channel: SmartTileRenderChannel.canopy,
                frameSampling: SmartTileFrameSampling.tessellated,
                offsetUnit: SmartTileOffsetUnit.cell,
                offsetX: -3,
                offsetY: 2,
                spatialHeightOffset: .75,
                spatialFollowTerrain: false,
                spatialClip: SmartTileSpatialClip(
                  left: .1,
                  top: .2,
                  right: .8,
                  bottom: .9,
                ),
                footprintWidth: 3,
                footprintHeight: 2,
                anchorX: 1,
                anchorY: 1,
                drawOrder: -4,
              ),
            ],
          ),
        ],
      );
      final catalog = ProjectSmartTileCatalog(patterns: [pattern]);
      final encoded = wire(catalog.toJson());
      expect(ProjectSmartTileCatalog.fromJson(encoded), catalog);
      expect((encoded['patterns'] as List).single, pattern.toJson());
    },
  );
  test(
    'empty eraser cells and explicit collision remain distinct from sparse holes',
    () {
      final pattern = basic.copyWith(
        width: 3,
        cells: [
          const SmartTilePatternCell(x: 0, y: 0),
          const SmartTilePatternCell(
            x: 1,
            y: 0,
            eraseMaterial: true,
            collision: SmartTilePatternCollision.passable,
          ),
        ],
      );
      final catalog = ProjectSmartTileCatalog(patterns: [pattern]);
      final restored = ProjectSmartTileCatalog.fromJson(wire(catalog.toJson()));
      expect(restored, catalog);
      expect(restored.patterns.single.cells.map((cell) => cell.x), [0, 1]);
      expect(restored.patterns.single.cells[1].eraseMaterial, isTrue);
      expect(
        restored.patterns.single.cells[1].collision,
        SmartTilePatternCollision.passable,
      );
    },
  );
  test(
    'portable catalog retains every pattern ID and typed dependency after compaction',
    () {
      final animated = basic.copyWith(
        id: 'reaction',
        cells: [
          SmartTilePatternCell(
            x: 0,
            y: 0,
            parts: [
              const SmartTileVisualPart(
                source: SmartTileVisualSource.animation(animationId: 'react'),
                channel: SmartTileRenderChannel.actorOcclusion,
              ),
            ],
          ),
        ],
      );
      final catalog = ResourcePackCatalog(
        smartTileCatalog: ProjectSmartTileCatalog(patterns: [basic, animated]),
        smartTilePatternIds: ['floor', 'reaction'],
      );
      final encoded = wire(catalog.toJson());
      final restored = ResourcePackCatalog.fromJson(encoded);
      expect(restored, catalog);
      expect(restored.smartTileCatalog.patterns.map((pattern) => pattern.id), [
        'floor',
        'reaction',
      ]);
      expect(
        restored.smartTileCatalog.patterns[1].cells.single.parts.single.source,
        const SmartTileVisualSource.animation(animationId: 'react'),
      );
      expect(
        jsonEncode(encoded).length,
        lessThan(
          jsonEncode({
            ...encoded,
            'smartTileCatalog': catalog.smartTileCatalog.toJson(compact: false)
              ..remove('drafts'),
          }).length,
        ),
      );
    },
  );
  test(
    'compaction does not mutate authored patterns or accept invalid compact integers',
    () {
      final before = jsonEncode(basic.toJson());
      final catalog = ProjectSmartTileCatalog(patterns: [basic]);
      final encoded = wire(catalog.toJson());
      expect(jsonEncode(basic.toJson()), before);
      final pattern =
          (encoded['patterns'] as List).single as Map<String, dynamic>;
      pattern['anchorX'] = .5;
      expect(
        () => ProjectSmartTileCatalog.fromJson(encoded),
        throwsFormatException,
      );
    },
  );
}
