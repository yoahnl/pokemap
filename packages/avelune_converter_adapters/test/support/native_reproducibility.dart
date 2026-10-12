import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:path/path.dart' as path;

const _authoringRoot = '.pokemap/authoring/';
const _volatileLogs = {
  '${_authoringRoot}idempotency.jsonl',
  '${_authoringRoot}history.jsonl',
  '${_authoringRoot}audit.jsonl',
};
const _emptyLocks = {
  '${_authoringRoot}idempotency.jsonl.lock',
  '${_authoringRoot}history.lock',
  '${_authoringRoot}audit.lock',
  '${_authoringRoot}blobs.lock',
  '${_authoringRoot}transactions/write.lock',
};

Map<String, List<int>> recoverNativeBootstrapBytes(
    Map<String, List<int>> files, List<String> operations) {
  _require(
      operations.isNotEmpty &&
          operations.length <= 2048 &&
          operations.toSet().length == operations.length,
      'Expected operations must be nonempty, unique and bounded.');
  final ledgerBytes = files['${_authoringRoot}idempotency.jsonl'];
  final historyBytes = files['${_authoringRoot}history.jsonl'];
  _require(ledgerBytes != null && historyBytes != null,
      'Bootstrap recovery requires complete retained authoring logs.');
  final creations = _jsonLines(ledgerBytes!)
      .map((event) =>
          AuthoringIdempotencyRecord.fromJson(_object(event['record'])))
      .where((record) =>
          record.scope.actionId == 'project.create' &&
          record.status == AuthoringIdempotencyStatus.completed)
      .toList();
  _require(creations.length == 1 && creations.single.receipt != null,
      'Exactly one completed bootstrap receipt is required.');
  final resources = creations.single.receipt!.affectedResources;
  final keys = resources
      .map((resource) =>
          resource.kind == 'project' ? 'project.json' : resource.id)
      .toSet();
  _require(
      keys.isNotEmpty &&
          keys.length == resources.length &&
          resources.every((resource) => resource.revision == null),
      'Bootstrap resource inventory is invalid or ambiguous.');
  final events = _jsonLines(historyBytes!);
  _verifyChain(events, 'authoring-history-event.json');
  _require(events.length == operations.length,
      'History denominator differs during bootstrap recovery.');
  final firstChanges = <String, AuthoringHistoryResourceChange>{};
  for (var index = 0; index < events.length; index++) {
    final event = events[index];
    final entry = AuthoringHistoryEntry.fromJson(
        _object(_object(event['payload'])['entry']));
    _require(
        event['sequence'] == index + 1 &&
            event['type'] == 'append' &&
            entry.operationId == operations[index],
        'History order differs during bootstrap recovery.');
    final seen = <String>{};
    for (final change in entry.changes) {
      _require(seen.add(change.storageKey), 'Duplicate history storage key.');
      for (final pair in [
        (change.beforeBlobId, change.beforeRevision),
        (change.afterBlobId, change.afterRevision)
      ]) {
        if (pair.$1 == null) continue;
        final bytes =
            files['${_authoringRoot}blobs/${pair.$1!.substring(7)}.blob'];
        _require(
            bytes != null &&
                computeAuthoringBytesFingerprint(bytes,
                        logicalName: change.storageKey) ==
                    pair.$2,
            'History resource revision differs from its retained image.');
      }
      firstChanges.putIfAbsent(change.storageKey, () => change);
    }
  }
  final bootstrap = <String, List<int>>{};
  for (final key in keys) {
    final first = firstChanges[key];
    List<int>? bytes;
    if (first == null) {
      bytes = files[key];
    } else {
      _require(first.beforeBlobId != null && first.beforeRevision != null,
          'A bootstrap resource has no retained pre-image.');
      bytes = files[
          '${_authoringRoot}blobs/${first.beforeBlobId!.substring(7)}.blob'];
    }
    _require(bytes != null, 'A bootstrap resource image is missing.');
    bootstrap[key] = List<int>.unmodifiable(bytes!);
  }
  _normaliseTree(files, operations, bootstrap);
  return Map<String, List<int>>.unmodifiable(bootstrap);
}

