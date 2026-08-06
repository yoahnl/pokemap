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
      final profile = await GamePackageExportProfileStore(
        projectRoot: projectRoot,
      ).load();
      expect(profile, isNotNull);

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
