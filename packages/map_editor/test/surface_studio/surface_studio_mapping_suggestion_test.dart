import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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
                        'reason': 'Center water candidates.',
                      },
                      {
                        'role': 'endNorth',
                        'columns': [99],
                        'confidence': 'high',
                        'reason': 'Out of range.',
                      },
                      {
                        'role': 'endEast',
                        'columns': [1, 2],
                        'confidence': 'high',
                        'reason': 'Too many columns.',
                      },
                      {
                        'role': 'unknown',
                        'columns': [3],
                        'confidence': 'high',
                        'reason': 'Unknown role.',
                      },
                    ],
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
