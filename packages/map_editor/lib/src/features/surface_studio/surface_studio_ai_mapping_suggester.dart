import 'dart:typed_data';

import 'surface_studio_mapping_suggestion_models.dart';

abstract interface class SurfaceStudioAiMappingSuggester {
  Future<SurfaceStudioMappingSuggestionResult> suggest({
    required String apiKey,
    required Uint8List imageBytes,
    required int tileWidth,
    required int tileHeight,
    required int columnCount,
    required int frameCount,
  });
}
