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
    required this.media,
  });

  final String learnset;
  final String evolution;
  final String media;
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
    required this.genIntroduced,
    required this.types,
    required this.isEnabledInProject,
    required this.refs,
    this.portraitRelativePath,
  });

  final String id;
  final int nationalDex;
  final String primaryName;
  final int genIntroduced;
  final List<String> types;

  /// Le lot 38 a besoin d'un filtre activée/désactivée directement sur la
  /// projection légère de liste.
  ///
  /// On expose donc uniquement le booléen déjà présent dans
  /// `PokemonSpeciesClassification.isEnabledInProject`, sans embarquer toute la
  /// classification détaillée dans l'index.
  final bool isEnabledInProject;
  final PokemonDatabaseIndexRefs refs;

  /// Portrait local optionnel pour embellir la liste Pokédex.
  ///
  /// Cette donnée reste volontairement légère et décorative :
  /// - elle ne remplace pas le chargement complet de la fiche média ;
  /// - elle n'est présente que si un `media.json` lisible pointe vers un
  ///   portrait et que le fichier existe réellement dans le workspace ;
  /// - son absence ne doit jamais bloquer la liste.
  ///
  /// On conserve ici un chemin **relatif projet** plutôt qu'un chemin absolu :
  /// - l'application garde une projection portable ;
  /// - l'UI résout ensuite le chemin absolu à partir du workspace courant ;
  /// - on évite d'enfermer ce modèle applicatif dans un chemin machine-local.
  final String? portraitRelativePath;

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
  ///
  /// Le lot 13 ajoute `types` à cette projection légère.
  /// Pourquoi ici :
  /// - la liste Pokédex simple doit montrer les types ;
  /// - `PokemonSpeciesIndexEntry` les possède déjà sans nouvelle lecture disque ;
  /// - les propager ici évite d’inventer un second pipeline UI parallèle.
  ///
  /// Le lot 15 ajoute `genIntroduced` à la même projection légère.
  /// Pourquoi ce petit élargissement reste légitime :
  /// - le filtre génération a été demandé sur la liste existante ;
  /// - `PokemonSpeciesFile` expose déjà `genIntroduced` comme donnée locale
  ///   lecture seule ;
  /// - on continue à réutiliser le pipeline d’index courant au lieu de créer une
  ///   nouvelle façade ou de relire autre chose depuis la UI.
  ///
  /// Le lot 38 ajoute `isEnabledInProject` à la même projection légère.
  /// Pourquoi ce booléen précis est légitime ici :
  /// - la liste Pokédex doit filtrer "Toutes / Activées / Désactivées" ;
  /// - la source de vérité existe déjà dans `PokemonSpeciesFile.classification`;
  /// - on évite ainsi de charger la fiche détail juste pour un filtre liste ;
  /// - on n'introduit toujours aucun second état parallèle pour le statut.
  ///
  /// Le scope reste strict :
  /// - on ne charge toujours ni learnsets, ni évolutions, ni médias ;
  /// - on n’ajoute aucun détail riche de fiche Pokémon ;
  /// - on complète seulement la projection minimale utile à la liste locale et
  ///   à ses filtres simples.
  factory PokemonDatabaseIndexEntry.fromSpeciesEntry({
    required PokemonSpeciesIndexEntry speciesIndexEntry,
    required PokemonSpeciesFile species,
    String? portraitRelativePath,
  }) {
    return PokemonDatabaseIndexEntry(
      id: speciesIndexEntry.id,
      nationalDex: speciesIndexEntry.nationalDex,
      primaryName: speciesIndexEntry.primaryName,
      genIntroduced: species.genIntroduced,
      types: List<String>.from(speciesIndexEntry.types),
      isEnabledInProject: species.classification.isEnabledInProject,
      refs: PokemonDatabaseIndexRefs(
        learnset: species.refs.learnset.trim(),
        evolution: species.refs.evolution.trim(),
        media: species.refs.media.trim(),
      ),
      portraitRelativePath: portraitRelativePath?.trim().isEmpty ?? true
          ? null
          : portraitRelativePath?.trim(),
    );
  }
}
