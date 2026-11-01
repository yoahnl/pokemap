import 'gen5_battle_script_commands.dart';
import 'gen5_battle_script_control_flow.dart';
import 'gen5_battle_script_source.dart';

sealed class Gen5BattleOperand {
  const Gen5BattleOperand(this.raw);

  final String raw;
}

final class Gen5BattleNumberOperand extends Gen5BattleOperand {
  const Gen5BattleNumberOperand._(super.raw, this.unsignedWord);

  final int unsignedWord;
  int get signedWord =>
      unsignedWord >= 2147483648 ? unsignedWord - 4294967296 : unsignedWord;
}

final class Gen5BattleSymbolOperand extends Gen5BattleOperand {
  const Gen5BattleSymbolOperand._(super.raw);

  String get symbol => raw;
}

final class Gen5BattleParameterizedInstruction {
  Gen5BattleParameterizedInstruction._({
    required this.instruction,
    required Map<String, Gen5BattleOperand> parameters,
  }) : parameters = Map.unmodifiable(parameters);

  final Gen5BattleScriptInstruction instruction;
  final Map<String, Gen5BattleOperand> parameters;
}

final class Gen5BattleScriptParameters {
  Gen5BattleScriptParameters._({
    required this.source,
    required this.controlFlow,
    required List<Gen5BattleParameterizedInstruction> instructions,
  }) : instructions = List.unmodifiable(instructions);

  final Gen5BattleScriptSource source;
  final Gen5BattleScriptControlFlow controlFlow;
  final List<Gen5BattleParameterizedInstruction> instructions;

  static final _number = RegExp(r'^-?(?:0[xX][0-9a-fA-F]+|[0-9]+)$');
  static final _minimum = BigInt.from(-2147483648);
  static final _maximum = BigInt.from(4294967295);

  static Gen5BattleScriptParameters read(Gen5BattleScriptSource source) {
    final controlFlow = Gen5BattleScriptControlFlow.analyze(source);
    final instructions = <Gen5BattleParameterizedInstruction>[];
    for (final instruction in source.instructions) {
      final fields = gen5BattleCommandFields[instruction.name];
      if (fields == null || fields.length != instruction.arguments.length) {
        throw FormatException(
          'Unsupported battle operands at line ${instruction.line}',
        );
      }
      instructions.add(
        Gen5BattleParameterizedInstruction._(
          instruction: instruction,
          parameters: {
            for (var index = 0; index < fields.length; index++)
              fields[index]: _parseOperand(instruction.arguments[index]),
          },
        ),
      );
    }
    return Gen5BattleScriptParameters._(
      source: source,
      controlFlow: controlFlow,
      instructions: instructions,
    );
  }

  static Gen5BattleOperand _parseOperand(String raw) {
    if (!_number.hasMatch(raw)) return Gen5BattleSymbolOperand._(raw);
    final negative = raw.startsWith('-');
    final magnitude = negative ? raw.substring(1) : raw;
    final hex = magnitude.startsWith('0x') || magnitude.startsWith('0X');
    final parsed = BigInt.parse(
      hex ? magnitude.substring(2) : magnitude,
      radix: hex ? 16 : 10,
    );
    final value = negative ? -parsed : parsed;
    if (value < _minimum || value > _maximum) {
      throw const FormatException('Battle operand exceeds 32 bits');
    }
    final integer = value.toInt();
    final word = integer < 0 ? integer + 4294967296 : integer;
    return Gen5BattleNumberOperand._(raw, word);
  }
}