final class NativeReproducibilityComparison {
  const NativeReproducibilityComparison(
      {required this.left,
      required this.right,
      required this.fileCount,
      required this.canonicalFingerprint});
  final NativeStudyVerification left;
  final NativeStudyVerification right;
  final int fileCount;
  final String canonicalFingerprint;
  Map<String, Object?> toJson() => {
        'kind': 'nativeReproducibilityComparison',
        'version': 1,
        'equal': true,
        'left': left.toJson(),
        'right': right.toJson(),
        'fileCount': fileCount,
        'canonicalFingerprint': canonicalFingerprint
      };
}

Future<NativeReproducibilityComparison> compareNativeStudyDirectories(
    {required String leftProjectPath,
    required String rightProjectPath,
    required String allowedParentPath,
    required List<String> expectedOperationIds}) async {
  _require(
      path.isAbsolute(allowedParentPath) &&
          path.isAbsolute(leftProjectPath) &&
          path.isAbsolute(rightProjectPath),
      'Comparison requires absolute project paths and an explicit narrow parent.');
  final parent = await Directory(allowedParentPath).resolveSymbolicLinks();
  _require(parent != path.rootPrefix(parent),
      'A filesystem root is not a narrow parent.');
  final leftPath = await Directory(leftProjectPath).resolveSymbolicLinks();
  final rightPath = await Directory(rightProjectPath).resolveSymbolicLinks();
  _require(
      leftPath != rightPath &&
          path.isWithin(parent, leftPath) &&
          path.isWithin(parent, rightPath),
      'Comparison requires two distinct projects within the authorized parent.');
  final first = await readNativeStudyTree(leftPath);
  final second = await readNativeStudyTree(rightPath);
  final left = await const NativeStudyVerifier()
      .verify(projectPath: leftPath, allowedParentPath: parent);
  final right = await const NativeStudyVerifier()
      .verify(projectPath: rightPath, allowedParentPath: parent);
  _requireExactTree(first, await readNativeStudyTree(leftPath));
  _requireExactTree(second, await readNativeStudyTree(rightPath));
  _require(left.nativeRevision == right.nativeRevision,
      'Strict native revisions differ.');
  assertCanonicalNativeEquality(first, second, expectedOperationIds);
  final normalized = _normaliseTree(first, expectedOperationIds,
      recoverNativeBootstrapBytes(first, expectedOperationIds));
  final inventory = normalized.keys.toList()..sort();
  return NativeReproducibilityComparison(
      left: left,
      right: right,
      fileCount: first.length,
      canonicalFingerprint: computeAuthoringJsonFingerprint({
        for (final key in inventory)
          key: {
            'byteLength': normalized[key]!.length,
            'fingerprint': computeAuthoringBytesFingerprint(normalized[key]!,
                logicalName: key)
          }
      }, logicalName: 'canonical-native-study-inventory.json'));
}

void _requireExactTree(
    Map<String, List<int>> first, Map<String, List<int>> second) {
  _require(
      first.length == second.length &&
          first.entries.every((entry) =>
              second[entry.key] != null &&
              _bytesEqual(entry.value, second[entry.key]!)),
      'Native output changed during read-only comparison.');
}

void assertCanonicalNativeEquality(Map<String, List<int>> first,
    Map<String, List<int>> second, List<String> operations,
    [Map<String, List<int>>? bootstrap]) {
  final left = _normaliseTree(first, operations,
      bootstrap ?? recoverNativeBootstrapBytes(first, operations));
  final right = _normaliseTree(second, operations,
      bootstrap ?? recoverNativeBootstrapBytes(second, operations));
  _require(left.length == right.length, 'File inventory differs.');
  for (final entry in left.entries) {
    final other = right[entry.key];
    _require(other != null && _bytesEqual(entry.value, other),
        'Native file differs: ${entry.key}${other == null || !_volatileLogs.contains(entry.key) ? '' : _firstDifference(_jsonLines(entry.value), _jsonLines(other))}');
  }
}

