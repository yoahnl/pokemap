import 'surface_studio_mistral_vision_pack.dart';

const surfaceStudioMistralAllowedRoleNames = <String>[
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

const surfaceStudioMistralRoleLabelMap = <String, String>{
  'Plein(center)': 'isolated',
  'Bord haut': 'endNorth',
  'Bord droit': 'endEast',
  'Bord bas': 'endSouth',
  'Bord gauche': 'endWest',
  'Horizontal': 'horizontal',
  'Vertical': 'vertical',
  'Coin haut gauche': 'cornerNW',
  'Coin haut droit': 'cornerNE',
  'Coin bas gauche': 'cornerSW',
  'Coin bas droit': 'cornerSE',
  'Coin int. haut gauche': 'innerCornerNW',
  'Coin int. haut droit': 'innerCornerNE',
  'Coin int. bas gauche': 'innerCornerSW',
  'Coin int. bas droit': 'innerCornerSE',
  'Té haut': 'teeNorth',
  'Té droit': 'teeEast',
  'Té bas': 'teeSouth',
  'Té gauche': 'teeWest',
  'Croix': 'cross',
};

String buildSurfaceStudioMappingSuggestionPrompt({
  required int tileWidth,
  required int tileHeight,
  required int columnCount,
  required int frameCount,
  List<SurfaceStudioColumnVisualDescriptor> columnDescriptors =
      const <SurfaceStudioColumnVisualDescriptor>[],
}) {
  final roles = surfaceStudioMistralAllowedRoleNames.join(', ');
  final roleLabels = surfaceStudioMistralRoleLabelMap.entries
      .map((entry) => '- ${entry.key} = ${entry.value}')
      .join('\n');
  final descriptors = columnDescriptors.isEmpty
      ? '[]'
      : surfaceStudioColumnDescriptorsJson(columnDescriptors);
  return '''
You are analyzing a Pokémon-like animated surface atlas for a no-code map editor.
Take your time internally.
Use high-effort visual reasoning.
Inspect the column contact sheet first.
Do not rush.
Do not guess.
Do not guess when uncertain.
Prefer abstaining over wrong mappings.
Only assign roles when visual evidence is strong.
Return JSON only.
Return valid JSON only. No markdown. No prose outside JSON. Do not expose chain-of-thought.

You receive three images:
1. Original atlas image.
2. Annotated atlas image with grid and readable 1-based column numbers.
3. Column contact sheet. The column contact sheet is the priority image for identification.

Inspect the atlas as a grid:
- columns are visual variants
- rows are animation frames
- Columns are 1-based in this UI
- tileWidth: $tileWidth
- tileHeight: $tileHeight
- columns: $columnCount
- frames: $frameCount
- every role must map to existing columns only

Your task:
Assign atlas columns to surface autotile roles.

Allowed technical roles, in canonical order:
$roles

French UI label to technical role mapping:
$roleLabels

Visual guidance:
- A bright or pink guide column may be a border, not necessarily center.
- Repeated water-only columns are likely center/isolated.
- Shoreline strips indicate borders.
- L-shaped shorelines indicate external corners.
- Inner L-shaped cutouts indicate inner corners.
- T shapes indicate junctions.
- Cross shapes indicate cross junction.
- If uncertain, leave the role empty and add a warning.
- Prefer fewer high-confidence mappings over many guesses.
- If the atlas only contains center/water fill columns without clear borders, leave border/corner roles empty.
- Never map likelyEmpty columns.

Local column descriptors from deterministic analysis:
$descriptors

Validation rules:
- All column numbers must be between 1 and $columnCount.
- isolated may contain multiple columns.
- All other roles must contain at most one column.
- Do not invent roles.
- Never map columns marked likelyEmpty by the local descriptors.
- confidence must be exactly high, medium, or low.
- reason must be a short string for each assignment.
- evidenceColumns must be inside the atlas bounds.
- rejectedColumns must be inside the atlas bounds.
- warnings must be strings and should explain ambiguity.

Before producing JSON, internally verify:
1. All column numbers are within range.
2. isolated/center may contain multiple columns.
3. All other roles contain at most one column.
4. No role is invented.
5. likelyEmpty columns are not mapped.
6. Warnings explain ambiguity.
7. Output is valid JSON only.

Expected JSON schema:
{
  "assignments": [
    {
      "role": "isolated",
      "columns": [4, 5],
      "confidence": "high",
      "evidenceColumns": [4, 5],
      "reason": "Columns 4 and 5 are full water tiles without shoreline and can repeat as center variants."
    }
  ],
  "rejectedColumns": [
    {
      "column": 3,
      "reason": "Likely empty or insufficient visual evidence."
    }
  ],
  "warnings": [
    "Inner corners are not confidently visible."
  ]
}
''';
}
