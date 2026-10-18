import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'scene_graph_patch_test.dart' show fixture;

void main() {
  test(
      'L15 character deletion refuses to erase an avatar still referenced by a Scene',
      () async {
    final f = await _AvatarFixture.create();
    addTearDown(f.dispose);
    final authored =
        await f.mutations.plan(f.project, await f.request('uniform'));
    await f.mutations.apply(f.project,
        planId: authored['planId']! as String,
        operationId: 'author-avatar-before-delete');
    Future<AuthoringRequest> deletion(
        {bool inspect = false, String resolution = 'clear'}) async {
      final id = 'delete-avatar-${++f.sequence}';
      return AuthoringRequest(
          requestId: id,
          actionId:
              'characterStudio.character.${inspect ? 'deletePlan' : 'delete'}',
          actionVersion: 1,
          workspaceHandle: f.workspace.value,
          parameters: {
            'characterId': 'uniform',
            if (!inspect) 'resolution': resolution,
            if (!inspect && resolution == 'replace') 'replacementId': 'original'
          },
          expectedRevision: (await f.snapshots.load(f.project)).revision,
          idempotencyKey: id,
          dryRun: inspect);
    }

    final before = await f.file.readAsBytes();
    final preview =
        await f.mutations.plan(f.project, await deletion(inspect: true));
    expect(jsonEncode(preview), contains('scenePlayerAvatar'));
    expect(jsonEncode(preview),
        contains('scene_player_avatar_character_required'));
    for (final resolution in ['clear', 'replace']) {
      await expectLater(
          f.mutations.plan(f.project, await deletion(resolution: resolution)),
          throwsA(isA<CharacterStudioActionException>().having(
              (error) => error.code,
              'code',
              'character_studio.character.${resolution == 'clear' ? 'clear' : 'replacement'}_incompatible')));
      expect(await f.file.readAsBytes(), before);
    }
    await expectLater(
        f.mutations.plan(f.project, await deletion(resolution: 'cancel')),
        throwsA(isA<CharacterStudioActionException>().having(
            (error) => error.code,
            'code',
            'character_studio.character.delete_cancelled')));
    expect(await f.file.readAsBytes(), before);
  });

  test('L15 canonical actions describe persistent player avatar semantics', () {
    for (final id in ['scene.graph.patch', 'scene.upsert']) {
      final action =
          SceneActions.descriptors.singleWhere((entry) => entry.id == id);
      final contract = action.extensions['setPlayerAvatar'];
      expect(contract, isA<Map>(), reason: id);
      final avatar = contract! as Map;
      expect(avatar['consequenceKind'], 'setPlayerAvatar');
      expect(avatar['parameters'], ['characterId']);
      expect(avatar['projectDimensions'], ['twoD', 'threeD']);
      expect(avatar['persistentField'], 'trainerProfile.avatarCharacterId');
      expect(avatar['restoration'], 'explicitCharacterSelection');
      expect(avatar['collisionEffect'], 'none');
    }
  });

  for (final jsonl in [false, true]) {
    for (final spatial in [false, true]) {
      test(
          'L15 ${jsonl ? 'JSONL' : 'API'} avatar change and restoration cold reopen ${spatial ? '3D' : '2D'}',
          () async {
        final f = await _AvatarFixture.create(spatial: spatial);
        addTearDown(f.dispose);
        final other = f.initial.scenes.last;
        final layout = f.initial.scenes.first.layout;
        for (final characterId in ['uniform', 'original']) {
          final before = await f.file.readAsBytes();
          final request = await f.request(characterId);
          final plan = jsonl
              ? await f.success('plan', {
                  'projectHandle': f.project.value,
                  'request': request.toJson()
                })
              : await f.mutations.plan(f.project, request);
          expect(await f.file.readAsBytes(), before);
          if (jsonl) {
            await f.success('apply', {
              'projectHandle': f.project.value,
              'planId': plan['planId'],
              'operationId': 'apply-${f.sequence}'
            });
          } else {
            await f.mutations.apply(f.project,
                planId: plan['planId']! as String,
                operationId: 'apply-${f.sequence}');
          }
          await f.close();
          await f.open();
          final snapshot = await f.snapshots.load(f.project);
          final scene = snapshot.manifest.scenes.first;
          final payload = scene.graph.nodes
              .singleWhere((node) => node.id == 'action')
              .payload as SceneActionPayload;
          expect(payload.consequence!.toJson(),
              {'kind': 'setPlayerAvatar', 'characterId': characterId});
          expect(scene.layout, layout);
          expect(snapshot.manifest.scenes.last, other);
          final query = await f.success('query', {
            'projectHandle': f.project.value,
            'request': AuthoringQueryRequest(
                resourceKind: 'scene',
                operation: AuthoringQueryOperation.get,
                view: AuthoringQueryView.detail,
                ids: ['test']).toJson()
          });
          expect(jsonEncode(query), contains(characterId));
        }
      });
    }

    test(
        'L15 ${jsonl ? 'JSONL' : 'API'} refuses invalid avatar references and payloads before writing',
        () async {
      final f = await _AvatarFixture.create();
      addTearDown(f.dispose);
      for (final payload in [
        {'kind': 'setPlayerAvatar', 'characterId': 'missing'},
        {'kind': 'setPlayerAvatar', 'characterId': 'duplicate'},
        {'kind': 'setPlayerAvatar', 'characterId': 'no-sheet'},
        {'kind': 'setPlayerAvatar', 'characterId': 'bad-size'},
        {'kind': 'setPlayerAvatar', 'characterId': ''},
        {
          'kind': 'setPlayerAvatar',
          'characterId': 'uniform',
          'collisionWidth': 5
        },
        {'kind': 'setPlayerAvatar', 'characterId': null},
      ]) {
        for (final action in ['scene.graph.patch', 'scene.upsert']) {
          final before = await f.file.readAsBytes();
          final request =
              await f.request('uniform', payload: payload, action: action);
          if (jsonl) {
            final result = await f.command('plan', {
              'projectHandle': f.project.value,
              'request': request.toJson()
            });
            expect(result.status, AuthoringResultStatus.failure,
                reason: '$action $payload');
          } else {
            await expectLater(f.mutations.plan(f.project, request),
                throwsA(isA<NarrativeAuthoringException>()),
                reason: '$action $payload');
          }
          expect(await f.file.readAsBytes(), before);
        }
      }
    });
  }
}

