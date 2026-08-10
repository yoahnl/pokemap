import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('personalization feature never imports map_runtime', () {
    final feature = Directory('lib/src/features/personalization');
    final offenders = feature
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where(
          (file) => file.readAsStringSync().contains('package:map_runtime'),
        )
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
  });
}
