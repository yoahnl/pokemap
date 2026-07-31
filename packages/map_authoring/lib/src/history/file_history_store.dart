import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../security/authoring_permission.dart';
import '../support/authoring_fingerprint.dart';
import 'authoring_history.dart';
import 'history_store.dart';

final class AuthoringHistoryStoreException implements Exception {
  const AuthoringHistoryStoreException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'AuthoringHistoryStoreException($code): $message';
}

/// Locked, hash-chained JSONL history with snapshot-bound pagination.
final class FileAuthoringHistoryStore implements AuthoringHistoryStore {
  FileAuthoringHistoryStore._(this._projectRoot);

  static Future<FileAuthoringHistoryStore> open({
    required String projectRoot,
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

  static final Map<String, Future<void>> _inProcessLocks = {};

  @override
  Future<void> append(AuthoringHistoryEntry entry) {
    return _guard(() async {
      await _withLock(() async {
        final file = await _historyFile();
        final state = await _readState(file);
        final key = _entryKey(entry.projectId, entry.entryId);
        final existing = state.entries[key];
        if (existing != null) {
          if (canonicalAuthoringJson(existing.entry.toJson()) ==
              canonicalAuthoringJson(entry.toJson())) {
            return;
          }
          throw const AuthoringHistoryStoreException(
            'history.identity_conflict',
            'The history entry identity is already in use.',
          );
        }
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
        final state = await _readState(await _historyFile());
        return state.entries[_entryKey(safeProject, safeEntry)]?.entry;
      });
    });
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
          state,
          type: 'markNonUndoable',
          payload: {
            'projectId': safeProject,
            'entryId': safeEntry,
            'reason': reason,
          },
        );
        return stored.entry.markNonUndoable(reason);
      });
    });
  }

  Future<void> _appendEvent(
    File file,
    _HistoryState state, {
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
  }

  Future<_HistoryState> _readState(File file) async {
    if (!await file.exists()) return _HistoryState.empty();
    final content = await file.readAsString();
    if (content.isEmpty) return _HistoryState.empty();
    final lines = content.split('\n');
    if (lines.last.isEmpty) lines.removeLast();
    if (lines.any((line) => line.isEmpty)) throw const FormatException();
    final entries = <String, _StoredHistoryEntry>{};
    var lastSequence = 0;
    String? lastDigest;
    for (final line in lines) {
      final decoded = jsonDecode(line);
      if (decoded is! Map) throw const FormatException();
      final event = _HistoryEvent.fromJson(
        Map<String, dynamic>.from(decoded),
      );
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
    return _HistoryState(
      entries: entries,
      lastSequence: lastSequence,
      lastDigest: lastDigest,
    );
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
