import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import '../domains/assets/resource_information_fixture.dart';

void main() {
  for (final direct in [true, false]) {
    test(
        'resource library persists and reopens through ${direct ? 'direct API' : 'JSONL'} with exact unrelated payload',
        () async {
      final fixture =
          await ResourceInformationFixture.create(smartInformationFixture());
      addTearDown(fixture.dispose);
      final file = File('${fixture.root.path}/project.json');
      final before = jsonDecode(await file.readAsString()) as Map;
      (before['smartTileCatalog'] as Map)['drafts'] = [
        {
          'id': 'editing',
          'targetPresetId': 'ground',
          'sourcePresetId': 'ground',
          'name': 'Mon brouillon non publié',
          'categoryId': 'shared',
          'usage': 'terrain',
          'lastStage': 'usage',
          'extensionData': {'authored': 'préservé'}
        }
      ];
      await file.writeAsString(jsonEncode(before));
      final initialBytes = await file.readAsBytes();
      final initial =
          await fixture.snapshots.load(ProjectHandle(fixture.project));
      final dry = AuthoringRequest(
          requestId: 'dry',
          actionId: 'resource.family.create',
          actionVersion: 1,
          workspaceHandle: fixture.workspace,
          expectedRevision: initial.revision,
          idempotencyKey: 'dry',
          dryRun: true,
          parameters: const {'familyId': 'dry-family', 'name': 'Dry'});
      if (direct) {
        final plan =
            await fixture.mutations.plan(ProjectHandle(fixture.project), dry);
        expect(plan['nonApplicableReason'], 'dry_run');
      } else {
        final plan = await fixture.command('plan',
            {'projectHandle': fixture.project, 'request': dry.toJson()});
        expect(plan.status, AuthoringResultStatus.success);
        expect(plan.data['nonApplicableReason'], 'dry_run');
      }
      expect(await file.readAsBytes(), initialBytes);
      await _mutate(fixture, direct, 'resource.family.create',
          {'familyId': 'forest-a', 'name': 'Forêt A', 'parentId': 'trees'});
      await _expectUnrelatedPayload(file, before);
      await _mutate(fixture, direct, 'resource.family.update', {
        'familyId': 'forest-a',
        'name': 'Forêt B',
        'parentId': 'vegetation'
      });
      await _expectUnrelatedPayload(file, before);
      await _mutate(fixture, direct, 'resource.classify', {
        'resourceKind': 'element',
        'resourceId': 'decor',
        'familyId': 'forest-a'
      });
      await _expectUnrelatedPayload(file, before);
      await _mutate(fixture, direct, 'resource.classify', {
        'resourceKind': 'smartTilePreset',
        'resourceId': 'ground',
        'familyId': 'ground'
      });
      await _expectUnrelatedPayload(file, before);
      final query = await fixture.command('query', {
        'projectHandle': fixture.project,
        'request': AuthoringQueryRequest(
                resourceKind: 'resourceLibraryEntry',
                operation: AuthoringQueryOperation.list,
                view: AuthoringQueryView.detail)
            .toJson()
      });
      expect(query.status, AuthoringResultStatus.success);
      expect(query.data['items'], hasLength(2));
      final reopened =
          await ResourceInformationFixture.create(await fixture.read());
      addTearDown(reopened.dispose);
      expect((await reopened.read()).resourceLibraryCatalog,
          (await fixture.read()).resourceLibraryCatalog);
      await _mutate(fixture, direct, 'resource.classify',
          {'resourceKind': 'element', 'resourceId': 'decor', 'familyId': null});
      await _expectUnrelatedPayload(file, before);
      await _mutate(
          fixture, direct, 'resource.family.delete', {'familyId': 'forest-a'});
      await _expectUnrelatedPayload(file, before);
      expect((await fixture.read()).resourceLibraryCatalog.families, isEmpty);
      expect(
          (await fixture.read())
              .resourceLibraryCatalog
              .entryFor('smartTilePreset', 'ground')
              ?.familyId,
          'ground');
    });
  }

  test(
      'JSONL refuses unknown typed targets map scope and stale revisions without writing',
      () async {
    final fixture =
        await ResourceInformationFixture.create(smartInformationFixture());
    addTearDown(fixture.dispose);
    final file = File('${fixture.root.path}/project.json');
    final before = await file.readAsBytes();
    for (final parameters in [
      {'resourceKind': 'model3d', 'resourceId': 'decor', 'familyId': 'trees'},
      {'resourceKind': 'element', 'resourceId': 'decor', 'mapId': 'missing'},
      {'resourceKind': 'element', 'resourceId': 'decor', 'familyId': 'missing'},
    ]) {
      expect((await fixture.plan('resource.classify', parameters)).status,
          AuthoringResultStatus.failure);
    }
    final planned = await fixture
        .plan('resource.family.create', {'familyId': 'stale', 'name': 'Stale'});
    expect(planned.status, AuthoringResultStatus.success);
    await fixture.mutate(
        'resource.family.create', {'familyId': 'fresh', 'name': 'Fresh'});
    final stable = await file.readAsBytes();
    final refused = await fixture.apply(planned);
    expect(refused.status, AuthoringResultStatus.failure);
    expect(await file.readAsBytes(), stable);
    expect(before, isNot(stable));
  });

  test(
      'classifying a resource is journaled and undo restores exact manifest bytes',
      () async {
    final fixture =
        await ResourceInformationFixture.create(smartInformationFixture());
    addTearDown(fixture.dispose);
    final file = File('${fixture.root.path}/project.json');
    final before = await file.readAsBytes();
    await fixture.mutate('resource.classify', {
      'resourceKind': 'element',
      'resourceId': 'decor',
      'familyId': 'trees'
    });
    final history = await fixture.mutations
        .history(ProjectHandle(fixture.project), limit: 1);
    final entry = (history['entries'] as List).single as Map;
    await fixture.mutations.undo(ProjectHandle(fixture.project),
        entryId: entry['entryId'] as String,
        idempotencyKey: 'undo-classification');
    expect(await file.readAsBytes(), before);
  });
}

Future<void> _expectUnrelatedPayload(File file, Map before) async {
  final after = jsonDecode(await file.readAsString()) as Map;
  for (final field in [
    'elements',
    'tilesets',
    'smartTileCatalog',
    'maps',
    'elementCategories',
    'tilesetFolders'
  ]) {
    expect(after[field], before[field], reason: field);
  }
}

Future<void> _mutate(ResourceInformationFixture fixture, bool direct,
    String action, Map<String, Object?> parameters) async {
  if (!direct) {
    await fixture.mutate(action, parameters);
    return;
  }
  final snapshot = await fixture.snapshots.load(ProjectHandle(fixture.project));
  final id = '${fixture.next++}';
  final plan = await fixture.mutations.plan(
      ProjectHandle(fixture.project),
      AuthoringRequest(
          requestId: id,
          actionId: action,
          actionVersion: 1,
          workspaceHandle: fixture.workspace,
          expectedRevision: snapshot.revision,
          idempotencyKey: id,
          parameters: parameters));
  await fixture.mutations.apply(ProjectHandle(fixture.project),
      planId: plan['planId'] as String, operationId: id);
}
