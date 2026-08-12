import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'production personalization contains no demo fixture or false claim',
    () {
      final sourceFiles = Directory('lib/src/features/personalization')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));
      final sources = <String, String>{
        for (final file in sourceFiles) file.path: file.readAsStringSync(),
      };

      for (final entry in sources.entries) {
        for (final forbidden in <String>[
          'PersonalizationPreviewFixtures',
          'PersonalizationCharacterPreviewFixtureSource',
          'Professeure Saule',
          'Roucool',
          'Brindibou',
          'Preview réelle',
        ]) {
          expect(
            entry.value,
            isNot(contains(forbidden)),
            reason: '${entry.key} contains $forbidden',
          );
        }
      }
    },
  );
}
