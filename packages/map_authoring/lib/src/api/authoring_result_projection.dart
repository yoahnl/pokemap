import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import '../contracts/authoring_receipt.dart';
import '../history/history_store.dart';
import '../ports/file_backed_payload_store.dart';
import '../security/resource_pack_bulk_capability.dart';
import '../transactions/authoring_payload.dart';
import '../transactions/authoring_plan.dart';
import '../workspace/workspace_handle_store.dart';

const authoringProjectionMaxBytes = 256 * 1024;
const authoringProjectionMaxRows = 200;
const authoringProjectionMaxChunkBytes = 128 * 1024;

final class AuthoringProjectionException implements Exception {
  const AuthoringProjectionException(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => 'AuthoringProjectionException($code): $message';
}

final class AuthoringProjectionChunk {
  AuthoringProjectionChunk(
      {required List<int> bytes,
      required this.offset,
      required this.totalBytes})
      : bytes = Uint8List.fromList(bytes).asUnmodifiableView();
  final Uint8List bytes;
  final int offset;
  final int totalBytes;
  int get nextOffset => offset + bytes.length;
  bool get complete => nextOffset == totalBytes;
  Map<String, Object?> toJson() => {
        'bytesBase64': base64Encode(bytes),
        'offset': offset,
        'nextOffset': nextOffset,
        'totalBytes': totalBytes,
        'complete': complete
      };
}

abstract interface class AuthoringResultProjectionPort {
  Future<Map<String, Object?>> reprojectMutationReceipt(
      ProjectHandle projectHandle,
      {required String receiptId});
  Future<Map<String, Object?>> readMutationDiffPage(ProjectHandle projectHandle,
      {required String diffRef,
      String? cursor,
      int limit = authoringProjectionMaxRows});
  Future<AuthoringProjectionChunk> readMutationPayloadChunk(
      ProjectHandle projectHandle,
      {required String payloadRef,
      required int offset,
      int byteLength = authoringProjectionMaxChunkBytes});
}

final class AuthoringResultProjectionStore {
  AuthoringResultProjectionStore(
      {required FileBackedPayloadStore store,
      required this.scope,
      String Function()? tokenFactory})
      : _store = store,
        _tokenFactory = tokenFactory ?? _projectionToken;
  final FileBackedPayloadStore _store;
  final FileBackedPayloadScope scope;
  final String Function() _tokenFactory;
  final Map<String, FileBackedPayloadLease> _leases = {};
  final Map<String, _PayloadProjection> _payloads = {};
  final Map<String, _DiffProjection> _diffs = {};
  final Map<String, (String, int)> _cursors = {};
  bool _disposed = false;
  Future<void> _preparing = Future.value();

  Future<Map<String, Object?>> preparePlan(
          {required AuthoringPlan plan,
          required AuthoringReceipt receipt,
          required String snapshotRevision}) =>
      _prepare(() async {
        final full = {
          'planId': plan.planId,
          'applicable': plan.applicable,
          if (plan.nonApplicableReason != null)
            'nonApplicableReason': plan.nonApplicableReason,
          'snapshotRevision': snapshotRevision,
          'plan': plan.toJson(),
          'receipt': receipt.toJson()
        };
        if (authoringProjectionFits(full)) return full;
        final receiptProjection = await _receipt(receipt);
        final summary = {...plan.toJson()};
        summary['changeSet'] = {
          'changeCount': plan.changeSet.changes.length,
          'inventoryRef': await _stageJson(
              [for (final change in plan.changeSet.changes) change.toJson()]),
          'diff': receiptProjection['diff'],
          'projectedRevision': plan.projectedRevision
        };
        summary['preview'] = await _boundedValue(plan.preview);
        summary['referenceImpact'] = await _boundedValue(plan.referenceImpact);
        summary['artifacts'] = await _boundedValue(
            [for (final artifact in plan.artifacts) artifact.toJson()]);
        return _requireBounded({
          ...full,
          'planId': await _boundedValue(plan.planId),
          'snapshotRevision': await _boundedValue(snapshotRevision),
          'plan': await _boundedObject(summary),
          'receipt': receiptProjection
        });
      });

