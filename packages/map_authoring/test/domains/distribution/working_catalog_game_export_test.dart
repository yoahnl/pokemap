import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../../../map_distribution/test/support/spatial_package_fixture.dart';

void main() {
  test(
      'working catalog export captures its current generation without publishing its head',
      () async {
    final root =
        await Directory.systemTemp.createTemp('working-catalog-export-');
    addTearDown(() => root.delete(recursive: true));
    for (final entry in spatialPayload().entries) {
      final file =
          File('${root.path}/${entry.key.substring('project/'.length)}');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value);
    }
    final projectFile = File('${root.path}/project.json');
    final project = ProjectManifest.fromJson(
        jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>);
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    final working = await WorkingProjectCatalog.create(
        store: store,
        projectId: 'export-test',
        project: project,
        expectedProjectRevision:
            await store.gateway.readResourceRevision('project.json'));
    final descriptorBefore = await projectFile.readAsBytes();
    final headBefore = await store.readHead();
    final profile = GamePackageExportProfile(
        gameId: 'games.example.working',
        gameVersion: '0.1.0',
        title: 'Working',
        authorName: 'Yoahn',
        defaultLocale: 'fr',
        supportedLocales: ['fr']);
    final context =
        await GamePackageExportProfileStore(projectRoot: root).read();
    expect(context.contextRevision, startsWith('sha256:'));
    final projection = await const RuntimeProjectProjectionBuilder()
        .build(projectRoot: root, profile: profile);
    expect(projection.project.name, project.name);
    expect(projection.project.models3d.map((m) => m.id),
        project.models3d.map((m) => m.id));
    expect(
        projection.payloadFiles.keys.any((path) =>
            path.endsWith('/HEAD.json') || path.endsWith('/IDENTITY.json')),
        isFalse);
    expect(
        jsonDecode(utf8
            .decode(projection.payloadFiles['project/project.json']!))['name'],
        project.name);
    final artifact = await const CanonicalGamePackageExportService().build(
      projectRoot: root,
      profile: profile,
      mode: GamePackageExportMode.localTest,
    );
    final archive = ZipDecoder().decodeBytes(artifact.packageBytes);
    final publishedDescriptor = jsonDecode(
            utf8.decode(archive.findFile('project/project.json')!.content))
        as Map<String, Object?>;
    expect(publishedDescriptor['format'], 'avelune.portable-catalog');
    final published = PortableCatalogPublication.decodeProjectSync(
        publishedDescriptor,
        readObject: (reference) => archive
            .findFile(
                'project/${PortableCatalogPublication.objectPath(reference)}')!
            .content);
    expect(published.name, project.name);
    expect(await store.readHead(), headBefore);
    expect(await projectFile.readAsBytes(), descriptorBefore);
    await working.close();
  });
}
