import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

enum BattleCombatantSpriteFacing {
  front,
  back,
}

final class BattleCombatantSpriteSpec {
  const BattleCombatantSpriteSpec({
    required this.facing,
    this.explicitImageAbsolutePath,
    this.explicitAnimatedImageAbsolutePath,
  });

  final BattleCombatantSpriteFacing facing;
  final String? explicitImageAbsolutePath;
  final String? explicitAnimatedImageAbsolutePath;

  bool get hasExplicitImage =>
      (explicitImageAbsolutePath?.trim().isNotEmpty ?? false);
}

/// Résout un sprite battle front/back depuis les médias Pokémon du projet.
///
/// Cette lecture reste volontairement côté runtime :
/// - `map_battle` ne reçoit aucune connaissance d'assets ;
/// - les chemins sprites ne polluent pas `BattleCombatantData` ;
/// - le resolver lit seulement le JSON média déjà authoré dans le projet.
final class BattlePokemonSpriteResolver {
  BattlePokemonSpriteResolver({
    required this.manifest,
    required this.projectRootDirectory,
  });

  final ProjectManifest manifest;
  final String projectRootDirectory;
  final Map<String, Future<_BattlePokemonMediaRecord?>> _mediaCache =
      <String, Future<_BattlePokemonMediaRecord?>>{};
  late final Future<String?> _canonicalProjectRoot = _resolveProjectRoot();
  int _actualMediaReadCount = 0;

  int get debugActualMediaReadCount => _actualMediaReadCount;

  Future<BattleCombatantSpriteSpec> resolve({
    required String speciesId,
    required bool isPlayerSide,
  }) async {
    final trimmedSpeciesId = speciesId.trim();
    final facing = isPlayerSide
        ? BattleCombatantSpriteFacing.back
        : BattleCombatantSpriteFacing.front;
    if (!_isSafeSpeciesId(trimmedSpeciesId)) {
      return BattleCombatantSpriteSpec(facing: facing);
    }

    final media = await _mediaCache.putIfAbsent(
      trimmedSpeciesId,
      () => _readMedia(trimmedSpeciesId),
    );
    if (media == null) {
      return BattleCombatantSpriteSpec(facing: facing);
    }

    final relativePath = isPlayerSide ? media.backStatic : media.frontStatic;
    final absolutePath = await _resolveProjectFile(
      relativePath,
      allowMissing: true,
    );
    final animatedPath = isPlayerSide
        ? media.backAnimated
        : media.frontAnimated;
    final animatedAbsolutePath = await _resolveProjectFile(animatedPath);

    return BattleCombatantSpriteSpec(
      facing: facing,
      explicitImageAbsolutePath: absolutePath,
      explicitAnimatedImageAbsolutePath: animatedAbsolutePath,
    );
  }

  Future<String?> resolveCry(String speciesId) async {
    final id = speciesId.trim().toLowerCase();
    if (!_isSafeSpeciesId(id)) return null;
    final media = await _mediaCache.putIfAbsent(id, () => _readMedia(id));
    final relativePath = media?.cry;
    final authored = await _resolveProjectFile(
      relativePath,
      allowMissing: true,
    );
    if (authored != null) return authored;
    for (final extension in const ['.ogg', '.mp3', '.wav']) {
      final path = await _resolveProjectFile(
        'assets/pokemon/cries/$id$extension',
      );
      if (path != null) return path;
    }
    return null;
  }

