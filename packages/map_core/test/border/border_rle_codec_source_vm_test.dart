@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('RLE scanner source keeps validation and fill free of per-run objects',
      () {
    final source = File(
      'lib/src/operations/border_rle_codec.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('class _DecimalField')));
    expect(source, isNot(contains('_DecimalField ')));
    expect(source, isNot(contains('onRun')));
    expect(source, isNot(contains('void Function(int offset')));
    expect(source, isNot(contains('expectedLength.toString()')));
    expect(source, isNot(contains('.split(')));
    expect(source, isNot(contains('_packDecimalField')));
    expect(source, isNot(contains('_packedField')));
    expect(source, contains('List<bool>? decoded'));
  });
}
