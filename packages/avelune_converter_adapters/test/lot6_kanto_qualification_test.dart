import 'dart:io';

import 'package:test/test.dart';

import '../tool/lot6_kanto_qualification.dart' as qualification;

void main() {
  test('qualification refuses evidence outside the owned lot directory before writing', () async {
    final parent = await Directory.systemTemp.createTemp('lot6-evidence-guard-');
    addTearDown(() => parent.delete(recursive: true));
    final candidate = Directory('${parent.path}/unused-evidence');
    await expectLater(qualification.main([candidate.path]), throwsArgumentError);
    expect(await candidate.exists(), isFalse);
  });

  test('qualification refuses relative evidence paths', () async {
    await expectLater(qualification.main(['relative-evidence']), throwsArgumentError);
  });
}
