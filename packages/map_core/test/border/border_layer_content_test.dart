import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('BorderLayerContent', () {
    test('distinguishes the V1 default from the latest supported version', () {
      expect(BorderLayerContent().formatVersion,
          BorderLayerContent.formatVersionV1);
      expect(
        BorderLayerContent.latestSupportedFormatVersion,
        BorderLayerContent.formatVersionV2,
      );
      expect(
        BorderLayerContent.currentFormatVersion,
        BorderLayerContent.latestSupportedFormatVersion,
      );
    });

    test('exposes one immutable empty V1 value', () {
      const content = BorderLayerContent.emptyContent;

      expect(content.formatVersion, 1);
      expect(content.features, isEmpty);
      expect(content.featureCount, 0);
      expect(content.isEmpty, isTrue);
      expect(content.featureById('missing'), isNull);
      expect(() => content.features.add(_feature('x')), throwsUnsupportedError);
    });

    test('copies features and preserves authored order', () {
      final source = <BorderFeature>[_feature('second'), _feature('first')];
      final content = BorderLayerContent(features: source);

      source
        ..clear()
        ..add(_feature('later'));

      expect(content.features.map((feature) => feature.id), <String>[
        'second',
        'first',
      ]);
      expect(content.featureCount, 2);
      expect(content.isEmpty, isFalse);
      expect(content.featureById('first'), content.features[1]);
      expect(content.featureById(' first '), isNull);
      expect(() => content.features.clear(), throwsUnsupportedError);
    });

    test('uses ordered value equality', () {
      final first = BorderLayerContent(
        features: <BorderFeature>[_feature('a'), _feature('b')],
      );
      final equal = BorderLayerContent(
        features: <BorderFeature>[_feature('a'), _feature('b')],
      );
      final reordered = BorderLayerContent(
        features: <BorderFeature>[_feature('b'), _feature('a')],
      );

      expect(first, equal);
      expect(first.hashCode, equal.hashCode);
      expect(first, isNot(reordered));
    });

    test('accepts V2 and rejects unsupported versions and duplicate ids', () {
      expect(
        BorderLayerContent(
          formatVersion: BorderLayerContent.formatVersionV2,
        ).formatVersion,
        BorderLayerContent.formatVersionV2,
      );
      for (final version in <int>[0, 3]) {
        expect(
          () => BorderLayerContent(formatVersion: version),
          throwsA(isA<ValidationException>()),
        );
      }
      expect(
        () => BorderLayerContent(
          features: <BorderFeature>[_feature('same'), _feature('same')],
        ),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            contains('same'),
          ),
        ),
      );
    });
  });
}

BorderFeature _feature(String id) => BorderFeature(
      id: id,
      name: 'Feature $id',
      blueprintId: 'blueprint-a',
      seed: BorderSignedInt64.fromInt(1),
      geometry: BorderRegionGeometry(
        width: 1,
        height: 1,
        cells: const <bool>[true],
      ),
      overrides: const <BorderSlotOverride>[],
      keepOutRegions: const <BorderKeepOutRegion>[],
    );
