import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../maps/map_catalog_fixture.dart';
import 'element_definition_fixture.dart';
import 'resource_information_fixture.dart';

Future<ResourceInformationFixture> registeredFixture(
    {ProjectManifest? manifest}) async {
  final fixture = await ResourceInformationFixture.create(
      manifest ?? elementDefinitionFixture(animated: true));
  await File('${fixture.root.path}/$assetCatalogStorageKey')
      .create(recursive: true);
  await File('${fixture.root.path}/$assetCatalogStorageKey')
      .writeAsString(jsonEncode(elementCatalog.toJson()));
  final blob =
      File('${fixture.root.path}/${assetBlobStorageKey(elementArtifact)}');
  await blob.create(recursive: true);
  await blob.writeAsBytes(elementPixels);
  await File('${fixture.root.path}/assets/source.png')
      .writeAsBytes(elementPixels);
  return fixture;
}

Future<AuthoringResult> applyConfirmed(
    ResourceInformationFixture fixture, AuthoringResult plan) async {
  final confirmation = await fixture.command('confirm',
      {'projectHandle': fixture.project, 'planId': plan.data['planId']});
  expect(confirmation.status, AuthoringResultStatus.success,
      reason: jsonEncode(confirmation.toJson()));
  return fixture.command('apply', {
    'projectHandle': fixture.project,
    'planId': plan.data['planId'],
    'operationId': 'confirmed-${fixture.next++}',
    'confirmationToken': confirmation.data['confirmationToken'],
  });
}

