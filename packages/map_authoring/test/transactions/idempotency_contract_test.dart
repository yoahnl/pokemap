import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart'
    show
        AuthoringPerformanceCounterName,
        AuthoringPerformanceObserver,
        AuthoringPerformanceSpan;
import 'package:test/test.dart';

void main() {
  group('durable authoring idempotency', () {
    late Directory sandbox;
    late String ledgerPath;
    late DateTime now;

    setUp(() async {
      sandbox = await Directory.systemTemp.createTemp('pokemap_idempotency_');
      addTearDown(() => sandbox.delete(recursive: true));
      ledgerPath = '${sandbox.path}${Platform.pathSeparator}ledger.jsonl';
      now = DateTime.utc(2026, 7, 31, 12);
    });

    test(
      'same scoped key and payload replays one exact receipt after reopen',
      () async {
        final scope = _scope();
        var applyCount = 0;
        final firstRequest = _request(requestId: 'req-first');
        final firstLedger = _ledger(ledgerPath, () => now);

        final first = await firstLedger.execute(
          scope: scope,
          request: firstRequest,
          operationId: 'operation-first',
          apply: () async {
            applyCount++;
            return _receipt(firstRequest, 'receipt-first');
          },
        );

        final reopenedLedger = _ledger(ledgerPath, () => now);
        final retry = await reopenedLedger.execute(
          scope: scope,
          request: _request(requestId: 'req-retry'),
          operationId: 'operation-retry',
          apply: () async {
            applyCount++;
            return _receipt(firstRequest, 'receipt-duplicate');
          },
        );

        expect(applyCount, 1);
        expect(retry.toJson(), first.toJson());
        expect(retry.requestId, 'req-first');
        expect(await File(ledgerPath).exists(), isTrue);
        final durableText = await File(ledgerPath).readAsString();
        expect(durableText, isNot(contains('key-shared')));
        expect(durableText, isNot(contains('workspace:ephemeral')));
      },
    );

    test('reports durable filesystem and JSON work to the observer', () async {
      final observer = _RecordingPerformanceObserver();
      final request = _request(requestId: 'req-observed');
      final ledger = AuthoringIdempotencyLedger(
        store: FileIdempotencyStore(
          filePath: ledgerPath,
          performanceObserver: observer,
        ),
        clock: () => now,
      );

      await ledger.execute(
        scope: _scope(),
        request: request,
        operationId: 'operation-observed',
        apply: () => _receipt(request, 'receipt-observed'),
      );
      await FileIdempotencyStore(
        filePath: ledgerPath,
        performanceObserver: observer,
      ).read(_scope());

      expect(
        observer.count(AuthoringPerformanceCounterName.filesystemMetadata),
        greaterThan(0),
      );
      expect(
        observer.count(AuthoringPerformanceCounterName.filesystemRead),
        greaterThan(0),
      );
      expect(
        observer.count(AuthoringPerformanceCounterName.filesystemWrite),
        greaterThan(0),
      );
      expect(
        observer.count(AuthoringPerformanceCounterName.jsonEncode),
        greaterThan(0),
      );
      expect(
        observer.count(AuthoringPerformanceCounterName.jsonDecode),
        greaterThan(0),
      );
    });

    test(
      'same scoped key with a different canonical payload is refused',
      () async {
        final ledger = _ledger(ledgerPath, () => now);
        final firstRequest = _request(requestId: 'req-first');
        await ledger.execute(
          scope: _scope(),
          request: firstRequest,
          operationId: 'operation-first',
          apply: () => _receipt(firstRequest, 'receipt-first'),
        );

        await expectLater(
          () => ledger.execute(
            scope: _scope(),
            request: _request(
              requestId: 'req-conflict',
              parameters: const {'amount': 2},
            ),
            operationId: 'operation-conflict',
            apply: () => throw StateError('must not apply'),
          ),
          throwsA(
            isA<AuthoringIdempotencyException>().having(
              (error) => error.code,
              'code',
              'idempotency.payload_conflict',
            ),
          ),
        );
      },
    );

    test(
      'actor project action version and key each scope reservations',
      () async {
        final ledger = _ledger(ledgerPath, () => now);
        var applies = 0;
        final scopes = [
          _scope(actorId: 'actor-a'),
          _scope(actorId: 'actor-b'),
          _scope(actorId: 'actor-a', projectId: 'project-b'),
          _scope(actorId: 'actor-a', actionVersion: 2, key: 'key-v2'),
          _scope(actorId: 'actor-a', key: 'key-other'),
        ];

        for (var index = 0; index < scopes.length; index++) {
          final scope = scopes[index];
          final request = _request(
            requestId: 'req-$index',
            actionVersion: scope.actionVersion,
            idempotencyKey: scope.key,
          );
          await ledger.execute(
            scope: scope,
            request: request,
            operationId: 'operation-$index',
            apply: () {
              applies++;
              return _receipt(request, 'receipt-$index');
            },
          );
        }

        expect(applies, scopes.length);
      },
    );

    test(
      'pending reservation survives failure and requires recovery',
      () async {
        final ledger = _ledger(ledgerPath, () => now);
        final request = _request(requestId: 'req-pending');
        var applies = 0;

        await expectLater(
          () => ledger.execute(
            scope: _scope(),
            request: request,
            operationId: 'operation-pending',
            apply: () {
              applies++;
              throw StateError('outcome unknown');
            },
          ),
          throwsStateError,
        );

        final reopened = _ledger(ledgerPath, () => now);
        await expectLater(
          () => reopened.execute(
            scope: _scope(),
            request: _request(requestId: 'req-retry'),
            operationId: 'operation-retry',
            apply: () {
              applies++;
              return _receipt(request, 'receipt-unsafe');
            },
          ),
          throwsA(
            isA<AuthoringIdempotencyException>().having(
              (error) => error.code,
              'code',
              'idempotency.recovery_required',
            ),
          ),
        );
        expect(applies, 1);
      },
    );

    test('concurrent retry never invokes the apply callback twice', () async {
      final firstLedger = _ledger(ledgerPath, () => now);
      final secondLedger = _ledger(ledgerPath, () => now);
      final request = _request(requestId: 'req-concurrent');
      final enteredApply = Completer<void>();
      final releaseApply = Completer<void>();
      var applies = 0;

      final first = firstLedger.execute(
        scope: _scope(),
        request: request,
        operationId: 'operation-first',
        apply: () async {
          applies++;
          enteredApply.complete();
          await releaseApply.future;
          return _receipt(request, 'receipt-concurrent');
        },
      );
      await enteredApply.future;

      await expectLater(
        () => secondLedger.execute(
          scope: _scope(),
          request: _request(requestId: 'req-concurrent-retry'),
          operationId: 'operation-second',
          apply: () {
            applies++;
            return _receipt(request, 'receipt-duplicate');
          },
        ),
        throwsA(
          isA<AuthoringIdempotencyException>().having(
            (error) => error.code,
            'code',
            'idempotency.recovery_required',
          ),
        ),
      );
      releaseApply.complete();

      expect((await first).receiptId, 'receipt-concurrent');
      expect(applies, 1);
    });

    test(
      'retention pruning removes expired completed records but not pending',
      () async {
        final store = FileIdempotencyStore(filePath: ledgerPath);
        final ledger = AuthoringIdempotencyLedger(
          store: store,
          clock: () => now,
          completedRetention: const Duration(hours: 1),
        );
        final completedScope = _scope(key: 'completed');
        final completedRequest = _request(
          requestId: 'req-completed',
          idempotencyKey: 'completed',
        );
        await ledger.execute(
          scope: completedScope,
          request: completedRequest,
          operationId: 'operation-completed',
          apply: () => _receipt(completedRequest, 'receipt-completed'),
        );

        final pendingScope = _scope(key: 'pending');
        final pendingRequest = _request(
          requestId: 'req-pending',
          idempotencyKey: 'pending',
        );
        await expectLater(
          () => ledger.execute(
            scope: pendingScope,
            request: pendingRequest,
            operationId: 'operation-pending',
            apply: () => throw StateError('pending'),
          ),
          throwsStateError,
        );
        now = now.add(const Duration(hours: 1));

        expect(await ledger.pruneExpired(), 1);
        expect(await store.read(completedScope), isNull);
        expect(
          (await store.read(pendingScope))?.status,
          AuthoringIdempotencyStatus.pending,
        );
        final compactedLines = await File(ledgerPath).readAsLines().then(
              (lines) => lines.where((line) => line.isNotEmpty).toList(),
            );
        expect(compactedLines, hasLength(1));
        expect(compactedLines.single, contains('operation-pending'));
        expect(compactedLines.single, isNot(contains('receipt-completed')));
      },
    );

    test('reuses one validated file snapshot until another writer changes it',
        () async {
      var fullReads = 0;
      final store = FileIdempotencyStore(
        filePath: ledgerPath,
        onFullRead: () => fullReads += 1,
      );
      final ledger = AuthoringIdempotencyLedger(
        store: store,
        clock: () => now,
      );
      final request = _request(requestId: 'req-cache');

      await ledger.execute(
        scope: _scope(),
        request: request,
        operationId: 'operation-cache',
        apply: () => _receipt(request, 'receipt-cache'),
      );
      expect(fullReads, 1);

      expect(
          await ledger.inspect(scope: _scope(), request: request), isNotNull);
      expect(fullReads, 1);

      await File(ledgerPath).writeAsString(
        '{"corrupt":true}\n',
        mode: FileMode.append,
      );
      await expectLater(
        () => store.read(_scope()),
        throwsA(
          isA<IdempotencyStoreException>().having(
            (error) => error.code,
            'code',
            'idempotency.store_corrupt',
          ),
        ),
      );
      expect(fullReads, 2);
    });

    test('first ledger access compacts expired completed receipts', () async {
      final request = _request(requestId: 'req-expired');
      final scope = _scope();
      final first = AuthoringIdempotencyLedger(
        store: FileIdempotencyStore(filePath: ledgerPath),
        clock: () => now,
        completedRetention: const Duration(hours: 1),
      );
      await first.execute(
        scope: scope,
        request: request,
        operationId: 'operation-expired',
        apply: () => _receipt(request, 'receipt-expired'),
      );
      now = now.add(const Duration(hours: 2));
      final reopened = AuthoringIdempotencyLedger(
        store: FileIdempotencyStore(filePath: ledgerPath),
        clock: () => now,
        completedRetention: const Duration(hours: 1),
      );

      expect(await reopened.inspect(scope: scope, request: request), isNull);
      expect(await File(ledgerPath).readAsString(), isEmpty);
    });

    test('scope validation rejects path-like identities', () {
      expect(
        () => _scope(projectId: '/Users/private/project'),
        throwsArgumentError,
      );
      expect(() => _scope(actorId: r'C:\private\actor'), throwsArgumentError);
    });

    test(
      'reopens safely from either interrupted compaction boundary',
      () async {
        final scope = _scope();
        final request = _request(requestId: 'req-recovery');
        final ledger = _ledger(ledgerPath, () => now);
        await ledger.execute(
          scope: scope,
          request: request,
          operationId: 'operation-recovery',
          apply: () => _receipt(request, 'receipt-recovery'),
        );

        await File(ledgerPath).rename('$ledgerPath.backup');
        final backupRecovered = await FileIdempotencyStore(
          filePath: ledgerPath,
        ).read(scope);
        expect(backupRecovered?.receipt?.receiptId, 'receipt-recovery');
        expect(await File('$ledgerPath.backup').exists(), isFalse);

        await File(ledgerPath).copy('$ledgerPath.compact');
        await File(ledgerPath).rename('$ledgerPath.backup');
        final compactRecovered = await FileIdempotencyStore(
          filePath: ledgerPath,
        ).read(scope);
        expect(compactRecovered?.receipt?.receiptId, 'receipt-recovery');
        expect(await File('$ledgerPath.compact').exists(), isFalse);
        expect(await File('$ledgerPath.backup').exists(), isFalse);
      },
    );

    test(
      'reports corrupt durable events without leaking the store path',
      () async {
        await File(ledgerPath).writeAsString('{not-json}\n');

        await expectLater(
          () => FileIdempotencyStore(filePath: ledgerPath).read(_scope()),
          throwsA(
            isA<IdempotencyStoreException>()
                .having(
                  (error) => error.code,
                  'code',
                  'idempotency.store_corrupt',
                )
                .having(
                  (error) => error.toString(),
                  'safe error',
                  isNot(contains(sandbox.path)),
                ),
          ),
        );
      },
    );

    test(
      'rejects symlinked metadata parents, ledger, and auxiliary files',
      () async {
        final outside = await Directory.systemTemp.createTemp(
          'pokemap_idempotency_outside_',
        );
        addTearDown(() => outside.delete(recursive: true));

        final parentProject = Directory('${sandbox.path}/parent-project');
        await parentProject.create();
        await Link('${parentProject.path}/.pokemap').create(outside.path);
        await _expectUnsafeStore(
          '${parentProject.path}/.pokemap/authoring/idempotency.jsonl',
        );
        expect(await Directory('${outside.path}/authoring').exists(), isFalse);

        for (final suffix in const ['', '.lock', '.compact', '.backup']) {
          final project = Directory(
            '${sandbox.path}/file-${suffix.isEmpty ? 'ledger' : suffix.substring(1)}',
          );
          final authoring = Directory('${project.path}/.pokemap/authoring');
          await authoring.create(recursive: true);
          final path = '${authoring.path}/idempotency.jsonl';
          final target = File(
            '${outside.path}/target-${suffix.isEmpty ? 'ledger' : suffix.substring(1)}',
          );
          await target.writeAsString('sentinel');
          await Link('$path$suffix').create(target.path);

          await _expectUnsafeStore(path);
          expect(await target.readAsString(), 'sentinel');
        }
      },
    );
  });
}

