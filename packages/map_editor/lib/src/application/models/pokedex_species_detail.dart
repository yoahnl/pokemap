import 'pokemon_project_data_models.dart';

/// Agrégat de détail Pokédex en lecture seule.
///
/// Ce modèle n'est pas un nouveau format de stockage. Il sert seulement à
/// rassembler, pour une espèce sélectionnée, les fichiers locaux déjà existants
/// afin que la UI affiche une fiche détail sans réinventer son propre contrat.
class PokedexSpeciesDetail {
  const PokedexSpeciesDetail({
    required this.species,
    this.learnset,
    this.evolution,
    this.media,
  });

  final PokemonSpeciesFile species;
  final PokemonLearnsetFile? learnset;
  final PokemonEvolutionFile? evolution;
  final PokemonMediaFile? media;
}
