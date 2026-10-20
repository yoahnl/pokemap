import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:path/path.dart' as p;

import '../contracts/artifact_ref.dart';
import '../contracts/json_contract_support.dart';
import 'native_project_creation.dart';
import 'project_creation_contracts.dart';
import 'workspace_policy.dart';

abstract interface class NativeProjectCreationTransportPort {
  Future<Map<String, Object?>> prepare(Map<String, dynamic> source,
      {bool Function()? isCancelled});
  Future<Map<String, Object?>> plan(Map<String, dynamic> request,
      {bool Function()? isCancelled});
  Future<Map<String, Object?>> publish(Map<String, dynamic> request,
      {bool Function()? isCancelled});
  Map<String, Object?> release(String preparedHandle);
  void close();
}

final class NativeProjectCreationTransport
    implements NativeProjectCreationTransportPort {
  NativeProjectCreationTransport(
      {required WorkspacePolicy policy,
      NativeProjectCreationService service =
          const NativeProjectCreationService()})
      : _policy = policy,
        _service = service;

  final WorkspacePolicy _policy;
  final NativeProjectCreationService _service;
  final _prepared = <String, _PreparedSource>{};
  final _plans = <String, _SourcePlan>{};
  final _random = Random.secure();
  var _retainedBytes = 0;
  bool _closed = false;
  bool _busy = false;

  @override
  Future<Map<String, Object?>> prepare(Map<String, dynamic> source,
          {bool Function()? isCancelled}) =>
      _serialized(() => _prepare(source, isCancelled));

  Future<Map<String, Object?>> _prepare(
      Map<String, dynamic> source, bool Function()? isCancelled) async {
    _requireOpen();
    if (_prepared.length >= 2) _fail('session_budget');
    final descriptor = _Witness.absolute(source);
    if (descriptor.byteLength > nativeProjectCreationMaxBytes) {
      _fail('source_budget');
    }
    final descriptorBytes = await _read(descriptor);
    final document = _object(jsonDecode(utf8.decode(descriptorBytes)));
    rejectUnknownContractKeys(
        document, const {'kind', 'schemaVersion', 'input'});
    if (document['kind'] != 'nativeProjectCreationSource' ||
        document['schemaVersion'] != 1) {
      _fail('descriptor_invalid');
    }
    final input = _object(document['input']);
    final root = p.dirname(descriptor.path);
    final witnesses = <_Witness>[descriptor];
    final artifactRows = _rows(input['artifacts']);
    final frameRows = _rows(input['borderFrames']);
    final sources = <Map<String, dynamic>, _Witness>{};
    void stage(Map<String, dynamic> row) {
      rejectUnknownContractKeys(row, const {'reference', 'source'});
      final ref = ContentArtifactRef.fromJson(_object(row['reference']));
      final witness = _Witness.relative(root, _object(row['source']));
      if (ref.byteLength != witness.byteLength) _fail('artifact_witness');
      sources[row] = witness;
      witnesses.add(witness);
    }

    for (final row in artifactRows) {
      stage(row);
    }
    for (final row in frameRows) {
      rejectUnknownContractKeys(
          row, const {'snapshotId', 'frameIndex', 'artifact'});
      stage(_object(row['artifact']));
    }
    if (sources.length > nativeProjectCreationMaxResources) {
      _fail('source_budget');
    }
    var total = descriptor.byteLength;
    for (final witness in sources.values) {
      if (witness.byteLength > nativeProjectCreationMaxBytes ||
          witness.byteLength > nativeProjectCreationMaxBytes - total) {
        _fail('source_budget');
      }
      total += witness.byteLength;
    }
    if (total > nativeProjectCreationMaxBytes - _retainedBytes) {
      _fail('session_budget');
    }
    final bytesByReference = <String, List<int>>{};
    final hashesByReference = <String, String>{};
    String key(Map<String, dynamic> reference) {
      final value = ContentArtifactRef.fromJson(reference);
      return '${value.handle}|${value.mediaType}|${value.byteLength}';
    }

    for (final entry in sources.entries) {
      final identity = key(_object(entry.key['reference']));
      final previousHash = hashesByReference[identity];
      if (previousHash != null && previousHash != entry.value.sha256) {
        _fail('artifact_witness');
      }
      hashesByReference[identity] = entry.value.sha256;
      bytesByReference[identity] ??= await _read(entry.value);
    }
    Map<String, Object?> reference(Map<String, dynamic> row) =>
        {'reference': row['reference']};
    final prepared = await _service.prepare(
        NativeProjectCreationInput.fromJson({
      ...input,
      'artifacts': artifactRows.map(reference).toList(),
      'borderFrames': [
        for (final row in frameRows)
          {...row, 'artifact': reference(_object(row['artifact']))}
      ],
    },
            artifactBytes: (row) =>
                bytesByReference[key(_object(row['reference']))]!));
    await _verify(witnesses);
    _requireOpen();
    if (isCancelled?.call() == true) throw const ProjectCreationCancelled();
    final handle = _handle();
    _prepared[handle] = _PreparedSource(prepared, witnesses, total);
    _retainedBytes += total;
    return {
      'actionId': nativeProjectCreationActionId,
      'actionVersion': 1,
      'preparedHandle': handle,
      'inventoryFingerprint': prepared.inventoryFingerprint,
      'byteLength': prepared.byteLength,
      'resourceCount': prepared.resourceCount,
      'source': descriptor.toJson(),
      'writesDestination': false,
      'capabilityScope': 'workerSessionOnlyReprepareAfterRestart'
    };
  }

  @override
  Future<Map<String, Object?>> plan(Map<String, dynamic> request,
          {bool Function()? isCancelled}) =>
      _serialized(() => _plan(request, isCancelled));

  Future<Map<String, Object?>> _plan(
      Map<String, dynamic> request, bool Function()? isCancelled) async {
    _requireOpen();
    rejectUnknownContractKeys(request, const {
      'preparedHandle',
      'expectedInventoryFingerprint',
      'parentPath',
      'folderName'
    });
    final prepared = _requirePrepared(request['preparedHandle']);
    _fingerprint(prepared.prepared.inventoryFingerprint, request);
    if (_plans.length >= 4) _fail('session_budget');
    await _verify(prepared.witnesses);
    final parent = requireContractString(request['parentPath'], 'parentPath');
    final canonicalParent = await _policy.authorizeProjectRoot(parent);
    if (parent != canonicalParent || !p.isAbsolute(parent)) _fail('path_alias');
    final plan = await _service.plan(
        prepared: prepared.prepared,
        parentPath: canonicalParent,
        folderName: requireContractString(request['folderName'], 'folderName'));
    _requireOpen();
    if (isCancelled?.call() == true) throw const ProjectCreationCancelled();
    final handle = _handle();
    _plans[handle] = _SourcePlan(prepared, plan);
    return {
      'actionId': nativeProjectCreationActionId,
      'actionVersion': 1,
      'planHandle': handle,
      'projectPath': plan.projectPath,
      'inventoryFingerprint': plan.inventoryFingerprint,
      'operationId': plan.operationId,
      'planId': plan.planId,
      'projectId': plan.projectId,
      'beforeRevision': plan.beforeRevision,
      'afterRevision': plan.afterRevision,
      'diff': plan.diff.toJson(),
      'createdAt': plan.createdAt.toUtc().toIso8601String(),
      'expiresAt': plan.expiresAt.toUtc().toIso8601String(),
      'writesDestination': false,
      'undoable': false,
      'replacesExisting': false
    };
  }

  @override
  Future<Map<String, Object?>> publish(Map<String, dynamic> request,
          {bool Function()? isCancelled}) =>
      _serialized(() => _publish(request, isCancelled));

  Future<Map<String, Object?>> _publish(
      Map<String, dynamic> request, bool Function()? isCancelled) async {
    _requireOpen();
    rejectUnknownContractKeys(
        request, const {'planHandle', 'expectedInventoryFingerprint'});
    final handle = requireContractString(request['planHandle'], 'planHandle');
    final entry = _plans[handle];
    if (entry == null) _fail('plan_unknown');
    _fingerprint(entry.plan.inventoryFingerprint, request);
    if (!entry.completed) await _verify(entry.source.witnesses);
    final parent = await _policy.authorizeProjectRoot(entry.plan.parentPath);
    if (parent != entry.plan.parentPath) _fail('path_alias');
    _requireOpen();
    if (isCancelled?.call() == true) throw const ProjectCreationCancelled();
    final receipt = await _service.publish(entry.plan);
    entry.completed = true;
    return {
      'actionId': nativeProjectCreationActionId,
      'actionVersion': 1,
      'projectPath': receipt.projectPath,
      'projectName': receipt.manifest.name,
      'mapIds': receipt.manifest.maps.map((map) => map.id).toList(),
      'inventoryFingerprint': receipt.inventoryFingerprint,
      'transactionReceipt': receipt.transactionReceipt.toJson(),
      'undoable': false,
      'replacesExisting': false
    };
  }

  @override
  Map<String, Object?> release(String preparedHandle) {
    if (_busy) _fail('session_busy');
    final removed = _prepared.remove(preparedHandle);
    if (removed != null) {
      _retainedBytes -= removed.sourceBytes;
      _plans.removeWhere((_, value) => identical(value.source, removed));
    }
    return {'released': removed != null};
  }

  @override
  void close() {
    _closed = true;
    _plans.clear();
    _prepared.clear();
    _retainedBytes = 0;
  }

  Future<Map<String, Object?>> _serialized(
      Future<Map<String, Object?>> Function() operation) async {
    _requireOpen();
    if (_busy) _fail('session_busy');
    _busy = true;
    try {
      return await operation();
    } finally {
      _busy = false;
    }
  }

  _PreparedSource _requirePrepared(Object? handle) {
    final value = _prepared[requireContractString(handle, 'preparedHandle')];
    if (value == null) _fail('prepared_unknown');
    return value;
  }

  void _requireOpen() {
    if (_closed) _fail('session_closed');
  }

  String _handle() =>
      base64UrlEncode(List.generate(24, (_) => _random.nextInt(256)));
  void _fingerprint(String expected, Map<String, dynamic> request) {
    if (request['expectedInventoryFingerprint'] != expected) {
      _fail('inventory_changed');
    }
  }

  Future<void> _authorize(_Witness witness) async {
    if (!p.isAbsolute(witness.path) ||
        p.normalize(witness.path) != witness.path ||
        witness.path.contains('\\') ||
        witness.path.contains('\u0000')) {
      _fail('source_path');
    }
    final parent = await _policy.authorizeProjectRoot(p.dirname(witness.path));
    if (parent != p.dirname(witness.path) ||
        await FileSystemEntity.type(witness.path, followLinks: false) !=
            FileSystemEntityType.file ||
        await File(witness.path).resolveSymbolicLinks() != witness.path) {
      _fail('source_path');
    }
  }

  Future<List<int>> _read(_Witness witness) async {
    await _authorize(witness);
    final before = await File(witness.path).stat();
    if (before.size != witness.byteLength) _fail('source_changed');
    final bytes = BytesBuilder(copy: false);
    var count = 0;
    await for (final chunk in File(witness.path).openRead()) {
      if (chunk.length > witness.byteLength - count) {
        _fail('source_changed');
      }
      count += chunk.length;
      bytes.add(chunk);
    }
    await _authorize(witness);
    final after = await File(witness.path).stat();
    final result = bytes.takeBytes();
    if (count != witness.byteLength ||
        before.size != after.size ||
        before.modified != after.modified ||
        crypto.sha256.convert(result).toString() != witness.sha256) {
      _fail('source_changed');
    }
    return result;
  }

  Future<void> _verify(List<_Witness> witnesses) async {
    for (final witness in witnesses) {
      await _authorize(witness);
      final before = await File(witness.path).stat();
      if (before.size != witness.byteLength) _fail('source_changed');
      var count = 0;
      final digest = await crypto.sha256
          .bind(File(witness.path).openRead().map((chunk) {
            count += chunk.length;
            if (count > witness.byteLength) _fail('source_changed');
            return chunk;
          }))
          .first;
      await _authorize(witness);
      final after = await File(witness.path).stat();
      if (count != witness.byteLength ||
          before.size != after.size ||
          before.modified != after.modified ||
          digest.toString() != witness.sha256) {
        _fail('source_changed');
      }
    }
  }
}

