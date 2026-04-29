import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_mistral_grouping_models.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_mistral_grouping_suggester.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_mapping_suggestion_models.dart';

void main() {
  test('provider sends high reasoning schema request without leaking secrets',
      () async {
    Map<String, dynamic>? requestBody;
    final suggester = TiledTsxMistralAnimationGroupingSuggester(
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
                    'suggestions': [
                      {
                        'role': 'isolated',
                        'animationId': 'tech-animations-tile-99',
                        'confidence': 'high',
                        'evidenceAnimationIds': ['tech-animations-tile-99'],
                        'reason': 'Full repeatable water tile.',
                      },
                    ],
                    'rejectedAnimationIds': const [],
                    'warnings': const ['No confident corner animation.'],
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
      apiKey: 'configured-secret',
      request: _request(),
      atlasImageBytes: _atlasBytes(),
    );

    final body = requestBody!;
    expect(body['reasoning_effort'], 'high');
    expect(body['temperature'], lessThanOrEqualTo(0.1));
    final responseFormat = body['response_format'] as Map<String, dynamic>;
    expect(responseFormat['type'], 'json_schema');
    expect(jsonEncode(responseFormat), contains('animationId'));
    expect(jsonEncode(body), contains('Do not infer or change frames'));
    expect(jsonEncode(body), contains('tech-animations-tile-99'));
    final content = ((body['messages'] as List).single
        as Map<String, dynamic>)['content'] as List<dynamic>;
    expect(
      content
          .whereType<Map<String, dynamic>>()
          .where((part) => part['type'] == 'image_url'),
      hasLength(1),
    );
    expect(result.suggestions, hasLength(1));
    expect(result.suggestions.single.role, SurfaceVariantRole.isolated);
    expect(result.suggestions.single.animationId, 'tech-animations-tile-99');
    expect(result.warnings, contains('No confident corner animation.'));
  });

  test('parser accepts content list, ignores thinking and validates ids', () {
    final result = parseTiledTsxMistralGroupingChatResponse(
      _chatResponse(
        jsonEncode({
          'suggestions': [
            {
              'role': 'isolated',
              'animationId': 'tech-animations-tile-99',
              'confidence': 'high',
              'evidenceAnimationIds': ['tech-animations-tile-99'],
              'reason': 'Full tile.',
            },
            {
              'role': 'endNorth',
              'animationId': 'unknown-animation',
              'confidence': 'high',
              'evidenceAnimationIds': ['unknown-animation'],
              'reason': 'Unknown.',
            },
            {
              'role': 'unknownRole',
              'animationId': 'tech-animations-tile-105',
              'confidence': 'high',
              'evidenceAnimationIds': ['tech-animations-tile-105'],
              'reason': 'Unknown role.',
            },
            {
              'role': 'endEast',
              'animationId': 'tech-animations-tile-105',
              'confidence': 'certain',
              'evidenceAnimationIds': ['tech-animations-tile-105'],
              'reason': 'Bad confidence.',
            },
          ],
          'rejectedAnimationIds': ['tech-animations-tile-105'],
          'warnings': ['Ambiguous shorelines.'],
        }),
      ),
      request: _request(),
    );

    expect(result.suggestions, hasLength(1));
    expect(result.suggestions.single.role, SurfaceVariantRole.isolated);
    expect(result.rejectedAnimationIds, ['tech-animations-tile-105']);
    expect(result.warnings, contains('Ambiguous shorelines.'));
    expect(
      result.warnings,
      contains(
        'Animation Mistral inconnue ou non sélectionnée rejetée pour endNorth : unknown-animation.',
      ),
    );
    expect(
      result.warnings,
      contains('Rôle Mistral inconnu rejeté : unknownRole.'),
    );
    expect(
      result.warnings,
      contains('Confiance Mistral inconnue rejetée pour endEast.'),
    );
    expect(result.warnings.join('\n'), isNot(contains('internal reasoning')));
  });

  test('parser rejects duplicate roles and duplicate animation ids', () {
    final result = parseTiledTsxMistralGroupingChatResponse(
      _chatResponse(
        jsonEncode({
          'suggestions': [
            {
              'role': 'isolated',
              'animationId': 'tech-animations-tile-99',
              'confidence': 'high',
              'evidenceAnimationIds': ['tech-animations-tile-99'],
              'reason': 'First.',
            },
            {
              'role': 'isolated',
              'animationId': 'tech-animations-tile-105',
              'confidence': 'high',
              'evidenceAnimationIds': ['tech-animations-tile-105'],
              'reason': 'Duplicate role.',
            },
            {
              'role': 'endNorth',
              'animationId': 'tech-animations-tile-99',
              'confidence': 'high',
              'evidenceAnimationIds': ['tech-animations-tile-99'],
              'reason': 'Duplicate animation.',
            },
          ],
          'rejectedAnimationIds': const [],
          'warnings': const [],
        }),
      ),
      request: _request(),
    );

    expect(result.suggestions, hasLength(1));
    expect(
      result.warnings,
      contains('Rôle Mistral dupliqué rejeté : isolated.'),
    );
    expect(
      result.warnings,
      contains(
        'Animation Mistral dupliquée rejetée pour endNorth : tech-animations-tile-99.',
      ),
    );
  });
}

String _chatResponse(String usefulJson) {
  return jsonEncode({
    'choices': [
      {
        'message': {
          'content': [
            {
              'type': 'thinking',
              'thinking': [
                {'type': 'text', 'text': 'internal reasoning must be ignored'},
              ],
            },
            {'type': 'text', 'text': usefulJson},
          ],
        },
      },
    ],
  });
}

TiledTsxMistralGroupingRequest _request() {
  return TiledTsxMistralGroupingRequest(
    animations: [
      _animation('tech-animations-tile-99'),
      _animation('tech-animations-tile-105'),
    ],
    tileWidth: 8,
    tileHeight: 8,
    atlasColumns: 4,
    atlasRows: 2,
    availableRoles: standardSurfaceVariantRoleOrder,
  );
}

ProjectSurfaceAnimation _animation(String id) {
  return ProjectSurfaceAnimation(
    id: id,
    name: id,
    timeline: SurfaceAnimationTimeline(
      frames: [
        SurfaceAnimationFrame(
          tileRef: SurfaceAtlasTileRef(
            atlasId: 'tech-animations',
            column: 1,
            row: 0,
          ),
          durationMs: 100,
        ),
      ],
    ),
  );
}

Uint8List _atlasBytes() {
  const tile = 8;
  final image = img.Image(width: 4 * tile, height: 2 * tile);
  img.fill(image, color: img.ColorRgb8(40, 90, 180));
  return Uint8List.fromList(img.encodePng(image));
}
