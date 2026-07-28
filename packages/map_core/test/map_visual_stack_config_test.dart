import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('MapVisualStackConfig JSON', () {
    test('absent config keeps legacy JSON free from visualStack churn', () {
      const map = MapData(
        id: 'legacy',
        name: 'Legacy',
        size: GridSize(width: 1, height: 1),
      );

      final decoded = MapData.fromJson(
        jsonDecode(jsonEncode(map.toJson())) as Map<String, dynamic>,
      );

      expect(decoded.visualStack, isNull);
      expect(decoded.toJson(), isNot(contains('visualStack')));
      expect(
        buildMapVisualCompositionPlan(decoded).plan?.semantics,
        MapVisualCompositionSemantics.legacyRuntimeV1,
      );
    });

    test('canonical v1 round-trips with the Gate 1 map format', () {
      const map = MapData(
        id: 'canonical',
        name: 'Canonical',
        size: GridSize(width: 1, height: 1),
        version: ProjectVersion.v3,
        visualStack: MapVisualStackConfig.canonicalV1,
      );

      final decoded = MapData.fromJson(
        jsonDecode(jsonEncode(map.toJson())) as Map<String, dynamic>,
      );

      expect(decoded.version, ProjectVersion.v3);
      expect(decoded.visualStack, MapVisualStackConfig.canonicalV1);
      expect(
        decoded.toJson()['visualStack'],
        const <String, Object?>{'semanticsVersion': 1},
      );
    });

    test('canonical semantics reject an older map document format', () {
      expect(
        () => MapData.fromJson(
          <String, dynamic>{
            'id': 'unsafe-old-reader',
            'name': 'Unsafe old reader',
            'size': <String, dynamic>{'width': 1, 'height': 1},
            'version': 'v2',
            'visualStack': <String, dynamic>{'semanticsVersion': 1},
          },
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            allOf(contains(r'$.version'), contains('ProjectVersion.v3')),
          ),
        ),
      );
    });

    test('Gate 1 JSON is rejected by the pre-Gate version decoder', () {
      const map = MapData(
        id: 'canonical',
        name: 'Canonical',
        size: GridSize(width: 1, height: 1),
        version: ProjectVersion.v3,
        visualStack: MapVisualStackConfig.canonicalV1,
      );

      expect(
        () => _decodePreGateProjectVersion(map.toJson()['version']),
        throwsFormatException,
      );
    });

    test('legacy v2 remains readable when visualStack is absent', () {
      final decoded = MapData.fromJson(
        <String, dynamic>{
          'id': 'legacy-v2',
          'name': 'Legacy v2',
          'size': <String, dynamic>{'width': 1, 'height': 1},
          'version': 'v2',
        },
      );

      expect(decoded.version, ProjectVersion.v2);
      expect(decoded.visualStack, isNull);
    });

    test('Border authoring never downgrades a canonical v3 map', () {
      const map = MapData(
        id: 'canonical-border',
        name: 'Canonical Border',
        size: GridSize(width: 1, height: 1),
        version: ProjectVersion.v3,
        visualStack: MapVisualStackConfig.canonicalV1,
      );

      final withBorder = addBorderLayer(
        map,
        id: 'border',
        name: 'Border',
      );
      final updated = setBorderLayerContent(
        withBorder,
        layerId: 'border',
        content: BorderLayerContent(),
      );

      expect(withBorder.version, ProjectVersion.v3);
      expect(updated.version, ProjectVersion.v3);
    });

    test('write validation rejects canonical semantics below map format v3',
        () {
      const map = MapData(
        id: 'unsafe-write',
        name: 'Unsafe write',
        size: GridSize(width: 1, height: 1),
        version: ProjectVersion.v2,
        visualStack: MapVisualStackConfig.canonicalV1,
      );

      expect(
        () => MapValidator.validate(map),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            contains('ProjectVersion.v3'),
          ),
        ),
      );
    });

    test('future positive version stays decodable but cannot compose', () {
      final decoded = MapData.fromJson(
        <String, dynamic>{
          'id': 'future',
          'name': 'Future',
          'size': <String, dynamic>{'width': 1, 'height': 1},
          'version': 'v3',
          'visualStack': <String, dynamic>{'semanticsVersion': 99},
        },
      );

      final result = buildMapVisualCompositionPlan(decoded);

      expect(decoded.visualStack?.semanticsVersion, 99);
      expect(result.plan, isNull);
      expect(result.requiresReadOnly, isTrue);
      expect(
        result.diagnostics.single.code,
        MapVisualCompositionDiagnosticCode.unsupportedSemanticsVersion,
      );
    });

    test('direct construction rejects non-positive semantics in release too',
        () {
      expect(
        () => MapVisualStackConfig(semanticsVersion: 0),
        throwsArgumentError,
      );
      expect(
        () => MapVisualStackConfig(semanticsVersion: -1),
        throwsArgumentError,
      );
    });

    for (final invalid in <Object?>[
      null,
      'v1',
      <String, dynamic>{},
      <String, dynamic>{'semanticsVersion': '1'},
      <String, dynamic>{'semanticsVersion': 0},
      <String, dynamic>{'semanticsVersion': -1},
    ]) {
      test('rejects malformed visualStack value $invalid with a JSON path', () {
        expect(
          () => MapData.fromJson(
            <String, dynamic>{
              'id': 'invalid',
              'name': 'Invalid',
              'size': <String, dynamic>{'width': 1, 'height': 1},
              'visualStack': invalid,
            },
          ),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              contains(r'$.visualStack'),
            ),
          ),
        );
      });
    }
  });
}

String _decodePreGateProjectVersion(Object? value) {
  if (value == 'v1' || value == 'v2') {
    return value! as String;
  }
  throw FormatException('Unknown pre-Gate ProjectVersion: $value');
}
