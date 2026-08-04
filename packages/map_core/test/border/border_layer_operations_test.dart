import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Border layer operations', () {
    test('add appends a Border layer, promotes V2, and preserves map data', () {
      final source = _map(
        layers: <MapLayer>[_tileLayer()],
        placedElements: const <MapPlacedElement>[
          MapPlacedElement(
            id: 'crate',
            layerId: 'ground',
            elementId: 'crate',
            pos: GridPos(x: 1, y: 1),
          ),
        ],
      );

      final updated = addBorderLayer(
        source,
        id: 'borders',
        name: 'Bordures',
      );

      expect(source.version, ProjectVersion.v6);
      expect(source.layers, hasLength(1));
      expect(updated.version, ProjectVersion.v6);
      expect(updated.layers.map((layer) => layer.id), <String>[
        'ground',
        'borders',
      ]);
      expect(updated.layers.last, isA<BorderLayer>());
      expect(updated.placedElements, source.placedElements);
      expect(updated.entities, source.entities);
      expect(updated.connections, source.connections);
      expect(updated.warps, source.warps);
      expect(updated.triggers, source.triggers);
      expect(updated.gameplayZones, source.gameplayZones);
      expect(updated.events, source.events);
      expect(updated.mapMetadata, source.mapMetadata);
      expect(updated.properties, source.properties);
    });

    test('add rejects duplicate layer ids deterministically', () {
      final source = _map(layers: <MapLayer>[_tileLayer()]);

      expect(
        () => addBorderLayer(source, id: 'ground', name: 'Duplicate'),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            'Layer ID already exists: ground',
          ),
        ),
      );
    });

    test('add rejects invalid insertion indexes instead of clamping', () {
      final source = _map(layers: <MapLayer>[_tileLayer()]);

      for (final index in <int>[-1, source.layers.length + 1]) {
        expect(
          () => addBorderLayer(
            source,
            id: 'borders',
            name: 'Bordures',
            insertIndex: index,
          ),
          _validationMessage('Invalid Border layer insertIndex: $index'),
        );
      }
    });

    test('set content updates only the target and promotes an invalid V1 input',
        () {
      final ground = _tileLayer();
      final source = _map(
        layers: <MapLayer>[
          ground,
          const MapLayer.border(id: 'borders', name: 'Bordures'),
        ],
      );
      final content = BorderLayerContent(
        features: <BorderFeature>[_feature('coast')],
      );

      final updated = setBorderLayerContent(
        source,
        layerId: 'borders',
        content: content,
      );

      expect(source.version, ProjectVersion.v6);
      expect(updated.version, ProjectVersion.v6);
      expect(identical(updated.layers.first, ground), isTrue);
      expect((updated.layers.last as BorderLayer).content, content);
      expect((source.layers.last as BorderLayer).content.isEmpty, isTrue);
    });

    test('set content promotes an inverted V1 feature payload to V2', () {
      final source = _map(
        layers: <MapLayer>[
          const MapLayer.border(id: 'borders', name: 'Bordures'),
        ],
      );
      final inverted = _feature(
        'inverted',
        lineSide: BorderLineSide.inverted,
      );
      final invalidV1 = BorderLayerContent(
        formatVersion: BorderLayerContent.formatVersionV1,
        features: <BorderFeature>[inverted],
      );

      final updated = setBorderLayerContent(
        source,
        layerId: 'borders',
        content: invalidV1,
      );
      final stored = (updated.layers.single as BorderLayer).content;

      expect(stored.formatVersion, BorderLayerContent.formatVersionV2);
      expect(stored.features.single, inverted);
    });

    test('set content rejects missing and non-Border target layers', () {
      final source = _map(layers: <MapLayer>[_tileLayer()]);

      expect(
        () => setBorderLayerContent(
          source,
          layerId: 'missing',
          content: BorderLayerContent.emptyContent,
        ),
        _validationMessage('Layer not found: missing'),
      );
      expect(
        () => setBorderLayerContent(
          source,
          layerId: 'ground',
          content: BorderLayerContent.emptyContent,
        ),
        _validationMessage('Layer is not a border layer: ground'),
      );
    });

    test('upsert appends new features and replaces existing features in place',
        () {
      final first = _feature('first', name: 'Before');
      final second = _feature('second');
      final source = _mapWithBorder(<BorderFeature>[first]);

      final appended = upsertBorderFeature(
        source,
        layerId: 'borders',
        feature: second,
      );
      final replaced = upsertBorderFeature(
        appended,
        layerId: 'borders',
        feature: _feature('first', name: 'After'),
      );
      final features = (replaced.layers.last as BorderLayer).content.features;

      expect(features.map((feature) => feature.id), <String>[
        'first',
        'second',
      ]);
      expect(features.first.name, 'After');
      expect(
        ((source.layers.last as BorderLayer).content.features.single).name,
        'Before',
      );
    });

    test('upsert promotes connectedLine or inverted side but not legacy', () {
      final source = _mapWithBorder(<BorderFeature>[_feature('existing')]);

      final legacy = upsertBorderFeature(
        source,
        layerId: 'borders',
        feature: _feature('legacy'),
        template: BorderBlueprintTemplate.organicEdge,
      );
      final connected = upsertBorderFeature(
        source,
        layerId: 'borders',
        feature: _feature('connected'),
        template: BorderBlueprintTemplate.connectedLine,
      );
      final inverted = upsertBorderFeature(
        source,
        layerId: 'borders',
        feature: _feature('inverted', lineSide: BorderLineSide.inverted),
      );

      expect(
        (legacy.layers.last as BorderLayer).content.formatVersion,
        BorderLayerContent.formatVersionV1,
      );
      expect(
        (connected.layers.last as BorderLayer).content.formatVersion,
        BorderLayerContent.formatVersionV2,
      );
      expect(
        (inverted.layers.last as BorderLayer).content.formatVersion,
        BorderLayerContent.formatVersionV2,
      );
    });

    test('complete writes and upserts promote disabled rotation to V2', () {
      final source = _mapWithBorder(<BorderFeature>[_feature('existing')]);
      final disabled = _feature('disabled', allowAutoRotation: false);
      final invalidV1 = BorderLayerContent(
        features: <BorderFeature>[disabled],
      );

      final replaced = setBorderLayerContent(
        source,
        layerId: 'borders',
        content: invalidV1,
      );
      final upserted = upsertBorderFeature(
        source,
        layerId: 'borders',
        feature: disabled,
      );

      for (final map in <MapData>[replaced, upserted]) {
        final content = (map.layers.last as BorderLayer).content;
        expect(content.formatVersion, BorderLayerContent.formatVersionV2);
        final reloaded = decodeBorderLayerContentJson(
          encodeBorderLayerContentJson(content),
        );
        expect(
          reloaded.featureById('disabled')!.paramsOverride!.allowAutoRotation,
          isFalse,
        );
      }
    });

    test('remove deletes only the requested feature and rejects absence', () {
      final source = _mapWithBorder(<BorderFeature>[
        _feature('first'),
        _feature('second'),
        _feature('third'),
      ]);

      final updated = removeBorderFeature(
        source,
        layerId: 'borders',
        featureId: 'second',
      );

      expect(
        (updated.layers.last as BorderLayer)
            .content
            .features
            .map((feature) => feature.id),
        <String>['first', 'third'],
      );
      expect(updated.version, ProjectVersion.v6);
      expect(
        () => removeBorderFeature(
          source,
          layerId: 'borders',
          featureId: 'missing',
        ),
        _validationMessage(
          'Border feature not found in layer borders: missing',
        ),
      );
    });

    test('reorder uses a strict destination index and preserves all features',
        () {
      final source = _mapWithBorder(<BorderFeature>[
        _feature('first'),
        _feature('second'),
        _feature('third'),
      ]);

      final updated = reorderBorderFeature(
        source,
        layerId: 'borders',
        featureId: 'first',
        newIndex: 2,
      );

      expect(
        (updated.layers.last as BorderLayer)
            .content
            .features
            .map((feature) => feature.id),
        <String>['second', 'third', 'first'],
      );
      expect(
        () => reorderBorderFeature(
          source,
          layerId: 'borders',
          featureId: 'first',
          newIndex: 3,
        ),
        _validationMessage('Invalid Border feature newIndex: 3'),
      );
      expect(
        () => reorderBorderFeature(
          source,
          layerId: 'borders',
          featureId: 'missing',
          newIndex: 0,
        ),
        _validationMessage(
          'Border feature not found in layer borders: missing',
        ),
      );
    });

    test('feature operations reject a non-Border layer consistently', () {
      final source = _map(layers: <MapLayer>[_tileLayer()]);

      expect(
        () => upsertBorderFeature(
          source,
          layerId: 'ground',
          feature: _feature('coast'),
        ),
        _validationMessage('Layer is not a border layer: ground'),
      );
      expect(
        () => removeBorderFeature(
          source,
          layerId: 'ground',
          featureId: 'coast',
        ),
        _validationMessage('Layer is not a border layer: ground'),
      );
    });
  });
}

