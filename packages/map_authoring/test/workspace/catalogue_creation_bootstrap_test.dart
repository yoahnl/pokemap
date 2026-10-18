import 'dart:io';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:test/test.dart';

import '../support/project_template_fixture.dart';

void main() {
  test(
      'An injected template preview describes both maps without creating a project',
      () async {
    final parent = await Directory.systemTemp.createTemp('synthetic-preview-');
    addTearDown(() => parent.delete(recursive: true));
    final api = ProjectCreationBootstrapApi(
      policy: await WorkspacePolicy.create(
        allowedRootPaths: [parent.path],
        fileReader: LocalProjectFileReader(),
      ),
      creation: LocalProjectCreationService(
          templateCatalog: SyntheticProjectTemplate().catalog),
    );
    final preview = await api.preview({
      'name': 'Mon village',
      'folderName': 'mon-village',
      'parentPath': parent.path,
      'template': 'catalogue',
      'templateId': 'alpha',
    });
    expect(preview['writes'], containsAll(['maps/', 'dialogues/']));
    expect(preview['request'], containsPair('tileSize', 32));
    expect(await parent.list().toList(), isEmpty);
  });
}
