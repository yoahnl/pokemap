import 'dart:typed_data';

import 'surface_studio_ai_mapping_suggester.dart';
import 'surface_studio_local_mapping_suggester.dart';
import 'surface_studio_mapping_suggestion_models.dart';

final class SurfaceStudioMappingSuggestionController {
  const SurfaceStudioMappingSuggestionController({
    this.localSuggester = const SurfaceStudioLocalMappingSuggester(),
    this.aiSuggester,
  });

  final SurfaceStudioLocalMappingSuggester localSuggester;
  final SurfaceStudioAiMappingSuggester? aiSuggester;

  SurfaceStudioMappingSuggestionResult suggestLocal({
    required int columnCount,
  }) {
    return localSuggester.suggest(columnCount: columnCount);
  }

  Future<SurfaceStudioMappingSuggestionResult> suggestMistral({
    required String apiKey,
    required Uint8List imageBytes,
    required int tileWidth,
    required int tileHeight,
    required int columnCount,
    required int frameCount,
  }) {
    final suggester = aiSuggester;
    if (suggester == null) {
      return Future.value(
        const SurfaceStudioMappingSuggestionResult(
          suggestions: <SurfaceStudioRoleSuggestion>[],
          warnings: <String>['Analyse IA Mistral indisponible.'],
          source: SurfaceStudioMappingSuggestionSource.mistral,
        ),
      );
    }
    return suggester.suggest(
      apiKey: apiKey,
      imageBytes: imageBytes,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      columnCount: columnCount,
      frameCount: frameCount,
    );
  }
}
