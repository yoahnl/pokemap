import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:map_core/map_core.dart';

import 'surface_studio_ai_mapping_suggester.dart';
import 'surface_studio_mapping_suggestion_models.dart';
import 'surface_studio_mapping_suggestion_prompt_builder.dart';
import 'surface_studio_mistral_vision_pack.dart';

final class SurfaceStudioMistralMappingSuggester
    implements SurfaceStudioAiMappingSuggester {
  SurfaceStudioMistralMappingSuggester({
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
  Future<SurfaceStudioMappingSuggestionResult> suggest({
    required String apiKey,
    required Uint8List imageBytes,
    required int tileWidth,
    required int tileHeight,
    required int columnCount,
    required int frameCount,
  }) async {
    final key = apiKey.trim();
    if (key.isEmpty) {
      return const SurfaceStudioMappingSuggestionResult(
        suggestions: <SurfaceStudioRoleSuggestion>[],
        warnings: <String>['Clé Mistral absente.'],
        source: SurfaceStudioMappingSuggestionSource.mistral,
      );
    }

    final visionPack = buildSurfaceStudioMistralVisionPack(
      imageBytes: imageBytes,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      columnCount: columnCount,
      frameCount: frameCount,
    );
    final prompt = buildSurfaceStudioMappingSuggestionPrompt(
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      columnCount: columnCount,
      frameCount: frameCount,
      columnDescriptors: visionPack.columnDescriptors,
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
              'image_url': visionPack.originalAtlasDataUrl,
            },
            {
              'type': 'image_url',
              'image_url': visionPack.annotatedAtlasDataUrl,
            },
            {
              'type': 'image_url',
              'image_url': visionPack.columnContactSheetDataUrl,
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
        return SurfaceStudioMappingSuggestionResult(
          suggestions: const <SurfaceStudioRoleSuggestion>[],
          warnings: <String>['Mistral HTTP ${response.statusCode}.'],
          source: SurfaceStudioMappingSuggestionSource.mistral,
        );
      }
      return _parseChatResponse(
        response.body,
        columnCount: columnCount,
        columnDescriptors: visionPack.columnDescriptors,
      );
    } on TimeoutException {
      return const SurfaceStudioMappingSuggestionResult(
        suggestions: <SurfaceStudioRoleSuggestion>[],
        warnings: <String>['Mistral timeout.'],
        source: SurfaceStudioMappingSuggestionSource.mistral,
      );
    } catch (_) {
      return const SurfaceStudioMappingSuggestionResult(
        suggestions: <SurfaceStudioRoleSuggestion>[],
        warnings: <String>['Analyse Mistral impossible.'],
        source: SurfaceStudioMappingSuggestionSource.mistral,
      );
    }
  }

  Map<String, Object?> _jsonSchemaResponseFormat() {
    return {
      'type': 'json_schema',
      'json_schema': {
        'name': 'surface_studio_mapping_suggestion',
        'strict': true,
        'schema': {
          'type': 'object',
          'additionalProperties': false,
          'required': ['assignments', 'rejectedColumns', 'warnings'],
          'properties': {
            'assignments': {
              'type': 'array',
              'items': {
                'type': 'object',
                'additionalProperties': false,
                'required': [
                  'role',
                  'columns',
                  'confidence',
                  'evidenceColumns',
                  'reason',
                ],
                'properties': {
                  'role': {
                    'type': 'string',
                    'enum': surfaceStudioMistralAllowedRoleNames,
                  },
                  'columns': {
                    'type': 'array',
                    'items': {'type': 'integer'},
                  },
                  'confidence': {
                    'type': 'string',
                    'enum': ['high', 'medium', 'low'],
                  },
                  'evidenceColumns': {
                    'type': 'array',
                    'items': {'type': 'integer'},
                  },
                  'reason': {'type': 'string'},
                },
              },
            },
            'rejectedColumns': {
              'type': 'array',
              'items': {
                'type': 'object',
                'additionalProperties': false,
                'required': ['column', 'reason'],
                'properties': {
                  'column': {'type': 'integer'},
                  'reason': {'type': 'string'},
                },
              },
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

  SurfaceStudioMappingSuggestionResult _parseChatResponse(
    String body, {
    required int columnCount,
    required List<SurfaceStudioColumnVisualDescriptor> columnDescriptors,
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
      final content = message['content'];
      if (content is! String) {
        throw const FormatException('content');
      }
      final payload = jsonDecode(content);
      if (payload is! Map<String, dynamic>) {
        throw const FormatException('payload');
      }
      return _parsePayload(
        payload,
        columnCount: columnCount,
        columnDescriptors: columnDescriptors,
      );
    } catch (e) {
      return SurfaceStudioMappingSuggestionResult(
        suggestions: const <SurfaceStudioRoleSuggestion>[],
        warnings: <String>['Réponse Mistral invalide: $e'],
        source: SurfaceStudioMappingSuggestionSource.mistral,
      );
    }
  }

  SurfaceStudioMappingSuggestionResult _parsePayload(
    Map<String, dynamic> payload, {
    required int columnCount,
    required List<SurfaceStudioColumnVisualDescriptor> columnDescriptors,
  }) {
    final warnings = <String>[];
    final descriptorsByColumn = <int, SurfaceStudioColumnVisualDescriptor>{
      for (final descriptor in columnDescriptors) descriptor.column: descriptor,
    };
    final likelyEmptyColumns = descriptorsByColumn.values
        .where((descriptor) => descriptor.likelyEmpty)
        .map((descriptor) => descriptor.column)
        .toSet();
    final rawWarnings = payload['warnings'];
    if (rawWarnings is List) {
      for (final warning in rawWarnings) {
        if (warning is String && warning.trim().isNotEmpty) {
          warnings.add(warning.trim());
        }
      }
    }
    final rejectedColumns = payload['rejectedColumns'];
    if (rejectedColumns is List) {
      for (final rejected in rejectedColumns) {
        if (rejected is! Map<String, dynamic>) {
          warnings.add('Colonne rejetée Mistral non objet ignorée.');
          continue;
        }
        final column = rejected['column'];
        final reason = rejected['reason'];
        if (column is! int || column < 1 || column > columnCount) {
          warnings.add('Colonne rejetée Mistral hors bornes ignorée.');
          continue;
        }
        if (reason is String && reason.trim().isNotEmpty) {
          warnings
              .add('Mistral a rejeté la colonne $column : ${reason.trim()}');
        }
      }
    }

    final suggestions = <SurfaceStudioRoleSuggestion>[];
    final assignments = payload['assignments'];
    if (assignments is! List) {
      warnings.add('Réponse Mistral sans assignments.');
      return SurfaceStudioMappingSuggestionResult(
        suggestions: const <SurfaceStudioRoleSuggestion>[],
        warnings: List<String>.unmodifiable(warnings),
        source: SurfaceStudioMappingSuggestionSource.mistral,
      );
    }

    for (final item in assignments) {
      if (item is! Map<String, dynamic>) {
        warnings.add('Assignation Mistral non objet rejetée.');
        continue;
      }
      final roleName = item['role'];
      final role = roleName is String ? _roleFromName(roleName) : null;
      if (role == null) {
        warnings.add('Rôle Mistral inconnu rejeté : $roleName.');
        continue;
      }
      final columns = _parseColumns(item['columns']);
      if (columns.isEmpty) {
        warnings
            .add('Assignation Mistral sans colonne rejetée pour $roleName.');
        continue;
      }
      final outOfRange =
          columns.where((column) => column < 1 || column > columnCount);
      if (outOfRange.isNotEmpty) {
        warnings.add(
          'Colonne Mistral hors bornes rejetée pour $roleName : ${outOfRange.first}.',
        );
        continue;
      }
      int? emptyColumn;
      for (final column in columns) {
        if (likelyEmptyColumns.contains(column)) {
          emptyColumn = column;
          break;
        }
      }
      if (emptyColumn != null) {
        warnings.add(
          'Suggestion Mistral sur colonne likelyEmpty rejetée pour $roleName : $emptyColumn.',
        );
        continue;
      }
      if (role != SurfaceVariantRole.isolated && columns.length > 1) {
        warnings
            .add('Suggestion Mistral multi-colonnes rejetée pour $roleName.');
        continue;
      }
      final evidenceColumns = _parseColumns(item['evidenceColumns']);
      if (evidenceColumns.isEmpty) {
        warnings.add(
            'Suggestion Mistral sans evidenceColumns rejetée pour $roleName.');
        continue;
      }
      final evidenceOutOfRange = evidenceColumns.where(
        (column) => column < 1 || column > columnCount,
      );
      if (evidenceOutOfRange.isNotEmpty) {
        warnings.add(
          'Evidence Mistral hors bornes rejetée pour $roleName : ${evidenceOutOfRange.first}.',
        );
        continue;
      }
      final confidence = _confidenceFromName(item['confidence']);
      if (confidence == null) {
        warnings.add('Confiance Mistral inconnue rejetée pour $roleName.');
        continue;
      }
      final reason = item['reason'];
      for (final column in columns) {
        final descriptor = descriptorsByColumn[column];
        if (descriptor == null) {
          continue;
        }
        if (!descriptor.localCandidateRoles.contains(role.name)) {
          warnings.add(
            'Mistral contredit l’analyse locale pour ${role.name} colonne $column.',
          );
        }
      }
      suggestions.add(
        SurfaceStudioRoleSuggestion(
          role: role,
          columns: List<int>.unmodifiable(columns),
          confidence: confidence,
          source: SurfaceStudioMappingSuggestionSource.mistral,
          reason: reason is String && reason.trim().isNotEmpty
              ? reason.trim()
              : 'Suggestion Mistral sans raison détaillée.',
        ),
      );
    }

    return SurfaceStudioMappingSuggestionResult(
      suggestions: List<SurfaceStudioRoleSuggestion>.unmodifiable(suggestions),
      warnings: List<String>.unmodifiable(warnings),
      source: SurfaceStudioMappingSuggestionSource.mistral,
    );
  }

  SurfaceVariantRole? _roleFromName(String name) {
    for (final role in standardSurfaceVariantRoleOrder) {
      if (role.name == name) {
        return role;
      }
    }
    return null;
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

  List<int> _parseColumns(Object? value) {
    if (value is! List) {
      return const <int>[];
    }
    final columns = <int>[];
    for (final raw in value) {
      if (raw is int) {
        columns.add(raw);
      }
    }
    return columns;
  }
}
