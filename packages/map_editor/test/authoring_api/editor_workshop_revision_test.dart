import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/authoring_transport.dart';
import 'package:map_editor/src/application/authoring_api/editor_receipt_presenter.dart';
import 'package:path/path.dart' as p;

import '../../../map_authoring/test/domains/maps/environment_spatial_actions_test.dart'
    show environmentModelGlb, spatialEnvironmentFixture;

void main() {
  for (final action in const [
    'campaign.shop.upsert',
    'campaign.trainer.upsert',
    'map3d.instance.visibility.set',
  ]) {
    test('$action selects the canonical workshop revision in Editor', () async {
      final fixture = await _fixture();
      final visibility = action == 'map3d.instance.visibility.set';
      const condition = {'kind': 'all', 'children': <Object?>[]};
      final parameters = switch (action) {
        'campaign.shop.upsert' => <String, Object?>{
          'value': {'id': 'hiker-shop', 'label': 'Hiker shop'},
        },
        'campaign.trainer.upsert' => <String, Object?>{
          'value': {'id': 'hiker', 'name': 'Hiker', 'trainerClass': 'Ranger'},
        },
        _ => <String, Object?>{
          'mapId': 'map',
          'instanceId': 'tree-owner',
          'visibilityCondition': condition,
        },
      };
      final source = visibility ? fixture.mapFile : fixture.projectFile;
      final before = await source.readAsBytes();
      final unrelated = await fixture.unrelatedMap.readAsBytes();
      final fullRevision = await fixture.mutations.readRevision(
        fixture.root.path,
      );

      await expectLater(
        fixture.mutations.plan(
          fixture.root.path,
          actionId: action,
          parameters: parameters,
          idempotencyKey: 'stale-full',
          expectedRevision: fullRevision,
        ),
        throwsA(
          isA<EditorAuthoringMutationFailure>().having(
            (error) => error.code,
            'code',
            'plan.stale',
          ),
        ),
      );
      expect(await source.readAsBytes(), before);

      fixture.reader.readPaths.clear();
      final plan = await fixture.mutations.plan(
        fixture.root.path,
        actionId: action,
        parameters: parameters,
        idempotencyKey: 'fresh-scope',
      );
      expect(plan.snapshotRevision, isNot(fullRevision));
      final applied = await fixture.mutations.apply(
        plan,
        operationId: 'fresh-scope',
      );
      expect(applied.receipt.status, AuthoringReceiptStatus.applied);
      expect(applied.snapshotRevision, isNotNull);
      expect(applied.diagnostic, isNull);
      expect(fixture.reader.readPaths, isNot(contains('maps/unrelated.json')));
      await fixture.mutations.closeAll();
      await fixture.queries.closeAll();

      final saved = jsonDecode(await source.readAsString()) as Map;
      switch (action) {
        case 'campaign.shop.upsert':
          expect((saved['shops'] as List).single['label'], 'Hiker shop');
        case 'campaign.trainer.upsert':
          expect((saved['trainers'] as List).single['trainerClass'], 'Ranger');
        default:
          final spatial = saved['spatialScene'] as Map;
          expect(
            (spatial['instances'] as List).single['visibilityCondition'],
            condition,
          );
      }
      expect(await fixture.unrelatedMap.readAsBytes(), unrelated);
    });
  }
}

Future<
  ({
    Directory root,
    _RecordingReader reader,
    AuthoringQueryAdapter queries,
    AuthoringMutationAdapter mutations,
    File projectFile,
    File mapFile,
    File unrelatedMap,
  })
>
_fixture() async {
  final root = await Directory.systemTemp.createTemp('pmcp085-editor-scope-');
  final reader = _RecordingReader(root.path);
  final queries = AuthoringQueryAdapter(fileReader: reader);
  final mutations = AuthoringMutationAdapter(
    fileReader: reader,
    queries: queries,
    projectRoots: reader,
  );
  addTearDown(() async {
    await mutations.closeAll();
    await queries.closeAll();
    await root.delete(recursive: true);
  });
  final base = spatialEnvironmentFixture();
  final project = base.project.copyWith(
    maps: [
      ...base.project.maps,
      const ProjectMapEntry(
        id: 'unrelated',
        name: 'Unrelated',
        relativePath: 'maps/unrelated.json',
      ),
    ],
  );
  final map = base.map.copyWith(
    spatialScene: base.map.spatialScene!.copyWith(
      instances: [
        SpatialModelInstance(
          id: 'tree-owner',
          modelId: 'tree',
          position: Model3dVector3(x: 1.5, y: 0, z: 1.5),
        ),
      ],
    ),
  );
  Future<File> write(String relative, Object json) async {
    final file = File(p.join(root.path, relative));
    await file.parent.create(recursive: true);
    return file.writeAsString(jsonEncode(json));
  }

  final projectFile = await write('project.json', project.toJson());
  final mapFile = await write('maps/map.json', map.toJson());
  final unrelatedMap = await write(
    'maps/unrelated.json',
    base.map.copyWith(id: 'unrelated', name: 'Unrelated').toJson(),
  );
  final model = project.models3d.single;
  final modelBytes = environmentModelGlb();
  final artifact = ContentArtifactRef.fromBytes(
    modelBytes,
    mediaType: 'model/gltf-binary',
  );
  for (final path in [model.relativePath, assetBlobStorageKey(artifact)]) {
    final file = File(p.join(root.path, path));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(modelBytes);
  }
  await write(
    assetCatalogStorageKey,
    AssetCatalog(
      records: [
        AssetRecord(
          id: model.sourceAssetId,
          logicalPath: model.relativePath,
          artifact: artifact,
        ),
      ],
    ).toJson(),
  );
  return (
    root: root,
    reader: reader,
    queries: queries,
    mutations: mutations,
    projectFile: projectFile,
    mapFile: mapFile,
    unrelatedMap: unrelatedMap,
  );
}

final class _RecordingReader
    implements ProjectFileReader, EditorProjectRootLocator {
  _RecordingReader(this.root);

  static const _files = LocalProjectFileReader();
  final String root;
  final readPaths = <String>{};

  @override
  Future<String> canonicalizeDirectory(String path) =>
      _files.canonicalizeDirectory(path);

  @override
  Future<String> locateForResource(String resourcePath) async => root;

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) {
    readPaths.add(relativePath);
    return _files.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }
}
