// TEMPORARY projection inventory probe. Delete after use.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/game_export/application/game_package_export_profile.dart';
import 'package:map_editor/src/features/game_export/application/runtime_project_projection_builder.dart';

void main() {
  test('list projection payload files', () async {
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
    final keys = projection.payloadFiles.keys.toList()..sort();
    File(
      '/private/tmp/claude-501/-Users-karim-Project-pokemonProject/b87054f1-b2df-44c4-beb6-5e75d36238ea/scratchpad/projection_files.txt',
    ).writeAsStringSync(keys.join('\n'));
    // ignore: avoid_print
    print('payload files: ${keys.length}');
  }, timeout: const Timeout(Duration(minutes: 15)));
}