  Future<Map<String, Object?>> prepareMutation(
          {required AuthoringReceipt receipt,
          required String? snapshotRevision,
          Map<String, Object?>? diagnostic}) =>
      _prepare(() async {
        final full = {
          'receipt': receipt.toJson(),
          'snapshotRevision': snapshotRevision,
          if (diagnostic != null) 'diagnostic': diagnostic
        };
        if (authoringProjectionFits(full)) return full;
        return _requireBounded({
          ...full,
          'snapshotRevision': await _boundedValue(snapshotRevision),
          if (diagnostic != null) 'diagnostic': await _boundedValue(diagnostic),
          'receipt': await _receipt(receipt)
        });
      });

  Future<Map<String, Object?>> prepareCommittedMutation(
      {required AuthoringReceipt receipt,
      required String? snapshotRevision,
      Map<String, Object?>? diagnostic}) async {
    try {
      return await prepareMutation(
          receipt: receipt,
          snapshotRevision: snapshotRevision,
          diagnostic: diagnostic);
    } on Object {
      return compactUnavailableMutationResult(
          receipt: receipt,
          snapshotRevision: snapshotRevision,
          diagnostic: diagnostic);
    }
  }

  Future<Map<String, Object?>> prepareHistory(AuthoringHistoryPage page) =>
      _prepare(() async {
        final full = {
          'entries': [for (final entry in page.entries) entry.toJson()],
          if (page.nextCursor != null) 'nextCursor': page.nextCursor!.wireValue
        };
        if (authoringProjectionFits(full)) return full;
        final entries = <Map<String, Object?>>[];
        for (final entry in page.entries) {
          entries.add({
            'entryId': entry.entryId,
            'projectId': entry.projectId,
            'actorId': entry.actorId,
            'planId': entry.planId,
            'operationId': entry.operationId,
            'kind': entry.kind.wireName,
            if (entry.targetEntryId != null)
              'targetEntryId': entry.targetEntryId,
            'committedAtUtc': entry.committedAt.toIso8601String(),
            'receipt': await _receipt(entry.receipt),
            'changes': await _stageJson(
                [for (final change in entry.changes) change.toJson()]),
            if (entry.nonUndoableReason != null)
              'nonUndoableReason': entry.nonUndoableReason
          });
        }
        var projected = {...full, 'entries': entries};
        if (!authoringProjectionFits(projected)) {
          projected = {
            ...full,
            'entries': [for (final entry in entries) await _stageJson(entry)]
          };
        }
        return _requireBounded(projected);
      });

  Future<Map<String, Object?>> _receipt(AuthoringReceipt receipt) async {
    final diff = await _prepareDiff(receipt);
    final full = {...receipt.toJson(), 'diff': diff};
    full['affectedResources'] = {'count': receipt.affectedResources.length};
    full['artifacts'] = await _boundedValue(
        [for (final artifact in receipt.artifacts) artifact.toJson()]);
    full['extensions'] = await _boundedValue(receipt.extensions);
    return _requireBounded(await _boundedObject(full));
  }