final class _RecordingPerformanceObserver
    implements AuthoringPerformanceObserver {
  final Map<String, int> _counters = <String, int>{};

  int count(String name) => _counters[name] ?? 0;

  @override
  void incrementCounter(String name, {int by = 1}) {
    _counters.update(name, (value) => value + by, ifAbsent: () => by);
  }

  @override
  AuthoringPerformanceSpan? startSpan(String name) => null;
}

Future<void> _expectUnsafeStore(String filePath) async {
  await expectLater(
    () => FileIdempotencyStore(filePath: filePath).read(_scope()),
    throwsA(
      isA<IdempotencyStoreException>().having(
        (error) => error.code,
        'code',
        'idempotency.path_unsafe',
      ),
    ),
  );
}

AuthoringIdempotencyLedger _ledger(String filePath, DateTime Function() clock) {
  return AuthoringIdempotencyLedger(
    store: FileIdempotencyStore(filePath: filePath),
    clock: clock,
    completedRetention: const Duration(days: 30),
  );
}

AuthoringIdempotencyScope _scope({
  String actorId = 'actor-a',
  String projectId = 'project-a',
  int actionVersion = 1,
  String key = 'key-shared',
}) {
  return AuthoringIdempotencyScope(
    actorId: actorId,
    projectId: projectId,
    actionId: 'fixture.increment',
    actionVersion: actionVersion,
    key: key,
  );
}

