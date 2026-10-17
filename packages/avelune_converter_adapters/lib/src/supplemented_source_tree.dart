import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:path/path.dart' as path;

import 'macos_source_tree.dart';

final class SupplementedSourceTree implements SourceTreePort {
  SupplementedSourceTree._(this._trees);

  static const maxSupplementalRoots = 4;
  static const maxSupplementalMediaFiles = 1024;
  static const maxSupplementalMediaBytes = 536870912;
  static const maxSupplementalMediaFileBytes = 33554432;
  static const sharedPaths = {
    'Data/Scripts.rxdata',
    'Data/items.dat',
    'PBS/items.txt',
    'Data/moves.dat',
    'PBS/moves.txt',
    'Data/species.dat',
    'PBS/pokemon.txt',
    'PBS/pokemon_forms.txt',
    'Game.exe',
  };
  static const maxSupplementalFiles = maxSupplementalMediaFiles + 9;
  static const _mediaRoots = {'Graphics', 'Audio'};
  static const _imageExtensions = {'.png', '.bmp', '.jpg', '.jpeg'};
  static const _audioExtensions = {'.wav', '.ogg', '.mp3', '.flac'};

  final List<MacOsSourceTree> _trees;
  final Expando<_SourceOrigin> _origins = Expando<_SourceOrigin>();
  final Map<String, String> _sharedOrigins = {};
  bool _closed = false;

  String get rootPath => _trees.first.rootPath;
  List<String> get supplementalRootPaths =>
      List.unmodifiable(_trees.skip(1).map((tree) => tree.rootPath));
  List<String> get sourceRoots =>
      List.unmodifiable(_trees.map((tree) => tree.rootPath));
  List<String> get sharedRelativePaths =>
      List.unmodifiable(_sharedOrigins.keys.toList()..sort());

  static bool isSupplementalFilePath(String value) {
    if (sharedPaths.contains(value)) return true;
    final extension = path.posix.extension(value).toLowerCase();
    return value.startsWith('Graphics/') &&
            _imageExtensions.contains(extension) ||
        value.startsWith('Audio/') && _audioExtensions.contains(extension);
  }

  static bool _isCandidatePath(String value) {
    final key = sourcePathCollisionKey(value);
    if (sharedPaths
        .any((selected) => sourcePathCollisionKey(selected) == key)) {
      return true;
    }
    final extension = path.posix.extension(value).toLowerCase();
    return key.startsWith('graphics/') &&
            _imageExtensions.contains(extension) ||
        key.startsWith('audio/') && _audioExtensions.contains(extension);
  }

