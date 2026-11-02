import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_battle_script_control_flow.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_battle_script_parameters.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_battle_script_source.dart';
import 'package:test/test.dart';

const _revision = '0123456789abcdef0123456789abcdef01234567';
const _path = 'res/battle/animations/moves/example.s';

Gen5BattleScriptSource _read(
  String source, {
  String revision = _revision,
  String path = _path,
  String? digest,
}) {
  final bytes = Uint8List.fromList(utf8.encode(source));
  return Gen5BattleScriptSource.read(
    bytes,
    sourceRevision: revision,
    sourcePath: path,
    expectedSha256: digest ?? sha256.convert(bytes).toString(),
  );
}

const _source = '''
#include "asm/btlv_effvm.inc"
ScriptHeader 1
ScriptVariant Example
Example:
  WaitFrames 3
  FutureCommand 0x2000, -7, EFFVM_DEFENDER // preserve unknown commands
  End
''';

void main() {
  test('preserves every instruction, operand, order and source identity', () {
    final parsed = _read(_source);
    expect(parsed.sourceRevision, _revision);
    expect(parsed.sourcePath, _path);
    expect(parsed.sha256Hex, sha256.convert(utf8.encode(_source)).toString());
    expect(parsed.variant, 'Example');
    expect(parsed.instructions.map((step) => step.name), [
      'WaitFrames',
      'FutureCommand',
      'End',
    ]);
    expect(parsed.instructions[0].arguments, ['3']);
    expect(parsed.instructions[1].arguments, [
      '0x2000',
      '-7',
      'EFFVM_DEFENDER',
    ]);
    expect(parsed.instructions[1].line, 6);
    expect(() => parsed.instructions.clear(), throwsUnsupportedError);
    expect(
        () => parsed.instructions[1].arguments.clear(), throwsUnsupportedError);
  });

  test('rejects altered content or unsafe source identity', () {
    expect(() => _read(_source, digest: '0' * 64), throwsFormatException);
    expect(() => _read(_source, revision: 'main'), throwsFormatException);
    expect(
      () => _read(_source, path: 'res/battle/animations/moves/../other.s'),
      throwsFormatException,
    );
    expect(() => _read(_source, path: '/tmp/example.s'), throwsFormatException);
  });

  test('rejects unsupported structure and incomplete scripts', () {
    final invalid = [
      _source.replaceFirst('ScriptHeader 1', 'ScriptHeader 2'),
      _source.replaceFirst('ScriptVariant Example', 'ScriptVariant Other'),
      _source.replaceFirst('Example:', 'Example:\nAnother:'),
      _source.replaceFirst('  End\n', ''),
      '$_source\nWaitFrames 2',
      _source.replaceFirst('WaitFrames 3', 'WaitFrames 1 + 2'),
      _source.replaceFirst('WaitFrames 3', 'WaitFrames 1,,2'),
      _source.replaceFirst('#include "asm/btlv_effvm.inc"', '#include "other"'),
      _source.replaceFirst('WaitFrames 3', '#define VALUE 3'),
      _source.replaceFirst('  End', '  End 1'),
    ];
    for (final source in invalid) {
      expect(() => _read(source), throwsFormatException, reason: source);
    }
  });

  test('accepts a single trailing four-byte assembler alignment', () {
    final parsed = _read('$_source  .balign 4\n');
    expect(parsed.instructions.map((item) => item.name), [
      'WaitFrames',
      'FutureCommand',
      'End',
    ]);
    for (final source in [
      '$_source  .balign 2\n',
      '$_source  .balign 4\n  .balign 4\n',
      '$_source  .balign 4\n  WaitFrames 1\n',
      _source.replaceFirst('  End', '  .balign 4\n  End'),
    ]) {
      expect(() => _read(source), throwsFormatException, reason: source);
    }
  });

  test('bounds input size and rejects invalid UTF-8', () {
    final oversized = ' ' * (64 * 1024 + 1);
    expect(() => _read(oversized), throwsFormatException);
    final longLine = _source.replaceFirst('WaitFrames 3', 'A' * 513);
    expect(() => _read(longLine), throwsFormatException);
    final tooManyInstructions = _source.replaceFirst(
      '  WaitFrames 3',
      '  WaitFrames 3\n' * 1025,
    );
    expect(() => _read(tooManyInstructions), throwsFormatException);
    final tooManyArguments = _source.replaceFirst(
      'WaitFrames 3',
      'FutureCommand ${List.filled(65, 'A').join(',')}',
    );
    expect(() => _read(tooManyArguments), throwsFormatException);
    final bytes = Uint8List.fromList([0xff]);
    expect(
      () => Gen5BattleScriptSource.read(
        bytes,
        sourceRevision: _revision,
        sourcePath: _path,
        expectedSha256: sha256.convert(bytes).toString(),
      ),
      throwsFormatException,
    );
  });

  test(
    'reads the pinned BW2 flamethrower script without dropping instructions',
    () async {
      const revision = '41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c';
      const path = 'res/battle/animations/moves/flamethrower.s';
      final client = HttpClient();
      try {
        final uri = Uri.https(
          'raw.githubusercontent.com',
          '/fuddlesworth/pokebw2/$revision/$path',
        );
        final request = await client.getUrl(uri).timeout(
              const Duration(seconds: 20),
            );
        request.followRedirects = false;
        final response = await request.close().timeout(
              const Duration(seconds: 20),
            );
        expect(response.statusCode, HttpStatus.ok);
        final builder = BytesBuilder(copy: false);
        await for (final chunk
            in response.timeout(const Duration(seconds: 20))) {
          if (builder.length + chunk.length > 64 * 1024) {
            throw const FormatException('Battle script exceeds test limit');
          }
          builder.add(chunk);
        }
        final parsed = Gen5BattleScriptSource.read(
          builder.takeBytes(),
          sourceRevision: revision,
          sourcePath: path,
          expectedSha256:
              '4cec7ed1fd757ee10d8e6f07941cefcd709cbaaac365ecf7782593a5dcc897f9',
        );
        expect(parsed.variant, 'Flamethrower');
        expect(parsed.instructions.length, 32);
        final parameters = Gen5BattleScriptParameters.read(parsed);
        expect(parameters.instructions.length, 32);
        final moveSe = parameters.instructions.singleWhere(
          (item) => item.instruction.name == 'MoveSE',
        );
        expect(
          (moveSe.parameters['start']! as Gen5BattleNumberOperand).signedWord,
          -3000,
        );
        final emitter = parameters.instructions.firstWhere(
          (item) => item.instruction.name == 'EmitterMove',
        );
        expect(
          (emitter.parameters['offsetY']! as Gen5BattleNumberOperand)
              .unsignedWord,
          8192,
        );
        expect(
          (emitter.parameters['from']! as Gen5BattleSymbolOperand).symbol,
          'EFFVM_EMIT_ATTACKER',
        );
        final blocks = Gen5BattleScriptControlFlow.analyze(parsed).blocks;
        expect(blocks.length, 21);
        expect(
          blocks.expand((block) => block.instructions),
          orderedEquals(parsed.instructions),
        );
        expect(
          blocks
              .where(
                (block) =>
                    block.boundary == Gen5BattleScriptBoundary.particleLoad,
              )
              .length,
          1,
        );
        expect(
          blocks
              .where(
                (block) =>
                    block.boundary == Gen5BattleScriptBoundary.waitFrames,
              )
              .length,
          2,
        );
        expect(
          blocks
              .where(
                (block) =>
                    block.boundary == Gen5BattleScriptBoundary.waitCondition,
              )
              .length,
          3,
        );
        expect(
          blocks
              .where(
                (block) =>
                    block.instructions.first.name == 'SetYield' &&
                    block.instructions.first.arguments.single == 'FALSE',
              )
              .map((block) => block.instructions.length),
          [7, 6],
        );
        for (final entry in {
          'PlaySE': 6,
          'EmitterMove': 2,
          'EmitterAdd': 2,
          'WaitFrames': 2,
          'Wait': 3,
          'End': 1,
        }.entries) {
          expect(
            parsed.instructions.where((item) => item.name == entry.key).length,
            entry.value,
          );
        }
      } finally {
        client.close(force: true);
      }
    },
    skip: Platform.environment['AVELUNE_BW2_SCRIPT_TEST'] == '1'
        ? false
        : 'Requires network access to the pinned source',
  );
}
