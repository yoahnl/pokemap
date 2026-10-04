import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'resource_information_fixture.dart';
import 'resource_source_fixture.dart';

Future<ResourceInformationFixture> registeredSource(
    ResourceSourceFixture source) async {
  final fixture = await ResourceInformationFixture.create(source.project);
  await Directory('${fixture.root.path}/assets/.pokemap-store')
      .create(recursive: true);
  await File('${fixture.root.path}/$assetCatalogStorageKey')
      .writeAsString(jsonEncode(source.catalog.toJson()));
  await File('${fixture.root.path}/${assetBlobStorageKey(source.old)}')
      .writeAsBytes(source.oldBytes);
  await File('${fixture.root.path}/${source.path}')
      .writeAsBytes(source.oldBytes);
  return fixture;
}

Future<AuthoringMutationPlanResult> planReplacement(
    ResourceInformationFixture fixture,
    List<int> bytes,
    String operation) async {
  final staged = await fixture.mutations.artifacts.put(bytes);
  final snapshot = await fixture.snapshots.load(ProjectHandle(fixture.project));
  return fixture.mutations.planMutation(
    ProjectHandle(fixture.project),
    AuthoringRequest(
      requestId: operation,
      actionId: 'tileset.source.replace',
      actionVersion: 1,
      workspaceHandle: fixture.workspace,
      parameters: {
        'tilesetId': 'sheet',
        'artifactHandle': staged.reference.handle
      },
      expectedRevision: snapshot.revision,
      idempotencyKey: operation,
    ),
  );
}

Future<AuthoringMutationResult> applyReplacement(
    ResourceInformationFixture fixture,
    AuthoringMutationPlanResult plan,
    String operation,
    {AuthoringTransactionPrecondition? precondition}) async {
  final confirmation = await fixture.mutations.confirmMutation(
      ProjectHandle(fixture.project),
      planId: plan.plan.planId);
  return fixture.mutations.applyMutation(ProjectHandle(fixture.project),
      planId: plan.plan.planId,
      operationId: operation,
      confirmationToken: confirmation.confirmationToken,
      precondition: precondition);
}

