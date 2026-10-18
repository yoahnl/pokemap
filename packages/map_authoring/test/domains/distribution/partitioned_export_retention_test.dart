import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../../../map_distribution/test/support/spatial_package_fixture.dart';

void main() {
  test('game projection retains definitions reached by declared dynamic references',
      () async {
    final root = await Directory.systemTemp.createTemp('l4-game-retention-');
    addTearDown(() => root.delete(recursive: true));
    final payload = spatialPayload();
    final original = ProjectManifest.fromJson(
        jsonDecode(utf8.decode(payload['project/project.json']!)));
    payload['project/assets/models3d/dynamic-model.glb'] =
        payload['project/assets/models3d/model.glb']!;
    final assets = jsonDecode(utf8.decode(
        payload['project/assets/.pokemap-assets.json']!)) as Map<String, dynamic>;
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
      original.copyWith(models3d: [
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
            CatalogDefinitionKey(CatalogDefinitionKind.model3d, 'dynamic-model'),
          ],
        ),
      ],
    );
    payload['project/project.json'] = utf8.encode(jsonEncode(project.toJson()));
    for (final entry in payload.entries) {
      final file = File('${root.path}/${entry.key.substring('project/'.length)}');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value);
    }
    final before = await File('${root.path}/project.json').readAsBytes();
    final result = await const RuntimeProjectProjectionBuilder().build(
      projectRoot: root,
      profile: GamePackageExportProfile(
        gameId: 'games.example.retention',
        gameVersion: '1.0.0',
        title: 'Retention',
        authorName: 'Avelune',
        defaultLocale: 'fr',
        supportedLocales: const ['fr'],
      ),
    );
    expect(result.project.models3d.map((model) => model.id),
        containsAll(['model', 'dynamic-model', 'unplaced']));
    expect(PortableCatalogPublication.projectDynamicDependencies(result.project)
            .map((entry) => entry.toJson()),
        PortableCatalogPublication.projectDynamicDependencies(project)
            .map((entry) => entry.toJson()));
    expect(await File('${root.path}/project.json').readAsBytes(), before);
  });
}
