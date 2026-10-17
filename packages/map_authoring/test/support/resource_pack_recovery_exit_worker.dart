import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../domains/assets/resource_pack_export_test.dart' as source;
import '../domains/assets/resource_pack_import_fixture.dart';
import 'transaction_test_fixture.dart';

const recoveryDCheckpoints = [
  'afterJournalPreparing',
  'afterPayloadsStaged',
  'afterJournalStaged',
  'afterReservation',
  'afterJournalPrepared',
  'beforeResourcePromotion',
  'afterResourcePromoted',
  'afterResourceJournaled',
  'afterJournalCommitted',
];

Future<NativeResourcePackImportFixture> _fixture({
  AuthoringTransactionFaultInjector? faultInjector,
}) {
  final base = source.originalManifest();
  return NativeResourcePackImportFixture.create(
    sourceManifest: base.copyWith(
      smartTileCatalog: const ProjectSmartTileCatalog.empty(),
      tilesets: [
        for (var i = 0; i < 2; i++)
          base.tilesets.single.copyWith(
            id: 'recovery-$i',
            relativePath: 'assets/recovery-$i.png',
            source: ProjectTilesetSource.regularAtlas(
              assetId: 'image-$i',
              pixelWidth: 2,
              pixelHeight: 2,
              tileWidth: 2,
              tileHeight: 2,
            ),
          ),
      ],
    ),
    sourceFiles: [
      for (var i = 0; i < 2; i++)
        source.nativeImage(id: 'image-$i', path: 'assets/recovery-$i.png'),
    ],
    roots: [
      for (var i = 0; i < 2; i++)
        NativeResourcePackRef(
          kind: ResourcePackKind.tileset,
          id: 'recovery-$i',
        ),
    ],
    faultInjector: faultInjector,
  );
}

Future<AuthoringMutationPlanResult> _plan(
  NativeResourcePackImportFixture fixture,
) async {
  final selected = await fixture.select(
    roots: [
      for (final tileset in fixture.source.archive.inspection.catalog.tilesets)
        ResourcePackRef(kind: ResourcePackKind.tileset, id: tileset.id),
    ],
  );
  return fixture.plan(await fixture.prepare(selection: selected));
}

List<Map<String, Object?>> _frozen(AuthoringMutationPlanResult plan) => [
      for (final change in plan.plan.changeSet.changes)
        {
          'storageKey': change.storageKey,
          'beforeRevision': change.beforeRevision,
          'afterRevision': change.afterRevision,
        },
    ]..sort(
        (a, b) =>
            (a['storageKey'] as String).compareTo(b['storageKey'] as String),
      );