AuthoringRequest _request({
  required String requestId,
  int actionVersion = 1,
  String idempotencyKey = 'key-shared',
  Map<String, Object?> parameters = const {'amount': 1},
}) {
  return AuthoringRequest(
    requestId: requestId,
    actionId: 'fixture.increment',
    actionVersion: actionVersion,
    workspaceHandle: 'workspace:ephemeral',
    parameters: parameters,
    expectedRevision: _revision('before'),
    idempotencyKey: idempotencyKey,
  );
}

AuthoringReceipt _receipt(AuthoringRequest request, String receiptId) {
  final resource = AuthoringResourceRef(kind: 'project', id: 'project-a');
  return AuthoringReceipt(
    receiptId: receiptId,
    requestId: request.requestId,
    actionId: request.actionId,
    actionVersion: request.actionVersion,
    status: AuthoringReceiptStatus.applied,
    beforeRevision: request.expectedRevision,
    afterRevision: _revision(receiptId),
    createdAtUtc: '2026-07-31T12:00:00.000Z',
    diff: AuthoringDiff([
      AuthoringDiffEntry(
        operation: AuthoringDiffOperation.replace,
        resource: resource,
        path: r'$.value',
        before: 0,
        after: 1,
      ),
    ]),
  );
}

String _revision(String value) => computeAuthoringBytesFingerprint(
      utf8.encode(value),
      logicalName: 'project.json',
    );