Map<String, List<int>> _normaliseTree(Map<String, List<int>> files,
    List<String> operations, Map<String, List<int>> bootstrap) {
  _require(files.keys.toSet().containsAll({..._volatileLogs, ..._emptyLocks}),
      'Expected metadata inventory is incomplete.');
  for (final entry in files.entries) {
    if (!entry.key.startsWith(_authoringRoot)) continue;
    if (_emptyLocks.contains(entry.key)) {
      _require(entry.value.isEmpty, 'Lock contains unexpected bytes.');
    } else if (!_volatileLogs.contains(entry.key)) {
      final match = RegExp(r'^\.pokemap/authoring/blobs/([a-f0-9]{64})\.blob$')
          .firstMatch(entry.key);
      _require(match != null, 'Unlisted authoring metadata file.');
      _require(
          computeAuthoringBytesFingerprint(entry.value,
                  logicalName: 'authoring-history-blob') ==
              'sha256:${match!.group(1)}',
          'Retained blob differs from its content address.');
    }
  }
  final normaliser = _LogNormaliser(operations, bootstrap);
  final result = {...files};
  result['${_authoringRoot}idempotency.jsonl'] = _encodeLines(normaliser
      .ledger(_jsonLines(files['${_authoringRoot}idempotency.jsonl']!)));
  result['${_authoringRoot}history.jsonl'] = _encodeLines(normaliser.history(
      _jsonLines(files['${_authoringRoot}history.jsonl']!), files));
  result['${_authoringRoot}audit.jsonl'] = _encodeLines(
      normaliser.audit(_jsonLines(files['${_authoringRoot}audit.jsonl']!)));
  return result;
}

final class _LogNormaliser {
  _LogNormaliser(this.operations, this.bootstrapBytes);
  final List<String> operations;
  final Map<String, List<int>> bootstrapBytes;
  final _receipts = <String, Map<String, dynamic>>{};
  final _projects = <String, String>{};
  final _plans = <String, String>{};
  final _receiptIds = <String, String>{};
  final _requests = <String, String>{};
  final _reservationTimes = <String, DateTime>{};
  String? _bootstrap;

  List<Map<String, dynamic>> ledger(List<Map<String, dynamic>> events) {
    final pending = <String, AuthoringIdempotencyRecord>{};
    final completed = <String>[];
    final result = <Map<String, dynamic>>[];
    for (final event in events) {
      _keys(event, const {'schemaVersion', 'event', 'record'});
      _require(event['schemaVersion'] == 1 && event['event'] == 'put',
          'Unexpected idempotency event.');
      final recordJson = _object(event['record']);
      final record = AuthoringIdempotencyRecord.fromJson(recordJson);
      _sameJson(recordJson, record.toJson());
      final bootstrap = record.scope.actionId == 'project.create';
      final operation = record.operationId;
      if (bootstrap) {
        _require(RegExp(r'^creation-[0-9]+$').hasMatch(operation),
            'Unexpected bootstrap operation identity.');
        _bootstrap ??= operation;
        _require(_bootstrap == operation && record.scope.matchesKey(operation),
            'Bootstrap idempotency key is inconsistent.');
      } else {
        _require(operations.contains(operation), 'Unknown native operation.');
        _require(record.scope.matchesKey(operation),
            'Native idempotency key is inconsistent.');
      }
      final project = bootstrap ? 'bootstrap-project' : 'native-project';
      _bind(_projects, record.scope.projectId, project);
      final scope = _object(recordJson['scope']);
      scope['projectId'] = project;
      if (bootstrap) {
        recordJson['operationId'] = 'bootstrap';
        scope['keyFingerprint'] = 'bootstrap-key-fingerprint';
      }
      recordJson['createdAtUtc'] = 'valid-utc-time';
      if (record.status == AuthoringIdempotencyStatus.pending) {
        _require(!pending.containsKey(operation), 'Duplicate pending intent.');
        pending[operation] = record;
      } else {
        final intent = pending[operation];
        _require(
            intent != null &&
                intent.scope.storageKey == record.scope.storageKey &&
                intent.payloadFingerprint == record.payloadFingerprint &&
                intent.createdAt == record.createdAt &&
                record.expiresAt!.difference(record.createdAt) ==
                    const Duration(days: 30),
            'Completed intent is inconsistent.');
        _require(!completed.contains(operation), 'Duplicate completed intent.');
        completed.add(operation);
        final receipt = record.receipt!;
        _require(
            receipt.status == AuthoringReceiptStatus.applied &&
                receipt.actionId == record.scope.actionId &&
                receipt.actionVersion == record.scope.actionVersion &&
                receipt.extensions['operationId'] == operation,
            'Completed receipt is inconsistent.');
        _require(
            !DateTime.parse(receipt.createdAtUtc).isAfter(record.createdAt),
            'Frozen intended receipt follows its durable reservation.');
        _reservationTimes[operation] = record.createdAt;
        if (bootstrap) {
          _require(
              receipt.receiptId == 'receipt-$operation' &&
                  receipt.extensions['planId'] == 'plan-$operation',
              'Bootstrap creation tokens are inconsistent.');
        }
        final rawReceipt = _object(recordJson['receipt']);
        _receipts[operation] = _copy(rawReceipt);
        _bind(_requests, receipt.requestId, operation);
        _bind(_receiptIds, receipt.receiptId, '$operation:receipt');
        _bind(
            _plans, receipt.extensions['planId'] as String, '$operation:plan');
        recordJson['expiresAtUtc'] = 'valid-utc-expiry-after-30-days';
        recordJson['receipt'] = _receipt(rawReceipt, operation, bootstrap);
      }
      result.add(event);
    }
    _require(
        completed.length == operations.length + 1 &&
            completed.first == _bootstrap &&
            _sameList(completed.skip(1).toList(), operations),
        'Native operation order or denominator differs.');
    return result;
  }

