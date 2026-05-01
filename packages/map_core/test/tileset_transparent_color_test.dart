import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('TilesetTransparentColor construction', () {
    test('accepts RGB components in the 0..255 range', () {
      final color = TilesetTransparentColor(red: 240, green: 91, blue: 161);

      expect(color.red, 240);
      expect(color.green, 91);
      expect(color.blue, 161);
    });

    test('rejects RGB components outside the 0..255 range', () {
      expect(
        () => TilesetTransparentColor(red: -1, green: 91, blue: 161),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => TilesetTransparentColor(red: 256, green: 91, blue: 161),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => TilesetTransparentColor(red: 240, green: -1, blue: 161),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => TilesetTransparentColor(red: 240, green: 256, blue: 161),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => TilesetTransparentColor(red: 240, green: 91, blue: -1),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => TilesetTransparentColor(red: 240, green: 91, blue: 256),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('TilesetTransparentColor hex parsing', () {
    test('accepts lowercase, uppercase, and optional # RGB values', () {
      for (final value in ['f05ba1', 'F05BA1', '#f05ba1', '#F05BA1']) {
        final color = TilesetTransparentColor.fromHexRgb(value);

        expect(color.red, 240);
        expect(color.green, 91);
        expect(color.blue, 161);
      }
    });

    test('returns canonical lowercase RGB without # and with padding', () {
      expect(
        TilesetTransparentColor.fromHexRgb('#F05BA1').toHexRgb(),
        'f05ba1',
      );
      expect(
        TilesetTransparentColor(red: 0, green: 0, blue: 255).toHexRgb(),
        '0000ff',
      );
    });

    test('rejects invalid hex RGB strings', () {
      for (final value in [
        '',
        '#',
        'f05ba',
        'f05ba11',
        'gggggg',
        '#gggggg',
        'f05ba1ff',
        '0xF05BA1',
      ]) {
        expect(
          () => TilesetTransparentColor.fromHexRgb(value),
          throwsA(isA<ArgumentError>()),
          reason: value,
        );
      }
    });
  });

  group('TilesetTransparentColor matching', () {
    test('matches RGB components exactly', () {
      final color = TilesetTransparentColor.fromHexRgb('f05ba1');

      expect(color.matchesRgb(red: 240, green: 91, blue: 161), isTrue);
      expect(color.matchesRgb(red: 240, green: 91, blue: 160), isFalse);
    });

    test('matches ARGB 32-bit values while ignoring alpha', () {
      final color = TilesetTransparentColor.fromHexRgb('f05ba1');

      expect(color.matchesArgb32(0xFFF05BA1), isTrue);
      expect(color.matchesArgb32(0x00F05BA1), isTrue);
      expect(color.matchesArgb32(0x80F05BA1), isTrue);
      expect(color.matchesArgb32(0xFF0000FF), isFalse);
    });
  });

  group('TilesetTransparentColor equality', () {
    test('uses value equality and stable hashCode', () {
      final a = TilesetTransparentColor.fromHexRgb('f05ba1');
      final b = TilesetTransparentColor.fromHexRgb('#F05BA1');
      final c = TilesetTransparentColor(red: 0, green: 0, blue: 255);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('ProjectTilesetEntry transparentColor', () {
    test('serializes transparent color as lowercase hex RGB', () {
      final entry = ProjectTilesetEntry(
        id: 'tech_nature_animations',
        name: 'TECH-Nature-animations',
        relativePath: 'tilesets/tech.png',
        transparentColor: TilesetTransparentColor.fromHexRgb('#F05BA1'),
      );

      expect(entry.toJson()['transparentColor'], 'f05ba1');
    });

    test('deserializes transparent color from hex RGB', () {
      final entry = ProjectTilesetEntry.fromJson({
        'id': 'tech_nature_animations',
        'name': 'TECH-Nature-animations',
        'relativePath': 'tilesets/tech.png',
        'transparentColor': 'f05ba1',
      });

      expect(
        entry.transparentColor,
        TilesetTransparentColor.fromHexRgb('f05ba1'),
      );
    });
  });
}
