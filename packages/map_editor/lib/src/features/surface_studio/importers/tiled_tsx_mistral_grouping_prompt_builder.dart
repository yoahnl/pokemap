import 'package:map_core/map_core.dart';

import 'tiled_tsx_mistral_grouping_models.dart';

const List<String> tiledTsxMistralAllowedRoleNames = <String>[
  'isolated',
  'endNorth',
  'endEast',
  'endSouth',
  'endWest',
  'horizontal',
  'vertical',
  'cornerNW',
  'cornerNE',
  'cornerSW',
  'cornerSE',
  'innerCornerNW',
  'innerCornerNE',
  'innerCornerSW',
  'innerCornerSE',
  'teeNorth',
  'teeEast',
  'teeSouth',
  'teeWest',
  'cross',
];

String buildTiledTsxMistralGroupingPrompt({
  required TiledTsxMistralGroupingRequest request,
  required String metadataJson,
}) {
  final roleNames = tiledTsxMistralAllowedRoleNames.join(', ');
  return '''
You are helping a no-code Pokémon-like map editor group already-imported TSX animations into visual surface roles.

The animation frames are already imported from Tiled TSX.
Do not infer or change frames.
Do not output tile ids.
Do not output raw atlas coordinates.
Only propose mappings from SurfaceVariantRole to existing animationId.

Take your time internally.
Use high-effort visual reasoning.
Prefer abstaining over wrong mappings.
Do not guess.
Return JSON only.
Do not expose chain-of-thought.

Allowed roles:
$roleNames

Rules:
- isolated is important but only propose it when visually clear.
- Use each animationId at most once.
- Never invent an animationId.
- Never invent a role.
- If uncertain, leave the role empty and add a warning.
- Propose fewer roles with stronger evidence.
- Do not create a preset.
- Do not apply the mapping.

Tile metadata:
- tileWidth: ${request.tileWidth}
- tileHeight: ${request.tileHeight}
- atlasColumns: ${request.atlasColumns}
- atlasRows: ${request.atlasRows}

Animation metadata JSON:
$metadataJson

Return this JSON shape:
{
  "suggestions": [
    {
      "role": "isolated",
      "animationId": "existing-animation-id",
      "confidence": "high",
      "evidenceAnimationIds": ["existing-animation-id"],
      "reason": "Short visual evidence."
    }
  ],
  "rejectedAnimationIds": ["existing-animation-id"],
  "warnings": ["Ambiguity note."]
}
''';
}

SurfaceVariantRole? tiledTsxRoleFromName(String name) {
  for (final role in standardSurfaceVariantRoleOrder) {
    if (role.name == name) {
      return role;
    }
  }
  return null;
}
