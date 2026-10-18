import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'dialogue_runtime_models.dart';
import 'runtime_project_catalog.dart';

enum DialoguePortraitResolutionCode {
  catalogUnavailable,
  characterUnknown,
  portraitStateUnknown,
  portraitUnassigned,
  assetUnknown,
  assetInvalid,
  assetMissing,
}

final class DialoguePortraitResolutionDiagnostic {
  const DialoguePortraitResolutionDiagnostic({
    required this.code,
    required this.characterId,
    required this.portraitStateId,
    this.assetId,
  });

  final DialoguePortraitResolutionCode code;
  final String characterId;
  final String portraitStateId;
  final String? assetId;
}

final class ResolvedDialoguePortrait {
  const ResolvedDialoguePortrait({
    required this.characterId,
    required this.characterName,
    required this.portraitStateId,
    required this.portraitStateName,
    required this.assetId,
    required this.absoluteFilePath,
    required this.fitMode,
  });

  final String characterId;
  final String characterName;
  final String portraitStateId;
  final String portraitStateName;
  final String assetId;
  final String absoluteFilePath;
  final CharacterPortraitFitMode fitMode;
}

typedef DialoguePortraitLookup = ResolvedDialoguePortrait? Function({
  required String characterId,
  required String portraitStateId,
});

typedef DialoguePortraitCatalogLoader = Future<AssetCatalog?> Function(
  String projectRootDirectory,
);

final class DialoguePortraitResolver {
  DialoguePortraitResolver({
    required this.manifest,
    required String projectRootDirectory,
    this.cacheCapacity = 64,
    this.preloadLimit = 16,
    DialoguePortraitCatalogLoader? loadCatalog,
    bool Function(String path)? fileExists,
    this.onDiagnostic,
  }) : projectRootDirectory = p.normalize(p.absolute(projectRootDirectory)),
       _loadCatalog = loadCatalog ?? _catalogLoaderFor(manifest),
       _fileExists = fileExists ?? FileSystemEntity.isFileSync {
    if (cacheCapacity < 1) {
      throw ArgumentError.value(cacheCapacity, 'cacheCapacity');
    }
    if (preloadLimit < 0) {
      throw ArgumentError.value(preloadLimit, 'preloadLimit');
    }
  }

  final ProjectManifest manifest;
  final String projectRootDirectory;
  final int cacheCapacity;
  final int preloadLimit;
  final DialoguePortraitCatalogLoader _loadCatalog;
  final bool Function(String path) _fileExists;
  final void Function(DialoguePortraitResolutionDiagnostic diagnostic)?
  onDiagnostic;
  final Map<String, ResolvedDialoguePortrait?> _cache =
      <String, ResolvedDialoguePortrait?>{};
  final _hydratedCharacters =
      <
        String,
        ({
          ProjectCharacterEntry character,
          Map<String, CharacterPortraitStateDefinition> states,
        })?
      >{};
  AssetCatalog? _catalog;
  bool _catalogLoaded = false;
  int _preloadGeneration = 0;

  int get cachedResolutionCount => _cache.length;

  Future<void> preload(DialogueSession session) async {
    final generation = ++_preloadGeneration;
    _hydratedCharacters.clear();
    _cache.clear();
    final references =
        <String, ({String characterId, String portraitStateId})>{};
    for (final node in session.nodes) {
      _collectReferences(node.steps, references);
    }
    if (references.isEmpty) return;
    await _ensureCatalogLoaded();
    await _hydrateCharacters(
      references.values.map((reference) => reference.characterId),
      generation: generation,
    );
    if (generation != _preloadGeneration) return;
    if (!_catalogLoaded || preloadLimit == 0) return;
    for (final reference in references.values.take(preloadLimit)) {
      resolve(
        characterId: reference.characterId,
        portraitStateId: reference.portraitStateId,
      );
    }
  }

  ResolvedDialoguePortrait? resolve({
    required String characterId,
    required String portraitStateId,
  }) {
    if (!_catalogLoaded) return null;
    final cacheKey = '$characterId\u0000$portraitStateId';
    if (_cache.containsKey(cacheKey)) {
      final cached = _cache.remove(cacheKey);
      _cache[cacheKey] = cached;
      return cached;
    }
    final resolved = _resolveUncached(
      characterId: characterId,
      portraitStateId: portraitStateId,
    );
    _cache[cacheKey] = resolved;
    while (_cache.length > cacheCapacity) {
      _cache.remove(_cache.keys.first);
    }
    return resolved;
  }

  Future<void> ensureCatalogLoaded({
    Iterable<String> characterIds = const [],
  }) async {
    await _ensureCatalogLoaded();
    await _hydrateCharacters(characterIds, maximumCharacters: 64);
  }

  Future<void> _hydrateCharacters(
    Iterable<String> characterIds, {
    int? maximumCharacters,
    int? generation,
  }) async {
    final owner = RuntimeProjectCatalog.ownerOf(manifest);
    if (owner == null) return;
    for (final id in characterIds.toSet()) {
      if (manifest.characters.any((character) => character.id == id) ||
          _hydratedCharacters.containsKey(id)) {
        continue;
      }
      try {
        final view = await owner.manifestForCharacter(id);
        if (generation != null && generation != _preloadGeneration) return;
        final character = view.characters.firstWhere((value) => value.id == id);
        _hydratedCharacters[id] = (
          character: character,
          states: {
            for (final state in view.characterStudioCatalog.portraitStates)
              if (character.portraits.any(
                (portrait) => portrait.portraitStateId == state.id,
              ))
                state.id: state,
          },
        );
      } on RuntimeCatalogDefinitionMissingException catch (error) {
        if (generation != null && generation != _preloadGeneration) return;
        if (error.key !=
            CatalogDefinitionKey(CatalogDefinitionKind.character, id)) {
          rethrow;
        }
        _hydratedCharacters[id] = null;
      }
      _cache.removeWhere((key, _) => key.startsWith('$id\u0000'));
      if (maximumCharacters != null) {
        while (_hydratedCharacters.length > maximumCharacters) {
          _hydratedCharacters.remove(_hydratedCharacters.keys.first);
        }
      }
    }
    if (maximumCharacters != null) {
      while (_hydratedCharacters.length > maximumCharacters) {
        _hydratedCharacters.remove(_hydratedCharacters.keys.first);
      }
    }
  }