final class _SourcePlan {
  _SourcePlan(this.source, this.plan);
  final _PreparedSource source;
  final NativeProjectCreationPlan plan;
  bool completed = false;
}

final class _PreparedSource {
  const _PreparedSource(this.prepared, this.witnesses, this.sourceBytes);
  final NativePreparedProjectCreation prepared;
  final List<_Witness> witnesses;
  final int sourceBytes;
}

final class _Witness {
  const _Witness(this.path, this.sha256, this.byteLength);
  factory _Witness.absolute(Map<String, dynamic> json) {
    rejectUnknownContractKeys(
        json, const {'descriptorPath', 'sha256', 'byteLength'});
    return _Witness._read(
        requireContractString(json['descriptorPath'], 'descriptorPath'), json);
  }
  factory _Witness.relative(String root, Map<String, dynamic> json) {
    rejectUnknownContractKeys(
        json, const {'relativePath', 'sha256', 'byteLength'});
    final relative =
        requireContractString(json['relativePath'], 'relativePath');
    if (p.isAbsolute(relative) ||
        relative.contains('\\') ||
        relative
            .split('/')
            .any((part) => part.isEmpty || part == '.' || part == '..')) {
      _fail('source_path');
    }
    return _Witness._read(p.join(root, relative), json);
  }
  factory _Witness._read(String path, Map<String, dynamic> json) {
    final sha = requireContractString(json['sha256'], 'sha256');
    final length = json['byteLength'];
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(sha) ||
        length is! int ||
        length < 0) {
      _fail('witness_invalid');
    }
    return _Witness(path, sha, length);
  }
  final String path, sha256;
  final int byteLength;
  Map<String, Object?> toJson() =>
      {'descriptorPath': path, 'sha256': sha256, 'byteLength': byteLength};
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw const FormatException('An object is required.');
  }
  return Map<String, dynamic>.from(value);
}

List<Map<String, dynamic>> _rows(Object? value) {
  if (value == null) return const [];
  if (value is! List || value.length > nativeProjectCreationMaxResources) {
    _fail('source_budget');
  }
  return value.map(_object).toList();
}

Never _fail(String reason) => throw ProjectCreationException(
    'native_creation.$reason', 'Native project creation refused: $reason.');