void main() {
  test('JSONL duplicate persists independent definition without image writes',
      () async {
    final fixture = await registeredFixture();
    addTearDown(fixture.dispose);
    final before = await fixture.read();
    final blob =
        File('${fixture.root.path}/${assetBlobStorageKey(elementArtifact)}');
    final catalog = File('${fixture.root.path}/$assetCatalogStorageKey');
    final originalPixels = await blob.readAsBytes();
    final originalCatalog = await catalog.readAsBytes();
    final plan = await fixture.plan('element.duplicate', duplicateParameters());
    expect(plan.status, AuthoringResultStatus.success,
        reason: jsonEncode(plan.toJson()));
    expect((await fixture.read()).elements, before.elements);
    final applied = await fixture.apply(plan);
    expect(applied.status, AuthoringResultStatus.success,
        reason: jsonEncode(applied.toJson()));
    final after = await fixture.read();
    final copy = after.elements.singleWhere((element) => element.id == 'copy');
    expect(copy,
        before.elements.single.copyWith(id: 'copy', name: 'Décor — copie'));
    await fixture.mutate('element.upsert', {
      'element': copy.copyWith(frames: [
        copy.frames.first.copyWith(durationMs: 75)
      ], collisionProfile: copy.collisionProfile!.copyWith(cells: [])).toJson(),
    });
    final reread = (await independentlyReopen(fixture.root)).manifest;
    expect(reread.elements.singleWhere((element) => element.id == 'decor'),
        before.elements.single);
    expect(
        reread.elements.singleWhere((element) => element.id == 'copy').frames,
        [copy.frames.first.copyWith(durationMs: 75)]);
    expect(await blob.readAsBytes(), originalPixels);
    expect(await catalog.readAsBytes(), originalCatalog);
    final files = await fixture.root.list(recursive: true).toList();
    expect(files.whereType<File>().where((file) => file.path.endsWith('.png')),
        hasLength(1));
  });

  test('target ID created after plan refuses transaction without replacement',
      () async {
    final fixture = await registeredFixture();
    addTearDown(fixture.dispose);
    final plan = await fixture.plan('element.duplicate', duplicateParameters());
    expect(plan.status, AuthoringResultStatus.success);
    final original = await fixture.read();
    final external = original.copyWith(elements: [
      ...original.elements,
      original.elements.single.copyWith(id: 'copy', name: 'Autre auteur'),
    ]);
    final projectFile = File('${fixture.root.path}/project.json');
    await projectFile.writeAsString(jsonEncode(external.toJson()));
    final expected = await projectFile.readAsBytes();
    final result = await fixture.apply(plan);
    expect(result.status, AuthoringResultStatus.failure);
    expect(await projectFile.readAsBytes(), expected);
    expect(
        (await fixture.read()).elements.singleWhere((e) => e.id == 'copy').name,
        'Autre auteur');
  });

  test('deleted destination after plan preserves original and creates no copy',
      () async {
    final fixture = await registeredFixture();
    addTearDown(fixture.dispose);
    final plan = await fixture.plan('element.duplicate', {
      ...duplicateParameters(),
      'categoryId': 'other',
    });
    expect(plan.status, AuthoringResultStatus.success);
    final original = await fixture.read();
    final file = File('${fixture.root.path}/project.json');
    await file.writeAsString(jsonEncode(original.copyWith(elementCategories: [
      for (final category in original.elementCategories)
        if (category.id != 'other') category,
    ]).toJson()));
    final expected = await file.readAsBytes();
    final result = await fixture.apply(plan);
    expect(result.status, AuthoringResultStatus.failure);
    expect(await file.readAsBytes(), expected);
    expect((await fixture.read()).elements.map((element) => element.id),
        ['decor']);
  });

  test('double application cannot create a second independent copy', () async {
    final fixture = await registeredFixture();
    addTearDown(fixture.dispose);
    final plan = await fixture.plan('element.duplicate', duplicateParameters());
    expect(plan.status, AuthoringResultStatus.success);
    final first = await fixture.apply(plan, operation: 'duplicate-once');
    expect(first.status, AuthoringResultStatus.success);
    final file = File('${fixture.root.path}/project.json');
    final expected = await file.readAsBytes();
    final repeated = await fixture.apply(plan, operation: 'duplicate-once');
    expect(repeated.status, AuthoringResultStatus.success);
    expect(await file.readAsBytes(), expected);
    expect((await fixture.read()).elements.map((element) => element.id),
        ['copy', 'decor']);
  });

  test('closed map references refuse deletion through actual JSONL handler',
      () async {
    final original = elementDefinitionFixture();
    final map = catalogMap('closed').copyWith(placedElements: const [
      MapPlacedElement(
          id: 'placed',
          layerId: 'objects',
          elementId: 'decor',
          pos: GridPos(x: 1, y: 1)),
    ]);
    final fixture = await registeredFixture();
    addTearDown(fixture.dispose);
    await File('${fixture.root.path}/maps/closed.json').create(recursive: true);
    await File('${fixture.root.path}/maps/closed.json')
        .writeAsString(jsonEncode(map.toJson()));
    await File('${fixture.root.path}/project.json').writeAsString(jsonEncode(
        original.copyWith(maps: const [
      ProjectMapEntry(
          id: 'closed', name: 'Fermée', relativePath: 'maps/closed.json')
    ]).toJson()));
    final expected =
        await File('${fixture.root.path}/maps/closed.json').readAsBytes();
    final plan = await fixture.plan('element.delete', {'elementId': 'decor'});
    expect(plan.status, AuthoringResultStatus.failure);
    expect(plan.error!.details['domainCode'], 'element.references_blocking');
    expect(await File('${fixture.root.path}/maps/closed.json').readAsBytes(),
        expected);
    expect((await fixture.read()).elements.single.id, 'decor');
  });

  test('confirmed unused deletion retains source and has unknown repeat target',
      () async {
    final fixture = await registeredFixture();
    addTearDown(fixture.dispose);
    final blob =
        File('${fixture.root.path}/${assetBlobStorageKey(elementArtifact)}');
    final before = await blob.readAsBytes();
    final plan = await fixture.plan('element.delete', {'elementId': 'decor'});
    expect(plan.status, AuthoringResultStatus.success);
    final result = await applyConfirmed(fixture, plan);
    expect(result.status, AuthoringResultStatus.success);
    expect((await fixture.read()).elements, isEmpty);
    expect(await blob.readAsBytes(), before);
    final repeat = await fixture.plan('element.delete', {'elementId': 'decor'});
    expect(repeat.status, AuthoringResultStatus.failure);
    expect(repeat.error!.details['domainCode'], 'element.unknown');
  });

  test('new closed map dependency after plan blocks confirmed deletion',
      () async {
    final fixture = await registeredFixture();
    addTearDown(fixture.dispose);
    final plan = await fixture.plan('element.delete', {'elementId': 'decor'});
    expect(plan.status, AuthoringResultStatus.success);
    final confirmation = await fixture.command('confirm',
        {'projectHandle': fixture.project, 'planId': plan.data['planId']});
    expect(confirmation.status, AuthoringResultStatus.success);
    final original = await fixture.read();
    final updated = original.copyWith(borderCatalog: retainedElementBorder());
    final file = File('${fixture.root.path}/project.json');
    await file.writeAsString(jsonEncode(updated.toJson()));
    final expected = await file.readAsBytes();
    final result = await fixture.command('apply', {
      'projectHandle': fixture.project,
      'planId': plan.data['planId'],
      'operationId': 'stale-delete',
      'confirmationToken': confirmation.data['confirmationToken'],
    });
    expect(result.status, AuthoringResultStatus.failure);
    expect(await file.readAsBytes(), expected);
  });
}

Future<ProjectSnapshot> independentlyReopen(Directory root) async {
  const reader = LocalProjectFileReader();
  final handles = WorkspaceHandleStore();
  final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path], fileReader: reader);
  final loader = ProjectSnapshotLoader(handles: handles);
  final api = AuthoringReadApi(
      openService: ProjectOpenService(
          policy: policy, fileReader: reader, handles: handles),
      snapshotLoader: loader);
  final worker = JsonlWorker(api: api);
  final result =
      AuthoringResult.fromJson(jsonDecode(await worker.processLine(jsonEncode({
    'id': 'independent',
    'command': 'open',
    'args': {'projectRoot': root.path}
  }))));
  expect(result.status, AuthoringResultStatus.success);
  final handle = ProjectHandle(result.data['projectHandle'] as String);
  final snapshot = await loader.load(handle);
  await worker.processLine(jsonEncode({
    'id': 'independent-close',
    'command': 'close',
    'args': {'projectHandle': handle.value}
  }));
  return snapshot;
}
