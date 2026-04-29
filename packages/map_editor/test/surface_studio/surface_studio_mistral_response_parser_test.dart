import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_mapping_suggestion_models.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_mistral_response_parser.dart';

void main() {
  test('extractMistralAssistantTextContent accepts string content', () {
    expect(
      extractMistralAssistantTextContent('  {"assignments":[]}  '),
      '{"assignments":[]}',
    );
  });

  test(
      'extractMistralAssistantTextContent ignores thinking and joins text parts',
      () {
    final content = [
      {
        'type': 'thinking',
        'thinking': [
          {'type': 'text', 'text': 'internal reasoning must be ignored'},
        ],
      },
      {'type': 'text', 'text': '{"assignments":'},
      {'type': 'text', 'text': '[],"warnings":[]}'},
      {'type': 'unknown', 'text': 'ignored'},
    ];

    expect(
      extractMistralAssistantTextContent(content),
      '{"assignments":[],"warnings":[]}',
    );
    expect(
      extractMistralAssistantTextContent([
        {'type': 'thinking', 'thinking': 'private'},
      ]),
      isNull,
    );
  });

  test('extractFirstJsonObjectFromMistralText accepts wrapped JSON', () {
    final object = extractFirstJsonObjectFromMistralText(
      'notes before {"assignments":[],"warnings":[]} notes after',
    );

    expect(object, isNotNull);
    expect(object!['assignments'], isEmpty);
  });

  test('real content-list response parses legacy schema without thinking leak',
      () {
    final result = parseSurfaceStudioMistralChatResponse(
      _chatResponse(_legacyUsefulJson()),
      columnCount: 20,
      columnDescriptors: const [],
    );

    expect(result.source, SurfaceStudioMappingSuggestionSource.mistral);
    expect(result.suggestions, hasLength(11));
    expect(
      result.suggestions
          .singleWhere(
            (suggestion) => suggestion.role == SurfaceVariantRole.isolated,
          )
          .columns,
      <int>[4, 5],
    );
    expect(
      result.suggestions
          .singleWhere(
            (suggestion) => suggestion.role == SurfaceVariantRole.horizontal,
          )
          .columns,
      <int>[6],
    );
    expect(
      result.suggestions
          .singleWhere(
            (suggestion) => suggestion.role == SurfaceVariantRole.vertical,
          )
          .columns,
      <int>[7],
    );
    expect(
      result.suggestions.map((suggestion) => suggestion.role),
      containsAll(<SurfaceVariantRole>[
        SurfaceVariantRole.cornerNW,
        SurfaceVariantRole.cornerNE,
        SurfaceVariantRole.cornerSW,
        SurfaceVariantRole.cornerSE,
        SurfaceVariantRole.teeNorth,
        SurfaceVariantRole.teeEast,
        SurfaceVariantRole.teeSouth,
        SurfaceVariantRole.teeWest,
      ]),
    );
    expect(result.warnings, contains('No confident inner corners.'));
    expect(
      result.warnings,
      contains(
        'Réponse Mistral sans rejectedColumns/evidenceColumns, compat legacy appliquée.',
      ),
    );
    expect(result.warnings.join('\n'), isNot(contains('internal reasoning')));
  });

  test('parser rejects unknown roles, out of range and invalid multi-columns',
      () {
    final result = parseSurfaceStudioMistralChatResponse(
      jsonEncode({
        'choices': [
          {
            'message': {
              'content': jsonEncode({
                'assignments': [
                  {
                    'role': 'unknown',
                    'columns': [2],
                    'confidence': 'high',
                    'reason': 'Unknown.',
                  },
                  {
                    'role': 'endNorth',
                    'columns': [99],
                    'confidence': 'high',
                    'reason': 'Out.',
                  },
                  {
                    'role': 'endEast',
                    'columns': [2, 3],
                    'confidence': 'high',
                    'reason': 'Too many.',
                  },
                ],
                'warnings': [],
              }),
            },
          },
        ],
      }),
      columnCount: 12,
      columnDescriptors: const [],
    );

    expect(result.suggestions, isEmpty);
    expect(result.warnings, contains('Rôle Mistral inconnu rejeté : unknown.'));
    expect(
      result.warnings,
      contains('Colonne Mistral hors bornes rejetée pour endNorth : 99.'),
    );
    expect(
      result.warnings,
      contains('Suggestion Mistral multi-colonnes rejetée pour endEast.'),
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

String _legacyUsefulJson() {
  return jsonEncode({
    'assignments': [
      {
        'role': 'isolated',
        'columns': [4, 5],
        'confidence': 'high',
        'reason': 'Full center water variants.',
      },
      {
        'role': 'horizontal',
        'columns': [6],
        'confidence': 'high',
        'reason': 'Horizontal strip.',
      },
      {
        'role': 'vertical',
        'columns': [7],
        'confidence': 'high',
        'reason': 'Vertical strip.',
      },
      {
        'role': 'cornerNW',
        'columns': [8],
        'confidence': 'high',
        'reason': 'North-west corner.',
      },
      {
        'role': 'cornerNE',
        'columns': [9],
        'confidence': 'high',
        'reason': 'North-east corner.',
      },
      {
        'role': 'cornerSW',
        'columns': [10],
        'confidence': 'high',
        'reason': 'South-west corner.',
      },
      {
        'role': 'cornerSE',
        'columns': [11],
        'confidence': 'high',
        'reason': 'South-east corner.',
      },
      {
        'role': 'teeNorth',
        'columns': [12],
        'confidence': 'medium',
        'reason': 'T junction north.',
      },
      {
        'role': 'teeEast',
        'columns': [13],
        'confidence': 'medium',
        'reason': 'T junction east.',
      },
      {
        'role': 'teeSouth',
        'columns': [14],
        'confidence': 'medium',
        'reason': 'T junction south.',
      },
      {
        'role': 'teeWest',
        'columns': [15],
        'confidence': 'medium',
        'reason': 'T junction west.',
      },
    ],
    'warnings': ['No confident inner corners.'],
  });
}
