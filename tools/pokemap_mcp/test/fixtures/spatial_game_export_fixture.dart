import 'dart:io';

import 'package:map_authoring/map_authoring.dart';

import '../../../../packages/map_distribution/test/support/spatial_package_fixture.dart';

Future<void> main(List<String> args) async {
  final root = Directory(args.first).absolute;
  for (final entry in spatialPayload().entries) {
    final file = File('${root.path}/${entry.key.substring(8)}');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(entry.value);
  }
  await GamePackageExportProfileStore(projectRoot: root).save(
    GamePackageExportProfile(
      gameId: 'games.example.spatial-export',
      gameVersion: args.length > 1 ? args[1] : '0.1.0',
      title: 'Exploration MCP',
      authorName: 'Yoahn',
      defaultLocale: 'fr',
      supportedLocales: ['fr'],
    ),
  );
}
