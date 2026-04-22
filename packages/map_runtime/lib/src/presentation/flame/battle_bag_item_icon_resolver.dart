import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

final class BattleBagItemIconSpec {
  const BattleBagItemIconSpec({
    required this.itemId,
    this.explicitImageAbsolutePath,
  });

  final String itemId;
  final String? explicitImageAbsolutePath;

  bool get hasExplicitImage =>
      (explicitImageAbsolutePath?.trim().isNotEmpty ?? false);
}

/// Résout les icônes d'items battle depuis le catalogue items local du projet.
///
/// Frontière volontaire :
/// - la source de vérité visuelle reste le workspace projet ;
/// - le runtime lit seulement `items.json` + `localSpritePath` ;
/// - ce seam reste purement présentational et best-effort ;
/// - un sprite manquant ne doit jamais casser le flow de combat.
final class BattleBagItemIconResolver {
  BattleBagItemIconResolver({
    required this.manifest,
    required this.projectRootDirectory,
  });

  final ProjectManifest manifest;
  final String projectRootDirectory;
  final Map<String, Future<Map<String, String?>>> _catalogCache =
      <String, Future<Map<String, String?>>>{};

  Future<BattleBagItemIconSpec> resolve(String itemId) async {
    final trimmedItemId = itemId.trim();
    if (trimmedItemId.isEmpty) {
      return const BattleBagItemIconSpec(itemId: '');
    }

    final catalog = await _loadCatalog();
    final relativePath = catalog[trimmedItemId];
    if (relativePath == null || relativePath.isEmpty) {
      return BattleBagItemIconSpec(itemId: trimmedItemId);
    }

    return BattleBagItemIconSpec(
      itemId: trimmedItemId,
      explicitImageAbsolutePath: p.normalize(
        p.join(projectRootDirectory, relativePath),
      ),
    );
  }

  Future<Map<String, String?>> _loadCatalog() async {
    final relativePath = manifest.pokemon.catalogFiles['items']?.trim() ??
        'data/pokemon/catalogs/items.json';
    final cacheKey =
        '${p.normalize(projectRootDirectory)}|${p.normalize(relativePath)}';
    final cached = _catalogCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final future = _readCatalog(relativePath);
    _catalogCache[cacheKey] = future;
    try {
      return await future;
    } catch (_) {
      final current = _catalogCache[cacheKey];
      if (identical(current, future)) {
        _catalogCache.remove(cacheKey);
      }
      rethrow;
    }
  }

  Future<Map<String, String?>> _readCatalog(String relativePath) async {
    final file = File(_resolveProjectPath(relativePath));
    if (!await file.exists()) {
      return const <String, String?>{};
    }

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        return const <String, String?>{};
      }
      final rawEntries = decoded['entries'];
      if (rawEntries is! List) {
        return const <String, String?>{};
      }

      final pathsByItemId = <String, String?>{};
      for (final rawEntry in rawEntries) {
        if (rawEntry is! Map) {
          continue;
        }
        final entry = rawEntry.cast<String, dynamic>();
        final itemId = (entry['id'] as String?)?.trim() ?? '';
        if (itemId.isEmpty) {
          continue;
        }
        pathsByItemId[itemId] = _normalizeProjectRelativePath(
          (entry['localSpritePath'] as String?)?.trim(),
        );
      }
      return Map<String, String?>.unmodifiable(pathsByItemId);
    } catch (_) {
      return const <String, String?>{};
    }
  }

  String _resolveProjectPath(String relativeOrAbsolutePath) {
    if (p.isAbsolute(relativeOrAbsolutePath)) {
      return p.normalize(relativeOrAbsolutePath);
    }
    return p.normalize(p.join(projectRootDirectory, relativeOrAbsolutePath));
  }

  String? _normalizeProjectRelativePath(String? rawPath) {
    final trimmed = rawPath?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }
    final normalized = p.posix.normalize(trimmed.replaceAll(r'\', '/'));
    if (normalized.startsWith('..') || p.isAbsolute(normalized)) {
      return null;
    }
    return normalized;
  }
}
