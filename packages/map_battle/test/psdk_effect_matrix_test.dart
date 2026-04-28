import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('effect matrix exposes hook families for PSDK migration gates', () {
    final matrix = File('../../reports/previous/psdk-effect-porting-matrix.md');

    expect(matrix.existsSync(), isTrue);
    final content = matrix.readAsStringSync();

    expect(content, contains('| Hook families |'));
    expect(content, contains('`Attract`'));
    expect(content, contains('`HealBlock`'));
    expect(content, contains('`Imprison`'));
    expect(content, contains('`Protect`'));
    expect(content, contains('`Disable`'));
    expect(content, contains('`Encore`'));
    expect(content, contains('`Taunt`'));
    expect(content, contains('`Torment`'));
    expect(content, contains('`move_prevention`'));
    expect(content, contains('`ability_immunity`'));
    expect(content, contains('`accuracy`'));
    expect(content, contains('`two_turn_shortcut`'));
    expect(content, contains('Object-backed ProtectEffect'));
    expect(content, contains('Object-backed AttractEffect'));
    expect(content, contains('Object-backed DisableEffect'));
    expect(content, contains('Object-backed EncoreEffect'));
    expect(content, contains('Object-backed HealBlockEffect'));
    expect(content, contains('Object-backed ImprisonEffect'));
    expect(content, contains('Object-backed TauntEffect'));
    expect(content, contains('Object-backed TormentEffect'));
  });
}
