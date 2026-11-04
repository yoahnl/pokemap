import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_source_program_converter.dart';
import 'package:test/test.dart';

import '../../../tool/gen5_source_workshop_batch.dart' as workshop;

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
  test('transcribes source gauge movement for a single combatant', () {
    final program = _convert(_source.replaceFirst('WaitFrames 2', 'Gauge 2, 4'));
    expect(program['conversion'], 'supported');
    expect(_instructions(program).first['op'], 'setSourceGauge');
    expect(_args(_instructions(program).first), {'mode': 2, 'target': 4});
    expect(workshop.admitted(_instructions(program)), isTrue);
    final unsafe = _convert(_source.replaceFirst('WaitFrames 2', 'Gauge 4, 4'));
    expect(unsafe['conversion'], isNot('supported'));
  });

  test('transcribes simultaneous source motions down to zero scale', () {
    final source = _source.replaceFirst('WaitFrames 2', '''
  McssScale EFFVM_ALL, 2, -0x1000, -0x1000, 1, 0, 40
  McssMoveXY EFFVM_ALL, 2, 0x800, 0, 60, 0, 1''');
    final program = _convert(source);
    expect(program['conversion'], 'supported');
    expect(workshop.admitted(_instructions(program)), isTrue);
    final unsafe = _convert(source.replaceFirst('-0x1000, -0x1000', '-0x1001, -0x1000'));
    expect(unsafe['conversion'], isNot('supported'));
  });

  test('transcribes moving orthographic emitters with their source trajectory', () {
    final program = _convert(_source.replaceFirst('WaitFrames 2',
        'EmitterMoveOrtho 238, 2, 2, EFFVM_EMIT_ATTACKER, EFFVM_EMIT_DEFENDER, 0x2000, 0x2d000, 0x4000, 0x1000, 0x1000, 0'));
    expect(program['conversion'], 'supported');
    final instruction = _instructions(program).first;
    expect(instruction['op'], 'startMovingOrthoEmitter');
    expect(_args(instruction)['motion'], 2);
    expect(_args(instruction)['motionFrames'], 45);
    expect(_args(instruction)['height'], 0x4000);
    expect(workshop.admitted(_instructions(program)), isTrue);
  });

  test('transcribes bounded BW2 orbiting emitters', () {
    for (final type in [2, 3]) {
      final program = _convert(_source.replaceFirst('WaitFrames 2',
          'OrbitEmitters 711, 2, $type, 0x2000, 0x1800, -0x1000, 120, 1, 3, 2'));
      expect(program['conversion'], 'supported');
      final instruction = _instructions(program).first;
      expect(instruction['op'], 'startOrbitEmitter');
      expect(_args(instruction), {
        'particle': 711, 'emitter': 2, 'type': type,
        'radiusX': 8192, 'radiusZ': 6144, 'offsetY': -4096,
        'frames': 120, 'wait': 1, 'unknown': 3, 'delay': 2,
      });
      expect(workshop.admitted(_instructions(program)), isTrue);
    }
    for (final command in [
      'OrbitEmitters 711, 2, 2, 0x2000, 0x1800, 0, 0, 0, 3, 0',
      'OrbitEmitters 711, 2, 4, 0x2000, 0x1800, 0, 120, 0, 3, 0',
    ]) {
      expect(_convert(_source.replaceFirst('WaitFrames 2', command))['conversion'],
          isNot('supported'));
    }
  });

  test('preserves absolute BW2 camera moves separately from relative moves', () {
    final program = _convert(_source.replaceFirst('WaitFrames 2',
        'CameraMove 1, 0xca6, 0x5f33, 0x1dcc3, -0xe8d, 0xad9a, 0x27f6, 32, 0, 26'));
    expect(program['conversion'], 'supported');
    final instruction = _instructions(program).first;
    expect(instruction['op'], 'moveCameraAbsolute');
    expect(_args(instruction)['x'], 0xca6);
    expect(_args(instruction)['targetY'], 0xad9a);
    expect(workshop.admitted(_instructions(program)), isTrue);
  });

  test('preserves the field origin and target of a moving emitter', () {
    final program = _convert(_source.replaceFirst('WaitFrames 2',
        'EmitterMoveFrom 418, 3, 1, 0, 0x2000, 0, EFFVM_EMIT_DEFENDER, 0x2000, 0x14000, 0, 0x1000, 0x1000, 0'));
    expect(program['conversion'], 'supported');
    final instruction = _instructions(program).first;
    expect(instruction['op'], 'startMovingFieldEmitter');
    expect(_args(instruction), containsPair('fromY', 0x2000));
    expect(_args(instruction), containsPair('to', 'EFFVM_EMIT_DEFENDER'));
    expect(_args(instruction), containsPair('motionFrames', 20));
    expect(workshop.admitted(_instructions(program)), isTrue);
  });

  test('preserves the source camera mode used by flat actors', () {
    final program = _convert(_source.replaceFirst('WaitFrames 2', 'McssCameraMode 0, 0'));
    expect(program['conversion'], 'supported');
    expect(_instructions(program).first['op'], 'setActorCameraMode');
    expect(_args(_instructions(program).first), {'mode': 0, 'scope': 0});
    expect(workshop.admitted(_instructions(program)), isTrue);
    final unsupported = _convert(_source.replaceFirst('WaitFrames 2', 'McssCameraMode 1, 1'));
    expect(unsupported['conversion'], isNot('supported'));
  });

  test('preserves particle deletion in the source program', () {
    final program = _convert(_source.replaceFirst('WaitFrames 2',
        'ParticleLoad 511\n  ParticleDelete 511'));
    expect(program['conversion'], 'supported');
    expect(_instructions(program)[1]['op'], 'deleteParticle');
    expect(_args(_instructions(program)[1])['particle'], 511);
    expect(workshop.admitted(_instructions(program)), isTrue);
  });

  test('preserves source pan oscillation and panning controls', () {
    for (final source in [
      'PanSE 1, 1, EFFVM_ATTACKER, EFFVM_DEFENDER, 0, 50, 0, 0',
      'MoveSE 1, 0, 2, -128, 127, 90, 25, 0, 0',
    ]) {
      final program = _convert(_source.replaceFirst('WaitFrames 2', source));
      expect(program['conversion'], 'supported', reason: source);
      expect(workshop.admitted(_instructions(program)), isTrue, reason: source);
    }
    final invalid = _convert(_source.replaceFirst('WaitFrames 2',
        'MoveSE 1, 0, 2, -129, 127, 90, 25, 0, 0'));
    expect(invalid['conversion'], isNot('supported'));
  });

  test('admits up to 32 source emitter invocations for the workshop', () async {
    const command = '  EmitterAdd 218, 0, EFFVM_EMIT_ATTACKER, EFFVM_EMIT_DEFENDER, 0, 0, 0, 0x1000, 0x1000, 0x1000, 0x1000';
    const directory = '../../tools/avelune_attack_comparator/assets/bw2/particle218';
    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    for (final count in [27, 32, 33]) {
      final source = _source.replaceFirst('  WaitFrames 2', List.filled(count, command).join('\n'));
      final bytes = utf8.encode(source);
      final document = {
        'move': {'id': 'repeated-emitters', 'sourceId': 1},
        'source': {'revision': _revision},
        'script': {'path': _path, 'sha256': sha256.convert(bytes).toString(),
          'data': base64Encode(bytes)},
      };
      final result = await workshop.convert(document, {'names': []}, client,
          fetchResource: (path, limit) async {
        if (path.endsWith('particles.json')) {
          return File('$directory/source.json').readAsBytes();
        }
        final name = path.split('/').last.replaceFirst('.png', '.b64');
        return base64Decode((await File('$directory/$name').readAsString()).trim());
      });
      expect(result != null, count <= 32, reason: '$count invocations');
    }
  });

  test('flags source scaling that exceeds the workshop particle size limit', () async {
    final source = _source.replaceFirst('WaitFrames 2',
        'EmitterAdd 218, 0, EFFVM_EMIT_ATTACKER, EFFVM_EMIT_DEFENDER, 0, 0, 0, 0x1000, 0x1000, 0x2000, 0x1000');
    final bytes = utf8.encode(source);
    final document = {
      'move': {'id': 'scaled-particle', 'sourceId': 1},
      'source': {'revision': _revision},
      'script': {
        'path': _path,
        'sha256': sha256.convert(bytes).toString(),
        'data': base64Encode(bytes),
      },
    };
    const directory = '../../tools/avelune_attack_comparator/assets/bw2/particle218';
    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    final result = await workshop.convert(document, {'names': []}, client,
        fetchResource: (path, limit) async {
      if (path.endsWith('particles.json')) {
        final json = jsonDecode(await File('$directory/source.json').readAsString()) as Map;
        ((json['emitters'] as List).first as Map)['baseScale'] = 20000;
        return Uint8List.fromList(utf8.encode(jsonEncode(json)));
      }
      final name = path.split('/').last.replaceFirst('.png', '.b64');
      return base64Decode((await File('$directory/$name').readAsString()).trim());
    });
    expect(result, isNotNull);
    expect(result!['approximations'], contains('source-emitter:scaled-size-clamped'));
  });

  test('bakes the BW2 texture wrapping during workshop conversion', () async {
    final source = _source.replaceFirst('WaitFrames 2',
        'EmitterAdd 218, 0, EFFVM_EMIT_ATTACKER, EFFVM_EMIT_DEFENDER, 0, 0, 0, 0x1000, 0x1000, 0x1000, 0x1000');
    final bytes = utf8.encode(source);
    final document = {
      'move': {'id': 'wrapped-texture', 'sourceId': 1},
      'source': {'revision': _revision},
      'script': {
        'path': _path,
        'sha256': sha256.convert(bytes).toString(),
        'data': base64Encode(bytes),
      },
    };
    const directory = '../../tools/avelune_attack_comparator/assets/bw2/particle218';
    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    final result = await workshop.convert(document, {'names': []}, client,
        fetchResource: (path, limit) async {
      if (path.endsWith('particles.json')) {
        final json = jsonDecode(await File('$directory/source.json').readAsString()) as Map;
        for (final texture in (json['textures'] as List).cast<Map>()) {
          texture['repeat'] = 't';
          texture['flip'] = 't';
        }
        ((json['emitters'] as List).first as Map)['textureRepeatShiftT'] = 1;
        return Uint8List.fromList(utf8.encode(jsonEncode(json)));
      }
      final name = path.split('/').last.replaceFirst('.png', '.b64');
      return base64Decode((await File('$directory/$name').readAsString()).trim());
    });
    final group = result!;
    final emitter = (((group['definition'] as Map)['emitters'] as List).single as Map);
    final texture = (emitter['appearance'] as Map)['initialTexture'] as String;
    expect(texture, contains('__bw2_'));
    final baked = image.decodePng(base64Decode((group['textures'] as Map)[texture] as String))!;
    final original = image.decodePng(base64Decode(
        (await File('$directory/texture00.b64').readAsString()).trim()))!;
    expect(baked.width, original.width);
    expect(baked.height, original.height * 2);
    expect(baked.getPixel(0, baked.height - 1).toList(),
        original.getPixel(0, 0).toList());
    expect(result['approximations'], isNot(contains('texture-field:repeat')));
    expect(result['approximations'], isNot(contains('particle-field:textureRepeatShiftT')));
  });

  test('converts separate particle groups with independent textures', () async {
    final source = _source.replaceFirst('WaitFrames 2', '''
  EmitterAdd 218, 0, EFFVM_EMIT_ATTACKER, EFFVM_EMIT_DEFENDER, 0, 0, 0, 0x1000, 0x1000, 0x1000, 0x1000
  EmitterAdd 220, 1, EFFVM_EMIT_ATTACKER, EFFVM_EMIT_DEFENDER, 0, 0, 0, 0x1000, 0x1000, 0x1000, 0x1000''');
    final bytes = utf8.encode(source);
    final document = {
      'move': {'id': 'two-particle-groups', 'sourceId': 1},
      'source': {'revision': _revision},
      'script': {
        'path': _path,
        'sha256': sha256.convert(bytes).toString(),
        'data': base64Encode(bytes),
      },
    };
    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    final result = await workshop.convert(document, {'names': []}, client,
        fetchResource: (path, limit) async {
      final match = RegExp(r'/([0-9]+)/(particles\.json|texture[0-9]+\.png)$')
          .firstMatch(path)!;
      final directory = '../../tools/avelune_attack_comparator/assets/bw2/'
          'particle${match[1]}';
      final name = match[2]!;
      if (name == 'particles.json') {
        return File('$directory/source.json').readAsBytes();
      }
      return base64Decode(
          (await File('$directory/${name.replaceFirst('.png', '.b64')}')
                  .readAsString())
              .trim());
    });
    expect(result, isNotNull);
    final groups = result!['particleGroups'] as Map;
    expect(groups.keys.toSet(), {'218', '220'});
    for (final id in [218, 220]) {
      final group = groups['$id'] as Map;
      expect(group['sourceEmitterIndices'], [id == 218 ? 0 : 1]);
      final expected = base64Decode(File(
        '../../tools/avelune_attack_comparator/assets/bw2/particle$id/texture00.b64',
      ).readAsStringSync().trim());
      expect(base64Decode((group['textures'] as Map)['texture00'] as String), expected);
    }
    final firstTexture = ((groups['218'] as Map)['textures'] as Map)['texture00'];
    final secondTexture = ((groups['220'] as Map)['textures'] as Map)['texture00'];
    expect(firstTexture, isNot(secondTexture));
  });

  test('admits source animation and palette commands for both combatants', () {
    final program = _convert(_source.replaceFirst('WaitFrames 2', '''
  McssSetVanish EFFVM_ALL, TRUE
  McssPalFade EFFVM_ALL, 0, 12, 2, 0x7fff'''));
    expect(program['conversion'], 'supported');
    expect(workshop.admitted(_instructions(program)), isTrue);
  });

  test('preserves BW2 cry instructions and cry waits', () {
    final program = _convert(_source.replaceFirst('WaitFrames 2', '''
  PlayCry EFFVM_ATTACKER, 34304, 127, 60, -64, 1, 0
  Wait EFFVM_WAIT_CRY'''));
    expect(program['conversion'], 'supported');
    expect(_instructions(program).first['op'], 'playCry');
    expect(_args(_instructions(program).first), containsPair('speed', 34304));
    expect(_args(_instructions(program)[1])['what'], 'CRY');
    expect(workshop.admitted(_instructions(program)), isTrue);
    final invalid = _convert(_source.replaceFirst('WaitFrames 2',
        'PlayCry EFFVM_ATTACKER, 0, 127, 0, 0, 2, 0'));
    expect(invalid['conversion'], isNot('supported'));
  });

  test('admits an orthographic emitter at player position zero', () {
    final program = _convert(_source.replaceFirst('WaitFrames 2',
        'EmitterAddOrtho 284, 0, 0, 8, 0, 0x399a, 0, 0x800, 0x1000, 0x1800, 0x1000'));
    expect(program['conversion'], 'supported');
    expect(workshop.admitted(_instructions(program)), isTrue);
  });

  test('admits a bounded non-unit source emitter camera scale', () {
    final program = _convert(_source.replaceFirst('WaitFrames 2',
        'EmitterAdd 654, 2, EFFVM_EMIT_ATTACKER, EFFVM_EMIT_DEFENDER, 0x2000, 0, 0, 0x1000, 0x59a, 0x1000, 0x1800'));
    expect(program['conversion'], 'supported');
    expect(workshop.admitted(_instructions(program)), isTrue);
    _args(_instructions(program).first)['cameraScale'] = 12289;
    expect(workshop.admitted(_instructions(program)), isFalse);
  });

  test('preserves source sound identifiers and modulation values', () {
    for (final source in [
      'PlaySE SEQ_SE_W229_KIIN, 1, EFFVM_ATTACKER, 0, 200, 80, 200, 100, 0',
      'PlaySE SEQ_SE_W319_SWARD, 1, EFFVM_DEFENDER, 42, -50, 127, 2000, 100, 0',
      'PlaySE 0, 2, EFFVM_ATTACKER, 0, 0, 127, 0, 0, 0',
    ]) {
      final program = _convert(_source.replaceFirst('WaitFrames 2', source));
      expect(program['conversion'], 'supported');
      expect(_instructions(program).first['op'], 'playSound');
    }
    final invalid = _convert(_source.replaceFirst('WaitFrames 2',
        'PlaySE SEQ_SE_W229_KIIN, 1, EFFVM_ATTACKER, 0, 0, 80, 32768, 100, 0'));
    expect(invalid['conversion'], isNot('supported'));
  });

  test('retains a source wait for sound player one', () {
    final program = _convert(_source.replaceFirst('WaitFrames 2',
        'Wait EFFVM_WAIT_SE_PLAYER_1'));
    expect(program['conversion'], 'supported');
    expect(_args(_instructions(program).first)['what'], 'SE_PLAYER_1');
  });

  test('transcribes bounded relative position and return movements', () {
    for (final source in [
      'McssMoveXY EFFVM_ATTACKER, 1, 0, -0x14000, 30, 1, 1',
      'McssMoveXY EFFVM_ATTACKER, 5, 0, 0, 1, 0, 0',
    ]) {
      final program = _convert(_source.replaceFirst('WaitFrames 2', source));
      expect(program['conversion'], 'supported');
      expect(_instructions(program).first['op'], 'moveCombatant');
      expect(workshop.admitted(_instructions(program)), isTrue);
    }
    final unsafe = _convert(_source.replaceFirst('WaitFrames 2',
        'McssMoveXY EFFVM_ATTACKER, 1, 0x20001, 0, 1, 0, 0'));
    expect(unsafe['conversion'], isNot('supported'));
  });

  test('transcribes the zero-frame movement and alpha used by Ally Switch', () {
    final source = _source.replaceFirst('WaitFrames 2', '''
  McssMoveXY EFFVM_ATTACKER, 1, 0, -0x20000, 0, 0, 0
  McssAlpha EFFVM_ATTACKER, 0, 31, 0, 0, 0''');
    final program = _convert(source);
    final instructions = _instructions(program);
    expect(program['conversion'], 'supported');
    expect(_args(instructions[0])['frames'], 0);
    expect(_args(instructions[1])['frames'], 0);
    expect(workshop.admitted(instructions), isTrue);
    for (final invalid in [
      'McssMoveXY EFFVM_ATTACKER, 3, 0, 0, 0, 0, 1',
      'McssAlpha EFFVM_ATTACKER, 1, 31, 0, 0, 0',
    ]) {
      expect(_convert(_source.replaceFirst('WaitFrames 2', invalid))['conversion'],
          isNot('supported'));
    }
  });

  test('transcribes a source rotation step', () {
    final program = _convert(_source.replaceFirst('WaitFrames 2',
        'McssRotate EFFVM_DEFENDER, 1, 0xffff000, 80, 0, 0'));
    expect(program['conversion'], 'supported');
    expect(_instructions(program).first['op'], 'rotateCombatant');
    expect(_args(_instructions(program).first)['angle'], 268431360);
    expect(workshop.admitted(_instructions(program)), isTrue);
  });

  test('transcribes a source rotation swing', () {
    final program = _convert(_source.replaceFirst('WaitFrames 2',
        'McssRotate EFFVM_ATTACKER, 2, 0xff8e3955, 6, 2, 2'));
    expect(program['conversion'], 'supported');
    expect(_instructions(program).first['op'], 'rotateCombatant');
    expect(_args(_instructions(program).first)['angle'], -7456427);
    expect(workshop.admitted(_instructions(program)), isTrue);
  });

  test('selects a supported source variant when another is unsupported', () {
    const source = '''
#include "asm/btlv_effvm.inc"
ScriptHeader 2
ScriptVariant Example
ScriptVariant Other
Example:
  McssSetMode EFFVM_ATTACKER, 3
  End
Other:
  McssMosaic EFFVM_ATTACKER, 1
  End
''';
    final program = _convert(source);
    expect(program['conversion'], 'unsupported');
    final selected = workshop.selectSupportedVariant(program);
    expect(selected, isNotNull);
    expect(selected!['variants'], ['Example']);
    expect(selected['entryIndex'], 0);
    expect(_instructions(selected).map((item) => item['op']),
        ['setCombatantVisibility', 'end']);
    expect(workshop.admitted(_instructions(selected)), isTrue);
    expect(workshop.selectSupportedVariant(_convert(source, variant: 'Other')), isNull);
  });

  test('rebases selected variant labels and rejects missing ends or branches', () {
    const source = '''
#include "asm/btlv_effvm.inc"
ScriptHeader 2
ScriptVariant Other
ScriptVariant Example
Other:
  McssMosaic EFFVM_ATTACKER, 1
  End
Example:
  WaitFrames 2
Middle:
  End
''';
    final selected = workshop.selectSupportedVariant(_convert(source));
    expect(selected, isNotNull);
    expect(selected!['entryIndex'], 0);
    expect(selected['labels'], [
      {'name': 'Example', 'instructionIndex': 0, 'line': 8},
      {'name': 'Middle', 'instructionIndex': 1, 'line': 10},
    ]);
    expect(
      workshop.selectSupportedVariant(_convert(source.replaceFirst(
          '  WaitFrames 2', '  IfVarConst EFFVM_VAR_ATTACKER_SIDE, EFFVM_CMP_EQ, 0, Middle'))),
      isNull,
    );
    final missingEnd = source.replaceFirst(
        '  End\nExample:', '  WaitFrames 1\nExample:');
    expect(workshop.selectSupportedVariant(_convert(missingEnd)), isNotNull);
    expect(workshop.selectSupportedVariant(_convert(missingEnd, variant: 'Other')), isNull);
  });

  test('transcribes source combatant alpha changes', () {
    for (final type in [0, 1]) {
      final program = _convert(_source.replaceFirst('WaitFrames 2',
          'McssAlpha EFFVM_ATTACKER, $type, 2, 20, 1, 0'));
      expect(program['conversion'], 'supported');
      final instruction = _instructions(program).first;
      expect(instruction['op'], 'fadeCombatantAlpha');
      expect(_args(instruction), containsPair('alpha', 2));
      expect(workshop.admitted(_instructions(program)), isTrue);
    }
    final unsupported = _convert(_source.replaceFirst('WaitFrames 2',
        'McssAlpha EFFVM_ATTACKER, 2, 2, 20, 1, 1'));
    expect(unsupported['conversion'], isNot('supported'));
  });

  test('admits the bounded emitter, alpha and movement used by Dark Void', () {
    for (final command in [
      'McssAlpha EFFVM_DEFENDER, 2, 1, 4, 0, 0',
      'McssMoveXY EFFVM_DEFENDER, 2, 0, -0xc000, 60, 0, 1',
      'EmitterAdd 644, 2, EFFVM_EMIT_DEFENDER, 8, 0x333, 0, 0, 0x1000, 0x1000, 0x5000, 0x1000',
    ]) {
      final program = _convert(_source.replaceFirst('WaitFrames 2', command));
      expect(program['conversion'], 'supported', reason: command);
      expect(workshop.admitted(_instructions(program)), isTrue, reason: command);
    }
  });

  test('transcribes temporary source combatant visibility', () {
    for (final mode in [3, 4]) {
      final program = _convert(_source.replaceFirst('WaitFrames 2',
          'McssSetMode EFFVM_ATTACKER, $mode'));
      expect(program['conversion'], 'supported');
      final instruction = _instructions(program).first;
      expect(instruction['op'], 'setCombatantVisibility');
      expect(_args(instruction), containsPair('mode', mode));
      expect(workshop.admitted(_instructions(program)), isTrue);
    }
    final unknown = _convert(_source.replaceFirst('WaitFrames 2',
        'McssSetMode EFFVM_ATTACKER, 5'));
    expect(unknown['conversion'], isNot('supported'));
  });

  test('transcribes an emitter positioned in the BW2 battlefield', () {
    final program = _convert(_source.replaceFirst('WaitFrames 2',
        'EmitterAddAt 529, 0, -0x1000, 0, 0x3000, 0, 0, 0, 0x2000, 0, 0, 0x1000, 0x1000, 0x1000, 0x1000'));
    expect(program['conversion'], 'supported');
    final instruction = _instructions(program).first;
    expect(instruction['op'], 'startFieldEmitter');
    expect(_args(instruction), containsPair('fromX', -4096));
    expect(_args(instruction), containsPair('fromZ', 12288));
    expect(_args(instruction), containsPair('offsetY', 8192));
    expect(workshop.admitted(_instructions(program)), isTrue);

    final distant = _convert(_source.replaceFirst('WaitFrames 2',
        'EmitterAddAt 529, 0, 0x40000000, 0, 0, 0, 0, 0, 0, 0, 0, 0x1000, 0x1000, 0x1000, 0x1000'));
    expect(workshop.admitted(_instructions(distant)), isFalse);
  });

  test('transcribes a relative source camera movement', () {
    final program = _convert(_source.replaceFirst('WaitFrames 2',
        'CameraMove 2, 0, 0, 0, 0, 0x3000, 0, 16, 0, 12'));
    expect(program['conversion'], 'supported');
    expect(_instructions(program).first['op'], 'moveCameraRelative');
    expect(_args(_instructions(program).first)['targetY'], 12288);
    expect(workshop.admitted(_instructions(program)), isTrue);
  });

  test('transcribes sinusoidal moving emitters from the source', () {
    for (final type in [5, 6]) {
      final program = _convert(_source.replaceFirst('WaitFrames 2',
          'EmitterMove 308, 0, $type, EFFVM_EMIT_ATTACKER, EFFVM_EMIT_DEFENDER, 0x2000, 0x64000, 0x666, 0x1000, 0x1000, 0x4000'));
      expect(program['conversion'], 'supported');
      expect(_args(_instructions(program).first)['motion'], type);
      expect(workshop.admitted(_instructions(program)), isTrue);
    }
  });

  test('workshop resolves player-side branches without executing the enemy branch', () async {
    Map<String, Object?> document(String source) {
      final bytes = utf8.encode(source);
      return {
        'move': {'id': 'example', 'sourceId': 1},
        'source': {'revision': _revision},
        'script': {'data': base64Encode(bytes), 'path': _path,
          'sha256': sha256.convert(bytes).toString()},
      };
    }
    final source = _source.replaceFirst('WaitFrames 2', '''
  IfVarConst EFFVM_VAR_ATTACKER_SIDE, EFFVM_CMP_EQ, 1, Enemy
  McssMoveXY EFFVM_ATTACKER, 2, 0x1000, 0, 2, 0, 1
  IfVarConst EFFVM_VAR_ATTACKER_SIDE, EFFVM_CMP_EQ, 0, Done
Enemy:
  McssMoveXY EFFVM_ATTACKER, 2, 0x2000, 0, 2, 0, 1
Done:''');
    final client = HttpClient();
    try {
      final bundle = await workshop.convert(document(source), {}, client);
      expect(bundle, isNotNull);
      final program = bundle!['program'] as Map<String, Object?>;
      final instructions = _instructions(program);
      expect(instructions.map((item) => item['op']), ['moveCombatant', 'end']);
      expect(_args(instructions.first)['x'], 4096);
      expect(bundle['approximations'], contains('source-branch:player-side-only'));
      final unsupported = source.replaceAll('EFFVM_VAR_ATTACKER_SIDE',
          'EFFVM_VAR_UNKNOWN');
      expect(await workshop.convert(document(unsupported), {}, client), isNull);
      final loop = source.replaceFirst('1, Enemy', '0, Example');
      expect(await workshop.convert(document(loop), {}, client), isNull);
    } finally {
      client.close(force: true);
    }
  });

  test('workshop resolves source battle style for a single battle', () async {
    final client = HttpClient();
    try {
      for (final (condition, value, expected) in [
        ('EFFVM_CMP_NE', '2', 4096),
        ('EFFVM_CMP_EQ', '0', 4096),
        ('EFFVM_CMP_EQ', '2', 8192),
        ('EFFVM_CMP_NE', '0', 8192),
      ]) {
        final source = _source.replaceFirst('WaitFrames 2', '''
  IfVarConst EFFVM_VAR_BATTLE_STYLE, $condition, $value, Single
  McssMoveXY EFFVM_ATTACKER, 2, 0x2000, 0, 2, 0, 1
  End
Single:
  McssMoveXY EFFVM_ATTACKER, 2, 0x1000, 0, 2, 0, 1''');
        final bytes = utf8.encode(source);
        final document = {
          'move': {'id': 'example', 'sourceId': 1},
          'source': {'revision': _revision},
          'script': {
            'data': base64Encode(bytes),
            'path': _path,
            'sha256': sha256.convert(bytes).toString(),
          },
        };
        final bundle = await workshop.convert(document, {}, client);
        expect(bundle, isNotNull, reason: '$condition $value');
        final program = bundle!['program'] as Map<String, Object?>;
        expect(_args(_instructions(program).first)['x'], expected);
        expect(bundle['approximations'], contains('source-branch:single-battle-only'));
        expect(bundle['approximations'], isNot(contains('source-branch:player-side-only')));
      }
    } finally {
      client.close(force: true);
    }
  });

  test('workshop preserves the player-side route through a forward jump', () {
    final source = _source.replaceFirst('WaitFrames 2', '''
  IfVarConst EFFVM_VAR_ATTACKER_SIDE, EFFVM_CMP_EQ, 1, Enemy
  CameraMovePreset 1, 1, 32, 0, 12
  EmitterMove 361, 0, 2, EFFVM_EMIT_ATTACKER, 1, 0x1000, 0x14000, 0x2000, 0x1000, 0x1000, 0
  EmitterAdd 361, 1, 1, 8, 0x1000, 0, 0, 0x1000, 0x1000, 0x1000, 0x1000
  Jump Done
Enemy:
  CameraMovePreset 1, 0, 32, 0, 12
Done:''');
    final specialized = workshop.specializeWorkshopContext(_convert(source));
    expect(specialized, isNotNull);
    final instructions = _instructions(specialized!);
    expect(instructions.map((item) => item['op']),
        ['moveCameraPreset', 'startMovingEmitter', 'startEmitter', 'end']);
    expect(_args(instructions[0])['camera'], 1);
    expect(_args(instructions[1])['to'], 'EFFVM_EMIT_DEFENDER');
    expect(_args(instructions[2])['from'], 'EFFVM_EMIT_DEFENDER');
    expect(workshop.admitted(instructions), isTrue);
    final backwards = source.replaceFirst('Jump Done', 'Jump Example');
    expect(workshop.specializeWorkshopContext(_convert(backwards)), isNull);
  });

  test('transcribes a source position shake', () {
    final program = _convert(_source.replaceFirst('WaitFrames 2',
        'McssMoveXY EFFVM_DEFENDER, 3, 0x1000, 0, 1, 2, 3'));
    expect(program['conversion'], 'supported');
    expect(_args(_instructions(program).first)['type'], 3);
    expect(workshop.admitted(_instructions(program)), isTrue);
  });

  test('transcribes horizontal camera shake from the source', () {
    final program = _convert(_source.replaceFirst('WaitFrames 2',
        'CameraShake 1, 0x333, 0, 2, 0, 12'));
    expect(program['conversion'], 'supported');
    expect(_args(_instructions(program).first)['direction'], 1);
    expect(workshop.admitted(_instructions(program)), isTrue);
  });

  test('transcribes waiting for both stage and field fades', () {
    final program = _convert(_source.replaceFirst('WaitFrames 2',
        'Wait EFFVM_WAIT_STAGE_FIELD_FADE'));
    expect(program['conversion'], 'supported');
    expect(_args(_instructions(program).first)['what'], 'STAGE_FIELD_FADE');
  });

  test('admits orthographic emitters aimed at the opposing combatant', () {
    final program = _convert(_source.replaceFirst('WaitFrames 2',
        'EmitterAddOrtho 236, 0, EFFVM_EMIT_DEFENDER, EFFVM_EMIT_ATTACKER, 0, 0xb33, 0, 0x800, 0x1000, 0x800, 0x1000'));
    expect(program['conversion'], 'supported');
    expect(workshop.admitted(_instructions(program)), isTrue);
  });

  test('admits moving emitters with source particle lifetime scaling', () {
    final program = _convert(_source.replaceFirst('WaitFrames 2',
        'EmitterMove 605, 0, 2, EFFVM_EMIT_ATTACKER, EFFVM_EMIT_DEFENDER, 0x2000, 0x36000, 0x4000, 0xe66, 0x1000, 0'));
    expect(program['conversion'], 'supported');
    expect(_args(_instructions(program).first)['lifeScale'], 0xe66);
    expect(workshop.admitted(_instructions(program)), isTrue);

    final scaledCamera = _convert(_source.replaceFirst('WaitFrames 2',
        'EmitterMove 605, 0, 2, EFFVM_EMIT_ATTACKER, EFFVM_EMIT_DEFENDER, 0x2000, 0x36000, 0x4000, 0xe66, 0x2000, 0'));
    expect(workshop.admitted(_instructions(scaledCamera)), isFalse);
  });

  test('transcribes BW2 emitter scaling and reverse target parameters', () {
    final program = _convert(_source.replaceFirst('WaitFrames 2',
        'EmitterAdd 470, 0, EFFVM_EMIT_DEFENDER, EFFVM_EMIT_ATTACKER, 0x2000, 0x3000, 1, 0x800, 0x800, 0x1800, 0x1000'));
    expect(program['conversion'], 'supported');
    final instructions = _instructions(program);
    expect(_args(instructions.first), containsPair('lifeScale', 2048));
    expect(_args(instructions.first), containsPair('radiusScale', 2048));
    expect(_args(instructions.first), containsPair('scaleScale', 6144));
    expect(workshop.admitted(instructions), isTrue);

    final sideZero = _convert(_source.replaceFirst('WaitFrames 2',
        'EmitterAdd 470, 0, 0, 8, 0x2000, 0, 0, 0x1000, 0x1000, 0x1000, 0x1000'));
    expect(sideZero['conversion'], 'supported');
    expect(workshop.admitted(_instructions(sideZero)), isTrue);

    final cameraScale = _convert(_source.replaceFirst('WaitFrames 2',
        'EmitterAdd 470, 0, EFFVM_EMIT_DEFENDER, 8, 0x2000, 0, 0, 0x1000, 0x1000, 0x1000, 0x2000'));
    expect(workshop.admitted(_instructions(cameraScale)), isTrue);
  });

  test('transcribes BW2 scale steps with an absolute destination', () {
    final program = _convert(_source.replaceFirst('WaitFrames 2',
        'McssScale EFFVM_ATTACKER, 1, 0x800, 0x800, 4, 1, 0'));
    expect(program['conversion'], 'supported');
    final instructions = _instructions(program);
    expect(_args(instructions.first)['type'], 1);
    expect(_args(instructions.first)['x'], 2048);
    expect(_args(instructions.first)['times'], 0);
    expect(workshop.admitted(instructions), isTrue);
    final unsafe = _convert(_source.replaceFirst('WaitFrames 2',
        'McssScale EFFVM_ATTACKER, 1, 0, 0x1000, 4, 1, 0'));
    expect(unsafe['conversion'], isNot('supported'));
  });

  test('converts actor-only source programs without inventing particles', () async {
    Map<String, Object?> document(String source) {
      final bytes = utf8.encode(source);
      return {
        'move': {'id': 'bulk-up', 'sourceId': 339},
        'source': {'revision': _revision},
        'script': {'data': base64Encode(bytes), 'path': _path,
          'sha256': sha256.convert(bytes).toString()},
      };
    }

    final client = HttpClient();
    try {
      final source = _source.replaceFirst('WaitFrames 2',
          'McssScale EFFVM_ATTACKER, 3, 0x666, -0x666, 6, 1, 1');
      final bundle = await workshop.convert(document(source), {}, client);
      expect(bundle, isNotNull);
      expect(bundle!['particle'], isNull);
      expect(bundle['sourceEmitterIndices'], isEmpty);
      expect(bundle['textures'], isEmpty);
      expect(await workshop.convert(document(_source), {}, client), isNull);
    } finally {
      client.close(force: true);
    }
  });

  test('transcribes bounded BW2 scale shake and rejects unsafe excursions', () {
    final program = _convert(_source.replaceFirst('WaitFrames 2',
        'McssScale EFFVM_DEFENDER, 3, -0x333, 0, 2, 1, 3'));
    expect(program['conversion'], 'supported');
    final instructions = _instructions(program);
    expect(instructions.first['op'], 'scaleCombatant');
    expect(_args(instructions.first)['type'], 3);
    expect(workshop.admitted(instructions), isTrue);

    final unsafe = _convert(_source.replaceFirst('WaitFrames 2',
        'McssScale EFFVM_DEFENDER, 3, 0x1000, 0, 2, 1, 1'));
    expect(unsafe['conversion'], isNot('supported'));
    final roundingUnsafe = _convert(_source.replaceFirst('WaitFrames 2',
        'McssScale EFFVM_DEFENDER, 3, 0xfff, 0, 2, 1, 1'));
    expect(roundingUnsafe['conversion'], isNot('supported'));
    final args = _args(instructions.first);
    args['x'] = 4095;
    expect(workshop.admitted(instructions), isFalse);
  });

  test('transcribes additional single-battle camera presets', () {
    for (final preset in [10, 12, 14, 21]) {
      final program = _convert(_source.replaceFirst(
        'WaitFrames 2', 'CameraMovePreset 1, $preset, 24, 0, 8',
      ));
      expect(program['conversion'], 'supported', reason: 'preset $preset');
      expect(_args(_instructions(program).first)['camera'], preset);
      expect(workshop.admitted(_instructions(program)), isTrue);
    }
  });

  test('retains the original sound channels and centered pan in source scripts', () {
    final program = _convert(_source.replaceFirst('WaitFrames 2', '''
PlaySE SEQ_SE_W157_03, 3, EFFVM_DEFENDER, 0, 0, 80, 0, 0, 0
PlaySE SEQ_SE_FLD_34, 5, EFFVM_PAN_CENTER, 0, 0, 127, 0, 0, 0
PanSE 3, 0, EFFVM_DEFENDER, EFFVM_ATTACKER, 0, 40, 0, 0
MoveSE 4, 0, 0, -1000, 2000, 0, 90, 0, 0
'''));
    expect(program['conversion'], 'supported');
    final instructions = _instructions(program);
    expect(instructions.map((value) => value['op']),
        ['playSound', 'playSound', 'panSound', 'moveSound', 'end']);
    expect(_args(instructions[0])['player'], 3);
    expect(_args(instructions[1])['player'], 5);
    expect(_args(instructions[1])['pan'], 'EFFVM_PAN_CENTER');
    expect(_args(instructions[2])['player'], 3);
    expect(_args(instructions[3])['player'], 4);
    expect(workshop.admitted(instructions), isTrue);
  });

  test('converts the original Psychic background without inventing particles',
      () async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.https('pokemon-api.yoahn.me',
          '/v1/snapshots/public-2026-11-02-bw2/gen5-move-script/94'));
      final response = await request.close().timeout(const Duration(seconds: 20));
      expect(response.statusCode, 200);
      final document = jsonDecode(await utf8.decodeStream(response)) as Map;
      expect((document['script'] as Map)['sha256'],
          'f6aff585ceb2eba95bba012a449583c657474af36e7a0b0f9292d0d0a9c6680b');
      final source = document['script'] as Map;
      final program = Gen5SourceProgramConverter.convert(
        base64Decode(source['data'] as String), sourceRevision: _revision,
        sourcePath: source['path'] as String,
        expectedSha256: source['sha256'] as String, variant: 'Psychic',
      );
      expect(program['conversion'], 'supported', reason: '${program['diagnostics']}');
      expect(workshop.admitted(_instructions(program)), isTrue);
      final result = await workshop.convert(document, {
        'names': [
          {'language': {'name': 'fr'}, 'name': 'Psyko'},
          {'language': {'name': 'en'}, 'name': 'Psychic'},
        ],
        'type': {'name': 'psychic'},
        'damage_class': {'name': 'special'},
      }, client);
      expect(result, isNotNull);
      expect(result!['particle'], isNull);
      expect(result['sourceEmitterIndices'], isEmpty);
      expect((result['backgrounds'] as Map).keys, contains('48'));
      expect(result['approximations'], contains('background-wave:trigonometry-experimental'));
    } finally {
      client.close(force: true);
    }
  }, skip: Platform.environment['GEN5_TEST_PINNED_SOURCE_NETWORK'] != '1');

  test('transcribes the moving and rippling background used by Psychic', () {
    final program = _convert(_source.replaceFirst('WaitFrames 2', '''
LoadBg 48
BgMove 1, 0, 40, 40, 1, 0
BgWave 1, 0x1800, 16, 60, 0, 0
Wait EFFVM_WAIT_ALL
'''));
    expect(program['conversion'], 'supported');
    final instructions = _instructions(program);
    expect(_args(instructions[1]), {
      'mode': 1, 'x': 0, 'y': 40, 'frames': 40, 'wait': 1, 'count': 0,
    });
    expect(instructions[2]['op'], 'waveBackground');
    expect(_args(instructions[2]), {
      'mode': 1, 'amplitude': 6144, 'step': 16, 'frames': 60,
      'fadeMode': 0, 'fadeFrames': 0,
    });
    expect(workshop.admitted(instructions), isTrue);
  });

  test('admits source scroll parameters ignored by BW2', () {
    final program = _convert(_source.replaceFirst(
      'WaitFrames 2', 'BgMove 4, 0, 8, 140, 1, 0',
    ));
    expect(program['conversion'], 'supported');
    expect(workshop.admitted(_instructions(program)), isTrue);
  });

  test('transcribes the background controls used by Hydro Pump', () {
    final program = _convert(_source.replaceFirst('WaitFrames 2', '''
LoadBg 18
SetVanish 2, 0
PaletteFade 4, 0, 14, 0, 0
BgMove 4, -20, 0, 130, 0, 0
SetVanish 0, 1
PaletteFade 3, 14, 6, 0, 0
Wait EFFVM_WAIT_BG
'''));
    expect(program['conversion'], 'supported');
    final instructions = _instructions(program);
    expect(instructions.map((x) => x['op']), [
      'loadBackground',
      'setSceneVisibility',
      'fadeStagePalette',
      'moveBackground',
      'setSceneVisibility',
      'fadeStagePalette',
      'waitTasks',
      'end',
    ]);
    expect(_args(instructions[0]), {'background': 18});
    expect(_args(instructions[1]), {'target': 2, 'hide': 0});
    expect(_args(instructions[3]), {
      'mode': 4, 'x': -20, 'y': 0, 'frames': 130, 'wait': 0, 'count': 0,
    });
    expect(_args(instructions[6]), {'what': 'BG'});
  });

  test('rejects unsupported background motions and visibility targets', () {
    for (final command in [
      'LoadBg -1',
      'SetVanish 5, 1',
      'BgMove 3, -20, 0, 130, 0, 0',
      'BgMove 4, -20, 0, -1, 1, 0',
      'BgWave 1, 0x1800, 16, 60, 1, 4',
      'PaletteFade 5, 0, 14, 0, 0',
    ]) {
      final program = _convert(_source.replaceFirst('WaitFrames 2', command));
      expect(program['conversion'], 'unsupported', reason: command);
    }
  });

  test('transcribes the background swing and sound channel of Fire Blast', () {
    final program = _convert(_source.replaceFirst('WaitFrames 2', '''
BgMove 2, 0, 8, 2, 0, 16
BgPalAnim 6, 3
MoveSE 0, 0, 0, -1000, 2000, 0, 45, 0, 0
'''));
    expect(program['conversion'], 'supported');
    expect(_args(_instructions(program).first), {
      'mode': 2, 'x': 0, 'y': 8, 'frames': 2, 'wait': 0, 'count': 16,
    });
    expect(_args(_instructions(program)[1]), {'animation': 6, 'loops': 3});
    expect(_args(_instructions(program)[2])['player'], 0);
    expect(workshop.admitted(_instructions(program)), isTrue);
  });

  test('admits each pinned Hydro Pump command for the workshop', () async {
    const path = 'res/battle/animations/moves/hydro_pump.s';
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.https('raw.githubusercontent.com',
          '/fuddlesworth/pokebw2/$_revision/$path'));
      final response = await request.close().timeout(const Duration(seconds: 20));
      expect(response.statusCode, 200);
      final bytes = Uint8List.fromList(await response.expand((x) => x).toList());
      final program = Gen5SourceProgramConverter.convert(bytes,
          sourceRevision: _revision,
          sourcePath: path,
          expectedSha256: '060b02b3f752dfb35e5e9d1b4269630a92e270376820cb45b9ef0ae7b72c3db2',
          variant: 'HydroPump');
      expect(program['conversion'], 'supported', reason: '${program['diagnostics']}');
      for (final instruction in _instructions(program)) {
        expect(workshop.admitted([instruction]), isTrue,
            reason: '${instruction['source']} ${instruction['args']}');
      }
    } finally {
      client.close(force: true);
    }
  }, skip: Platform.environment['GEN5_TEST_PINNED_SOURCE_NETWORK'] != '1');

  test('transcribes the orthographic emitter used by Quick Attack', () {
    final program = _convert(_source.replaceFirst(
      'WaitFrames 2',
      'EmitterAddOrtho 270, 0, EFFVM_EMIT_DEFENDER, 8, 0, 0x2000, 0, 0x800, 0x1000, 0x800, 0x1000',
    ));
    expect(program['conversion'], 'supported');
    final instruction = _instructions(program).first;
    expect(instruction['op'], 'startOrthoEmitter');
    expect(_args(instruction), {
      'particle': 270,
      'emitter': 0,
      'from': 'EFFVM_EMIT_DEFENDER',
      'to': 8,
      'offsetX': 0,
      'offsetY': 8192,
      'offsetZ': 0,
      'radiusScale': 2048,
      'lifeScale': 4096,
      'scaleScale': 2048,
      'cameraScale': 4096,
    });
    expect(workshop.admitted(_instructions(program)), isTrue);
  });

  test('transcribes the fixed-point circular motion used by Quick Attack', () {
    final program = _convert(_source.replaceFirst(
      'WaitFrames 2',
      'McssCircle EFFVM_ATTACKER, 3, 3, 0x1000, 0x1000, 0xa000, 0x1000, 0x1000, 0',
    ));
    expect(program['conversion'], 'supported');
    final instruction = _instructions(program).first;
    expect(instruction['op'], 'circleCombatant');
    final args = _args(instruction);
    expect(args['targets'], 'EFFVM_ATTACKER');
    expect(args['mode'], 3);
    expect(args['start'], 3);
    expect(args['radius1'], 4096);
    expect(args['radius2'], 4096);
    expect(args['framesFx32'], 40960);
    expect(args['frames'], 10);
    expect(args['waitFx32'], 4096);
    expect(args['wait'], 1);
    expect(args['countFx32'], 4096);
    expect(args['count'], 1);
    expect(args['turnWait'], 0);
    expect(workshop.admitted(_instructions(program)), isTrue);
  });

  test('rejects a circular motion with zero frames', () {
    final program = _convert(_source.replaceFirst(
      'WaitFrames 2',
      'McssCircle EFFVM_ATTACKER, 3, 3, 0x1000, 0x1000, 0, 0, 0x1000, 0',
    ));
    expect(program['conversion'], 'unsupported');
    expect((_instructions(program).first)['op'], 'unsupported');
  });

  test('transcribes solo camera presets used by Quick Attack', () {
    for (final preset in [15, 16, 17]) {
      final program = _convert(_source.replaceFirst(
        'WaitFrames 2',
        'CameraMovePreset 1, $preset, 24, 0, 0',
      ));
      expect(program['conversion'], 'supported', reason: 'preset $preset');
      final instruction = _instructions(program).first;
      expect(instruction['op'], 'moveCameraPreset');
      expect(_args(instruction)['camera'], preset);
    }
  });

  test('translates the BW2 rotating shake used by Charm', () {
    final program = _convert(_source.replaceFirst(
      'WaitFrames 2',
      'McssRotate EFFVM_ATTACKER, 3, 0xaaaa00, 6, 1, 3',
    ));
    expect(program['conversion'], 'supported');
    final instruction = _instructions(program).first;
    expect(instruction['op'], 'rotateCombatant');
    expect(_args(instruction)['angle'], 0xaaaa00);
    expect(_args(instruction)['type'], 3);
    expect(_args(instruction)['frames'], 6);
    expect(_args(instruction)['wait'], 1);
    expect(_args(instruction)['times'], 3);
  });

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
        'EmitterMove 220, 1, 3, EFFVM_EMIT_ATTACKER, EFFVM_EMIT_DEFENDER, 0x2000, 0x1e000, 0x800, 0x1000, 0x1000, 0x5000'));
    expect(mode['conversion'], 'unsupported');
    expect((_instructions(mode).first['source'] as Map)['operands'][2], '3');
    expect((mode['diagnostics'] as List).single['code'], 'unsupportedOperand');
  });

  test('converts an arcing moving emitter with its original height', () {
    final program = _convert(_source.replaceFirst('WaitFrames 2',
        'EmitterMove 216, 1, 2, EFFVM_EMIT_ATTACKER, EFFVM_EMIT_DEFENDER, 0x2000, 0x1e000, 0x399a, 0x1000, 0x1000, 0'));
    expect(program['conversion'], 'supported');
    final instruction = _instructions(program).first;
    expect(instruction['op'], 'startMovingEmitter');
    expect(_args(instruction)['motion'], 2);
    expect(_args(instruction)['height'], 0x399a);
    expect(_args(instruction)['motionFramesFx32'], 0x1e000);
  });

  test('converts stationary emitters, stage fades, and silent audio controls', () {
    for (final instruction in [
      'EmitterMove 218, 0, 1, EFFVM_EMIT_ATTACKER, EFFVM_EMIT_DEFENDER, 0x2000, 0, 0, 0x1000, 0x1000, 0',
      'PaletteFade 2, 0, 10, 0, 30',
      'PlaySE SEQ_SE_W307_02, 0, EFFVM_DEFENDER, 10, 0, 127, 0, 0, 0',
      'MoveSE 2, 0, 0, -3000, 0, 0, 60, 0, 0',
    ]) {
      final program = _convert(_source.replaceFirst('WaitFrames 2', instruction));
      expect(program['conversion'], 'supported', reason: instruction);
    }
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
