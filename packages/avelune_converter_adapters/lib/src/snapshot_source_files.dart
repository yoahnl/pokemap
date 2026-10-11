import 'dart:typed_data';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;

final class SnapshotSourceFiles implements SourceFilePort {
  SnapshotSourceFiles._(this._source, this._snapshot, this._policy,
      this._cancellation, this._manifest)
      : _entries = {
          for (final entry in _snapshot.entries) entry.fileId: entry,
        };

  final SourceTreePort _source;
  final SourceSnapshot _snapshot;
  final SourceScanPolicy _policy;
  final ScanCancellation _cancellation;
  final _SnapshotManifest _manifest;
  final Map<ConverterId, SourceFileEntry> _entries;
  int _readAttempts = 0;
  int _reservedBytes = 0;

  static Future<SnapshotSourceFiles> bind({
    required SourceTreePort source,
    required SourceSnapshot snapshot,
    SourceScanPolicy? policy,
    ScanCancellation? cancellation,
  }) async {
    final effective = policy ?? SourceScanPolicy();
    final cancel = cancellation ?? ScanCancellation();
    cancel.check();
    if (snapshot.state != SourceScanState.complete) {
      throw ContractError('source.snapshot_incomplete', r'$',
          'Source reads require a complete inventory.');
    }
    if (snapshot.policyHash != effective.canonicalHash) {
      throw ContractError('source.policy_mismatch', r'$',
          'Source policy does not match the inventory.');
    }
    _validateSnapshot(snapshot, effective);
    final manifest = await _enumerate(source, effective, cancel);
    _match(snapshot, manifest);
    cancel.check();
    return SnapshotSourceFiles._(source, snapshot, effective, cancel, manifest);
  }

  @override
  Future<List<int>> read(ConverterId fileId) async {
    _cancellation.check();
    final entry = _entries[fileId];
    if (entry == null) {
      throw ContractError('source.file_unknown', r'$',
          'File ID is not in the bound inventory.');
    }
    if (entry.kind != SourceNodeKind.file) {
      throw ContractError('source.node_not_file', entry.relativePath,
          'Only inventoried regular files can be read.');
    }
    final limits = _policy.limits;
    if (_readAttempts >= limits.maxEntries) {
      throw ContractError('source.read_count_limit', entry.relativePath,
          'Source read attempt quota exceeded.');
    }
    if (entry.byteLength > limits.maxTotalBytes - _reservedBytes) {
      throw ContractError('source.read_byte_limit', entry.relativePath,
          'Cumulative source read reservation quota exceeded.');
    }
    _readAttempts++;
    _reservedBytes += entry.byteLength;
    final node = _manifest.nodes[entry.relativePath]!;
    final bytes = BytesBuilder(copy: true);
    final digest = _SnapshotDigestSink();
    final hash = crypto.sha256.startChunkedConversion(digest);
    var consumed = 0;
    var emptyChunks = 0;
    var hashClosed = false;
    try {
      await for (final chunk in _source.read(node,
          maxBytes: entry.byteLength, cancellation: _cancellation)) {
        _cancellation.check();
        if (chunk.isEmpty) {
          if (++emptyChunks > 1024) {
            throw ContractError('source.empty_chunk_limit', entry.relativePath,
                'Source stream exceeds the empty chunk quota.');
          }
          continue;
        }
        if (chunk.length > entry.byteLength - consumed) {
          throw ContractError('source.changed', entry.relativePath,
              'Source bytes exceed their inventoried length.');
        }
        for (final byte in chunk) {
          if (byte < 0 || byte > 255) {
            throw ContractError('source.invalid_byte', entry.relativePath,
                'Source stream contains a value outside the byte range.');
          }
        }
        consumed += chunk.length;
        hash.add(chunk);
        bytes.add(chunk);
      }
      _cancellation.check();
      if (consumed != entry.byteLength) {
        throw ContractError('source.changed', entry.relativePath,
            'Source bytes differ from their inventoried length.');
      }
      hash.close();
      hashClosed = true;
      if (digest.hash != entry.sha256) {
        throw ContractError('source.content_changed', entry.relativePath,
            'Source bytes do not match the inventory hash.');
      }
      return bytes.takeBytes().asUnmodifiableView();
    } on ContractError {
      rethrow;
    } catch (_) {
      throw ContractError('source.read_failed', entry.relativePath,
          'The bound source file could not be read.');
    } finally {
      if (!hashClosed) hash.close();
    }
  }

  Future<void> verifyUnchanged() async {
    _cancellation.check();
    final fresh = await _enumerate(_source, _policy, _cancellation);
    _match(_snapshot, fresh);
    for (final entry in _manifest.nodes.entries) {
      if (fresh.nodes[entry.key]!.token != entry.value.token) {
        throw ContractError('source.snapshot_changed', entry.key,
            'Source metadata changed after snapshot binding.');
      }
    }
    _cancellation.check();
  }