Future<Map<String, String>> _businessFiles(String root) async {
  final hashes = <String, String>{};
  await for (final file in Directory(
    root,
  ).list(recursive: true, followLinks: false)) {
    final relative = file.path.substring(root.length + 1);
    if (relative == '.pokemap' || relative.startsWith('.pokemap/')) continue;
    _require(file is! Link, 'Unexpected fixture symlink: $relative');
    if (file is File) {
      hashes[relative] = sha256.convert(await file.readAsBytes()).toString();
    }
  }
  return Map.fromEntries(
    hashes.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
}

Future<void> _verifyPrefix(
  String root,
  List<Map<String, Object?>> frozen,
  int count,
) async {
  for (var i = 0; i < frozen.length; i++) {
    final entry = frozen[i];
    final key = entry['storageKey'] as String;
    final file = File('$root/$key');
    final actual = await file.exists()
        ? computeAuthoringBytesFingerprint(
            await file.readAsBytes(),
            logicalName: key,
          )
        : null;
    _equal(
      actual,
      entry[i < count ? 'afterRevision' : 'beforeRevision'],
      'disk prefix $i $key',
    );
  }
}

final class _Session {
  _Session(this.handles, this.loader, this.opened, this.mutations, this.api);
  final WorkspaceHandleStore handles;
  final ProjectSnapshotLoader loader;
  final OpenedProject opened;
  final LocalMapAuthoringMutationApi mutations;
  final LocalResourcePackTransferApi api;

  static Future<_Session> open(
    String root, {
    bool readonly = false,
    AuthoringTransactionFaultInjector? faultInjector,
  }) async {
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final loader = ProjectSnapshotLoader(handles: handles);
    final service = ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
    );
    final opened = await service.openProject(root);
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: loader,
      actor: readonly ? AuthoringActor(actorId: 'local_cli') : null,
      faultInjector: faultInjector,
    );
    await mutations.attachProject(
      projectRootPath: root,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    return _Session(
      handles,
      loader,
      opened,
      mutations,
      LocalResourcePackTransferApi(
        mutations: mutations,
        snapshotLoader: loader,
      ),
    );
  }

  Future<Map<String, Object?>> transfer(
    String verb, [
    Map<String, Object?> input = const {},
  ]) =>
      api.transfer(opened.projectHandle, verb: verb, input: input);

  Future<Map<String, Object?>> job(
    String verb,
    Map<String, Object?> input, {
    String expected = 'succeeded',
  }) async {
    final start = await transfer(verb, input);
    final deadline = DateTime.now().add(const Duration(seconds: 20));
    while (DateTime.now().isBefore(deadline)) {
      final state = await transfer('get', {'jobId': start['jobId']});
      final snapshot = state['snapshot'] as Map;
      if (const [
        'succeeded',
        'failed',
        'cancelled',
      ].contains(snapshot['state'])) {
        _equal(snapshot['state'], expected, 'job $verb ${jsonEncode(state)}');
        return state;
      }
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    throw StateError('Job $verb did not finish within 20 seconds.');
  }

  Future<void> close() async {
    await api.closeTransferWorkspace(opened.workspaceHandle);
    await mutations.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
  }
}

Future<void> _denyReadonly(String root, String operation) async {
  final session = await _Session.open(root, readonly: true);
  try {
    _equal(
      (await session.transfer('recovery_status'))['recoveryRequired'],
      true,
      'readonly pending',
    );
    final before = await _businessFiles(root);
    final result = await session.job(
        'start_recovery',
        {
          'operationId': operation,
        },
        expected: 'failed');
    _equal(
      (result['snapshot'] as Map)['errorCode'],
      'authorization.permission_denied',
      'readonly recovery',
    );
    _equal(
      (await session.transfer('recovery_status'))['recoveryRequired'],
      true,
      'readonly pending retained',
    );
    _equal(await _businessFiles(root), before, 'readonly files retained');
  } finally {
    await session.close();
  }
}

Future<void> _verifyBlobs(_Session session, String root) async {
  final history = await session.mutations.listMutationHistory(
    session.opened.projectHandle,
    limit: 100,
  );
  _equal(history.nextCursor, null, 'bounded history page');
  final retained = <String>{
    for (final entry in history.entries)
      for (final change in entry.changes) ...change.retainedBlobIds,
  };
  final blobs = await FileAuthoringContentBlobStore.open(projectRoot: root);
  _equal((await blobs.listIds()).toSet(), retained, 'retained blob closure');
}

Future<Map<String, Object?>> _recoverAndUndo(
  Map<String, dynamic> record,
) async {
  final root = record['root'] as String;
  final operation = record['operationId'] as String;
  final frozen = (record['frozen'] as List)
      .map((v) => Map<String, Object?>.from(v as Map))
      .toList();
  await _denyReadonly(root, operation);
  var session = await _Session.open(root);
  try {
    final pending = await session.transfer('recovery_status');
    _equal(pending['recoveryRequired'], true, 'fresh pending before snapshot');
    final beforeBlocked = await _businessFiles(root);
    Object? blocked;
    try {
      await session.mutations.planMutation(
        session.opened.projectHandle,
        AuthoringRequest(
          requestId: 'blocked',
          actionId: 'resource.family.create',
          actionVersion: 1,
          workspaceHandle: session.opened.workspaceHandle.value,
          expectedRevision: record['initialRevision'] as String,
          idempotencyKey: 'blocked',
          parameters: {'familyId': 'blocked', 'name': 'Blocked'},
        ),
      );
    } catch (error) {
      blocked = error;
    }
    _require(
      blocked is AuthoringRecoveryException &&
          blocked.code == 'resource_pack.recovery_required',
      'ordinary mutation must be recovery-blocked: $blocked',
    );
    _equal(await _businessFiles(root), beforeBlocked, 'blocked mutation files');
    final recovered = await session.job('start_recovery', {
      'operationId': operation,
    });
    _equal(
      (await session.transfer('recovery_status'))['recoveryRequired'],
      false,
      'recovery cleared',
    );
    await _verifyPrefix(root, frozen, frozen.length);
    final snapshot = await session.loader.load(session.opened.projectHandle);
    _equal(snapshot.manifest.tilesets.length, 2, 'recovered tilesets');
    final expectedKeys = <String>{
      ...(record['initialFiles'] as Map).keys.cast<String>(),
      for (final entry in frozen)
        if (entry['afterRevision'] != null) entry['storageKey'] as String,
    };
    _equal(
      (await _businessFiles(root)).keys.toSet(),
      expectedKeys,
      'installed file closure',
    );
    final history = await session.mutations.listMutationHistory(
      session.opened.projectHandle,
      limit: 100,
    );
    _equal(history.entries.length, 1, 'single recovered import history');
    final receipt = Map<String, Object?>.from(
      (recovered['result'] as Map)['receipt'] as Map,
    );
    final historyBytes =
        await File('$root/.pokemap/authoring/history.jsonl').readAsString();
    final appliedFiles = await _businessFiles(root);
    final gateway = await LocalTransactionFileGateway.open(projectRoot: root);
    final journalBeforeReplay = await gateway.readJournal(operation);
    _require(
      journalBeforeReplay != null,
      'recovery journal should remain for natural replay cleanup',
    );
    final deniedReplay = await _Session.open(root, readonly: true);
    try {
      final denied = await deniedReplay.job(
          'start_apply',
          {
            'planId': record['planId'],
            'operationId': operation,
          },
          expected: 'failed');
      _equal(
        (denied['snapshot'] as Map)['errorCode'],
        'authorization.permission_denied',
        'readonly replay',
      );
      _equal(
        (await gateway.readJournal(operation))?.toJson(),
        journalBeforeReplay!.toJson(),
        'readonly replay retained journal',
      );
    } finally {
      await deniedReplay.close();
    }
    final mismatched = await session.job(
        'start_apply',
        {
          'planId': 'foreign-plan',
          'operationId': operation,
        },
        expected: 'failed');
    _equal(
      (mismatched['snapshot'] as Map)['errorCode'],
      'authorization.replay_context_mismatch',
      'mismatched replay',
    );
    _equal(
      (await gateway.readJournal(operation))?.toJson(),
      journalBeforeReplay.toJson(),
      'mismatched replay retained journal',
    );
    final replay = await session.job('start_apply', {
      'operationId': operation,
      'planId': record['planId'],
    });
    _equal(
      (replay['result'] as Map)['receipt'],
      receipt,
      'same durable replay receipt',
    );
    _equal(
      await File('$root/.pokemap/authoring/history.jsonl').readAsString(),
      historyBytes,
      'no second history entry',
    );
    _equal(
      await _businessFiles(root),
      appliedFiles,
      'no second promotion files',
    );
    _equal(
      await gateway.readJournal(operation),
      null,
      'natural replay journal cleanup',
    );
    _equal(
      await Directory('$root/.pokemap/authoring/transactions/$operation')
          .exists(),
      false,
      'transaction stage removed',
    );
    await _verifyBlobs(session, root);
    final undo = await session.job('start_history', {
      'operation': 'undo',
      'entryId': receipt['receiptId'],
      'expectedRevision': snapshot.revision,
      'expectedHeadEntryId': receipt['receiptId'],
      'operationId': 'undo-$operation',
    });
    _equal(
      await _businessFiles(root),
      record['initialFiles'],
      'undo initial business bytes',
    );
    await _verifyBlobs(session, root);
    _equal(
      await gateway.listJournals(),
      <Object>[],
      'no transaction journals after undo',
    );
    await session.close();
    session = await _Session.open(root);
    _equal(
      (await session.transfer('recovery_status'))['recoveryRequired'],
      false,
      'reopened no pending',
    );
    final reopened = await session.loader.load(session.opened.projectHandle);
    _equal(reopened.manifest.tilesets.length, 0, 'reopened undo inventory');
    _equal(
      await _businessFiles(root),
      record['initialFiles'],
      'fresh reopen initial business',
    );
    final finalHistory = await session.mutations.listMutationHistory(
      session.opened.projectHandle,
      limit: 100,
    );
    _equal(finalHistory.entries.length, 2, 'import plus undo history');
    _equal(
      finalHistory.entries.first.kind,
      AuthoringHistoryKind.undo,
      'undo history head',
    );
    _equal(
      finalHistory.entries.first.targetEntryId,
      receipt['receiptId'],
      'undo target',
    );
    return {
      'pending': pending,
      'blockedCode': (blocked as AuthoringRecoveryException).code,
      'readonlyDenied': true,
      'recoveredReceipt': receipt,
      'replayReceipt': (replay['result'] as Map)['receipt'],
      'journalBeforeReplay': journalBeforeReplay.status.name,
      'journalAfterReplay': null,
      'afterRevision': snapshot.revision,
      'undoReceipt': (undo['result'] as Map)['receipt'],
      'reopenedRevision': reopened.revision,
      'reopenedTilesets': 0,
      'initialFiles': record['initialFiles'],
      'appliedFiles': appliedFiles,
      'finalFiles': await _businessFiles(root),
      'historyEntries': 2,
      'blobClosureVerified': true,
    };
  } finally {
    await session.close();
  }
}

Future<Map<String, Object?>> recoveryDCooperative(
  String checkpoint, {
  bool middle = false,
}) async {
  final operation = 'recovery-d-$checkpoint${middle ? '-middle' : ''}';
  var armed = true;
  var index = 0;
  final hits = <Map<String, Object?>>[];
  final fixture = await _fixture(
    faultInjector: (context) {
      if (armed &&
          context.operationId == operation &&
          context.checkpoint.name == checkpoint &&
          (context.promotionIndex == null || context.promotionIndex == index)) {
        armed = false;
        hits.add({
          'checkpoint': context.checkpoint.name,
          'operationId': context.operationId,
          'storageKey': context.storageKey,
          'promotionIndex': context.promotionIndex,
        });
        throw const AuthoringTransactionSimulatedCrash();
      }
    },
  );
  try {
    await File('${fixture.root.path}/unrelated-sentinel.txt')
        .writeAsString('keep recovery fixture');
    final initialFiles = await _businessFiles(fixture.root.path);
    final initialRevision = (await fixture.loader.load(
      fixture.opened.projectHandle,
    ))
        .revision;
    final plan = await _plan(fixture);
    final frozen = _frozen(plan);
    _require(frozen.length >= 3, 'At least three actual promotions required.');
    if (middle) {
      index = frozen.length ~/ 2;
      _require(
        index > 0 && index < frozen.length - 1,
        'Not an interior promotion.',
      );
    }
    Object? observed;
    try {
      await fixture.apply(plan, operationId: operation);
    } catch (error) {
      observed = error;
    }
    _require(
      observed is AuthoringTransactionSimulatedCrash,
      'Expected simulated checkpoint crash, got $observed',
    );
    _equal(hits.length, 1, 'exact checkpoint hit');
    if (hits.single['promotionIndex'] != null) {
      _equal(
        hits.single['storageKey'],
        frozen[index]['storageKey'],
        'checkpoint storage key',
      );
    }
    final early = recoveryDCheckpoints.indexOf(checkpoint) < 3;
    final promoted = checkpoint == 'afterJournalCommitted'
        ? frozen.length
        : const [
            'afterResourcePromoted',
            'afterResourceJournaled',
          ].contains(checkpoint)
            ? index + 1
            : checkpoint == 'beforeResourcePromotion'
                ? index
                : 0;
    await _verifyPrefix(fixture.root.path, frozen, promoted);
    final gateway = await LocalTransactionFileGateway.open(
      projectRoot: fixture.root.path,
    );
    final journal = (await gateway.readJournal(operation))!;
    final ledger = AuthoringIdempotencyLedger(
      store: FileIdempotencyStore(
        filePath: '${fixture.root.path}/.pokemap/authoring/idempotency.jsonl',
      ),
    );
    final reservation = await ledger.recordForRecovery(journal.scope);
    _equal(
      reservation?.status,
      early ? null : AuthoringIdempotencyStatus.pending,
      'reservation boundary',
    );
    await fixture.close();
    Map<String, Object?> result;
    if (early) {
      final session = await _Session.open(fixture.root.path);
      try {
        final status = await session.transfer('recovery_status');
        _equal(status['recoveryRequired'], false, 'unreserved is not blocking');
        final inspected = await session.mutations.resourcePackPending(
          session.opened.projectHandle,
        );
        _equal(
          inspected.single.disposition,
          AuthoringRecoveryDisposition.unreservedIntent,
          'early intent',
        );
        _equal(
          await _businessFiles(fixture.root.path),
          initialFiles,
          'unreserved business unchanged',
        );
        final recovery = AuthoringRecoveryService(
          gateway: gateway,
          idempotency: ledger,
          clock: DateTime.now,
        );
        _equal(
          await recovery.discardUnreserved(operation),
          true,
          'validated unreserved discard',
        );
        _equal(
          await gateway.readJournal(operation),
          null,
          'unreserved stage cleanup',
        );
      } finally {
        await session.close();
      }
      await fixture.open();
      await fixture.stage();
      final fresh = await _plan(fixture);
      final imported = await fixture.apply(
        fresh,
        operationId: 'fresh-$operation',
      );
      final after = await fixture.loader.load(fixture.opened.projectHandle);
      _equal(after.manifest.tilesets.length, 2, 'fresh import after discard');
      await fixture.close();
      final sessionAfter = await _Session.open(fixture.root.path);
      try {
        final history = await sessionAfter.mutations.listMutationHistory(
          sessionAfter.opened.projectHandle,
          limit: 10,
        );
        _equal(history.entries.length, 1, 'fresh import history');
        await sessionAfter.job('start_history', {
          'operation': 'undo',
          'entryId': imported.receipt.receiptId,
          'expectedRevision': after.revision,
          'expectedHeadEntryId': imported.receipt.receiptId,
          'operationId': 'undo-fresh-$operation',
        });
        _equal(
          await _businessFiles(fixture.root.path),
          initialFiles,
          'unreserved fresh import undo',
        );
        await _verifyBlobs(sessionAfter, fixture.root.path);
        _equal(
          await gateway.listJournals(),
          <Object>[],
          'unreserved final journal closure',
        );
      } finally {
        await sessionAfter.close();
      }
      result = {
        'unreservedIntent': true,
        'discarded': true,
        'freshImportReceipt': imported.receipt.toJson(),
        'finalFiles': await _businessFiles(fixture.root.path),
      };
    } else {
      result = await _recoverAndUndo({
        'root': fixture.root.path,
        'operationId': operation,
        'planId': plan.planId,
        'frozen': frozen,
        'initialFiles': initialFiles,
        'initialRevision': initialRevision,
      });
    }
    final evidence = {
      'case': checkpoint,
      'middle': middle,
      'operationId': operation,
      'frozen': frozen,
      'promotionIndex': index,
      'promotedAtStop': promoted,
      'journalStatusAtStop': journal.status.name,
      'reservationAtStop': reservation?.status.name,
      'hit': hits.single,
      'result': result,
    };
    await recoveryDEvidence(
      'cooperative-$checkpoint${middle ? '-middle' : ''}',
      evidence,
    );
    return evidence;
  } finally {
    await fixture.dispose();
  }
}

Future<void> recoveryDEvidence(String name, Map<String, Object?> data) async {
  final path = Platform.environment['POKEMAP_RESOURCE_PACK_RECOVERY_EVIDENCE'];
  if (path != null) {
    final directory = await Directory(path).create(recursive: true);
    await File('${directory.path}/$name.json')
        .writeAsString('${jsonEncode(data)}\n', flush: true);
  }
  stdout.writeln(jsonEncode({'recoveryD': name, 'status': 'verified'}));
}

void _require(bool condition, String message) {
  if (!condition) throw StateError(message);
}

Object? _canonical(Object? value) {
  if (value is Set) {
    return value.map((v) => jsonEncode(_canonical(v))).toList()..sort();
  }
  if (value is Map) {
    return {
      for (final key in value.keys.map((v) => v.toString()).toList()..sort())
        key: _canonical(value[key]),
    };
  }
  if (value is List) return value.map(_canonical).toList();
  if (value is Enum) return value.name;
  return value;
}

void _equal(Object? actual, Object? expected, String context) {
  if (jsonEncode(_canonical(actual)) != jsonEncode(_canonical(expected))) {
    throw StateError(
      '$context: expected ${jsonEncode(_canonical(expected))}, actual ${jsonEncode(_canonical(actual))}',
    );
  }
}

Future<void> main(List<String> arguments) async {
  _require(
    arguments.length == 2,
    'Expected fixed worker mode and request path.',
  );
  final record = Map<String, dynamic>.from(
    jsonDecode(await File(arguments[1]).readAsString()) as Map,
  );
  final runtime = await _runtimeIdentity();
  if (arguments.first == 'apply-exit') {
    record['workerRuntime'] = runtime;
    await _applyExit(record);
    throw StateError('Requested checkpoint did not terminate the process.');
  }
  _equal(arguments.first, 'recover', 'worker mode');
  final result = await _recoverAndUndo(record);
  await File(record['resultPath'] as String).writeAsString(
    jsonEncode({...result, 'recoveryPid': pid, 'workerRuntime': runtime}),
    flush: true,
  );
}

Future<void> _applyExit(Map<String, dynamic> request) async {
  final root = request['root'] as String;
  final checkpoint = request['checkpoint'] as String;
  final operation = request['operationId'] as String;
  var targetIndex = 0;
  late Map<String, Object?> plannedRecord;
  final session = await _Session.open(
    root,
    faultInjector: (context) async {
      if (context.operationId == operation &&
          context.checkpoint.name == checkpoint &&
          (context.promotionIndex == null ||
              context.promotionIndex == targetIndex)) {
        final marker = {
          'checkpoint': context.checkpoint.name,
          'operationId': context.operationId,
          'storageKey': context.storageKey,
          'promotionIndex': context.promotionIndex,
          'pid': pid,
          'planId': plannedRecord['planId'],
        };
        await File(request['markerPath'] as String)
            .writeAsString(jsonEncode(marker), flush: true);
        stdout.writeln(jsonEncode({'exit77Marker': marker}));
        await stdout.flush();
        exit(77);
      }
    },
  );
  try {
    final preparer = session.mutations.resourcePackImports(
      session.opened.projectHandle,
    );
    final archive = File(request['archivePath'] as String);
    final staged = await session.mutations
        .resourcePackPayloadStore(session.opened.projectHandle)
        .stage(
          scope: preparer.scope,
          byteLength: await archive.length(),
          chunks: archive.openRead(),
        );
    final selected = await preparer.select(
      archiveHandle: staged.payload.handle,
      roots: [
        for (final id in request['tilesetIds'] as List)
          ResourcePackRef(kind: ResourcePackKind.tileset, id: id as String),
      ],
    );
    final revision =
        (await session.loader.load(session.opened.projectHandle)).revision;
    _equal(
      revision,
      request['initialRevision'],
      'child unchanged initial revision',
    );
    final prepared = await preparer.prepare(
      selectionHandle: selected.handle,
      selectionRevision: selected.revision,
      expectedRevision: revision,
      conflictPolicy: ResourcePackConflictPolicy.preserveProject,
    );
    final plan = await session.mutations.planMutation(
      session.opened.projectHandle,
      AuthoringRequest(
        requestId: 'exit-import',
        actionId: 'resource_pack.import',
        actionVersion: 1,
        workspaceHandle: session.opened.workspaceHandle.value,
        expectedRevision: revision,
        idempotencyKey: 'exit-import',
        parameters: {'preparedImportHandle': prepared.preparedImportHandle},
      ),
    );
    final frozen = _frozen(plan);
    _require(frozen.length >= 3, 'Need actual interior promotion.');
    targetIndex = frozen.length ~/ 2;
    _require(
      targetIndex > 0 && targetIndex < frozen.length - 1,
      'Need an interior promotion index.',
    );
    plannedRecord = {
      ...request,
      'planId': plan.planId,
      'frozen': frozen,
      'promotionIndex': targetIndex,
      'applyPid': pid,
    };
    await File(request['recordPath'] as String)
        .writeAsString(jsonEncode(plannedRecord), flush: true);
    final confirmation = await session.mutations.confirmMutation(
      session.opened.projectHandle,
      planId: plan.planId,
    );
    await session.job('start_apply', {
      'planId': plan.planId,
      'operationId': operation,
      'confirmationToken': confirmation.confirmationToken,
    });
  } finally {
    await session.close();
  }
}

Future<Map<String, Object?>> _child(
  String mode,
  String requestPath,
  String runtimeTmp,
) async {
  await _verifyKernel();
  final executable = Platform.environment['POKEMAP_TEST_DART'] ?? 'dart';
  final args = [
    '--packages=${Directory.current.path}/.dart_tool/package_config.json',
    _kernelFile!.path,
    mode,
    requestPath,
  ];
  final process = await Process.start(
    executable,
    args,
    environment: {'TMPDIR': '$runtimeTmp/'},
  );
  final watch = Stopwatch()..start();
  final output = process.stdout.transform(utf8.decoder).join();
  final errors = process.stderr.transform(utf8.decoder).join();
  stdout.writeln(
    jsonEncode({
      'recoveryDChildPid': process.pid,
      'executable': executable,
      'args': args,
      'mode': mode,
    }),
  );
  final code = await process.exitCode.timeout(const Duration(seconds: 20));
  watch.stop();
  await _verifyKernel();
  return {
    'pid': process.pid,
    'executable': executable,
    'args': args,
    'exitCode': code,
    'stdout': await output,
    'stderr': await errors,
    'kernelIdentity': _kernelIdentity,
    'processMilliseconds': watch.elapsedMilliseconds,
  };
}

Directory? _kernelDirectory;
File? _kernelFile;
Map<String, Object?>? _kernelIdentity;

Future<Map<String, Object?>> _runtimeIdentity() async {
  final sdk = File(
    await File(Platform.resolvedExecutable).resolveSymbolicLinks(),
  );
  _require(
    sdk.path.contains('dart') && !sdk.path.contains('flutter_tester'),
    'Recovery requires the real Dart interpreter.',
  );
  return {
    'sdkExecutable': sdk.path,
    'sdkSha256': sha256.convert(await sdk.readAsBytes()).toString(),
    'sdkVersion': Platform.version,
  };
}

Future<Map<String, Object?>> _workerInputs() async {
  final current = Directory.current.path;
  return {
    ...await _runtimeIdentity(),
    'files': {
      for (final path in [
        '.dart_tool/package_config.json',
        'test/support/resource_pack_recovery_exit_worker.dart',
        'test/domains/assets/resource_pack_transaction_test.dart',
        'lib/src/transactions/journaled_transaction.dart',
        'lib/src/security/secure_mutation_executor.dart',
      ])
        path: sha256
            .convert(await File('$current/$path').readAsBytes())
            .toString(),
    },
  };
}

Future<void> recoveryDCompileWorker() async {
  _require(_kernelDirectory == null, 'Worker already compiled.');
  final directory = await Directory.systemTemp.createTemp(
    'recovery-d-worker-kernel-',
  );
  _kernelDirectory = directory;
  _kernelFile = File('${directory.path}/recovery-worker.dill');
  final temporary = await Directory('${directory.path}/compiler-tmp').create();
  final before = await _workerInputs();
  final executable = Platform.environment['POKEMAP_TEST_DART'] ?? 'dart';
  final args = [
    'compile',
    'kernel',
    '--packages=${Directory.current.path}/.dart_tool/package_config.json',
    '${Directory.current.path}/test/support/resource_pack_recovery_exit_worker.dart',
    '-o',
    _kernelFile!.path,
  ];
  final watch = Stopwatch()..start();
  final process = await Process.start(
    executable,
    args,
    environment: {'TMPDIR': '${temporary.path}/'},
  );
  stdout.writeln(
    jsonEncode({
      'recoveryDKernelCompilerPid': process.pid,
      'executable': executable,
      'args': args,
    }),
  );
  final output = process.stdout.transform(utf8.decoder).join();
  final errors = process.stderr.transform(utf8.decoder).join();
  final code = await process.exitCode;
  watch.stop();
  final out = await output;
  final err = await errors;
  _equal(code, 0, 'kernel compilation $err $out');
  _equal(
    await _workerInputs(),
    before,
    'source/config/SDK stable during compile',
  );
  _kernelIdentity = {
    'inputs': before,
    'kernelPath': _kernelFile!.path,
    'kernelSha256': sha256.convert(await _kernelFile!.readAsBytes()).toString(),
    'kernelByteLength': await _kernelFile!.length(),
    'kind': 'Dart kernel, not AOT',
  };
  await recoveryDEvidence('kernel-compile', {
    'identity': _kernelIdentity,
    'compilerPid': process.pid,
    'argv': [executable, ...args],
    'exitCode': code,
    'compileMilliseconds': watch.elapsedMilliseconds,
    'stdout': out,
    'stderr': err,
    'measurement': 'Compilation separated from each process deadline20s',
  });
}

Future<void> _verifyKernel() async {
  _require(
    _kernelFile != null && _kernelIdentity != null,
    'No compiled test worker.',
  );
  _equal(
    await _workerInputs(),
    _kernelIdentity!['inputs'],
    'worker source/config/SDK pinned',
  );
  _equal(
    sha256.convert(await _kernelFile!.readAsBytes()).toString(),
    _kernelIdentity!['kernelSha256'],
    'kernel SHA pinned',
  );
}

Future<void> recoveryDDisposeWorker() async {
  try {
    if (_kernelIdentity != null) await _verifyKernel();
    if (_kernelDirectory != null && await _kernelDirectory!.exists()) {
      await _kernelDirectory!.delete(recursive: true);
    }
  } finally {
    _kernelFile = null;
    _kernelDirectory = null;
    _kernelIdentity = null;
  }
}

Future<Map<String, Object?>> recoveryDRealExit(String checkpoint) async {
  final fixture = await _fixture();
  final runtime = await Directory.systemTemp.createTemp(
    'recovery-d-child-runtime-',
  );
  try {
    final root = fixture.root.path;
    final base = fixture.source.directory.path;
    final archiveFile = File('$base/process-input.avelunepack');
    await fixture.source.archive.withSource((source) async {
      final out = await archiveFile.open(mode: FileMode.write);
      try {
        await for (final chunk in sourceChunks(source)) {
          await out.writeFrom(chunk);
        }
        await out.flush();
      } finally {
        await out.close();
      }
    });
    final archiveHash =
        sha256.convert(await archiveFile.readAsBytes()).toString();
    await File('$root/unrelated-sentinel.txt')
        .writeAsString('keep recovery fixture');
    final request = {
      'root': root,
      'operationId': 'recovery-d-exit-$checkpoint',
      'checkpoint': checkpoint,
      'archivePath': archiveFile.path,
      'tilesetIds': [
        for (final tileset
            in fixture.source.archive.inspection.catalog.tilesets)
          tileset.id,
      ],
      'initialFiles': await _businessFiles(root),
      'initialRevision': (await fixture.loader.load(
        fixture.opened.projectHandle,
      ))
          .revision,
      'markerPath': '$base/exit-marker.json',
      'recordPath': '$base/exit-record.json',
      'resultPath': '$base/recovery-result.json',
    };
    final requestFile = File('$base/exit-request.json');
    await requestFile.writeAsString(jsonEncode(request), flush: true);
    await fixture.close();
    final applyChild = await _child(
      'apply-exit',
      requestFile.path,
      runtime.path,
    );
    _equal(
      applyChild['exitCode'],
      77,
      'real apply exit: ${applyChild['stderr']}',
    );
    final marker = Map<String, dynamic>.from(
      jsonDecode(await File(request['markerPath'] as String).readAsString())
          as Map,
    );
    final record = Map<String, dynamic>.from(
      jsonDecode(await File(request['recordPath'] as String).readAsString())
          as Map,
    );
    _equal(
      record['workerRuntime'],
      await _runtimeIdentity(),
      'apply child actual SDK identity',
    );
    _equal(marker['pid'], applyChild['pid'], 'marker OS child identity');
    _equal(marker['operationId'], request['operationId'], 'marker operation');
    _equal(marker['planId'], record['planId'], 'marker plan');
    _equal(marker['checkpoint'], checkpoint, 'marker checkpoint');
    final frozen = (record['frozen'] as List)
        .map((v) => Map<String, Object?>.from(v as Map))
        .toList();
    final promoted = checkpoint == 'afterJournalPrepared'
        ? 0
        : (record['promotionIndex'] as int) + 1;
    _equal(
      marker['promotionIndex'],
      checkpoint == 'afterJournalPrepared' ? null : record['promotionIndex'],
      'marker exact index',
    );
    _equal(
      marker['storageKey'],
      checkpoint == 'afterJournalPrepared'
          ? null
          : frozen[promoted - 1]['storageKey'],
      'marker exact storage',
    );
    await _verifyPrefix(root, frozen, promoted);
    final gateway = await LocalTransactionFileGateway.open(projectRoot: root);
    final journal = (await gateway.readJournal(
      request['operationId'] as String,
    ))!;
    _equal(
      journal.status.name,
      checkpoint == 'afterJournalPrepared' ? 'prepared' : 'promoting',
      'actual stopped journal phase',
    );
    final ledger = AuthoringIdempotencyLedger(
      store: FileIdempotencyStore(
        filePath: '$root/.pokemap/authoring/idempotency.jsonl',
      ),
    );
    _equal(
      (await ledger.recordForRecovery(journal.scope))!.status,
      AuthoringIdempotencyStatus.pending,
      'actual exit reservation pending',
    );
    _equal(
      sha256.convert(await archiveFile.readAsBytes()).toString(),
      archiveHash,
      'private input archive unchanged',
    );
    await archiveFile.delete();
    final runtimeAtExit = await _businessFiles(runtime.path);
    final recovered = await _child(
      'recover',
      request['recordPath'] as String,
      runtime.path,
    );
    _equal(
      recovered['exitCode'],
      0,
      'fresh recovery child: ${recovered['stderr']}',
    );
    _require(
      recovered['pid'] != applyChild['pid'],
      'Recovery must use distinct OS process.',
    );
    final result = Map<String, Object?>.from(
      jsonDecode(await File(request['resultPath'] as String).readAsString())
          as Map,
    );
    _equal(
      result['workerRuntime'],
      await _runtimeIdentity(),
      'recovery child actual SDK identity',
    );
    _equal(
      result['recoveryPid'],
      recovered['pid'],
      'fresh process result identity',
    );
    final evidence = {
      'checkpoint': checkpoint,
      'marker': marker,
      'record': record,
      'actualPromotedAtExit': promoted,
      'applyChild': applyChild,
      'recoveryChild': recovered,
      'inputArchiveSha256': archiveHash,
      'privateInputRemovedBeforeRecovery': true,
      'result': result,
      'privateRuntimeFilesAfterExit': runtimeAtExit,
      'privateRuntimeFilesAfterRecovery': await _businessFiles(runtime.path),
      'runtimeLimit':
          'Process projection cache is inventoried; only harness-owned runtime is retired. No product crash-cache GC claim.',
    };
    await recoveryDEvidence('real-exit-$checkpoint', evidence);
    return evidence;
  } finally {
    await fixture.dispose();
    if (await runtime.exists()) await runtime.delete(recursive: true);
  }
}

const recoveryDCleanupGuards = [
  'pending',
  'scope',
  'operation',
  'plan',
  'receipt',
  'journalStatus',
  'journalScope',
  'readFailure',
  'deleteFailure',
];

Future<void> recoveryDCleanupGuard(String defect) async {
  final harness = await TransactionTestHarness.create(
    faultInjector: (context) {
      if (context.checkpoint ==
          AuthoringTransactionCheckpoint.afterJournalCommitted) {
        throw const AuthoringTransactionSimulatedCrash();
      }
    },
  );
  try {
    Object? crash;
    try {
      await harness.apply();
    } catch (error) {
      crash = error;
    }
    _require(
      crash is AuthoringTransactionSimulatedCrash,
      'Guard setup must reach committed checkpoint.',
    );
    final initialJournal = (await harness.readJournal())!;
    final receipt = defect == 'pending'
        ? initialJournal.intendedReceipt
        : await (await harness.reopenRecovery()).resume(harness.operationId);
    if (defect == 'journalStatus') {
      final json = Map<String, dynamic>.from(
        (await harness.readJournal())!.toJson(),
      );
      json['status'] = 'prepared';
      json['finalReceipt'] = null;
      await harness.gateway.writeJournal(
        AuthoringTransactionJournal.fromJson(json),
      );
    }
    if (defect == 'journalScope') {
      final json = Map<String, dynamic>.from(
        (await harness.readJournal())!.toJson(),
      );
      json['scope'] = {...json['scope'] as Map, 'actorId': 'foreign-actor'};
      await harness.gateway.writeJournal(
        AuthoringTransactionJournal.fromJson(json),
      );
    }
    final journalBefore = (await harness.readJournal())!.toJson();
    final filesBefore = await _businessFiles(harness.projectDirectory.path);
    final gateway = _CleanupFailureGateway(
      harness.gateway,
      failRead: defect == 'readFailure',
      failDelete: defect == 'deleteFailure',
    );
    final transaction = JournaledAuthoringTransaction(
      plans: harness.planStore,
      gateway: gateway,
      idempotency: harness.ledger,
      clock: () => harness.now,
    );
    await transaction.cleanupCompletedReplay(
      scope: defect == 'scope'
          ? AuthoringIdempotencyScope(
              actorId: 'foreign-actor',
              projectId: harness.scope.projectId,
              actionId: harness.scope.actionId,
              actionVersion: harness.scope.actionVersion,
              key: harness.scope.key,
            )
          : harness.scope,
      planId: defect == 'plan' ? 'foreign-plan' : harness.plan.planId,
      operationId:
          defect == 'operation' ? 'foreign-operation' : harness.operationId,
      receipt: defect == 'receipt' ? initialJournal.intendedReceipt : receipt,
    );
    _equal(
      (await harness.readJournal())?.toJson(),
      journalBefore,
      'guard retained $defect journal',
    );
    _equal(
      await _businessFiles(harness.projectDirectory.path),
      filesBefore,
      'guard $defect business untouched',
    );
    _equal(
      gateway.deleteAttempts,
      defect == 'deleteFailure' ? 1 : 0,
      'guard $defect delete attempts',
    );
    _equal(gateway.lockDepth, 0, 'guard lock released');
    _require(gateway.lockEntries == 1, 'Cleanup must use exclusive lock.');
    if (defect == 'readFailure' || defect == 'deleteFailure') {
      gateway.failRead = false;
      gateway.failDelete = false;
      await transaction.cleanupCompletedReplay(
        scope: harness.scope,
        planId: harness.plan.planId,
        operationId: harness.operationId,
        receipt: receipt,
      );
      _equal(await harness.readJournal(), null, 'failure retry cleanup');
      final retained = await harness.ledger.recordForRecovery(harness.scope);
      _equal(
        retained!.receipt!.toJson(),
        receipt.toJson(),
        'best effort retains same completed receipt',
      );
    }
    await recoveryDEvidence('cleanup-guard-$defect', {
      'defect': defect,
      'businessUnchanged': true,
      'exclusiveLock': true,
      'journalRetainedOnRefusalOrFailure': true,
      'completedReceiptPreserved': defect != 'pending',
    });
  } finally {
    await harness.planStore.dispose();
    await harness.dispose();
  }
}

final class _CleanupFailureGateway implements TransactionFileGateway {
  _CleanupFailureGateway(
    this.delegate, {
    this.failRead = false,
    this.failDelete = false,
  });
  final TransactionFileGateway delegate;
  bool failRead;
  bool failDelete;
  int deleteAttempts = 0;
  int lockDepth = 0;
  int lockEntries = 0;
  @override
  Future<void> deleteTransaction(String operationId) {
    _equal(lockDepth, 1, 'delete under lock');
    deleteAttempts++;
    if (failDelete) {
      throw const FileSystemException('Injected cleanup delete failure');
    }
    return delegate.deleteTransaction(operationId);
  }

  @override
  Future<AuthoringTransactionJournal?> readJournal(String operationId) {
    _equal(lockDepth, 1, 'journal read under lock');
    if (failRead) {
      throw const FileSystemException('Injected cleanup read failure');
    }
    return delegate.readJournal(operationId);
  }

  @override
  Future<T> withExclusiveWriteLock<T>(Future<T> Function() operation) =>
      delegate.withExclusiveWriteLock(() async {
        lockEntries++;
        lockDepth++;
        try {
          return await operation();
        } finally {
          lockDepth--;
        }
      });
  @override
  Future<List<AuthoringTransactionJournal>> listJournals() =>
      delegate.listJournals();
  @override
  Future<void> promoteStaged({
    required String operationId,
    required String storageKey,
    required TransactionPayloadKind kind,
    required String? expectedCurrentRevision,
  }) =>
      delegate.promoteStaged(
        operationId: operationId,
        storageKey: storageKey,
        kind: kind,
        expectedCurrentRevision: expectedCurrentRevision,
      );
  @override
  Future<List<int>?> readResource(String storageKey) =>
      delegate.readResource(storageKey);
  @override
  Future<String?> readResourceRevision(String storageKey) =>
      delegate.readResourceRevision(storageKey);
  @override
  Future<TransactionStagedPayload> readStagedPayload({
    required String operationId,
    required String storageKey,
    required TransactionPayloadKind kind,
  }) =>
      delegate.readStagedPayload(
        operationId: operationId,
        storageKey: storageKey,
        kind: kind,
      );
  @override
  Future<void> stagePayload({
    required String operationId,
    required String storageKey,
    required TransactionPayloadKind kind,
    required List<int>? bytes,
  }) =>
      delegate.stagePayload(
        operationId: operationId,
        storageKey: storageKey,
        kind: kind,
        bytes: bytes,
      );
  @override
  Future<void> writeJournal(AuthoringTransactionJournal journal) =>
      delegate.writeJournal(journal);
}

Future<void> recoveryDBestEffortReplay(String defect) async {
  final fixture = await _fixture(
    faultInjector: (context) {
      if (context.checkpoint ==
          AuthoringTransactionCheckpoint.afterJournalPrepared) {
        throw const AuthoringTransactionSimulatedCrash();
      }
    },
  );
  _Session? session;
  final plans = AuthoringPlanStore();
  try {
    final plan = await _plan(fixture);
    Object? crash;
    try {
      await fixture.apply(plan, operationId: 'best-effort-replay');
    } catch (error) {
      crash = error;
    }
    _require(
      crash is AuthoringTransactionSimulatedCrash,
      'Expected best effort setup checkpoint.',
    );
    await fixture.close();
    session = await _Session.open(fixture.root.path);
    final recovered = await session.job('start_recovery', {
      'operationId': 'best-effort-replay',
    });
    final receipt = Map<String, Object?>.from(
      (recovered['result'] as Map)['receipt'] as Map,
    );
    final local = await LocalTransactionFileGateway.open(
      projectRoot: fixture.root.path,
    );
    final journal = (await local.readJournal('best-effort-replay'))!;
    final gateway = _CleanupFailureGateway(
      local,
      failRead: defect == 'read',
      failDelete: defect == 'delete',
    );
    final store = FileIdempotencyStore(
      filePath: '${fixture.root.path}/.pokemap/authoring/idempotency.jsonl',
    );
    final transaction = JournaledAuthoringTransaction(
      plans: plans,
      gateway: gateway,
      idempotency: AuthoringIdempotencyLedger(store: store),
      clock: DateTime.now,
    );
    final audit = await FileAuthoringAuditLog.open(
      projectRoot: fixture.root.path,
    );
    final executor = SecureAuthoringMutationExecutor(
      transaction: transaction,
      policy: AuthoringAuthorizationPolicy(
        confirmations: AuthoringConfirmationStore(clock: DateTime.now),
        clock: DateTime.now,
      ),
      auditLog: audit,
      clock: DateTime.now,
      auditIdFactory: () => 'best-effort-$defect',
    );
    final history = await FileAuthoringHistoryStore.open(
      projectRoot: fixture.root.path,
    );
    final historyFile = File(
      '${fixture.root.path}/.pokemap/authoring/history.jsonl',
    );
    final historyBefore = await historyFile.readAsString();
    final filesBefore = await _businessFiles(fixture.root.path);
    final replay = await executor.inspectDurableReplay(
      actor: AuthoringActor(
        actorId: 'local_cli',
        permissions: AuthoringPermissionScope.values,
      ),
      projectId: journal.scope.projectId,
      planId: plan.planId,
      operationId: 'best-effort-replay',
      lookup: () => store.lookupOperation(
        actorId: 'local_cli',
        projectId: journal.scope.projectId,
        operationId: 'best-effort-replay',
        now: DateTime.now(),
      ),
      readHistory: (id) =>
          history.get(projectId: journal.scope.projectId, entryId: id),
      resolveAction: (id) => session!.mutations
          .describeMutationContracts()
          .actions
          .singleWhere((action) => action.id == id),
    );
    _equal(
      replay!.toJson(),
      receipt,
      'cleanup $defect failure returns same authorized receipt',
    );
    _equal(
      (await local.readJournal('best-effort-replay'))!.toJson(),
      journal.toJson(),
      'cleanup $defect failure retained journal',
    );
    _equal(
      await historyFile.readAsString(),
      historyBefore,
      'cleanup $defect failure history',
    );
    _equal(
      await _businessFiles(fixture.root.path),
      filesBefore,
      'cleanup $defect failure files',
    );
    final lastAudit = (await audit.readAll()).last;
    _equal(
      lastAudit.decision,
      AuthoringAuditDecision.succeeded,
      'cleanup failure audit unchanged success',
    );
    _equal(
      lastAudit.details['touchedResources'],
      0,
      'cleanup failure zero touched resources',
    );
    _equal(
      gateway.deleteAttempts,
      defect == 'delete' ? 1 : 0,
      'injected failure exact attempts',
    );
    _equal(gateway.lockEntries, 1, 'best effort held exclusive lock');
    await recoveryDEvidence('best-effort-replay-$defect', {
      'injectedFailure': defect,
      'sameReceiptReturned': true,
      'receipt': replay.toJson(),
      'journalRetained': true,
      'historyAndBusinessUnchanged': true,
      'auditDecision': lastAudit.decision.name,
    });
  } finally {
    await session?.close();
    await plans.dispose();
    await fixture.dispose();
  }
}
