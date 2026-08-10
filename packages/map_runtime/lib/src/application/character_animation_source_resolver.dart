import 'dart:io';
import 'dart:ui';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

String characterAnimationRuntimeImageId(String sourceAssetId) =>
    'character-animation:${sourceAssetId.trim()}';

enum CharacterAnimationSourceDiagnosticCode {
  dedicatedSourceUnavailable,
  assetUnknown,
  assetInvalid,
  assetMissing,
}

final class CharacterAnimationSourceDiagnostic {
  const CharacterAnimationSourceDiagnostic({
    required this.code,
    required this.characterId,
    required this.sourceAssetId,
    this.state,
    this.direction,
  });

  final CharacterAnimationSourceDiagnosticCode code;
  final String characterId;
  final String sourceAssetId;
  final CharacterAnimationState? state;
  final EntityFacing? direction;
}

final class ResolvedCharacterAnimationFrameSource {
  const ResolvedCharacterAnimationFrameSource({
    required this.imageId,
    required this.sourceRect,
    required this.usesLegacyGrid,
  });

  final String imageId;
  final Rect sourceRect;
  final bool usesLegacyGrid;
}

final class CharacterAnimationSourceResolver {
  CharacterAnimationSourceResolver({this.onDiagnostic});

  final void Function(CharacterAnimationSourceDiagnostic diagnostic)?
      onDiagnostic;
  final Set<String> _emittedDiagnostics = <String>{};

  ResolvedCharacterAnimationFrameSource? resolveFrame({
    required ProjectCharacterEntry character,
    required CharacterAnimation animation,
    required CharacterAnimationFrame frame,
    required int tileWidth,
    required int tileHeight,
    required Set<String> availableImageIds,
  }) {
    final sourceAssetId = animation.sourceAssetId?.trim();
    if (sourceAssetId != null && sourceAssetId.isNotEmpty) {
      final runtimeImageId = characterAnimationRuntimeImageId(sourceAssetId);
      if (!availableImageIds.contains(runtimeImageId)) {
        _emitOnce(
          CharacterAnimationSourceDiagnostic(
            code: CharacterAnimationSourceDiagnosticCode
                .dedicatedSourceUnavailable,
            characterId: character.id,
            sourceAssetId: sourceAssetId,
            state: animation.state,
            direction: animation.direction,
          ),
        );
        return null;
      }
      final source = frame.source;
      return ResolvedCharacterAnimationFrameSource(
        imageId: runtimeImageId,
        sourceRect: Rect.fromLTWH(
          source.x.toDouble(),
          source.y.toDouble(),
          source.width.toDouble(),
          source.height.toDouble(),
        ),
        usesLegacyGrid: false,
      );
    }
    final width = character.frameWidth.clamp(2, 1 << 20) * tileWidth;
    final height = character.frameHeight.clamp(2, 1 << 20) * tileHeight;
    return ResolvedCharacterAnimationFrameSource(
      imageId: character.tilesetId,
      sourceRect: Rect.fromLTWH(
        (frame.source.x * width).toDouble(),
        (frame.source.y * height).toDouble(),
        width.toDouble(),
        height.toDouble(),
      ),
      usesLegacyGrid: true,
    );
  }

  ResolvedCharacterAnimationFrameSource? resolveCustomFrame({
    required ProjectCharacterEntry character,
    required CharacterCustomAnimationClip clip,
    required CharacterAnimationFrame frame,
    required Set<String> availableImageIds,
  }) {
    final sourceAssetId = clip.sourceAssetId.trim();
    final runtimeImageId = characterAnimationRuntimeImageId(sourceAssetId);
    if (sourceAssetId.isEmpty || !availableImageIds.contains(runtimeImageId)) {
      _emitOnce(
        CharacterAnimationSourceDiagnostic(
          code:
              CharacterAnimationSourceDiagnosticCode.dedicatedSourceUnavailable,
          characterId: character.id,
          sourceAssetId: sourceAssetId,
          direction: clip.direction,
        ),
      );
      return null;
    }
    final source = frame.source;
    return ResolvedCharacterAnimationFrameSource(
      imageId: runtimeImageId,
      sourceRect: Rect.fromLTWH(
        source.x.toDouble(),
        source.y.toDouble(),
        source.width.toDouble(),
        source.height.toDouble(),
      ),
      usesLegacyGrid: false,
    );
  }

