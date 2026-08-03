import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('MapLayer.border schema integration', () {
    test('constructs immutable defaults without collision data', () {
      const layer = MapLayer.border(id: 'border', name: 'Bordures');
      final borderLayer = layer as BorderLayer;

      expect(layer, isA<BorderLayer>());
      expect(layer.id, 'border');
      expect(layer.name, 'Bordures');
      expect(layer.isVisible, isTrue);
      expect(layer.opacity, 1.0);
      expect(borderLayer.content, BorderLayerContent.emptyContent);
      expect(borderLayer.properties, isEmpty);
      expect(MapLayerKind.border.name, 'border');
      expect(layer.toJson().toString(), isNot(contains('collision')));
    });

    test('round-trips the exact border union and authored content', () {
      final layer = MapLayer.border(
        id: 'coast',
        name: 'Côte',
        isVisible: false,
        opacity: 0.75,
        content: BorderLayerContent(
          features: <BorderFeature>[_feature('north'), _feature('south')],
        ),
        properties: const <String, String>{'purpose': 'visual'},
      );

      final encoded = layer.toJson();
      final decoded = MapLayer.fromJson(
        jsonDecode(jsonEncode(encoded)) as Map<String, dynamic>,
      );

      expect(encoded['runtimeType'], 'border');
      expect(
        encoded['content'],
        encodeBorderLayerContentJson((layer as BorderLayer).content),
      );
      expect(encoded['properties'], <String, String>{'purpose': 'visual'});
      expect(decoded, layer);
      expect((decoded as BorderLayer).content.featureCount, 2);
    });

    test('missing content defaults but explicit null and future are strict',
        () {
      final missing = _minimalBorderLayerJson()..remove('content');
      final decoded = MapLayer.fromJson(missing);
      expect((decoded as BorderLayer).content, BorderLayerContent.emptyContent);

      for (final (invalidContent, expectedPath) in <(Object?, String)>[
        (null, r'$.content'),
        (true, r'$.content'),
        (
          <String, Object?>{
            'formatVersion': 4,
            'features': <Object?>[],
          },
          r'$.content.formatVersion',
        ),
      ]) {
        final invalid = _minimalBorderLayerJson()..['content'] = invalidContent;
        expect(
          () => MapLayer.fromJson(invalid),
          _formatAt(expectedPath),
          reason: '$invalidContent',
        );
      }
    });

    test('MapData v6 preserves a border layer and its runtime type', () {
      final map = MapData(
        id: 'port',
        name: 'Port',
        size: const GridSize(width: 2, height: 2),
        version: ProjectVersion.v6,
        layers: const <MapLayer>[
          MapLayer.border(id: 'border', name: 'Bordures'),
        ],
      );

      final encoded = map.toJson();
      final decoded = MapData.fromJson(
        jsonDecode(jsonEncode(encoded)) as Map<String, dynamic>,
      );

      expect(encoded['version'], 'v6');
      expect(
        (encoded['layers']! as List<Map<String, dynamic>>)
            .single['runtimeType'],
        'border',
      );
      expect(decoded, map);
      expect(decoded.layers.single, isA<BorderLayer>());
    });

    test('generic add creates Border last and promotes only it to V2', () {
      final source = _map();

      final withBorder = addMapLayer(
        source,
        kind: MapLayerKind.border,
        id: 'border',
        name: 'Bordures',
      );
      final withObject = addMapLayer(
        source,
        kind: MapLayerKind.object,
        id: 'objects',
        name: 'Objets',
      );

      expect(source.layers, isEmpty);
      expect(source.version, ProjectVersion.v6);
      expect(withBorder.layers.single, isA<BorderLayer>());
      expect(withBorder.layers.single.id, 'border');
      expect(withBorder.version, ProjectVersion.v6);
      expect(withObject.version, ProjectVersion.v6);
    });

    test('generic metadata edits preserve Border content and properties', () {
      final content = BorderLayerContent(
        features: <BorderFeature>[_feature('north')],
      );
      final source = _map(
        version: ProjectVersion.v6,
        layers: <MapLayer>[
          MapLayer.border(
            id: 'border',
            name: 'Before',
            content: content,
            properties: const <String, String>{'purpose': 'visual'},
          ),
        ],
      );

      final renamed = renameMapLayer(source, layerId: 'border', name: 'After');
      final hidden = setMapLayerVisibility(
        renamed,
        layerId: 'border',
        isVisible: false,
      );
      final faded = setMapLayerOpacity(
        hidden,
        layerId: 'border',
        opacity: 0.5,
      );
      final border = faded.layers.single as BorderLayer;

      expect(border.name, 'After');
      expect(border.isVisible, isFalse);
      expect(border.opacity, 0.5);
      expect(border.content, content);
      expect(border.properties, <String, String>{'purpose': 'visual'});
    });

    test('legacy resize refuses Border and validation checks properties', () {
      final content = BorderLayerContent(
        features: <BorderFeature>[_feature('north')],
      );
      final source = _map(
        version: ProjectVersion.v6,
        layers: <MapLayer>[
          MapLayer.border(
            id: 'border',
            name: 'Bordures',
            content: content,
          ),
        ],
      );

      expect(
        () => resizeMapData(source, width: 3, height: 4),
        throwsA(isA<ValidationException>()),
      );
      expect(() => MapValidator.validate(source), returnsNormally);
      expect(
        () => MapValidator.validate(
          _map(
            version: ProjectVersion.v6,
            layers: const <MapLayer>[
              MapLayer.border(
                id: 'border',
                name: 'Bordures',
                properties: <String, String>{' ': 'invalid'},
              ),
            ],
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

MapData _map({
  ProjectVersion version = ProjectVersion.v6,
  List<MapLayer> layers = const <MapLayer>[],
}) =>
    MapData(
      id: 'port',
      name: 'Port',
      size: const GridSize(width: 2, height: 2),
      version: version,
      layers: layers,
    );

Map<String, dynamic> _minimalBorderLayerJson() => <String, dynamic>{
      'id': 'border',
      'name': 'Bordures',
      'isVisible': true,
      'opacity': 1.0,
      'content': <String, Object?>{
        'formatVersion': 1,
        'features': <Object?>[],
      },
      'properties': <String, String>{},
      'runtimeType': 'border',
    };

Matcher _formatAt(String path) => throwsA(
      isA<FormatException>().having(
        (error) => error.message,
        'message',
        startsWith('$path:'),
      ),
    );

BorderFeature _feature(String id) => BorderFeature(
      id: id,
      name: 'Feature $id',
      blueprintId: 'coast',
      seed: BorderSignedInt64.fromInt(1),
      geometry: BorderRegionGeometry(
        width: 1,
        height: 1,
        cells: const <bool>[true],
      ),
      overrides: const <BorderSlotOverride>[],
      keepOutRegions: const <BorderKeepOutRegion>[],
    );
