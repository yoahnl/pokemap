import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Converter depends on the canonical design system without Studio', () {
    final specification = File('../avelune_converter/pubspec.yaml')
        .readAsStringSync();
    expect(specification, isNot(contains('  avelune_studio:')));
    expect(specification, contains('  avelune_design_system:'));
  });

}