  void _emitOnce(CharacterAnimationSourceDiagnostic diagnostic) {
    final key = '${diagnostic.code.name}\u0000${diagnostic.characterId}'
        '\u0000${diagnostic.sourceAssetId}\u0000${diagnostic.state?.name}'
        '\u0000${diagnostic.direction?.name}';
    if (_emittedDiagnostics.add(key)) {
      onDiagnostic?.call(diagnostic);
    }
  }
}

final class CharacterAnimationSourcePreloadPlan {
  CharacterAnimationSourcePreloadPlan({
    required Map<String, String> absolutePathsByAssetId,
    required List<CharacterAnimationSourceDiagnostic> diagnostics,
  })  : absolutePathsByAssetId =
            Map<String, String>.unmodifiable(absolutePathsByAssetId),
        diagnostics =
            List<CharacterAnimationSourceDiagnostic>.unmodifiable(diagnostics);

  final Map<String, String> absolutePathsByAssetId;
  final List<CharacterAnimationSourceDiagnostic> diagnostics;
}

CharacterAnimationSourcePreloadPlan buildCharacterAnimationSourcePreloadPlan({
  required ProjectManifest manifest,
  required String projectRootDirectory,
  required AssetCatalog? assetCatalog,
  bool Function(String path)? fileExists,
}) {
  final root = p.normalize(p.absolute(projectRootDirectory));
  final exists = fileExists ?? FileSystemEntity.isFileSync;
  final paths = <String, String>{};
  final diagnostics = <CharacterAnimationSourceDiagnostic>[];
  final assetIds = <String, String>{};
  for (final character in manifest.characters) {
    for (final animation in character.animations) {
      final assetId = animation.sourceAssetId?.trim();
      if (assetId != null && assetId.isNotEmpty) {
        assetIds.putIfAbsent(assetId, () => character.id);
      }
    }
    for (final clip in character.customAnimations) {
      final assetId = clip.sourceAssetId.trim();
      if (assetId.isNotEmpty) {
        assetIds.putIfAbsent(assetId, () => character.id);
      }
    }
  }
  for (final entry in assetIds.entries) {
    final asset = assetCatalog?.find(entry.key);
    if (asset == null) {
      diagnostics.add(
        CharacterAnimationSourceDiagnostic(
          code: CharacterAnimationSourceDiagnosticCode.assetUnknown,
          characterId: entry.value,
          sourceAssetId: entry.key,
        ),
      );
      continue;
    }
    if (asset.artifact.mediaType != 'image/png') {
      diagnostics.add(
        CharacterAnimationSourceDiagnostic(
          code: CharacterAnimationSourceDiagnosticCode.assetInvalid,
          characterId: entry.value,
          sourceAssetId: entry.key,
        ),
      );
      continue;
    }
    final absolutePath = p.normalize(
      p.join(root, assetBlobStorageKey(asset.artifact)),
    );
    if (!p.isWithin(root, absolutePath)) {
      diagnostics.add(
        CharacterAnimationSourceDiagnostic(
          code: CharacterAnimationSourceDiagnosticCode.assetInvalid,
          characterId: entry.value,
          sourceAssetId: entry.key,
        ),
      );
      continue;
    }
    if (!exists(absolutePath)) {
      diagnostics.add(
        CharacterAnimationSourceDiagnostic(
          code: CharacterAnimationSourceDiagnosticCode.assetMissing,
          characterId: entry.value,
          sourceAssetId: entry.key,
        ),
      );
      continue;
    }
    paths[entry.key] = absolutePath;
  }
  return CharacterAnimationSourcePreloadPlan(
    absolutePathsByAssetId: paths,
    diagnostics: diagnostics,
  );
}
