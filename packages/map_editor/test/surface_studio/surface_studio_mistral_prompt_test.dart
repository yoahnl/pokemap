import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_mapping_suggestion_prompt_builder.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart';

void main() {
  test('prompt asks for careful visual reasoning and documents roles exactly',
      () {
    final prompt = buildSurfaceStudioMappingSuggestionPrompt(
      tileWidth: 8,
      tileHeight: 8,
      columnCount: 5,
      frameCount: 2,
    );

    expect(prompt, contains('Take your time internally'));
    expect(prompt, contains('Use high-effort visual reasoning'));
    expect(prompt, contains('Inspect the column contact sheet first'));
    expect(prompt, contains('Do not guess'));
    expect(prompt, contains('Prefer abstaining over wrong mappings'));
    expect(prompt, contains('Do not guess when uncertain'));
    expect(prompt, contains('Columns are 1-based'));
    expect(prompt, contains('Never map likelyEmpty columns'));
    expect(prompt, contains('tileWidth: 8'));
    expect(prompt, contains('tileHeight: 8'));
    expect(prompt, contains('columns: 5'));
    expect(prompt, contains('frames: 2'));
    expect(prompt, contains('isolated may contain multiple columns'));
    expect(prompt, contains('All other roles must contain at most one column'));
    expect(
      prompt,
      contains(
        'isolated, endNorth, endEast, endSouth, endWest, horizontal, vertical, cornerNW, cornerNE, cornerSW, cornerSE, innerCornerNW, innerCornerNE, innerCornerSW, innerCornerSE, teeNorth, teeEast, teeSouth, teeWest, cross',
      ),
    );
    expect(prompt, contains('Plein(center) = isolated'));
    expect(prompt, contains('Bord haut = endNorth'));
  });

  test('Mistral request uses high reasoning, schema output and no secret body',
      () async {
    Map<String, dynamic>? requestBody;
    final suggester = SurfaceStudioMistralMappingSuggester(
      httpClient: MockClient((request) async {
        requestBody = jsonDecode(request.body) as Map<String, dynamic>;
        expect(request.headers['Authorization'], 'Bearer configured-secret');
        expect(request.body, isNot(contains('configured-secret')));
        expect(request.body, isNot(contains('/Users/')));
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': jsonEncode({
                    'assignments': const [],
                    'rejectedColumns': const [],
                    'warnings': const ['No confident mapping.'],
                  }),
                },
              },
            ],
          }),
          200,
        );
      }),
    );

    await suggester.suggest(
      apiKey: 'configured-secret',
      imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
      tileWidth: 8,
      tileHeight: 8,
      columnCount: 5,
      frameCount: 2,
    );

    final body = requestBody!;
    expect(body['reasoning_effort'], 'high');
    expect(body['temperature'], lessThanOrEqualTo(0.2));
    final responseFormat = body['response_format'] as Map<String, dynamic>;
    expect(responseFormat['type'], 'json_schema');
    expect(responseFormat['json_schema'], isA<Map<String, dynamic>>());
    expect(jsonEncode(responseFormat), contains('evidenceColumns'));
    expect(jsonEncode(responseFormat), contains('rejectedColumns'));
    expect(jsonEncode(body), contains('Take your time internally'));
    expect(
        jsonEncode(body), contains('Inspect the column contact sheet first'));
    final content = ((body['messages'] as List).single
        as Map<String, dynamic>)['content'] as List<dynamic>;
    expect(
      content
          .whereType<Map<String, dynamic>>()
          .where((part) => part['type'] == 'image_url'),
      hasLength(3),
    );
  });
}
