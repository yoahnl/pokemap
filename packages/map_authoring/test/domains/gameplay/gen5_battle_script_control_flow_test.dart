import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_battle_script_control_flow.dart';
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
  test('groups instructions until SetYield returns control to the caller', () {
    final script = _script('''
SetYield FALSE
PlaySE SOUND, 1, EFFVM_ATTACKER, 0, 0, 100, 0, 0, 0
PanSE 1, 0, EFFVM_ATTACKER, EFFVM_DEFENDER, 0, 40, 0, 0
SetYield TRUE
WaitFrames 3
End''');
    final blocks = Gen5BattleScriptControlFlow.analyze(script).blocks;
    expect(blocks.map((block) => block.boundary), [
      Gen5BattleScriptBoundary.yieldToCaller,
      Gen5BattleScriptBoundary.waitFrames,
      Gen5BattleScriptBoundary.end,
    ]);
    expect(blocks.map((block) => block.resume), [
      Gen5BattleScriptResume.nextCall,
      Gen5BattleScriptResume.afterNativeCompletionThenNextCall,
      Gen5BattleScriptResume.halted,
    ]);
    expect(blocks[0].instructions.map((step) => step.name), [
      'SetYield',
      'PlaySE',
      'PanSE',
      'SetYield',
    ]);
    expect(blocks[1].instructions.single.arguments, ['3']);
    expect(() => blocks.clear(), throwsUnsupportedError);
    expect(() => blocks[0].instructions.clear(), throwsUnsupportedError);
  });

  test('wait resets yielding while a resource load preserves it', () {
    final script = _script('''
SetYield FALSE
ParticleLoad 7
Wait EFFVM_WAIT_ALL
CameraMovePreset 1, 2, 3, 0, 0
End''');
    final blocks = Gen5BattleScriptControlFlow.analyze(script).blocks;
    expect(blocks.map((block) => block.boundary), [
      Gen5BattleScriptBoundary.particleLoad,
      Gen5BattleScriptBoundary.waitCondition,
      Gen5BattleScriptBoundary.yieldToCaller,
      Gen5BattleScriptBoundary.end,
    ]);
    expect(blocks[0].instructions.map((step) => step.name), [
      'SetYield',
      'ParticleLoad',
    ]);
    expect(blocks[1].instructions.single.name, 'Wait');
    expect(
      blocks[1].resume,
      Gen5BattleScriptResume.afterNativeCompletionThenNextCall,
    );
    expect(blocks[1].waitChecks, {
      Gen5BattleWaitCheck.camera,
      Gen5BattleWaitCheck.mcss,
      Gen5BattleWaitCheck.background,
      Gen5BattleWaitCheck.particles,
      Gen5BattleWaitCheck.stageFade,
      Gen5BattleWaitCheck.fieldFade,
      Gen5BattleWaitCheck.paletteFade,
      Gen5BattleWaitCheck.window,
      Gen5BattleWaitCheck.paletteAnimation,
      Gen5BattleWaitCheck.backgroundWave,
    });
    expect(blocks[1].waitChecks, isNot(contains(Gen5BattleWaitCheck.sound)));
    expect(blocks[2].instructions.single.name, 'CameraMovePreset');
  });

  test('resource loading does not reset a disabled yield flag', () {
    final script = _script('''
SetYield FALSE
ParticleLoad 7
CameraMovePreset 1, 2, 3, 0, 0
SetYield TRUE
End''');
    final blocks = Gen5BattleScriptControlFlow.analyze(script).blocks;
    expect(blocks.map((block) => block.boundary), [
      Gen5BattleScriptBoundary.particleLoad,
      Gen5BattleScriptBoundary.yieldToCaller,
      Gen5BattleScriptBoundary.end,
    ]);
    expect(blocks[1].instructions.map((step) => step.name), [
      'CameraMovePreset',
      'SetYield',
    ]);
    expect(
        blocks[0].resume, Gen5BattleScriptResume.conditionalNativeCompletion);
  });

  test('accepts a bounded hexadecimal frame count', () {
    final blocks = Gen5BattleScriptControlFlow.analyze(
      _script('WaitFrames 0x14\nEnd'),
    ).blocks;
    expect(blocks.first.boundary, Gen5BattleScriptBoundary.waitFrames);
    expect(blocks.first.instructions.single.arguments, ['0x14']);
  });

  test('preserves the specific BW2 wait condition and sound dependencies', () {
    final cases = <String, Set<String>>{
      'EFFVM_WAIT_CAMERA': {'camera'},
      'EFFVM_WAIT_PARTICLES': {'particles'},
      'EFFVM_WAIT_MCSS': {'mcss'},
      'EFFVM_WAIT_SE': {'sound', 'soundDelay', 'soundAutomation'},
    };
    for (final entry in cases.entries) {
      final blocks = Gen5BattleScriptControlFlow.analyze(
        _script('Wait ${entry.key}\nEnd'),
      ).blocks;
      expect(blocks.first.boundary, Gen5BattleScriptBoundary.waitCondition);
      expect(blocks.first.resume,
          Gen5BattleScriptResume.afterNativeCompletionThenNextCall);
      expect(blocks.first.waitChecks.map((check) => check.name).toSet(),
          entry.value,
          reason: entry.key);
    }
  });

  test('rejects unknown commands and malformed known commands', () {
    for (final body in [
      'FutureCommand 1\nEnd',
      'SetYield MAYBE\nEnd',
      'WaitFrames -1\nEnd',
      'WaitFrames UNKNOWN\nEnd',
      'Wait EFFVM_WAIT_UNKNOWN\nEnd',
      'PlaySE SOUND, 1\nEnd',
      'CameraMovePreset 1, 2, 3, 4\nEnd',
    ]) {
      expect(
        () => Gen5BattleScriptControlFlow.analyze(_script(body)),
        throwsFormatException,
        reason: body,
      );
    }
  });
}
