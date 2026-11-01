import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_battle_script_parameters.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_battle_script_source.dart';
import 'package:test/test.dart';

Gen5BattleScriptSource _script(String body) {
  final bytes = Uint8List.fromList(
    utf8.encode('ScriptHeader 1\nScriptVariant Demo\nDemo:\n$body\n'),
  );
  return Gen5BattleScriptSource.read(
    bytes,
    sourceRevision: '0123456789abcdef0123456789abcdef01234567',
    sourcePath: 'res/battle/animations/moves/example.s',
    expectedSha256: sha256.convert(bytes).toString(),
  );
}

void main() {
  test('names operands while retaining signed words and unresolved symbols',
      () {
    final source = _script('''
SetYield FALSE
MoveSE 2, 0, 0, -3000, 0, 0, 60, 0, 0
EmitterMove 218, 0, 1, EFFVM_EMIT_ATTACKER, EFFVM_EMIT_DEFENDER, 0x2000, 0, 0, 0x1000, 0x1000, 0
SetYield TRUE
End''');
    final parsed = Gen5BattleScriptParameters.read(source);
    expect(parsed.source, same(source));
    expect(parsed.instructions.map((item) => item.instruction.name), [
      'SetYield',
      'MoveSE',
      'EmitterMove',
      'SetYield',
      'End',
    ]);
    final move = parsed.instructions[1].parameters;
    final start = move['start']! as Gen5BattleNumberOperand;
    expect(start.raw, '-3000');
    expect(start.unsignedWord, 4294964296);
    expect(start.signedWord, -3000);
    final emitter = parsed.instructions[2].parameters;
    expect((emitter['particle']! as Gen5BattleNumberOperand).unsignedWord, 218);
    expect((emitter['offsetY']! as Gen5BattleNumberOperand).unsignedWord, 8192);
    expect(
      (emitter['from']! as Gen5BattleSymbolOperand).symbol,
      'EFFVM_EMIT_ATTACKER',
    );
    expect(
      (emitter['to']! as Gen5BattleSymbolOperand).symbol,
      'EFFVM_EMIT_DEFENDER',
    );
    expect(() => emitter.clear(), throwsUnsupportedError);
    expect(() => parsed.instructions.clear(), throwsUnsupportedError);
  });

  test('retains unsigned 32-bit patterns and rejects overflow', () {
    final parsed = Gen5BattleScriptParameters.read(
      _script('McssPalFade EFFVM_DEFENDER, 0, 0, 1, 0xffffffff\nEnd'),
    );
    final color = parsed.instructions.first.parameters['color']!
        as Gen5BattleNumberOperand;
    expect(color.unsignedWord, 4294967295);
    expect(color.signedWord, -1);
    for (final literal in ['4294967296', '-2147483649', '0x100000000']) {
      expect(
        () => Gen5BattleScriptParameters.read(
          _script('McssPalFade EFFVM_DEFENDER, 0, 0, 1, $literal\nEnd'),
        ),
        throwsFormatException,
        reason: literal,
      );
    }
  });

  test('does not parameterize commands with unknown semantics or arity', () {
    for (final body in [
      'FutureCommand 1\nEnd',
      'EmitterMove 218, 0\nEnd',
      'Wait EFFVM_WAIT_UNKNOWN\nEnd',
    ]) {
      expect(
        () => Gen5BattleScriptParameters.read(_script(body)),
        throwsFormatException,
        reason: body,
      );
    }
  });
}
