import 'dart:convert';

import 'package:map_core/map_core.dart';

import 'surface_studio_mapping_suggestion_models.dart';
import 'surface_studio_mistral_vision_pack.dart';

const String surfaceStudioMistralLegacySchemaWarning =
    'Réponse Mistral sans rejectedColumns/evidenceColumns, compat legacy appliquée.';

String? extractMistralAssistantTextContent(Object? content) {
  if (content is String) {
    final trimmed = content.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  if (content is! List) {
    return null;
  }
  final buffer = StringBuffer();
  for (final part in content) {
    if (part is! Map) {
      continue;
    }
    if (part['type'] != 'text') {
      continue;
    }
    final text = part['text'];
    if (text is String && text.isNotEmpty) {
      buffer.write(text);
    }
  }
  final trimmed = buffer.toString().trim();
  return trimmed.isEmpty ? null : trimmed;
}

Map<String, dynamic>? extractFirstJsonObjectFromMistralText(String text) {
  final trimmed = text.trim();
  try {
    final decoded = jsonDecode(trimmed);
    return decoded is Map<String, dynamic> ? decoded : null;
  } catch (_) {
    // Fall through to balanced-object extraction for providers that wrap JSON.
  }

  var start = -1;
  var depth = 0;
  var inString = false;
  var escaped = false;
  for (var i = 0; i < trimmed.length; i++) {
    final codeUnit = trimmed.codeUnitAt(i);
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (codeUnit == 0x5C) {
        escaped = true;
      } else if (codeUnit == 0x22) {
        inString = false;
      }
      continue;
    }
    if (codeUnit == 0x22) {
      inString = true;
      continue;
    }
    if (codeUnit == 0x7B) {
      if (depth == 0) {
        start = i;
      }
      depth++;
      continue;
    }
    if (codeUnit != 0x7D || depth == 0) {
      continue;
    }
    depth--;
    if (depth == 0 && start >= 0) {
      try {
        final decoded = jsonDecode(trimmed.substring(start, i + 1));
        return decoded is Map<String, dynamic> ? decoded : null;
      } catch (_) {
        return null;
      }
    }
  }
  return null;
}

SurfaceStudioMappingSuggestionResult parseSurfaceStudioMistralChatResponse(
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
    final text = extractMistralAssistantTextContent(message['content']);
    if (text == null) {
      throw const FormatException('content text');
    }
    final payload = extractFirstJsonObjectFromMistralText(text);
    if (payload == null) {
      throw const FormatException('payload');
    }
    final wrappedJson = text.trim() != jsonEncode(payload);
    return parseSurfaceStudioMistralSuggestionPayload(
      payload,
      columnCount: columnCount,
      columnDescriptors: columnDescriptors,
      wrappedJson: wrappedJson,
    );
  } catch (e) {
    return SurfaceStudioMappingSuggestionResult(
      suggestions: const <SurfaceStudioRoleSuggestion>[],
      warnings: <String>['Réponse Mistral invalide: $e'],
      source: SurfaceStudioMappingSuggestionSource.mistral,
    );
  }
}

SurfaceStudioMappingSuggestionResult parseSurfaceStudioMistralSuggestionPayload(
  Map<String, dynamic> payload, {
  required int columnCount,
  required List<SurfaceStudioColumnVisualDescriptor> columnDescriptors,
  bool wrappedJson = false,
}) {
  final warnings = <String>[];
  if (wrappedJson) {
    warnings.add(
      'Réponse Mistral avec texte autour du JSON, premier objet JSON utilisé.',
    );
  }
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

  final assignments = payload['assignments'];
  if (assignments is! List) {
    warnings.add('Réponse Mistral sans assignments.');
    return SurfaceStudioMappingSuggestionResult(
      suggestions: const <SurfaceStudioRoleSuggestion>[],
      warnings: List<String>.unmodifiable(warnings),
      source: SurfaceStudioMappingSuggestionSource.mistral,
    );
  }

  final hasRejectedColumns = payload['rejectedColumns'] is List;
  final hasEveryEvidenceColumn = assignments.every(
    (item) => item is Map<String, dynamic> && item['evidenceColumns'] is List,
  );
  if (!hasRejectedColumns || !hasEveryEvidenceColumn) {
    warnings.add(surfaceStudioMistralLegacySchemaWarning);
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
        warnings.add('Mistral a rejeté la colonne $column : ${reason.trim()}');
      }
    }
  }

  final suggestions = <SurfaceStudioRoleSuggestion>[];
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
      warnings.add('Assignation Mistral sans colonne rejetée pour $roleName.');
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
      warnings.add('Suggestion Mistral multi-colonnes rejetée pour $roleName.');
      continue;
    }

    final rawEvidenceColumns = item['evidenceColumns'];
    final evidenceColumns = rawEvidenceColumns is List
        ? _parseColumns(rawEvidenceColumns)
        : List<int>.of(columns);
    if (evidenceColumns.isEmpty) {
      warnings.add(
        'Suggestion Mistral sans evidenceColumns rejetée pour $roleName.',
      );
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
