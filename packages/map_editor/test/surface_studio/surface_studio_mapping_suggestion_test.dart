import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_local_mapping_suggester.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_ai_mapping_suggester.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_mapping_suggestion_models.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart';

import 'surface_studio_rebuild_test_harness.dart';

void main() {
  test('local suggester returns bounded reviewable suggestions', () {
    final result = SurfaceStudioLocalMappingSuggester().suggest(columnCount: 3);

    expect(result.source, SurfaceStudioMappingSuggestionSource.local);
    expect(result.suggestions, isNotEmpty);
    expect(
      result.suggestions.every(
        (suggestion) =>
            suggestion.columns.every((column) => column >= 1 && column <= 3),
      ),
      isTrue,
    );
    expect(result.warnings, isNotEmpty);
  });

  testWidgets('Suggestion auto opens a review before mutating the mapping',
      (tester) async {
    await pumpSurfaceStudioForTest(tester);
    await tester.pump();

    await tester.tap(find.byKey(const Key('surfaceStudio.action.autoSuggest')));
    await tester.pumpAndSettle();

    expect(find.text('Suggestions détectées'), findsOneWidget);
    expect(find.text('Source : Local'), findsOneWidget);
    expect(find.text('Appliquer les suggestions fiables'), findsOneWidget);
    expect(
      find.byKey(const Key('surfaceStudio.suggestion.mistral')),
      findsOneWidget,
    );
    expect(
      find.text(
          'Clé Mistral absente : Projet → Paramètres (IA) ou MISTRAL_API_KEY'),
      findsOneWidget,
    );

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Suggestions détectées'), findsNothing);
  });

  testWidgets('Mistral prep detects configured key without displaying it',
      (tester) async {
    await pumpSurfaceStudioForTest(
      tester,
      projectSettings: const ProjectSettings(mistralApiKey: 'configured'),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('surfaceStudio.action.autoSuggest')));
    await tester.pumpAndSettle();

    expect(find.text('Clé Mistral configurée.'), findsOneWidget);
    expect(find.textContaining('configured'), findsNothing);
    expect(
      find.byKey(const Key('surfaceStudio.suggestion.mistral')),
      findsOneWidget,
    );
  });

  testWidgets('Mistral analysis asks confirmation before any provider call',
      (tester) async {
    final fakeAi = _FakeAiSuggester();

    await pumpSurfaceStudioForTest(
      tester,
      projectSettings: const ProjectSettings(mistralApiKey: 'configured'),
      aiMappingSuggester: fakeAi,
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('surfaceStudio.action.autoSuggest')));
    await tester.pump(const Duration(milliseconds: 50));
    final mistralButton =
        find.byKey(const Key('surfaceStudio.suggestion.mistral'));
    await tester.ensureVisible(mistralButton);
    await tester.tap(mistralButton);
    await tester.pump(const Duration(milliseconds: 50));

    expect(fakeAi.calls, 0);
    expect(find.text('Confirmer l’analyse IA'), findsOneWidget);

    final cancelAi = find.text('Annuler l’analyse IA');
    await tester.ensureVisible(cancelAi);
    await tester.tap(cancelAi);
    await tester.pump(const Duration(milliseconds: 50));
    expect(fakeAi.calls, 0);
  });

  testWidgets('accepted Mistral suggestion updates mapping and live preview',
      (tester) async {
    final temp =
        Directory.systemTemp.createTempSync('surface_mistral_preview_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final image = File('${temp.path}/tiles/water.png');
    image.parent.createSync(recursive: true);
    image.writeAsBytesSync(_atlasBytes());
    final fakeAi = _FakeAiSuggester();

    await pumpSurfaceStudioForTest(
      tester,
      readModel: _readModel(),
      projectSettings: const ProjectSettings(mistralApiKey: 'configured'),
      projectTilesets: const <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'water_tiles',
          name: 'Water Tiles',
          relativePath: 'tiles/water.png',
          sortOrder: 0,
        ),
      ],
      projectRootPath: temp.path,
      aiMappingSuggester: fakeAi,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Assignez au moins le rôle'), findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.preview.tileRenderer')),
        findsNothing);

    await tester.tap(find.byKey(const Key('surfaceStudio.action.autoSuggest')));
    await tester.pumpAndSettle();
    final mistralButton =
        find.byKey(const Key('surfaceStudio.suggestion.mistral'));
    await tester.ensureVisible(mistralButton);
    await tester.tap(mistralButton);
    await tester.pumpAndSettle();
    expect(find.text('Confirmer l’analyse IA'), findsOneWidget);
    expect(fakeAi.calls, 0);

    final confirmButton =
        find.byKey(const Key('surfaceStudio.suggestion.confirmAi'));
    await tester.ensureVisible(confirmButton);
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();
    expect(fakeAi.calls, 1);
    expect(find.text('AI center'), findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.preview.tileRenderer')),
        findsNothing);

    final acceptButton =
        find.byKey(const Key('surfaceStudio.suggestion.accept.isolated'));
    await tester.ensureVisible(acceptButton);
    await tester.tap(acceptButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('Assignez au moins le rôle'), findsNothing);
    expect(find.byKey(const Key('surfaceStudio.preview.tileRenderer')),
        findsOneWidget);
    final centerSlot =
        find.byKey(const Key('surfaceStudio.schema.role.center'));
    expect(find.descendant(of: centerSlot, matching: find.text('4')),
        findsOneWidget);
    expect(find.descendant(of: centerSlot, matching: find.text('5')),
        findsOneWidget);
  });

  test('Mistral suggester validates JSON without leaking secrets', () async {
    final requests = <http.Request>[];
    final suggester = SurfaceStudioMistralMappingSuggester(
      httpClient: MockClient((request) async {
        requests.add(request);
        expect(request.headers['Authorization'], 'Bearer configured');
        expect(request.body, isNot(contains('configured')));
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': jsonEncode({
                    'assignments': [
                      {
                        'role': 'isolated',
                        'columns': [4, 5],
                        'confidence': 'medium',
                        'evidenceColumns': [4, 5],
                        'reason': 'Center water candidates.',
                      },
                      {
                        'role': 'endNorth',
                        'columns': [99],
                        'confidence': 'high',
                        'evidenceColumns': [99],
                        'reason': 'Out of range.',
                      },
                      {
                        'role': 'endEast',
                        'columns': [1, 2],
                        'confidence': 'high',
                        'evidenceColumns': [1, 2],
                        'reason': 'Too many columns.',
                      },
                      {
                        'role': 'unknown',
                        'columns': [3],
                        'confidence': 'high',
                        'evidenceColumns': [3],
                        'reason': 'Unknown role.',
                      },
                    ],
                    'rejectedColumns': const [],
                    'warnings': ['Inner corners are ambiguous.'],
                  }),
                },
              },
            ],
          }),
          200,
        );
      }),
    );

    final result = await suggester.suggest(
      apiKey: 'configured',
      imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
      tileWidth: 32,
      tileHeight: 32,
      columnCount: 12,
      frameCount: 32,
    );

    expect(requests, hasLength(1));
    expect(result.source, SurfaceStudioMappingSuggestionSource.mistral);
    expect(result.suggestions, hasLength(1));
    expect(result.suggestions.single.role, SurfaceVariantRole.isolated);
    expect(result.suggestions.single.columns, [4, 5]);
    expect(result.warnings, contains('Inner corners are ambiguous.'));
    expect(
      result.warnings,
      contains('Rôle Mistral inconnu rejeté : unknown.'),
    );
    expect(
      result.warnings,
      contains('Colonne Mistral hors bornes rejetée pour endNorth : 99.'),
    );
    expect(
      result.warnings,
      contains('Suggestion Mistral multi-colonnes rejetée pour endEast.'),
    );
  });

  test('Mistral suggester returns a warning for invalid JSON', () async {
    final suggester = SurfaceStudioMistralMappingSuggester(
      httpClient: MockClient((_) async {
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': 'not json'},
              },
            ],
          }),
          200,
        );
      }),
    );

    final result = await suggester.suggest(
      apiKey: 'configured',
      imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
      tileWidth: 32,
      tileHeight: 32,
      columnCount: 12,
      frameCount: 32,
    );

    expect(result.suggestions, isEmpty);
    expect(result.warnings.single, contains('Réponse Mistral invalide'));
  });

  test('Mistral suggester rejects locally likelyEmpty columns', () async {
    final suggester = SurfaceStudioMistralMappingSuggester(
      httpClient: MockClient((_) async {
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': jsonEncode({
                    'assignments': [
                      {
                        'role': 'isolated',
                        'columns': [3],
                        'confidence': 'high',
                        'evidenceColumns': [3],
                        'reason': 'Looks empty but claimed as center.',
                      },
                    ],
                    'rejectedColumns': const [],
                    'warnings': const [],
                  }),
                },
              },
            ],
          }),
          200,
        );
      }),
    );

    final result = await suggester.suggest(
      apiKey: 'configured',
      imageBytes: _atlasBytesWithEmptyColumn(),
      tileWidth: 8,
      tileHeight: 8,
      columnCount: 4,
      frameCount: 2,
    );

    expect(result.suggestions, isEmpty);
    expect(
      result.warnings,
      contains(
        'Suggestion Mistral sur colonne likelyEmpty rejetée pour isolated : 3.',
      ),
    );
  });
}

