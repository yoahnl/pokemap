import 'package:avelune_studio/features/game_export/domain/studio_game_export_port.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../avelune_studio/test/support/project_creation_workspace_fixture.dart';
import 'uwu6_resource_host.dart';

Future<void> exportUwu6Resources(Uwu6ResourceHost host) async {
  final tester = host.tester;
  final directory = host.fixture.directory;
  await tester.pumpWidget(const SizedBox());
  await host.close();
  final exporter = ProjectCreationWorkspaceFixture(
    tester,
    host.temporary,
    host.package,
  );
  addTearDown(exporter.dispose);
  await exporter.mount(size: const Size(1536, 1024));
  expect(await exporter.openExisting(directory.path), isTrue);
  expect(exporter.session.state.project!.directoryPath, directory.path);
  expect(
    await exporter.exportPackage(
      metadata: StudioGameExportMetadata(
        gameId: 'games.avelune.recette-ressources-uwu-vi',
        title: exporter.gameExport!.projectName,
        version: '0.1.0',
        author: 'Recette UwU VI',
        locale: 'fr',
        locales: 'fr',
      ),
    ),
    isTrue,
    reason: exporter.gameExport!.error,
  );
  expect(
    exporter.gameExport!.outputPath,
    host.package.path,
    reason: exporter.gameExport!.error,
  );
  await tester.pumpWidget(const SizedBox());
  await exporter.dispose();
  expect(exporter.session.state.project, isNull);
  print(
    'UWU6_RESOURCE_EXPORT_CONTROLLER=${host.package.path} authorSessionsClosed=true',
  );
}