MapData _map({
  List<MapLayer> layers = const <MapLayer>[],
  List<MapPlacedElement> placedElements = const <MapPlacedElement>[],
}) =>
    MapData(
      id: 'port',
      name: 'Port',
      size: const GridSize(width: 2, height: 2),
      layers: layers,
      placedElements: placedElements,
      mapMetadata: const MapMetadata(
        displayName: 'Port des Brisants',
        tags: <String>['coast'],
      ),
      properties: const <String, dynamic>{'keep': 'map'},
    );

MapData _mapWithBorder(List<BorderFeature> features) => _map(
      layers: <MapLayer>[
        _tileLayer(),
        MapLayer.border(
          id: 'borders',
          name: 'Bordures',
          content: BorderLayerContent(features: features),
        ),
      ],
    ).copyWith(version: ProjectVersion.v6);

MapLayer _tileLayer() => const MapLayer.tile(
      id: 'ground',
      name: 'Ground',
      cells: <int>[0, 0, 0, 0],
    );

BorderFeature _feature(
  String id, {
  String? name,
  BorderLineSide lineSide = BorderLineSide.primary,
  bool allowAutoRotation = true,
}) =>
    BorderFeature(
      id: id,
      name: name ?? 'Feature $id',
      blueprintId: 'coast',
      seed: BorderSignedInt64.fromInt(1),
      geometry: BorderRegionGeometry(
        width: 1,
        height: 1,
        cells: const <bool>[true],
      ),
      lineSide: lineSide,
      paramsOverride: BorderGenerationParams(
        irregularityPermille: 0,
        detailDensityPermille: 0,
        variationPermille: 0,
        maxOverlapPx: 0,
        gapTolerancePx: 0,
        depthRows: 1,
        allowAutoRotation: allowAutoRotation,
      ),
      overrides: const <BorderSlotOverride>[],
      keepOutRegions: const <BorderKeepOutRegion>[],
    );

Matcher _validationMessage(String message) => throwsA(
      isA<ValidationException>().having(
        (error) => error.message,
        'message',
        message,
      ),
    );
