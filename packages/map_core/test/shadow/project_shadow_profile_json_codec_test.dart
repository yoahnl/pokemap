import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

ProjectShadowProfile _completeProfile() {
  return ProjectShadowProfile(
    id: 'tree_large',
    name: 'Large tree shadow',
    mode: ShadowCasterMode.ellipse,
    renderPass: ShadowRenderPass.groundStatic,
    offsetX: 4,
    offsetY: 12,
    scaleX: 1.2,
    scaleY: 0.45,
    opacity: 0.35,
    colorHexRgb: '000000',
    softnessMode: ShadowSoftnessMode.hardEdge,
  );
}

Map<String, Object?> _completeJson() {
  return <String, Object?>{
    'id': 'tree_large',
    'name': 'Large tree shadow',
    'mode': 'ellipse',
    'renderPass': 'groundStatic',
    'offsetX': 4.0,
    'offsetY': 12.0,
    'scaleX': 1.2,
    'scaleY': 0.45,
    'opacity': 0.35,
    'colorHexRgb': '000000',
    'softnessMode': 'hardEdge',
  };
}

Map<String, Object?> _minimalJson() {
  return <String, Object?>{
    'id': 'actor_contact',
    'name': 'Actor contact shadow',
    'mode': 'contactBlob',
    'renderPass': 'actorContact',
  };
}

Map<String, Object?> _without(
  Map<String, Object?> source,
  String key,
) {
  return Map<String, Object?>.from(source)..remove(key);
}

