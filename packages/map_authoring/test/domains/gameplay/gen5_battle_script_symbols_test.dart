import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_battle_script_parameters.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_battle_script_source.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_battle_script_symbols.dart';
import 'package:test/test.dart';

const _revision = '41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c';

Gen5BattleScriptParameters _script(String body, {String revision = _revision}) {
  final bytes = Uint8List.fromList(
    utf8.encode('ScriptHeader 1\nScriptVariant Demo\nDemo:\n$body\n'),
  );
  return Gen5BattleScriptParameters.read(
    Gen5BattleScriptSource.read(
      bytes,
      sourceRevision: revision,
      sourcePath: 'res/battle/animations/moves/example.s',
      expectedSha256: sha256.convert(bytes).toString(),
    ),
  );
}

void main() {
  test('resolves pinned constants and keeps sound symbols unresolved', () {
    final parameters = _script('''
SetYield FALSE
PlaySE SEQ_EXAMPLE, 1, EFFVM_ATTACKER, 0, 0, 100, 0, 0, 0
EmitterMove 218, 0, 1, EFFVM_EMIT_ATTACKER, EFFVM_EMIT_DEFENDER, 0x2000, 0, 0, 0x1000, 0x1000, 0
SetYield TRUE
Wait EFFVM_WAIT_ALL
End''');
    final result = Gen5BattleScriptSymbols.resolve(parameters);
    expect(result.resolvedSymbols, {
      'FALSE': 0,
      'TRUE': 1,
      'EFFVM_ATTACKER': 14,
      'EFFVM_EMIT_ATTACKER': 9,
      'EFFVM_EMIT_DEFENDER': 11,
      'EFFVM_WAIT_ALL': 0,
    });
    expect(result.unresolvedSymbols, {'SEQ_EXAMPLE'});
    expect(result.allSymbolsResolved, isFalse);
    expect(result.requireAllSymbolsResolved, throwsFormatException);
    expect(() => result.resolvedSymbols.clear(), throwsUnsupportedError);
    expect(() => result.unresolvedSymbols.clear(), throwsUnsupportedError);
  });

  test('accepts fully resolved constants without claiming an executable recipe',
      () {
    final result = Gen5BattleScriptSymbols.resolve(
      _script('SetYield FALSE\nSetYield TRUE\nWait EFFVM_WAIT_ALL\nEnd'),
    );
    expect(result.allSymbolsResolved, isTrue);
    expect(result.requireAllSymbolsResolved, returnsNormally);
  });

  test('rejects an unrecognized declared source revision', () {
    final parameters = _script(
      'End',
      revision: '0123456789abcdef0123456789abcdef01234567',
    );
    expect(
      () => Gen5BattleScriptSymbols.resolve(parameters),
      throwsFormatException,
    );
  });

  test(
    'finds the five unresolved sound cues in the pinned BW2 script',
    () async {
      const path = 'res/battle/animations/moves/flamethrower.s';
      final client = HttpClient();
      try {
        final request = await client
            .getUrl(Uri.https(
              'raw.githubusercontent.com',
              '/fuddlesworth/pokebw2/$_revision/$path',
            ))
            .timeout(const Duration(seconds: 20));
        request.followRedirects = false;
        final response =
            await request.close().timeout(const Duration(seconds: 20));
        expect(response.statusCode, HttpStatus.ok);
        final builder = BytesBuilder(copy: false);
        await for (final chunk
            in response.timeout(const Duration(seconds: 20))) {
          if (builder.length + chunk.length > 64 * 1024) {
            throw const FormatException('Battle script exceeds test limit');
          }
          builder.add(chunk);
        }
        final source = Gen5BattleScriptSource.read(
          builder.takeBytes(),
          sourceRevision: _revision,
          sourcePath: path,
          expectedSha256:
              '4cec7ed1fd757ee10d8e6f07941cefcd709cbaaac365ecf7782593a5dcc897f9',
        );
        final result = Gen5BattleScriptSymbols.resolve(
          Gen5BattleScriptParameters.read(source),
        );
        expect(result.unresolvedSymbols, {
          'SEQ_SE_BE_SE_016',
          'SEQ_SE_W001_01',
          'SEQ_SE_W027_01',
          'SEQ_SE_W307_01',
          'SEQ_SE_W307_02',
        });
        expect(result.resolvedSymbols['EFFVM_DEFENDER'], 16);
        expect(result.resolvedSymbols['EFFVM_EMIT_ATTACKER'], 9);
        expect(result.resolvedSymbols['EFFVM_EMIT_DEFENDER'], 11);
        expect(result.allSymbolsResolved, isFalse);
      } finally {
        client.close(force: true);
      }
    },
    skip: Platform.environment['AVELUNE_BW2_SCRIPT_TEST'] == '1'
        ? false
        : 'Requires network access to the pinned source',
  );
}
