import 'gen5_battle_script_parameters.dart';

final class Gen5BattleScriptSymbols {
  Gen5BattleScriptSymbols._({
    required Map<String, int> resolvedSymbols,
    required Set<String> unresolvedSymbols,
  })  : resolvedSymbols = Map.unmodifiable(resolvedSymbols),
        unresolvedSymbols = Set.unmodifiable(unresolvedSymbols);

  final Map<String, int> resolvedSymbols;
  final Set<String> unresolvedSymbols;

  bool get allSymbolsResolved => unresolvedSymbols.isEmpty;

  void requireAllSymbolsResolved() {
    if (!allSymbolsResolved) {
      throw const FormatException('Battle script has unresolved symbols');
    }
  }

  static const sourceRevision = '41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c';
  static const _constants = <String, int>{
    'FALSE': 0,
    'TRUE': 1,
    'EFFVM_ATTACKER': 14,
    'EFFVM_DEFENDER': 16,
    'EFFVM_EMIT_ATTACKER': 9,
    'EFFVM_EMIT_DEFENDER': 11,
    'EFFVM_WAIT_ALL': 0,
    'EFFVM_WAIT_CAMERA': 1,
    'EFFVM_WAIT_PARTICLES': 2,
    'EFFVM_WAIT_MCSS': 3,
    'EFFVM_WAIT_SE': 10,
  };

  static Gen5BattleScriptSymbols resolve(
      Gen5BattleScriptParameters parameters) {
    if (parameters.source.sourceRevision != sourceRevision) {
      throw const FormatException('Unrecognized battle symbol revision');
    }
    final resolved = <String, int>{};
    final unresolved = <String>{};
    for (final instruction in parameters.instructions) {
      for (final operand in instruction.parameters.values) {
        if (operand is! Gen5BattleSymbolOperand) continue;
        final value = _constants[operand.symbol];
        if (value == null) {
          unresolved.add(operand.symbol);
        } else {
          resolved[operand.symbol] = value;
        }
      }
    }
    return Gen5BattleScriptSymbols._(
      resolvedSymbols: resolved,
      unresolvedSymbols: unresolved,
    );
  }
}