void main() {
  group('ProjectShadowProfile JSON codec', () {
    test('encodes a complete profile into canonical JSON', () {
      expect(
        encodeProjectShadowProfile(_completeProfile()),
        _completeJson(),
      );
    });

    test('decodes complete JSON into a profile', () {
      expect(
        decodeProjectShadowProfile(_completeJson()),
        _completeProfile(),
      );
    });

    test('roundtrips encode then decode without changing value', () {
      final profile = _completeProfile();

      expect(
        decodeProjectShadowProfile(encodeProjectShadowProfile(profile)),
        profile,
      );
    });

    test('roundtrips decode then encode into canonical JSON', () {
      final json = Map<String, Object?>.from(_completeJson())
        ..['colorHexRgb'] = '#000000'
        ..['unknownFutureField'] = true;

      expect(
        encodeProjectShadowProfile(decodeProjectShadowProfile(json)),
        _completeJson(),
      );
    });

    test('decodes minimal JSON with V0 defaults', () {
      final profile = decodeProjectShadowProfile(_minimalJson());

      expect(profile.id, 'actor_contact');
      expect(profile.name, 'Actor contact shadow');
      expect(profile.mode, ShadowCasterMode.contactBlob);
      expect(profile.renderPass, ShadowRenderPass.actorContact);
      expect(profile.offsetX, 0);
      expect(profile.offsetY, 0);
      expect(profile.scaleX, 1);
      expect(profile.scaleY, 1);
      expect(profile.opacity, 0.35);
      expect(profile.colorHexRgb, '000000');
      expect(profile.softnessMode, ShadowSoftnessMode.hardEdge);
    });

    test('accepts lowercase colorHexRgb and normalizes uppercase', () {
      final profile = decodeProjectShadowProfile(
        Map<String, Object?>.from(_minimalJson())..['colorHexRgb'] = '0a0b0c',
      );

      expect(profile.colorHexRgb, '0A0B0C');
      expect(encodeProjectShadowProfile(profile)['colorHexRgb'], '0A0B0C');
    });

    test('accepts colorHexRgb with # and encodes without #', () {
      final profile = decodeProjectShadowProfile(
        Map<String, Object?>.from(_minimalJson())..['colorHexRgb'] = '#0a0b0c',
      );

      expect(profile.colorHexRgb, '0A0B0C');
      expect(encodeProjectShadowProfile(profile)['colorHexRgb'], '0A0B0C');
    });

    test('rejects invalid colorHexRgb values', () {
      for (final color in <String>[
        '',
        '#',
        '#00000',
        '#0000000',
        '00000',
        '0000000',
        'GGGGGG',
        '#GGGGGG',
      ]) {
        expect(
          () => decodeProjectShadowProfile(
            Map<String, Object?>.from(_minimalJson())..['colorHexRgb'] = color,
          ),
          throwsA(isA<ValidationException>()),
          reason: color,
        );
      }
    });

    test('rejects unknown enum values', () {
      expect(
        () => decodeProjectShadowProfile(
          Map<String, Object?>.from(_minimalJson())..['mode'] = 'projectedQuad',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectShadowProfile(
          Map<String, Object?>.from(_minimalJson())..['renderPass'] = 'z999',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectShadowProfile(
          Map<String, Object?>.from(_minimalJson())
            ..['softnessMode'] = 'feathered',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectShadowProfile(
          Map<String, Object?>.from(_minimalJson())
            ..['softnessMode'] = 'runtimeBlur',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects missing required fields', () {
      for (final key in <String>['id', 'name', 'mode', 'renderPass']) {
        expect(
          () => decodeProjectShadowProfile(_without(_minimalJson(), key)),
          throwsA(isA<ValidationException>()),
          reason: key,
        );
      }
    });

    test('rejects non-string string fields', () {
      for (final entry in <String, Object?>{
        'id': 123,
        'name': 123,
        'mode': 1,
        'renderPass': true,
        'colorHexRgb': 123,
        'softnessMode': false,
      }.entries) {
        expect(
          () => decodeProjectShadowProfile(
            Map<String, Object?>.from(_minimalJson())
              ..[entry.key] = entry.value,
          ),
          throwsA(isA<ValidationException>()),
          reason: entry.key,
        );
      }
    });

    test('rejects non-numeric numeric fields', () {
      for (final key in <String>[
        'offsetX',
        'offsetY',
        'scaleX',
        'scaleY',
        'opacity',
      ]) {
        expect(
          () => decodeProjectShadowProfile(
            Map<String, Object?>.from(_minimalJson())..[key] = '1',
          ),
          throwsA(isA<ValidationException>()),
          reason: key,
        );
      }
    });

    test('rejects values invalidated by the model', () {
      for (final invalid in <({String key, Object? value, String reason})>[
        (key: 'scaleX', value: 0, reason: 'scaleX zero'),
        (key: 'scaleY', value: 0, reason: 'scaleY zero'),
        (key: 'opacity', value: -0.01, reason: 'opacity low'),
        (key: 'opacity', value: 1.01, reason: 'opacity high'),
        (key: 'offsetX', value: double.nan, reason: 'offsetX NaN'),
        (key: 'offsetY', value: double.infinity, reason: 'offsetY infinity'),
        (key: 'scaleX', value: double.infinity, reason: 'scaleX infinity'),
        (
          key: 'scaleY',
          value: double.negativeInfinity,
          reason: 'scaleY negative infinity',
        ),
        (key: 'opacity', value: double.nan, reason: 'opacity NaN'),
      ]) {
        final json = Map<String, Object?>.from(_minimalJson());
        json[invalid.key] = invalid.value;
        expect(
          () => decodeProjectShadowProfile(json),
          throwsA(isA<ValidationException>()),
          reason: invalid.reason,
        );
      }
    });

    test('ignores unknown fields while encode emits only canonical fields', () {
      final profile = decodeProjectShadowProfile(
        Map<String, Object?>.from(_minimalJson())
          ..['runtimeBlur'] = true
          ..['blurRadius'] = 12,
      );

      final encoded = encodeProjectShadowProfile(profile);

      expect(profile.mode, ShadowCasterMode.contactBlob);
      expect(encoded.containsKey('runtimeBlur'), isFalse);
      expect(encoded.containsKey('blurRadius'), isFalse);
      expect(encoded.keys, [
        'id',
        'name',
        'mode',
        'renderPass',
        'offsetX',
        'offsetY',
        'scaleX',
        'scaleY',
        'opacity',
        'colorHexRgb',
        'softnessMode',
      ]);
    });

    test('rejects non-object JSON root', () {
      expect(
        () => decodeProjectShadowProfile(null),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectShadowProfile(<Object?>[]),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
