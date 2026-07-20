import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/services/narrative_document_session.dart';
import 'package:map_editor/src/application/services/narrative_undo_stack.dart';

void main() {
  group('NarrativeDocumentSession', () {
    test('initializes from disk as saved when no recovery exists', () async {
      final fixture = _fixture(diskDocument: 'disk-A', diskRevision: 'rev-A');

      await fixture.session.initialize();

      expect(fixture.session.state.isInitialized, isTrue);
      expect(
        fixture.session.state.status,
        NarrativeDocumentSessionStatus.saved,
      );
      expect(fixture.session.state.document, 'disk-A');
      expect(fixture.session.state.baseline, 'disk-A');
      expect(fixture.session.state.baselineRevision, 'rev-A');
      expect(fixture.session.state.isDirty, isFalse);
    });

    test('journals an edit before publishing the dirty document', () async {
      final fixture = _fixture();
      await fixture.session.initialize();
      final visibleDuringWrite = <String>[];
      fixture.store.onWrite = (_) {
        visibleDuringWrite.add(fixture.session.state.document);
      };

      final applied = await fixture.session.apply(
        operationId: 'edit-1',
        label: 'Modifier la timeline',
        document: 'local-B',
      );

      expect(applied, isTrue);
      expect(visibleDuringWrite, ['disk-A']);
      expect(fixture.store.writeCount, 1);
      expect(fixture.store.record!.document, 'local-B');
      expect(fixture.session.state.document, 'local-B');
      expect(
        fixture.session.state.status,
        NarrativeDocumentSessionStatus.dirty,
      );
      expect(fixture.session.state.canUndo, isTrue);
    });

    test('stays saving until persistence confirms and clears recovery after it',
        () async {
      final persistence = Completer<NarrativeDocumentSaveResult<String>>();
      final fixture = _fixture(saveHandler: (_) => persistence.future);
      await fixture.session.initialize();
      await fixture.session.apply(
        operationId: 'edit-1',
        label: 'Modifier',
        document: 'local-B',
      );

      final pending = fixture.session.save(operationId: 'save-1');
      await fixture.gateway.saveStarted.future;

      expect(
        fixture.session.state.status,
        NarrativeDocumentSessionStatus.saving,
      );
      expect(fixture.store.clearCount, 0);
      persistence.complete(
        const NarrativeDocumentSaveResult<String>.saved(
          NarrativeDocumentVersion(revision: 'rev-B', document: 'local-B'),
        ),
      );

      expect(await pending, isTrue);
      expect(
        fixture.session.state.status,
        NarrativeDocumentSessionStatus.saved,
      );
      expect(fixture.session.state.baselineRevision, 'rev-B');
      expect(fixture.session.state.isDirty, isFalse);
      expect(fixture.store.clearCount, 1);
    });

    test('failed save keeps the exact local snapshot and recovery journal',
        () async {
      final fixture = _fixture(
        saveHandler: (_) async =>
            const NarrativeDocumentSaveResult<String>.failed(
          code: 'diskFull',
          message: 'Disk full',
        ),
      );
      await fixture.session.initialize();
      await fixture.session.apply(
        operationId: 'edit-1',
        label: 'Modifier',
        document: 'local-B',
      );

      final saved = await fixture.session.save(operationId: 'save-1');

      expect(saved, isFalse);
      expect(
        fixture.session.state.status,
        NarrativeDocumentSessionStatus.failed,
      );
      expect(fixture.session.state.document, 'local-B');
      expect(fixture.session.state.isDirty, isTrue);
      expect(fixture.session.state.code, 'diskFull');
      expect(fixture.store.record, isNotNull);
      expect(fixture.store.clearCount, 0);
    });

    test('refuses a concurrent save without a second gateway call', () async {
      final persistence = Completer<NarrativeDocumentSaveResult<String>>();
      final fixture = _fixture(saveHandler: (_) => persistence.future);
      await fixture.session.initialize();
      await fixture.session.apply(
        operationId: 'edit-1',
        label: 'Modifier',
        document: 'local-B',
      );

      final first = fixture.session.save(operationId: 'save-1');
      await fixture.gateway.saveStarted.future;
      final second = await fixture.session.save(operationId: 'save-2');

      expect(second, isFalse);
      expect(fixture.gateway.saveCount, 1);
      persistence.complete(
        const NarrativeDocumentSaveResult<String>.saved(
          NarrativeDocumentVersion(revision: 'rev-B', document: 'local-B'),
        ),
      );
      expect(await first, isTrue);
    });

    test('recovers the document and both history branches on matching base',
        () async {
      const first = NarrativeUndoEntry<String>(
        operationId: 'edit-1',
        label: 'Première',
        before: 'disk-A',
        after: 'local-B',
      );
      const second = NarrativeUndoEntry<String>(
        operationId: 'edit-2',
        label: 'Deuxième',
        before: 'local-B',
        after: 'local-C',
      );
      final fixture = _fixture(
        recovery: const NarrativeDocumentRecoveryRecord<String>(
          documentId: 'cinematics',
          baseRevision: 'rev-A',
          baseline: 'disk-A',
          document: 'local-B',
          undoEntries: [first],
          redoEntries: [second],
        ),
      );

      await fixture.session.initialize();

      expect(
        fixture.session.state.status,
        NarrativeDocumentSessionStatus.recovered,
      );
      expect(fixture.session.state.document, 'local-B');
      expect(fixture.session.state.canUndo, isTrue);
      expect(fixture.session.state.canRedo, isTrue);
      expect(fixture.store.clearCount, 0);
    });

    test('clears a stale journal when its current document is already durable',
        () async {
      final fixture = _fixture(
        diskDocument: 'local-B',
        diskRevision: 'rev-B',
        recovery: const NarrativeDocumentRecoveryRecord<String>(
          documentId: 'cinematics',
          baseRevision: 'rev-A',
          baseline: 'disk-A',
          document: 'local-B',
        ),
      );

      await fixture.session.initialize();

      expect(
        fixture.session.state.status,
        NarrativeDocumentSessionStatus.saved,
      );
      expect(fixture.session.state.baselineRevision, 'rev-B');
      expect(fixture.store.clearCount, 1);
    });

    test('surfaces divergent recovery as a conflict with exact comparison',
        () async {
      final fixture = _fixture(
        diskDocument: 'external-C',
        diskRevision: 'rev-C',
        recovery: const NarrativeDocumentRecoveryRecord<String>(
          documentId: 'cinematics',
          baseRevision: 'rev-A',
          baseline: 'disk-A',
          document: 'local-B',
        ),
      );

      await fixture.session.initialize();

      expect(
        fixture.session.state.status,
        NarrativeDocumentSessionStatus.conflicted,
      );
      expect(fixture.session.state.document, 'local-B');
      expect(fixture.session.comparison!.baseline, 'disk-A');
      expect(fixture.session.comparison!.local, 'local-B');
      expect(fixture.session.comparison!.external, 'external-C');
      expect(fixture.store.clearCount, 0);
    });

    test('keep local rebases on external revision and saves with CAS',
        () async {
      final fixture = _fixture(
        diskDocument: 'external-C',
        diskRevision: 'rev-C',
        recovery: const NarrativeDocumentRecoveryRecord<String>(
          documentId: 'cinematics',
          baseRevision: 'rev-A',
          baseline: 'disk-A',
          document: 'local-B',
        ),
        saveHandler: (_) async =>
            const NarrativeDocumentSaveResult<String>.saved(
          NarrativeDocumentVersion(revision: 'rev-D', document: 'local-B'),
        ),
      );
      await fixture.session.initialize();

      expect(await fixture.session.keepLocal(), isTrue);
      expect(fixture.session.state.baseline, 'external-C');
      expect(fixture.session.state.baselineRevision, 'rev-C');
      expect(fixture.session.state.document, 'local-B');
      expect(
        fixture.session.state.status,
        NarrativeDocumentSessionStatus.dirty,
      );

      expect(await fixture.session.save(operationId: 'save-local'), isTrue);
      expect(fixture.gateway.lastSave!.expectedRevision, 'rev-C');
    });

    test('reload external is undoable and undo restores the local document',
        () async {
      final fixture = _fixture(
        diskDocument: 'external-C',
        diskRevision: 'rev-C',
        recovery: const NarrativeDocumentRecoveryRecord<String>(
          documentId: 'cinematics',
          baseRevision: 'rev-A',
          baseline: 'disk-A',
          document: 'local-B',
        ),
      );
      await fixture.session.initialize();

      expect(await fixture.session.reloadExternal(), isTrue);
      expect(fixture.session.state.document, 'external-C');
      expect(
        fixture.session.state.status,
        NarrativeDocumentSessionStatus.saved,
      );
      expect(fixture.session.state.canUndo, isTrue);

      expect(await fixture.session.undo(), isTrue);
      expect(fixture.session.state.document, 'local-B');
      expect(
        fixture.session.state.status,
        NarrativeDocumentSessionStatus.dirty,
      );
      expect(fixture.store.record!.document, 'local-B');
    });

    test('recovery write failure refuses the visible edit', () async {
      final fixture = _fixture();
      await fixture.session.initialize();
      fixture.store.writeError = const FileSystemException('read only');

      final applied = await fixture.session.apply(
        operationId: 'edit-1',
        label: 'Modifier',
        document: 'local-B',
      );

      expect(applied, isFalse);
      expect(fixture.session.state.document, 'disk-A');
      expect(
        fixture.session.state.status,
        NarrativeDocumentSessionStatus.failed,
      );
      expect(fixture.session.state.code, 'recoveryWriteFailed');
    });

    test('configurable autosave replaces its pending scheduled action',
        () async {
      final scheduler = _ManualScheduler();
      final fixture = _fixture(scheduler: scheduler.schedule);
      await fixture.session.initialize();

      await fixture.session.apply(
        operationId: 'edit-1',
        label: 'Modifier',
        document: 'local-B',
      );
      expect(scheduler.pending, isEmpty);

      fixture.session.setAutosaveEnabled(true);
      expect(scheduler.pending, hasLength(1));
      await fixture.session.apply(
        operationId: 'edit-2',
        label: 'Modifier encore',
        document: 'local-C',
      );

      expect(scheduler.cancelCount, 1);
      expect(scheduler.pending.where((task) => !task.cancelled), hasLength(1));
      await scheduler.runLatest();
      expect(fixture.gateway.saveCount, 1);
      expect(
          fixture.session.state.status, NarrativeDocumentSessionStatus.saved);
    });

    test('discard restores the durable baseline and clears both histories',
        () async {
      final fixture = _fixture();
      await fixture.session.initialize();
      await fixture.session.apply(
        operationId: 'edit-1',
        label: 'Modifier',
        document: 'local-B',
      );
      await fixture.session.undo();
      await fixture.session.redo();
      final clearsBeforeDiscard = fixture.store.clearCount;

      expect(await fixture.session.discard(), isTrue);
      expect(fixture.session.state.document, 'disk-A');
      expect(fixture.session.state.canUndo, isFalse);
      expect(fixture.session.state.canRedo, isFalse);
      expect(
          fixture.session.state.status, NarrativeDocumentSessionStatus.saved);
      expect(fixture.store.clearCount, clearsBeforeDiscard + 1);
    });

    test('explicit discard recovers from an unreadable recovery journal',
        () async {
      final fixture = _fixture();
      fixture.store.readError = const FormatException('broken journal');
      await fixture.session.initialize();

      expect(
        fixture.session.state.status,
        NarrativeDocumentSessionStatus.failed,
      );
      expect(fixture.session.state.baselineRevision, isNull);

      fixture.store.readError = null;
      expect(await fixture.session.discard(), isTrue);
      expect(fixture.session.state.document, 'disk-A');
      expect(fixture.session.state.baselineRevision, 'rev-A');
      expect(
        fixture.session.state.status,
        NarrativeDocumentSessionStatus.saved,
      );
      expect(fixture.store.clearCount, 1);
    });
  });
}

