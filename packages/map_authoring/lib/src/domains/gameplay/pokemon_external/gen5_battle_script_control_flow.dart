import 'gen5_battle_script_commands.dart';
import 'gen5_battle_script_source.dart';

enum Gen5BattleScriptBoundary {
  yieldToCaller,
  waitFrames,
  waitCondition,
  particleLoad,
  end,
}

enum Gen5BattleScriptResume {
  nextCall,
  afterNativeCompletionThenNextCall,
  conditionalNativeCompletion,
  halted,
}

enum Gen5BattleWaitCheck {
  camera,
  mcss,
  background,
  particles,
  stageFade,
  fieldFade,
  paletteFade,
  window,
  paletteAnimation,
  backgroundWave,
  sound,
}

final class Gen5BattleScriptBlock {
  Gen5BattleScriptBlock._({
    required List<Gen5BattleScriptInstruction> instructions,
    required this.boundary,
  }) : instructions = List.unmodifiable(instructions);

  final List<Gen5BattleScriptInstruction> instructions;
  final Gen5BattleScriptBoundary boundary;

  Gen5BattleScriptResume get resume => switch (boundary) {
        Gen5BattleScriptBoundary.yieldToCaller =>
          Gen5BattleScriptResume.nextCall,
        Gen5BattleScriptBoundary.waitFrames ||
        Gen5BattleScriptBoundary.waitCondition =>
          Gen5BattleScriptResume.afterNativeCompletionThenNextCall,
        Gen5BattleScriptBoundary.particleLoad =>
          Gen5BattleScriptResume.conditionalNativeCompletion,
        Gen5BattleScriptBoundary.end => Gen5BattleScriptResume.halted,
      };

  Set<Gen5BattleWaitCheck> get waitChecks =>
      boundary == Gen5BattleScriptBoundary.waitCondition
          ? const {
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
            }
          : const {};
}

final class Gen5BattleScriptControlFlow {
  Gen5BattleScriptControlFlow._(List<Gen5BattleScriptBlock> blocks)
      : blocks = List.unmodifiable(blocks);

  final List<Gen5BattleScriptBlock> blocks;

  static Gen5BattleScriptControlFlow analyze(Gen5BattleScriptSource source) {
    final blocks = <Gen5BattleScriptBlock>[];
    var pending = <Gen5BattleScriptInstruction>[];
    var yields = true;
    void finish(Gen5BattleScriptBoundary boundary) {
      blocks.add(
        Gen5BattleScriptBlock._(instructions: pending, boundary: boundary),
      );
      pending = <Gen5BattleScriptInstruction>[];
    }

    for (final instruction in source.instructions) {
      final fields = gen5BattleCommandFields[instruction.name];
      if (fields == null || instruction.arguments.length != fields.length) {
        throw FormatException(
          'Unsupported battle instruction at line ${instruction.line}',
        );
      }
      pending.add(instruction);
      switch (instruction.name) {
        case 'SetYield':
          yields = switch (instruction.arguments.single) {
            'TRUE' => true,
            'FALSE' => false,
            _ => throw FormatException(
                'Invalid yield flag at line ${instruction.line}',
              ),
          };
          if (yields) finish(Gen5BattleScriptBoundary.yieldToCaller);
        case 'WaitFrames':
          final frames = int.tryParse(instruction.arguments.single);
          if (frames == null || frames < 0 || frames > 60000) {
            throw FormatException(
              'Invalid frame wait at line ${instruction.line}',
            );
          }
          yields = true;
          finish(Gen5BattleScriptBoundary.waitFrames);
        case 'Wait':
          if (instruction.arguments.single != 'EFFVM_WAIT_ALL') {
            throw FormatException(
              'Unsupported wait condition at line ${instruction.line}',
            );
          }
          yields = true;
          finish(Gen5BattleScriptBoundary.waitCondition);
        case 'ParticleLoad':
          finish(Gen5BattleScriptBoundary.particleLoad);
        case 'End':
          finish(Gen5BattleScriptBoundary.end);
        default:
          if (yields) finish(Gen5BattleScriptBoundary.yieldToCaller);
      }
    }
    if (pending.isNotEmpty ||
        blocks.isEmpty ||
        blocks.last.boundary != Gen5BattleScriptBoundary.end) {
      throw const FormatException('Incomplete battle control flow');
    }
    return Gen5BattleScriptControlFlow._(blocks);
  }
}
