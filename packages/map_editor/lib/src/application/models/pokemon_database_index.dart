import 'pokemon_project_data_models.dart';

/// References legeres exposees par l'index local Pokemon.
///
/// On regroupe ici uniquement les refs deja presentes dans le JSON espece.
/// Le but n'est pas d'introduire un nouveau contrat metier ; on fournit juste
/// une forme stable et lisible pour les prochains lots qui voudront afficher
/// une liste d'especes puis ouvrir des details ciblés.
class PokemonDatabaseIndexRefs {
  const PokemonDatabaseIndexRefs({
    required this.learnset,
    required this.evolution,
    required this.spriteSet,
    required this.cry,
  });

  final String learnset;
  final String evolution;
  final String spriteSet;
  final String cry;
}

/// Projection minimale d'une espece pour une future liste Pokédex.
///
/// Cette entree reste volontairement plus petite que `PokemonSpeciesFile` :
/// - pas de stats ;
/// - pas d'abilities ;
/// - pas de learnset charge ;
/// - pas de media detaille charge.
///
/// Le lot 11 ne cherche pas a remplacer les models de lecture existants.
/// Il pose seulement une projection liste, rapide a calculer, stable et
/// suffisamment explicite pour un futur outil no-code.
class PokemonDatabaseIndexEntry {
  const PokemonDatabaseIndexEntry({
    required this.id,
    required this.nationalDex,
    required this.primaryName,
    required this.refs,
  });

  final String id;
  final int nationalDex;
  final String primaryName;
  final PokemonDatabaseIndexRefs refs;

  /// Construit l'entree specifique au lot 11 a partir d'une source de vérité
  /// déjà existante.
  ///
  /// Le mini-fix 11b retire volontairement le mini parsing parallèle du JSON :
  /// - `PokemonSpeciesIndexEntry` fournit déjà `id`, `nationalDex` et
  ///   `primaryName` ;
  /// - `PokemonSpeciesFile` reste la source de vérité pour les refs.
  ///
  /// Cette factory ne décide donc plus comment parser le JSON ni comment
  /// calculer le nom principal. Elle assemble seulement une projection plus
  /// petite destinée à une future liste locale.
  factory PokemonDatabaseIndexEntry.fromSpeciesEntry({
    required PokemonSpeciesIndexEntry speciesIndexEntry,
    required PokemonSpeciesFile species,
  }) {
    return PokemonDatabaseIndexEntry(
      id: speciesIndexEntry.id,
      nationalDex: speciesIndexEntry.nationalDex,
      primaryName: speciesIndexEntry.primaryName,
      refs: PokemonDatabaseIndexRefs(
        learnset: species.learnsetRef.trim(),
        evolution: species.evolutionRef.trim(),
        spriteSet: species.spriteSetRef.trim(),
        cry: species.cryRef.trim(),
      ),
    );
  }
}
