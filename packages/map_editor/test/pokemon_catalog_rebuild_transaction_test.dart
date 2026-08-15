import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/pokemon_catalog_rebuild_transaction.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'replaces only catalog directories and keeps a recoverable backup',
    () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'pokemon_catalog_rebuild_transaction_',
      );
      addTearDown(() => sandbox.delete(recursive: true));

      final project = Directory(p.join(sandbox.path, 'project'));
      final staging = Directory(p.join(sandbox.path, 'staging'));
      final backup = Directory(p.join(sandbox.path, 'backup'));
      await _writeMarker(project, 'data/pokemon', 'old-data');
      await _writeMarker(project, 'assets/pokemon', 'old-assets');
      await _writeMarker(staging, 'data/pokemon', 'new-data');
      await _writeMarker(staging, 'assets/pokemon', 'new-assets');

      final result = await const PokemonCatalogRebuildTransaction().replace(
        projectDirectory: project,
        stagingDirectory: staging,
        backupDirectory: backup,
      );

      expect(result.backupDirectory.path, backup.path);
      expect(await _readMarker(project, 'data/pokemon'), 'new-data');
      expect(await _readMarker(project, 'assets/pokemon'), 'new-assets');
      expect(await _readMarker(backup, 'data/pokemon'), 'old-data');
      expect(await _readMarker(backup, 'assets/pokemon'), 'old-assets');
    },
  );

  test(
    'rejects an incomplete staging catalog before touching the project',
    () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'pokemon_catalog_rebuild_transaction_',
      );
      addTearDown(() => sandbox.delete(recursive: true));

      final project = Directory(p.join(sandbox.path, 'project'));
      final staging = Directory(p.join(sandbox.path, 'staging'));
      final backup = Directory(p.join(sandbox.path, 'backup'));
      await _writeMarker(project, 'data/pokemon', 'old-data');
      await _writeMarker(project, 'assets/pokemon', 'old-assets');
      await _writeMarker(staging, 'data/pokemon', 'new-data');

      await expectLater(
        const PokemonCatalogRebuildTransaction().replace(
          projectDirectory: project,
          stagingDirectory: staging,
          backupDirectory: backup,
        ),
        throwsA(isA<FileSystemException>()),
      );

      expect(await _readMarker(project, 'data/pokemon'), 'old-data');
      expect(await _readMarker(project, 'assets/pokemon'), 'old-assets');
      expect(await backup.exists(), isFalse);
    },
  );

  test('catalog gate requires every National Dex id through generation 6', () {
    final gate = PokemonCatalogRebuildGate(
      firstNationalDex: 1,
      lastNationalDex: 721,
    );
    final completeIds = <int>{for (var value = 1; value <= 721; value++) value};

    expect(
      gate.validate(
        nationalDexIds: completeIds,
        speciesIds: <String>{
          for (var value = 1; value <= 721; value++) 'p$value',
        },
        learnsetIds: <String>{
          for (var value = 1; value <= 721; value++) 'p$value',
        },
        evolutionIds: <String>{
          for (var value = 1; value <= 721; value++) 'p$value',
        },
        mediaIds: <String>{
          for (var value = 1; value <= 721; value++) 'p$value',
        },
        coherenceReport: PokemonCatalogCoherenceReport(const []),
      ),
      isEmpty,
    );
  });

  test('catalog gate reports missing documents and coherence errors', () {
    final gate = PokemonCatalogRebuildGate(
      firstNationalDex: 1,
      lastNationalDex: 3,
    );

    final issues = gate.validate(
      nationalDexIds: const <int>{1, 2},
      speciesIds: const <String>{'a', 'b'},
      learnsetIds: const <String>{'a'},
      evolutionIds: const <String>{'a', 'b'},
      mediaIds: const <String>{'a', 'b'},
      coherenceReport: PokemonCatalogCoherenceReport(<PokemonCatalogDiagnostic>[
        const PokemonCatalogDiagnostic(
          code: 'broken.reference',
          severity: PokemonCatalogDiagnosticSeverity.error,
          path: 'data/pokemon/species/a.json',
          message: 'Broken reference.',
          recommendedAction: 'Fix it.',
        ),
      ]),
    );

    expect(issues, contains('National Dex ids missing: 3'));
    expect(issues, contains('Learnset documents: expected 2, found 1'));
    expect(issues, contains('Pokemon coherence errors: 1'));
  });
}

Future<void> _writeMarker(
  Directory root,
  String relativeDirectory,
  String value,
) async {
  final directory = Directory(p.join(root.path, relativeDirectory));
  await directory.create(recursive: true);
  await File(p.join(directory.path, 'marker.txt')).writeAsString(value);
}

Future<String> _readMarker(Directory root, String relativeDirectory) {
  return File(
    p.join(root.path, relativeDirectory, 'marker.txt'),
  ).readAsString();
}
