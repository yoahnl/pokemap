import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('effect matrix exposes hook families for PSDK migration gates', () {
    final matrix = File('../../reports/psdk-effect-porting-matrix.md');

    expect(matrix.existsSync(), isTrue);
    final content = matrix.readAsStringSync();

    expect(content, contains('| Hook families |'));
    expect(content, contains('`Protect`'));
    expect(content, contains('`move_prevention`'));
    expect(content, contains('`ability_immunity`'));
    expect(content, contains('`accuracy`'));
    expect(content, contains('`two_turn_shortcut`'));
    expect(content, contains('Object-backed ProtectEffect'));
  });
}
