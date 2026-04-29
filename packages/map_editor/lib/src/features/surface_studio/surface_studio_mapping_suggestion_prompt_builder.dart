import 'package:map_core/map_core.dart';

String buildSurfaceStudioMappingSuggestionPrompt({
  required int tileWidth,
  required int tileHeight,
  required int columnCount,
  required int frameCount,
}) {
  final roles =
      standardSurfaceVariantRoleOrder.map((role) => role.name).join(', ');
  return '''
You are helping map a Pokemon-style surface atlas.
Return JSON only. No markdown. No prose outside JSON.

Expected schema:
{
  "assignments": [
    {
      "role": "isolated",
      "columns": [4, 5],
      "confidence": "medium",
      "reason": "Columns 4 and 5 look like repeatable center water tiles."
    }
  ],
  "warnings": ["Inner corners are ambiguous."]
}

Atlas metadata:
- tileWidth: $tileWidth
- tileHeight: $tileHeight
- columns: $columnCount
- frames: $frameCount
- allowedRoles: $roles

Rules:
- Use only allowed role names.
- Columns are 1-based and must be between 1 and $columnCount.
- isolated may use multiple columns.
- Every other role must use at most one column.
- confidence must be high, medium, or low.
- Provide a short reason for each assignment.
''';
}