  List<Map<String, dynamic>> history(
      List<Map<String, dynamic>> events, Map<String, List<int>> files) {
    _verifyChain(events, 'authoring-history-event.json');
    _require(
        events.length == operations.length, 'History denominator differs.');
    for (var index = 0; index < events.length; index++) {
      final event = events[index];
      _keys(event, const {
        'schemaVersion',
        'sequence',
        'previousDigest',
        'type',
        'payload',
        'digest'
      });
      _require(event['sequence'] == index + 1 && event['type'] == 'append',
          'Unexpected history sequence or event.');
      final payload = _object(event['payload']);
      _keys(payload, const {'entry'});
      final entryJson = _object(payload['entry']);
      final entry = AuthoringHistoryEntry.fromJson(entryJson);
      _sameJson(entryJson, entry.toJson());
      final operation = operations[index];
      _require(entry.operationId == operation, 'History operation differs.');
      _sameJson(entry.receipt.toJson(), _receipts[operation]!);
      _require(entry.committedAt == DateTime.parse(entry.receipt.createdAtUtc),
          'History timestamp differs from its frozen receipt.');
      _require(
          _plans[entry.planId] == '$operation:plan' &&
              _receiptIds[entry.entryId] == '$operation:receipt' &&
              _projects[entry.projectId] == 'native-project',
          'History token relation differs.');
      for (final change in entry.changes) {
        for (final blobId in [change.beforeBlobId, change.afterBlobId]) {
          if (blobId == null) continue;
          _require(
              files.containsKey(
                  '${_authoringRoot}blobs/${blobId.substring(7)}.blob'),
              'History references a missing retained blob.');
        }
      }
      entryJson['entryId'] = '$operation:receipt';
      entryJson['projectId'] = 'native-project';
      entryJson['planId'] = '$operation:plan';
      entryJson['committedAtUtc'] = 'valid-utc-time';
      entryJson['receipt'] =
          _receipt(_object(entryJson['receipt']), operation, false);
    }
    _rehashChain(events, 'authoring-history-event.json');
    return events;
  }

