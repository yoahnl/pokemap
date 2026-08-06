// TEMPORARY end-to-end export probe. Delete after use.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/game_export/application/game_package_export_profile.dart';
import 'package:map_editor/src/features/game_export/application/game_package_export_service.dart';

void main() {
  test('export the real project', () async {
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
    late final artifact;
    try {
      artifact = await const GamePackageExportService().build(
        projectRoot: root,
        profile: profile,
      );
    } on GamePackageExportException catch (error) {
      // ignore: avoid_print
      print('FAILED code=${error.code} path=${error.path}');
      // ignore: avoid_print
      print('message=${error.message}');
      // ignore: avoid_print
      print('cause=${error.cause}');
      rethrow;
    }
    // ignore: avoid_print
    print('certified=${artifact.certification.isCertified}');
    // ignore: avoid_print
    print('diagnostics=${artifact.certification.diagnostics}');
    // ignore: avoid_print
    print('file=${artifact.suggestedFileName}');
    // ignore: avoid_print
    print('bytes=${artifact.packageBytes.length}');
    // ignore: avoid_print
    print('manifestTitle=${artifact.manifest.title}');
    // ignore: avoid_print
    print('dialogues=${artifact.compiledDialogueCount}');
    // ignore: avoid_print
    print('scrubbedSecrets=${artifact.scrubbedSecretFieldCount}');
    expect(artifact.certification.isCertified, isTrue);
  }, timeout: const Timeout(Duration(minutes: 15)));
}
