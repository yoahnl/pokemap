import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/services/narrative_activity_journal.dart';
import 'package:map_editor/src/application/services/narrative_document_session.dart';
import 'package:map_editor/src/application/services/narrative_undo_stack.dart';

void main() {
  group('NarrativeActivityJournal', () {
    test('is empty until an activity is explicitly appended', () {
      const journal = NarrativeActivityJournal.empty();

      expect(journal.entries, isEmpty);
      expect(
        journal.entries.where(
          (entry) => entry.label.toLowerCase().contains('runtime'),
        ),
        isEmpty,
      );
    });

    test('keeps newest entries first, deduplicates, and stays bounded', () {
      var journal = const NarrativeActivityJournal.empty(maxEntries: 2);
      final first = _entry('first', minute: 1);
      final second = _entry('second', minute: 2);
      final third = _entry('third', minute: 3);

      journal =
          journal.append(first).append(first).append(second).append(third);

      expect(
        journal.entries.map((entry) => entry.id),
        <String>['third', 'second'],
      );
    });

    test('round-trips a versioned deterministic JSON envelope', () {
      final journal = const NarrativeActivityJournal.empty().append(
        NarrativeActivityEntry(
          id: 'activity-1',
          occurredAtUtc: DateTime.utc(2026, 7, 20, 10, 30),
          kind: NarrativeActivityKind.edited,
          label: 'Renommer le chapitre',
          detail: 'Modification locale sécurisée.',
          destination: NarrativeActivityDestination.storylines,
          operationId: 'rename_chapter',
          assetId: 'story-main',
        ),
      );

      final decoded = NarrativeActivityJournal.fromJson(journal.toJson());

      expect(decoded.toJson(), journal.toJson());
    });
  });

  group('NarrativeActivityJournalService', () {
    const service = NarrativeActivityJournalService();
    final now = DateTime.utc(2026, 7, 20, 12);

    test('records a new NSC-13 edit with its exact intention', () {
      final before = _state(
        status: NarrativeDocumentSessionStatus.saved,
        history: const NarrativeUndoStack<String>(),
      );
      final after = _state(
        status: NarrativeDocumentSessionStatus.dirty,
        document: 'after',
        history: const NarrativeUndoStack<String>().record(
          operationId: 'rename_chapter',
          label: 'Renommer le chapitre',
          before: 'before',
          after: 'after',
        ),
      );

      final journal = service.recordSessionTransition(
        journal: const NarrativeActivityJournal.empty(),
        previous: before,
        current: after,
        occurredAtUtc: now,
        destination: NarrativeActivityDestination.storylines,
        assetId: 'story-main',
      );

      expect(journal.entries, hasLength(1));
      expect(journal.entries.single.kind, NarrativeActivityKind.edited);
      expect(journal.entries.single.label, 'Renommer le chapitre');
      expect(journal.entries.single.operationId, 'rename_chapter');
      expect(
        journal.entries.single.destination,
        NarrativeActivityDestination.storylines,
      );
    });

    test('records saved, recovered, failed and conflicted transitions', () {
      var journal = const NarrativeActivityJournal.empty();
      final cases = <NarrativeDocumentSessionStatus, NarrativeActivityKind>{
        NarrativeDocumentSessionStatus.saved: NarrativeActivityKind.saved,
        NarrativeDocumentSessionStatus.recovered:
            NarrativeActivityKind.recovered,
        NarrativeDocumentSessionStatus.failed: NarrativeActivityKind.saveFailed,
        NarrativeDocumentSessionStatus.conflicted:
            NarrativeActivityKind.conflicted,
      };

      var minute = 0;
      for (final entry in cases.entries) {
        journal = service.recordSessionTransition(
          journal: journal,
          previous: _state(status: NarrativeDocumentSessionStatus.saving),
          current: _state(
            status: entry.key,
            code: entry.key.name,
            message: 'Transition ${entry.key.name}',
          ),
          occurredAtUtc: now.add(Duration(minutes: minute++)),
          destination: NarrativeActivityDestination.cinematics,
        );
      }

      expect(
        journal.entries.map((entry) => entry.kind).toSet(),
        cases.values.toSet(),
      );
    });

    test('ignores saving and unchanged session publications', () {
      const empty = NarrativeActivityJournal.empty();
      final saved = _state(status: NarrativeDocumentSessionStatus.saved);
      final saving = _state(status: NarrativeDocumentSessionStatus.saving);

      final afterSaving = service.recordSessionTransition(
        journal: empty,
        previous: saved,
        current: saving,
        occurredAtUtc: now,
        destination: NarrativeActivityDestination.cinematics,
      );
      final afterUnchanged = service.recordSessionTransition(
        journal: afterSaving,
        previous: saved,
        current: saved,
        occurredAtUtc: now,
        destination: NarrativeActivityDestination.cinematics,
      );

      expect(afterUnchanged.entries, isEmpty);
    });
  });

  test('NarrativeActivitySessionRecorder persists real NSC-13 transitions',
      () async {
    final session = NarrativeDocumentSession<String>(
      documentId: 'cinematics',
      initialDocument: 'before',
      gateway: _Gateway(),
      recoveryStore: _RecoveryStore(),
    );
    await session.initialize();
    final store = _ActivityStore();
    var minute = 0;
    final recorder = NarrativeActivitySessionRecorder<String>(
      session: session,
      store: store,
      destination: NarrativeActivityDestination.cinematics,
      nowUtc: () => DateTime.utc(2026, 7, 20, 12, minute++),
    );
    addTearDown(() {
      recorder.dispose();
      session.dispose();
    });

    expect(
      await session.apply(
        operationId: 'rename_cinematic',
        label: 'Renommer la cinématique',
        document: 'after',
      ),
      isTrue,
    );
    await recorder.settled;
    expect(
      await session.save(operationId: 'save_cinematics'),
      isTrue,
    );
    await recorder.settled;

    expect(
      store.journal.entries.map((entry) => entry.kind),
      <NarrativeActivityKind>[
        NarrativeActivityKind.saved,
        NarrativeActivityKind.edited,
      ],
    );
    expect(store.saveCount, 2);
  });
}

