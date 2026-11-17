import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring.dart';

import '../../../map_distribution/test/support/spatial_package_fixture.dart';

Future<void> main(List<String> arguments) async {
  final root = Directory(arguments.single);
  await Directory('${root.path}/dialogues').create(recursive: true);
  const entry = ProjectDialogueEntry(
      id: 'talk', name: 'Accueil', relativePath: 'dialogues/talk.yarn');
  final files = spatialPayload();
  final project = ProjectManifest.fromJson(
          jsonDecode(utf8.decode(files.remove('project/project.json')!)))
      .copyWith(name: 'Langues', dialogues: [entry]);
  for (final entry in files.entries) {
    final file = File('${root.path}/${entry.key.substring(8)}');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(entry.value);
  }
  final store = await CatalogStorageStore.open(projectRoot: root.path);
  await WorkingProjectCatalog.create(
      store: store, projectId: 'dialogue-localization', project: project);
  await store.prepareLocalEditing();
  await File('${root.path}/${entry.relativePath}')
      .writeAsString('title: Start\n---\nBonjour\n===\n');
  await GamePackageExportProfileStore(projectRoot: root).save(
      GamePackageExportProfile(
          gameId: 'games.example.localized-mcp',
          gameVersion: '0.1.0',
          title: 'Langues',
          authorName: 'Yoahn',
          defaultLocale: 'fr',
          supportedLocales: ['fr', 'en']));
}