  Future<void> _ensureCatalogLoaded() async {
    if (_catalogLoaded) return;
    try {
      _catalog = await _loadCatalog(projectRootDirectory);
    } on Object {
      _catalog = null;
    }
    _catalogLoaded = true;
    if (_catalog == null) {
      _emit(
        DialoguePortraitResolutionCode.catalogUnavailable,
        characterId: '',
        portraitStateId: '',
      );
    }
  }

  ResolvedDialoguePortrait? _resolveUncached({
    required String characterId,
    required String portraitStateId,
  }) {
    final hydrated = _hydratedCharacters[characterId];
    final character =
        _firstWhereOrNull(
          manifest.characters,
          (value) => value.id == characterId,
        ) ??
        hydrated?.character;
    if (character == null) {
      _emit(
        DialoguePortraitResolutionCode.characterUnknown,
        characterId: characterId,
        portraitStateId: portraitStateId,
      );
      return null;
    }
    final state =
        _firstWhereOrNull(
          manifest.characterStudioCatalog.portraitStates,
          (value) => value.id == portraitStateId,
        ) ??
        hydrated?.states[portraitStateId];
    if (state == null) {
      _emit(
        DialoguePortraitResolutionCode.portraitStateUnknown,
        characterId: characterId,
        portraitStateId: portraitStateId,
      );
      return null;
    }
    final variant = _firstWhereOrNull(
      character.portraits,
      (value) => value.portraitStateId == portraitStateId,
    );
    if (variant == null) {
      _emit(
        DialoguePortraitResolutionCode.portraitUnassigned,
        characterId: characterId,
        portraitStateId: portraitStateId,
      );
      return null;
    }
    final asset = _catalog?.find(variant.assetId);
    if (asset == null) {
      _emit(
        DialoguePortraitResolutionCode.assetUnknown,
        characterId: characterId,
        portraitStateId: portraitStateId,
        assetId: variant.assetId,
      );
      return null;
    }
    if (asset.artifact.mediaType != 'image/png') {
      _emit(
        DialoguePortraitResolutionCode.assetInvalid,
        characterId: characterId,
        portraitStateId: portraitStateId,
        assetId: variant.assetId,
      );
      return null;
    }
    final absolutePath = p.normalize(
      p.join(projectRootDirectory, assetBlobStorageKey(asset.artifact)),
    );
    if (!p.isWithin(projectRootDirectory, absolutePath)) {
      _emit(
        DialoguePortraitResolutionCode.assetInvalid,
        characterId: characterId,
        portraitStateId: portraitStateId,
        assetId: variant.assetId,
      );
      return null;
    }
    if (!_fileExists(absolutePath)) {
      _emit(
        DialoguePortraitResolutionCode.assetMissing,
        characterId: characterId,
        portraitStateId: portraitStateId,
        assetId: variant.assetId,
      );
      return null;
    }
    return ResolvedDialoguePortrait(
      characterId: character.id,
      characterName: character.name,
      portraitStateId: state.id,
      portraitStateName: state.displayName,
      assetId: asset.id,
      absoluteFilePath: absolutePath,
      fitMode: variant.fitMode,
    );
  }

  void _emit(
    DialoguePortraitResolutionCode code, {
    required String characterId,
    required String portraitStateId,
    String? assetId,
  }) {
    onDiagnostic?.call(
      DialoguePortraitResolutionDiagnostic(
        code: code,
        characterId: characterId,
        portraitStateId: portraitStateId,
        assetId: assetId,
      ),
    );
  }
}

DialoguePortraitCatalogLoader _catalogLoaderFor(ProjectManifest manifest) {
  final owner = RuntimeProjectCatalog.ownerOf(manifest);
  return owner == null
      ? _loadRuntimeAssetCatalog
      : (_) => owner.loadAssetCatalog();
}

Future<AssetCatalog?> _loadRuntimeAssetCatalog(String projectRoot) async {
  final file = File(p.join(projectRoot, assetCatalogStorageKey));
  if (!await file.exists()) return null;
  final decoded = jsonDecode(await file.readAsString());
  if (decoded is! Map) throw const FormatException('Expected JSON object.');
  return AssetCatalog.fromJson(Map<String, dynamic>.from(decoded));
}

void _collectReferences(
  List<YarnStep> steps,
  Map<String, ({String characterId, String portraitStateId})> output,
) {
  for (final step in steps) {
    switch (step) {
      case YarnStepLine(:final characterId, :final portraitStateId):
        if (characterId != null && portraitStateId != null) {
          output.putIfAbsent(
            '$characterId\u0000$portraitStateId',
            () => (characterId: characterId, portraitStateId: portraitStateId),
          );
        }
      case YarnStepChoiceBlock(:final choices):
        for (final choice in choices) {
          _collectReferences(choice.steps, output);
        }
      case YarnStepJump():
        break;
    }
  }
}

T? _firstWhereOrNull<T>(Iterable<T> values, bool Function(T value) test) {
  for (final value in values) {
    if (test(value)) return value;
  }
  return null;
}