  Future<Map<String, Object?>> _prepareDiff(AuthoringReceipt receipt) async {
    final directory =
        await Directory.systemTemp.createTemp('authoring-diff-projection-');
    final file = File('${directory.path}${Platform.pathSeparator}rows');
    final offsets = <(int, int)>[];
    var length = 0;
    try {
      final writer = await file.open(mode: FileMode.write);
      try {
        for (final entry in receipt.diff.entries) {
          final row = {...entry.toJson()};
          final header = {...row}
            ..remove('before')
            ..remove('after');
          Object projected;
          if (!authoringProjectionFits(header, maxBytes: 44 * 1024)) {
            projected = await _stageJson(entry.toJson());
          } else {
            if (entry.hasBefore) {
              row['before'] = await _boundedValue(entry.before);
            }
            if (entry.hasAfter) {
              row['after'] = await _boundedValue(entry.after);
            }
            projected = row;
          }
          final bytes = utf8.encode(jsonEncode(projected));
          offsets.add((length, bytes.length));
          length += bytes.length;
          await writer.writeFrom(bytes);
        }
        await writer.flush();
      } finally {
        await writer.close();
      }
      final lease = await _store.stage(
          scope: scope,
          chunks: file.openRead().transform(_boundedChunks()),
          byteLength: length);
      _leases[lease.payload.handle] = lease;
      final ref = _newToken('diff_');
      final fingerprint = bulkDiffFingerprint(receipt.diff);
      _diffs[ref] = _DiffProjection(
          lease.payload.handle, List.unmodifiable(offsets), fingerprint);
      return {
        'diffRef': ref,
        'entryCount': offsets.length,
        'affectedResourceCount': receipt.affectedResources.length,
        'fullDiffFingerprint': fingerprint
      };
    } finally {
      await directory.delete(recursive: true);
    }
  }

  Future<Map<String, Object?>> _boundedObject(
          Map<String, Object?> value) async =>
      {
        for (final entry in value.entries)
          entry.key: await _boundedValue(entry.value)
      };

  Future<Object?> _boundedValue(Object? value) async =>
      authoringProjectionFits(value, maxBytes: 8 * 1024)
          ? value
          : await _stageJson(value);

  Future<Map<String, Object?>> _stageJson(Object? value) async {
    final length = projectionJsonChunks(value)
        .fold<int>(0, (total, chunk) => total + chunk.length);
    final segments = <StoredFilePayload>[];
    Stream<List<int>> stagedChunks() async* {
      var buffer = Uint8List(authoringProjectionMaxChunkBytes);
      var filled = 0;
      for (final chunk in projectionJsonChunks(value)) {
        var offset = 0;
        while (offset < chunk.length) {
          final copied = min(buffer.length - filled, chunk.length - offset);
          buffer.setRange(filled, filled + copied, chunk, offset);
          filled += copied;
          offset += copied;
          if (filled == buffer.length) {
            final lease = await _store.stage(
                scope: scope,
                chunks: Stream.value(buffer),
                byteLength: buffer.length);
            _leases[lease.payload.handle] = lease;
            segments.add(lease.payload);
            yield buffer;
            buffer = Uint8List(authoringProjectionMaxChunkBytes);
            filled = 0;
          }
        }
      }
      if (filled > 0) {
        final tail = Uint8List.sublistView(buffer, 0, filled);
        final lease = await _store.stage(
            scope: scope, chunks: Stream.value(tail), byteLength: tail.length);
        _leases[lease.payload.handle] = lease;
        segments.add(lease.payload);
        yield tail;
      }
    }

    final inspection = await inspectAuthoringPayload(stagedChunks(),
        storageKey: 'authoring-projection.json', byteLength: length);
    final ref = _newToken('payload_');
    _payloads[ref] = _PayloadProjection(List.unmodifiable(segments), length);
    return {
      'projectionType': 'jsonPayload',
      'payloadRef': ref,
      'rawSha256': inspection.rawSha256,
      'resourceRevision': inspection.resourceRevision,
      'byteLength': length
    };
  }

