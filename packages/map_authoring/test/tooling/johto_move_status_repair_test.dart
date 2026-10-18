import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_authoring/src/transactions/plan_store.dart'
    show AuthoringPlanException;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../tool/repair_johto_move_statuses.dart';

void main() {
  final fixture = jsonDecode(File(
    '../map_battle/test/fixtures/johto_moves_status_catalog.json',
  ).readAsStringSync()) as Map<String, dynamic>;
  final repairedEntries = fixture['entries'] as List;
  const originals = {
    'poison_powder': 'poisoned',
    'stun_spore': 'paralyzed',
    'sleep_powder': 'asleep',
    'bite': 'flinch',
    'confuse_ray': 'confused',
    'smog': 'poisoned',
    'sludge': 'poisoned',
    'hyper_fang': 'flinch',
  };

  Map<String, dynamic> brokenCatalog() {
    final entries = jsonDecode(jsonEncode(repairedEntries)) as List;
    for (final raw in entries) {
      final entry = raw as Map<String, dynamic>;
      final effect = (entry['effects'] as List).single as Map<String, dynamic>;
      effect
        ..remove('volatileStatusId')
        ..['kind'] = 'apply_status'
        ..['statusId'] = originals[entry['id']];
    }
    return {
      'schemaVersion': 1,
      'catalog': 'moves',
      'meta': {
        'retained': ['Johto', 4]
      },
      'entries': [
        ...entries,
        for (var index = 0; index < 358; index++)
          {
            'id': 'retained_$index',
            'vendor': {'value': index, 'nullable': null},
          },
      ],
    };
  }

  test('repairs exactly eight known effects and retains every other value', () {
    final before = brokenCatalog();
    final original = jsonDecode(jsonEncode(before));
    final repaired = correctJohtoMoveStatusCatalog(before);
    expect(repaired.changedMoveIds.toSet(), originals.keys.toSet());
    expect(before, original);
    expect(repaired.document['meta'], before['meta']);
    final entries = repaired.document['entries'] as List;
    expect(entries.take(8).toList(), repairedEntries);
    expect(
        entries.skip(8).toList(), (before['entries'] as List).skip(8).toList());
    expect(repaired.document.keys, before.keys);
  });

  test('already repaired data is a no-op and partial repair is safe', () {
    final before = brokenCatalog();
    (before['entries'] as List)[0] = repairedEntries[0];
    final once = correctJohtoMoveStatusCatalog(before);
    expect(once.changedMoveIds, hasLength(7));
    final twice = correctJohtoMoveStatusCatalog(once.document);
    expect(twice.changedMoveIds, isEmpty);
    expect(twice.document, once.document);
  });

  test('missing or duplicate ids reject the complete correction', () {
    for (final duplicate in [false, true]) {
      final before = brokenCatalog();
      final entries = before['entries'] as List;
      duplicate ? entries.add(entries.first) : entries.removeAt(0);
      final original = jsonEncode(before);
      expect(
          () => correctJohtoMoveStatusCatalog(before), throwsFormatException);
      expect(jsonEncode(before), original);
    }
  });

  test('unexpected effect, probability or target is never silently rewritten',
      () {
    for (final change in <Map<String, Object?>>[
      {'chance': 17},
      {'targetScope': 'user'},
      {'statusId': 'burn'},
      {'kind': 'heal'},
    ]) {
      final before = brokenCatalog();
      final entry = (before['entries'] as List).first as Map;
      ((entry['effects'] as List).single as Map).addAll(change);
      final original = jsonEncode(before);
      expect(
          () => correctJohtoMoveStatusCatalog(before), throwsFormatException);
      expect(jsonEncode(before), original);
    }
    final before = brokenCatalog();
    ((before['entries'] as List).first as Map)['effects'] = [];
    expect(() => correctJohtoMoveStatusCatalog(before), throwsFormatException);
  });

  test('rejects another catalog kind', () {
    final catalog = brokenCatalog()..['catalog'] = 'abilities';
    expect(() => correctJohtoMoveStatusCatalog(catalog), throwsFormatException);
  });

  test('canonical preview, apply and retry preserve all unrelated project data',
      () async {
    final root = await Directory.systemTemp.createTemp('johto-status-repair-');
    addTearDown(() => root.delete(recursive: true));
    final manifest = File('${root.path}/project.json');
    await manifest.writeAsString(jsonEncode(const ProjectManifest(
      name: 'Johto status correction fixture',
      maps: [],
      tilesets: [],
    ).toJson()));
    final manifestBefore = await manifest.readAsBytes();
    final file = File('${root.path}/data/pokemon/catalogs/moves.json');
    await file.parent.create(recursive: true);
    final catalog = PokemonCatalogFile.fromJson(brokenCatalog()).toJson();
    await file.writeAsString('${jsonEncode(catalog)}\n');
    final original = await file.readAsBytes();

    final preview = await repairJohtoMoveStatuses(root.path);
    expect(preview['status'], 'planned');
    expect(preview['changedMoveIds'], hasLength(8));
    expect(await file.readAsBytes(), original);

    final applied = await repairJohtoMoveStatuses(root.path, apply: true);
    expect(applied['status'], 'applied');
    expect(applied['changedMoveIds'], hasLength(8));
    expect(jsonDecode(await file.readAsString()),
        correctJohtoMoveStatusCatalog(catalog).document);
    expect(await manifest.readAsBytes(), manifestBefore);
    final history = File('${root.path}/.pokemap/authoring/history.jsonl');
    final historyBeforeRetry = await history.readAsBytes();
    final correctedBytes = await file.readAsBytes();

    final repeated = await repairJohtoMoveStatuses(root.path, apply: true);
    expect(repeated['status'], 'unchanged');
    expect(await file.readAsBytes(), correctedBytes);
    expect(await history.readAsBytes(), historyBeforeRetry);
  });

  test('canonical apply refuses a stale catalog and preserves concurrent bytes',
      () async {
    final root = await Directory.systemTemp.createTemp('johto-status-stale-');
    addTearDown(() => root.delete(recursive: true));
    final manifest = File('${root.path}/project.json');
    await manifest.writeAsString(jsonEncode(const ProjectManifest(
      name: 'Johto stale catalog fixture',
      maps: [],
      tilesets: [],
    ).toJson()));
    final manifestBefore = await manifest.readAsBytes();
    final file = File('${root.path}/data/pokemon/catalogs/moves.json');
    await file.parent.create(recursive: true);
    final catalog = PokemonCatalogFile.fromJson(brokenCatalog()).toJson();
    await file.writeAsString('${jsonEncode(catalog)}\n');
    final original = await file.readAsBytes();
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final readApi = AuthoringReadApi(
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
    final opened = await readApi.openProject(root.path);
    try {
      await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      final snapshot = await snapshots.load(opened.projectHandle);
      final planned = await mutations.planMutation(
        opened.projectHandle,
        AuthoringRequest(
          requestId: 'johto-stale-catalog',
          actionId: 'pokemon.catalog.write',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          expectedRevision: snapshot.revision,
          idempotencyKey: 'johto-stale-catalog',
          parameters: {
            'relativePath': 'data/pokemon/catalogs/moves.json',
            'beforeBytesBase64': base64Encode(original),
            'document': correctJohtoMoveStatusCatalog(catalog).document,
          },
        ),
      );
      expect(planned.plan.changeSet.changes, hasLength(1));
      expect(
          await planned.plan.changeSet.changes.single.beforePayload!
              .readBytes(),
          original);
      final confirmation = await mutations.confirmMutation(
        opened.projectHandle,
        planId: planned.planId,
      );
      final history = File('${root.path}/.pokemap/authoring/history.jsonl');
      final historyBefore =
          await history.exists() ? await history.readAsBytes() : null;
      final concurrent =
          jsonDecode(jsonEncode(catalog)) as Map<String, dynamic>;
      ((concurrent['entries'] as List).first as Map)['name'] =
          'Concurrent author name';
      final concurrentBytes = utf8.encode('${jsonEncode(concurrent)}\n\n');
      await file.writeAsBytes(concurrentBytes);

      await expectLater(
        mutations.applyMutation(
          opened.projectHandle,
          planId: planned.planId,
          operationId: 'johto-stale-catalog',
          confirmationToken: confirmation.confirmationToken,
        ),
        throwsA(isA<AuthoringPlanException>()
            .having((error) => error.code, 'code', 'plan.stale')),
      );
      expect(await file.readAsBytes(), concurrentBytes);
      expect(await manifest.readAsBytes(), manifestBefore);
      expect(await history.exists() ? await history.readAsBytes() : null,
          historyBefore);
    } finally {
      await mutations.detachWorkspace(opened.workspaceHandle);
      await readApi.closeWorkspace(opened.workspaceHandle);
    }
  });
}
