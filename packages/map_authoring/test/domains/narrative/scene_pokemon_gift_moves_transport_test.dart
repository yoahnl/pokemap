import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'scene_trainer_defeated_transport_test.dart' as base;

void main() {
  for (final interactive in [false, true]) {
    for (final jsonl in [false, true]) {
      test(
          '${interactive ? 'interactive' : 'consequence'} gift move references over ${jsonl ? 'JSONL' : 'API'}',
          () async {
        final root = await Directory.systemTemp.createTemp('gift-moves-');
        addTearDown(() => root.delete(recursive: true));
        final file = File('${root.path}/project.json');
        final map = MapData(
            id: 'room',
            name: 'Room',
            size: const GridSize(width: 16, height: 16));
        final mapFile = File('${root.path}/maps/room.json');
        await mapFile.parent.create(recursive: true);
        await mapFile.writeAsString(jsonEncode(map.toJson()));
        final mapBefore = await mapFile.readAsBytes();
        Map<String, Object?> gift(Object? moves) => {
              'kind': interactive
                  ? 'receivePokemonFromCatalog'
                  : 'givePokemonFromCatalog',
              'speciesId': 'sproutle',
              'formId': 'sunny',
              'level': 8,
              if (moves != null) 'moveIds': moves,
              if (interactive) ...{
                'nicknamePolicy': 'offer',
                'nicknameMaxGraphemes': 12,
                'pokedexPresentationPolicy': 'whenNewAndPokedexVisible'
              },
            };
        Map<String, Object?> node(Object? moves) => {
              'id': 'gift',
              'kind': 'action',
              'title': 'Compagnon',
              'payload': {
                interactive ? 'interactiveCommand' : 'consequence': gift(moves)
              },
            };
        Map<String, Object?> scene(Object? moves) => {
              'id': 'gift-scene',
              'name': 'Compagnon',
              'metadata': {'preserved': 'yes'},
              'graph': {
                'startNodeId': 'start',
                'nodes': [
                  {'id': 'start', 'kind': 'start'},
                  node(moves),
                  {'id': 'end', 'kind': 'end'},
                ],
                'edges': [
                  {
                    'id': 'enter',
                    'fromNodeId': 'start',
                    'fromPortId': 'completed',
                    'toNodeId': 'gift',
                    'kind': 'default'
                  },
                  for (final port in interactive
                      ? ['party', 'pc', 'noCapacity']
                      : ['completed'])
                    {
                      'id': 'leave-$port',
                      'fromNodeId': 'gift',
                      'fromPortId': port,
                      'toNodeId': 'end',
                      'kind': 'actionCompleted'
                    },
                ]
              },
            };
        final project = base.fixture().copyWith(
          maps: [
            const ProjectMapEntry(
                id: 'room', name: 'Room', relativePath: 'maps/room.json')
          ],
          scenes: [
            SceneAsset.fromJson({...scene(null), 'name': 'Original'})
          ],
          trainers: [],
          pokemon: base.fixture().pokemon.copyWith(
              enabled: true, catalogFiles: {'moves': 'data/moves.json'}),
        );
        await file.writeAsString(jsonEncode(project.toJson()));
        final movesFile = File('${root.path}/data/moves.json');
        await movesFile.parent.create(recursive: true);
        Future<void> catalogue(List<Object?> entries) async =>
            movesFile.writeAsString(jsonEncode({
              'schemaVersion': 1,
              'kind': 'catalog',
              'catalog': 'moves',
              'entries': entries,
            }));
        await catalogue([
          {'id': 'tackle'},
          {'id': 'exceptional'}
        ]);
        const reader = LocalProjectFileReader();
        final policy = await WorkspacePolicy.create(
            allowedRootPaths: [root.path], fileReader: reader);
        final handles = WorkspaceHandleStore();
        final snapshots = ProjectSnapshotLoader(handles: handles);
        final api = AuthoringReadApi(
            openService: ProjectOpenService(
                policy: policy, fileReader: reader, handles: handles),
            snapshotLoader: snapshots);
        final mutations = LocalMapAuthoringMutationApi(
            policy: policy, snapshotLoader: snapshots);
        final worker = JsonlWorker(api: api, mutations: mutations);
        var opened = await api.openProject(root.path);
        Future<void> attach() => mutations.attachProject(
            projectRootPath: root.path,
            workspaceHandle: opened.workspaceHandle,
            projectHandle: opened.projectHandle);
        await attach();
        var sequence = 0;
        Future<AuthoringResult> transport(
                String command, Map<String, Object?> args) async =>
            AuthoringResult.fromJson(jsonDecode(await worker.processLine(
                jsonEncode({
              'id': 'gift-$sequence',
              'command': command,
              'args': args
            }))) as Map<String, dynamic>);
        final actions = [
          'scene.upsert',
          'scene.graph.patch',
          if (interactive) 'scene.interactive_command.set',
          'narrative.publish_document'
        ];
        Future<Map<String, Object?>> plan(String action, Object? moves,
            {bool failure = false}) async {
          final request = AuthoringRequest(
              requestId: 'gift-${++sequence}',
              actionId: action,
              actionVersion: 1,
              workspaceHandle: opened.workspaceHandle.value,
              expectedRevision:
                  (await snapshots.load(opened.projectHandle)).revision,
              idempotencyKey: 'gift-$sequence',
              parameters: switch (action) {
                'scene.upsert' => {'scene': scene(moves)},
                'scene.graph.patch' => {
                    'sceneId': 'gift-scene',
                    'upsertNodes': [node(moves)]
                  },
                'scene.interactive_command.set' => {
                    'sceneId': 'gift-scene',
                    'nodeId': 'gift',
                    'command': gift(moves)
                  },
                _ => {
                    'map': map.toJson(),
                    'mapRevision': narrativeEventBytesFingerprint(
                        await mapFile.readAsBytes()),
                    'scenes': [scene(moves)]
                  },
              });
          final before = await file.readAsBytes();
          if (jsonl) {
            final result = await transport('plan', {
              'projectHandle': opened.projectHandle.value,
              'request': request.toJson()
            });
            expect(
                result.status,
                failure
                    ? AuthoringResultStatus.failure
                    : AuthoringResultStatus.success,
                reason: jsonEncode(result.toJson()));
            if (failure) {
              expect(result.error!.details['domainCode'],
                  isNot('worker.internal'));
            }
            expect(await file.readAsBytes(), before);
            expect(await mapFile.readAsBytes(), mapBefore);
            return result.data;
          }
          if (failure) {
            await expectLater(mutations.plan(opened.projectHandle, request),
                throwsA(isA<NarrativeAuthoringException>()));
            expect(await file.readAsBytes(), before);
            expect(await mapFile.readAsBytes(), mapBefore);
            return {};
          }
          final result = await mutations.plan(opened.projectHandle, request);
          expect(await file.readAsBytes(), before);
          expect(await mapFile.readAsBytes(), mapBefore);
          return result;
        }

        for (final action in actions) {
          await plan(action, ['missing'], failure: true);
        }
        for (final entries in [
          [
            {'id': 'tackle'},
            {'id': 'tackle'}
          ],
          [null]
        ]) {
          await catalogue(entries);
          for (final action in actions) {
            await plan(action, ['tackle'], failure: true);
          }
        }
        await movesFile.writeAsString('{');
        await plan('scene.upsert', ['tackle'], failure: true);
        await movesFile.delete();
        await plan('scene.upsert', ['tackle'], failure: true);
        await plan('scene.upsert', null);
        await catalogue([
          {'id': 'tackle'},
          {'id': 'exceptional'}
        ]);
        for (final invalid in [
          <String>[],
          ['tackle', 'tackle'],
          [' tackle'],
          ['tackle', 'a', 'b', 'c', 'd'],
          [7],
          'tackle'
        ]) {
          for (final action in actions) {
            await plan(action, invalid, failure: true);
          }
        }
        for (final action in actions) {
          final selected = actions.indexOf(action).isEven
              ? ['exceptional', 'tackle']
              : ['tackle', 'exceptional'];
          final planned = await plan(action, selected);
          if (jsonl) {
            expect(
                (await transport('apply', {
                  'projectHandle': opened.projectHandle.value,
                  'planId': planned['planId'],
                  'operationId': 'apply-$sequence'
                }))
                    .status,
                AuthoringResultStatus.success);
          } else {
            await mutations.apply(opened.projectHandle,
                planId: planned['planId']! as String,
                operationId: 'apply-$sequence');
          }
          final stored = ProjectManifest.fromJson(
              jsonDecode(await file.readAsString()) as Map<String, dynamic>);
          final payload = stored.scenes.single.graph.nodes
              .singleWhere((value) => value.id == 'gift')
              .payload as SceneActionPayload;
          expect(
              (payload.consequence?.toJson() ??
                  payload.interactiveCommand!.toJson())['moveIds'],
              selected);
        }
        await api.closeWorkspace(opened.workspaceHandle);
        opened = await api.openProject(root.path);
        await attach();
        await catalogue([
          {'id': 'tackle'}
        ]);
        final queried = await api.queryProject(
            opened.projectHandle,
            AuthoringQueryRequest(
                resourceKind: 'scene',
                operation: AuthoringQueryOperation.get,
                ids: ['gift-scene'],
                view: AuthoringQueryView.detail));
        expect(jsonEncode(queried.items.single['diagnostics']),
            contains('commandPokemonMoveRefUnknown'));
        await api.closeWorkspace(opened.workspaceHandle);
      });
    }
  }
}
