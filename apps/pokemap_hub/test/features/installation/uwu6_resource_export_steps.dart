import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../avelune_studio/test/support/m2_ui_fixture.dart';
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
  await tester.tap(find.text('Utiliser un chemin exact'));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.enterText(
    find.widgetWithText(TextField, 'Dossier du projet'),
    directory.path,
  );
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await pumpIo(tester, frames: 35);
  expect(exporter.session.state.project!.directoryPath, directory.path);
  await tester.tap(find.text('Accueil'));
  await pumpIo(tester, frames: 12);
  await tester.tap(find.text('Exporter le jeu…'));
  await pumpIo(tester, frames: 12);
  await tester.enterText(
    find.widgetWithText(TextField, 'Auteur'),
    'Recette UwU VI',
  );
  await tester.tap(find.text('Test local').first);
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('start-game-export')));
  await pumpIo(tester, frames: 3);
  final owner =
      tester
          .widget<MapWorkspaceScreen>(find.byType(MapWorkspaceScreen))
          .gameExport!;
  print(
    'UWU6_RESOURCE_EXPORT_START stage=${owner.stage} busy=${owner.busy} canStart=${owner.canStart} error=${owner.error}',
  );
  for (var i = 0; i < 200 && owner.outputPath == null; i++) {
    await pumpIo(tester, frames: 2);
    if (owner.error != null) break;
  }
  expect(owner.outputPath, host.package.path, reason: owner.error);
  await tester.pumpWidget(const SizedBox());
  await exporter.dispose();
  expect(exporter.session.state.project, isNull);
  print(
    'UWU6_RESOURCE_EXPORT_UI=${host.package.path} authorSessionsClosed=true',
  );
}
