import 'package:map_core/map_core.dart';

import 'surface_studio_mapping_suggestion_models.dart';

final class SurfaceStudioLocalMappingSuggester {
  const SurfaceStudioLocalMappingSuggester();

  SurfaceStudioMappingSuggestionResult suggest({required int columnCount}) {
    if (columnCount <= 0) {
      return const SurfaceStudioMappingSuggestionResult(
        suggestions: <SurfaceStudioRoleSuggestion>[],
        warnings: <String>[
          'Aucune colonne disponible pour proposer un mapping.',
        ],
        source: SurfaceStudioMappingSuggestionSource.local,
      );
    }

    final suggestions = <SurfaceStudioRoleSuggestion>[];
    final warnings = <String>[];
    final usedColumns = <int>{};
    final centerColumns = _centerColumns(columnCount);
    usedColumns.addAll(centerColumns);
    suggestions.add(
      SurfaceStudioRoleSuggestion(
        role: SurfaceVariantRole.isolated,
        columns: centerColumns,
        confidence: centerColumns.length >= 2
            ? SurfaceStudioMappingSuggestionConfidence.medium
            : SurfaceStudioMappingSuggestionConfidence.low,
        source: SurfaceStudioMappingSuggestionSource.local,
        reason:
            'Le rôle Plein accepte plusieurs colonnes ; la suggestion locale choisit une plage centrale bornée par l’atlas.',
      ),
    );
    if (centerColumns.length > 1) {
      warnings.add(
        'Plein peut recevoir plusieurs colonnes, mais la génération V2.1 utilise seulement la première colonne pour les animations.',
      );
    }

    var nextColumn = 1;
    for (final role in standardSurfaceVariantRoleOrder) {
      if (role == SurfaceVariantRole.isolated) {
        continue;
      }
      while (nextColumn <= columnCount && usedColumns.contains(nextColumn)) {
        nextColumn++;
      }
      if (nextColumn > columnCount) {
        break;
      }
      suggestions.add(
        SurfaceStudioRoleSuggestion(
          role: role,
          columns: <int>[nextColumn],
          confidence: SurfaceStudioMappingSuggestionConfidence.low,
          source: SurfaceStudioMappingSuggestionSource.local,
          reason:
              'Assignation déterministe selon l’ordre standard des rôles Surface.',
        ),
      );
      usedColumns.add(nextColumn);
      nextColumn++;
    }

    if (suggestions.length < standardSurfaceVariantRoleOrder.length) {
      warnings.add(
        'L’atlas ne contient pas assez de colonnes pour couvrir tous les rôles standard.',
      );
    }

    return SurfaceStudioMappingSuggestionResult(
      suggestions: List<SurfaceStudioRoleSuggestion>.unmodifiable(suggestions),
      warnings: List<String>.unmodifiable(warnings),
      source: SurfaceStudioMappingSuggestionSource.local,
    );
  }

  List<int> _centerColumns(int columnCount) {
    if (columnCount >= 6) {
      return <int>[4, 5, 6].where((column) => column <= columnCount).toList();
    }
    if (columnCount >= 3) {
      return const <int>[1, 2, 3];
    }
    return <int>[1];
  }
}
