import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

import '../../support/bw2_vm_trace.dart';

List<Bw2VmTraceEvent> trace(String body) {
  final bytes = Uint8List.fromList(utf8.encode('''
#include "asm/btlv_effvm.inc"
ScriptHeader 1
ScriptVariant Example
Example:
ParticleLoad 218
$body
McssPalFade EFFVM_DEFENDER, 0, 10, 1, 0x1f
End
'''));
  return traceBw2VmSegment(
    bytes,
    sourceRevision: '41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c',
    sourcePath: 'res/battle/animations/moves/example.s',
    expectedSha256: sha256.convert(bytes).toString(),
  );
}

void main() {
  test('preserves yield boundaries and the native wait resume call', () {
    final events = trace('''
SetYield FALSE
PlaySE SEQ_TEST, 1, EFFVM_DEFENDER, 0, 0, 100, 0, 0, 0
SetYield TRUE
EmitterMove 218, 0, 1, EFFVM_EMIT_ATTACKER, EFFVM_EMIT_DEFENDER, 0, 0, 0, 4096, 4096, 0
WaitFrames 2
CameraMovePreset 1, 11, 16, 0, 8
EmitterAdd 218, 2, EFFVM_EMIT_DEFENDER, 8, 0, 0, 0, 4096, 4096, 4096, 4096
''');
    expect(
      events.map((event) => (event.instruction, event.call)).toList(),
      [
        ('SetYield', 0),
        ('PlaySE', 0),
        ('SetYield', 0),
        ('EmitterMove', 1),
        ('WaitFrames', 2),
        ('CameraMovePreset', 5),
        ('EmitterAdd', 6),
      ],
    );
  });

  test('a zero frame wait still consumes one native callback', () {
    final events = trace('''
SetYield FALSE
WaitFrames 0
EmitterAdd 218, 2, EFFVM_EMIT_DEFENDER, 8, 0, 0, 0, 4096, 4096, 4096, 4096
''');
    expect(events.last.call, 2);
  });

  test('rejects waits whose completion cannot be inferred from the script', () {
    expect(
      () => trace('''
SetYield FALSE
Wait EFFVM_WAIT_ALL
EmitterAdd 218, 2, EFFVM_EMIT_DEFENDER, 8, 0, 0, 0, 4096, 4096, 4096, 4096
'''),
      throwsFormatException,
    );
  });
}
