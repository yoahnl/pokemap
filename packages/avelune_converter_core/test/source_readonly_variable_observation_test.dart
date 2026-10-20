import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

void main() {
  const read = r'$player.party[$game_variables[pbGet(29)]].happiness >= 255';
  for (final expression in [
    read,
    r'$player.party[$game_variables[pbGet(1)]].happiness >= 0',
    r' $player.party [ $game_variables [ pbGet ( 5000 ) ] ] .happiness >= 255 ',
  ]) {
    test('recognizes only the closed pure condition syntax $expression', () {
      expect(
          recognizesSourcePartyHappinessVariableReadSyntax(expression), isTrue);
    });
  }
  for (final expression in [
    '$read; pbSet(7, 1)',
    '$read\nunknown()',
    r'$player.party[$game_variables[foo()]].happiness >= 255',
    r'$player.party[$game_variables[pbGet(29, foo())]].happiness >= 255',
    r'$player.party[$game_variables[pbGet(target)]].happiness >= 255',
    r'$player.party[$game_variables[pbGet(29) + foo()]].happiness >= 255',
    r'$player.party[$game_variables[pbGet(29)] = 1].happiness >= 255',
    r'$player.party[$game_variables[pbGet(29)] += 1].happiness >= 255',
    r'$player.party[$game_variables[pbGet(29)] ||= 1].happiness >= 255',
    r'$player.party[$game_variables[pbGet(29)] &&= 1].happiness >= 255',
    r'$player.party[$game_variables.[]=(pbGet(29), 1)].happiness >= 255',
    r'$player.party[$game_variables[pbGet(29)].replace([])].happiness >= 255',
    r'$player.party[$game_variables[pbGet(29)]].happiness = 255',
    r'$player.party[$game_variables[pbGet(29)]].happiness += 255',
    r'$player.party[$game_variables[pbGet(29)]].happiness >= foo()',
    r'$player.party[$game_variables[pbGet(0)]].happiness >= 255',
    r'$player.party[$game_variables[pbGet(5001)]].happiness >= 255',
    r'$player.party[$game_variables[pbGet(29)]].happiness >= 256',
    r'$player.party[$game_variables[pbGet(29)]].happiness >= -1',
    r'$player.party[$game_variables[pbGet(029)]].happiness >= 255',
    r'$player.party[$game_variables[pbGet(29)]].happiness >= 255'
        .replaceFirst('pbGet', 'pbGet\u00a0'),
    r'$player.party[$game_variables[pbGet(29)]].happiness >= 255'
        .replaceFirst('pbGet', 'pbGet\n'),
    '$read || $read',
    '"$read"',
    '$read # comment',
  ]) {
    test('retains the opaque writer guard for $expression', () {
      expect(recognizesSourcePartyHappinessVariableReadSyntax(expression),
          isFalse);
    });
  }
}
