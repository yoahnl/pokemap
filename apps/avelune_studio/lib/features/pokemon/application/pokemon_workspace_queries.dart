part of 'pokemon_workspace_controller.dart';

extension PokemonWorkspaceQueries on PokemonWorkspaceController {
  List<PokemonSpeciesSummary> get visibleSpecies {
    final needle = search.trim().toLowerCase();
    return [
      for (final entry in index?.entries ?? const <PokemonSpeciesSummary>[])
        if ((needle.isEmpty ||
                entry.name.toLowerCase().contains(needle) ||
                entry.id.toLowerCase().contains(needle)) &&
            (typeFilter == null || entry.types.contains(typeFilter)) &&
            (generationFilter == null ||
                entry.generation == generationFilter) &&
            (enabledFilter == null || entry.enabled == enabledFilter))
          entry,
    ];
  }
}
