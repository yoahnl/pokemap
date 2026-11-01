import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

import '../../../tools/gen5_battle_sprite/source_assets.dart';

void main() {
  Map<String, Object?> document() {
    final bytes = utf8.encode('synthetic');
    return {
      'format': 'gen5-battle-source-v1',
      'game': 'black2-white2',
      'scope': 'default-form',
      'species': 'pikachu',
      'nationalDex': 25,
      'assets': {
        for (final name in gen5BattleSourceAssetNames)
          name: {
            'encoding': 'base64',
            'size': bytes.length,
            'sha256': sha256.convert(bytes).toString(),
            'data': base64.encode(bytes),
          },
      },
    };
  }

  test('verifies the complete immutable source bytes', () {
    final result = verifyGen5SourceAssets(document());
    expect(result.keys.toSet(), gen5BattleSourceAssetNames.toSet());
    expect(utf8.decode(result['front.png']!), 'synthetic');
  });

  test('rejects a missing member and a digest mismatch', () {
    final missing = document();
    (missing['assets'] as Map).remove('front_info.bin');
    expect(() => verifyGen5SourceAssets(missing), throwsFormatException);
    final corrupt = document();
    ((corrupt['assets'] as Map)['front.png'] as Map)['sha256'] = '0' * 64;
    expect(() => verifyGen5SourceAssets(corrupt), throwsFormatException);
  });

  test('rejects a mismatched length and noncanonical base64', () {
    final wrongSize = document();
    ((wrongSize['assets'] as Map)['normal.pal'] as Map)['size'] = 1000001;
    expect(() => verifyGen5SourceAssets(wrongSize), throwsFormatException);
    final badBase64 = document();
    ((badBase64['assets'] as Map)['normal.pal'] as Map)['data'] =
        'c3ludGhldGlj\n';
    expect(() => verifyGen5SourceAssets(badBase64), throwsFormatException);
  });

  test('rejects unsupported identity and oversized metadata', () {
    final unsupported = document()..['nationalDex'] = 650;
    expect(() => verifyGen5SourceAssets(unsupported), throwsFormatException);
    final oversized = document();
    ((oversized['assets'] as Map)['front.png'] as Map)['size'] = 1048577;
    expect(() => verifyGen5SourceAssets(oversized), throwsFormatException);
  });
}
