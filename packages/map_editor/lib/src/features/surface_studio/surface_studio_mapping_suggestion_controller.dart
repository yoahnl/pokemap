import 'surface_studio_local_mapping_suggester.dart';
import 'surface_studio_mapping_suggestion_models.dart';

final class SurfaceStudioMappingSuggestionController {
  const SurfaceStudioMappingSuggestionController({
    this.localSuggester = const SurfaceStudioLocalMappingSuggester(),
  });

  final SurfaceStudioLocalMappingSuggester localSuggester;

  SurfaceStudioMappingSuggestionResult suggestLocal({
    required int columnCount,
  }) {
    return localSuggester.suggest(columnCount: columnCount);
  }
}

abstract class SurfaceStudioAiMappingSuggester {
  Future<SurfaceStudioMappingSuggestionResult> suggest();
}
