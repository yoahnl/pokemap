import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_source_program_converter.dart';
import 'package:test/test.dart';

import '../../../tool/gen5_source_workshop_batch.dart' as workshop;

void main() {
  test('admits the boosted cross-move emitter parameters within bounded limits', () {
    Map<String, dynamic> instruction(String op, Map<String, dynamic> args) =>
        {'op': op, 'args': args};

    final standard = <String, dynamic>{
      'particle': 738, 'emitter': 4,
      'from': 'EFFVM_EMIT_DEFENDER', 'to': 8,
      'offsetY': 4096, 'unk18': 0, 'unused': 0,
      'radiusScale': 8192, 'lifeScale': 12288,
      'scaleScale': 12288, 'cameraScale': 4096,
    };
    final field = <String, dynamic>{
      'particle': 738, 'emitter': 3,
      'fromX': 0, 'fromY': 53248, 'fromZ': 0,
      'toX': 0, 'toY': 0, 'toZ': 0, 'offsetY': 0,
      'unk18': 0, 'unused': 0, 'radiusScale': 4096,
      'lifeScale': 12288, 'scaleScale': 12288, 'cameraScale': 4096,
    };
    final moving = <String, dynamic>{
      'particle': 738, 'emitter': 2, 'motion': 2,
      'fromX': 0, 'fromY': 53248, 'fromZ': 0,
      'to': 'EFFVM_EMIT_DEFENDER', 'offsetY': 12288,
      'height': -28672, 'lifeScale': 8192, 'cameraScale': 8192,
      'turns': 0, 'motionFramesFx32': 81920, 'motionFrames': 20,
    };
    for (final entry in [
      ('startEmitter', standard),
      ('startFieldEmitter', field),
      ('startMovingFieldEmitter', moving),
    ]) {
      expect(workshop.admitted([instruction(entry.$1, entry.$2)]), isTrue,
          reason: entry.$1);
    }
    expect(workshop.admitted([
      instruction('startEmitter', {...standard, 'lifeScale': 12289}),
    ]), isFalse);
    expect(workshop.admitted([
      instruction('startFieldEmitter', {...field, 'scaleScale': 12289}),
    ]), isFalse);
    expect(workshop.admitted([
      instruction('startMovingFieldEmitter', {...moving, 'cameraScale': 8193}),
    ]), isFalse);
  });

  test('converts the requested source variant and keeps the default', () async {
    final bytes = utf8.encode('''
#include "asm/btlv_effvm.inc"
ScriptHeader 2
ScriptVariant Example
ScriptVariant Example_Impact
Example:
  McssMoveXY EFFVM_ATTACKER, 2, 0x1000, 0, 2, 0, 1
  End
Example_Impact:
  McssMoveXY EFFVM_ATTACKER, 2, 0x2000, 0, 2, 0, 1
  End
''');
    final document = {
      'move': {'id': 'example', 'sourceId': 1},
      'source': {'revision': '41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c'},
      'script': {
        'path': 'res/battle/animations/moves/example.s',
        'sha256': sha256.convert(bytes).toString(),
        'data': base64Encode(bytes),
      },
    };
    final client = HttpClient();
    addTearDown(() => client.close(force: true));

    final defaultBundle = await workshop.convert(document, {}, client);
    final impactBundle = await workshop.convert(
      document,
      {},
      client,
      selectedVariant: 'Example_Impact',
    );

    final defaultProgram = defaultBundle!['program'] as Map;
    final impactProgram = impactBundle!['program'] as Map;
    expect(defaultProgram['variant'], 'Example');
    expect(impactProgram['variant'], 'Example_Impact');
    final instructions = impactProgram['instructions'] as List;
    final entry = instructions[impactProgram['entryIndex'] as int] as Map;
    expect((entry['args'] as Map)['x'], 8192);
    expect(
        defaultBundle['approximations'], contains('source-variant:first-only'));
    expect(impactBundle['approximations'],
        isNot(contains('source-variant:first-only')));
  });

  test('admits an explicitly selected camera-only variant', () async {
    final bytes = utf8.encode('''
#include "asm/btlv_effvm.inc"
ScriptHeader 2
ScriptVariant Example
ScriptVariant Example_Camera
Example:
  End
Example_Camera:
  CameraMovePreset 1, 9, 16, 0, 8
  Wait EFFVM_WAIT_CAMERA
  End
''');
    final document = {
      'move': {'id': 'example', 'sourceId': 1},
      'source': {'revision': '41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c'},
      'script': {
        'path': 'res/battle/animations/moves/example.s',
        'sha256': sha256.convert(bytes).toString(),
        'data': base64Encode(bytes),
      },
    };
    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    final bundle = await workshop.convert(
      document,
      {},
      client,
      selectedVariant: 'Example_Camera',
    );
    expect(bundle, isNotNull);
    expect((bundle!['program'] as Map)['variant'], 'Example_Camera');
  });

  test('admits a zero-frame position step but not a zero-frame swing', () {
    Map<String, Object?> convert(int type) {
      final bytes = utf8.encode('''
#include "asm/btlv_effvm.inc"
ScriptHeader 1
ScriptVariant Example
Example:
  McssMoveXY EFFVM_ATTACKER, $type, 0, -0x14000, 0, 0, 0
  End
''');
      return Gen5SourceProgramConverter.convert(
        bytes,
        sourceRevision: '41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c',
        sourcePath: 'res/battle/animations/moves/example.s',
        expectedSha256: sha256.convert(bytes).toString(),
        variant: 'Example',
      );
    }

    final program = convert(1);
    expect(program['conversion'], 'supported');
    expect(
        workshop.admitted(
            (program['instructions'] as List).cast<Map<String, dynamic>>()),
        isTrue);
    expect(convert(3)['conversion'], isNot('supported'));
  });
}
