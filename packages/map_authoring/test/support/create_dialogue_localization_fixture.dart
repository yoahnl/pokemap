import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring.dart';

Future<void> main(List<String> arguments) async {
  final root = Directory(arguments.single);
  await Directory('${root.path}/dialogues').create(recursive: true);
  const entry = ProjectDialogueEntry(
      id: 'talk', name: 'Accueil', relativePath: 'dialogues/talk.yarn');
  const project = ProjectManifest(
      name: 'Langues', maps: [], tilesets: [], dialogues: [entry]);
  final store = await CatalogStorageStore.open(projectRoot: root.path);
  await WorkingProjectCatalog.create(
      store: store, projectId: 'dialogue-localization', project: project);
  await store.prepareLocalEditing();
  await File('${root.path}/${entry.relativePath}')
      .writeAsString('title: Start\n---\nBonjour\n===\n');
}