  static Future<SupplementedSourceTree> open(String rootPath,
      {List<String> supplementalRootPaths = const []}) async {
    if (supplementalRootPaths.length > maxSupplementalRoots ||
        [rootPath, ...supplementalRootPaths].any((root) =>
            !path.isAbsolute(root) ||
            root.length > 4096 ||
            root.contains('\u0000'))) {
      throw ContractError('source.shared.roots_invalid', r'$',
          'Choose at most four explicit absolute supplemental folders.');
    }
    final trees = <MacOsSourceTree>[];
    try {
      final roots = <String>{};
      for (final selected in [rootPath, ...supplementalRootPaths]) {
        final tree = await MacOsSourceTree.open(selected);
        trees.add(tree);
        if (!roots.add(tree.rootPath)) {
          throw ContractError('source.shared.roots_invalid', r'$',
              'Source folders must be canonically distinct.');
        }
      }
      return SupplementedSourceTree._(List.unmodifiable(trees));
    } catch (_) {
      for (final tree in trees.reversed) {
        await tree.close();
      }
      rethrow;
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    for (final tree in _trees.reversed) {
      await tree.close();
    }
  }

  @override
  Stream<SourceNode> walk(
      {required SourceScanPolicy policy,
      required ScanCancellation cancellation}) async* {
    _check(cancellation);
    _sharedOrigins.clear();
    final merged = <String, SourceNode>{};
    final inventories = <_SourceInventory>[];
    var entries = 0;
    var totalBytes = 0;
    var pathUnits = 0;
    var mediaFiles = 0;
    var mediaBytes = 0;

    void admit(SourceNode node, MacOsSourceTree origin,
        List<_SourceInventory> earlier) {
      cancellation.check();
      if (++entries > policy.limits.maxEntries) {
        throw ContractError('source.entry_limit', node.relativePath,
            'Source entry limit exceeded.');
      }
      pathUnits += node.relativePath.length;
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
        _origins[node] = _SourceOrigin(origin, earlier, policy);
      }
    }

    final primary = _trees.first;
    await for (final node
        in primary.walk(policy: policy, cancellation: cancellation)) {
      final key = sourcePathCollisionKey(node.relativePath);
      if (_trees.length > 1 && merged.containsKey(key)) {
        throw ContractError('source.path_collision', node.relativePath,
            'Source paths collide after Unicode and case normalization.');
      }
      merged[key] = node;
      admit(node, primary, const []);
      yield node;
    }
    inventories.add(_SourceInventory(primary, Map.unmodifiable(merged)));
    for (final reference in _trees.skip(1)) {
      final nodes = <String, SourceNode>{};
      await for (final node in reference.walkSelected(
          relativePaths: sharedPaths,
          recursivePaths: _mediaRoots,
          policy: policy,
          cancellation: cancellation)) {
        final key = sourcePathCollisionKey(node.relativePath);
        if (nodes.containsKey(key)) {
          throw ContractError('source.path_collision', node.relativePath,
              'Supplemental paths collide after Unicode and case normalization.');
        }
        nodes[key] = node;
        if (policy.isExcluded(node.relativePath) || merged.containsKey(key)) {
          continue;
        }
        if (node.kind == SourceNodeKind.link ||
            node.kind == SourceNodeKind.special) {
          throw ContractError('source.shared.node_invalid', node.relativePath,
              'Supplemental inputs require regular files and directory ancestors without links.');
        }
      }
      final earlier = List<_SourceInventory>.unmodifiable(inventories);
      final files = nodes.values
          .where((node) =>
              _isCandidatePath(node.relativePath) &&
              !policy.isExcluded(node.relativePath) &&
              !merged.containsKey(sourcePathCollisionKey(node.relativePath)))
          .toList()
        ..sort((a, b) => a.relativePath.compareTo(b.relativePath));
      for (final file in files) {
        if (!isSupplementalFilePath(file.relativePath)) {
          throw ContractError('source.shared.path_conflict', file.relativePath,
              'Supplemental input casing must match the exact supported path.');
        }
        if (file.kind != SourceNodeKind.file) {
          throw ContractError('source.shared.node_invalid', file.relativePath,
              'Supplemental inputs require regular files.');
        }
        if (!sharedPaths.contains(file.relativePath)) {
          mediaFiles++;
          mediaBytes += file.byteLength;
          if (mediaFiles > maxSupplementalMediaFiles ||
              mediaBytes > maxSupplementalMediaBytes ||
              file.byteLength > maxSupplementalMediaFileBytes) {
            throw ContractError('source.shared.media_quota', file.relativePath,
                'Supplemental media exceeds its count or byte budget.');
          }
        }
        final segments = file.relativePath.split('/');
        for (var i = 1; i < segments.length; i++) {
          final parent = segments.take(i).join('/');
          final key = sourcePathCollisionKey(parent);
          for (final inventory in earlier) {
            final previous = inventory.nodes[key];
            if (previous != null &&
                (previous.kind != SourceNodeKind.directory ||
                    previous.relativePath != parent)) {
              throw ContractError('source.shared.path_conflict', parent,
                  'The supplemental path conflicts with a higher-priority ancestor.');
            }
          }
          final existing = merged[key];
          final ancestor = existing ?? nodes[key];
          if (ancestor == null ||
              ancestor.kind != SourceNodeKind.directory ||
              ancestor.relativePath != parent) {
            throw ContractError('source.shared.path_conflict', parent,
                'The supplemental path conflicts with a higher-priority ancestor.');
          }
          if (existing == null) {
            merged[key] = ancestor;
            admit(ancestor, reference, earlier);
            yield ancestor;
          }
        }
        merged[sourcePathCollisionKey(file.relativePath)] = file;
        _sharedOrigins[file.relativePath] = reference.rootPath;
        admit(file, reference, earlier);
        yield file;
      }
      inventories.add(_SourceInventory(reference, Map.unmodifiable(nodes)));
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
    await _verifyEarlier(node.relativePath, origin, cancellation);
    yield* origin.tree
        .read(node, maxBytes: maxBytes, cancellation: cancellation);
    await _verifyEarlier(node.relativePath, origin, cancellation);
  }

  Future<void> _verifyEarlier(String relativePath, _SourceOrigin origin,
      ScanCancellation cancellation) async {
    final selected = sourcePathCollisionKey(relativePath);
    for (final inventory in origin.earlier) {
      final observed = <String, String>{};
      await for (final node in inventory.tree.walkSelected(
          relativePaths: {relativePath},
          policy: origin.policy,
          cancellation: cancellation)) {
        final key = sourcePathCollisionKey(node.relativePath);
        if (observed.containsKey(key)) throw _changed(relativePath);
        observed[key] = _identity(node);
      }
      final segments = selected.split('/');
      final keys = [
        for (var index = 1; index <= segments.length; index++)
          segments.take(index).join('/')
      ];
      final expected = {
        for (final key in keys)
          if (inventory.nodes.containsKey(key))
            key: _identity(inventory.nodes[key]!)
      };
      if (observed.length != expected.length ||
          expected.entries.any((entry) => observed[entry.key] != entry.value)) {
        throw _changed(relativePath);
      }
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
              _sharedOrigins.containsKey(entry.relativePath) &&
              entry.sha256 != null)
          .map((entry) => ConverterSharedSourceFile(
              relativePath: entry.relativePath,
              referenceRootPath: _sharedOrigins[entry.relativePath]!,
              fileId: entry.fileId,
              sha256: entry.sha256!)));

  static ContractError _changed(String value) => ContractError('source.changed',
      value, 'A higher-priority source changed after inventory.');
  static String _identity(SourceNode node) =>
      '${node.relativePath}:${node.kind.name}:${node.byteLength}:${node.token}';
}

final class _SourceInventory {
  const _SourceInventory(this.tree, this.nodes);
  final MacOsSourceTree tree;
  final Map<String, SourceNode> nodes;
}

final class _SourceOrigin {
  const _SourceOrigin(this.tree, this.earlier, this.policy);
  final MacOsSourceTree tree;
  final List<_SourceInventory> earlier;
  final SourceScanPolicy policy;
}

final class ConverterSharedSourceFile {
  ConverterSharedSourceFile(
      {required this.relativePath,
      required this.referenceRootPath,
      required this.fileId,
      required this.sha256}) {
    validateSourceRelativePath(relativePath);
    if (!SupplementedSourceTree.isSupplementalFilePath(relativePath) ||
        !path.isAbsolute(referenceRootPath) ||
        referenceRootPath.contains('\u0000') ||
        referenceRootPath.length > 4096 ||
        path.normalize(referenceRootPath) != referenceRootPath) {
      throw ContractError('source.shared.reference_invalid', r'$',
          'Invalid supplemental source reference.');
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
          'Invalid supplemental source reference.');
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
        'sha256': sha256.value
      };
}

List<ConverterSharedSourceFile> validateSupplementalProvenance(
    List<ConverterSharedSourceFile> files, List<String> roots) {
  if (files.length > SupplementedSourceTree.maxSupplementalFiles ||
      files
              .where((file) => !SupplementedSourceTree.sharedPaths
                  .contains(file.relativePath))
              .length >
          SupplementedSourceTree.maxSupplementalMediaFiles ||
      files
              .map((file) => sourcePathCollisionKey(file.relativePath))
              .toSet()
              .length !=
          files.length ||
      files.any((file) => !roots.contains(file.referenceRootPath))) {
    throw ContractError('source.shared.reference_invalid', r'$',
        'Supplemental provenance must be unique, bounded and bound to selected roots.');
  }
  final ordered = files.toList()
    ..sort((a, b) => a.relativePath.compareTo(b.relativePath));
  canonicalJsonOf(ordered.map((file) => file.toJson()).toList(),
      limits: const ContractLimits(maxTextCodeUnits: 2097152));
  return List.unmodifiable(ordered);
}
