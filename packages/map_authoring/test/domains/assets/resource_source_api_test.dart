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

void main() {
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
