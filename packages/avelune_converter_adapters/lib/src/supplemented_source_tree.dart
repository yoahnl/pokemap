import 'package:avelune_converter_core/avelune_converter_core.dart';

import 'package:path/path.dart' as path;

import 'macos_source_tree.dart';

final class SupplementedSourceTree implements SourceTreePort {
  SupplementedSourceTree._(
      this._primary, this._reference, this._selectedReferenceRootPath);

  static const sharedPaths = {
    'Data/Scripts.rxdata',
    'Data/items.dat',
    'PBS/items.txt',
    'Data/moves.dat',
    'PBS/moves.txt',
  };

  final MacOsSourceTree _primary;
  final MacOsSourceTree? _reference;
  final String? _selectedReferenceRootPath;
  final Expando<_SourceOrigin> _origins = Expando<_SourceOrigin>();
  final Set<String> _sharedRelativePaths = {};
  Map<String, String> _primaryExpected = {};
  bool _closed = false;

  String get rootPath => _primary.rootPath;
  String? get sharedDataRootPath => _reference?.rootPath;
  List<String> get sourceRoots =>
      [rootPath, if (_reference != null) _reference.rootPath];
  List<String> get sharedRelativePaths =>
      List.unmodifiable(_sharedRelativePaths.toList()..sort());

