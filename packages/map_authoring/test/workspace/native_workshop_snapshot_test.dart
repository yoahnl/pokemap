import 'dart:convert';

import 'package:map_authoring/src/workspace/project_snapshot_loader.dart';
import 'package:map_authoring/src/workspace/project_snapshot.dart';
import 'package:map_authoring/src/workspace/workspace_handle_store.dart';
import 'package:map_authoring/src/ports/project_file_reader.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final unrelated in [0, 900]) {
    test('native field routes load their map without unrelated definitions $unrelated', () async {
      final f = _Fixture(unrelated: unrelated);
      final map = MapData(id: 'owner', name: 'Owner', version: ProjectVersion.v9,
        size: const GridSize(width: 4, height: 4), spatialScene: MapSpatialScene(width: 4, depth: 4));
      f.resources['maps/owner.json'] = utf8.encode(jsonEncode(map.toJson()));
      f.raw['settings'] = {'unrelatedInvalidSettings': true};
      f.updateProject();
      for (var repeat = 0; repeat < 2; repeat++) {
        f.reads.clear();
        final snapshot = await f.loader.loadWorkshop(f.handle, actionId: 'gameplay_zone.set_field_action_payload',
          parameters: const {'mapId': 'owner', 'zoneId': 'route', 'payload': {'actionKind': 'waterfall'}});
        expect(snapshot.maps.single, map);
        expect(snapshot.manifest.models3d, isEmpty);
        expect(snapshot.availableProjectSections, isEmpty);
        expect(f.reads.toSet(), {'project.json', 'maps/owner.json'});
      }
    });
  }
  test('savings native scope includes conflicting Fact runtime identities only', () async {
    final f = _Fixture(unrelated: 900);
    f.raw['facts'] = [
      NarrativeFactDefinition(id: 'enabled', label: 'Enabled', legacyFlagName: 'shared').toJson(),
      NarrativeFactDefinition(id: 'balance', label: 'Balance', initialValue: NarrativeValue.integer(0)).toJson(),
      NarrativeFactDefinition(id: 'conflict', label: 'Conflict', legacyFlagName: 'shared').toJson(),
      {'id': 'unrelated', 'label': 37},
    ];
    f.updateProject();
    const config = ProjectBattleSavingsConfig(enabledFactId: 'enabled', balanceFactId: 'balance', percentage: 25, maximumBalance: 999999);
    final snapshot = await f.loader.loadWorkshop(f.handle, actionId: 'campaign.battle_savings.update', parameters: {'battleSavings': config.toJson()});
    expect(snapshot.manifest.facts.map((fact) => fact.id), unorderedEquals(['enabled', 'balance', 'conflict']));
    expect(() => config.validate(snapshot.manifest.facts), throwsA(isA<ValidationException>()));
    expect(snapshot.maps, isEmpty);
    expect(f.reads, ['project.json', 'project.json']);
  });
  for (final unrelated in [0, 900]) {
    test('savings first and repeated scope ignores $unrelated foreign definitions', () async {
      final f = _Fixture(unrelated: unrelated);
      f.raw['facts'] = [
        NarrativeFactDefinition(id: 'enabled', label: 'Enabled').toJson(),
        NarrativeFactDefinition(id: 'balance', label: 'Balance', initialValue: NarrativeValue.integer(0)).toJson(),
        for (var i = 0; i < unrelated; i++) {'id': 'bad_$i', 'label': 37},
      ];
      f.updateProject();
      for (var attempt = 0; attempt < 2; attempt++) {
        f.reads.clear();
        final snapshot = await f.loader.loadWorkshop(f.handle,
          actionId: 'campaign.battle_savings.update', parameters: const {'battleSavings': {
            'enabledFactId': 'enabled', 'balanceFactId': 'balance', 'percentage': 25, 'maximumBalance': 999999}});
        expect(snapshot.maps, isEmpty);
        expect(snapshot.manifest.characters, isEmpty);
        expect(snapshot.manifest.facts.map((f) => f.id), unorderedEquals(['enabled', 'balance']));
        expect(snapshot.availableProjectSections, contains('battleSavings'));
        expect(f.reads, ['project.json', 'project.json']);
      }
    });

    test(
        'native gameplay first and repeated loads ignore $unrelated unrelated definitions',
        () async {
      final f = _Fixture(unrelated: unrelated);
      for (var attempt = 0; attempt < 2; attempt++) {
        f.reads.clear();
        final snapshot = await f.loader.loadWorkshop(f.handle,
            actionId: 'bag.capacity.set',
            parameters: const {'mode': 'unlimited'});
        expect(snapshot.maps, isEmpty);
        expect(snapshot.manifest.characters, isEmpty);
        expect(snapshot.manifest.facts, isEmpty);
        expect(snapshot.availableProjectSections, contains('bagCapacity'));
        expect(snapshot.resourceBytes('project'), f.resources['project.json']);
        expect(f.reads, ['project.json', 'project.json']);
      }
      final cold = ProjectSnapshotLoader(handles: f.handles);
      expect(
          (await cold.loadWorkshop(f.handle, actionId: 'item.create'))
              .resourceStorageKeys,
          {'project': 'project.json'});
    });
    test('guided loads only the owner map with $unrelated missing foreign maps',
        () async {
      final f = _Fixture(unrelated: unrelated);
      for (var attempt = 0; attempt < 2; attempt++) {
        f.reads.clear();
        final snapshot = await f.loader.loadWorkshop(f.handle,
            actionId: 'narrative.publish_document',
            parameters: const {
              'map': {'id': 'owner'},
              'facts': [
                {'id': 'new_fact'}
              ]
            });
        expect(snapshot.maps.map((map) => map.id), ['owner']);
        expect(snapshot.manifest.maps.map((map) => map.id), ['owner']);
        expect(snapshot.availableProjectDocuments!['facts'], {'new_fact'});
        expect(f.reads, [
          'project.json',
          'maps/owner.json',
          'project.json',
          'maps/owner.json'
        ]);
      }
    });
  }
  test('3D gameplay projection preserves the dimension and camera', () async {
    final f = _Fixture(unrelated: 3);
    f.raw['version'] = 'v9';
    f.raw['settings'] = ProjectSettings(
            dimension: ProjectDimension.threeD,
            spatialCamera: SpatialCameraProfile())
        .toJson();
    f.updateProject();
    final snapshot =
        await f.loader.loadWorkshop(f.handle, actionId: 'bag.capacity.set');
    expect(snapshot.manifest.settings.dimension, ProjectDimension.threeD);
    expect(snapshot.manifest.settings.spatialCamera, isNotNull);
  });
  test(
      'item updates include battle items and balls without unrelated trainer hydration',
      () async {
    final f = _Fixture(unrelated: 900);
    final trainer = const ProjectTrainerEntry(
        id: 'uses',
        name: 'Uses',
        trainerClass: 'Trainer',
        team: [],
        battleItems: {'potion': 1});
    f.raw['trainers'] = [
      trainer.toJson(),
      {'id': 'unrelated', 'name': 3, 'rewardItemId': 'potion'}
    ];
    f.updateProject();
    final snapshot = await f.loader.loadWorkshop(f.handle,
        actionId: 'item.update', parameters: const {'itemId': 'potion'});
    expect(snapshot.manifest.trainers.map((trainer) => trainer.id), ['uses']);
  });
  test('optional dependencies retain absent revisions for atomic apply checks',
      () async {
    final f = _Fixture(unrelated: 900);
    final snapshot = await f.loader.loadWorkshop(f.handle,
        actionId: 'item.create',
        readDependencies: const {'optional': 'data/optional.json'});
    expect(snapshot.scopedStorageRevisions, {
      'project.json': snapshot.resourceFingerprints['project'],
      'data/optional.json': null,
      'data/pokemon/catalogs/items.json': null,
    });
    expect(f.reads.where((path) => path == 'data/optional.json'), hasLength(2));
  });
  test('double battle rules inspect only matching trainer documents', () async {
    final f = _Fixture(unrelated: 900);
    f.raw['trainers'] = [
      const ProjectTrainerEntry(
          id: 'double',
          name: 'Double',
          trainerClass: 'Trainer',
          battleFormat: BattleFormat.doubles,
          team: []).toJson(),
      {'id': 'single', 'name': 4, 'battleFormat': 'singles'},
    ];
    f.updateProject();
    final profile = PokemonRulesetProfile.pokeMapBetaV1.toJson();
    final snapshot = await f.loader.loadWorkshop(f.handle,
        actionId: 'pokemon.ruleset.set', parameters: {'profile': profile});
    expect(snapshot.manifest.trainers.map((trainer) => trainer.id), ['double']);
  });
  test(
      'guided event selection reads nested event identities without hydrating foreign records',
      () async {
    final f = _Fixture(unrelated: 900);
    f.raw['eventRegistry'] = {
      'schemaVersion': 1,
      'mode': 'dualRead',
      'legacyClaims': [],
      'records': [
        {
          'state': 'draft',
          'draft': {
            'id': 'evt_019abcde-0029-7000-8000-000000000001',
            'name': 'Owner',
            'source': {
              'kind': 'entityInteract',
              'mapId': 'owner',
              'entityId': 'npc'
            },
            'conditions': [],
            'priority': 0,
            'order': 0,
          }
        },
        {
          'state': 'invalid-foreign',
          'draft': {
            'id': 'foreign',
            'source': {'mapId': 'foreign'}
          }
        },
      ],
    };
    f.updateProject();
    final snapshot = await f.loader.loadWorkshop(f.handle,
        actionId: 'narrative.publish_document',
        parameters: const {
          'map': {'id': 'owner'}
        });
    expect(snapshot.manifest.eventRegistry!.records.single.id,
        'evt_019abcde-0029-7000-8000-000000000001');
    expect(snapshot.availableProjectDocuments!['eventRegistry'],
        {'evt_019abcde-0029-7000-8000-000000000001'});
    expect(snapshot.maps.map((map) => map.id), ['owner']);
  });
  test(
      'guided step references select their story owner without foreign hydration',
      () async {
    final f = _Fixture(unrelated: 900);
    final story = StorylineAsset(
      id: 'owner_story',
      type: StorylineType.main,
      title: 'Owner story',
      chapters: [
        StorylineChapter(
            id: 'chapter',
            title: 'Chapter',
            order: 0,
            steps: [StorylineStep(id: 'needed', title: 'Needed', order: 0)])
      ],
    );
    f.raw['storylines'] = [
      story.toJson(),
      {'id': 'unrelated_story', 'title': 8}
    ];
    f.updateProject();
    final scene = SceneAsset(
        id: 'edited',
        name: 'Edited',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
                id: 'action',
                kind: SceneNodeKind.action,
                payload: SceneActionPayload.consequence(
                    SceneCompleteStoryStepConsequence(stepId: 'needed'))),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
                id: 'flow',
                fromNodeId: 'start',
                fromPortId: 'completed',
                toNodeId: 'action',
                kind: SceneEdgeKind.defaultFlow),
            SceneEdge(
                id: 'done',
                fromNodeId: 'action',
                fromPortId: 'completed',
                toNodeId: 'end',
                kind: SceneEdgeKind.defaultFlow),
          ],
        ));
    final snapshot = await f.loader.loadWorkshop(f.handle,
        actionId: 'narrative.publish_document',
        parameters: {
          'map': {'id': 'owner'},
          'scenes': [scene.toJson()]
        });
    expect(snapshot.manifest.storylines, [story]);
    expect(snapshot.availableProjectDocuments!['storylines'], {'owner_story'});
    expect(snapshot.maps.map((map) => map.id), ['owner']);
  });
  test('an unchanged owner scene does not pull foreign event source maps',
      () async {
    final f = _Fixture(unrelated: 900);
    final scene = SceneAsset(
        id: 'shared',
        name: 'Shared',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(id: 'end', kind: SceneNodeKind.end)
          ],
          edges: [
            SceneEdge(
                id: 'flow',
                fromNodeId: 'start',
                fromPortId: 'completed',
                toNodeId: 'end',
                kind: SceneEdgeKind.defaultFlow)
          ],
        ));
    f.raw['scenes'] = [
      {...scene.toJson(), 'futurePresentation': 'preserve'}
    ];
    f.raw['eventRegistry'] = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: [
          for (final entry in {'owner': '001', 'foreign_0': '002'}.entries)
            NarrativeEventRecord.configuredStructurallyUnchecked(
                NarrativeEventDefinition(
                  id: 'evt_019abcde-0029-7000-8000-000000000${entry.value}',
                  name: entry.key,
                  source: NarrativeEventSourceRef.mapEnter(entry.key),
                  conditions: [],
                  sceneId: scene.id,
                  reusePolicy: NarrativeEventReusePolicy.reusable,
                  priority: 0,
                  order: 0,
                ),
                enabled: true)
        ],
        legacyClaims: []).toJson();
    f.updateProject();
    for (final explicitScene in [false, true]) {
      f.reads.clear();
      final snapshot = await f.loader.loadWorkshop(f.handle,
          actionId: 'narrative.publish_document',
          parameters: {
            'map': {'id': 'owner'},
            if (explicitScene) 'scenes': [scene.toJson()],
          });
      expect(snapshot.maps.map((map) => map.id), ['owner']);
      expect(
          snapshot.manifest.eventRegistry!.records.map((record) => record.id),
          ['evt_019abcde-0029-7000-8000-000000000001']);
      expect(f.reads.where((path) => path.startsWith('missing/')), isEmpty);
      expect(snapshot.resourceBytes('project'), f.resources['project.json']);
    }
  });
  test('selected malformed documents fail without reading foreign files',
      () async {
    final f = _Fixture(unrelated: 900);
    await expectLater(
        f.loader.loadWorkshop(f.handle,
            actionId: 'campaign.trainer.upsert',
            parameters: const {
              'value': {'id': 'foreign_0'}
            }),
        throwsA(anything));
    expect(f.reads, ['project.json']);
  });
  test('a project modification during loading rejects the scoped snapshot',
      () async {
    final f = _Fixture(unrelated: 0);
    f.changeProjectOnSecondRead = true;
    await expectLater(
        f.loader.loadWorkshop(f.handle, actionId: 'bag.capacity.set'),
        throwsA(isA<ProjectSnapshotException>().having(
            (error) => error.code, 'code', 'project.changed_during_snapshot')));
  });
  test(
      'history snapshots retain opaque project bytes without hydrating definitions',
      () async {
    final f = _Fixture(unrelated: 900);
    final snapshot = await f.loader.loadHistorySnapshot(f.handle);
    expect(snapshot.manifest.maps, isEmpty);
    expect(snapshot.manifest.facts, isEmpty);
    expect(snapshot.resourceBytes('project'), f.resources['project.json']);
    expect(f.reads, ['project.json', 'project.json']);
    expect(snapshot.availableProjectSections, isEmpty);
  });
  test('read dependencies cannot replace the retained project identity',
      () async {
    final f = _Fixture(unrelated: 0);
    await expectLater(
        f.loader.loadWorkshop(f.handle,
            actionId: 'item.create',
            readDependencies: const {'project': 'data/forged.json'}),
        throwsA(isA<ProjectSnapshotException>().having((error) => error.code,
            'code', 'project.workshop_dependency_invalid')));
    expect(f.reads, ['project.json']);
  });
  test('unscoped actions reject without reading the project', () async {
    final f = _Fixture(unrelated: 0);
    await expectLater(
        f.loader.loadWorkshop(f.handle, actionId: 'scene.delete'),
        throwsA(isA<ProjectSnapshotException>().having(
            (error) => error.code, 'code', 'project.workshop_scope_required')));
    expect(f.reads, isEmpty);
  });
}

