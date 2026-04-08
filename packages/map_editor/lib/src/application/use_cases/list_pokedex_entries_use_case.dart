import '../models/pokedex_list_entry.dart';
import '../ports/project_workspace.dart';
import '../services/pokemon_project_data_reader.dart';

/// Première façade applicative Pokédex orientée liste, en lecture seule.
///
/// Le use case masque les détails de stockage local et retourne uniquement
/// un modèle applicatif exploitable par une future UI.
class ListPokedexEntriesUseCase {
  const ListPokedexEntriesUseCase({
    this.reader = const PokemonProjectDataReader(),
  });

  final PokemonProjectDataReader reader;

  Future<List<PokedexListEntry>> execute(ProjectWorkspace workspace) async {
    final speciesIndexEntries = await reader.listSpeciesIndexEntries(workspace);
    final pokedexEntries = <PokedexListEntry>[];

    for (final speciesIndexEntry in speciesIndexEntries) {
      // La liste légère donne l'identité et l'ordre. On relit ensuite l'espèce
      // détaillée pour les champs purement métier qui n'appartiennent pas à la
      // projection technique locale.
      final species = await reader.readSpeciesById(workspace, speciesIndexEntry.id);
      pokedexEntries.add(
        PokedexListEntry(
          id: speciesIndexEntry.id,
          nationalDex: speciesIndexEntry.nationalDex,
          primaryName: speciesIndexEntry.primaryName,
          types: speciesIndexEntry.types,
          isStarterEligible: species.gameplayFlags.starterEligible,
          genIntroduced: species.genIntroduced,
        ),
      );
    }

    pokedexEntries.sort((left, right) {
      final dexCompare = left.nationalDex.compareTo(right.nationalDex);
      if (dexCompare != 0) return dexCompare;
      return left.id.compareTo(right.id);
    });

    return pokedexEntries;
  }
}
