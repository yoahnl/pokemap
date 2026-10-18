import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final jsonl in [false, true]) {
    test(
        '${jsonl ? 'JSONL' : 'API'} protects an authored Ball from deletion and capability removal',
        () async {
      final fixture = await _Fixture.create(duplicate: false);
      addTearDown(fixture.dispose);
      await fixture.upsert(_trainer(['lunar_orb']), jsonl);
      final catalog =
          File('${fixture.root.path}/data/pokemon/catalogs/items.json');
      final before = await catalog.readAsBytes();
      await expectLater(
          fixture.mutate('item.delete_apply', {'itemId': 'lunar_orb'}, jsonl),
          throwsA(anything));
      expect(await catalog.readAsBytes(), before);
      await expectLater(
          fixture.mutate(
              'item.update',
              {
                'itemId': 'lunar_orb',
                'definition': {
                  'id': 'lunar_orb',
                  'displayName': 'No longer a Ball',
                  'pocketId': 'medicine',
                }
              },
              jsonl),
          throwsA(anything));
      expect(await catalog.readAsBytes(), before);
    });
    test(
        '${jsonl ? 'JSONL' : 'API'} authors distinct trainer Balls and clears them explicitly',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      await fixture.upsert(_trainer(['lunar_orb', 'solar_orb']), jsonl);
      final queried = await fixture.query(jsonl);
      expect(_balls(queried), ['lunar_orb', 'solar_orb']);
      await fixture.upsert(_trainer([null, 'solar_orb']), jsonl);
      expect(_balls(await fixture.query(jsonl)), [null, 'solar_orb']);
      final stored = ProjectManifest.fromJson(
          jsonDecode(await fixture.file.readAsString())
              as Map<String, dynamic>);
      expect(
          stored.trainers.single.team.first.toJson().containsKey('ballItemId'),
          isFalse);
      expect(
          stored.trainers.single.team.last.toJson()['ballItemId'], 'solar_orb');
    });

    final rejectedBalls = <Object, String>{
      'missing': 'trainer.ball_item_unknown',
      'potion': 'trainer.ball_item_not_capture',
      '': 'trainer.ball_item_id_invalid',
      ' ': 'trainer.ball_item_id_invalid',
      ' lunar_orb ': 'trainer.ball_item_id_invalid',
      42: 'trainer.ball_item_id_invalid',
      'ambiguous_orb': 'trainer.ball_item_ambiguous',
    };
    for (final rejected in rejectedBalls.entries) {
      test(
          '${jsonl ? 'JSONL' : 'API'} rejects trainer Ball ${jsonEncode(rejected.key)} with ${rejected.value} atomically',
          () async {
        final fixture = await _Fixture.create();
        addTearDown(fixture.dispose);
        final before = await fixture.file.readAsBytes();
        final catalogue =
            File('${fixture.root.path}/data/pokemon/catalogs/items.json');
        final beforeCatalogue = await catalogue.readAsBytes();
        final revision =
            (await fixture.snapshots.load(fixture.opened.projectHandle))
                .revision;
        final Matcher rejection = jsonl
            ? isA<AuthoringError>()
                .having((error) => error.code, 'code',
                    isNot(AuthoringErrorCode.internal))
                .having((error) => error.code, 'code',
                    AuthoringErrorCode.validationFailed)
                .having((error) => error.details['domainCode'], 'domainCode',
                    isNot('worker.internal'))
                .having((error) => error.details['domainCode'], 'domainCode',
                    rejected.value)
            : isA<ValidationException>()
                .having((error) => error.code, 'code', rejected.value);
        await expectLater(fixture.upsert(_trainer([rejected.key]), jsonl),
            throwsA(rejection));
        expect(await fixture.file.readAsBytes(), before);
        expect(await catalogue.readAsBytes(), beforeCatalogue);
        expect(
            (await fixture.snapshots.load(fixture.opened.projectHandle))
                .revision,
            revision);
      });
    }
  }

  test(
      'trainer Ball validation requires catalogue context in the direct semantic API',
      () {
    final trainer = ProjectTrainerEntry.fromJson(_trainer(['lunar_orb']));
    expect(
      () => const CampaignContentActions().upsert(
        ProjectManifest(name: 'No catalogue', maps: [], tilesets: []),
        CampaignContentKind.trainer,
        trainer,
      ),
      throwsA(isA<ValidationException>()),
    );
  });
}

Map<String, dynamic> _trainer(List<Object?> balls) => {
      'id': 'lysa',
      'name': 'Lysa',
      'trainerClass': 'Trainer',
      'team': [
        for (final id in balls)
          {'speciesId': 'sproutle', 'level': 10, 'ballItemId': id},
      ],
    };