NarrativeActivityEntry _entry(String id, {required int minute}) {
  return NarrativeActivityEntry(
    id: id,
    occurredAtUtc: DateTime.utc(2026, 7, 20, 12, minute),
    kind: NarrativeActivityKind.edited,
    label: id,
    destination: NarrativeActivityDestination.storylines,
  );
}

NarrativeDocumentSessionState<String> _state({
  required NarrativeDocumentSessionStatus status,
  String document = 'before',
  NarrativeUndoStack<String> history = const NarrativeUndoStack<String>(),
  String? code,
  String? message,
}) {
  return NarrativeDocumentSessionState<String>(
    documentId: 'narrative-project',
    document: document,
    baseline: 'before',
    baselineRevision: 'revision-1',
    status: status,
    history: history,
    autosaveEnabled: false,
    isInitialized: true,
    code: code,
    message: message,
  );
}

class _Gateway implements NarrativeDocumentGateway<String> {
  @override
  Future<NarrativeDocumentVersion<String>> read() async {
    return const NarrativeDocumentVersion<String>(
      revision: 'revision-1',
      document: 'before',
    );
  }

  @override
  Future<NarrativeDocumentSaveResult<String>> save({
    required String expectedRevision,
    required String before,
    required String after,
    required String operationId,
  }) async {
    return const NarrativeDocumentSaveResult<String>.saved(
      NarrativeDocumentVersion<String>(
        revision: 'revision-2',
        document: 'after',
      ),
    );
  }
}

class _RecoveryStore implements NarrativeDocumentRecoveryStore<String> {
  @override
  Future<void> clear() async {}

  @override
  Future<NarrativeDocumentRecoveryRecord<String>?> read() async => null;

  @override
  Future<void> write(NarrativeDocumentRecoveryRecord<String> record) async {}
}

class _ActivityStore implements NarrativeActivityJournalStore {
  NarrativeActivityJournal journal = const NarrativeActivityJournal.empty();
  int saveCount = 0;

  @override
  Future<NarrativeActivityJournal> load() async => journal;

  @override
  Future<void> save(NarrativeActivityJournal journal) async {
    this.journal = journal;
    saveCount++;
  }
}
