import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../domains/assets/resource_information_fixture.dart';
import '../domains/maps/map_catalog_fixture.dart' show catalogMap;

void main() {
  for (final direct in [true, false]) {
    test(
        'invalid description batch is atomic through ${direct ? 'direct API' : 'JSONL'}',
        () async {
      final fixture =
          await ResourceInformationFixture.create(smartInformationFixture());
      addTearDown(fixture.dispose);
      final file = File('${fixture.root.path}/project.json');
      final before = await file.readAsBytes();
      final parameters = {
        'entries': [
          {
            'resourceKind': 'element',
            'resourceId': 'decor',
            'description': 'Arbre pour les routes.'
          },
          {'resourceKind': 'tileset', 'resourceId': 'sheet', 'description': 1},
        ],
      };
      if (direct) {
        await expectLater(
            () => _mutate(fixture, true, 'resource.classify_batch', parameters),
            throwsA(isA<VisualLibraryException>()));
      } else {
        expect(
            (await fixture.plan('resource.classify_batch', parameters)).status,
            AuthoringResultStatus.failure);
      }
      expect(await file.readAsBytes(), before);
      expect((await fixture.read()).resourceLibraryCatalog.isEmpty, isTrue);
    });

    test(
        'individual description lifecycle through ${direct ? 'direct API' : 'JSONL'}',
        () async {
      final fixture =
          await ResourceInformationFixture.create(smartInformationFixture());
      addTearDown(fixture.dispose);
      for (final action in ['resource.classify', 'resource.classify_batch']) {
        Map<String, Object?> parameters(Object? description) {
          final entry = {
            'resourceKind': 'element',
            'resourceId': 'decor',
            'description': description
          };
          return action == 'resource.classify'
              ? entry
              : {
                  'entries': [entry]
                };
        }

        await _mutate(
            fixture, direct, action, parameters('Arbre pour les routes.'));
        expect(
            (await fixture.read())
                .resourceLibraryCatalog
                .entries
                .single
                .toJson()['description'],
            'Arbre pour les routes.');
        await _mutate(fixture, direct, action, parameters(null));
        expect((await fixture.read()).resourceLibraryCatalog.isEmpty, isTrue);
      }
    });

    for (final action in ['resource.classify', 'resource.classify_batch']) {
      test(
          '$action context-only lifecycle through ${direct ? 'direct API' : 'JSONL'}',
          () async {
        final fixture =
            await ResourceInformationFixture.create(smartInformationFixture());
        addTearDown(fixture.dispose);
        Map<String, Object?> parameters(Map<String, Object?> entry) =>
            action == 'resource.classify'
                ? entry
                : {
                    'entries': [entry]
                  };
        for (final context in ['interior', 'exterior', 'both']) {
          await _mutate(
              fixture,
              direct,
              action,
              parameters({
                'resourceKind': 'element',
                'resourceId': 'decor',
                'placementContext': context,
              }));
          expect(
              (await fixture.read())
                  .resourceLibraryCatalog
                  .entries
                  .single
                  .toJson(),
              {
                'resourceKind': 'element',
                'resourceId': 'decor',
                'placementContext': context,
              });
          await _mutate(
              fixture,
              direct,
              action,
              parameters({
                'resourceKind': 'element',
                'resourceId': 'decor',
                'familyId': 'trees',
              }));
          expect(
              (await fixture.read())
                  .resourceLibraryCatalog
                  .entries
                  .single
                  .placementContext
                  ?.name,
              context);
          await _mutate(
              fixture,
              direct,
              action,
              parameters({
                'resourceKind': 'element',
                'resourceId': 'decor',
                'familyId': null,
                'placementContext': null,
              }));
          expect(
              (await fixture.read()).resourceLibraryCatalog.entries, isEmpty);
        }
      });
    }
    test(
        'role-only changes preserve family and map through ${direct ? 'direct API' : 'JSONL'}',
        () async {
      final fixture =
          await ResourceInformationFixture.create(smartInformationFixture());
      addTearDown(fixture.dispose);
      final map = catalogMap('a');
      await Directory('${fixture.root.path}/maps').create();
      await File('${fixture.root.path}/maps/a.json')
          .writeAsString(jsonEncode(map.toJson()));
      final project = (await fixture.read()).copyWith(
        maps: const [
          ProjectMapEntry(id: 'a', name: 'A', relativePath: 'maps/a.json')
        ],
        resourceLibraryCatalog: ResourceLibraryCatalog(entries: [
          ResourceLibraryEntry(
            resourceKind: 'element',
            resourceId: 'decor',
            familyId: 'trees',
            mapId: 'a',
            placementContext: ResourcePlacementContext.interior,
          )
        ]),
      );
      final file = File('${fixture.root.path}/project.json');
      await file.writeAsString(jsonEncode(project.toJson()));
      await _mutate(fixture, direct, 'resource.classify', {
        'resourceKind': 'element',
        'resourceId': 'decor',
        'role': 'component',
      });
      await _mutate(fixture, direct, 'resource.classify_batch', {
        'entries': [
          {'resourceKind': 'element', 'resourceId': 'decor', 'role': 'standard'}
        ],
      });
      expect(
          (await fixture.read()).resourceLibraryCatalog.entries.single.toJson(),
          {
            'resourceKind': 'element',
            'resourceId': 'decor',
            'familyId': 'trees',
            'mapId': 'a',
            'placementContext': 'interior',
          });
      final source = jsonDecode(await file.readAsString()) as Map;
      await _expectUnrelatedPayload(file, project.toJson());
      expect(source['maps'], project.toJson()['maps']);
    });
    test(
        'classification batch is atomic idempotent undoable and reopens through ${direct ? 'direct API' : 'JSONL'}',
        () async {
      final fixture =
          await ResourceInformationFixture.create(smartInformationFixture());
      addTearDown(fixture.dispose);
      final file = File('${fixture.root.path}/project.json');
      final raw = jsonDecode(await file.readAsString()) as Map;
      (raw['smartTileCatalog'] as Map)['extensionData'] = {
        'authored': 'preserved'
      };
      await file.writeAsString(jsonEncode(raw));
      final before = await file.readAsBytes();
      final snapshot =
          await fixture.snapshots.load(ProjectHandle(fixture.project));
      AuthoringRequest request(String id, {bool dryRun = false}) =>
          AuthoringRequest(
            requestId: id,
            actionId: 'resource.classify_batch',
            actionVersion: 1,
            workspaceHandle: fixture.workspace,
            expectedRevision: snapshot.revision,
            idempotencyKey: id,
            dryRun: dryRun,
            parameters: const {
              'entries': [
                {
                  'resourceKind': 'element',
                  'resourceId': 'decor',
                  'familyId': 'trees',
                  'role': 'component',
                  'placementContext': 'both',
                },
                {
                  'resourceKind': 'smartTilePreset',
                  'resourceId': 'ground',
                  'familyId': 'ground'
                },
              ]
            },
          );
      Future<Map<String, Object?>> plan(AuthoringRequest request) async {
        if (direct) {
          return fixture.mutations
              .plan(ProjectHandle(fixture.project), request);
        }
        final result = await fixture.command('plan',
            {'projectHandle': fixture.project, 'request': request.toJson()});
        expect(result.status, AuthoringResultStatus.success,
            reason: '${result.toJson()}');
        return result.data;
      }

      Future<Map<String, Object?>> apply(Map<String, Object?> planned) async {
        if (direct) {
          return fixture.mutations.apply(ProjectHandle(fixture.project),
              planId: planned['planId'] as String, operationId: 'batch');
        }
        final result = await fixture.command('apply', {
          'projectHandle': fixture.project,
          'planId': planned['planId'],
          'operationId': 'batch'
        });
        expect(result.status, AuthoringResultStatus.success,
            reason: '${result.toJson()}');
        return result.data;
      }

      expect(
          (await plan(
              request('dry-batch', dryRun: true)))['nonApplicableReason'],
          'dry_run');
      expect(await file.readAsBytes(), before);
      final planned = await plan(request('batch'));
      expect(await file.readAsBytes(), before);
      final applied = await apply(planned);
      expect((await apply(planned))['receipt'], applied['receipt']);
      final manifest = await fixture.read();
      expect(manifest.resourceLibraryCatalog.entries, hasLength(2));
      expect(manifest.resourceLibraryCatalog.entryFor('element', 'decor')!.role,
          ResourceLibraryRole.component);
      expect(
          manifest.resourceLibraryCatalog
              .entryFor('element', 'decor')!
              .placementContext,
          ResourcePlacementContext.both);
      await _expectUnrelatedPayload(file, raw);
      expect((jsonDecode(await file.readAsString()) as Map)['smartTileCatalog'],
          raw['smartTileCatalog']);
      final history = await fixture.mutations
          .history(ProjectHandle(fixture.project), limit: 100);
      expect(history['entries'], hasLength(1));
      final saved = await file.readAsBytes();
      await fixture.command('close', {'projectHandle': fixture.project});
      final reopened =
          await fixture.command('open', {'projectRoot': fixture.root.path});
      expect(reopened.status, AuthoringResultStatus.success);
      final query = await fixture.command('query', {
        'projectHandle': reopened.data['projectHandle'],
        'request': AuthoringQueryRequest(
                resourceKind: 'resourceLibraryEntry',
                operation: AuthoringQueryOperation.list,
                view: AuthoringQueryView.detail)
            .toJson(),
      });
      expect(query.status, AuthoringResultStatus.success);
      expect(query.data['items'], hasLength(2));
      expect(
          (query.data['items'] as List)
              .cast<Map>()
              .singleWhere((item) => item['resourceKind'] == 'element')['role'],
          'component');
      expect(
          (query.data['items'] as List).cast<Map>().singleWhere(
              (item) => item['resourceKind'] == 'element')['placementContext'],
          'both');
      final entry = (history['entries'] as List).single as Map;
      await fixture.mutations.undo(
          ProjectHandle(reopened.data['projectHandle'] as String),
          entryId: entry['entryId'] as String,
          idempotencyKey: 'undo-batch');
      await fixture
          .command('close', {'projectHandle': reopened.data['projectHandle']});
      expect(await file.readAsBytes(), before);
      expect(saved, isNot(before));
    });

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
      {
        'resourceKind': 'element',
        'resourceId': 'decor',
        'placementContext': 'unknown'
      },
      {'resourceKind': 'element', 'resourceId': 'decor', 'placementContext': 1},
    ]) {
      expect((await fixture.plan('resource.classify', parameters)).status,
          AuthoringResultStatus.failure);
    }
    final planned = await fixture.plan('resource.classify', {
      'resourceKind': 'element',
      'resourceId': 'decor',
      'placementContext': 'interior',
    });
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
      'JSONL rejects a late invalid batch entry and stale batch without partial writes',
      () async {
    final fixture =
        await ResourceInformationFixture.create(smartInformationFixture());
    addTearDown(fixture.dispose);
    final file = File('${fixture.root.path}/project.json');
    final before = await file.readAsBytes();
    for (final invalid in [
      {'resourceKind': 'tileset', 'resourceId': 'missing'},
      {'resourceKind': 'tileset', 'resourceId': 'sheet', 'familyId': 'missing'},
      {'resourceKind': 'tileset', 'resourceId': 'sheet', 'mapId': 'missing'},
      {
        'resourceKind': 'tileset',
        'resourceId': 'sheet',
        'placementContext': 'unknown'
      },
      {'resourceKind': 'tileset', 'resourceId': 'sheet', 'placementContext': 1},
      {'resourceKind': 'tileset', 'resourceId': 'sheet', 'description': 1},
    ]) {
      final refused = await fixture.plan('resource.classify_batch', {
        'entries': [
          {
            'resourceKind': 'element',
            'resourceId': 'decor',
            'placementContext': 'interior'
          },
          invalid,
        ]
      });
      expect(refused.status, AuthoringResultStatus.failure);
      expect(await file.readAsBytes(), before);
      expect(
          (await fixture.mutations
              .history(ProjectHandle(fixture.project), limit: 100))['entries'],
          isEmpty);
    }
    final planned = await fixture.plan('resource.classify_batch', {
      'entries': [
        {
          'resourceKind': 'element',
          'resourceId': 'decor',
          'placementContext': 'both'
        },
        {'resourceKind': 'tileset', 'resourceId': 'sheet', 'familyId': 'props'},
      ]
    });
    expect(planned.status, AuthoringResultStatus.success);
    await fixture.mutate(
        'resource.family.create', {'familyId': 'fresh', 'name': 'Fresh'});
    final stable = await file.readAsBytes();
    expect(
        (await fixture.apply(planned)).status, AuthoringResultStatus.failure);
    expect(await file.readAsBytes(), stable);
    expect((await fixture.read()).resourceLibraryCatalog.entries, isEmpty);
  });

  test(
      'JSONL batch rejects transitive scope conflict without partial classification',
      () async {
    final fixture =
        await ResourceInformationFixture.create(smartInformationFixture());
    addTearDown(fixture.dispose);
    final file = File('${fixture.root.path}/project.json');
    final maps = [
      catalogMap('a'),
      catalogMap('b').copyWith(placedElements: const [
        MapPlacedElement(
            id: 'placed',
            layerId: 'base',
            elementId: 'decor',
            pos: GridPos(x: 1, y: 1)),
      ])
    ];
    final project = (await fixture.read()).copyWith(maps: [
      for (final map in maps)
        ProjectMapEntry(
            id: map.id, name: map.name, relativePath: 'maps/${map.id}.json'),
    ]);
    await Directory('${fixture.root.path}/maps').create();
    for (final map in maps) {
      await File('${fixture.root.path}/maps/${map.id}.json')
          .writeAsString(jsonEncode(map.toJson()));
    }
    await file.writeAsString(jsonEncode(project.toJson()));
    final before = await file.readAsBytes();
    final refused = await fixture.plan('resource.classify_batch', {
      'entries': [
        {'resourceKind': 'element', 'resourceId': 'decor', 'familyId': 'trees'},
        {'resourceKind': 'tileset', 'resourceId': 'sheet', 'mapId': 'a'},
      ]
    });
    expect(refused.status, AuthoringResultStatus.failure);
    expect(refused.error!.details['domainCode'],
        'resource_library.scope_conflict');
    expect(await file.readAsBytes(), before);
    expect((await fixture.read()).resourceLibraryCatalog.entries, isEmpty);
    expect(
        (await fixture.mutations
            .history(ProjectHandle(fixture.project), limit: 100))['entries'],
        isEmpty);
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
      'placementContext': 'interior'
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
