import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:map_core/map_core.dart';

import '../surface_studio_mapping_suggestion_models.dart';
import '../surface_studio_mistral_response_parser.dart';
import 'tiled_tsx_mistral_animation_pack.dart';
import 'tiled_tsx_mistral_grouping_models.dart';
import 'tiled_tsx_mistral_grouping_prompt_builder.dart';

abstract interface class TiledTsxAnimationGroupingSuggester {
  Future<TiledTsxMistralGroupingResult> suggest({
    required String apiKey,
    required TiledTsxMistralGroupingRequest request,
    required Uint8List? atlasImageBytes,
  });
}

final class TiledTsxMistralAnimationGroupingSuggester
    implements TiledTsxAnimationGroupingSuggester {
  TiledTsxMistralAnimationGroupingSuggester({
    http.Client? httpClient,
    this.baseUrl = 'https://api.mistral.ai/v1/chat/completions',
    this.model = 'mistral-large-latest',
    this.timeout = const Duration(seconds: 30),
  }) : _client = httpClient ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  final String model;
  final Duration timeout;

  @override
  Future<TiledTsxMistralGroupingResult> suggest({
    required String apiKey,
    required TiledTsxMistralGroupingRequest request,
    required Uint8List? atlasImageBytes,
  }) async {
    final key = apiKey.trim();
    if (key.isEmpty) {
      return const TiledTsxMistralGroupingResult(
        suggestions: <TiledTsxRoleAnimationSuggestion>[],
        rejectedAnimationIds: <String>[],
        warnings: <String>['Clé Mistral absente.'],
      );
    }

    final pack = buildTiledTsxMistralAnimationPack(
      request: request,
      atlasImageBytes: atlasImageBytes,
    );
    final prompt = buildTiledTsxMistralGroupingPrompt(
      request: request,
      metadataJson: pack.metadataJson,
    );
    final body = jsonEncode({
      'model': model,
      'temperature': 0.1,
      'reasoning_effort': 'high',
      'response_format': _jsonSchemaResponseFormat(),
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': prompt},
            {
              'type': 'image_url',
              'image_url': pack.contactSheetDataUrl,
            },
          ],
        },
      ],
    });

    try {
      final response = await _client
          .post(
            Uri.parse(baseUrl),
            headers: {
              'Authorization': 'Bearer $key',
              'Content-Type': 'application/json',
            },
            body: body,
          )
          .timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return TiledTsxMistralGroupingResult(
          suggestions: const <TiledTsxRoleAnimationSuggestion>[],
          rejectedAnimationIds: const <String>[],
          warnings: <String>['Mistral HTTP ${response.statusCode}.'],
        );
      }
      return parseTiledTsxMistralGroupingChatResponse(
        response.body,
        request: request,
      );
    } on TimeoutException {
      return const TiledTsxMistralGroupingResult(
        suggestions: <TiledTsxRoleAnimationSuggestion>[],
        rejectedAnimationIds: <String>[],
        warnings: <String>['Mistral timeout.'],
      );
    } catch (_) {
      return const TiledTsxMistralGroupingResult(
        suggestions: <TiledTsxRoleAnimationSuggestion>[],
        rejectedAnimationIds: <String>[],
        warnings: <String>['Analyse Mistral impossible.'],
      );
    }
  }

  Map<String, Object?> _jsonSchemaResponseFormat() {
    return {
      'type': 'json_schema',
      'json_schema': {
        'name': 'tiled_tsx_animation_grouping',
        'strict': true,
        'schema': {
          'type': 'object',
          'additionalProperties': false,
          'required': ['suggestions', 'rejectedAnimationIds', 'warnings'],
          'properties': {
            'suggestions': {
              'type': 'array',
              'items': {
                'type': 'object',
                'additionalProperties': false,
                'required': [
                  'role',
                  'animationId',
                  'confidence',
                  'evidenceAnimationIds',
                  'reason',
                ],
                'properties': {
                  'role': {
                    'type': 'string',
                    'enum': tiledTsxMistralAllowedRoleNames,
                  },
                  'animationId': {'type': 'string'},
                  'confidence': {
                    'type': 'string',
                    'enum': ['high', 'medium', 'low'],
                  },
                  'evidenceAnimationIds': {
                    'type': 'array',
                    'items': {'type': 'string'},
                  },
                  'reason': {'type': 'string'},
                },
              },
            },
            'rejectedAnimationIds': {
              'type': 'array',
              'items': {'type': 'string'},
            },
            'warnings': {
              'type': 'array',
              'items': {'type': 'string'},
            },
          },
        },
      },
    };
  }
}

TiledTsxMistralGroupingResult parseTiledTsxMistralGroupingChatResponse(
  String body, {
  required TiledTsxMistralGroupingRequest request,
}) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('root');
    }
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const FormatException('choices');
    }
    final first = choices.first;
    if (first is! Map<String, dynamic>) {
      throw const FormatException('choice');
    }
    final message = first['message'];
    if (message is! Map<String, dynamic>) {
      throw const FormatException('message');
    }
    final text = extractMistralAssistantTextContent(message['content']);
    if (text == null) {
      throw const FormatException('content text');
    }
    final payload = extractFirstJsonObjectFromMistralText(text);
    if (payload == null) {
      throw const FormatException('payload');
    }
    return parseTiledTsxMistralGroupingPayload(payload, request: request);
  } catch (e) {
    return TiledTsxMistralGroupingResult(
      suggestions: const <TiledTsxRoleAnimationSuggestion>[],
      rejectedAnimationIds: const <String>[],
      warnings: <String>['Réponse Mistral invalide: $e'],
    );
  }
}