  List<Map<String, dynamic>> audit(List<Map<String, dynamic>> events) {
    _verifyChain(events, 'authoring-audit-event.json');
    _require(events.length == operations.length, 'Audit denominator differs.');
    final auditIds = <String>{};
    for (var index = 0; index < events.length; index++) {
      final event = events[index];
      _keys(
          event, const {'schemaVersion', 'previousDigest', 'record', 'digest'});
      final recordJson = _object(event['record']);
      final record = AuthoringAuditRecord.fromJson(recordJson);
      _sameJson(recordJson, record.toJson());
      final operation = operations[index];
      final receipt = _receipts[operation]!;
      _require(
          auditIds.add(record.auditId) &&
              record.decision == AuthoringAuditDecision.succeeded &&
              _requests[record.requestId] == operation &&
              record.actionId == receipt['actionId'] &&
              record.actionVersion == receipt['actionVersion'] &&
              _projects[record.projectId] == 'native-project' &&
              _plans[record.planId] == '$operation:plan',
          'Audit token relation differs.');
      _require(!record.timestamp.isBefore(_reservationTimes[operation]!),
          'Audit success predates its durable reservation.');
      _require(record.operation.wireName == 'apply',
          'Audit operation order differs.');
      if (record.receiptId != null) {
        _require(_receiptIds[record.receiptId] == '$operation:receipt',
            'Audit receipt relation differs.');
        recordJson['receiptId'] = '$operation:receipt';
      }
      recordJson['auditId'] = '$operation:audit';
      recordJson['projectId'] = 'native-project';
      recordJson['planId'] = '$operation:plan';
      recordJson['timestampUtc'] = 'valid-utc-time';
    }
    _rehashChain(events, 'authoring-audit-event.json');
    return events;
  }

  Map<String, dynamic> _receipt(
      Map<String, dynamic> receipt, String operation, bool bootstrap) {
    receipt['receiptId'] =
        bootstrap ? 'bootstrap-receipt' : '$operation:receipt';
    receipt['createdAtUtc'] = 'valid-utc-time';
    final extensions = _object(receipt['extensions']);
    extensions['planId'] = bootstrap ? 'bootstrap-plan' : '$operation:plan';
    if (bootstrap) {
      _bootstrapRevisions(receipt);
      receipt['requestId'] = 'bootstrap-request';
      extensions['operationId'] = 'bootstrap';
      final resources = receipt['affectedResources'] as List;
      for (final raw in resources) {
        _bootstrapResource(_object(raw));
      }
      for (final raw in (_object(receipt['diff'])['entries'] as List)) {
        _bootstrapResource(_object(_object(raw)['resource']));
      }
    }
    return receipt;
  }

  void _bootstrapRevisions(Map<String, dynamic> receipt) {
    final resources = (receipt['affectedResources'] as List)
        .map((raw) => AuthoringResourceRef.fromJson(_object(raw)))
        .toList(growable: false);
    _require(resources.every((resource) => resource.revision == null),
        'Bootstrap resource unexpectedly contains a pre-image revision.');
    final keys = {
      for (final resource in resources)
        resource.kind == 'project' ? 'project.json' : resource.id
    };
    _require(
        keys.length == bootstrapBytes.length &&
            keys.containsAll(bootstrapBytes.keys),
        'Bootstrap resources do not match the original bootstrap bytes.');
    AuthoringRevisionSet revisions(
            {required bool after, required bool normalise}) =>
        AuthoringRevisionSet([
          for (final resource in resources)
            AuthoringResourceRevision(
              resource: AuthoringResourceRef(
                  kind: resource.kind,
                  id: normalise && resource.kind == 'project'
                      ? 'bootstrap-project'
                      : resource.id,
                  extensions: resource.extensions),
              revision: after
                  ? computeAuthoringBytesFingerprint(
                      bootstrapBytes[resource.kind == 'project'
                          ? 'project.json'
                          : resource.id]!,
                      logicalName: resource.kind == 'project'
                          ? 'project.json'
                          : resource.id)
                  : null,
            )
        ]);
    _require(
        receipt['beforeRevision'] ==
                revisions(after: false, normalise: false).fingerprint &&
            receipt['afterRevision'] ==
                revisions(after: true, normalise: false).fingerprint,
        'Bootstrap revision does not match its original resource bytes.');
    receipt['beforeRevision'] =
        revisions(after: false, normalise: true).fingerprint;
    receipt['afterRevision'] =
        revisions(after: true, normalise: true).fingerprint;
  }

  void _bootstrapResource(Map<String, dynamic> resource) {
    if (resource['kind'] != 'project') return;
    _require(_projects[resource['id']] == 'bootstrap-project',
        'Bootstrap resource handle differs.');
    resource['id'] = 'bootstrap-project';
  }
}

void _bind(Map<String, String> values, String actual, String stable) {
  _require(
      (values[actual] == null || values[actual] == stable) &&
          !values.entries
              .any((entry) => entry.key != actual && entry.value == stable),
      'Volatile identity is not bijective.');
  values[actual] = stable;
}

