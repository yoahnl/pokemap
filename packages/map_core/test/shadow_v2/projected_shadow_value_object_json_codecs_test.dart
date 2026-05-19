import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectedShadowDirection JSON codec', () {
    test('encodes the canonical x/y object', () {
      final direction = ProjectedShadowDirection(x: -0.55, y: 0.35);

      expect(
        encodeProjectedShadowDirection(direction),
        <String, Object?>{'x': -0.55, 'y': 0.35},
      );
    });

    test('decodes the canonical x/y object and ignores unknown keys', () {
      final direction = decodeProjectedShadowDirection(<String, Object?>{
        'x': -0.55,
        'y': 0.35,
        'debug': true,
      });

      expect(direction, ProjectedShadowDirection(x: -0.55, y: 0.35));
      expect(
        encodeProjectedShadowDirection(direction),
        <String, Object?>{'x': -0.55, 'y': 0.35},
      );
    });

    test('round-trips through the canonical object', () {
      final encoded = encodeProjectedShadowDirection(
        ProjectedShadowDirection(x: -0.55, y: 0.35),
      );

      expect(
        encodeProjectedShadowDirection(
          decodeProjectedShadowDirection(encoded),
        ),
        encoded,
      );
    });

    test('rejects invalid JSON shape and required fields', () {
      expect(
        () => decodeProjectedShadowDirection(null),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowDirection(<String, Object?>{'y': 0.35}),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowDirection(<String, Object?>{'x': -0.55}),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowDirection(<String, Object?>{
          'x': 'west',
          'y': 0.35,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowDirection(<String, Object?>{'x': 0, 'y': 0}),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('ProjectedShadowAnchor JSON codec', () {
    test('encodes the canonical xRatio/yRatio object', () {
      final anchor = ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.98);

      expect(
        encodeProjectedShadowAnchor(anchor),
        <String, Object?>{'xRatio': 0.5, 'yRatio': 0.98},
      );
    });

    test('decodes the canonical ratio object and ignores unknown keys', () {
      final anchor = decodeProjectedShadowAnchor(<String, Object?>{
        'xRatio': 0.5,
        'yRatio': 0.98,
        'editorLabel': 'south door',
      });

      expect(anchor, ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.98));
      expect(
        encodeProjectedShadowAnchor(anchor),
        <String, Object?>{'xRatio': 0.5, 'yRatio': 0.98},
      );
    });

    test('round-trips through the canonical object', () {
      final encoded = encodeProjectedShadowAnchor(
        ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.98),
      );

      expect(
        encodeProjectedShadowAnchor(decodeProjectedShadowAnchor(encoded)),
        encoded,
      );
    });

    test('rejects missing fields and invalid ratios', () {
      expect(
        () => decodeProjectedShadowAnchor(<String, Object?>{'yRatio': 0.98}),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowAnchor(<String, Object?>{'xRatio': 0.5}),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowAnchor(<String, Object?>{
          'xRatio': 1.01,
          'yRatio': 0.98,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowAnchor(<String, Object?>{
          'xRatio': 0.5,
          'yRatio': 'bottom',
        }),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('ProjectedShadowOffset JSON codec', () {
    test('encodes the canonical x/y object', () {
      final offset = ProjectedShadowOffset(x: 0, y: -2.5);

      expect(
        encodeProjectedShadowOffset(offset),
        <String, Object?>{'x': 0, 'y': -2.5},
      );
    });

    test(
        'decodes positive, zero, and negative offsets with unknown keys ignored',
        () {
      final offset = decodeProjectedShadowOffset(<String, Object?>{
        'x': 3.25,
        'y': -2.5,
        'note': 'local tweak',
      });

      expect(offset, ProjectedShadowOffset(x: 3.25, y: -2.5));
      expect(
        encodeProjectedShadowOffset(offset),
        <String, Object?>{'x': 3.25, 'y': -2.5},
      );
    });

    test('round-trips through the canonical object', () {
      final encoded = encodeProjectedShadowOffset(
        ProjectedShadowOffset(x: 0, y: -2.5),
      );

      expect(
        encodeProjectedShadowOffset(decodeProjectedShadowOffset(encoded)),
        encoded,
      );
    });

    test('rejects missing and non-numeric coordinates', () {
      expect(
        () => decodeProjectedShadowOffset(<String, Object?>{'y': -2.5}),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowOffset(<String, Object?>{'x': 0}),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowOffset(<String, Object?>{
          'x': 0,
          'y': double.infinity,
        }),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('ProjectedShadowShapeTuning JSON codec', () {
    test('encodes the canonical shape object', () {
      final shape = ProjectedShadowShapeTuning(
        lengthRatio: 0.28,
        nearWidthRatio: 0.85,
        farWidthRatio: 0.75,
      );

      expect(
        encodeProjectedShadowShapeTuning(shape),
        <String, Object?>{
          'lengthRatio': 0.28,
          'nearWidthRatio': 0.85,
          'farWidthRatio': 0.75,
        },
      );
    });

    test('decodes the canonical shape object and ignores unknown keys', () {
      final shape = decodeProjectedShadowShapeTuning(<String, Object?>{
        'lengthRatio': 0.28,
        'nearWidthRatio': 0.85,
        'farWidthRatio': 0.75,
        'legacyWidth': 12,
      });

      expect(
        shape,
        ProjectedShadowShapeTuning(
          lengthRatio: 0.28,
          nearWidthRatio: 0.85,
          farWidthRatio: 0.75,
        ),
      );
      expect(
        encodeProjectedShadowShapeTuning(shape),
        <String, Object?>{
          'lengthRatio': 0.28,
          'nearWidthRatio': 0.85,
          'farWidthRatio': 0.75,
        },
      );
    });

    test('round-trips through the canonical object', () {
      final encoded = encodeProjectedShadowShapeTuning(
        ProjectedShadowShapeTuning(
          lengthRatio: 0.28,
          nearWidthRatio: 0.85,
          farWidthRatio: 0.75,
        ),
      );

      expect(
        encodeProjectedShadowShapeTuning(
          decodeProjectedShadowShapeTuning(encoded),
        ),
        encoded,
      );
    });

    test('rejects missing fields and invalid ratios', () {
      expect(
        () => decodeProjectedShadowShapeTuning(<String, Object?>{
          'nearWidthRatio': 0.85,
          'farWidthRatio': 0.75,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowShapeTuning(<String, Object?>{
          'lengthRatio': 0.28,
          'farWidthRatio': 0.75,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowShapeTuning(<String, Object?>{
          'lengthRatio': 0.28,
          'nearWidthRatio': 0.85,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowShapeTuning(<String, Object?>{
          'lengthRatio': -0.01,
          'nearWidthRatio': 0.85,
          'farWidthRatio': 0.75,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowShapeTuning(<String, Object?>{
          'lengthRatio': 0.28,
          'nearWidthRatio': 0,
          'farWidthRatio': 0.75,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowShapeTuning(<String, Object?>{
          'lengthRatio': 0.28,
          'nearWidthRatio': 0.85,
          'farWidthRatio': 'wide',
        }),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('ProjectedShadowAppearance JSON codec', () {
    test('encodes the canonical appearance object with uppercase color', () {
      final appearance = ProjectedShadowAppearance(
        opacity: 0.18,
        colorHexRgb: 'abcdef',
      );

      expect(
        encodeProjectedShadowAppearance(appearance),
        <String, Object?>{'opacity': 0.18, 'colorHexRgb': 'ABCDEF'},
      );
    });

    test('decodes the canonical appearance object and ignores unknown keys',
        () {
      final appearance = decodeProjectedShadowAppearance(<String, Object?>{
        'opacity': 0.18,
        'colorHexRgb': '000000',
        'debugColorName': 'soft black',
      });

      expect(
        appearance,
        ProjectedShadowAppearance(opacity: 0.18, colorHexRgb: '000000'),
      );
      expect(
        encodeProjectedShadowAppearance(appearance),
        <String, Object?>{'opacity': 0.18, 'colorHexRgb': '000000'},
      );
    });

    test('round-trips lowercase color as uppercase', () {
      final appearance = decodeProjectedShadowAppearance(<String, Object?>{
        'opacity': 0.18,
        'colorHexRgb': 'abcdef',
      });

      expect(appearance.colorHexRgb, 'ABCDEF');
      expect(
        encodeProjectedShadowAppearance(appearance),
        <String, Object?>{'opacity': 0.18, 'colorHexRgb': 'ABCDEF'},
      );
    });

    test('accepts opacity boundaries', () {
      expect(
        decodeProjectedShadowAppearance(<String, Object?>{
          'opacity': 0,
          'colorHexRgb': '000000',
        }).opacity,
        0,
      );
      expect(
        decodeProjectedShadowAppearance(<String, Object?>{
          'opacity': 1,
          'colorHexRgb': 'FFFFFF',
        }).opacity,
        1,
      );
    });

    test('rejects missing fields and invalid appearance values', () {
      expect(
        () => decodeProjectedShadowAppearance(<String, Object?>{
          'colorHexRgb': '000000',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowAppearance(<String, Object?>{
          'opacity': 0.18,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowAppearance(<String, Object?>{
          'opacity': -0.01,
          'colorHexRgb': '000000',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowAppearance(<String, Object?>{
          'opacity': 1.01,
          'colorHexRgb': '000000',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowAppearance(<String, Object?>{
          'opacity': 0.18,
          'colorHexRgb': '00000',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowAppearance(<String, Object?>{
          'opacity': 0.18,
          'colorHexRgb': 0,
        }),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('ProjectedShadowTimeOfDayMode JSON codec', () {
    test('encodes fixed and followsSun', () {
      expect(
        encodeProjectedShadowTimeOfDayMode(ProjectedShadowTimeOfDayMode.fixed),
        'fixed',
      );
      expect(
        encodeProjectedShadowTimeOfDayMode(
          ProjectedShadowTimeOfDayMode.followsSun,
        ),
        'followsSun',
      );
    });

    test('decodes fixed and followsSun', () {
      expect(
        decodeProjectedShadowTimeOfDayMode('fixed'),
        ProjectedShadowTimeOfDayMode.fixed,
      );
      expect(
        decodeProjectedShadowTimeOfDayMode('followsSun'),
        ProjectedShadowTimeOfDayMode.followsSun,
      );
    });

    test('rejects unknown, non-string, and wrongly-cased values', () {
      expect(
        () => decodeProjectedShadowTimeOfDayMode('moonlight'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowTimeOfDayMode(0),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowTimeOfDayMode('FollowsSun'),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