class _Fixture {
  _Fixture({required int unrelated}) {
    raw = const ProjectManifest(name: 'Native', maps: [
      ProjectMapEntry(
          id: 'owner', name: 'Owner', relativePath: 'maps/owner.json')
    ], tilesets: []).toJson();
    for (final field in [
      'trainers',
      'facts',
      'scenes',
      'characters',
      'tilesets',
      'elements'
    ]) {
      raw[field] = [
        for (var i = 0; i < unrelated; i++)
          {'id': 'foreign_$i', 'name': 7, 'unmodeled': true}
      ];
    }
    raw['maps'] = <dynamic>[...(raw['maps'] as List)];
    (raw['maps'] as List).addAll(<dynamic>[
      for (var i = 0; i < unrelated; i++)
        {
          'id': 'foreign_$i',
          'name': 'Foreign',
          'relativePath': 'missing/$i.json'
        }
    ]);
    raw['unknownNativeField'] = {
      'preserve': [1, 2, 3]
    };
    updateProject();
    resources['maps/owner.json'] = utf8.encode(jsonEncode(const MapData(
            id: 'owner', name: 'Owner', size: GridSize(width: 1, height: 1))
        .toJson()));
    final registered = handles.registerProject(
        projectName: 'Native',
        initialFingerprint: 'sha256:${List.filled(64, '0').join()}',
        readBytes: (path) async {
          reads.add(path);
          if (path == 'project.json' &&
              changeProjectOnSecondRead &&
              reads.where((path) => path == 'project.json').length == 2) {
            return utf8.encode('{}');
          }
          final bytes = resources[path];
          if (bytes == null) {
            throw const WorkspaceAccessException(
                'workspace.file_unavailable', 'Missing dependency');
          }
          return bytes;
        });
    handle = registered.projectHandle;
    loader = ProjectSnapshotLoader(handles: handles);
    addTearDown(() => handles.closeWorkspace(registered.workspaceHandle));
  }
  final handles = WorkspaceHandleStore();
  final resources = <String, List<int>>{};
  final reads = <String>[];
  late Map<String, dynamic> raw;
  late ProjectHandle handle;
  late ProjectSnapshotLoader loader;
  var changeProjectOnSecondRead = false;
  void updateProject() {
    resources['project.json'] = utf8.encode(jsonEncode(raw));
  }
}