void _verifyChain(List<Map<String, dynamic>> events, String logicalName) {
  String? previous;
  for (final event in events) {
    _require(event['previousDigest'] == previous, 'Original chain is broken.');
    final payload = {...event}..remove('digest');
    _require(
        event['digest'] ==
            computeAuthoringJsonFingerprint(payload, logicalName: logicalName),
        'Original event digest is invalid.');
    previous = event['digest'] as String;
  }
}

void _rehashChain(List<Map<String, dynamic>> events, String logicalName) {
  String? previous;
  for (final event in events) {
    event['previousDigest'] = previous;
    final payload = {...event}..remove('digest');
    event['digest'] =
        computeAuthoringJsonFingerprint(payload, logicalName: logicalName);
    previous = event['digest'] as String;
  }
}

List<Map<String, dynamic>> _jsonLines(List<int> bytes) {
  final content = utf8.decode(bytes);
  _require(content.endsWith('\n'), 'Log is not completely flushed.');
  return content
      .substring(0, content.length - 1)
      .split('\n')
      .map((line) => _object(jsonDecode(line)))
      .toList(growable: false);
}

List<int> _encodeLines(List<Map<String, dynamic>> events) =>
    utf8.encode('${events.map(canonicalAuthoringJson).join('\n')}\n');

Map<String, dynamic> _object(Object? value) {
  _require(value is Map<String, dynamic>, 'Expected a JSON object.');
  return value as Map<String, dynamic>;
}

Map<String, dynamic> _copy(Map<String, dynamic> value) =>
    _object(jsonDecode(jsonEncode(value)));

void _keys(Map<String, dynamic> value, Set<String> keys) => _require(
    value.keys.toSet().length == keys.length &&
        value.keys.toSet().containsAll(keys),
    'Unexpected log schema.');

void _sameJson(Object? first, Object? second) => _require(
    canonicalAuthoringJson(first) == canonicalAuthoringJson(second),
    'Typed log round trip or receipt relation differs.');

bool _sameList(List<String> first, List<String> second) =>
    first.length == second.length &&
    Iterable<int>.generate(first.length).every((i) => first[i] == second[i]);

bool _bytesEqual(List<int> first, List<int> second) =>
    first.length == second.length &&
    Iterable<int>.generate(first.length).every((i) => first[i] == second[i]);

void _require(bool condition, String message) {
  if (!condition) throw FormatException(message);
}

Future<Map<String, List<int>>> readNativeStudyTree(String root) async {
  final result = <String, List<int>>{};
  var total = 0;
  await for (final entry
      in Directory(root).list(recursive: true, followLinks: false)) {
    _require(entry is File || entry is Directory, 'Unexpected tree entry.');
    if (entry is File) {
      final before = await entry.stat();
      _require(
          before.type == FileSystemEntityType.file &&
              before.size <= 67108864 &&
              result.length < 8192,
          'Comparison file inventory exceeds its bounded scope.');
      total += before.size;
      _require(total <= 1073741824, 'Comparison byte budget exceeded.');
      final bytes = await entry.readAsBytes();
      final after = await entry.stat();
      _require(
          before.type == after.type &&
              before.size == after.size &&
              before.modified == after.modified &&
              bytes.length == before.size &&
              await FileSystemEntity.type(entry.path, followLinks: false) ==
                  FileSystemEntityType.file,
          'Comparison resource changed while it was read.');
      result[entry.path.substring(root.length + 1)] = bytes;
    }
  }
  return result;
}

String _firstDifference(Object? left, Object? right, [String locator = r'$']) {
  if (left is Map && right is Map) {
    for (final key in {...left.keys, ...right.keys}) {
      final found = _firstDifference(left[key], right[key], '$locator.$key');
      if (found.isNotEmpty) return found;
    }
  } else if (left is List && right is List && left.length == right.length) {
    for (var i = 0; i < left.length; i++) {
      final found = _firstDifference(left[i], right[i], '$locator[$i]');
      if (found.isNotEmpty) return found;
    }
  } else if (canonicalAuthoringJson(left) != canonicalAuthoringJson(right)) {
    return ' at $locator: $left != $right';
  }
  return '';
}
