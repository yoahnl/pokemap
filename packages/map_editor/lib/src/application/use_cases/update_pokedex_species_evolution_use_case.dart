import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/pokemon_read_repository.dart';
import '../ports/pokemon_write_repository.dart';
import '../ports/project_workspace.dart';

/// Surface d'édition locale du lot 42.
class UpdatePokedexSpeciesEvolutionRequest {
  const UpdatePokedexSpeciesEvolutionRequest({
    required this.speciesId,
    required this.preEvolution,
    required this.evolutions,
  });

  final String speciesId;
  final String? preEvolution;
  final List<PokemonEvolutionEntry> evolutions;
}

typedef PokedexSpeciesEvolutionSaver = Future<PokemonEvolutionFile> Function(
  ProjectWorkspace workspace,
  UpdatePokedexSpeciesEvolutionRequest request,
);

/// Réécrit la chaîne d'évolution locale d'une espèce.
///
/// On reste volontairement sur le modèle déjà supporté :
/// - `preEvolution`
/// - `targetSpeciesId`
/// - `method`
/// - `minLevel`
/// - `itemId`
/// - `requiredMoveId`
/// - `conditionText`
///
/// Aucun élargissement de schéma n'est introduit ici.
class UpdatePokedexSpeciesEvolutionUseCase {
  const UpdatePokedexSpeciesEvolutionUseCase({
    required this.readRepository,
    required this.writeRepository,
  });

  final PokemonReadRepository readRepository;
  final PokemonWriteRepository writeRepository;

  Future<PokemonEvolutionFile> execute(
    ProjectWorkspace workspace,
    UpdatePokedexSpeciesEvolutionRequest request,
  ) async {
    final speciesId = request.speciesId.trim();
    if (speciesId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon species id cannot be empty',
      );
    }

    final currentSpecies = await readRepository.readSpeciesById(
      workspace,
      speciesId,
    );
    final evolutionRef = currentSpecies.refs.evolution.trim();
    if (evolutionRef.isEmpty) {
      throw const EditorValidationException(
        'Pokemon species evolution ref cannot be empty',
      );
    }

    final evolution = PokemonEvolutionFile(
      speciesId: evolutionRef,
      preEvolution: _normalizeOptionalText(request.preEvolution),
      evolutions: _normalizeEntries(request.evolutions),
    );

    _validateEvolution(
      evolution,
      ownerSpeciesId: currentSpecies.id,
    );
    await writeRepository.saveEvolution(workspace, evolution);
    return evolution;
  }

  List<PokemonEvolutionEntry> _normalizeEntries(
    List<PokemonEvolutionEntry> values,
  ) {
    return values
        .map(
          (entry) => PokemonEvolutionEntry(
            targetSpeciesId: entry.targetSpeciesId.trim(),
            method: entry.method.trim(),
            minLevel: entry.minLevel,
            itemId: _normalizeOptionalText(entry.itemId),
            requiredMoveId: _normalizeOptionalText(entry.requiredMoveId),
            conditionText: _normalizeLocalizedValues(entry.conditionText),
          ),
        )
        .toList(growable: false);
  }

  Map<String, String> _normalizeLocalizedValues(Map<String, String> values) {
    final normalized = <String, String>{};
    for (final entry in values.entries) {
      final locale = entry.key.trim();
      final value = entry.value.trim();
      if (locale.isEmpty || value.isEmpty) {
        continue;
      }
      normalized[locale] = value;
    }
    return normalized;
  }

  void _validateEvolution(
    PokemonEvolutionFile evolution, {
    required String ownerSpeciesId,
  }) {
    final speciesId = evolution.speciesId.trim();
    if (speciesId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon evolution speciesId cannot be empty',
      );
    }

    final hasPreEvolution = evolution.preEvolution != null &&
        evolution.preEvolution!.trim().isNotEmpty;
    if (!hasPreEvolution && evolution.evolutions.isEmpty) {
      throw const EditorValidationException(
        'Pokemon evolution must define preEvolution or evolutions',
      );
    }

    for (final entry in evolution.evolutions) {
      final targetSpeciesId = entry.targetSpeciesId.trim();
      if (targetSpeciesId.isEmpty) {
        throw const EditorValidationException(
          'Pokemon evolution targetSpeciesId cannot be empty',
        );
      }
      if (targetSpeciesId == ownerSpeciesId.trim()) {
        throw const EditorValidationException(
          'Pokemon evolution cannot target itself',
        );
      }
      if (entry.method.trim().isEmpty) {
        throw const EditorValidationException(
          'Pokemon evolution method cannot be empty',
        );
      }
      if (entry.method.trim() == 'level_up' &&
          entry.minLevel != null &&
          entry.minLevel! <= 0) {
        throw const EditorValidationException(
          'Pokemon evolution minLevel must be positive for level_up',
        );
      }
    }
  }

  String? _normalizeOptionalText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