  static Future<SupplementedSourceTree> open(String rootPath,
      {String? sharedDataRootPath}) async {
    final primary = await MacOsSourceTree.open(rootPath);
    try {
      final reference = sharedDataRootPath == null
          ? null
          : await MacOsSourceTree.open(sharedDataRootPath);
      return SupplementedSourceTree._(
          primary,
          reference,
          sharedDataRootPath == null
              ? null
              : path.normalize(sharedDataRootPath));
    } catch (_) {
      await primary.close();
      rethrow;
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    try {
      await _primary.close();
    } finally {
      await _reference?.close();
    }
  }

  @override
  Stream<SourceNode> walk(
      {required SourceScanPolicy policy,
      required ScanCancellation cancellation}) async* {
    _check(cancellation);
    _sharedRelativePaths.clear();
    _primaryExpected = {};
    final primaryNodes = <String, SourceNode>{};
    var entries = 0;
    var totalBytes = 0;
    var pathUnits = 0;

    void admit(SourceNode node, MacOsSourceTree origin) {
      cancellation.check();
      entries++;
      pathUnits += node.relativePath.length;
      if (entries > policy.limits.maxEntries) {
        throw ContractError('source.entry_limit', node.relativePath,
            'Source entry limit exceeded.');
      }
      if (pathUnits > policy.limits.maxTotalPathCodeUnits) {
        throw ContractError('source.total_path_limit', node.relativePath,
            'Source total path length limit exceeded.');
      }
      if (node.kind == SourceNodeKind.file &&
          !policy.isExcluded(node.relativePath)) {
        totalBytes += node.byteLength;
        if (totalBytes > policy.limits.maxTotalBytes) {
          throw ContractError('source.total_bytes_limit', node.relativePath,
              'Source total byte limit exceeded.');
        }
        _origins[node] = _SourceOrigin(
            origin,
            identical(origin, _reference),
            identical(origin, _reference)
                ? Map.unmodifiable(_primaryExpected)
                : const {},
            policy);
      }
    }

    await for (final node
        in _primary.walk(policy: policy, cancellation: cancellation)) {
      final key = sourcePathCollisionKey(node.relativePath);
      if (_reference != null && primaryNodes.containsKey(key)) {
        throw ContractError('source.path_collision', node.relativePath,
            'Source paths collide after Unicode and case normalization.');
      }
      primaryNodes[key] = node;
      if (_isSelected(key)) _primaryExpected[key] = _identity(node);
      admit(node, _primary);
      yield node;
    }
    final reference = _reference;
    if (reference == null) return;
    final missing = sharedPaths
        .where(
            (value) => !primaryNodes.containsKey(sourcePathCollisionKey(value)))
        .toSet();
    if (missing.isEmpty) return;
    final sharedNodes = <String, SourceNode>{};
    await for (final node in reference.walkSelected(
        relativePaths: missing, policy: policy, cancellation: cancellation)) {
      final key = sourcePathCollisionKey(node.relativePath);
      if (sharedNodes.containsKey(key)) {
        throw ContractError('source.path_collision', node.relativePath,
            'Shared paths collide after Unicode and case normalization.');
      }
      sharedNodes[key] = node;
      if (policy.isExcluded(node.relativePath)) continue;
      final target =
          missing.any((value) => sourcePathCollisionKey(value) == key);
      if (node.kind !=
          (target ? SourceNodeKind.file : SourceNodeKind.directory)) {
        throw ContractError('source.shared.node_invalid', node.relativePath,
            'Shared references require regular files and directory ancestors without links.');
      }
    }
    await _verifyPrimary(cancellation, _primaryExpected, policy);
    final emitted = primaryNodes.keys.toSet();
    final files = sharedNodes.values
        .where((node) =>
            node.kind == SourceNodeKind.file &&
            !policy.isExcluded(node.relativePath))
        .toList()
      ..sort((a, b) => a.relativePath.compareTo(b.relativePath));
    for (final file in files) {
      final segments = file.relativePath.split('/');
      for (var i = 1; i < segments.length; i++) {
        final parent = segments.take(i).join('/');
        final key = sourcePathCollisionKey(parent);
        final existing = primaryNodes[key];
        if (existing != null &&
            (existing.kind != SourceNodeKind.directory ||
                existing.relativePath != parent)) {
          throw ContractError('source.shared.path_conflict', parent,
              'The shared path conflicts with a source ancestor.');
        }
        if (emitted.add(key)) {
          final node = sharedNodes[key]!;
          admit(node, reference);
          yield node;
        }
      }
      admit(file, reference);
      _sharedRelativePaths.add(file.relativePath);
      yield file;
    }
  }

  @override
  Stream<List<int>> read(SourceNode node,
      {required int maxBytes, required ScanCancellation cancellation}) async* {
    _check(cancellation);
    final origin = _origins[node];
    if (origin == null) {
      throw ContractError('source.node_unissued', node.relativePath,
          'The source file was not authorized by this source tree instance.');
    }
    if (origin.shared) {
      await _verifyPrimary(cancellation, origin.primaryExpected, origin.policy);
    }
    yield* origin.tree
        .read(node, maxBytes: maxBytes, cancellation: cancellation);
    if (origin.shared) {
      await _verifyPrimary(cancellation, origin.primaryExpected, origin.policy);
    }
  }

  Future<void> _verifyPrimary(ScanCancellation cancellation,
      Map<String, String> expected, SourceScanPolicy policy) async {
    final observed = <String, String>{};
    await for (final node in _primary.walkSelected(
        relativePaths: sharedPaths,
        policy: policy,
        cancellation: cancellation)) {
      final key = sourcePathCollisionKey(node.relativePath);
      if (observed.containsKey(key)) {
        throw ContractError('source.changed', node.relativePath,
            'The primary source changed after inventory.');
      }
      observed[key] = _identity(node);
    }
    if (observed.length != expected.length ||
        observed.entries.any((entry) => expected[entry.key] != entry.value)) {
      throw ContractError('source.changed', r'$',
          'The primary source changed after inventory.');
    }
  }

  void _check(ScanCancellation cancellation) {
    cancellation.check();
    if (_closed) {
      throw ContractError('source.closed', r'$', 'The source tree is closed.');
    }
  }

  List<ConverterSharedSourceFile> sharedSourceFilesFor(
          SourceSnapshot snapshot) =>
      List.unmodifiable(snapshot.entries
          .where((entry) =>
              _sharedRelativePaths.contains(entry.relativePath) &&
              entry.sha256 != null)
          .map((entry) => ConverterSharedSourceFile(
              relativePath: entry.relativePath,
              referenceRootPath: _selectedReferenceRootPath!,
              fileId: entry.fileId,
              sha256: entry.sha256!)));

  static bool _isSelected(String key) => sharedPaths.any((value) {
        final selected = sourcePathCollisionKey(value);
        return selected == key || selected.startsWith('$key/');
      });

  static String _identity(SourceNode node) =>
      '${node.relativePath}:${node.kind.name}:${node.byteLength}:${node.token}';
}

final class _SourceOrigin {
  const _SourceOrigin(
      this.tree, this.shared, this.primaryExpected, this.policy);
  final MacOsSourceTree tree;
  final bool shared;
  final Map<String, String> primaryExpected;
  final SourceScanPolicy policy;
}

final class ConverterSharedSourceFile {
  ConverterSharedSourceFile(
      {required this.relativePath,
      required this.referenceRootPath,
      required this.fileId,
      required this.sha256}) {
    validateSourceRelativePath(relativePath);
    if (!SupplementedSourceTree.sharedPaths
            .map(sourcePathCollisionKey)
            .contains(sourcePathCollisionKey(relativePath)) ||
        !path.isAbsolute(referenceRootPath) ||
        referenceRootPath.contains('\u0000') ||
        referenceRootPath.length > 4096 ||
        path.normalize(referenceRootPath) != referenceRootPath) {
      throw ContractError('source.shared.reference_invalid', r'$',
          'Invalid shared source reference.');
    }
  }

  factory ConverterSharedSourceFile.fromJson(Object? input) {
    if (input is! Map ||
        input.length != 4 ||
        input['relativePath'] is! String ||
        input['referenceRootPath'] is! String ||
        input['fileId'] is! String ||
        input['sha256'] is! String) {
      throw ContractError('source.shared.reference_invalid', r'$',
          'Invalid shared source reference.');
    }
    return ConverterSharedSourceFile(
        relativePath: input['relativePath'] as String,
        referenceRootPath: input['referenceRootPath'] as String,
        fileId: ConverterId(input['fileId'] as String),
        sha256: Sha256Hash(input['sha256'] as String));
  }

  final String relativePath;
  final String referenceRootPath;
  final ConverterId fileId;
  final Sha256Hash sha256;

  Map<String, Object?> toJson() => {
        'relativePath': relativePath,
        'referenceRootPath': referenceRootPath,
        'fileId': fileId.value,
        'sha256': sha256.value,
      };
}