final class _AvatarFixture {
  _AvatarFixture(this.root, this.initial, this.api, this.snapshots,
      this.mutations, this.worker);
  final Directory root;
  final ProjectManifest initial;
  final AuthoringReadApi api;
  final ProjectSnapshotLoader snapshots;
  final LocalMapAuthoringMutationApi mutations;
  final JsonlWorker worker;
  late ProjectHandle project;
  late WorkspaceHandle workspace;
  var sequence = 0;
  File get file => File('${root.path}/project.json');

  static Future<_AvatarFixture> create({bool spatial = false}) async {
    final root = await Directory.systemTemp.createTemp('l15-avatar-authoring-');
    final initial = fixture().copyWith(
      version: spatial ? ProjectVersion.v9 : ProjectVersion.v8,
      settings: ProjectSettings(
          dimension: spatial ? ProjectDimension.threeD : ProjectDimension.twoD),
      characters: [
        for (final id in ['original', 'uniform', 'duplicate', 'duplicate'])
          ProjectCharacterEntry(
              id: id,
              name: id,
              tilesetId: 'actors',
              animations: [
                for (final direction in EntityFacing.values)
                  CharacterAnimation(
                      state: CharacterAnimationState.walk,
                      direction: direction,
                      frames: [
                        CharacterAnimationFrame(
                            source: TilesetSourceRect(
                                x: 0, y: 0, width: 16, height: 32)),
                      ]),
              ]),
        const ProjectCharacterEntry(
            id: 'no-sheet', name: 'Missing', tilesetId: 'absent'),
        const ProjectCharacterEntry(
            id: 'bad-size',
            name: 'Invalid',
            tilesetId: 'actors',
            frameWidth: 0),
      ],
      tilesets: [
        const ProjectTilesetEntry(
            id: 'actors', name: 'Actors', relativePath: 'tilesets/actors.json')
      ],
    );
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(initial.toJson()));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final api = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles),
        snapshotLoader: snapshots);
    final mutations =
        LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: snapshots);
    final f = _AvatarFixture(root, initial, api, snapshots, mutations,
        JsonlWorker(api: api, mutations: mutations));
    await f.open();
    return f;
  }

  Future<AuthoringResult> command(
          String name, Map<String, Object?> args) async =>
      AuthoringResult.fromJson(jsonDecode(await worker.processLine(jsonEncode(
              {'id': 'avatar-${++sequence}', 'command': name, 'args': args})))
          as Map<String, dynamic>);
  Future<Map<String, Object?>> success(
      String name, Map<String, Object?> args) async {
    final result = await command(name, args);
    expect(result.status, AuthoringResultStatus.success,
        reason: jsonEncode(result.toJson()));
    return result.data;
  }

  Future<void> open() async {
    final data = await success('open', {'projectRoot': root.path});
    project = ProjectHandle(data['projectHandle']! as String);
    workspace = WorkspaceHandle(data['workspaceHandle']! as String);
  }

  Future<void> close() async => api.closeWorkspace(workspace);
  Future<AuthoringRequest> request(String characterId,
      {Map<String, Object?>? payload,
      String action = 'scene.graph.patch'}) async {
    final node = {
      'id': 'action',
      'kind': 'action',
      'payload': {
        'consequence':
            payload ?? {'kind': 'setPlayerAvatar', 'characterId': characterId}
      }
    };
    final id = 'avatar-${++sequence}';
    final scene = initial.scenes.first.toJson();
    final graph = Map<String, dynamic>.from(scene['graph'] as Map);
    graph['nodes'] = [
      for (final item in graph['nodes'] as List)
        if ((item as Map)['id'] == 'action') node else item
    ];
    scene['graph'] = graph;
    return AuthoringRequest(
        requestId: id,
        actionId: action,
        actionVersion: 1,
        workspaceHandle: workspace.value,
        expectedRevision: (await snapshots.load(project)).revision,
        idempotencyKey: id,
        parameters: action == 'scene.upsert'
            ? {'scene': scene}
            : {
                'sceneId': 'test',
                'upsertNodes': [node]
              });
  }

  Future<void> dispose() async {
    await close();
    await root.delete(recursive: true);
  }
}
