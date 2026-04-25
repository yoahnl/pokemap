import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/tools/export_pokemon_sdk_studio_catalog_cli.dart';

void main() {
  group('ExportPokemonSdkStudioCatalogCli', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('psdk_catalog_cli_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('prints converted PSDK Studio moves catalog as formatted JSON',
        () async {
      _writeMove(tempDir, '001_tackle.json', _tacklePayload);
      final stdout = StringBuffer();
      final stderr = StringBuffer();

      final exitCode = await ExportPokemonSdkStudioCatalogCli(
        stdout: stdout,
        stderr: stderr,
      ).run(<String>[
        '--project-root',
        tempDir.path,
        '--catalog',
        'moves',
      ]);

      expect(exitCode, 0);
      expect(stderr.toString(), isEmpty);
      expect(stdout.toString(), contains('\n  "schemaVersion": 1'));
      final decoded = jsonDecode(stdout.toString()) as Map<String, dynamic>;
      expect(decoded['catalog'], 'moves');
      expect(
        ((decoded['meta'] as Map<String, dynamic>)['sourcePriority'] as List),
        contains('pokemon_sdk_studio'),
      );
      expect(
        ((decoded['entries'] as List).single as Map<String, dynamic>)['id'],
        'tackle',
      );
    });

    test('writes converted catalog to output when provided', () async {
      _writeMove(tempDir, '001_tackle.json', _tacklePayload);
      final outputFile = File('${tempDir.path}/out/catalogs/moves.json');
      final stdout = StringBuffer();
      final stderr = StringBuffer();

      final exitCode = await ExportPokemonSdkStudioCatalogCli(
        stdout: stdout,
        stderr: stderr,
      ).run(<String>[
        '--project-root',
        tempDir.path,
        '--catalog',
        'moves',
        '--output',
        outputFile.path,
      ]);

      expect(exitCode, 0);
      expect(stderr.toString(), isEmpty);
      expect(stdout.toString(), contains('Wrote 1 moves'));
      expect(outputFile.existsSync(), isTrue);
      final decoded =
          jsonDecode(outputFile.readAsStringSync()) as Map<String, dynamic>;
      expect(decoded['catalog'], 'moves');
      expect((decoded['entries'] as List), hasLength(1));
    });

    test('rejects missing project root with a usage error', () async {
      final stdout = StringBuffer();
      final stderr = StringBuffer();

      final exitCode = await ExportPokemonSdkStudioCatalogCli(
        stdout: stdout,
        stderr: stderr,
      ).run(const <String>[]);

      expect(exitCode, 64);
      expect(stdout.toString(), isEmpty);
      expect(stderr.toString(), contains('--project-root'));
    });

    test('returns a data error when Data/Studio is missing', () async {
      final stdout = StringBuffer();
      final stderr = StringBuffer();

      final exitCode = await ExportPokemonSdkStudioCatalogCli(
        stdout: stdout,
        stderr: stderr,
      ).run(<String>[
        '--project-root',
        tempDir.path,
      ]);

      expect(exitCode, 65);
      expect(stdout.toString(), isEmpty);
      expect(stderr.toString(), contains('Data/Studio'));
    });
  });
}

void _writeMove(
  Directory root,
  String fileName,
  Map<String, Object?> payload,
) {
  final file = File('${root.path}/Data/Studio/moves/$fileName')
    ..createSync(recursive: true);
  file.writeAsStringSync(jsonEncode(payload));
}

const Map<String, Object?> _tacklePayload = <String, Object?>{
  'dbSymbol': 'tackle',
  'name': 'Tackle',
  'type': 'normal',
  'category': 'physical',
  'power': 40,
  'accuracy': 100,
  'pp': 35,
  'battleEngineMethod': 's_basic',
  'battleEngineAimedTarget': 'adjacent_foe',
};