List<Object?> _balls(Map<String, Object?> project) => [
      for (final member
          in ((project['trainers']! as List).single as Map)['team'] as List)
        (member as Map)['ballItemId'],
    ];

class _Fixture {
  _Fixture(this.root, this.file, this.api, this.mutations, this.snapshots,
      this.opened, this.worker);
  final Directory root;
  final File file;
  final AuthoringReadApi api;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;
  final OpenedProject opened;
  final JsonlWorker worker;
  int sequence = 0;

  static Future<_Fixture> create({bool duplicate = true}) async {
    final root =
        await Directory.systemTemp.createTemp('trainer-ball-authoring-');
    final file = File('${root.path}/project.json');
    await file.writeAsString(jsonEncode(ProjectManifest(
      name: 'Trainer Balls',
      maps: [],
      tilesets: [],
      pokemon: const ProjectPokemonConfig(
        enabled: true,
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        catalogFiles: {'items': 'data/pokemon/catalogs/items.json'},
      ),
    ).toJson()));
    final catalog = File('${root.path}/data/pokemon/catalogs/items.json');
    await catalog.parent.create(recursive: true);
    Map<String, Object?> ball(String id) => {
          'id': id,
          'displayName': id,
          'pocketId': 'balls',
          'capture': {
            'rateNumerator': 1,
            'rateDenominator': 1,
            'allowedEncounterKinds': ['walk']
          },
        };
    await catalog.writeAsString(jsonEncode({
      'schemaVersion': 1,
      'entries': [
        ball('lunar_orb'),
        ball('solar_orb'),
        ball('ambiguous_orb'),
        if (duplicate) ball('ambiguous_orb'),
        {'id': 'potion', 'displayName': 'Potion', 'pocketId': 'medicine'},
      ]
    }));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final api = AuthoringReadApi(
      openService: ProjectOpenService(
          policy: policy, fileReader: reader, handles: handles),
      snapshotLoader: snapshots,
    );
    final mutations =
        LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: snapshots);
    final opened = await api.openProject(root.path);
    await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    return _Fixture(root, file, api, mutations, snapshots, opened,
        JsonlWorker(api: api, mutations: mutations));
  }

  Future<Map<String, Object?>> wire(
      String command, Map<String, Object?> args) async {
    final result = AuthoringResult.fromJson(jsonDecode(await worker.processLine(
      jsonEncode(
          {'id': '$command-${sequence++}', 'command': command, 'args': args}),
    )) as Map<String, dynamic>);
    if (result.status != AuthoringResultStatus.success) {
      throw result.error!;
    }
    return result.data;
  }

  Future<Map<String, Object?>> query(bool jsonl) async {
    final request = AuthoringQueryRequest(
        resourceKind: 'project',
        operation: AuthoringQueryOperation.get,
        ids: ['project'],
        view: AuthoringQueryView.detail,
        fieldMask: ['trainers']);
    final page = jsonl
        ? AuthoringQueryPage.fromJson(
            Map<String, dynamic>.from(await wire('query', {
            'projectHandle': opened.projectHandle.value,
            'request': request.toJson(),
          })))
        : await api.queryProject(opened.projectHandle, request);
    return page.items.single;
  }

  Future<void> upsert(Map<String, dynamic> trainer, bool jsonl) async {
    await mutate('campaign.trainer.upsert', {'value': trainer}, jsonl);
  }

  Future<void> mutate(
      String actionId, Map<String, Object?> parameters, bool jsonl) async {
    final id = 'ball-${sequence++}';
    final request = AuthoringRequest(
        requestId: id,
        actionId: actionId,
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle.value,
        expectedRevision: (await snapshots.load(opened.projectHandle)).revision,
        idempotencyKey: id,
        parameters: parameters);
    final before = await file.readAsBytes();
    final plan = jsonl
        ? await wire('plan', {
            'projectHandle': opened.projectHandle.value,
            'request': request.toJson()
          })
        : await mutations.plan(opened.projectHandle, request);
    expect(await file.readAsBytes(), before);
    if (jsonl) {
      await wire('apply', {
        'projectHandle': opened.projectHandle.value,
        'planId': plan['planId'],
        'operationId': id
      });
    } else {
      await mutations.apply(opened.projectHandle,
          planId: plan['planId']! as String, operationId: id);
    }
  }

  Future<void> dispose() async {
    await mutations.detachWorkspace(opened.workspaceHandle);
    await api.closeWorkspace(opened.workspaceHandle);
    await root.delete(recursive: true);
  }
}
