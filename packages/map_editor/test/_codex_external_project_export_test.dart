import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/game_export/application/game_package_export_service.dart';
import 'package:map_editor/src/features/game_export/infrastructure/game_package_export_profile_store.dart';

void main() {
  test(
    'exports the configured external project',
    () async {
      final projectPath = Platform.environment['POKEMAP_EXTERNAL_PROJECT']!;
      final outputPath = Platform.environment['POKEMAP_EXTERNAL_OUTPUT']!;
      final projectRoot = Directory(projectPath);
      final profileStore = GamePackageExportProfileStore(
        projectRoot: projectRoot,
      );
      var profile = await profileStore.load();
      expect(profile, isNotNull);
      final requestedVersion = Platform
          .environment['POKEMAP_EXTERNAL_GAME_VERSION']
          ?.trim();
      final requestedAuthor = Platform
          .environment['POKEMAP_EXTERNAL_GAME_AUTHOR']
          ?.trim();
      if ((requestedVersion != null && requestedVersion.isNotEmpty) ||
          (requestedAuthor != null && requestedAuthor.isNotEmpty)) {
        profile = profile!.copyWith(
          gameVersion: requestedVersion,
          authorName: requestedAuthor,
        );
        await profileStore.save(profile);
      }

      final artifact = await const GamePackageExportService().exportToFile(
        projectRoot: projectRoot,
        profile: profile!,
        outputFile: File(outputPath),
      );

      expect(artifact.packageBytes, isNotEmpty);
      expect(await File(outputPath).length(), artifact.packageBytes.length);
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
