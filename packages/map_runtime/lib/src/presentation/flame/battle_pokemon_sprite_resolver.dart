import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../application/runtime_battle_presentation.dart';

enum BattleCombatantSpriteFacing { front, back }

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
    RuntimeBattleVisualIdentity? visualIdentity,
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

    final identity = visualIdentity?.speciesId.trim() == trimmedSpeciesId
        ? visualIdentity
        : null;
    final requestedForm = identity?.formId?.trim();
    final requestedVariant = _readVariantMap(
      requestedForm == null || requestedForm.isEmpty
          ? null
          : media.variants[requestedForm],
    );
    final defaultVariant = _defaultVariant(media);
    final variant = requestedVariant ?? defaultVariant;
    if (variant == null) return BattleCombatantSpriteSpec(facing: facing);
    var paths = await _resolveVariant(
      variant,
      media: media,
      isPlayerSide: isPlayerSide,
      identity:
          requestedForm != null &&
              requestedForm.isNotEmpty &&
              requestedVariant == null
          ? null
          : identity,
      allowMissingStatic: requestedVariant == null,
    );
    if (requestedVariant != null &&
        defaultVariant != null &&
        paths.staticPath == null &&
        paths.animatedPath == null) {
      paths = await _resolveVariant(
        defaultVariant,
        media: media,
        isPlayerSide: isPlayerSide,
        allowMissingStatic: true,
      );
    }
    return BattleCombatantSpriteSpec(
      facing: facing,
      explicitImageAbsolutePath: paths.staticPath,
      explicitAnimatedImageAbsolutePath: paths.animatedPath,
    );
  }

  Future<({String? staticPath, String? animatedPath})> _resolveVariant(
    Map<String, dynamic> variant, {
    required _BattlePokemonMediaRecord media,
    required bool isPlayerSide,
    required bool allowMissingStatic,
    RuntimeBattleVisualIdentity? identity,
  }) async {
    final prefix = isPlayerSide ? 'back' : 'front';
    final shiny = identity?.isShiny == true;
    final female = identity?.genderId == 'female';
    String? relativeField(String field) {
      final value = variant['$prefix$field'];
      return value is String ? _normalizeProjectRelativePath(value) : null;
    }

    String? animatedAbsolutePath;
    if (media.readAnimated) {
      final candidates = <String>[
        if (shiny && female) 'ShinyFemaleAnimated',
        if (shiny) 'ShinyAnimated',
        if (!shiny && identity?.isShiny != null && female) 'FemaleAnimated',
        if (!shiny) 'Animated',
      ];
      for (final candidate in candidates) {
        animatedAbsolutePath = await _resolveProjectFile(
          relativeField(candidate),
        );
        if (animatedAbsolutePath != null) break;
      }
    }
    final shinyStaticPath = shiny
        ? await _resolveProjectFile(relativeField('ShinyStatic'))
        : null;
    final useShiny =
        shiny && (animatedAbsolutePath != null || shinyStaticPath != null);
    final absolutePath = useShiny
        ? shinyStaticPath
        : await _resolveProjectFile(
            relativeField('Static'),
            allowMissing: allowMissingStatic,
          );
    if (shiny && !useShiny && media.readAnimated) {
      animatedAbsolutePath = await _resolveProjectFile(
        relativeField('Animated'),
      );
    }

    return (staticPath: absolutePath, animatedPath: animatedAbsolutePath);
  }

  Future<String?> resolveCry(String speciesId) async {
    final id = speciesId.trim().toLowerCase();
    if (!_isSafeSpeciesId(id)) return null;
    final media = await _mediaCache.putIfAbsent(id, () => _readMedia(id));
    final rawCry = media == null ? null : _defaultVariant(media)?['cry'];
    final relativePath = rawCry is String ? rawCry : null;
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
    final rawSpeciesDirectory = manifest.pokemon.speciesDir.trim();
    final speciesDirectory = rawSpeciesDirectory.isEmpty
        ? 'data/pokemon/species'
        : _normalizeProjectRelativePath(rawSpeciesDirectory);
    if (speciesDirectory == null) return null;
    final speciesPath = await _resolveProjectFile(
      p.posix.join(speciesDirectory, '$speciesId.json'),
    );
    var mediaId = speciesId;
    String? speciesFormId;
    if (speciesPath != null) {
      final decoded = jsonDecode(await File(speciesPath).readAsString());
      if (decoded is! Map<String, dynamic>) return null;
      final species = PokemonSpeciesFile.fromJson(decoded);
      if (species.id != speciesId) return null;
      if (species.mediaRef.isNotEmpty) mediaId = species.mediaRef;
      speciesFormId = species.forms.formId;
    }
    if (!_isSafeSpeciesId(mediaId) ||
        p.windows.isAbsolute(mediaId) ||
        Uri.tryParse(mediaId)?.hasScheme == true) {
      return null;
    }
    final rawDirectory = manifest.pokemon.mediaDir.trim();
    final directory = rawDirectory.isEmpty || rawDirectory == '.'
        ? ''
        : _normalizeProjectRelativePath(rawDirectory);
    if (directory == null) return null;
    final relativePath = directory.isEmpty
        ? '$mediaId.json'
        : p.posix.join(directory, '$mediaId.json');
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

    return _BattlePokemonMediaRecord(
      variants: variants,
      defaultFormId: speciesFormId?.isNotEmpty == true &&
              variants[speciesFormId] is Map
          ? speciesFormId
          : (decoded['defaultFormId'] as String?)?.trim(),
      readAnimated: decoded['schemaVersion'] == 2,
    );
  }

  Map<String, dynamic>? _defaultVariant(_BattlePokemonMediaRecord media) {
    final selected =
        _readVariantMap(media.variants[media.defaultFormId]) ??
        _readVariantMap(media.variants['base']);
    if (selected != null) return selected;
    for (final rawVariant in media.variants.values) {
      final variant = _readVariantMap(rawVariant);
      if (variant != null) return variant;
    }
    return null;
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
    required this.variants,
    required this.defaultFormId,
    required this.readAnimated,
  });

  final Map<String, dynamic> variants;
  final String? defaultFormId;
  final bool readAnimated;
}
