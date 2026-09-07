import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

typedef _ItemIconBundle = ({
  Archive archive,
  String cacheKey,
  Map<String, String> aliases,
});

final class RuntimeBundledItemIcons {
  RuntimeBundledItemIcons({
    AssetBundle? assetBundle,
    Future<Directory> Function()? cacheDirectory,
  })  : _assetBundle = assetBundle ?? rootBundle,
        _cacheDirectory = cacheDirectory ?? getTemporaryDirectory;

  static final shared = RuntimeBundledItemIcons();
  static const _assetRoot = 'packages/map_runtime/assets/menu/items';

  final AssetBundle _assetBundle;
  final Future<Directory> Function() _cacheDirectory;
  Future<_ItemIconBundle>? _bundle;
  final Map<String, Future<String?>> _pending = {};

  Future<String?> resolve(String itemId) async {
    final canonicalId = itemId.replaceAll('_', '-');
    if (!RegExp(r'^[a-z0-9][a-z0-9-]*$').hasMatch(canonicalId)) return null;
    try {
      final bundle = await (_bundle ??= _loadBundle());
      final assetId = bundle.aliases[canonicalId] ?? canonicalId;
      if (!RegExp(r'^[a-z0-9][a-z0-9-]*$').hasMatch(assetId)) return null;
      final pending = _pending[assetId];
      if (pending != null) return await pending;
      final future = _resolve(assetId, bundle);
      _pending[assetId] = future;
      try {
        return await future;
      } finally {
        _pending.remove(assetId);
      }
    } on Object {
      _bundle = null;
      return null;
    }
  }

  Future<String?> _resolve(String assetId, _ItemIconBundle bundle) async {
    final image = bundle.archive.findFile('$assetId.png');
    if (image == null || !image.isFile) return null;
    final temporary = await _cacheDirectory();
    var root = await temporary.resolveSymbolicLinks();
    for (final segment in ['pokemap-menu-item-icons', bundle.cacheKey]) {
      root = p.join(root, segment);
      final type = await FileSystemEntity.type(root, followLinks: false);
      if (type == FileSystemEntityType.link ||
          (type != FileSystemEntityType.notFound &&
              type != FileSystemEntityType.directory)) {
        return null;
      }
      await Directory(root).create();
    }
    final file = File(p.join(root, '$assetId.png'));
    if (await FileSystemEntity.type(file.path, followLinks: false) ==
        FileSystemEntityType.link) {
      return null;
    }
    final bytes = image.content;
    if (!await file.exists() || !_sameBytes(await file.readAsBytes(), bytes)) {
      await file.writeAsBytes(bytes, flush: true);
    }
    return file.path;
  }

  Future<_ItemIconBundle> _loadBundle() async {
    final manifest = jsonDecode(
      await _assetBundle.loadString('$_assetRoot/manifest.json'),
    ) as Map<String, dynamic>;
    final cacheKey = manifest['archiveSha256'] as String;
    if (manifest['schemaVersion'] != 1 ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(cacheKey)) {
      throw const FormatException('Invalid item icon bundle manifest.');
    }
    final data = await _assetBundle.load('$_assetRoot/icons.zip');
    return (
      archive: ZipDecoder().decodeBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        verify: true,
      ),
      cacheKey: cacheKey,
      aliases: (manifest['aliases'] as Map<String, dynamic>? ?? const {})
          .cast<String, String>(),
    );
  }

  bool _sameBytes(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}