  static void _validateSnapshot(
      SourceSnapshot snapshot, SourceScanPolicy policy) {
    final limits = policy.limits;
    if (snapshot.entries.length + snapshot.excludedPaths.length >
        limits.maxEntries) {
      throw ContractError('source.entry_limit', r'$',
          'Inventory exceeds the source entry quota.');
    }
    var pathUnits = 0;
    var declaredBytes = 0;
    void path(String value) {
      validateSourceRelativePath(value, maxCodeUnits: limits.maxPathCodeUnits);
      if (value.split('/').length > limits.maxDepth) {
        throw ContractError(
            'source.depth_limit', value, 'Inventory exceeds the depth quota.');
      }
      if (value.length > limits.maxTotalPathCodeUnits - pathUnits) {
        throw ContractError('source.path_total_limit', value,
            'Inventory exceeds the cumulative path quota.');
      }
      pathUnits += value.length;
    }

    for (final entry in snapshot.entries) {
      path(entry.relativePath);
      if (policy.isExcluded(entry.relativePath)) {
        throw ContractError('source.snapshot_changed', entry.relativePath,
            'An excluded path is present in the inventory.');
      }
      if (entry.kind == SourceNodeKind.file) {
        if (entry.byteLength > limits.maxFileBytes) {
          throw ContractError('source.file_limit', entry.relativePath,
              'Inventory file exceeds its byte quota.');
        }
        if (entry.byteLength > limits.maxTotalBytes - declaredBytes) {
          throw ContractError('source.total_limit', entry.relativePath,
              'Inventory exceeds the aggregate byte quota.');
        }
        declaredBytes += entry.byteLength;
      }
    }
    for (final excluded in snapshot.excludedPaths) {
      path(excluded);
      if (!policy.isExcluded(excluded)) {
        throw ContractError('source.snapshot_changed', excluded,
            'An excluded inventory path does not match the source policy.');
      }
    }
  }

  static Future<_SnapshotManifest> _enumerate(SourceTreePort source,
      SourceScanPolicy policy, ScanCancellation cancellation) async {
    final limits = policy.limits;
    final nodes = <String, SourceNode>{};
    final seen = <String>{};
    final excluded = <String>{};
    var count = 0;
    var pathUnits = 0;
    var declaredBytes = 0;
    try {
      await for (final node
          in source.walk(policy: policy, cancellation: cancellation)) {
        cancellation.check();
        if (++count > limits.maxEntries) {
          throw ContractError(
              'source.entry_limit', r'$', 'Source exceeds the entry quota.');
        }
        final path = node.relativePath;
        validateSourceRelativePath(path, maxCodeUnits: limits.maxPathCodeUnits);
        if (path.split('/').length > limits.maxDepth) {
          throw ContractError(
              'source.depth_limit', path, 'Source exceeds the depth quota.');
        }
        if (path.length > limits.maxTotalPathCodeUnits - pathUnits) {
          throw ContractError('source.path_total_limit', path,
              'Source exceeds the cumulative path quota.');
        }
        pathUnits += path.length;
        if (node.byteLength < 0 ||
            node.byteLength > 9007199254740991 ||
            node.token.isEmpty) {
          throw ContractError('source.node', path, 'Invalid source node.');
        }
        if (!seen.add(path)) {
          throw ContractError(
              'source.duplicate_path', path, 'Duplicate path in source walk.');
        }
        if (policy.isExcluded(path)) {
          excluded.add(path);
          continue;
        }
        if (node.kind == SourceNodeKind.file) {
          if (node.byteLength > limits.maxFileBytes) {
            throw ContractError('source.file_limit', path,
                'Source file exceeds its byte quota.');
          }
          if (node.byteLength > limits.maxTotalBytes - declaredBytes) {
            throw ContractError('source.total_limit', path,
                'Source exceeds the aggregate byte quota.');
          }
          declaredBytes += node.byteLength;
        }
        nodes[path] = node;
      }
      cancellation.check();
    } on ContractError {
      rethrow;
    } catch (_) {
      throw ContractError('source.walk_failed', r'$',
          'The bound source tree could not be enumerated.');
    }
    return _SnapshotManifest(nodes, excluded);
  }

  static void _match(SourceSnapshot snapshot, _SnapshotManifest actual) {
    if (actual.nodes.length != snapshot.entries.length ||
        actual.excludedPaths.length != snapshot.excludedPaths.length ||
        !actual.excludedPaths.containsAll(snapshot.excludedPaths)) {
      throw ContractError('source.snapshot_changed', r'$',
          'Source manifest differs from the bound inventory.');
    }
    for (final entry in snapshot.entries) {
      final node = actual.nodes[entry.relativePath];
      if (node == null ||
          node.kind != entry.kind ||
          node.byteLength != entry.byteLength) {
        throw ContractError('source.snapshot_changed', entry.relativePath,
            'Source metadata differs from the bound inventory.');
      }
    }
  }
}

final class _SnapshotManifest {
  _SnapshotManifest(Map<String, SourceNode> nodes, Set<String> excludedPaths)
      : nodes = Map.unmodifiable(nodes),
        excludedPaths = Set.unmodifiable(excludedPaths);

  final Map<String, SourceNode> nodes;
  final Set<String> excludedPaths;
}

final class _SnapshotDigestSink implements Sink<crypto.Digest> {
  crypto.Digest? _digest;
  Sha256Hash get hash => Sha256Hash(_digest!.toString());

  @override
  void add(crypto.Digest data) => _digest = data;

  @override
  void close() {}
}
