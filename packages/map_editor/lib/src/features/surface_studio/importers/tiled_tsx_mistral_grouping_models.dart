import 'package:map_core/map_core.dart';

import '../surface_studio_mapping_suggestion_models.dart';

final class TiledTsxMistralGroupingRequest {
  const TiledTsxMistralGroupingRequest({
    required this.animations,
    required this.tileWidth,
    required this.tileHeight,
    required this.atlasColumns,
    required this.atlasRows,
    required this.availableRoles,
  });

  final List<ProjectSurfaceAnimation> animations;
  final int tileWidth;
  final int tileHeight;
  final int atlasColumns;
  final int atlasRows;
  final List<SurfaceVariantRole> availableRoles;
}

final class TiledTsxRoleAnimationSuggestion {
  const TiledTsxRoleAnimationSuggestion({
    required this.role,
    required this.animationId,
    required this.confidence,
    required this.reason,
    required this.evidenceAnimationIds,
  });

  final SurfaceVariantRole role;
  final String animationId;
  final SurfaceStudioMappingSuggestionConfidence confidence;
  final String reason;
  final List<String> evidenceAnimationIds;
}

final class TiledTsxMistralGroupingResult {
  const TiledTsxMistralGroupingResult({
    required this.suggestions,
    required this.rejectedAnimationIds,
    required this.warnings,
  });

  final List<TiledTsxRoleAnimationSuggestion> suggestions;
  final List<String> rejectedAnimationIds;
  final List<String> warnings;

  Iterable<TiledTsxRoleAnimationSuggestion> get reliableSuggestions =>
      suggestions.where(
        (suggestion) =>
            suggestion.confidence ==
                SurfaceStudioMappingSuggestionConfidence.high ||
            suggestion.confidence ==
                SurfaceStudioMappingSuggestionConfidence.medium,
      );
}