  Future<Map<String, Object?>> readDiffPage(
      {required String diffRef,
      String? cursor,
      int limit = authoringProjectionMaxRows}) async {
    _checkOpen();
    if (limit < 1 || limit > authoringProjectionMaxRows) {
      throw ArgumentError.value(limit, 'limit');
    }
    final diff = _diffs[diffRef];
    if (diff == null) _unavailable();
    var start = 0;
    if (cursor != null) {
      final position = _cursors[cursor];
      if (position == null || position.$1 != diffRef) _unavailable();
      start = position.$2;
    }
    final rows = <Object?>[];
    var index = start;
    await _store.withSource(
        scope: scope,
        handle: diff.handle,
        read: (source) async {
          while (index < diff.offsets.length && rows.length < limit) {
            final offset = diff.offsets[index];
            final row = jsonDecode(
                utf8.decode(source.readAtSync(offset.$1, offset.$2)));
            final candidate = {
              'diffRef': diffRef,
              'fullDiffFingerprint': diff.fingerprint,
              'totalRows': diff.offsets.length,
              'startIndex': start,
              'entries': [...rows, row],
              'nextCursor': List.filled(96, 'x').join()
            };
            if (!authoringProjectionFits(candidate)) break;
            rows.add(row);
            index++;
          }
        });
    if (index == start && index < diff.offsets.length) {
      throw const AuthoringProjectionException('projection.row_unavailable',
          'The projected row exceeds its page budget.');
    }
    final next = index < diff.offsets.length
        ? diff.cursors.putIfAbsent(index, () {
            final token = _newToken('cursor_');
            _cursors[token] = (diffRef, index);
            return token;
          })
        : null;
    return _requireBounded({
      'diffRef': diffRef,
      'fullDiffFingerprint': diff.fingerprint,
      'totalRows': diff.offsets.length,
      'startIndex': start,
      'entries': rows,
      if (next != null) 'nextCursor': next
    });
  }

  Future<AuthoringProjectionChunk> readPayloadChunk(
      {required String payloadRef,
      required int offset,
      int byteLength = authoringProjectionMaxChunkBytes}) async {
    _checkOpen();
    if (offset < 0 ||
        byteLength < 1 ||
        byteLength > authoringProjectionMaxChunkBytes) {
      throw ArgumentError('Projection chunk bounds are invalid.');
    }
    final payload = _payloads[payloadRef];
    if (payload == null) _unavailable();
    final total = payload.byteLength;
    if (offset > total) throw ArgumentError.value(offset, 'offset');
    final builder = BytesBuilder(copy: false);
    var position = offset;
    final end = min(offset + byteLength, total);
    while (position < end) {
      final index = position ~/ authoringProjectionMaxChunkBytes;
      final segment = payload.segments[index];
      final localOffset = position % authoringProjectionMaxChunkBytes;
      final count = min(end - position, segment.byteLength - localOffset);
      builder.add(await _store.withSource(
          scope: scope,
          handle: segment.handle,
          read: (source) => source.readAtSync(localOffset, count)));
      position += count;
    }
    return AuthoringProjectionChunk(
        bytes: builder.takeBytes(), offset: offset, totalBytes: total);
  }

  Future<T> _prepare<T>(Future<T> Function() build) async {
    _checkOpen();
    final previous = _preparing;
    final completion = Completer<void>();
    _preparing = completion.future;
    await previous;
    final existing = _leases.keys.toSet();
    final existingPayloads = _payloads.keys.toSet();
    final existingDiffs = _diffs.keys.toSet();
    try {
      _checkOpen();
      return await build();
    } on Object catch (error, stack) {
      final staged =
          _leases.keys.where((key) => !existing.contains(key)).toList();
      _diffs.removeWhere((key, value) => !existingDiffs.contains(key));
      _payloads.removeWhere((key, value) => !existingPayloads.contains(key));
      await _releaseLeases(staged);
      Error.throwWithStackTrace(error, stack);
    } finally {
      completion.complete();
    }
  }

  Future<void> _releaseLeases(Iterable<String> handles) async {
    await Future.wait([
      for (final handle in handles)
        () async {
          final lease = _leases[handle];
          if (lease == null) return;
          try {
            await _store.release(scope: scope, leaseId: lease.leaseId);
            _leases.remove(handle);
          } on Object {
            return;
          }
        }()
    ]);
  }

