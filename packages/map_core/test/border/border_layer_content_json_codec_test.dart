import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('BorderLayerContent JSON codec', () {
    test('encodes the exact canonical empty V1 payload', () {
      expect(
        encodeBorderLayerContentJson(BorderLayerContent.emptyContent),
        <String, Object?>{
          'formatVersion': 1,
          'features': <Object?>[],
        },
      );
    });

    test('round-trips features in authored order through JSON', () {
      final content = BorderLayerContent(
        features: <BorderFeature>[_feature('second'), _feature('first')],
      );

      final encoded = encodeBorderLayerContentJson(content);
      final encodedFeatures = encoded['features']! as List<Object?>;

      expect(encoded.keys, <String>['formatVersion', 'features']);
      expect(
        encodedFeatures.map(
          (value) => (value! as Map<String, Object?>)['id'],
        ),
        <String>['second', 'first'],
      );
      expect(
        jsonDecode(jsonEncode(encoded)),
        encoded,
      );
      expect(decodeBorderLayerContentJson(encoded), content);
    });

    test('rejects non-object roots and non-string keys', () {
      for (final invalid in <Object?>[null, true, 1, 'layer', <Object?>[]]) {
        expect(
          () => decodeBorderLayerContentJson(invalid),
          _formatAt(r'$'),
          reason: '$invalid',
        );
      }
      expect(
        () => decodeBorderLayerContentJson(<Object?, Object?>{
          'formatVersion': 1,
          'features': <Object?>[],
          1: 'invalid key',
        }),
        _formatAt(r'$'),
      );
    });

    test('requires exactly formatVersion and features', () {
      final unknown = _emptyJson()..['future'] = true;
      expect(
        () => decodeBorderLayerContentJson(unknown),
        _formatAt(r'$.future'),
      );

      for (final key in <String>['formatVersion', 'features']) {
        final missing = _emptyJson()..remove(key);
        expect(
          () => decodeBorderLayerContentJson(missing),
          _formatAt('\$.$key'),
        );
      }
    });

    test('accepts V1/V2 and rejects unsupported strict integer versions', () {
      for (final invalidVersion in <Object?>[
        null,
        true,
        1.0,
        '1',
        0,
        3,
      ]) {
        final invalid = _emptyJson()..['formatVersion'] = invalidVersion;
        expect(
          () => decodeBorderLayerContentJson(invalid),
          _formatAt(r'$.formatVersion'),
          reason: '$invalidVersion',
        );
      }

      for (final invalidFeatures in <Object?>[
        null,
        true,
        <String, Object?>{},
      ]) {
        final invalid = _emptyJson()..['features'] = invalidFeatures;
        expect(
          () => decodeBorderLayerContentJson(invalid),
          _formatAt(r'$.features'),
        );
      }
    });

    test('V2 round-trips inverted side and V1 preserves historical shape', () {
      final content = BorderLayerContent(
        formatVersion: 2,
        features: <BorderFeature>[
          _feature('cliff', lineSide: BorderLineSide.inverted),
        ],
      );

      final encoded = encodeBorderLayerContentJson(content);
      expect(encoded['formatVersion'], 2);
      expect(
        ((encoded['features']! as List<Object?>).single!
            as Map<String, Object?>)['lineSide'],
        'inverted',
      );
      expect(decodeBorderLayerContentJson(encoded), content);

      final historical = _emptyJson()
        ..['features'] = <Object?>[
          encodeBorderFeatureJson(_feature('old')),
        ];
      final decodedHistorical = decodeBorderLayerContentJson(historical);
      expect(decodedHistorical.formatVersion, 1);
      expect(
          decodedHistorical.features.single.lineSide, BorderLineSide.primary);
      expect(encodeBorderLayerContentJson(decodedHistorical), historical);
    });

    test('delegates child validation with indexed paths', () {
      final wrongElement = _emptyJson()..['features'] = <Object?>[true];
      expect(
        () => decodeBorderLayerContentJson(wrongElement),
        _formatAt(r'$.features[0]'),
      );

      final invalidFeature = encodeBorderFeatureJson(_feature('a'));
      invalidFeature['future'] = true;
      final invalidChild = _emptyJson()
        ..['features'] = <Object?>[invalidFeature];
      expect(
        () => decodeBorderLayerContentJson(invalidChild),
        _formatAt(r'$.features[0].future'),
      );
    });

    test('reports duplicate ids at the second feature id path', () {
      final feature = encodeBorderFeatureJson(_feature('same'));
      final invalid = _emptyJson()
        ..['features'] = <Object?>[
          _deepCopy(feature),
          _deepCopy(feature),
        ];

      expect(
        () => decodeBorderLayerContentJson(
          invalid,
          path: r'$.layers[3].content',
        ),
        _formatAt(r'$.layers[3].content.features[1].id'),
      );
    });

    test('propagates custom paths while encoding nested features', () {
      final content = BorderLayerContent(features: <BorderFeature>[
        _feature('a'),
      ]);

      final encoded = encodeBorderLayerContentJson(
        content,
        path: r'$.layers[2].content',
      );

      expect(
        encoded['features'],
        <Object?>[
          encodeBorderFeatureJson(
            content.features.single,
            path: r'$.layers[2].content.features[0]',
          ),
        ],
      );
    });
  });
}

Map<String, Object?> _emptyJson() => <String, Object?>{
      'formatVersion': 1,
      'features': <Object?>[],
    };

Map<String, Object?> _deepCopy(Map<String, Object?> value) =>
    jsonDecode(jsonEncode(value)) as Map<String, Object?>;

Matcher _formatAt(String path) => throwsA(
      isA<FormatException>().having(
        (error) => error.message,
        'message',
        startsWith('$path:'),
      ),
    );

BorderFeature _feature(
  String id, {
  BorderLineSide lineSide = BorderLineSide.primary,
}) =>
    BorderFeature(
      id: id,
      name: 'Feature $id',
      blueprintId: 'blueprint-a',
      seed: BorderSignedInt64.fromInt(1),
      geometry: BorderRegionGeometry(
        width: 1,
        height: 1,
        cells: const <bool>[true],
      ),
      lineSide: lineSide,
      overrides: const <BorderSlotOverride>[],
      keepOutRegions: const <BorderKeepOutRegion>[],
    );
