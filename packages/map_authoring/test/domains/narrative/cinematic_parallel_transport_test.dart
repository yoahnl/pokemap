import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../../../map_core/test/fixtures/cinematic_facing_fixture.dart';

void main() {
  for (final jsonl in [false, true]) {
    test('actor-relative coordinates survive direct and JSONL authoring jsonl=$jsonl', () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final asset = _jumpJson();
      final context = asset['stageContext'] as Map<String, dynamic>;
      context['initialPlacements'] = <Object>[];
      final point = (context['stagePoints'] as List).last as Map<String, dynamic>;
      point['relativeToActorId'] = 'actor'; point['x'] = -1.0; point['y'] = 2.0;
      final request = await f.request('cinematic.upsert', {'cinematic': asset});
      String planId;
      if (jsonl) {
        final plan = await f.command('plan', {'projectHandle': f.opened.projectHandle.value, 'request': request.toJson()});
        expect(plan.status, AuthoringResultStatus.success, reason: jsonEncode(plan.toJson()));
        planId = plan.data['planId'] as String;
      } else {
        planId = (await f.api.planMutation(f.opened.projectHandle, request)).planId;
      }
      if (jsonl) {
        final applied = await f.command('apply', {'projectHandle': f.opened.projectHandle.value, 'planId': planId, 'operationId': 'relative'});
        expect(applied.status, AuthoringResultStatus.success, reason: jsonEncode(applied.toJson()));
      } else {
        await f.api.applyMutation(f.opened.projectHandle, planId: planId, operationId: 'relative');
      }
      final persisted = (await f.loader.load(f.opened.projectHandle)).manifest.cinematics.single;
      expect(persisted.stageContext!.stagePoints.last.relativeToActorId, 'actor');
      expect(persisted.stageContext!.stagePoints.last.x, -1);
      expect(jsonEncode((await f.command('describe', {})).toJson()), contains('relativeToActorId'));
      final before = await f.file.readAsBytes();
      point['relativeToActorId'] = 'missing';
      final invalid = await f.request('cinematic.upsert', {'cinematic': asset});
      if (jsonl) {
        final rejected = await f.command('plan', {'projectHandle': f.opened.projectHandle.value, 'request': invalid.toJson()});
        expect(rejected.status, isNot(AuthoringResultStatus.success));
      } else {
        await expectLater(f.api.planMutation(f.opened.projectHandle, invalid), throwsA(anything));
      }
      expect(await f.file.readAsBytes(), before);

    });

    test(
      'parallel group is validated and persisted canonically jsonl=$jsonl',
      () async {
        final f = await _Fixture.create();
        addTearDown(f.dispose);
        final asset = _jumpJson();
        final request = await f.request('cinematic.upsert', {
          'cinematic': asset,
        });
        final before = await f.file.readAsBytes();
        late String planId;
        if (jsonl) {
          final plan = await f.command('plan', {
            'projectHandle': f.opened.projectHandle.value,
            'request': request.toJson(),
          });
          expect(
            plan.status,
            AuthoringResultStatus.success,
            reason: jsonEncode(plan.toJson()),
          );
          planId = plan.data['planId'] as String;
        } else {
          planId = (await f.api.planMutation(
            f.opened.projectHandle,
            request,
          )).planId;
        }
        expect(await f.file.readAsBytes(), before);
        if (jsonl) {
          final applied = await f.command('apply', {
            'projectHandle': f.opened.projectHandle.value,
            'planId': planId,
            'operationId': 'jump',
          });
          expect(
            applied.status,
            AuthoringResultStatus.success,
            reason: jsonEncode(applied.toJson()),
          );
        } else {
          await f.api.applyMutation(
            f.opened.projectHandle,
            planId: planId,
            operationId: 'jump',
          );
        }
        final persisted = (await f.loader.load(f.opened.projectHandle))
            .manifest
            .cinematics
            .single;
        expect(persisted.toJson(), asset);
        final describe = await f.command('describe', {});
        expect(jsonEncode(describe.toJson()), contains('parallelGroupId'));
      },
    );
    test('invalid group refuses without changing bytes jsonl=$jsonl', () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final before = await f.file.readAsBytes();
      for (final mutation in <void Function(Map<String, dynamic>)>[
        (step) => step['parallelGroupId'] = null,
        (step) => step['parallelGroupId'] = ' group',
        (step) => step['actorId'] = 'missing',
        (step) => step['durationMs'] = 0,
        (step) => step['kind'] = 'marker',
        (step) => step['parallelGroupId'] = 42,
      ]) {
        final asset = _jumpJson();
        final step =
            ((asset['timeline'] as Map)['steps'] as List)[1]
                as Map<String, dynamic>;
        mutation(step);
        final request = await f.request('cinematic.upsert', {
          'cinematic': asset,
        });
        if (jsonl) {
          final result = await f.command('plan', {
            'projectHandle': f.opened.projectHandle.value,
            'request': request.toJson(),
          });
          expect(result.status, isNot(AuthoringResultStatus.success));
        } else {
          await expectLater(
            f.api.planMutation(f.opened.projectHandle, request),
            throwsA(anything),
          );
        }
        expect(await f.file.readAsBytes(), before);
      }
    });
  }
}

