import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'production personalization contains no demo fixture or false claim',
    () {
      final sourceFiles =
          <String>[
            'lib/src/features/personalization',
            '../map_player_ui/lib',
            '../../apps/pokemap_hub/lib',
            '../../examples/playable_runtime_host/lib',
          ].expand(
            (path) => Directory(path)
                .listSync(recursive: true)
                .whereType<File>()
                .where((file) => file.path.endsWith('.dart')),
          );
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
