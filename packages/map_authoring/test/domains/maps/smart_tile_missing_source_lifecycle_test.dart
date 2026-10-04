import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'smart_tile_lifecycle_api_test.dart'
    show independentRead, lifecycleFixture;

void main() {
  test('terrain metadata and copy preserve a missing logical source', () async {
    final fixture = await lifecycleFixture();
    addTearDown(fixture.dispose);
    final original = await independentRead(fixture);
    final projectFile = File('${fixture.root.path}/project.json');
    Future<Map<String, dynamic>> unrelatedFields() async =>
        jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>
          ..remove('smartTileCatalog')
          ..remove('version');
    final unrelatedBefore = await unrelatedFields();
    final source = File('${fixture.root.path}/assets/source.png');
    final artifact = ContentArtifactRef.fromBytes(await source.readAsBytes(),
        mediaType: 'image/png');
    final blob = File('${fixture.root.path}/${assetBlobStorageKey(artifact)}');
    final blobBefore = await blob.readAsBytes();
    final catalog = File('${fixture.root.path}/$assetCatalogStorageKey');
    final catalogBefore = await catalog.readAsBytes();
    await source.delete();

    await fixture.mutate('smart_tile.preset.rename',
        {'presetId': 'ground', 'name': 'Chemin sans copie PNG'});
    await fixture.mutate('smart_tile.preset.duplicate', {
      'presetId': 'ground',
      'newDraftId': 'copy-draft',
      'targetPresetId': 'copy',
      'name': 'Copie indépendante'
    });

    final reopened = await independentRead(fixture);
    expect(
        reopened.smartTileCatalog.presets.single,
        original.smartTileCatalog.presets.single
            .copyWith(name: 'Chemin sans copie PNG'));
    expect(
        reopened.smartTileCatalog.drafts
            .firstWhere((item) => item.id == 'editing'),
        original.smartTileCatalog.drafts.single
            .copyWith(name: 'Chemin sans copie PNG'));
    final copy = reopened.smartTileCatalog.drafts
        .firstWhere((item) => item.id == 'copy-draft');
    expect(copy.sourcePresetId, isNull);
    expect(copy.targetPresetId, 'copy');
    expect(
        (copy.rules.single.candidates.single.parts.single.source
                as SmartTileFrameSource)
            .frame
            .atlasId,
        copy.atlases.single.id);
    expect(copy.atlases.single.tilesetId, 'sheet');
    expect(reopened.tilesets, original.tilesets);
    expect(reopened.elements, original.elements);
    expect(reopened.smartTileCatalog.materials,
        original.smartTileCatalog.materials);
    expect(
        reopened.smartTileCatalog.atlases, original.smartTileCatalog.atlases);
    expect(await source.exists(), isFalse);
    expect(await blob.readAsBytes(), blobBefore);
    expect(await catalog.readAsBytes(), catalogBefore);
    expect(await unrelatedFields(), unrelatedBefore);
  });

  test('terrain rename and copy refuse a missing canonical source without loss',
      () async {
    final fixture = await lifecycleFixture();
    addTearDown(fixture.dispose);
    final snapshot =
        await fixture.snapshots.load(ProjectHandle(fixture.project));
    final original = await independentRead(fixture);
    final source = File('${fixture.root.path}/assets/source.png');
    final bytes = await source.readAsBytes();
    final artifact =
        ContentArtifactRef.fromBytes(bytes, mediaType: 'image/png');
    final blob = File('${fixture.root.path}/${assetBlobStorageKey(artifact)}');
    final project = File('${fixture.root.path}/project.json');
    final before = await project.readAsBytes();
    final catalog = File('${fixture.root.path}/$assetCatalogStorageKey');
    final catalogBefore = await catalog.readAsBytes();
    await source.delete();
    await blob.delete();

    for (final (action, parameters) in [
      ('smart_tile.preset.rename', {'presetId': 'ground', 'name': 'Refusé'}),
      (
        'smart_tile.preset.duplicate',
        {
          'presetId': 'ground',
          'newDraftId': 'copy-draft',
          'targetPresetId': 'copy',
          'name': 'Refusée'
        }
      )
    ]) {
      final refused = await fixture.command('plan', {
        'projectHandle': fixture.project,
        'request': AuthoringRequest(
          requestId: action,
          actionId: action,
          actionVersion: 1,
          workspaceHandle: fixture.workspace,
          parameters: parameters,
          expectedRevision: snapshot.revision,
          idempotencyKey: action,
        ).toJson()
      });
      expect(refused.status, AuthoringResultStatus.failure,
          reason: jsonEncode(refused.toJson()));
      expect(
          refused.error,
          isA<AuthoringError>().having((error) => error.details['domainCode'],
              'domainCode', 'project.asset_blob_missing'));
      expect(await project.readAsBytes(), before);
      expect(await catalog.readAsBytes(), catalogBefore);
      expect(await fixture.read(), original);
      expect(await source.exists(), isFalse);
      expect(await blob.exists(), isFalse);
    }

    await expectLater(
        independentRead(fixture),
        throwsA(isA<ProjectSnapshotException>().having(
            (error) => error.code, 'code', 'project.asset_blob_missing')));
    await blob.writeAsBytes(bytes);
    expect(await independentRead(fixture), original);
    expect(await source.exists(), isFalse);
    expect(await project.readAsBytes(), before);
    expect(await catalog.readAsBytes(), catalogBefore);
  });
}