  Future<_BattlePokemonMediaRecord?> _readMedia(String speciesId) async {
    final rawDirectory = manifest.pokemon.mediaDir.trim();
    final directory = rawDirectory.isEmpty || rawDirectory == '.'
        ? ''
        : _normalizeProjectRelativePath(rawDirectory);
    if (directory == null) return null;
    final relativePath = directory.isEmpty
        ? '$speciesId.json'
        : p.posix.join(directory, '$speciesId.json');
    final path = await _resolveProjectFile(relativePath);
    if (path == null) {
      return null;
    }
    _actualMediaReadCount += 1;

    final decoded = jsonDecode(await File(path).readAsString());
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final variants = (decoded['variants'] as Map?)?.cast<String, dynamic>();
    if (variants == null || variants.isEmpty) {
      return null;
    }

    final defaultFormId = (decoded['defaultFormId'] as String?)?.trim();
    Map<String, dynamic>? candidateVariant =
        _readVariantMap(variants[defaultFormId]) ??
            _readVariantMap(variants['base']);
    if (candidateVariant == null) {
      for (final rawVariant in variants.values) {
        candidateVariant = _readVariantMap(rawVariant);
        if (candidateVariant != null) {
          break;
        }
      }
    }
    if (candidateVariant == null) {
      return null;
    }

    final frontAnimated = candidateVariant['frontAnimated'];
    final backAnimated = candidateVariant['backAnimated'];
    final readAnimated = decoded['schemaVersion'] == 2;
    return _BattlePokemonMediaRecord(
      frontStatic: _normalizeProjectRelativePath(
        candidateVariant['frontStatic'] as String?,
      ),
      backStatic: _normalizeProjectRelativePath(
        candidateVariant['backStatic'] as String?,
      ),
      frontAnimated: readAnimated && frontAnimated is String
          ? _normalizeProjectRelativePath(frontAnimated)
          : null,
      backAnimated: readAnimated && backAnimated is String
          ? _normalizeProjectRelativePath(backAnimated)
          : null,
      cry: _normalizeProjectRelativePath(candidateVariant['cry'] as String?),
    );
  }

  Map<String, dynamic>? _readVariantMap(Object? rawVariant) {
    if (rawVariant is! Map) {
      return null;
    }
    return rawVariant.cast<String, dynamic>();
  }

  String? _normalizeProjectRelativePath(String? rawPath) {
    final trimmed = rawPath?.trim() ?? '';
    if (trimmed.isEmpty ||
        trimmed.contains('\u0000') ||
        p.windows.isAbsolute(trimmed) ||
        Uri.tryParse(trimmed)?.hasScheme == true) {
      return null;
    }
    final normalized = p.posix.normalize(trimmed.replaceAll(r'\', '/'));
    if (normalized.startsWith('..') || p.posix.isAbsolute(normalized)) {
      return null;
    }
    return normalized;
  }

  bool _isSafeSpeciesId(String id) =>
      id.isNotEmpty &&
      id != '.' &&
      id != '..' &&
      !id.contains('/') &&
      !id.contains(r'\') &&
      !id.contains('\u0000');

  Future<String?> _resolveProjectRoot() async {
    try {
      return await Directory(projectRootDirectory).resolveSymbolicLinks();
    } on FileSystemException {
      return null;
    }
  }

  Future<String?> _resolveProjectFile(
    String? rawPath, {
    bool allowMissing = false,
  }) async {
    final relativePath = _normalizeProjectRelativePath(rawPath);
    if (relativePath == null || relativePath == '.') return null;
    final root = await _canonicalProjectRoot;
    if (root == null) return null;
    try {
      final segments = p.posix.split(relativePath);
      var current = root;
      for (var index = 0; index < segments.length; index++) {
        current = p.join(current, segments[index]);
        if (!p.isWithin(root, current)) return null;
        final type = await FileSystemEntity.type(current, followLinks: false);
        if (type == FileSystemEntityType.notFound) {
          if (!allowMissing) return null;
          final path = p.normalize(
            p.joinAll([current, ...segments.skip(index + 1)]),
          );
          return p.isWithin(root, path) ? path : null;
        }
        if (type == FileSystemEntityType.link) {
          current = await Link(current).resolveSymbolicLinks();
          if (current != root && !p.isWithin(root, current)) return null;
        }
      }
      if (!allowMissing && !await File(current).exists()) return null;
      return current;
    } on FileSystemException {
      return null;
    }
  }
}

final class _BattlePokemonMediaRecord {
  const _BattlePokemonMediaRecord({
    required this.frontStatic,
    required this.backStatic,
    required this.frontAnimated,
    required this.backAnimated,
    required this.cry,
  });

  final String? frontStatic;
  final String? backStatic;
  final String? frontAnimated;
  final String? backAnimated;
  final String? cry;
}
