import 'dart:io';

import 'package:map_core/map_core.dart';

/// Resolve the editor-wide Mistral key without exposing or logging it.
///
/// Priority stays intentionally shared across editor AI features:
/// project settings first, then the `MISTRAL_API_KEY` environment fallback.
String resolveEditorMistralApiKey(ProjectSettings? settings) {
  final fromProject = settings?.mistralApiKey?.trim() ?? '';
  if (fromProject.isNotEmpty) {
    return fromProject;
  }
  return Platform.environment['MISTRAL_API_KEY'] ?? '';
}

bool hasEditorMistralApiKey(ProjectSettings? settings) =>
    resolveEditorMistralApiKey(settings).trim().isNotEmpty;
