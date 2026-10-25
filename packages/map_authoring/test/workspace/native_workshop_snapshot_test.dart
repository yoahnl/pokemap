import 'dart:convert';

import 'package:map_authoring/src/workspace/project_snapshot_loader.dart';
import 'package:map_authoring/src/workspace/project_snapshot.dart';
import 'package:map_authoring/src/workspace/workspace_handle_store.dart';
import 'package:map_authoring/src/ports/project_file_reader.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final unrelated in [0, 900]) {
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
