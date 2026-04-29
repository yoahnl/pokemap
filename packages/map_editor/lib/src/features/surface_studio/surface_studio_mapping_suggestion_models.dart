import 'package:map_core/map_core.dart';

enum SurfaceStudioMappingSuggestionSource {
  local,
  mistral,
  merged,
}

enum SurfaceStudioMappingSuggestionConfidence {
  high,
  medium,
  low,
}

final class SurfaceStudioRoleSuggestion {
  const SurfaceStudioRoleSuggestion({
    required this.role,
    required this.columns,
    required this.confidence,
    required this.source,
    required this.reason,
  });

  final SurfaceVariantRole role;
  final List<int> columns;
  final SurfaceStudioMappingSuggestionConfidence confidence;
  final SurfaceStudioMappingSuggestionSource source;
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceStudioRoleSuggestion &&
          other.role == role &&
          _listEquals(other.columns, columns) &&
          other.confidence == confidence &&
          other.source == source &&
          other.reason == reason;

  @override
  int get hashCode => Object.hash(
        role,
        Object.hashAll(columns),
        confidence,
        source,
        reason,
      );
}

final class SurfaceStudioMappingSuggestionResult {
  const SurfaceStudioMappingSuggestionResult({
    required this.suggestions,
    required this.warnings,
    required this.source,
  });

  final List<SurfaceStudioRoleSuggestion> suggestions;
  final List<String> warnings;
  final SurfaceStudioMappingSuggestionSource source;

  Iterable<SurfaceStudioRoleSuggestion> get reliableSuggestions =>
      suggestions.where(
        (suggestion) =>
            suggestion.confidence ==
                SurfaceStudioMappingSuggestionConfidence.high ||
            suggestion.confidence ==
                SurfaceStudioMappingSuggestionConfidence.medium,
      );
}

bool _listEquals(List<int> a, List<int> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
