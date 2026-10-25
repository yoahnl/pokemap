import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import '../security/authoring_permission.dart';
import '../support/authoring_file_snapshot.dart';
import '../support/authoring_fingerprint.dart';
import '../support/authoring_timeline.dart';
import 'authoring_history.dart';
import 'history_store.dart';

final class AuthoringHistoryStoreException implements Exception {
  const AuthoringHistoryStoreException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'AuthoringHistoryStoreException($code): $message';
}

typedef FileAuthoringHistoryDecodeWorkerRunner = Future<T> Function<T>(
  T Function() operation,
);

final class FileAuthoringHistoryDecodeDiagnostics {
  const FileAuthoringHistoryDecodeDiagnostics({
    required this.localOperations,
    required this.workerOperations,
    required this.workerFailures,
  });

  final int localOperations;
  final int workerOperations;
  final int workerFailures;
}

final class FileAuthoringHistoryDecodeExecutor {
  FileAuthoringHistoryDecodeExecutor({
    this.offloadThresholdBytes = defaultOffloadThresholdBytes,
    FileAuthoringHistoryDecodeWorkerRunner? workerRunner,
  }) : _workerRunner = workerRunner ?? _runFileAuthoringHistoryDecodeWorker {
    if (offloadThresholdBytes < 0) {
      throw ArgumentError.value(
        offloadThresholdBytes,
        'offloadThresholdBytes',
        'must not be negative',
      );
    }
  }

  static const int defaultOffloadThresholdBytes = 1024 * 1024;

  final int offloadThresholdBytes;
  final FileAuthoringHistoryDecodeWorkerRunner _workerRunner;

  var _localOperations = 0;
  var _workerOperations = 0;
  var _workerFailures = 0;

  FileAuthoringHistoryDecodeDiagnostics get diagnostics =>
      FileAuthoringHistoryDecodeDiagnostics(
        localOperations: _localOperations,
        workerOperations: _workerOperations,
        workerFailures: _workerFailures,
      );

  Future<_HistoryReadResult> _decode(Uint8List bytes) async {
    if (bytes.length < offloadThresholdBytes) {
      _localOperations++;
      return _decodeFileAuthoringHistory(bytes);
    }
    final transferred = TransferableTypedData.fromList([bytes]);
    _workerOperations++;
    try {
      return await _workerRunner(
        () => _decodeFileAuthoringHistory(
          transferred.materialize().asUint8List(),
        ),
      );
    } on Object {
      _workerFailures++;
      rethrow;
    }
  }
}

Future<T> _runFileAuthoringHistoryDecodeWorker<T>(T Function() operation) =>
    Isolate.run(operation);

