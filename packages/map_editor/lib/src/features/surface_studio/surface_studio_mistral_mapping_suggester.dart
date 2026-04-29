import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';

import 'surface_studio_ai_mapping_suggester.dart';
import 'surface_studio_mapping_suggestion_models.dart';
import 'surface_studio_mapping_suggestion_prompt_builder.dart';

final class SurfaceStudioMistralMappingSuggester
    implements SurfaceStudioAiMappingSuggester {
  SurfaceStudioMistralMappingSuggester({
    http.Client? httpClient,
    this.baseUrl = 'https://api.mistral.ai/v1/chat/completions',
    this.model = 'mistral-small-2506',
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

    final prompt = buildSurfaceStudioMappingSuggestionPrompt(
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      columnCount: columnCount,
      frameCount: frameCount,
    );
    final imageDataUrl = _imageDataUrl(imageBytes);
    final body = jsonEncode({
      'model': model,
      'temperature': 0,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': prompt},
            {'type': 'image_url', 'image_url': imageDataUrl},
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

  String _imageDataUrl(Uint8List bytes) {
    img.Image? decoded;
    try {
      decoded = img.decodeImage(bytes);
    } catch (_) {
      decoded = null;
    }
    if (decoded == null) {
      return 'data:image/png;base64,${base64Encode(bytes)}';
    }
    final longest =
        decoded.width > decoded.height ? decoded.width : decoded.height;
    final normalized = longest > 768
        ? img.copyResize(
            decoded,
            width: decoded.width >= decoded.height ? 768 : null,
            height: decoded.height > decoded.width ? 768 : null,
          )
        : decoded;
    return 'data:image/png;base64,${base64Encode(img.encodePng(normalized))}';
  }

  SurfaceStudioMappingSuggestionResult _parseChatResponse(
    String body, {
    required int columnCount,
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
      return _parsePayload(payload, columnCount: columnCount);
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
  }) {
    final warnings = <String>[];
    final rawWarnings = payload['warnings'];
    if (rawWarnings is List) {
      for (final warning in rawWarnings) {
        if (warning is String && warning.trim().isNotEmpty) {
          warnings.add(warning.trim());
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
      if (role != SurfaceVariantRole.isolated && columns.length > 1) {
        warnings
            .add('Suggestion Mistral multi-colonnes rejetée pour $roleName.');
        continue;
      }
      final confidence = _confidenceFromName(item['confidence']);
      if (confidence == null) {
        warnings.add('Confiance Mistral inconnue rejetée pour $roleName.');
        continue;
      }
      final reason = item['reason'];
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
