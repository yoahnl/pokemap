import 'package:map_distribution/map_distribution.dart';
import 'package:map_distribution/src/unicode_case_folding.dart';
import 'package:test/test.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

void main() {
  test('ASCII NFC normalization reuses its unchanged input', () {
    final value = String.fromCharCodes(
        'project/assets/a-lower-case-path-0123456789.json'.codeUnits);
    expect(identical(PackagePathPolicy.normalizeNfc(value), value), isTrue);
  });

  test('all ASCII characters and pairs retain NFC and collision keys', () {
    for (var first = 0; first < 128; first++) {
      final character = String.fromCharCode(first);
      expect(PackagePathPolicy.normalizeNfc(character), unorm.nfc(character));
      expect(PackagePathPolicy.collisionKey(character), _legacyKey(character));
      for (var second = 0; second < 128; second++) {
        final pair = String.fromCharCodes([first, second]);
        expect(PackagePathPolicy.normalizeNfc(pair), unorm.nfc(pair));
        expect(PackagePathPolicy.collisionKey(pair), _legacyKey(pair));
      }
    }
  });

  test('ASCII path validation preserves forbidden controls and separators', () {
    for (var unit = 0; unit < 128; unit++) {
      final path = 'project/a${String.fromCharCode(unit)}b.json';
      final forbidden =
          unit < 32 || unit == 127 || r'\<>:"|?*'.codeUnits.contains(unit);
      if (forbidden) {
        expect(
            () => PackagePathPolicy.validate(path, errorPath: 'path'),
            throwsA(isA<GamePackageFormatException>()
                .having((error) => error.code, 'code', 'invalidPackagePath')));
      } else {
        expect(() => PackagePathPolicy.validate(path, errorPath: 'path'),
            returnsNormally);
      }
    }
  });

  test('Unicode normalization and full folding keep the original behavior', () {
    final values = [
      'project/caf\u00e9.json',
      'project/cafe\u0301.json',
      'project/stra\u00dfe.json',
      'project/STRASSE.json',
      'project/\u03a3\u03c2\u03c3.json',
      'project/\u1f80.json',
      'project/\u0130.json',
      'project/i\u0307.json',
      'project/\u212a.json',
      'project/\u212b.json',
      'project/\u017f.json',
      'project/\ufb00\ufb13.json',
      'project/\u0345\u0301.json',
      'project/\u{10400}.json',
      'project/日本語.json',
      'project/\u{1f98a}.json',
      'project/a\u0000\u0301.json',
      'project/\ud800.json',
      'project/\udfff.json',
    ];
    for (final value in values) {
      expect(PackagePathPolicy.normalizeNfc(value), unorm.nfc(value));
      expect(PackagePathPolicy.collisionKey(value), _legacyKey(value));
    }
  });

  test('normalization does not relax traversal, reserved names or byte limits',
      () {
    for (final value in [
      '/project/a.json',
      'project/../a.json',
      'project/./a.json',
      'project//a.json',
      r'project\a.json',
      'project/CON.txt',
      'project/lpt9.json',
      'project/name.',
      'project/name ',
      'project/cafe\u0301.json',
      'project/\ud800.json',
      'project/${'a' * 256}',
      'project/${List.filled(32, 'a').join('/')}',
      'project/${'a' * 250}/${'b' * 250}/long-file.json',
    ]) {
      expect(
          () => PackagePathPolicy.validate(value, errorPath: 'path'),
          throwsA(isA<GamePackageFormatException>()
              .having((error) => error.code, 'code', 'invalidPackagePath')));
    }
    for (final value in [
      'project/caf\u00e9.json',
      'project/%2e%2e/file.json',
      'legal/notice.txt',
      'presentation/title.png'
    ]) {
      expect(() => PackagePathPolicy.validate(value, errorPath: 'path'),
          returnsNormally);
    }
  });
}

String _legacyKey(String value) =>
    unorm.nfc(UnicodeCaseFolding.fold(unorm.nfc(value)));
