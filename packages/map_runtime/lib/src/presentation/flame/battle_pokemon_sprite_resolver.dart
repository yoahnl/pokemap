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
  });

  final BattleCombatantSpriteFacing facing;
  final String? explicitImageAbsolutePath;

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
    if (trimmedSpeciesId.isEmpty) {
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
    if (relativePath == null || relativePath.isEmpty) {
      return BattleCombatantSpriteSpec(facing: facing);
    }

    return BattleCombatantSpriteSpec(
      facing: facing,
      explicitImageAbsolutePath: p.normalize(
        p.join(projectRootDirectory, relativePath),
      ),
    );
  }

  Future<String?> resolveCry(String speciesId) async {
    final id = speciesId.trim().toLowerCase();
    if (id.isEmpty || id.contains('/') || id.contains(r'\') || id == '..') return null;
    final media = await _mediaCache.putIfAbsent(id, () => _readMedia(id));
    final relativePath = media?.cry;
    if (relativePath != null) return p.normalize(p.join(projectRootDirectory, relativePath));
    for (final extension in const ['.ogg', '.mp3', '.wav']) {
      final path = p.join(projectRootDirectory, 'assets', 'pokemon', 'cries', '$id$extension');
      if (await File(path).exists()) return path;
    }
    return null;
  }

  Future<_BattlePokemonMediaRecord?> _readMedia(String speciesId) async {
    final mediaFile = File(
      p.join(projectRootDirectory, manifest.pokemon.mediaDir, '$speciesId.json'),
    );
    if (!await mediaFile.exists()) {
      return null;
    }
    _actualMediaReadCount += 1;

    final decoded = jsonDecode(await mediaFile.readAsString());
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

    return _BattlePokemonMediaRecord(
      frontStatic: _normalizeProjectRelativePath(
        candidateVariant['frontStatic'] as String?,
      ),
      backStatic: _normalizeProjectRelativePath(
        candidateVariant['backStatic'] as String?,
      ),
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

final class _BattlePokemonMediaRecord {
  const _BattlePokemonMediaRecord({
    required this.frontStatic,
    required this.backStatic,
    required this.cry,
  });

  final String? frontStatic;
  final String? backStatic;
  final String? cry;
}