final class _FakeAiSuggester implements SurfaceStudioAiMappingSuggester {
  int calls = 0;

  @override
  Future<SurfaceStudioMappingSuggestionResult> suggest({
    required String apiKey,
    required Uint8List imageBytes,
    required int tileWidth,
    required int tileHeight,
    required int columnCount,
    required int frameCount,
  }) async {
    calls++;
    expect(apiKey, 'configured');
    expect(imageBytes, isNotEmpty);
    return const SurfaceStudioMappingSuggestionResult(
      suggestions: <SurfaceStudioRoleSuggestion>[
        SurfaceStudioRoleSuggestion(
          role: SurfaceVariantRole.isolated,
          columns: <int>[4, 5],
          confidence: SurfaceStudioMappingSuggestionConfidence.medium,
          source: SurfaceStudioMappingSuggestionSource.mistral,
          reason: 'AI center',
        ),
      ],
      warnings: <String>['AI warning'],
      source: SurfaceStudioMappingSuggestionSource.mistral,
    );
  }
}

SurfaceStudioReadModel _readModel() {
  const atlasId = 'water-atlas';
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[
        ProjectSurfaceAtlas(
          id: atlasId,
          name: 'Water Atlas',
          tilesetId: 'water_tiles',
          geometry: SurfaceAtlasGeometry(
            tileSize: SurfaceAtlasTileSize(width: 8, height: 8),
            gridSize: SurfaceAtlasGridSize(columns: 5, rows: 2),
            layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
          ),
        ),
      ],
      animations: const <ProjectSurfaceAnimation>[],
      presets: const <ProjectSurfacePreset>[],
    ),
  );
}

Uint8List _atlasBytes() {
  const tile = 8;
  const columns = 5;
  const frames = 2;
  final image = img.Image(width: columns * tile, height: frames * tile);
  for (var frame = 0; frame < frames; frame++) {
    for (var column = 0; column < columns; column++) {
      img.fillRect(
        image,
        x1: column * tile,
        y1: frame * tile,
        x2: column * tile + tile - 1,
        y2: frame * tile + tile - 1,
        color: img.ColorRgb8(40 + column * 32, 80 + frame * 70, 180),
      );
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

Uint8List _atlasBytesWithEmptyColumn() {
  const tile = 8;
  const columns = 4;
  const frames = 2;
  final image = img.Image(width: columns * tile, height: frames * tile);
  img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));
  for (var frame = 0; frame < frames; frame++) {
    for (var column = 0; column < columns; column++) {
      if (column == 2) {
        continue;
      }
      img.fillRect(
        image,
        x1: column * tile,
        y1: frame * tile,
        x2: column * tile + tile - 1,
        y2: frame * tile + tile - 1,
        color: img.ColorRgba8(40 + column * 30, 100, 180, 255),
      );
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}
