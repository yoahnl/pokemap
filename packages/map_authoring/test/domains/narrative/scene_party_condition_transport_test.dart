import 'dart:convert';
import 'dart:io';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import 'scene_trainer_defeated_transport_test.dart' as base;
import 'package:map_authoring/src/domains/narrative/scene_party_move_catalog.dart';

void main() {
  for (final jsonl in [false, true]) {
    test(
        'party conditions validate catalogue over ${jsonl ? 'JSONL' : 'direct API'}',
        () async {
      final root = await Directory.systemTemp.createTemp('scene-party-');
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
      final project = base.fixture().copyWith(
          maps: [
            const ProjectMapEntry(
                id: 'room', name: 'Room', relativePath: 'maps/room.json')
          ],
          trainers: [],
          pokemon: base.fixture().pokemon.copyWith(
              enabled: true, catalogFiles: {'moves': 'data/moves.json'}));
      await file.writeAsString(jsonEncode(project.toJson()));
      final moves = File('${root.path}/data/moves.json');
      await moves.parent.create(recursive: true);
      Future<void> catalogue(List<Object?> entries) =>
          moves.writeAsString(jsonEncode({
            'schemaVersion': 1,
            'kind': 'catalog',
            'catalog': 'moves',
            'entries': entries
          }));
      await catalogue([
        {'id': 'tackle', 'name': 'Charge'}
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
      final opened = await api.openProject(root.path);
      addTearDown(() => api.closeWorkspace(opened.workspaceHandle));
      await mutations.attachProject(
          projectRootPath: root.path,
          workspaceHandle: opened.workspaceHandle,
          projectHandle: opened.projectHandle);
      var sequence = 0;
      Future<Map<String, Object?>> plan(
          SceneConditionSource source, String action,
          {bool failure = false, Map<String, Object?>? rawSource}) async {
        final current = ProjectManifest.fromJson(
            jsonDecode(await file.readAsString()) as Map<String, dynamic>);
        final scene = updateSceneConditionSource(current.scenes.first,
                nodeId: 'condition', source: source)
            .updatedScene;
        final node =
            scene.graph.nodes.singleWhere((value) => value.id == 'condition');
        final id = 'party-${++sequence}';
        final request = AuthoringRequest(
            requestId: id,
            actionId: action,
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision:
                (await snapshots.load(opened.projectHandle)).revision,
            idempotencyKey: id,
            parameters: switch (action) {
              'narrative.publish_document' => {
                  'map': map.toJson(),
                  'mapRevision': narrativeEventBytesFingerprint(
                      await mapFile.readAsBytes()),
                  'scenes': [scene.toJson()]
                },
              'scene.upsert' => {'scene': scene.toJson()},
              'scene.graph.patch' => {
                  'sceneId': scene.id,
                  'upsertNodes': [node.toJson()]
                },
              _ => {
                  'sceneId': scene.id,
                  'nodeId': node.id,
                  'conditionSource': rawSource ?? source.toJson()
                },
            });
        if (jsonl) {
          final result = AuthoringResult.fromJson(
              jsonDecode(await worker.processLine(jsonEncode({
            'id': id,
            'command': 'plan',
            'args': {
              'projectHandle': opened.projectHandle.value,
              'request': request.toJson()
            }
          }))) as Map<String, dynamic>);
          expect(
              result.status,
              failure
                  ? AuthoringResultStatus.failure
                  : AuthoringResultStatus.success,
              reason: result.toJson().toString());
          if (failure) {
            expect(
                result.error!.details['domainCode'], isNot('worker.internal'));
            return {};
          }
          return result.data;
        }
        if (failure) {
          await expectLater(mutations.plan(opened.projectHandle, request),
              throwsA(isA<NarrativeAuthoringException>()));
          return {};
        }
        return mutations.plan(opened.projectHandle, request);
      }

      await plan(
          SceneConditionSource.partyCanReceivePokemon(), 'scene.condition.set',
          failure: true,
          rawSource: {
            'sourceKind': 'partyState',
            'sourceId': 7,
            'operator': 'isTrue'
          });
      final deferred = await snapshots.load(opened.projectHandle,
          deferPokemonDocuments: true);
      expect(deferred.inlineResourceBytes.containsKey('pokemonCatalog:moves'),
          isFalse);
      expect(await loadScenePartyMoveCatalog(deferred), {'tackle'});
      final before = await file.readAsBytes();
      for (final entries in [
        <Object?>[
          {'id': 'other', 'name': 'Other'}
        ],
        <Object?>[
          {'id': 'tackle'},
          {'id': 'tackle'}
        ],
        <Object?>[null],
      ]) {
        await catalogue(entries);
        for (final action in [
          'scene.condition.set',
          'scene.graph.patch',
          'scene.upsert',
          'narrative.publish_document'
        ]) {
          await plan(
              SceneConditionSource.partyKnowsMove(moveId: 'tackle'), action,
              failure: true);
          expect(await file.readAsBytes(), before);
          expect(await mapFile.readAsBytes(), mapBefore);
        }
      }
      for (final malformed in ['{', '[]']) {
        await moves.writeAsString(malformed);
        for (final action in [
          'scene.condition.set',
          'scene.graph.patch',
          'scene.upsert',
          'narrative.publish_document'
        ]) {
          await plan(
              SceneConditionSource.partyHasUsableMove(moveId: 'tackle'), action,
              failure: true);
          expect(await file.readAsBytes(), before);
          expect(await mapFile.readAsBytes(), mapBefore);
        }
      }
      await moves.delete();
      for (final action in [
        'scene.condition.set',
        'scene.graph.patch',
        'scene.upsert',
        'narrative.publish_document'
      ]) {
        await plan(
            SceneConditionSource.partyKnowsMove(moveId: 'tackle'), action,
            failure: true);
        expect(await file.readAsBytes(), before);
        expect(await mapFile.readAsBytes(), mapBefore);
      }
      await plan(
          SceneConditionSource.partyCanReceivePokemon(), 'scene.condition.set');
      await plan(
          SceneConditionSource.partyCanUseFieldAbility(
              ability: FieldAbility.surf),
          'scene.condition.set');
      await catalogue([
        {'id': 'tackle', 'name': 'Charge'}
      ]);
      for (final expected in [true, false]) {
        for (final source in [
          SceneConditionSource.partyCanReceivePokemon(expected: expected),
          SceneConditionSource.partyKnowsMove(
              moveId: 'tackle', expected: expected),
          SceneConditionSource.partyHasUsableMove(
              moveId: 'tackle', expected: expected),
          SceneConditionSource.partyCanUseFieldAbility(
              ability: FieldAbility.rockSmash, expected: expected),
        ]) {
          final beforePlan = await file.readAsBytes();
          final planned = await plan(source, 'scene.condition.set');
          expect(await file.readAsBytes(), beforePlan);
          if (jsonl) {
            final result = AuthoringResult.fromJson(
                jsonDecode(await worker.processLine(jsonEncode({
              'id': 'apply-$sequence',
              'command': 'apply',
              'args': {
                'projectHandle': opened.projectHandle.value,
                'planId': planned['planId'],
                'operationId': 'apply-$sequence'
              }
            }))) as Map<String, dynamic>);
            expect(result.status, AuthoringResultStatus.success);
          } else {
            await mutations.apply(opened.projectHandle,
                planId: planned['planId']! as String,
                operationId: 'apply-$sequence');
          }
          final saved = ProjectManifest.fromJson(
              jsonDecode(await file.readAsString()) as Map<String, dynamic>);
          expect(
              (saved.scenes.first.graph.nodes
                      .singleWhere((node) => node.id == 'condition')
                      .payload as SceneConditionPayload)
                  .conditionSource,
              source);
          final query = await api.queryProject(
              opened.projectHandle,
              AuthoringQueryRequest(
                  resourceKind: 'scene',
                  operation: AuthoringQueryOperation.get,
                  ids: ['test'],
                  view: AuthoringQueryView.detail));
          final diagnostics = query.items.single['diagnostics'] as List;
          expect(
              diagnostics.where((value) => (value as Map)['code']
                  .toString()
                  .startsWith('conditionPartyMove')),
              isEmpty);
          if (source.partyMoveId != null) {
            for (final action in [
              'scene.graph.patch',
              'scene.upsert',
              'narrative.publish_document'
            ]) {
              await plan(
                  SceneConditionSource.fromJson({
                    ...source.toJson(),
                    'operator': expected ? 'isFalse' : 'isTrue'
                  }),
                  action);
            }
            await catalogue([
              {'id': 'other'}
            ]);
            final invalidQuery = await api.queryProject(
                opened.projectHandle,
                AuthoringQueryRequest(
                    resourceKind: 'scene',
                    operation: AuthoringQueryOperation.get,
                    ids: ['test'],
                    view: AuthoringQueryView.detail));
            expect(jsonEncode(invalidQuery.items.single['diagnostics']),
                contains('conditionPartyMoveRefUnknown'));
            await plan(source, 'scene.condition.set', failure: true);
            await catalogue([
              {'id': 'tackle', 'name': 'Charge'}
            ]);
          }
          expect(saved.scenes.last, project.scenes.last);
          expect(saved.scenes.first.layout, project.scenes.first.layout);
          expect(saved.facts, isEmpty);
        }
      }
    });
  }
}
