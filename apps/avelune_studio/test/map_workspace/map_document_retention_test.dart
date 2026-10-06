import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'package:avelune_studio/features/map_workspace/data/map_document_retention.dart';

void main() {
  test('omitted null metadata does not prevent opening an ordinary map', () {
    final source = _json();
    final placed = (source['placedElements'] as List).single as Map;
    placed['shadowOverride'] = null;
    final bytes = utf8.encode(jsonEncode(source));
    final original = List<int>.of(bytes);
    final map = MapData.fromJson(source);

    expect(() => requireMapDocumentRetention(bytes, map), returnsNormally);
    expect(bytes, original);
    expect(map.placedElements.single.id, 'tree-1');
    expect(map.placedElements.single.properties, {'ordinary': 'preserved'});
    final saved = jsonDecode(jsonEncode(map.toJson())) as Map;
    final savedPlaced = (saved['placedElements'] as List).single as Map;
    expect(savedPlaced.keys, isNot(contains('shadowOverride')));
  });

  for (final value in [false, 0, '', <String, dynamic>{}, <Object>[]]) {
    test('unmodeled non-null data remains protected: $value', () {
      final source = _json()..['unmodeledData'] = value;
      final map = MapData.fromJson(source);

      expect(
        () => requireMapDocumentRetention(utf8.encode(jsonEncode(source)), map),
        throwsFormatException,
      );
    });
  }

  test('nested unmodeled non-null data remains protected', () {
    final source = _json();
    final placed = (source['placedElements'] as List).single as Map;
    placed['unmodeledData'] = {'enabled': false};
    final map = MapData.fromJson(source);

    expect(
      () => requireMapDocumentRetention(utf8.encode(jsonEncode(source)), map),
      throwsFormatException,
    );
  });

  test(
    'non-null removed configuration is not silently discarded by Studio',
    () {
      final source = _json();
      final placed = (source['placedElements'] as List).single as Map;
      placed['shadowOverride'] = {'enabled': true, 'opacity': 0.5};
      final map = MapData.fromJson(source);

      expect(
        () => requireMapDocumentRetention(utf8.encode(jsonEncode(source)), map),
        throwsFormatException,
      );
    },
  );

  test('changed ordinary content remains protected', () {
    final source = _json();
    final map = MapData.fromJson(source).copyWith(name: 'Changed');

    expect(
      () => requireMapDocumentRetention(utf8.encode(jsonEncode(source)), map),
      throwsFormatException,
    );
  });

  test('removed placed elements remain protected', () {
    final source = _json();
    final map = MapData.fromJson(source).copyWith(placedElements: []);

    expect(
      () => requireMapDocumentRetention(utf8.encode(jsonEncode(source)), map),
      throwsFormatException,
    );
  });
}

Map<String, dynamic> _json() => jsonDecode(jsonEncode(_map.toJson()));

const _map = MapData(
  id: 'map',
  name: 'Current map',
  size: GridSize(width: 4, height: 4),
  placedElements: [
    MapPlacedElement(
      id: 'tree-1',
      layerId: 'decor',
      elementId: 'tree',
      pos: GridPos(x: 1, y: 1),
      properties: {'ordinary': 'preserved'},
    ),
  ],
);
