import 'dart:io';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:test/test.dart';

void main() {
  test('Clairbois preview describes both maps without creating a project',
      () async {
    final parent = await Directory.systemTemp.createTemp('clairbois-preview-');
    addTearDown(() => parent.delete(recursive: true));
    final api = ProjectCreationBootstrapApi(
      policy: await WorkspacePolicy.create(
        allowedRootPaths: [parent.path],
        fileReader: LocalProjectFileReader(),
      ),
      creation: const LocalProjectCreationService(),
    );
    final preview = await api.preview({
      'name': 'Mon village',
      'folderName': 'mon-village',
      'parentPath': parent.path,
      'template': 'clairbois',
    });
    expect(preview['writes'],
        containsAll(['maps/first-map.json', 'maps/maison.json']));
    expect(preview['request'], containsPair('tileSize', 32));
    expect(await parent.list().toList(), isEmpty);
  });
}
