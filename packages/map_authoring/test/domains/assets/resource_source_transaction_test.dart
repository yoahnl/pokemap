import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'resource_source_fixture.dart';
import 'resource_source_transaction_fixture.dart';

void main() {
  test(
      'frozen candidate applies after staging release with independent manifest/catalog reread',
      () async {
    final fixture = await ResourceSourceTransactionFixture.create(
        addressed: true, shared: true);
    addTearDown(fixture.dispose);
    await fixture.store
        .release(fixture.plan.request.parameters['artifactHandle']! as String);
    final receipt = await fixture.apply();
    final replay = await fixture.apply();
    expect(receipt.status, AuthoringReceiptStatus.applied);
    expect(replay.toJson(), receipt.toJson());
    final manifest = ProjectManifest.fromJson(jsonDecode(
        await File('${fixture.root.path}/project.json').readAsString()));
    final current =
        manifest.tilesets.firstWhere((entry) => entry.id == 'sheet');
    expect(
        await File('${fixture.root.path}/${current.relativePath}')
            .readAsBytes(),
        sourcePng(red: 255));
    expect(await File('${fixture.root.path}/assets/other.png').readAsBytes(),
        fixture.source.oldBytes);
    expect(
        await File(
                '${fixture.root.path}/${assetBlobStorageKey(fixture.source.old)}')
            .readAsBytes(),
        fixture.source.oldBytes);
    expect(current.source, fixture.source.project.tilesets.first.source);
    final catalog = AssetCatalog.fromJson(jsonDecode(
        await File('${fixture.root.path}/$assetCatalogStorageKey')
            .readAsString()));
    expect(catalog.require('other').artifact, fixture.source.old);
    expect(catalog.require('asset').logicalPath, current.relativePath);
  });

  test(
      'exact source preimage rejects concurrent pixels without publishing candidate',
      () async {
    final fixture = await ResourceSourceTransactionFixture.create();
    addTearDown(fixture.dispose);
    final catalogBefore =
        await File('${fixture.root.path}/$assetCatalogStorageKey')
            .readAsBytes();
    await File('${fixture.root.path}/${fixture.source.path}')
        .writeAsBytes(sourcePng(red: 90));
    await expectLater(
        fixture.apply(), throwsA(isA<AuthoringRevisionConflict>()));
    expect(
        await File('${fixture.root.path}/${fixture.source.path}').readAsBytes(),
        sourcePng(red: 90));
    expect(
        await File('${fixture.root.path}/$assetCatalogStorageKey')
            .readAsBytes(),
        catalogBefore);
    final candidate = ContentArtifactRef.fromBytes(sourcePng(red: 255),
        mediaType: 'image/png');
    expect(
        await File('${fixture.root.path}/${assetBlobStorageKey(candidate)}')
            .exists(),
        isFalse);
  });

  test('partial replacement crash compensates all promoted preimages',
      () async {
    var crashed = false;
    final fixture = await ResourceSourceTransactionFixture.create(
        addressed: true,
        faultInjector: (context) {
          if (!crashed &&
              context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterResourcePromoted &&
              context.promotionIndex == 0) {
            crashed = true;
            throw const AuthoringTransactionSimulatedCrash();
          }
        });
    addTearDown(fixture.dispose);
    final before = {
      for (final change in fixture.plan.changeSet.changes)
        change.storageKey: change.beforeBytes
    };
    await expectLater(
        fixture.apply(), throwsA(isA<AuthoringTransactionSimulatedCrash>()));
    final recovery = await fixture.recovery();
    final receipt = await recovery.compensate('source-operation');
    expect(receipt.status, AuthoringReceiptStatus.recovered);
    for (final entry in before.entries) {
      final file = File('${fixture.root.path}/${entry.key}');
      expect(await file.exists() ? await file.readAsBytes() : null, entry.value,
          reason: entry.key);
    }
  });

  test('logical source removal is durable and retains blob recoverability',
      () async {
    final fixture = await ResourceSourceTransactionFixture.create(remove: true);
    addTearDown(fixture.dispose);
    final result = await fixture.apply();
    expect(result.status, AuthoringReceiptStatus.applied);
    final independent = ProjectManifest.fromJson(jsonDecode(
        await File('${fixture.root.path}/project.json').readAsString()));
    expect(independent.tilesets, isEmpty);
    final catalog = AssetCatalog.fromJson(jsonDecode(
        await File('${fixture.root.path}/$assetCatalogStorageKey')
            .readAsString()));
    expect(catalog.records, isEmpty);
    expect(await File('${fixture.root.path}/${fixture.source.path}').exists(),
        isFalse);
    expect(
        await File(
                '${fixture.root.path}/${assetBlobStorageKey(fixture.source.old)}')
            .readAsBytes(),
        fixture.source.oldBytes);
  });
}
