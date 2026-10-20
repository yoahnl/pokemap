import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:path/path.dart' as path;

const _authoringRoot = '.pokemap/authoring/';
const _ledgerPath = '${_authoringRoot}idempotency.jsonl';
const _emptyLocks = {
  '${_authoringRoot}idempotency.jsonl.lock',
  '${_authoringRoot}transactions/write.lock',
};

Map<String, List<int>> recoverNativeCreationBytes(
    Map<String, List<int>> files, String expectedInventoryFingerprint) {
  _require(
      RegExp(r'^sha256:[a-f0-9]{64}$').hasMatch(expectedInventoryFingerprint),
      'An exact native creation inventory fingerprint is required.');
  final ledger = files[_ledgerPath];
  _require(ledger != null, 'Native creation requires its durable ledger.');
  for (final entry in files.entries) {
    if (!entry.key.startsWith(_authoringRoot)) continue;
    _require(
        entry.key == _ledgerPath ||
            (_emptyLocks.contains(entry.key) && entry.value.isEmpty),
        'Unlisted or nonempty authoring metadata.');
  }
  final events = _jsonLines(ledger!);
  _require(
      events.length == 2, 'Exactly one native creation intent is required.');
  final records = <AuthoringIdempotencyRecord>[];
  for (final event in events) {
    _require(
        event.keys
                .toSet()
                .difference({'schemaVersion', 'event', 'record'}).isEmpty &&
            event['schemaVersion'] == 1 &&
            event['event'] == 'put',
        'Invalid native creation ledger event.');
    final json = _object(event['record']);
    final record = AuthoringIdempotencyRecord.fromJson(json);
    _sameJson(json, record.toJson());
    records.add(record);
  }
  final pending = records.first;
  final completed = records.last;
  final operation = completed.operationId;
  final receipt = completed.receipt;
  _require(
      pending.status == AuthoringIdempotencyStatus.pending &&
          completed.status == AuthoringIdempotencyStatus.completed &&
          receipt != null &&
          pending.scope.storageKey == completed.scope.storageKey &&
          pending.operationId == operation &&
          pending.payloadFingerprint == completed.payloadFingerprint &&
          pending.createdAt == completed.createdAt &&
          completed.expiresAt?.difference(completed.createdAt) ==
              const Duration(days: 30) &&
          completed.scope.actorId == 'project-creator' &&
          completed.scope.projectId == 'project-$operation' &&
          completed.scope.actionId == nativeProjectCreationActionId &&
          completed.scope.actionVersion == 1 &&
          completed.scope.matchesKey(operation) &&
          RegExp(r'^native-creation-[0-9]+-[0-9]+$').hasMatch(operation),
      'Native creation intent, scope or completion differs.');
  final actualReceipt = receipt!;
  _require(
      actualReceipt.status == AuthoringReceiptStatus.applied &&
          actualReceipt.actionId == nativeProjectCreationActionId &&
          actualReceipt.actionVersion == 1 &&
          actualReceipt.receiptId == 'receipt-$operation' &&
          actualReceipt.requestId == operation &&
          !DateTime.parse(actualReceipt.createdAtUtc)
              .isAfter(completed.createdAt) &&
          actualReceipt.artifacts.isEmpty,
      'Native creation receipt identity differs.');
  _sameJson(actualReceipt.extensions, {
    'inventoryFingerprint': expectedInventoryFingerprint,
    'planId': 'plan-$operation',
    'operationId': operation,
    'multiFileGuarantee': 'recoverable',
    'history': AuthoringHistoryContext.fromExtensions(const {}).toJson(),
  });
  final native = {
    for (final entry in files.entries)
      if (!entry.key.startsWith(_authoringRoot)) entry.key: entry.value
  };
  _require(
      native.isNotEmpty &&
          native.length <= nativeProjectCreationMaxResources &&
          native.containsKey('project.json'),
      'Native creation inventory is incomplete.');
  final inventory = [
    for (final key in (native.keys.toList()..sort()))
      {
        'storageKey': key,
        'afterRevision':
            computeAuthoringBytesFingerprint(native[key]!, logicalName: key),
        'byteLength': native[key]!.length
      }
  ];
  _require(
      computeAuthoringJsonFingerprint(inventory,
              logicalName: 'native-project-creation-inventory.json') ==
          expectedInventoryFingerprint,
      'Native bytes differ from the approved creation inventory.');
  final unseen = native.keys.toSet();
  final before = <AuthoringResourceRevision>[];
  final after = <AuthoringResourceRevision>[];
  for (final entry in actualReceipt.diff.entries) {
    final key =
        entry.resource.kind == 'project' ? 'project.json' : entry.resource.id;
    final bytes = native[key];
    final kind = key == 'project.json'
        ? 'project'
        : key == 'assets/.pokemap-assets.json'
            ? 'assetCatalog'
            : key.endsWith('.blob') || key.endsWith('.png')
                ? 'assetBlob'
                : 'map';
    _require(
        bytes != null &&
            unseen.remove(key) &&
            entry.resource.kind == kind &&
            entry.resource.id ==
                (kind == 'project' ? 'project-$operation' : key) &&
            entry.resource.extensions.isEmpty &&
            entry.resource.revision == null &&
            entry.operation == AuthoringDiffOperation.add &&
            entry.path == r'$' &&
            !entry.hasBefore &&
            entry.hasAfter &&
            entry.extensions.isEmpty,
        'Native creation diff inventory differs.');
    _sameJson(entry.after, {'byteLength': bytes!.length});
    before.add(
        AuthoringResourceRevision(resource: entry.resource, revision: null));
    after.add(AuthoringResourceRevision(
        resource: entry.resource,
        revision: computeAuthoringBytesFingerprint(bytes, logicalName: key)));
  }
  _require(
      unseen.isEmpty &&
          actualReceipt.beforeRevision ==
              AuthoringRevisionSet(before).fingerprint &&
          actualReceipt.afterRevision ==
              AuthoringRevisionSet(after).fingerprint,
      'Native creation receipt revisions differ from the exact inventory.');
  final manifest = _object(jsonDecode(utf8.decode(native['project.json']!)));
  _require(
      completed.payloadFingerprint ==
          computeAuthoringJsonFingerprint({
            'parameters': {
              'inventoryFingerprint': expectedInventoryFingerprint,
              'name': manifest['name'],
              'tileWidth': _object(manifest['settings'])['tileWidth'],
              'tileHeight': _object(manifest['settings'])['tileHeight']
            },
            'expectedRevision': computeAuthoringJsonFingerprint(const {},
                logicalName: 'empty-project'),
            'dryRun': false,
            'extensions': const {},
          }, logicalName: 'idempotency-payload.json'),
      'Native creation request differs from its durable intent.');
  return Map.unmodifiable(native);
}

