// TEMPORARY content-policy audit over the whole player projection.
// Runs the real GamePackageContentValidator on every payload entry so all
// violations surface in one pass instead of one per export attempt.
// Delete after use.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_editor/src/features/game_export/application/game_package_export_profile.dart';
import 'package:map_editor/src/features/game_export/application/runtime_project_projection_builder.dart';

void main() {
  test('audit projection content policy', () async {
    final root = Directory(
      '/Users/karim/Desktop/pokeMap Project/le_train_de_17h42',
    );
    final profile = GamePackageExportProfile(
      gameId: 'games.local.g6249978bbc2d9dbd766cd1205797fef2',
      gameVersion: '0.1.0',
      title: 'le train de 17h42',
      authorName: 'Projet local',
      defaultLocale: 'fr',
      supportedLocales: const ['fr'],
    );
    final projection = await const RuntimeProjectProjectionBuilder().build(
      projectRoot: root,
      profile: profile,
    );
    const validator = GamePackageContentValidator(
      GamePackageSecurityPolicy(),
    );
    final failures = <String, String>{};
    final byCode = <String, int>{};
    for (final entry in projection.payloadFiles.entries) {
      final bytes = Uint8List.fromList(entry.value);
      try {
        validator.validate(
          GamePackageFileEntry(
            path: entry.key,
            size: bytes.length,
            sha256: '0' * 64,
          ),
          bytes,
        );
      } on GamePackageFormatException catch (error) {
        failures[entry.key] = '${error.code}: ${error.message}';
        byCode.update(error.code, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    final buffer = StringBuffer()
      ..writeln('payload entries: ${projection.payloadFiles.length}')
      ..writeln('failing entries: ${failures.length}')
      ..writeln('--- by code ---');
    for (final entry in byCode.entries) {
      buffer.writeln('${entry.value.toString().padLeft(5)}  ${entry.key}');
    }
    buffer.writeln('--- entries ---');
    final keys = failures.keys.toList()..sort();
    for (final key in keys) {
      buffer.writeln('$key\n    ${failures[key]}');
    }
    File(
      '/private/tmp/claude-501/-Users-karim-Project-pokemonProject/b87054f1-b2df-44c4-beb6-5e75d36238ea/scratchpad/content_audit.txt',
    ).writeAsStringSync(buffer.toString());
    // ignore: avoid_print
    print(buffer.toString());
  }, timeout: const Timeout(Duration(minutes: 20)));
}