TiledTsxMistralGroupingResult parseTiledTsxMistralGroupingPayload(
  Map<String, dynamic> payload, {
  required TiledTsxMistralGroupingRequest request,
}) {
  final selectedIds =
      request.animations.map((animation) => animation.id).toSet();
  final warnings = <String>[];
  final suggestions = <TiledTsxRoleAnimationSuggestion>[];
  final rejectedAnimationIds = <String>[];
  final usedRoles = <SurfaceVariantRole>{};
  final usedAnimationIds = <String>{};

  final rawWarnings = payload['warnings'];
  if (rawWarnings is List) {
    for (final warning in rawWarnings) {
      if (warning is String && warning.trim().isNotEmpty) {
        warnings.add(warning.trim());
      }
    }
  }

  final rawRejected = payload['rejectedAnimationIds'];
  if (rawRejected is List) {
    for (final id in rawRejected) {
      if (id is! String || id.trim().isEmpty) {
        warnings.add('Animation rejetée Mistral invalide ignorée.');
        continue;
      }
      final animationId = id.trim();
      if (!selectedIds.contains(animationId)) {
        warnings.add(
          'Animation rejetée Mistral inconnue ou non sélectionnée ignorée : $animationId.',
        );
        continue;
      }
      rejectedAnimationIds.add(animationId);
    }
  }

  final rawSuggestions = payload['suggestions'];
  if (rawSuggestions is! List) {
    warnings.add('Réponse Mistral sans suggestions.');
    return TiledTsxMistralGroupingResult(
      suggestions: const <TiledTsxRoleAnimationSuggestion>[],
      rejectedAnimationIds: List<String>.unmodifiable(rejectedAnimationIds),
      warnings: List<String>.unmodifiable(warnings),
    );
  }

  for (final item in rawSuggestions) {
    if (item is! Map<String, dynamic>) {
      warnings.add('Suggestion Mistral non objet rejetée.');
      continue;
    }
    final roleName = item['role'];
    final role = roleName is String ? tiledTsxRoleFromName(roleName) : null;
    if (role == null) {
      warnings.add('Rôle Mistral inconnu rejeté : $roleName.');
      continue;
    }
    if (usedRoles.contains(role)) {
      warnings.add('Rôle Mistral dupliqué rejeté : ${role.name}.');
      continue;
    }

    final rawAnimationId = item['animationId'];
    final animationId = rawAnimationId is String ? rawAnimationId.trim() : '';
    if (animationId.isEmpty || !selectedIds.contains(animationId)) {
      warnings.add(
        'Animation Mistral inconnue ou non sélectionnée rejetée pour ${role.name} : $rawAnimationId.',
      );
      continue;
    }
    if (usedAnimationIds.contains(animationId)) {
      warnings.add(
        'Animation Mistral dupliquée rejetée pour ${role.name} : $animationId.',
      );
      continue;
    }

    final confidence = _confidenceFromName(item['confidence']);
    if (confidence == null) {
      warnings.add('Confiance Mistral inconnue rejetée pour ${role.name}.');
      continue;
    }

    final evidence = _stringList(item['evidenceAnimationIds']);
    if (evidence.isEmpty) {
      warnings.add(
        'Suggestion Mistral sans evidenceAnimationIds rejetée pour ${role.name}.',
      );
      continue;
    }
    final unknownEvidence =
        evidence.where((id) => !selectedIds.contains(id)).toList();
    if (unknownEvidence.isNotEmpty) {
      warnings.add(
        'Evidence Mistral inconnue rejetée pour ${role.name} : ${unknownEvidence.first}.',
      );
      continue;
    }

    final reason = item['reason'];
    suggestions.add(
      TiledTsxRoleAnimationSuggestion(
        role: role,
        animationId: animationId,
        confidence: confidence,
        reason: reason is String && reason.trim().isNotEmpty
            ? reason.trim()
            : 'Suggestion Mistral sans raison détaillée.',
        evidenceAnimationIds: List<String>.unmodifiable(evidence),
      ),
    );
    usedRoles.add(role);
    usedAnimationIds.add(animationId);
  }

  return TiledTsxMistralGroupingResult(
    suggestions: List<TiledTsxRoleAnimationSuggestion>.unmodifiable(
      suggestions,
    ),
    rejectedAnimationIds: List<String>.unmodifiable(rejectedAnimationIds),
    warnings: List<String>.unmodifiable(warnings),
  );
}

SurfaceStudioMappingSuggestionConfidence? _confidenceFromName(Object? value) {
  if (value is! String) {
    return null;
  }
  for (final confidence in SurfaceStudioMappingSuggestionConfidence.values) {
    if (confidence.name == value) {
      return confidence;
    }
  }
  return null;
}

List<String> _stringList(Object? value) {
  if (value is! List) {
    return const <String>[];
  }
  final strings = <String>[];
  for (final raw in value) {
    if (raw is String && raw.trim().isNotEmpty) {
      strings.add(raw.trim());
    }
  }
  return strings;
}
