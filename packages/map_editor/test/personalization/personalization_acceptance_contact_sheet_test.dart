import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/personalization_acceptance_contact_sheets.dart';

void main() {
  test('references every editor and player personalization golden once', () {
    final repositoryRoot = findPersonalizationRepositoryRoot(Directory.current);
    final referencedPaths = personalizationAcceptanceContactSheets
        .expand((sheet) => sheet.items)
        .map((item) => item.sourcePath)
        .toList(growable: false);
    final goldenPaths = <String>{
      ..._goldensIn(
        repositoryRoot,
        'packages/map_editor/test/personalization/goldens/personalization',
      ),
      ..._goldensIn(
        repositoryRoot,
        'packages/map_player_ui/test/player/goldens/player_personalization',
      ),
    };

    expect(personalizationAcceptanceContactSheets, hasLength(6));
    expect(
      personalizationAcceptanceContactSheets.every(
        (sheet) => sheet.items.length == 6,
      ),
      isTrue,
    );
    expect(referencedPaths, hasLength(36));
    expect(referencedPaths.toSet(), hasLength(36));
    expect(referencedPaths.toSet(), goldenPaths);
  });

  test('generates readable contact sheets for every acceptance group', () {
    final repositoryRoot = findPersonalizationRepositoryRoot(Directory.current);
    final outputDirectory = Directory.systemTemp.createTempSync(
      'pokemap-personalization-contact-sheets-',
    );
    addTearDown(() => outputDirectory.deleteSync(recursive: true));

    final outputs = buildPersonalizationAcceptanceContactSheets(
      repositoryRoot: repositoryRoot,
      outputDirectory: outputDirectory,
    );

    expect(outputs, hasLength(6));
    for (final output in outputs) {
      expect(output.existsSync(), isTrue);
      expect(output.lengthSync(), greaterThan(1000));
    }
  });
}

Set<String> _goldensIn(Directory repositoryRoot, String relativeDirectory) {
  final directory = Directory('${repositoryRoot.path}/$relativeDirectory');
  return directory
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.png'))
      .map((file) => file.path.substring(repositoryRoot.path.length + 1))
      .toSet();
}
