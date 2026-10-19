import 'dart:io';

import 'package:test/test.dart';

import '../tool/lot6_kanto_qualification.dart' as qualification;

void main() {
  test('qualification refuses evidence outside the owned lot directory before writing', () async {
    final parent = await Directory.systemTemp.createTemp('lot6-evidence-guard-');
    addTearDown(() => parent.delete(recursive: true));
    final candidate = Directory('${parent.path}/unused-evidence');
    for (final scope in ['world', 'full']) {
      await expectLater(qualification.main([candidate.path, scope]), throwsArgumentError);
    }
    expect(await candidate.exists(), isFalse);
  });

  test('qualification refuses relative evidence paths', () async {
    await expectLater(qualification.main(['relative-evidence', 'world']), throwsArgumentError);
  });

  test('qualification requires a known explicit content scope', () async {
    for (final args in [<String>[], ['relative-evidence'], ['relative-evidence', 'unknown']]) {
      await expectLater(qualification.main(args), throwsArgumentError);
    }
  });

  test('qualification refuses unsafe destination names before writing', () async {
    for (final folder in ['', ' ', '.', '..', '../Kanto', 'Kanto/part', r'Kanto\part', '/Kanto', ' Kanto', 'Kanto\u0000']) {
      await expectLater(qualification.main(['/unused-evidence', 'full', folder]), throwsArgumentError);
    }
  });
}