void main() {
  test('restoring historical source pixels reuses the retained immutable blob',
      () async {
    final source = ResourceSourceFixture();
    final fixture = await registeredSource(source);
    addTearDown(fixture.dispose);

    final replacement = sourcePng(red: 255);
    final firstPlan =
        await planReplacement(fixture, replacement, 'replace-new');
    final first = await applyReplacement(fixture, firstPlan, 'replace-new');
    expect(first.receipt.status, AuthoringReceiptStatus.applied);
    final oldBlob =
        File('${fixture.root.path}/${assetBlobStorageKey(source.old)}');
    expect(await oldBlob.readAsBytes(), source.oldBytes);
    final catalog = AssetCatalog.fromJson(jsonDecode(
        await File('${fixture.root.path}/$assetCatalogStorageKey')
            .readAsString()));
    expect(
        catalog.records
            .any((record) => record.artifact.digest == source.old.digest),
        isFalse);
    final restorePlan =
        await planReplacement(fixture, source.oldBytes, 'restore-old');
    expect(restorePlan.plan.referenceImpact['retainedBlobDigests'],
        [source.old.digest]);
    expect(
        restorePlan.plan.changeSet.changes.any(
            (change) => change.storageKey == assetBlobStorageKey(source.old)),
        isFalse);
    final restored =
        await applyReplacement(fixture, restorePlan, 'restore-old');
    expect(restored.receipt.status, AuthoringReceiptStatus.applied);
    expect(await File('${fixture.root.path}/${source.path}').readAsBytes(),
        source.oldBytes);
    expect(await oldBlob.readAsBytes(), source.oldBytes);
    final replacedBlob = File('${fixture.root.path}/${assetBlobStorageKey(
      ContentArtifactRef.fromBytes(replacement, mediaType: 'image/png'),
    )}');
    expect(await replacedBlob.readAsBytes(), replacement);
    final independent = AssetCatalog.fromJson(jsonDecode(
        await File('${fixture.root.path}/$assetCatalogStorageKey')
            .readAsString()));
    expect(independent.require('asset').artifact.digest, source.old.digest);
  });

  for (final disappeared in [false, true]) {
    test(
        'retained blob ${disappeared ? 'removed' : 'altered'} after planning refuses before publication',
        () async {
      final source = ResourceSourceFixture();
      final fixture = await registeredSource(source);
      addTearDown(fixture.dispose);
      final replacement = sourcePng(red: 255);
      final firstPlan =
          await planReplacement(fixture, replacement, 'replace-new');
      await applyReplacement(fixture, firstPlan, 'replace-new');
      final restorePlan =
          await planReplacement(fixture, source.oldBytes, 'restore-old');
      final catalogFile = File('${fixture.root.path}/$assetCatalogStorageKey');
      final beforeCatalog = await catalogFile.readAsBytes();
      final beforeManifest =
          await File('${fixture.root.path}/project.json').readAsBytes();
      final oldBlob =
          File('${fixture.root.path}/${assetBlobStorageKey(source.old)}');
      final wrongBytes = sourcePng(red: 90);
      var initialSnapshotAccepted = false;
      final operation = applyReplacement(fixture, restorePlan, 'restore-old',
          precondition: () async {
        initialSnapshotAccepted = true;
        expect(await oldBlob.readAsBytes(), source.oldBytes);
        if (disappeared) {
          await oldBlob.delete();
        } else {
          await oldBlob.writeAsBytes(wrongBytes);
        }
      });
      await expectLater(
          operation,
          throwsA(disappeared
              ? isA<AuthoringPlanException>()
                  .having((error) => error.code, 'code', 'plan.stale')
              : isA<ProjectSnapshotException>().having((error) => error.code,
                  'code', 'project.asset_blob_mismatch')));
      expect(initialSnapshotAccepted, isTrue);
      expect(await catalogFile.readAsBytes(), beforeCatalog);
      expect(await File('${fixture.root.path}/project.json').readAsBytes(),
          beforeManifest);
      expect(await File('${fixture.root.path}/${source.path}').readAsBytes(),
          replacement);
      final currentBlob = File(
          '${fixture.root.path}/${assetBlobStorageKey(ContentArtifactRef.fromBytes(replacement, mediaType: 'image/png'))}');
      expect(await currentBlob.readAsBytes(), replacement);
      expect(await oldBlob.exists(), !disappeared);
      if (!disappeared) expect(await oldBlob.readAsBytes(), wrongBytes);
    });
  }

  test('JSONL batch import reuses a retained historical blob', () async {
    final source = ResourceSourceFixture();
    final fixture = await registeredSource(source);
    addTearDown(fixture.dispose);
    final first =
        await planReplacement(fixture, sourcePng(red: 255), 'replace');
    await applyReplacement(fixture, first, 'replace');
    final staged = await fixture.mutations.artifacts.put(source.oldBytes);
    final plan = await fixture.plan('asset.import_batch', {
      'entries': [
        {
          'artifactHandle': staged.reference.handle,
          'assetId': 'historical-copy',
          'logicalPath': 'assets/historical-copy.png'
        }
      ]
    });
    expect(plan.status, AuthoringResultStatus.success,
        reason: jsonEncode(plan.toJson()));
    final confirmation = await fixture.command('confirm',
        {'projectHandle': fixture.project, 'planId': plan.data['planId']});
    final applied = await fixture.command('apply', {
      'projectHandle': fixture.project,
      'planId': plan.data['planId'],
      'operationId': 'import-retained',
      'confirmationToken': confirmation.data['confirmationToken']
    });
    expect(applied.status, AuthoringResultStatus.success,
        reason: jsonEncode(applied.toJson()));
    expect(
        await File('${fixture.root.path}/assets/historical-copy.png')
            .readAsBytes(),
        source.oldBytes);
    expect(
        await File('${fixture.root.path}/${assetBlobStorageKey(source.old)}')
            .readAsBytes(),
        source.oldBytes);
    final catalog = AssetCatalog.fromJson(jsonDecode(
        await File('${fixture.root.path}/$assetCatalogStorageKey')
            .readAsString()));
    expect(
        catalog.require('historical-copy').artifact.digest, source.old.digest);
  });

  test('JSONL replaces true logical PNG and retains original source identity',
      () async {
    final source = ResourceSourceFixture();
    final fixture = await registeredSource(source);
    addTearDown(fixture.dispose);
    final candidate =
        await fixture.mutations.artifacts.put(sourcePng(red: 255));
    final preview = await fixture.plan('tileset.source.replace',
        {'tilesetId': 'sheet', 'artifactHandle': candidate.reference.handle});
    expect(preview.status, AuthoringResultStatus.success,
        reason: jsonEncode(preview.toJson()));
    expect(await File('${fixture.root.path}/${source.path}').readAsBytes(),
        source.oldBytes);
    final confirmation = await fixture.command('confirm',
        {'projectHandle': fixture.project, 'planId': preview.data['planId']});
    final result = await fixture.command('apply', {
      'projectHandle': fixture.project,
      'planId': preview.data['planId'],
      'operationId': 'replace',
      'confirmationToken': confirmation.data['confirmationToken']
    });
    expect(result.status, AuthoringResultStatus.success,
        reason: jsonEncode(result.toJson()));
    expect(await File('${fixture.root.path}/${source.path}').readAsBytes(),
        sourcePng(red: 255));
    final independent = ProjectManifest.fromJson(jsonDecode(
        await File('${fixture.root.path}/project.json').readAsString()));
    expect(independent.tilesets.single.id, 'sheet');
    expect(independent.tilesets.single.source,
        source.project.tilesets.single.source);
  });

  test('logical PNG missing is refused despite intact registered blob',
      () async {
    final source = ResourceSourceFixture();
    final fixture = await registeredSource(source);
    addTearDown(fixture.dispose);
    await File('${fixture.root.path}/${source.path}').delete();
    final snapshot =
        await fixture.snapshots.load(ProjectHandle(fixture.project));
    expect(snapshot.findResourceBytes('assetLogical:asset'), isNull);
    expect(
        snapshot
            .findResourceBytes(assetBlobResourceIdentity(source.old.digest)),
        source.oldBytes);
    final candidate =
        await fixture.mutations.artifacts.put(sourcePng(red: 255));
    final result = await fixture.plan('tileset.source.replace',
        {'tilesetId': 'sheet', 'artifactHandle': candidate.reference.handle});
    expect(result.status, AuthoringResultStatus.failure);
    expect(result.error!.details['domainCode'],
        'tileset.source_bytes_unavailable');
    expect(await File('${fixture.root.path}/${source.path}').exists(), isFalse);
  });

  test('logical PNG mismatch cannot be concealed by matching catalog blob',
      () async {
    final source = ResourceSourceFixture();
    final fixture = await registeredSource(source);
    addTearDown(fixture.dispose);
    await File('${fixture.root.path}/${source.path}')
        .writeAsBytes(sourcePng(red: 90));
    final candidate =
        await fixture.mutations.artifacts.put(sourcePng(red: 255));
    final result = await fixture.plan('tileset.source.replace',
        {'tilesetId': 'sheet', 'artifactHandle': candidate.reference.handle});
    expect(result.status, AuthoringResultStatus.failure);
    expect(result.error!.details['domainCode'],
        'tileset.source_bytes_unavailable');
    expect(await File('${fixture.root.path}/${source.path}').readAsBytes(),
        sourcePng(red: 90));
  });

  test(
      'usages inventory remains PNG-free while mutation snapshot certifies runtime PNG',
      () async {
    final source = ResourceSourceFixture();
    final fixture = await registeredSource(source);
    addTearDown(fixture.dispose);
    final read = await fixture.snapshots.load(ProjectHandle(fixture.project),
        policy: ProjectSnapshotLoadPolicy.resourceUsageReadProjection);
    expect(read.findResourceBytes('assetLogical:asset'), isNull);
    expect(read.findResourceBytes(assetBlobResourceIdentity(source.old.digest)),
        isNull);
    final mutation =
        await fixture.snapshots.load(ProjectHandle(fixture.project));
    expect(mutation.findResourceBytes('assetLogical:asset'), source.oldBytes);
    expect(mutation.resourceStorageKeys['assetLogical:asset'], source.path);
  });
}
