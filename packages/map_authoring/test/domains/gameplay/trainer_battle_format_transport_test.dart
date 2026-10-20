import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final shared = jsonDecode(
    File('test/fixtures/trainer_battle_format.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final doubles = Map<String, dynamic>.from(shared['doubles'] as Map);
  final canonicalTeam = ProjectTrainerEntry.fromJson(doubles).toJson()['team'];
  final codes = shared['domainCodes'] as Map;

  test('trainer action exposes the explicit supported format contract', () {
    final descriptor = CampaignContentActions.descriptors.singleWhere(
      (entry) => entry.id == 'campaign.trainer.upsert',
    );

    expect(descriptor.extensions['trainerBattleFormat'], shared['descriptor']);
  });

  test('ruleset action exposes both complete named profiles with beta default',
      () {
    final descriptor = PokemonRulesetActions.descriptors.singleWhere(
      (entry) => entry.id == 'pokemon.ruleset.set',
    );

    expect(descriptor.extensions['profiles'], {
      'default': 'pokemap-beta-v1',
      'values': [shared['betaProfile'], shared['standardProfile']],
    });
  });

  for (final wire in [false, true]) {
    final transport = wire ? 'JSONL' : 'API';
    test(
        '$transport preserves format through replay, stale, undo and cold open',
        () async {
      var fixture = await _Fixture.create(shared);
      final root = fixture.root;
      addTearDown(() async {
        await fixture.close();
        await root.delete(recursive: true);
      });
      final initial = await fixture.manifest.readAsBytes();
      final protectedMap = await fixture.map.readAsBytes();
      expect((await fixture.trainer(wire))['battleFormat'], 'singles');
      await fixture.refusesUnchanged(
        doubles,
        wire,
        codes['featureDisabled'] as String,
      );
      await fixture.apply(
        await fixture.planAction('pokemon.ruleset.set',
            {'profile': shared['standardProfile']}, wire),
        wire,
        'profile-apply',
      );
      final profileOnly = await fixture.manifest.readAsBytes();
      final profileHistory = await fixture.call('history', {'limit': 1}, wire);
      final profileEntry = (profileHistory['entries'] as List).single as Map;
      final stale =
          await fixture.plan({...doubles, 'name': 'Stale draft'}, wire);
      final planned = await fixture.plan(doubles, wire);
      expect(await fixture.manifest.readAsBytes(), profileOnly);
      final applied = await fixture.apply(planned, wire, 'format-apply');
      final published = await fixture.manifest.readAsBytes();

      expect(
        (await fixture.apply(planned, wire, 'format-apply'))['receipt'],
        applied['receipt'],
      );
      expect(await fixture.manifest.readAsBytes(), published);
      await fixture.refuses(
        () => fixture.apply(stale, wire, 'format-stale'),
        codes['stalePlan'] as String,
      );
      expect(await fixture.manifest.readAsBytes(), published);
      final queried = await fixture.trainer(wire);
      expect(queried['battleFormat'], 'doubles');
      expect(queried['team'], canonicalTeam);
      expect(queried['battleDifficulty'], doubles['battleDifficulty']);
      await fixture.refuses(
        () => fixture.planAction(
            'pokemon.ruleset.set', {'profile': shared['betaProfile']}, wire),
        codes['rulesetDowngrade'] as String,
      );
      expect(await fixture.manifest.readAsBytes(), published);

      final history = await fixture.call('history', {'limit': 1}, wire);
      final entry = (history['entries'] as List).single as Map;
      await fixture.call(
          'undo',
          {
            'entryId': entry['entryId'],
            'idempotencyKey': 'format-undo',
          },
          wire);
      expect(await fixture.manifest.readAsBytes(), profileOnly);
      expect((await fixture.trainer(wire))['battleFormat'], 'singles');
      await fixture.call(
          'undo',
          {
            'entryId': profileEntry['entryId'],
            'idempotencyKey': 'profile-undo',
          },
          wire);
      expect(await fixture.manifest.readAsBytes(), initial);
      await fixture.apply(
        await fixture.planAction('pokemon.ruleset.set',
            {'profile': shared['standardProfile']}, wire),
        wire,
        'profile-redo',
      );
      await fixture.apply(
          await fixture.plan(doubles, wire), wire, 'format-redo');

      await fixture.close();
      fixture = await _Fixture.open(root);
      expect((await fixture.trainer(wire))['battleFormat'], 'doubles');
      expect((await fixture.trainer(wire))['team'], canonicalTeam);
      expect(await fixture.map.readAsBytes(), protectedMap);
    });

    for (final invalid in shared['invalidFormats'] as List) {
      test(
          '$transport refuses explicit format ${jsonEncode(invalid)} atomically',
          () async {
        final fixture = await _Fixture.create(shared);
        addTearDown(() => fixture.dispose());
        await fixture.refusesUnchanged(
          {...doubles, 'battleFormat': invalid},
          wire,
          codes['invalidFormat'] as String,
        );
      });
    }

    for (final size in (shared['invalidDoubleTeamSizes'] as List).cast<int>()) {
      test('$transport refuses a double team of $size members atomically',
          () async {
        final fixture = await _Fixture.create(shared);
        addTearDown(() => fixture.dispose());
        final team = doubles['team'] as List;
        await fixture.refusesUnchanged(
          {
            ...doubles,
            'team': [
              for (var index = 0; index < size; index++) team[index % 2]
            ],
          },
          wire,
          codes['invalidDoubleTeamSize'] as String,
        );
      });
    }

    test('$transport refuses doubles for a static encounter profile atomically',
        () async {
      final fixture = await _Fixture.create(shared);
      addTearDown(() => fixture.dispose());
      await fixture.refusesUnchanged(
        Map<String, dynamic>.from(shared['staticTrainer'] as Map),
        wire,
        codes['staticDoublesUnsupported'] as String,
      );
    });

    final forgedProfiles = <Map<String, dynamic>>[
      {
        ...Map<String, dynamic>.from(shared['standardProfile'] as Map),
        'profileId': 'unknown-profile',
      },
      {
        ...Map<String, dynamic>.from(shared['betaProfile'] as Map),
        'disabledFeatures':
            (shared['standardProfile'] as Map)['disabledFeatures'],
      },
      {
        ...Map<String, dynamic>.from(shared['standardProfile'] as Map),
        'disabledFeatures': (shared['betaProfile'] as Map)['disabledFeatures'],
      },
    ];
    for (var index = 0; index < forgedProfiles.length; index++) {
      test('$transport refuses forged profile $index without any write',
          () async {
        final fixture = await _Fixture.create(shared);
        addTearDown(() => fixture.dispose());
        final before = await fixture.manifest.readAsBytes();
        final protectedMap = await fixture.map.readAsBytes();
        await fixture.refuses(
          () => fixture.planAction(
              'pokemon.ruleset.set', {'profile': forgedProfiles[index]}, wire),
          'pokemon.ruleset.profile_invalid',
        );
        expect(await fixture.manifest.readAsBytes(), before);
        expect(await fixture.map.readAsBytes(), protectedMap);
      });
    }
  }
}

final class _Fixture {
  _Fixture(this.root, this.api, this.mutations, this.snapshots, this.opened)
      : worker = JsonlWorker(api: api, mutations: mutations);

  final Directory root;
  final AuthoringReadApi api;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;
  final OpenedProject opened;
  final JsonlWorker worker;
  int sequence = 0;
  bool closed = false;

  File get manifest => File('${root.path}/project.json');
  File get map => File('${root.path}/maps/format.json');

  static Future<_Fixture> create(Map<String, dynamic> shared) async {
    final root =
        await Directory.systemTemp.createTemp('trainer-battle-format-');
    await File('${root.path}/project.json').writeAsString(jsonEncode(
      ProjectManifest.fromJson(
        Map<String, dynamic>.from(shared['project'] as Map),
      ).toJson(),
    ));
    final map = File('${root.path}/maps/format.json');
    await map.parent.create(recursive: true);
    await map.writeAsString(jsonEncode(MapData.fromJson(
      Map<String, dynamic>.from(shared['map'] as Map),
    ).toJson()));
    return open(root);
  }

  static Future<_Fixture> open(Directory root) async {
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final api = AuthoringReadApi(
      openService: ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ),
      snapshotLoader: snapshots,
    );
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
    );
    final opened = await api.openProject(root.path);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    return _Fixture(root, api, mutations, snapshots, opened);
  }

  Future<Map<String, Object?>> call(
    String command,
    Map<String, Object?> args,
    bool wire,
  ) async {
    if (wire) {
      final result = AuthoringResult.fromJson(jsonDecode(
        await worker.processLine(jsonEncode({
          'id': 'format-${sequence++}',
          'command': command,
          'args': {'projectHandle': opened.projectHandle.value, ...args},
        })),
      ) as Map<String, dynamic>);
      if (result.status != AuthoringResultStatus.success) throw result.error!;
      return result.data;
    }
    return switch (command) {
      'plan' => mutations.plan(
          opened.projectHandle,
          AuthoringRequest.fromJson(
              Map<String, dynamic>.from(args['request'] as Map))),
      'apply' => mutations.apply(opened.projectHandle,
          planId: args['planId'] as String,
          operationId: args['operationId'] as String),
      'history' =>
        mutations.history(opened.projectHandle, limit: args['limit'] as int),
      'undo' => mutations.undo(opened.projectHandle,
          entryId: args['entryId'] as String,
          idempotencyKey: args['idempotencyKey'] as String),
      'query' => api.query(
          opened.projectHandle,
          AuthoringQueryRequest.fromJson(
              Map<String, dynamic>.from(args['request'] as Map))),
      _ => throw StateError(command),
    };
  }

  Future<Map<String, Object?>> plan(Map<String, dynamic> value, bool wire) =>
      planAction('campaign.trainer.upsert', {'value': value}, wire);

  Future<Map<String, Object?>> planAction(
      String action, Map<String, Object?> parameters, bool wire) async {
    final id = 'format-plan-${sequence++}';
    final request = AuthoringRequest(
      requestId: id,
      actionId: action,
      actionVersion: 1,
      workspaceHandle: opened.workspaceHandle.value,
      expectedRevision: (await snapshots.load(opened.projectHandle)).revision,
      idempotencyKey: id,
      parameters: parameters,
    );
    return call('plan', {'request': request.toJson()}, wire);
  }

  Future<Map<String, Object?>> apply(
    Map<String, Object?> planned,
    bool wire,
    String operationId,
  ) =>
      call('apply', {'planId': planned['planId'], 'operationId': operationId},
          wire);

  Future<Map<String, Object?>> trainer(bool wire) async {
    final page = await call(
        'query',
        {
          'request': AuthoringQueryRequest(
            resourceKind: 'project',
            operation: AuthoringQueryOperation.get,
            ids: ['project'],
            view: AuthoringQueryView.detail,
            fieldMask: ['trainers'],
          ).toJson(),
        },
        wire);
    final project = (page['items'] as List).single as Map;
    return Map<String, Object?>.from(
        (project['trainers'] as List).single as Map);
  }

  Future<void> refuses(
      Future<Object?> Function() operation, String code) async {
    Object? failure;
    try {
      await operation();
    } on Object catch (error) {
      failure = error;
    }
    expect(failure, isNotNull, reason: code);
    if (failure case AuthoringError error) {
      expect(error.code, isNot(AuthoringErrorCode.internal));
      expect(error.details['domainCode'], code);
    } else {
      expect((failure as dynamic).code, code);
    }
  }

  Future<void> refusesUnchanged(
    Map<String, dynamic> value,
    bool wire,
    String code,
  ) async {
    final before = await manifest.readAsBytes();
    final protectedMap = await map.readAsBytes();
    final revision = (await snapshots.load(opened.projectHandle)).revision;
    await refuses(() => plan(value, wire), code);
    expect(await manifest.readAsBytes(), before);
    expect(await map.readAsBytes(), protectedMap);
    expect((await snapshots.load(opened.projectHandle)).revision, revision);
  }

  Future<void> close() async {
    if (closed) return;
    closed = true;
    await mutations.detachWorkspace(opened.workspaceHandle);
    await api.closeWorkspace(opened.workspaceHandle);
  }

  Future<void> dispose() async {
    await close();
    await root.delete(recursive: true);
  }
}
