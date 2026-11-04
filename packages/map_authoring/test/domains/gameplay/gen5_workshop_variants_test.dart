import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

import '../../../tool/gen5_source_workshop_batch.dart' as workshop;

void main() {
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
}
