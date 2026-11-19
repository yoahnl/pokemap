import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../../../map_distribution/test/support/spatial_package_fixture.dart';

void main() {
  test(
      'game projection retains definitions reached by declared dynamic references',
      () async {
    final root = await Directory.systemTemp.createTemp('l4-game-retention-');
    addTearDown(() => root.delete(recursive: true));
    final payload = spatialPayload();
    final original = ProjectManifest.fromJson(
        jsonDecode(utf8.decode(payload['project/project.json']!)));
    payload['project/assets/models3d/dynamic-model.glb'] =
        payload['project/assets/models3d/model.glb']!;
    final assets =
        jsonDecode(utf8.decode(payload['project/assets/.pokemap-assets.json']!))
            as Map<String, dynamic>;
    final records = assets['records'] as List<dynamic>;
    records.add({
      ...Map<String, dynamic>.from(records.first as Map),
      'id': 'dynamic-source',
      'logicalPath': 'assets/models3d/dynamic-model.glb',
    });
    payload['project/assets/.pokemap-assets.json'] =
        utf8.encode(jsonEncode(assets));
    payload['project/assets/models3d/unplaced.glb'] =
        payload['project/assets/models3d/model.glb']!;
    records.add({
      ...Map<String, dynamic>.from(records.first as Map),
      'id': 'unplaced-source',
      'logicalPath': 'assets/models3d/unplaced.glb',
    });
    payload['project/assets/.pokemap-assets.json'] =
        utf8.encode(jsonEncode(assets));
    final project = PortableCatalogPublication.withProjectDynamicDependencies(
      original.copyWith(resourcePackInstallations: _installation(), models3d: [
        ...original.models3d,
        ProjectModel3dEntry.fromJson({
          ...original.models3d.single.toJson(),
          'id': 'dynamic-model',
          'name': 'Dynamic',
          'relativePath': 'assets/models3d/dynamic-model.glb',
          'sourceAssetId': 'dynamic-source',
        }),
        ProjectModel3dEntry.fromJson({
          ...original.models3d.single.toJson(),
          'id': 'unplaced',
          'relativePath': 'assets/models3d/unplaced.glb',
          'sourceAssetId': 'unplaced-source',
        }),
      ]),
      [
        CatalogDynamicDependency(
          owner: CatalogDefinitionKey(CatalogDefinitionKind.model3d, 'model'),
          targets: [
            CatalogDefinitionKey(
                CatalogDefinitionKind.model3d, 'dynamic-model'),
          ],
        ),
      ],
    );
    payload['project/project.json'] = utf8.encode(jsonEncode(project.toJson()));
    for (final entry in payload.entries) {
      final file =
          File('${root.path}/${entry.key.substring('project/'.length)}');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value);
    }
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    final working = await WorkingProjectCatalog.create(
      store: store,
      projectId: 'retention',
      project: project,
      expectedProjectRevision:
          await store.gateway.readResourceRevision('project.json'),
    );
    addTearDown(working.close);
    final descriptor = File('${root.path}/project.json');
    final before = await descriptor.readAsBytes();
    final head = await store.readHead();
    final result = await const CanonicalGamePackageExportService().build(
      projectRoot: root,
      mode: GamePackageExportMode.localTest,
      profile: GamePackageExportProfile(
        gameId: 'games.example.retention',
        gameVersion: '1.0.0',
        title: 'Retention',
        authorName: 'Avelune',
        defaultLocale: 'fr',
        supportedLocales: const ['fr'],
      ),
    );
    final archive = ZipDecoder().decodeBytes(result.packageBytes, verify: true);
    final exported = PortableCatalogPublication.decodeProjectSync(
      jsonDecode(
          utf8.decode(archive.findFile('project/project.json')!.content)),
      readObject: (ref) => archive
          .findFile('project/${PortableCatalogPublication.objectPath(ref)}')!
          .content,
    );
    expect(exported.models3d.map((model) => model.id),
        unorderedEquals(['model', 'dynamic-model']));
    expect(archive.findFile('project/assets/models3d/unplaced.glb'), isNull);
    expect(
        archive.findFile('project/assets/models3d/dynamic-model.glb')!.content,
        payload['project/assets/models3d/dynamic-model.glb']);
    expect(
        PortableCatalogPublication.projectDynamicDependencies(exported)
            .map((entry) => entry.toJson()),
        PortableCatalogPublication.projectDynamicDependencies(project)
            .map((entry) => entry.toJson()));
    expect(
        exported.resourcePackInstallations, project.resourcePackInstallations);
    expect(await descriptor.readAsBytes(), before);
    expect(await store.readHead(), head);
  });
}

ResourcePackInstallationCatalog _installation() {
  final source = ResourcePackRef(kind: ResourcePackKind.model3d, id: 'source');
  return ResourcePackInstallationCatalog(entries: [
    ResourcePackInstallation(
      installationId: 'fixture',
      packId: 'avelune.fixture',
      packVersion: '1.0.0',
      universeId: 'avelune.test',
      archiveRawSha256: 'a' * 64,
      catalogRawSha256: 'b' * 64,
      copyOrdinal: 0,
      selectedRoots: [source],
      resources: [
        ResourcePackResourceMapping(
            source: source,
            targetId: 'unplaced',
            definitionRawSha256: 'c' * 64),
      ],
      supports: [],
      assets: [],
      origins: [],
      licenses: [],
      installedAtUtc: '2026-10-18T10:00:00.000Z',
      provenanceStatus: ResourcePackProvenanceStatus.declared,
    ),
  ]);
}