Map<String, dynamic> _jumpJson() {
  final json = facingCinematic().toJson();
  final step =
      ((json['timeline'] as Map)['steps'] as List).last as Map<String, dynamic>;
  step['kind'] = 'actorJump';
  step['metadata'] = <String, String>{
    'authoring.kind': 'basicBlock',
    'authoring.source': 'cinematic-builder-v0',
    'authoring.block': 'actorJump',
    'actor.jumpHeightCells': '0.5',
    'actor.facingMode': 'preserve',
  };
  step['parallelGroupId'] = 'pair';
  ((json['timeline'] as Map)['steps'] as List).add({
    'id': 'wait',
    'kind': 'wait',
    'durationMs': 1500,
    'parallelGroupId': 'pair',
    'metadata': <String, String>{},
  });
  return jsonDecode(jsonEncode(json)) as Map<String, dynamic>;
}

class _Fixture {
  _Fixture(
    this.directory,
    this.handles,
    this.opened,
    this.loader,
    this.api,
    this.readApi,
  );
  final Directory directory;
  final WorkspaceHandleStore handles;
  final OpenedProject opened;
  final ProjectSnapshotLoader loader;
  final LocalMapAuthoringMutationApi api;
  final AuthoringReadApi readApi;
  File get file => File('${directory.path}/project.json');

  static Future<_Fixture> create({
    ProjectVersion version = ProjectVersion.v8,
  }) async {
    final directory = await Directory.systemTemp.createTemp(
      'cinematic_parallel_',
    );
    await File('${directory.path}/project.json').writeAsString(
      jsonEncode(
        ProjectManifest(
          name: 'Cinematic',
          version: version,
          maps: const [
            ProjectMapEntry(
              id: 'room',
              name: 'Room',
              relativePath: 'maps/room.json',
            ),
          ],
          tilesets: const [],
        ).toJson(),
      ),
    );
    final mapFile = File('${directory.path}/maps/room.json');
    await mapFile.parent.create(recursive: true);
    await mapFile.writeAsString(
      jsonEncode(
        MapData(
          id: 'room',
          name: 'Room',
          size: const GridSize(width: 16, height: 16),
        ).toJson(),
      ),
    );
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [directory.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final opener = ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
    );
    final opened = await opener.openProject(directory.path);
    final loader = ProjectSnapshotLoader(handles: handles);
    final api = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: loader,
    );
    await api.attachProject(
      projectRootPath: directory.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    return _Fixture(
      directory,
      handles,
      opened,
      loader,
      api,
      AuthoringReadApi(openService: opener, snapshotLoader: loader),
    );
  }

  Future<AuthoringRequest> request(
    String action,
    Map<String, Object?> parameters,
  ) async => AuthoringRequest(
    requestId: '$action-${DateTime.now().microsecondsSinceEpoch}',
    actionId: action,
    actionVersion: 1,
    workspaceHandle: opened.workspaceHandle.value,
    expectedRevision: (await loader.load(opened.projectHandle)).revision,
    idempotencyKey: '$action-${DateTime.now().microsecondsSinceEpoch}',
    parameters: parameters,
  );

  Future<AuthoringResult> command(
    String name,
    Map<String, Object?> args,
  ) async => AuthoringResult.fromJson(
    jsonDecode(
      await JsonlWorker(
        api: readApi,
        mutations: api,
      ).processLine(jsonEncode({'id': name, 'command': name, 'args': args})),
    ) as Map<String, dynamic>,
  );

  Future<void> dispose() async {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    await directory.delete(recursive: true);
  }
}