_Fixture _fixture({
  String diskDocument = 'disk-A',
  String diskRevision = 'rev-A',
  NarrativeDocumentRecoveryRecord<String>? recovery,
  Future<NarrativeDocumentSaveResult<String>> Function(_SaveCall call)?
      saveHandler,
  NarrativeDocumentAutosaveScheduler? scheduler,
}) {
  final gateway = _FakeGateway(
    version: NarrativeDocumentVersion(
      revision: diskRevision,
      document: diskDocument,
    ),
    saveHandler: saveHandler,
  );
  final store = _FakeStore(record: recovery);
  return _Fixture(
    gateway: gateway,
    store: store,
    session: NarrativeDocumentSession<String>(
      documentId: 'cinematics',
      initialDocument: diskDocument,
      gateway: gateway,
      recoveryStore: store,
      autosaveDelay: const Duration(seconds: 2),
      autosaveScheduler: scheduler,
    ),
  );
}

final class _Fixture {
  const _Fixture({
    required this.gateway,
    required this.store,
    required this.session,
  });

  final _FakeGateway gateway;
  final _FakeStore store;
  final NarrativeDocumentSession<String> session;
}

typedef _SaveCall = ({
  String expectedRevision,
  String before,
  String after,
  String operationId,
});

final class _FakeGateway implements NarrativeDocumentGateway<String> {
  _FakeGateway({required this.version, this.saveHandler});