final class NativeReproducibilityComparison {
  const NativeReproducibilityComparison({
    required this.left,
    required this.right,
    required this.fileCount,
    required this.canonicalFingerprint,
    required this.creationInventoryFingerprint,
  });
  final NativeStudyVerification left;
  final NativeStudyVerification right;
  final int fileCount;
  final String canonicalFingerprint;
  final String creationInventoryFingerprint;
  Map<String, Object?> toJson() => {
        'kind': 'nativeReproducibilityComparison',
        'version': 2,
        'equal': true,
        'left': left.toJson(),
        'right': right.toJson(),
        'fileCount': fileCount,
        'canonicalFingerprint': canonicalFingerprint,
        'creationInventoryFingerprint': creationInventoryFingerprint,
        'publicationTransactionsPerOutput': 1,
      };
}

Future<NativeReproducibilityComparison> compareNativeStudyDirectories({
  required String leftProjectPath,
  required String rightProjectPath,
  required String allowedParentPath,
  required String expectedInventoryFingerprint,
}) async {
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
  assertCanonicalNativeEquality(first, second, expectedInventoryFingerprint);
  final native =
      recoverNativeCreationBytes(first, expectedInventoryFingerprint);
  return NativeReproducibilityComparison(
    left: left,
    right: right,
    fileCount: first.length,
    creationInventoryFingerprint: expectedInventoryFingerprint,
    canonicalFingerprint: computeAuthoringJsonFingerprint({
      for (final key in (native.keys.toList()..sort()))
        key: {
          'byteLength': native[key]!.length,
          'fingerprint':
              computeAuthoringBytesFingerprint(native[key]!, logicalName: key),
        }
    }, logicalName: 'canonical-native-study-inventory.json'),
  );
}

void assertCanonicalNativeEquality(Map<String, List<int>> first,
    Map<String, List<int>> second, String expectedInventoryFingerprint) {
  _require(
      first.keys.toSet().difference(second.keys.toSet()).isEmpty &&
          second.keys.toSet().difference(first.keys.toSet()).isEmpty,
      'File inventory differs.');
  _requireExactTree(
      recoverNativeCreationBytes(first, expectedInventoryFingerprint),
      recoverNativeCreationBytes(second, expectedInventoryFingerprint));
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

List<Map<String, dynamic>> _jsonLines(List<int> bytes) {
  final content = utf8.decode(bytes);
  _require(content.endsWith('\n'), 'Log is not completely flushed.');
  return content
      .substring(0, content.length - 1)
      .split('\n')
      .map((line) => _object(jsonDecode(line)))
      .toList(growable: false);
}

Map<String, dynamic> _object(Object? value) {
  _require(value is Map, 'Expected a JSON object.');
  return Map<String, dynamic>.from(value as Map);
}

void _sameJson(Object? first, Object? second) => _require(
    canonicalAuthoringJson(first) == canonicalAuthoringJson(second),
    'Canonical JSON differs.');
bool _bytesEqual(List<int> first, List<int> second) =>
    first.length == second.length &&
    first.asMap().entries.every((entry) => entry.value == second[entry.key]);
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
              result.length < nativeProjectCreationMaxResources + 8,
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
