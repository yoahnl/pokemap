import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';
import 'support/native_writer_fixture.dart';

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

void main() {
  test('PUB-04 identical approved conversion writes identical native data',
      () async {
    final root = await Directory.systemTemp.createTemp('ac15-pub04-original-');
    try {
      final output = await Directory('${root.path}/output').create();
      final source = await LiteralTileFixture.create(
          sourceRootPath: '${root.path}/source',
          maps: [LiteralFixtureMap(id: 1), LiteralFixtureMap(id: 8)]);
      final sourceBefore = await _treeBytes(source.sourceRootPath!);
      final composition = await const LiteralTileComposer().compose(
          source: source.source,
          files: source.files,
          selectedSourceMapIds: const [1, 8],
          projectName: 'Original reproducible native study',
          parentPath: output.path,
          folderName: 'original-pub04-study',
          sourceRootPath: source.sourceRootPath);
      expect(composition.canWrite, isTrue);
      final draft = composition.draft!;
      final approved = approveNativeFixtureDraft(draft);
      final inputHashes = [
        draft.canonicalHash,
        approved.plan.canonicalHash,
        approved.context.sourceSnapshotHash,
        approved.context.targetCapabilities.canonicalHash,
        approved.context.decisions.canonicalHash,
      ];
      final bootstrapBytes = <Map<String, List<int>>>[];
      final writer =
          NativeProjectWriter(checkpoint: (stage, _, projectPath) async {
        if (stage == NativeWriteStage.afterBootstrap) {
          final files = await _treeBytes(projectPath!);
          bootstrapBytes.add({
            for (final entry in files.entries)
              if (!entry.key.startsWith(_authoringRoot)) entry.key: entry.value
          });
        }
      });
      final first = await writer.write(approved.plan, approved.context, draft);
      final second = await writer.write(approved.plan, approved.context, draft);
      expect(bootstrapBytes, hasLength(2));
      expect(bootstrapBytes.first, bootstrapBytes.last);
      expect(first.stagingRoot, isNot(second.stagingRoot));
      expect(first.projectPath, isNot(second.projectPath));
      expect(first.draftHash, second.draftHash);
      expect(first.nativeRevision, second.nativeRevision);
      expect(first.mapHashes, second.mapHashes);
      expect(first.assetHashes, second.assetHashes);
      expect(first.published, isFalse);
      expect(second.published, isFalse);
      expect(await Directory('${output.path}/${draft.folderName}').exists(),
          isFalse);
      final firstBytes = await _treeBytes(first.projectPath);
      final secondBytes = await _treeBytes(second.projectPath);
      final expectedOperations = draft.mutations
          .map((mutation) => mutation.operationId.value)
          .toList(growable: false);
      _assertReproducible(
          firstBytes, secondBytes, expectedOperations, bootstrapBytes.first);
      expect(firstBytes.keys, unorderedEquals(secondBytes.keys));
      expect(firstBytes.length, secondBytes.length);
      expect(
          firstBytes.keys.where((name) =>
              name.startsWith('${_authoringRoot}blobs/') &&
              name.endsWith('.blob')),
          isNotEmpty);
      for (final receipt in [first, second]) {
        const reader = LocalProjectFileReader();
        final policy = await WorkspacePolicy.create(
            allowedRootPaths: [receipt.stagingRoot], fileReader: reader);
        final handles = WorkspaceHandleStore();
        final opener = ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles);
        final opened = await opener.openProject(receipt.projectPath);
        try {
          final native = await ProjectSnapshotLoader(handles: handles).load(
              opened.projectHandle,
              policy: ProjectSnapshotLoadPolicy.strict);
          expect(native.revision, receipt.nativeRevision);
          expect(native.loadDiagnostics, isEmpty);
          for (final map in composition.nativeMaps.values) {
            expect(native.mapById(map.id), map);
          }
        } finally {
          opener.closeWorkspace(opened.workspaceHandle);
        }
      }
      final changedNative = {...secondBytes};
      changedNative['project.json'] = [...secondBytes['project.json']!, 32];
      expect(
          () => _assertReproducible(firstBytes, changedNative,
              expectedOperations, bootstrapBytes.first),
          throwsFormatException);
      final blob = secondBytes.keys
          .firstWhere((name) => name.startsWith('${_authoringRoot}blobs/'));
      final changedBlob = {...secondBytes};
      changedBlob[blob] = [...secondBytes[blob]!, 0];
      expect(
          () => _assertReproducible(firstBytes, changedBlob, expectedOperations,
              bootstrapBytes.first),
          throwsFormatException);
      final unexpectedMetadata = {...secondBytes};
      unexpectedMetadata['${_authoringRoot}unlisted.log'] = const [1];
      expect(
          () => _assertReproducible(firstBytes, unexpectedMetadata,
              expectedOperations, bootstrapBytes.first),
          throwsFormatException);
      final changedBootstrapReceipt = {...secondBytes};
      final ledger =
          _jsonLines(secondBytes['${_authoringRoot}idempotency.jsonl']!);
      final bootstrapReceipt = _object(_object(ledger[1]['record'])['receipt']);
      bootstrapReceipt['afterRevision'] = 'sha256:${'0' * 64}';
      changedBootstrapReceipt['${_authoringRoot}idempotency.jsonl'] =
          _encodeLines(ledger);
      expect(
          () => _assertReproducible(firstBytes, changedBootstrapReceipt,
              expectedOperations, bootstrapBytes.first),
          throwsFormatException);
      final invalidChain = {...secondBytes};
      final audit = _jsonLines(secondBytes['${_authoringRoot}audit.jsonl']!);
      (_object(audit.first['record']))['code'] = 'fixture.changed';
      invalidChain['${_authoringRoot}audit.jsonl'] = _encodeLines(audit);
      expect(
          () => _assertReproducible(firstBytes, invalidChain,
              expectedOperations, bootstrapBytes.first),
          throwsFormatException);
      final changedAudit = {...secondBytes};
      _rehashChain(audit, 'authoring-audit-event.json');
      changedAudit['${_authoringRoot}audit.jsonl'] = _encodeLines(audit);
      expect(
          () => _assertReproducible(firstBytes, changedAudit,
              expectedOperations, bootstrapBytes.first),
          throwsFormatException);
      expect(await _treeBytes(first.projectPath), firstBytes);
      expect(await _treeBytes(second.projectPath), secondBytes);
      expect(await _treeBytes(source.sourceRootPath!), sourceBefore);
      expect([
        draft.canonicalHash,
        approved.plan.canonicalHash,
        approved.context.sourceSnapshotHash,
        approved.context.targetCapabilities.canonicalHash,
        approved.context.decisions.canonicalHash,
      ], inputHashes);
    } finally {
      await root.delete(recursive: true);
    }
  }, skip: !Platform.isMacOS);
}

void _assertReproducible(
    Map<String, List<int>> first,
    Map<String, List<int>> second,
    List<String> operations,
    Map<String, List<int>> bootstrap) {
  final left = _normaliseTree(first, operations, bootstrap);
  final right = _normaliseTree(second, operations, bootstrap);
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

Future<Map<String, List<int>>> _treeBytes(String root) async {
  final result = <String, List<int>>{};
  await for (final entry
      in Directory(root).list(recursive: true, followLinks: false)) {
    _require(entry is File || entry is Directory, 'Unexpected tree entry.');
    if (entry is File) {
      result[entry.path.substring(root.length + 1)] = await entry.readAsBytes();
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