  Future<void> dispose() async {
    _disposed = true;
    await _preparing;
    _payloads.clear();
    _diffs.clear();
    _cursors.clear();
    await _releaseLeases(_leases.keys.toList());
    if (_leases.isNotEmpty) {
      throw const AuthoringProjectionException('projection.cleanup_failed',
          'The projection owner could not release all of its staged segments.');
    }
  }

  String _newToken(String prefix) {
    final token = '$prefix${_tokenFactory()}';
    if (token.length > 80 ||
        !RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(token) ||
        _diffs.containsKey(token) ||
        _cursors.containsKey(token) ||
        _payloads.containsKey(token)) {
      throw StateError(
          'The projection token factory must issue unique safe tokens.');
    }
    return token;
  }

  void _checkOpen() {
    if (_disposed) _unavailable();
  }
}

final class _PayloadProjection {
  const _PayloadProjection(this.segments, this.byteLength);
  final List<StoredFilePayload> segments;
  final int byteLength;
}

final class _DiffProjection {
  _DiffProjection(this.handle, this.offsets, this.fingerprint);
  final String handle;
  final List<(int, int)> offsets;
  final String fingerprint;
  final Map<int, String> cursors = {};
}

Never _unavailable() => throw const AuthoringProjectionException(
    'projection.reference_unavailable',
    'The projection reference is unavailable in this session and project.');

Map<String, Object?> _requireBounded(Map<String, Object?> json) {
  if (!authoringProjectionFits(json)) {
    throw const AuthoringProjectionException('projection.response_too_large',
        'The projected response exceeds its byte budget.');
  }
  return Map.unmodifiable(json);
}

const projectionUnavailableDiagnostic = {
  'code': 'projection.unavailable',
  'message':
      'The mutation result is retained. Reload its canonical receipt to prepare a new projection.'
};

Map<String, Object?> compactAuthoringReceiptSummary(AuthoringReceipt receipt) {
  final summary = <String, Object?>{
    'receiptId': receipt.receiptId,
    'requestId': receipt.requestId,
    'actionId': receipt.actionId,
    'actionVersion': receipt.actionVersion,
    'status': receipt.status.wireName,
    'beforeRevision': receipt.beforeRevision,
    'afterRevision': receipt.afterRevision,
    'createdAtUtc': receipt.createdAtUtc,
    'planId': receipt.extensions['planId'],
    'operationId': receipt.extensions['operationId'],
    'diff': {
      'entryCount': receipt.diff.entries.length,
      'affectedResourceCount': receipt.affectedResources.length,
      'fullDiffFingerprint': bulkDiffFingerprint(receipt.diff)
    },
  };
  return _requireBounded({
    for (final entry in summary.entries)
      entry.key: boundedAuthoringSummaryValue(entry.value)
  });
}

Object? boundedAuthoringSummaryValue(Object? value) {
  if (authoringProjectionFits(value, maxBytes: 1024)) return value;
  return {
    'projectionType': 'unavailable',
    'byteLength': projectionJsonChunks(value)
        .fold<int>(0, (total, chunk) => total + chunk.length),
    'code': 'projection.unavailable'
  };
}

Map<String, Object?> compactUnavailableMutationResult(
        {required AuthoringReceipt receipt,
        required String? snapshotRevision,
        Map<String, Object?>? diagnostic}) =>
    _requireBounded({
      'receipt': compactAuthoringReceiptSummary(receipt),
      'snapshotRevision': boundedAuthoringSummaryValue(snapshotRevision),
      if (diagnostic != null)
        'diagnostic': boundedAuthoringSummaryValue(diagnostic),
      'projectionDiagnostic': projectionUnavailableDiagnostic,
    });

Map<String, Object?> compactUnavailablePlanResult(
        {required AuthoringPlan plan,
        required AuthoringReceipt receipt,
        required String snapshotRevision}) =>
    _requireBounded({
      'planId': boundedAuthoringSummaryValue(plan.planId),
      'applicable': plan.applicable,
      'snapshotRevision': boundedAuthoringSummaryValue(snapshotRevision),
      'changeCount': plan.changeSet.changes.length,
      'receipt': compactAuthoringReceiptSummary(receipt),
      'projectionDiagnostic': projectionUnavailableDiagnostic,
    });

Map<String, Object?> compactUnavailableHistoryResult(
    AuthoringHistoryPage page) {
  final summary = <String, Object?>{
    'entries': [
      for (final entry in page.entries)
        {
          'entryId': entry.entryId,
          'planId': entry.planId,
          'operationId': entry.operationId,
          'kind': entry.kind.wireName,
          'changeCount': entry.changes.length,
          'receipt': compactAuthoringReceiptSummary(entry.receipt)
        }
    ],
    'entryCount': page.entries.length,
    if (page.nextCursor != null)
      'nextCursor': boundedAuthoringSummaryValue(page.nextCursor!.wireValue),
    'projectionDiagnostic': projectionUnavailableDiagnostic
  };
  if (authoringProjectionFits(summary)) return _requireBounded(summary);
  final references = [
    for (final entry in page.entries)
      <String, Object?>{
        'entryId': entry.entryId,
        'projectId': entry.projectId,
        'planId': entry.planId,
        'operationId': entry.operationId,
        'kind': entry.kind.wireName,
        'changeCount': entry.changes.length,
        'status': entry.receipt.status.wireName
      }
  ];
  final minimal = {...summary, 'entries': references};
  if (authoringProjectionFits(minimal)) return _requireBounded(minimal);
  return _requireBounded({
    ...summary,
    'entries': const [],
    'entriesUnavailable': true,
    if (references.isNotEmpty) 'firstEntry': references.first,
    if (references.isNotEmpty) 'lastEntry': references.last
  });
}

bool authoringProjectionFits(Object? value,
    {int maxBytes = authoringProjectionMaxBytes}) {
  var length = 0;
  for (final chunk in projectionJsonChunks(value)) {
    length += chunk.length;
    if (length > maxBytes) return false;
  }
  return true;
}

Iterable<List<int>> projectionJsonChunks(Object? value) sync* {
  if (value is String) {
    yield const [34];
    var offset = 0;
    while (offset < value.length) {
      var end = min(offset + 4096, value.length);
      if (end < value.length &&
          value.codeUnitAt(end - 1) >= 0xd800 &&
          value.codeUnitAt(end - 1) <= 0xdbff) {
        end--;
      }
      final escaped = jsonEncode(value.substring(offset, end));
      yield utf8.encode(escaped.substring(1, escaped.length - 1));
      offset = end;
    }
    yield const [34];
  } else if (value is List) {
    yield const [91];
    for (var i = 0; i < value.length; i++) {
      if (i > 0) yield const [44];
      yield* projectionJsonChunks(value[i]);
    }
    yield const [93];
  } else if (value is Map) {
    yield const [123];
    var index = 0;
    for (final entry in value.entries) {
      if (index++ > 0) yield const [44];
      yield* projectionJsonChunks(entry.key as String);
      yield const [58];
      yield* projectionJsonChunks(entry.value);
    }
    yield const [125];
  } else {
    yield utf8.encode(jsonEncode(value));
  }
}

StreamTransformer<List<int>, List<int>> _boundedChunks() =>
    StreamTransformer.fromHandlers(handleData: (chunk, sink) {
      for (var offset = 0;
          offset < chunk.length;
          offset += authoringProjectionMaxChunkBytes) {
        sink.add(chunk.sublist(offset,
            min(offset + authoringProjectionMaxChunkBytes, chunk.length)));
      }
    });

String _projectionToken() {
  final random = Random.secure();
  return base64Url
      .encode(List.generate(24, (_) => random.nextInt(256)))
      .replaceAll('=', '');
}