/// Locked, hash-chained JSONL history with snapshot-bound pagination.
final class FileAuthoringHistoryStore
    implements AuthoringHistoryStore, AuthoringLocalHistoryReader {
  FileAuthoringHistoryStore._(
    this._projectRoot,
    this._onFullRead,
    this._decodeExecutor,
    this._incrementalWrites,
  );

  static Future<FileAuthoringHistoryStore> open({
    required String projectRoot,
    void Function()? onFullRead,
    FileAuthoringHistoryDecodeExecutor? decodeExecutor,
    bool incrementalWrites = false,
  }) async {
    try {
      final directory = Directory(projectRoot);
      if ((await directory.stat()).type != FileSystemEntityType.directory) {
        throw const AuthoringHistoryStoreException(
          'history.project_directory_required',
          'The history project root is not a directory.',
        );
      }
      return FileAuthoringHistoryStore._(
        await directory.resolveSymbolicLinks(),
        onFullRead,
        decodeExecutor ?? FileAuthoringHistoryDecodeExecutor(),
        incrementalWrites,
      );
    } on AuthoringHistoryStoreException {
      rethrow;
    } on Object {
      throw const AuthoringHistoryStoreException(
        'history.project_unavailable',
        'The history project root is unavailable.',
      );
    }
  }

  final String _projectRoot;
  final void Function()? _onFullRead;
  final FileAuthoringHistoryDecodeExecutor _decodeExecutor;
  final bool _incrementalWrites;
  _HistoryAppendIndex? _cachedAppendIndex;
  AuthoringFileSnapshot? _cachedSnapshot;

  static final Map<String, Future<void>> _inProcessLocks = {};

  @override
  Future<void> append(AuthoringHistoryEntry entry) {
    return _guard(() async {
      await _withLock(() async {
        if (_incrementalWrites) {
          if (!entry.entryId.startsWith('receipt_document_')) {
            throw const AuthoringHistoryException(
              'history.incremental_identity_required',
              'Incremental history requires a document receipt identity.',
            );
          }
          await _appendIncremental(entry);
          return;
        }
        _requirePublishedHead(await _readIncrementalHead());
        final incremental = await _readIncremental(entry.entryId);
        if (incremental != null) {
          _requireSameEntry(incremental.entry, entry);
        }
        final file = await _historyFile();
        final state = await _readAppendIndex(file);
        final key = _entryKey(entry.projectId, entry.entryId);
        final existingFingerprint = state.entryFingerprints[key];
        if (existingFingerprint != null) {
          if (existingFingerprint == _entryFingerprint(entry)) {
            return;
          }
          throw const AuthoringHistoryStoreException(
            'history.identity_conflict',
            'The history entry identity is already in use.',
          );
        }
        if (incremental != null) return;
        await _appendEvent(
          file,
          state,
          type: 'append',
          payload: {'entry': entry.toJson()},
        );
      });
    });
  }

  @override
  Future<AuthoringHistoryEntry?> get({
    required String projectId,
    required String entryId,
  }) {
    final safeProject = safeAuthoringSecurityIdentifier(
      projectId,
      'projectId',
    );
    final safeEntry = safeAuthoringSecurityIdentifier(entryId, 'entryId');
    return _guard(() async {
      return _withLock(() async {
        final checkpoint = await _localHistoryFile(
            'history-local-entries', '$safeProject/$safeEntry');
        final preparation = await _checkedFile(
            await _authoringRoot(), 'history-local-preparation.json');
        if (await checkpoint.exists() ||
            _incrementalWrites ||
            await preparation.exists()) {
          return _getLocalEntry(safeProject, safeEntry);
        }
        if (RegExp(r'^receipt_document_[a-f0-9]{32}$').hasMatch(safeEntry)) {
          final head = await _readIncrementalHead();
          _requirePublishedHead(head);
          final stored = await _readIncremental(safeEntry);
          if (stored != null &&
              stored.entry.projectId == safeProject &&
              stored.generation <= head.publishedGeneration) {
            return _applyIncrementalMark(stored.entry);
          }
        }
        final state = await _readMergedState();
        return state.entries[_entryKey(safeProject, safeEntry)]?.entry;
      });
    });
  }

  Future<AuthoringHistoryEntry?> getDocumentEntry(
      {required String projectId, required String entryId}) {
    final safeProject = safeAuthoringSecurityIdentifier(projectId, 'projectId');
    final safeEntry = safeAuthoringSecurityIdentifier(entryId, 'entryId');
    if (!RegExp(r'^receipt_document_[a-f0-9]{32}$').hasMatch(safeEntry)) {
      throw const AuthoringHistoryException(
          'history.document_identity_required',
          'A targeted document receipt is required.');
    }
    return _guard(() => _withLock(() async {
          final head = await _readIncrementalHead();
          _requirePublishedHead(head);
          final stored = await _readIncremental(safeEntry);
          if (stored == null ||
              stored.entry.projectId != safeProject ||
              stored.generation > head.publishedGeneration) {
            return null;
          }
          return _applyIncrementalMark(stored.entry);
        }));
  }

  @override
  Future<AuthoringHistoryEntry?> latestLocalEntry(
      {required String projectId}) async {
    final safeProject = safeAuthoringSecurityIdentifier(projectId, 'projectId');
    if (!_incrementalWrites) {
      final sequence = await _readIncrementalHead();
      final preparedHead =
          await _localHistoryFile('history-local-heads', safeProject);
      if (sequence.publishedGeneration == 0 && !await preparedHead.exists()) {
        return (await list(projectId: safeProject, limit: 1))
            .entries
            .firstOrNull;
      }
    }
    return _guard(() => _withLock(() async {
          final sequence = await _readIncrementalHead();
          _requirePublishedHead(sequence);
          final file =
              await _localHistoryFile('history-local-heads', safeProject);
          if (!await file.exists()) {
            if (sequence.publishedGeneration == 0 &&
                await _localHistoryPrepared()) {
              return null;
            }
            final legacy = await _historyFile();
            if (sequence.publishedGeneration == 0 &&
                (!await legacy.exists() || await legacy.length() == 0)) {
              return null;
            }
            throw const AuthoringHistoryException(
                'history.preparation_required',
                'Prepare the retained history explicitly before local undo or redo.');
          }
          final record = await _readRecord(
              file, 'authoring-history-local-head.json', const {
            'schemaVersion',
            'projectId',
            'entryId',
            'generation',
            'legacySnapshot'
          });
          if (record['projectId'] != safeProject ||
              record['entryId'] is! String ||
              record['generation'] != sequence.publishedGeneration ||
              canonicalAuthoringJson(record['legacySnapshot']) !=
                  canonicalAuthoringJson(await _legacyHistorySnapshot())) {
            throw const AuthoringHistoryException(
                'history.preparation_required',
                'The retained history changed and requires explicit local preparation.');
          }
          return _getLocalEntry(safeProject, record['entryId'] as String);
        }));
  }

  @override
  Future<AuthoringHistoryEntry?> getLocalEntry(
      {required String projectId, required String entryId}) {
    final safeProject = safeAuthoringSecurityIdentifier(projectId, 'projectId');
    final safeEntry = safeAuthoringSecurityIdentifier(entryId, 'entryId');
    return _guard(
        () => _withLock(() => _getLocalEntry(safeProject, safeEntry)));
  }

  Future<AuthoringHistoryEntry?> _getLocalEntry(
      String projectId, String entryId) async {
    final sequence = await _readIncrementalHead();
    _requirePublishedHead(sequence);
    final incremental = await _readIncremental(entryId);
    if (incremental != null) {
      if (incremental.entry.projectId != projectId ||
          incremental.generation > sequence.publishedGeneration) {
        return null;
      }
      return _applyIncrementalMark(incremental.entry);
    }
    final file =
        await _localHistoryFile('history-local-entries', '$projectId/$entryId');
    if (!await file.exists()) {
      if (await _localHistoryPrepared()) return null;
      final legacy = await _historyFile();
      if (await legacy.exists() && await legacy.length() != 0) {
        throw const AuthoringHistoryException('history.preparation_required',
            'Prepare this retained history entry explicitly before local undo or redo.');
      }
      return null;
    }
    final record = await _readRecord(file, 'authoring-history-local-entry.json',
        const {'schemaVersion', 'entry', 'legacySnapshot'});
    if (record['entry'] is! Map ||
        canonicalAuthoringJson(record['legacySnapshot']) !=
            canonicalAuthoringJson(await _legacyHistorySnapshot())) {
      throw const AuthoringHistoryException('history.preparation_required',
          'The retained history changed and requires explicit local preparation.');
    }
    final entry = AuthoringHistoryEntry.fromJson(
        Map<String, dynamic>.from(record['entry'] as Map));
    if (entry.projectId != projectId || entry.entryId != entryId) {
      throw const FormatException();
    }
    return entry;
  }

  Future<bool> _localHistoryPrepared() async {
    final marker = await _checkedFile(
        await _authoringRoot(), 'history-local-preparation.json');
    if (!await marker.exists()) return false;
    final record = await _readRecord(
        marker,
        'authoring-history-local-preparation.json',
        const {'schemaVersion', 'generation', 'legacySnapshot'});
    return canonicalAuthoringJson(record['legacySnapshot']) ==
        canonicalAuthoringJson(await _legacyHistorySnapshot());
  }

  Future<void> prepareLocalHistory({
    bool force = false,
    Future<void> Function(AuthoringHistoryEntry entry)? prepareEntry,
  }) =>
      _guard(() => _withLock(() async {
            final marker = await _checkedFile(
                await _authoringRoot(), 'history-local-preparation.json');
            final sequence = await _readIncrementalHead();
            _requirePublishedHead(sequence);
            final legacySnapshot = await _legacyHistorySnapshot();
            if (await marker.exists()) {
              final record = await _readRecord(
                  marker,
                  'authoring-history-local-preparation.json',
                  const {'schemaVersion', 'generation', 'legacySnapshot'});
              if (!force &&
                  canonicalAuthoringJson(record['legacySnapshot']) ==
                      canonicalAuthoringJson(legacySnapshot)) {
                return;
              }
            }
            final state = await _readMergedState();
            final heads = <String, AuthoringHistoryEntry>{};
            for (final stored in state.entries.values) {
              final entry = stored.entry;
              await prepareEntry?.call(entry);
              final file = await _localHistoryFile('history-local-entries',
                  '${entry.projectId}/${entry.entryId}');
              await _writeRecord(
                  file,
                  {
                    'schemaVersion': 1,
                    'entry': entry.toJson(),
                    'legacySnapshot': legacySnapshot
                  },
                  'authoring-history-local-entry.json');
              final previous = heads[entry.projectId];
              if (previous == null ||
                  _compareHistoryKey(entry.committedAt, entry.entryId,
                          previous.committedAt, previous.entryId) >
                      0) {
                heads[entry.projectId] = entry;
              }
            }
            for (final entry in heads.values) {
              await _publishLocalHead(entry, sequence.publishedGeneration);
            }
            await _writeRecord(
                marker,
                {
                  'schemaVersion': 1,
                  'generation': sequence.publishedGeneration,
                  'legacySnapshot': legacySnapshot
                },
                'authoring-history-local-preparation.json');
          }));

  Future<File> _localHistoryFile(String directoryName, String identity) async {
    final root = await _incrementalDirectory(directoryName, create: true);
    final digest = computeAuthoringJsonFingerprint(identity,
            logicalName: 'authoring-history-local-identity.json')
        .substring(7);
    return _checkedFile(root!, '$digest.json');
  }

  Future<Object?> _legacyHistorySnapshot() async {
    final snapshot = await AuthoringFileSnapshot.capture(await _historyFile());
    return snapshot == null
        ? null
        : [
            snapshot.size,
            snapshot.modified.microsecondsSinceEpoch,
            snapshot.changed.microsecondsSinceEpoch
          ];
  }

  Future<void> _publishLocalHead(
      AuthoringHistoryEntry entry, int generation) async {
    final file =
        await _localHistoryFile('history-local-heads', entry.projectId);
    await _writeRecord(
        file,
        {
          'schemaVersion': 1,
          'projectId': entry.projectId,
          'entryId': entry.entryId,
          'generation': generation,
          'legacySnapshot': await _legacyHistorySnapshot()
        },
        'authoring-history-local-head.json');
  }

  @override
  Future<AuthoringHistoryPage> list({
    required String projectId,
    required int limit,
    AuthoringHistoryCursor? cursor,
  }) {
    final safeProject = safeAuthoringSecurityIdentifier(
      projectId,
      'projectId',
    );
    if (limit < 1 || limit > 100) {
      throw const AuthoringHistoryException(
        'history.limit_invalid',
        'History page size must be between 1 and 100.',
      );
    }
    return _guard(() async {
      return _withLock(() async {
        final state = await _readState(await _historyFile());
        final incremental = await _readIncrementalEntries();
        for (final stored in incremental) {
          final existing = state
              .entries[_entryKey(stored.entry.projectId, stored.entry.entryId)];
          if (existing != null) {
            _requireSameEntry(existing.entry, stored.entry, ignoreMark: true);
          }
        }
        if ((cursor != null && _isMixedCursor(cursor)) ||
            (cursor == null && incremental.isNotEmpty)) {
          return _mixedPage(state, incremental,
              projectId: safeProject, limit: limit, cursor: cursor);
        }
        final projectEntries = state.entries.values
            .where((stored) => stored.entry.projectId == safeProject)
            .toList()
          ..sort((left, right) => right.sequence.compareTo(left.sequence));
        final decoded = cursor == null
            ? null
            : _decodeCursor(cursor, expectedProjectId: safeProject);
        final snapshotMax = decoded?.snapshotMaxSequence ??
            (projectEntries.isEmpty ? 0 : projectEntries.first.sequence);
        final beforeSequence = decoded?.beforeSequence ?? (snapshotMax + 1);
        final eligible = projectEntries
            .where(
              (stored) =>
                  stored.sequence <= snapshotMax &&
                  stored.sequence < beforeSequence,
            )
            .toList(growable: false);
        final page = eligible.take(limit).toList(growable: false);
        final hasMore = eligible.length > page.length;
        return AuthoringHistoryPage(
          entries: List.unmodifiable(page.map((stored) => stored.entry)),
          nextCursor: hasMore
              ? _encodeCursor(
                  projectId: safeProject,
                  snapshotMaxSequence: snapshotMax,
                  beforeSequence: page.last.sequence,
                )
              : null,
        );
      });
    });
  }

  @override
  Future<AuthoringHistoryEntry> markNonUndoable({
    required String projectId,
    required String entryId,
    required String reason,
  }) {
    final safeProject = safeAuthoringSecurityIdentifier(
      projectId,
      'projectId',
    );
    final safeEntry = safeAuthoringSecurityIdentifier(entryId, 'entryId');
    if (!RegExp(r'^[a-z][a-z0-9_.-]*$').hasMatch(reason)) {
      throw ArgumentError.value(reason, 'reason', 'must be a stable code');
    }
    return _guard(() async {
      return _withLock(() async {
        final incremental = await _readIncremental(safeEntry);
        if (incremental != null && incremental.entry.projectId == safeProject) {
          final state = await _readMergedState();
          final entry = state.entries[_entryKey(safeProject, safeEntry)]!.entry;
          if (entry.nonUndoableReason != null) return entry;
          final directory =
              await _incrementalDirectory('history-entry-marks', create: true);
          final file = await _checkedFile(directory!, '$safeEntry.json');
          await _writeRecord(
              file,
              {
                'schemaVersion': 1,
                'entryFingerprint': _entryFingerprint(incremental.entry),
                'reason': reason,
              },
              'authoring-history-entry-mark.json');
          return entry.markNonUndoable(reason);
        }
        final file = await _historyFile();
        final state = await _readState(file);
        final stored = state.entries[_entryKey(safeProject, safeEntry)];
        if (stored == null) {
          throw const AuthoringHistoryException(
            'history.entry_missing',
            'The requested history entry is unavailable.',
          );
        }
        if (stored.entry.nonUndoableReason != null) return stored.entry;
        await _appendEvent(
          file,
          _HistoryAppendIndex.fromState(state),
          type: 'markNonUndoable',
          payload: {
            'projectId': safeProject,
            'entryId': safeEntry,
            'reason': reason,
          },
        );
        _cachedAppendIndex = null;
        _cachedSnapshot = null;
        return stored.entry.markNonUndoable(reason);
      });
    });
  }

  Future<void> _appendIncremental(AuthoringHistoryEntry entry) async {
    final head = await _readIncrementalHead();
    final pending = head.pending;
    final fingerprint = _entryFingerprint(entry);
    if (pending != null && pending.entryId != entry.entryId) {
      _requirePublishedHead(head);
    }
    if (pending != null && pending.fingerprint != fingerprint) {
      throw const AuthoringHistoryStoreException('history.identity_conflict',
          'The pending history entry owns another payload.');
    }
    final existing = await _readIncremental(entry.entryId);
    if (existing != null) {
      _requireSameEntry(existing.entry, entry);
      if (pending == null && existing.generation > head.publishedGeneration) {
        throw const FormatException();
      }
      if (pending == null) {
        if (existing.generation == head.publishedGeneration) {
          await _publishLocalHead(entry, head.publishedGeneration);
        }
        return;
      }
      if (existing.generation != pending.generation) {
        throw const FormatException();
      }
    }
    final generation = pending?.generation ?? head.publishedGeneration + 1;
    if (pending == null) {
      await _writeIncrementalHead(_IncrementalHistoryHead(
        head.publishedGeneration,
        _PendingIncrementalHistoryEntry(generation, entry.entryId, fingerprint),
      ));
    }
    if (existing == null) {
      final root = await _incrementalDirectory('history-entries', create: true);
      final file = await _checkedFile(root!, '${entry.entryId}.json');
      await _writeRecord(
          file,
          {
            'schemaVersion': 1,
            'generation': generation,
            'entry': entry.toJson(),
          },
          'authoring-history-immutable-entry.json');
    }
    await _writeIncrementalHead(_IncrementalHistoryHead(generation, null));
    await _publishLocalHead(entry, generation);
  }

  Future<_IncrementalHistoryHead> _readIncrementalHead() async {
    final file = await _checkedFile(
        await _authoringRoot(), 'history-entries.sequence.json');
    if (!await file.exists()) {
      if (await _incrementalDirectory('history-entries') != null) {
        throw const FormatException('Missing incremental history generation.');
      }
      return const _IncrementalHistoryHead(0, null);
    }
    final record = await _readRecord(
        file,
        'authoring-history-entry-sequence.json',
        const {'schemaVersion', 'publishedGeneration', 'pending'});
    final published = record['publishedGeneration'];
    if (published is! int || published < 0) {
      throw const FormatException();
    }
    final rawPending = record['pending'];
    if (rawPending == null) return _IncrementalHistoryHead(published, null);
    if (rawPending is! Map ||
        rawPending.length != 3 ||
        rawPending.keys.any((key) =>
            !const {'generation', 'entryId', 'fingerprint'}.contains(key)) ||
        rawPending['generation'] != published + 1 ||
        rawPending['entryId'] is! String ||
        rawPending['fingerprint'] is! String ||
        !RegExp(r'^sha256:[0-9a-f]{64}$')
            .hasMatch(rawPending['fingerprint'] as String)) {
      throw const FormatException();
    }
    final entryId = safeAuthoringSecurityIdentifier(
        rawPending['entryId'] as String, 'entryId');
    if (!entryId.startsWith('receipt_document_')) throw const FormatException();
    return _IncrementalHistoryHead(
        published,
        _PendingIncrementalHistoryEntry(
            published + 1, entryId, rawPending['fingerprint'] as String));
  }

  Future<void> _writeIncrementalHead(_IncrementalHistoryHead head) async {
    final file = await _checkedFile(
        await _authoringRoot(), 'history-entries.sequence.json');
    await _writeRecord(
        file,
        {
          'schemaVersion': 1,
          'publishedGeneration': head.publishedGeneration,
          'pending': head.pending == null
              ? null
              : {
                  'generation': head.pending!.generation,
                  'entryId': head.pending!.entryId,
                  'fingerprint': head.pending!.fingerprint,
                },
        },
        'authoring-history-entry-sequence.json');
  }

  void _requirePublishedHead(_IncrementalHistoryHead head) {
    if (head.pending != null) {
      throw const AuthoringHistoryException('history.recovery_required',
          'Retry the pending history entry before accessing or appending history.');
    }
  }

  Future<_IncrementalHistoryEntry?> _readIncremental(String entryId) async {
    final safeEntry = safeAuthoringSecurityIdentifier(entryId, 'entryId');
    final root = await _incrementalDirectory('history-entries');
    if (root == null) return null;
    final file = await _checkedFile(root, '$safeEntry.json');
    if (!await file.exists()) return null;
    final record = await _readRecord(
        file,
        'authoring-history-immutable-entry.json',
        const {'schemaVersion', 'generation', 'entry'});
    final generation = record['generation'];
    if (generation is! int || generation < 1 || record['entry'] is! Map) {
      throw const FormatException();
    }
    final entry = AuthoringHistoryEntry.fromJson(
        Map<String, dynamic>.from(record['entry']! as Map));
    if (entry.entryId != safeEntry ||
        !entry.entryId.startsWith('receipt_document_')) {
      throw const FormatException();
    }
    return _IncrementalHistoryEntry(entry, generation);
  }

  Future<List<_IncrementalHistoryEntry>> _readIncrementalEntries() async {
    final head = await _readIncrementalHead();
    _requirePublishedHead(head);
    final root = await _incrementalDirectory('history-entries');
    if (root == null) {
      if (head.publishedGeneration != 0) throw const FormatException();
      return const [];
    }
    final maximum = head.publishedGeneration;
    final generations = <int>{};
    final entries = <_IncrementalHistoryEntry>[];
    await for (final entity in root.list(followLinks: false)) {
      final name = entity.uri.pathSegments.last;
      if (entity is! File || !name.endsWith('.json')) {
        throw const AuthoringHistoryStoreException('history.store_path_invalid',
            'The incremental history path is unsafe.');
      }
      final entry = await _readIncremental(name.substring(0, name.length - 5));
      if (entry == null ||
          entry.generation > maximum ||
          !generations.add(entry.generation)) {
        throw const FormatException();
      }
      entries.add(_IncrementalHistoryEntry(
          await _applyIncrementalMark(entry.entry), entry.generation));
    }
    if (generations.length != maximum) throw const FormatException();
    return entries;
  }

  Future<AuthoringHistoryEntry> _applyIncrementalMark(
      AuthoringHistoryEntry entry) async {
    final root = await _incrementalDirectory('history-entry-marks');
    if (root == null) return entry;
    final file = await _checkedFile(root, '${entry.entryId}.json');
    if (!await file.exists()) return entry;
    final record = await _readRecord(file, 'authoring-history-entry-mark.json',
        const {'schemaVersion', 'entryFingerprint', 'reason'});
    final reason = record['reason'];
    if (record['entryFingerprint'] != _entryFingerprint(entry) ||
        reason is! String ||
        !RegExp(r'^[a-z][a-z0-9_.-]*$').hasMatch(reason)) {
      throw const FormatException();
    }
    return entry.markNonUndoable(reason);
  }

  Future<_HistoryState> _readMergedState() async {
    final legacy = await _readState(await _historyFile());
    final entries = Map<String, _StoredHistoryEntry>.of(legacy.entries);
    for (final incremental in await _readIncrementalEntries()) {
      final key =
          _entryKey(incremental.entry.projectId, incremental.entry.entryId);
      final existing = entries[key];
      if (existing != null) {
        _requireSameEntry(existing.entry, incremental.entry, ignoreMark: true);
        if (existing.entry.nonUndoableReason == null) {
          entries[key] = _StoredHistoryEntry(
              entry: incremental.entry, sequence: existing.sequence);
        }
      } else {
        entries[key] = _StoredHistoryEntry(
            entry: incremental.entry, sequence: incremental.generation);
      }
    }
    return _HistoryState(
        entries: entries,
        lastSequence: legacy.lastSequence,
        lastDigest: legacy.lastDigest);
  }

  Future<AuthoringHistoryPage> _mixedPage(
    _HistoryState legacy,
    List<_IncrementalHistoryEntry> incremental, {
    required String projectId,
    required int limit,
    required AuthoringHistoryCursor? cursor,
  }) async {
    final head = await _readIncrementalHead();
    _requirePublishedHead(head);
    final maximum = head.publishedGeneration;
    final decoded =
        cursor == null ? null : _decodeMixedCursor(cursor, projectId);
    final legacyMaximum = decoded?.legacyMaximum ?? legacy.lastSequence;
    final generationMaximum = decoded?.generationMaximum ?? maximum;
    if (legacyMaximum > legacy.lastSequence || generationMaximum > maximum) {
      throw const AuthoringHistoryException(
          'history.cursor_invalid', 'The history snapshot is unavailable.');
    }
    final entries = <String, AuthoringHistoryEntry>{};
    for (final stored in legacy.entries.values) {
      if (stored.sequence <= legacyMaximum &&
          stored.entry.projectId == projectId) {
        entries[stored.entry.entryId] = stored.entry;
      }
    }
    for (final stored in incremental) {
      if (stored.entry.projectId != projectId) continue;
      final existing =
          legacy.entries[_entryKey(projectId, stored.entry.entryId)];
      if (existing != null) {
        _requireSameEntry(existing.entry, stored.entry, ignoreMark: true);
      }
      if (stored.generation <= generationMaximum) {
        entries[stored.entry.entryId] =
            existing?.entry.nonUndoableReason != null
                ? existing!.entry
                : stored.entry;
      }
    }
    final ordered = entries.values
        .where((entry) =>
            decoded == null ||
            _compareHistoryKey(entry.committedAt, entry.entryId,
                    decoded.beforeTime, decoded.beforeId) <
                0)
        .toList()
      ..sort((left, right) => _compareHistoryKey(
          right.committedAt, right.entryId, left.committedAt, left.entryId));
    final page = ordered.take(limit).toList(growable: false);
    return AuthoringHistoryPage(
        entries: List.unmodifiable(page),
        nextCursor: ordered.length > page.length
            ? _encodeMixedCursor(
                projectId, legacyMaximum, generationMaximum, page.last)
            : null);
  }

  void _requireSameEntry(
      AuthoringHistoryEntry before, AuthoringHistoryEntry after,
      {bool ignoreMark = false}) {
    final left = before.toJson();
    final right = after.toJson();
    if (ignoreMark) {
      if (before.nonUndoableReason != null &&
          after.nonUndoableReason != null &&
          before.nonUndoableReason != after.nonUndoableReason) {
        throw const AuthoringHistoryStoreException(
            'history.identity_conflict', 'The history entry marks conflict.');
      }
      left.remove('nonUndoableReason');
      right.remove('nonUndoableReason');
    }
    if (canonicalAuthoringJson(left) != canonicalAuthoringJson(right)) {
      throw const AuthoringHistoryStoreException('history.identity_conflict',
          'The history entry identity is already in use.');
    }
  }

  Future<Directory?> _incrementalDirectory(String name,
      {bool create = false}) async {
    final root = Directory(_join((await _authoringRoot()).path, name));
    final type = await FileSystemEntity.type(root.path, followLinks: false);
    if (type == FileSystemEntityType.notFound) {
      if (!create) return null;
      await root.create();
    } else if (type != FileSystemEntityType.directory) {
      throw const AuthoringHistoryStoreException('history.store_path_invalid',
          'The incremental history directory is unsafe.');
    }
    return root;
  }

  Future<File> _checkedFile(Directory root, String name) async {
    final file = File(_join(root.path, name));
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type != FileSystemEntityType.notFound &&
        type != FileSystemEntityType.file) {
      throw const AuthoringHistoryStoreException('history.store_path_invalid',
          'The incremental history file is unsafe.');
    }
    return file;
  }

  Future<Map<String, Object?>> _readRecord(
      File file, String logicalName, Set<String> keys) async {
    final raw = jsonDecode(await file.readAsString());
    if (raw is! Map) throw const FormatException();
    final record = Map<String, Object?>.from(raw);
    final digest = record.remove('digest');
    if (record['schemaVersion'] != 1 ||
        record.length != keys.length ||
        record.keys.any((key) => !keys.contains(key)) ||
        digest !=
            computeAuthoringJsonFingerprint(record, logicalName: logicalName)) {
      throw const FormatException();
    }
    return record;
  }

  Future<void> _writeRecord(
      File file, Map<String, Object?> record, String logicalName) async {
    final temporary =
        await _checkedFile(file.parent, '${file.uri.pathSegments.last}.tmp');
    try {
      final writer = await temporary.open(mode: FileMode.write);
      try {
        await writer.writeString(jsonEncode({
          ...record,
          'digest':
              computeAuthoringJsonFingerprint(record, logicalName: logicalName)
        }));
        await writer.flush();
      } finally {
        await writer.close();
      }
      await temporary.rename(file.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  Future<void> _appendEvent(
    File file,
    _HistoryAppendIndex state, {
    required String type,
    required Map<String, Object?> payload,
  }) async {
    final sequence = state.lastSequence + 1;
    final previousDigest = state.lastDigest;
    final event = _HistoryEvent(
      sequence: sequence,
      previousDigest: previousDigest,
      type: type,
      payload: payload,
      digest: _eventDigest(
        sequence: sequence,
        previousDigest: previousDigest,
        type: type,
        payload: payload,
      ),
    );
    final writer = await file.open(mode: FileMode.append);
    try {
      await writer.writeString('${jsonEncode(event.toJson())}\n');
      await writer.flush();
    } finally {
      await writer.close();
    }
    _cachedAppendIndex = _applyIndexedEvent(state, event);
    _cachedSnapshot = await AuthoringFileSnapshot.capture(file);
  }

  Future<_HistoryState> _readState(File file) async {
    final snapshot = await AuthoringFileSnapshot.capture(file);
    _onFullRead?.call();
    if (snapshot == null) {
      final state = _HistoryState.empty();
      _cachedAppendIndex = _HistoryAppendIndex.fromState(state);
      _cachedSnapshot = null;
      return state;
    }
    final bytes = await traceAuthoringPhase(
      'authoring.history.read_file',
      file.readAsBytes,
      arguments: {'bytes': snapshot.size},
    );
    if (bytes.isEmpty) {
      final state = _HistoryState.empty();
      _cachedAppendIndex = _HistoryAppendIndex.fromState(state);
      _cachedSnapshot = snapshot;
      return state;
    }
    final decoded = await traceAuthoringPhase(
      'authoring.history.decode_dispatch',
      () => _decodeExecutor._decode(bytes),
      arguments: {'bytes': bytes.length},
    );
    final state = decoded.state;
    _cachedAppendIndex = decoded.appendIndex;
    _cachedSnapshot = snapshot;
    return state;
  }

  Future<_HistoryAppendIndex> _readAppendIndex(File file) async {
    final snapshot = await AuthoringFileSnapshot.capture(file);
    final cached = _cachedAppendIndex;
    if (cached != null && snapshot == _cachedSnapshot) return cached;
    await _readState(file);
    return _cachedAppendIndex!;
  }

  Future<T> _withLock<T>(Future<T> Function() operation) async {
    final previous = _inProcessLocks[_projectRoot] ?? Future<void>.value();
    final completion = Completer<void>();
    _inProcessLocks[_projectRoot] = completion.future;
    await previous;
    try {
      late final RandomAccessFile lock;
      try {
        final root = await _authoringRoot();
        lock = await File(_join(root.path, 'history.lock')).open(
          mode: FileMode.append,
        );
        await lock.lock(FileLock.exclusive);
      } on AuthoringHistoryStoreException {
        rethrow;
      } on Object {
        throw const AuthoringHistoryStoreException(
          'history.store_io',
          'The history store lock failed safely.',
        );
      }
      try {
        return await operation();
      } finally {
        try {
          await lock.unlock();
        } on Object {
          // Closing still releases the OS lock.
        }
        await lock.close();
      }
    } finally {
      completion.complete();
      if (identical(_inProcessLocks[_projectRoot], completion.future)) {
        _inProcessLocks.remove(_projectRoot);
      }
    }
  }

  Future<File> _historyFile() async {
    final file = File(_join((await _authoringRoot()).path, 'history.jsonl'));
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type != FileSystemEntityType.notFound &&
        type != FileSystemEntityType.file) {
      throw const AuthoringHistoryStoreException(
        'history.store_path_invalid',
        'The history store path is unsafe.',
      );
    }
    return file;
  }

  Future<Directory> _authoringRoot() async {
    var current = Directory(_projectRoot);
    for (final segment in const ['.pokemap', 'authoring']) {
      final next = Directory(_join(current.path, segment));
      final type = await FileSystemEntity.type(next.path, followLinks: false);
      if (type == FileSystemEntityType.notFound) {
        await next.create();
      } else if (type != FileSystemEntityType.directory) {
        throw const AuthoringHistoryStoreException(
          'history.store_path_invalid',
          'The history store directory is unsafe.',
        );
      }
      current = next;
    }
    return current;
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on AuthoringHistoryException {
      rethrow;
    } on AuthoringHistoryStoreException {
      rethrow;
    } on FormatException {
      throw const AuthoringHistoryStoreException(
        'history.store_corrupt',
        'The history store failed strict verification.',
      );
    } on Object {
      throw const AuthoringHistoryStoreException(
        'history.store_io',
        'The history store failed safely.',
      );
    }
  }
}

final class _IncrementalHistoryEntry {
  const _IncrementalHistoryEntry(this.entry, this.generation);

  final AuthoringHistoryEntry entry;
  final int generation;
}

final class _IncrementalHistoryHead {
  const _IncrementalHistoryHead(this.publishedGeneration, this.pending);

  final int publishedGeneration;
  final _PendingIncrementalHistoryEntry? pending;
}

final class _PendingIncrementalHistoryEntry {
  const _PendingIncrementalHistoryEntry(
      this.generation, this.entryId, this.fingerprint);

  final int generation;
  final String entryId;
  final String fingerprint;
}

final class _MixedHistoryCursor {
  const _MixedHistoryCursor(this.legacyMaximum, this.generationMaximum,
      this.beforeTime, this.beforeId);

  final int legacyMaximum;
  final int generationMaximum;
  final DateTime beforeTime;
  final String beforeId;
}

int _compareHistoryKey(
    DateTime leftTime, String leftId, DateTime rightTime, String rightId) {
  final compared = leftTime.compareTo(rightTime);
  return compared == 0 ? leftId.compareTo(rightId) : compared;
}

Map<String, dynamic> _cursorEnvelope(AuthoringHistoryCursor cursor) {
  final value = cursor.wireValue;
  final padded =
      value.padRight(value.length + ((4 - value.length % 4) % 4), '=');
  final decoded = jsonDecode(utf8.decode(base64Url.decode(padded)));
  if (decoded is! Map || decoded['payload'] is! Map) {
    throw const FormatException();
  }
  return Map<String, dynamic>.from(decoded);
}

bool _isMixedCursor(AuthoringHistoryCursor cursor) {
  try {
    return (_cursorEnvelope(cursor)['payload'] as Map)['schemaVersion'] == 2;
  } on Object {
    throw const AuthoringHistoryException(
        'history.cursor_invalid', 'The history cursor is invalid.');
  }
}

AuthoringHistoryCursor _encodeMixedCursor(String projectId, int legacyMaximum,
    int generationMaximum, AuthoringHistoryEntry before) {
  final payload = <String, Object?>{
    'schemaVersion': 2,
    'projectId': projectId,
    'legacyMaximum': legacyMaximum,
    'generationMaximum': generationMaximum,
    'beforeTime': before.committedAt.toUtc().toIso8601String(),
    'beforeId': before.entryId,
  };
  return AuthoringHistoryCursor.fromWireValue(
      base64UrlEncode(utf8.encode(jsonEncode({
    'payload': payload,
    'digest': computeAuthoringJsonFingerprint(payload,
        logicalName: 'authoring-history-cursor.json'),
  }))).replaceAll('=', ''));
}

_MixedHistoryCursor _decodeMixedCursor(
    AuthoringHistoryCursor cursor, String projectId) {
  try {
    final envelope = _cursorEnvelope(cursor);
    final payload = Map<String, Object?>.from(envelope['payload'] as Map);
    const keys = {
      'schemaVersion',
      'projectId',
      'legacyMaximum',
      'generationMaximum',
      'beforeTime',
      'beforeId'
    };
    final legacy = payload['legacyMaximum'];
    final generation = payload['generationMaximum'];
    if (payload.length != keys.length ||
        payload.keys.any((key) => !keys.contains(key)) ||
        payload['schemaVersion'] != 2 ||
        payload['projectId'] != projectId ||
        legacy is! int ||
        legacy < 0 ||
        generation is! int ||
        generation < 1 ||
        payload['beforeTime'] is! String ||
        payload['beforeId'] is! String ||
        envelope['digest'] !=
            computeAuthoringJsonFingerprint(payload,
                logicalName: 'authoring-history-cursor.json')) {
      throw const FormatException();
    }
    final time = DateTime.parse(payload['beforeTime']! as String);
    final id = safeAuthoringSecurityIdentifier(
        payload['beforeId']! as String, 'beforeId');
    return _MixedHistoryCursor(legacy, generation, time, id);
  } on Object {
    throw const AuthoringHistoryException(
        'history.cursor_invalid', 'The history cursor is invalid.');
  }
}

final class _HistoryReadResult {
  const _HistoryReadResult({
    required this.state,
    required this.appendIndex,
  });

  final _HistoryState state;
  final _HistoryAppendIndex appendIndex;
}

_HistoryReadResult _decodeFileAuthoringHistory(Uint8List bytes) =>
    traceAuthoringSync(
      'authoring.history.decode_worker',
      () => _decodeHistoryEvents(bytes),
      arguments: {'bytes': bytes.length},
    );

_HistoryReadResult _decodeHistoryEvents(Uint8List bytes) {
  final entries = <String, _StoredHistoryEntry>{};
  var lastSequence = 0;
  String? lastDigest;
  var lineStart = 0;

  void applyLine(int lineEnd) {
    if (lineEnd == lineStart) throw const FormatException();
    final decoded = jsonDecode(
      utf8.decoder.convert(bytes, lineStart, lineEnd),
    );
    if (decoded is! Map) throw const FormatException();
    final event = _HistoryEvent.fromJson(Map<String, dynamic>.from(decoded));
    if (event.sequence != lastSequence + 1 ||
        event.previousDigest != lastDigest ||
        event.digest !=
            _eventDigest(
              sequence: event.sequence,
              previousDigest: event.previousDigest,
              type: event.type,
              payload: event.payload,
            )) {
      throw const FormatException();
    }
    if (event.type == 'append') {
      final rawEntry = event.payload['entry'];
      if (event.payload.length != 1 || rawEntry is! Map) {
        throw const FormatException();
      }
      final entry = AuthoringHistoryEntry.fromJson(
        Map<String, dynamic>.from(rawEntry),
      );
      final key = _entryKey(entry.projectId, entry.entryId);
      if (entries.containsKey(key)) throw const FormatException();
      entries[key] = _StoredHistoryEntry(
        entry: entry,
        sequence: event.sequence,
      );
    } else if (event.type == 'markNonUndoable') {
      if (event.payload.keys.toSet().difference(
            const {'projectId', 'entryId', 'reason'},
          ).isNotEmpty ||
          event.payload.length != 3) {
        throw const FormatException();
      }
      final projectId = event.payload['projectId'];
      final entryId = event.payload['entryId'];
      final reason = event.payload['reason'];
      if (projectId is! String || entryId is! String || reason is! String) {
        throw const FormatException();
      }
      final stored = entries[_entryKey(projectId, entryId)];
      if (stored == null || stored.entry.nonUndoableReason != null) {
        throw const FormatException();
      }
      entries[_entryKey(projectId, entryId)] = _StoredHistoryEntry(
        entry: stored.entry.markNonUndoable(reason),
        sequence: stored.sequence,
      );
    } else {
      throw const FormatException();
    }
    lastSequence = event.sequence;
    lastDigest = event.digest;
  }

  for (var index = 0; index < bytes.length; index++) {
    if (bytes[index] != 0x0a) continue;
    applyLine(index);
    lineStart = index + 1;
  }
  if (lineStart < bytes.length) applyLine(bytes.length);
  final state = _HistoryState(
    entries: entries,
    lastSequence: lastSequence,
    lastDigest: lastDigest,
  );
  return _HistoryReadResult(
    state: state,
    appendIndex: traceAuthoringSync(
      'authoring.history.build_append_index',
      () => _HistoryAppendIndex.fromState(state),
      arguments: {'entries': state.entries.length},
    ),
  );
}

final class _HistoryState {
  const _HistoryState({
    required this.entries,
    required this.lastSequence,
    required this.lastDigest,
  });

  factory _HistoryState.empty() => const _HistoryState(
        entries: {},
        lastSequence: 0,
        lastDigest: null,
      );

  final Map<String, _StoredHistoryEntry> entries;
  final int lastSequence;
  final String? lastDigest;
}

final class _StoredHistoryEntry {
  const _StoredHistoryEntry({required this.entry, required this.sequence});

  final AuthoringHistoryEntry entry;
  final int sequence;
}

final class _HistoryAppendIndex {
  const _HistoryAppendIndex({
    required this.entryFingerprints,
    required this.lastSequence,
    required this.lastDigest,
  });

  factory _HistoryAppendIndex.fromState(_HistoryState state) {
    return _HistoryAppendIndex(
      entryFingerprints: <String, String>{
        for (final entry in state.entries.entries)
          entry.key: _entryFingerprint(entry.value.entry),
      },
      lastSequence: state.lastSequence,
      lastDigest: state.lastDigest,
    );
  }

  final Map<String, String> entryFingerprints;
  final int lastSequence;
  final String? lastDigest;
}

final class _HistoryEvent {
  _HistoryEvent({
    required this.sequence,
    required this.previousDigest,
    required this.type,
    required Map<String, Object?> payload,
    required this.digest,
  }) : payload = Map.unmodifiable(payload);

  factory _HistoryEvent.fromJson(Map<String, dynamic> json) {
    const keys = {
      'schemaVersion',
      'sequence',
      'previousDigest',
      'type',
      'payload',
      'digest',
    };
    if (json['schemaVersion'] != 1 ||
        json.keys.any((key) => !keys.contains(key)) ||
        json['sequence'] is! int ||
        (json['previousDigest'] != null && json['previousDigest'] is! String) ||
        json['type'] is! String ||
        json['payload'] is! Map ||
        json['digest'] is! String) {
      throw const FormatException();
    }
    return _HistoryEvent(
      sequence: json['sequence'] as int,
      previousDigest: json['previousDigest'] as String?,
      type: json['type'] as String,
      payload: Map<String, Object?>.from(json['payload'] as Map),
      digest: json['digest'] as String,
    );
  }

  final int sequence;
  final String? previousDigest;
  final String type;
  final Map<String, Object?> payload;
  final String digest;

  Map<String, Object?> toJson() => {
        'schemaVersion': 1,
        'sequence': sequence,
        'previousDigest': previousDigest,
        'type': type,
        'payload': payload,
        'digest': digest,
      };
}

_HistoryAppendIndex _applyIndexedEvent(
  _HistoryAppendIndex state,
  _HistoryEvent event,
) {
  final fingerprints = Map<String, String>.of(state.entryFingerprints);
  if (event.type == 'append') {
    final entry = AuthoringHistoryEntry.fromJson(
      Map<String, dynamic>.from(event.payload['entry']! as Map),
    );
    fingerprints[_entryKey(entry.projectId, entry.entryId)] =
        _entryFingerprint(entry);
  }
  return _HistoryAppendIndex(
    entryFingerprints: fingerprints,
    lastSequence: event.sequence,
    lastDigest: event.digest,
  );
}

String _entryFingerprint(AuthoringHistoryEntry entry) =>
    computeAuthoringJsonFingerprint(
      entry.toJson(),
      logicalName: 'authoring-history-entry.json',
    );

final class _DecodedHistoryCursor {
  const _DecodedHistoryCursor({
    required this.snapshotMaxSequence,
    required this.beforeSequence,
  });

  final int snapshotMaxSequence;
  final int beforeSequence;
}

AuthoringHistoryCursor _encodeCursor({
  required String projectId,
  required int snapshotMaxSequence,
  required int beforeSequence,
}) {
  final payload = <String, Object?>{
    'schemaVersion': 1,
    'projectId': projectId,
    'snapshotMaxSequence': snapshotMaxSequence,
    'beforeSequence': beforeSequence,
  };
  final envelope = {
    'payload': payload,
    'digest': computeAuthoringJsonFingerprint(
      payload,
      logicalName: 'authoring-history-cursor.json',
    ),
  };
  return AuthoringHistoryCursor.fromWireValue(
    base64UrlEncode(utf8.encode(jsonEncode(envelope))).replaceAll('=', ''),
  );
}

_DecodedHistoryCursor _decodeCursor(
  AuthoringHistoryCursor cursor, {
  required String expectedProjectId,
}) {
  try {
    final value = cursor.wireValue;
    final padded =
        value.padRight(value.length + ((4 - value.length % 4) % 4), '=');
    final decoded = jsonDecode(utf8.decode(base64Url.decode(padded)));
    if (decoded is! Map || decoded['payload'] is! Map) {
      throw const FormatException();
    }
    final envelope = Map<String, dynamic>.from(decoded);
    final payload = Map<String, Object?>.from(envelope['payload'] as Map);
    const keys = {
      'schemaVersion',
      'projectId',
      'snapshotMaxSequence',
      'beforeSequence',
    };
    if (payload['schemaVersion'] != 1 ||
        payload.keys.any((key) => !keys.contains(key)) ||
        payload['projectId'] != expectedProjectId ||
        payload['snapshotMaxSequence'] is! int ||
        payload['beforeSequence'] is! int ||
        envelope['digest'] !=
            computeAuthoringJsonFingerprint(
              payload,
              logicalName: 'authoring-history-cursor.json',
            )) {
      throw const FormatException();
    }
    final snapshot = payload['snapshotMaxSequence'] as int;
    final before = payload['beforeSequence'] as int;
    if (snapshot < 0 || before < 1 || before > snapshot + 1) {
      throw const FormatException();
    }
    return _DecodedHistoryCursor(
      snapshotMaxSequence: snapshot,
      beforeSequence: before,
    );
  } on Object {
    throw const AuthoringHistoryException(
      'history.cursor_invalid',
      'The history cursor is invalid.',
    );
  }
}

String _eventDigest({
  required int sequence,
  required String? previousDigest,
  required String type,
  required Map<String, Object?> payload,
}) {
  return computeAuthoringJsonFingerprint(
    {
      'schemaVersion': 1,
      'sequence': sequence,
      'previousDigest': previousDigest,
      'type': type,
      'payload': payload,
    },
    logicalName: 'authoring-history-event.json',
  );
}

String _entryKey(String projectId, String entryId) =>
    '$projectId\u0000$entryId';

String _join(String first, String second) =>
    [first, second].join(Platform.pathSeparator);