  NarrativeDocumentVersion<String> version;
  final Future<NarrativeDocumentSaveResult<String>> Function(_SaveCall call)?
      saveHandler;
  final Completer<void> saveStarted = Completer<void>();
  int readCount = 0;
  int saveCount = 0;
  _SaveCall? lastSave;

  @override
  Future<NarrativeDocumentVersion<String>> read() async {
    readCount++;
    return version;
  }

  @override
  Future<NarrativeDocumentSaveResult<String>> save({
    required String expectedRevision,
    required String before,
    required String after,
    required String operationId,
  }) async {
    saveCount++;
    final call = (
      expectedRevision: expectedRevision,
      before: before,
      after: after,
      operationId: operationId,
    );
    lastSave = call;
    if (!saveStarted.isCompleted) saveStarted.complete();
    final result = await (saveHandler?.call(call) ??
        Future.value(
          NarrativeDocumentSaveResult<String>.saved(
            NarrativeDocumentVersion(
              revision: 'rev-saved-$saveCount',
              document: after,
            ),
          ),
        ));
    if (result case NarrativeDocumentSaved<String>(:final version)) {
      this.version = version;
    }
    return result;
  }
}

final class _FakeStore implements NarrativeDocumentRecoveryStore<String> {
  _FakeStore({this.record});

