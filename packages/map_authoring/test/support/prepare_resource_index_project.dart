import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

Future<void> main(List<String> arguments) async {
  final root = await Directory(arguments.single).resolveSymbolicLinks();
  if (!root.contains('/Library/Caches/AveluneQA/resource-inverse-index/')) {
    throw StateError('Use the owned resource index QA project.');
  }
  final store = await CatalogStorageStore.open(projectRoot: root);
  final revision = await store.gateway.readResourceRevision('project.json');
  final json = Map<String, dynamic>.from(
      jsonDecode(await File('$root/project.json').readAsString()) as Map);
  if (json['format'] == 'avelune.working-catalog') return;
  final working = await WorkingProjectCatalog.create(
      store: store,
      projectId: 'resource-index-native',
      project: ProjectManifest.fromJson(json),
      expectedProjectRevision: revision);
  await working.close();
}
