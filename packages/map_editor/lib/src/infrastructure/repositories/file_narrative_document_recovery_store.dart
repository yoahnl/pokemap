import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../application/services/narrative_document_session.dart';
import '../../application/services/narrative_undo_stack.dart';

typedef NarrativeRecoveryDocumentEncoder<T> = Object? Function(T document);
typedef NarrativeRecoveryDocumentDecoder<T> = T Function(Object? value);
typedef NarrativeRecoveryDocumentMigrationDetector =
    bool Function(Object? value);

/// File-backed crash-recovery journal for one narrative document session.
///
/// The journal is written through a flushed sibling file then atomically
/// renamed. Invalid evidence is deliberately retained for inspection instead
/// of being silently discarded.
final class FileNarrativeDocumentRecoveryStore<T>
    implements NarrativeDocumentRecoveryStore<T> {
  FileNarrativeDocumentRecoveryStore({
    required String journalPath,
    required NarrativeRecoveryDocumentEncoder<T> encodeDocument,
    required NarrativeRecoveryDocumentDecoder<T> decodeDocument,
    NarrativeRecoveryDocumentMigrationDetector? needsMigration,
  }) : _journal = File(_requiredPath(journalPath)),
       _encodeDocument = encodeDocument,
       _decodeDocument = decodeDocument,
       _needsMigration = needsMigration;

  final File _journal;
  final NarrativeRecoveryDocumentEncoder<T> _encodeDocument;
  final NarrativeRecoveryDocumentDecoder<T> _decodeDocument;
  final NarrativeRecoveryDocumentMigrationDetector? _needsMigration;
  _PendingRecoveryMutation<T>? _pendingMutation;
  Future<void>? _drainFuture;

  String get journalPath => _journal.path;

  @override
  Future<NarrativeDocumentRecoveryRecord<T>?> read() async {
    if (!await _journal.exists()) {
      return null;
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(await _journal.readAsString());
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException('Recovery journal cannot be decoded: $error');
    }
    final json = _object(decoded, 'journal');
    final record = _decodeRecord(json);
    if (_recordNeedsMigration(json)) {
      await write(record);
    }
    return record;
  }

  @override
  Future<void> write(NarrativeDocumentRecoveryRecord<T> record) {
    return _enqueueMutation(record);
  }

  @override
  Future<void> clear() => _enqueueMutation(null);

  Future<void> _writeNow(NarrativeDocumentRecoveryRecord<T> record) async {
    final temp = File('${_journal.path}.tmp');
    await _journal.parent.create(recursive: true);
    final bytes = utf8.encode(jsonEncode(_encodeRecord(record)));
    final handle = await temp.open(mode: FileMode.write);
    try {
      await handle.writeFrom(bytes);
      await handle.flush();
    } finally {
      await handle.close();
    }

    // Verify the exact flushed envelope before exposing it as recovery data.
    try {
      final verification = jsonDecode(await temp.readAsString());
      _decodeRecord(_object(verification, 'journal'));
      await temp.rename(_journal.path);
    } on Object {
      if (await temp.exists()) {
        await temp.delete();
      }
      rethrow;
    }
  }

  Future<void> _clearNow() async {
    if (await _journal.exists()) {
      await _journal.delete();
    }
    final temp = File('${_journal.path}.tmp');
    if (await temp.exists()) {
      await temp.delete();
    }
  }

  Future<void> _enqueueMutation(NarrativeDocumentRecoveryRecord<T>? record) {
    final completer = Completer<void>();
    final pending = _pendingMutation;
    _pendingMutation = _PendingRecoveryMutation<T>(
      record: record,
      waiters: <Completer<void>>[...?pending?.waiters, completer],
    );
    _drainFuture ??= _drainMutations();
    return completer.future;
  }

  Future<void> _drainMutations() async {
    while (true) {
      final mutation = _pendingMutation;
      if (mutation == null) break;
      _pendingMutation = null;
      try {
        final record = mutation.record;
        if (record == null) {
          await _clearNow();
        } else {
          await _writeNow(record);
        }
        for (final waiter in mutation.waiters) {
          waiter.complete();
        }
      } on Object catch (error, stackTrace) {
        for (final waiter in mutation.waiters) {
          waiter.completeError(error, stackTrace);
        }
      }
    }
    _drainFuture = null;
    if (_pendingMutation != null) {
      _drainFuture = _drainMutations();
    }
  }

  bool _recordNeedsMigration(Map<String, Object?> json) {
    final needsMigration = _needsMigration;
    if (needsMigration == null) return false;
    if (needsMigration(json['baseline']) || needsMigration(json['document'])) {
      return true;
    }
    for (final field in <String>['undoEntries', 'redoEntries']) {
      final entries = json[field];
      if (entries is! List) continue;
      for (final entry in entries) {
        if (entry is Map &&
            (needsMigration(entry['before']) ||
                needsMigration(entry['after']))) {
          return true;
        }
      }
    }
    return false;
  }

  Map<String, Object?> _encodeRecord(
    NarrativeDocumentRecoveryRecord<T> record,
  ) {
    return <String, Object?>{
      'schemaVersion': record.schemaVersion,
      'documentId': record.documentId,
      'baseRevision': record.baseRevision,
      'baseline': _encodeDocument(record.baseline),
      'document': _encodeDocument(record.document),
      'undoEntries': record.undoEntries.map(_encodeEntry).toList(),
      'redoEntries': record.redoEntries.map(_encodeEntry).toList(),
    };
  }

  Map<String, Object?> _encodeEntry(NarrativeUndoEntry<T> entry) {
    return <String, Object?>{
      'operationId': entry.operationId,
      'label': entry.label,
      'before': _encodeDocument(entry.before),
      'after': _encodeDocument(entry.after),
    };
  }

  NarrativeDocumentRecoveryRecord<T> _decodeRecord(Map<String, Object?> json) {
    final schemaVersion = _integer(json['schemaVersion'], 'schemaVersion');
    if (schemaVersion != 1) {
      throw FormatException(
        'Unsupported recovery journal schemaVersion: $schemaVersion.',
      );
    }
    return NarrativeDocumentRecoveryRecord<T>(
      schemaVersion: schemaVersion,
      documentId: _text(json['documentId'], 'documentId'),
      baseRevision: _text(json['baseRevision'], 'baseRevision'),
      baseline: _decodeDocument(json['baseline']),
      document: _decodeDocument(json['document']),
      undoEntries: _decodeEntries(json['undoEntries'], 'undoEntries'),
      redoEntries: _decodeEntries(json['redoEntries'], 'redoEntries'),
    );
  }

  List<NarrativeUndoEntry<T>> _decodeEntries(Object? value, String field) {
    if (value is! List) {
      throw FormatException('$field must be a JSON list.');
    }
    return List<NarrativeUndoEntry<T>>.unmodifiable(
      value.map((item) {
        final json = _object(item, field);
        return NarrativeUndoEntry<T>(
          operationId: _text(json['operationId'], '$field.operationId'),
          label: _text(json['label'], '$field.label'),
          before: _decodeDocument(json['before']),
          after: _decodeDocument(json['after']),
        );
      }),
    );
  }
}

final class _PendingRecoveryMutation<T> {
  const _PendingRecoveryMutation({required this.record, required this.waiters});

  final NarrativeDocumentRecoveryRecord<T>? record;
  final List<Completer<void>> waiters;
}

String _requiredPath(String value) {
  final path = value.trim();
  if (path.isEmpty) {
    throw ArgumentError.value(value, 'journalPath', 'must not be empty');
  }
  return path;
}

Map<String, Object?> _object(Object? value, String field) {
  if (value is! Map) {
    throw FormatException('$field must be a JSON object.');
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw FormatException('$field contains a non-string key.');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

String _text(Object? value, String field) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$field must be a non-empty string.');
  }
  return value.trim();
}

int _integer(Object? value, String field) {
  if (value is! int) {
    throw FormatException('$field must be an integer.');
  }
  return value;
}