  NarrativeDocumentRecoveryRecord<String>? record;
  Object? writeError;
  Object? readError;
  void Function(NarrativeDocumentRecoveryRecord<String> record)? onWrite;
  int readCount = 0;
  int writeCount = 0;
  int clearCount = 0;

  @override
  Future<NarrativeDocumentRecoveryRecord<String>?> read() async {
    readCount++;
    if (readError case final error?) throw error;
    return record;
  }

  @override
  Future<void> write(NarrativeDocumentRecoveryRecord<String> next) async {
    writeCount++;
    onWrite?.call(next);
    if (writeError case final error?) throw error;
    record = next;
  }

  @override
  Future<void> clear() async {
    clearCount++;
    record = null;
  }
}

final class _ManualTask implements NarrativeDocumentAutosaveHandle {
  _ManualTask(this.callback, this.onCancel);

  final Future<void> Function() callback;
  final VoidCallback onCancel;
  bool cancelled = false;

  @override
  void cancel() {
    if (cancelled) return;
    cancelled = true;
    onCancel();
  }
}

final class _ManualScheduler {
  final List<_ManualTask> pending = [];
  int cancelCount = 0;

  NarrativeDocumentAutosaveHandle schedule(
    Duration _,
    Future<void> Function() callback,
  ) {
    final task = _ManualTask(callback, () => cancelCount++);
    pending.add(task);
    return task;
  }

  Future<void> runLatest() async {
    final task = pending.lastWhere((candidate) => !candidate.cancelled);
    await task.callback();
  }
}
