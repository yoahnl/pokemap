import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';

import 'resource_fixture.dart';

Future<Map<String, List<int>>> _files(Directory directory) async => {
  for (final entity in await directory.list(recursive: true).toList())
    if (entity is File)
      entity.path.substring(directory.path.length): await entity.readAsBytes(),
};

void main() {
  test(
    'resource preview is read only and normalized no-op preserves author data',
    () async {
      final fixture = await ResourceFixture.create();
      addTearDown(fixture.dispose);
      final imported = await fixture.import();
      final tileset = imported.manifest.tilesets.single;
      final before = await _files(fixture.root);
      final prepared = await fixture.resources
          .prepareOperation('tileset.metadata.update', {
            'tilesetId': tileset.id,
            'name': ' ${tileset.name} ',
            'folderId': tileset.folderId,
          });
      expect(prepared.noChange, true);
      expect(await _files(fixture.root), before);
      final result = await fixture.resources.applyPrepared(prepared);
      expect(result.noChange, true);
      expect(result.revision, result.beforeRevision);
      expect(await fixture.manifestFile.readAsBytes(), before['/project.json']);
      expect(await fixture.mapFile.readAsBytes(), before['/garden.json']);
      expect(
        await File(
          '${fixture.root.path}/${tileset.relativePath}',
        ).readAsBytes(),
        before['/${tileset.relativePath}'],
      );
    },
  );

  test('prepared folder parameters retain captured nested intention', () async {
    final fixture = await ResourceFixture.create();
    addTearDown(fixture.dispose);
    final folder = <String, Object?>{'id': 'nature', 'name': 'Nature'};
    final prepared = await fixture.resources.prepareOperation(
      'tileset_folder.upsert',
      {'folder': folder},
    );
    folder['name'] = 'Modification sans nouvel aperçu';
    expect((prepared.parameters['folder'] as Map)['name'], 'Nature');
    expect(
      () => (prepared.parameters['folder'] as Map)['name'] = 'Mutation',
      throwsUnsupportedError,
    );
    await fixture.resources.applyPrepared(prepared);
    final reopened = await fixture.maps.loadProject(fixture.session);
    expect(reopened.tilesetFolders.single.name, 'Nature');
  });

  test('prepared metadata rejects stale project and duplicate apply', () async {
    final fixture = await ResourceFixture.create();
    addTearDown(fixture.dispose);
    final imported = await fixture.import();
    final tileset = imported.manifest.tilesets.single;
    final stale = await fixture.resources.prepareOperation(
      'tileset.metadata.update',
      {'tilesetId': tileset.id, 'name': 'Nom prévu', 'folderId': null},
    );
    final original =
        jsonDecode(await fixture.manifestFile.readAsString()) as Map;
    original['name'] = 'Auteur externe';
    await fixture.manifestFile.writeAsString(jsonEncode(original));
    final external = await fixture.manifestFile.readAsBytes();
    await expectLater(
      fixture.resources.applyPrepared(stale),
      throwsA(isA<ResourceFailure>()),
    );
    expect(await fixture.manifestFile.readAsBytes(), external);
    await fixture.maps.loadProject(fixture.session);
    final fresh = await fixture.resources.prepareOperation(
      'tileset.metadata.update',
      {'tilesetId': tileset.id, 'name': 'Nom prévu', 'folderId': null},
    );
    await fixture.resources.applyPrepared(fresh);
    final published = await fixture.manifestFile.readAsBytes();
    await expectLater(
      fixture.resources.applyPrepared(fresh),
      throwsA(isA<ResourceFailure>()),
    );
    expect(await fixture.manifestFile.readAsBytes(), published);
  });

  test('another session cannot apply this preparation', () async {
    final fixture = await ResourceFixture.create();
    addTearDown(fixture.dispose);
    final other = await ResourceFixture.create();
    addTearDown(other.dispose);
    final prepared = await fixture.resources.prepareOperation(
      'tileset_folder.upsert',
      {
        'folder': {'id': 'nature', 'name': 'Nature'},
      },
    );
    final before = await other.manifestFile.readAsBytes();
    await expectLater(
      other.resources.applyPrepared(prepared),
      throwsA(isA<ResourceFailure>()),
    );
    expect(await other.manifestFile.readAsBytes(), before);
  });
}
