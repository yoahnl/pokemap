import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_source_program_converter.dart';
import 'package:test/test.dart';

const _revision = '41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c';
const _path = 'res/battle/animations/moves/example.s';
const _source = '''
#include "asm/btlv_effvm.inc"
ScriptHeader 1
ScriptVariant Example
Example:
  WaitFrames 2
  End
''';

Map<String, Object?> _convert(String source, {String variant = 'Example'}) {
  final bytes = utf8.encode(source);
  return Gen5SourceProgramConverter.convert(
    bytes,
    sourceRevision: _revision,
    sourcePath: _path,
    expectedSha256: sha256.convert(bytes).toString(),
    variant: variant,
  );
}

List<Map<String, Object?>> _instructions(Map<String, Object?> program) =>
    (program['instructions'] as List).cast<Map<String, Object?>>();

Map<String, Object?> _args(Map<String, Object?> instruction) =>
    instruction['args'] as Map<String, Object?>;

void main() {
  test('converts a source from stdin with explicit identity and entry',
      () async {
    final process = await Process.start('dart', [
      'run',
      'bin/gen5_source_program_converter.dart',
      '--revision',
      _revision,
      '--path',
      _path,
      '--sha256',
      sha256.convert(utf8.encode(_source)).toString(),
      '--variant',
      'Example',
    ]);
    final stdoutText = process.stdout.transform(utf8.decoder).join();
    final stderrText = process.stderr.transform(utf8.decoder).join();
    process.stdin.write(_source);
    await process.stdin.close();
    final code = await process.exitCode;
    final output = await stdoutText;
    final error = await stderrText;
    expect(code, 0, reason: error);
    final program = jsonDecode(output) as Map<String, dynamic>;
    expect(program['kind'], 'gen5SourceProgram');
    expect(program['timebaseHz'], 60);
    expect(program['variant'], 'Example');
    expect(program['entryIndex'], 0);
    expect((program['instructions'] as List).first['op'], 'waitFrames');
    expect((program['instructions'] as List).first['args']['frames'], 2);
  });

  test('retains all variants, internal labels, instructions and entry indices',
      () {
    const source = '''
#include "asm/btlv_effvm.inc"
ScriptHeader 2
ScriptVariant First
ScriptVariant Second
First:
  WaitFrames 0
Middle:
  WaitFrames 1
  End
Second:
  WaitFrames 2
  End
''';
    final program = _convert(source, variant: 'Second');
    expect(program['variants'], ['First', 'Second']);
    expect(program['labels'], [
      {'name': 'First', 'instructionIndex': 0, 'line': 5},
      {'name': 'Middle', 'instructionIndex': 1, 'line': 7},
      {'name': 'Second', 'instructionIndex': 3, 'line': 10},
    ]);
    expect(program['entryIndex'], 3);
    expect(_instructions(program).map((item) => item['op']), [
      'waitFrames',
      'waitFrames',
      'end',
      'waitFrames',
      'end',
    ]);
    expect(() => _convert(source, variant: ''), throwsFormatException);
    expect(() => _convert(source, variant: 'Middle'), throwsFormatException);
  });

  test('rejects a selected variant without its own terminal instruction', () {
    const source = '''
#include "asm/btlv_effvm.inc"
ScriptHeader 2
ScriptVariant First
ScriptVariant Second
First:
  End
Second:
  WaitFrames 2
''';
    final result = _convert(source, variant: 'Second');
    expect(result['conversion'], 'unsupported');
    expect((result['diagnostics'] as List).single['code'], 'missingVariantEnd');
  });

  test('retains unknown instructions and refuses unsupported modes', () {
    final unknown = _convert(_source.replaceFirst(
        'WaitFrames 2', 'FutureOpcode 0x2000, EFFVM_DEFENDER'));
    expect(unknown['conversion'], 'unsupported');
    expect(unknown['diagnostics'], [
      {'instructionIndex': 0, 'line': 5, 'code': 'unsupportedOpcode'},
    ]);
    final first = _instructions(unknown).first;
    expect(first['op'], 'unsupported');
    expect((first['source'] as Map)['operands'], ['0x2000', 'EFFVM_DEFENDER']);
    final mode = _convert(_source.replaceFirst('WaitFrames 2',
        'EmitterMove 220, 1, 2, EFFVM_EMIT_ATTACKER, EFFVM_EMIT_DEFENDER, 0x2000, 0x1e000, 0x800, 0x1000, 0x1000, 0x5000'));
    expect(mode['conversion'], 'unsupported');
    expect((_instructions(mode).first['source'] as Map)['operands'][2], '2');
    expect((mode['diagnostics'] as List).single['code'], 'unsupportedOperand');
  });

  test(
      'normalizes signed BW2 words and rejects values outside supported ranges',
      () {
    Map<String, Object?> convertInstruction(String instruction) =>
        _convert(_source.replaceFirst('WaitFrames 2', instruction));

    final move = convertInstruction(
        'McssMoveXY EFFVM_ATTACKER, 2, 0xffffffff, 0xfffff000, 4, 1, 1');
    expect(move['conversion'], 'supported');
    expect(_instructions(move).first['op'], 'moveCombatant');
    expect(_args(_instructions(move).first)['x'], -1);
    expect(_args(_instructions(move).first)['y'], -4096);
    expect((_instructions(move).first['source'] as Map)['operands'],
        ['EFFVM_ATTACKER', '2', '0xffffffff', '0xfffff000', '4', '1', '1']);

    final scale = convertInstruction(
        'McssScale EFFVM_DEFENDER, 2, 0xffffffff, 0x4cd, 2, 1, 1');
    expect(scale['conversion'], 'supported');
    expect(_instructions(scale).first['op'], 'scaleCombatant');
    expect(_args(_instructions(scale).first)['type'], 2);
    expect(_args(_instructions(scale).first)['x'], -1);
    expect(_args(_instructions(scale).first)['y'], 1229);

    final sound = convertInstruction(
        'PlaySE SEQ_SE_W055_01, 1, EFFVM_DEFENDER, 0, 0xffffffd4, 100, 0, 0, 0');
    expect(sound['conversion'], 'supported');
    expect(_args(_instructions(sound).first)['pitch'], -44);
    for (final instruction in [
      'McssMoveXY EFFVM_ATTACKER, 2, 0x80000000, 0, 4, 1, 1',
      'McssMoveXY EFFVM_ATTACKER, 2, 0x7fffffff, 0, 4, 1, 1',
      'McssMoveXY EFFVM_ATTACKER, 2, 0, 0, 0, 1, 1',
      'McssScale EFFVM_DEFENDER, 2, 0, 0, 2, -1, 1',
      'CameraMovePreset 1, 11, 16, -1, 8',
      'CameraMovePreset 1, 11, 16, 0, 0xffffffff',
      'McssPalFade EFFVM_DEFENDER, 0, 12, 2, 0xffffffff',
      'WaitFrames 0xffffffff',
    ]) {
      final result = convertInstruction(instruction);
      expect(result['conversion'], 'unsupported', reason: instruction);
      expect(_instructions(result).first['op'], 'unsupported',
          reason: instruction);
      expect(
          (result['diagnostics'] as List).single['code'], 'unsupportedOperand',
          reason: instruction);
    }
  });

  test('rejects invalid identity and unknown source revisions', () {
    final bytes = utf8.encode(_source);
    final hash = sha256.convert(bytes).toString();
    expect(
        () => Gen5SourceProgramConverter.convert(bytes,
            sourceRevision: _revision,
            sourcePath: _path,
            expectedSha256: '0' * 64,
            variant: 'Example'),
        throwsFormatException);
    expect(
        () => Gen5SourceProgramConverter.convert(bytes,
            sourceRevision: '0' * 40,
            sourcePath: _path,
            expectedSha256: hash,
            variant: 'Example'),
        throwsFormatException);
    expect(
        () => Gen5SourceProgramConverter.convert(bytes,
            sourceRevision: _revision,
            sourcePath: '../example.s',
            expectedSha256: hash,
            variant: 'Example'),
        throwsFormatException);
  });

  test(
      'transcribes the three pinned BW2 source documents without losing operands',
      () async {
    const sources = {
      'tackle': (
        'Tackle',
        '7e4efb20a66db06afb4611900c65796e60401d02cd49e5d9e7a35fa6e40d441c'
      ),
      'water_gun': (
        'WaterGun',
        '4187b971388a95c156e6341b338fc076651ef397b2d176a387e215238e102ec8'
      ),
      'surf': (
        'Surf',
        'ec244cfd636f2e70fdec6c24720ae9d776003cd63af77e7b43b3cc8b9f328a74'
      ),
    };
    final client = HttpClient();
    try {
      for (final entry in sources.entries) {
        final path = 'res/battle/animations/moves/${entry.key}.s';
        final request = await client.getUrl(Uri.https(
            'raw.githubusercontent.com',
            '/fuddlesworth/pokebw2/$_revision/$path'));
        request.followRedirects = false;
        final response =
            await request.close().timeout(const Duration(seconds: 20));
        expect(response.statusCode, 200);
        final bytes = await response
            .fold<List<int>>(<int>[], (data, chunk) => data..addAll(chunk));
        final program = Gen5SourceProgramConverter.convert(
            Uint8List.fromList(bytes),
            sourceRevision: _revision,
            sourcePath: path,
            expectedSha256: entry.value.$2,
            variant: entry.value.$1);
        expect(program['conversion'], 'supported',
            reason: '${entry.key}: ${program['diagnostics']}');
        final expected = <Map<String, Object>>[];
        for (final raw in const LineSplitter().convert(utf8.decode(bytes))) {
          final line = raw.split('//').first.trim();
          if (line.isEmpty ||
              line.startsWith('#') ||
              line.startsWith('.') ||
              line.endsWith(':') ||
              line.startsWith('ScriptHeader ') ||
              line.startsWith('ScriptVariant ')) {
            continue;
          }
          final match = RegExp(r'^([A-Za-z_][A-Za-z0-9_]*)(?:\s+(.*))?$')
              .firstMatch(line)!;
          expected.add({
            'name': match.group(1)!,
            'operands': match.group(2) == null
                ? <String>[]
                : match.group(2)!.split(',').map((s) => s.trim()).toList(),
          });
        }
        final actual = _instructions(program).map((item) {
          final source = item['source'] as Map;
          return {'name': source['name'], 'operands': source['operands']};
        }).toList();
        expect(actual, expected, reason: entry.key);
        if (entry.key == 'water_gun') {
          final moving = _instructions(program)
              .where((item) => item['op'] == 'startMovingEmitter')
              .toList();
          expect(moving, hasLength(15));
          expect(
              _instructions(program)
                  .where((item) => item['op'] == 'startEmitter'),
              hasLength(2));
          expect(moving.map((item) => (item['source'] as Map)['index']).toSet(),
              hasLength(15));
          expect(_args(moving.first)['motionFramesFx32'], 0x1e000);
          expect(_args(moving.first)['motionFrames'], 30);
          expect(
              (_instructions(program)
                  .where((item) => item['op'] == 'waitTasks')
                  .map(_args)
                  .map((args) => args['what'])),
              containsAll(['ALL', 'PARTICLES']));
        }
        if (entry.key == 'surf') {
          final emitters = _instructions(program)
              .where((item) => item['op'] == 'startEmitter')
              .map(_args)
              .toList();
          expect(emitters.map((args) => args['particle']), everyElement(222));
          expect(emitters.map((args) => args['emitter']), [3, 1, 4, 5, 2]);
          expect(emitters.map((args) => args['scaleScale']),
              [4096, 2867, 4096, 4096, 4096]);
        }
      }
    } finally {
      client.close(force: true);
    }
  },
      skip: Platform.environment['GEN5_TEST_PINNED_SOURCE_NETWORK'] != '1'
          ? 'Set GEN5_TEST_PINNED_SOURCE_NETWORK=1 to fetch the pinned public sources'
          : false);
}
