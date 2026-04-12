// Modèles de résolution d'une requête d'import Pokédex externe.
//
// Ce fichier ne représente PAS un import, une preview, un batch exécuté
// ni une interaction réseau.
//
// Il représente seulement l'intention utilisateur telle qu'elle a été
// comprise par le résolveur du lot 1 :
// - une cible unitaire par nom/id ;
// - un numéro Pokédex unique ;
// - une plage dex ;
// - une génération ;
// - une liste explicite séparée par des virgules ;
// - ou une requête invalide/ambiguë.
//
// Cette séparation est importante pour la suite de la roadmap :
// - l'UI n'a pas à parser la saisie ;
// - le pipeline d'import 11A n'a pas à être réécrit ;
// - le lot 1 fournit uniquement une base stable réutilisable par
//   l'auto-complétion mono-espèce, le batch preview et l'exécution batch.

/// Nature de la résolution produite par le résolveur.
///
/// L'objectif est de permettre à l'UI et aux use cases futurs de raisonner
/// sur une intention claire sans réinterpréter la string d'origine.
enum PokemonExternalQueryResolutionKind {
  singleQuery,
  explicitList,
  nationalDexRange,
  generation,
  invalid,
}

/// Type d'une cible unitaire dans la saisie.
///
/// Une cible unitaire peut être :
/// - une requête textuelle d'espèce (`bulbasaur`, `porygon-z`) ;
/// - un numéro Pokédex (`1`, `001`, `0001`).
///
/// On garde explicitement cette distinction parce qu'un batch explicite peut
/// mélanger les deux sans que cela doive devenir un problème UI.
enum PokemonExternalSingleQueryKind {
  species,
  nationalDex,
}

/// Codes d'erreur structurés pour les requêtes invalides.
///
/// Ces codes évitent de dépendre de simples messages texte dans les tests ou
/// dans l'UI future. Le message reste fourni pour l'utilisateur, mais le code
/// constitue la vraie convention stable.
enum PokemonExternalInvalidQueryCode {
  emptyQuery,
  ambiguousWhitespaceSeparatedTerms,
  invalidNationalDex,
  invalidNationalDexRange,
  invalidGeneration,
  invalidExplicitList,
  unsupportedFormat,
}

/// Représente une cible unitaire déjà normalisée.
///
/// Elle reste volontairement minimale :
/// - pas d'information réseau ;
/// - pas de résolution vers une vraie espèce projet/source ;
/// - seulement une expression canonique locale de la saisie utilisateur.
class PokemonExternalSingleQuery {
  /// Construit une cible unitaire textuelle.
  const PokemonExternalSingleQuery.species({
    required this.rawValue,
    required this.normalizedValue,
  })  : kind = PokemonExternalSingleQueryKind.species,
        nationalDex = null;

  /// Construit une cible unitaire de type numéro Pokédex.
  const PokemonExternalSingleQuery.nationalDex({
    required this.rawValue,
    required this.nationalDex,
  })  : kind = PokemonExternalSingleQueryKind.nationalDex,
        normalizedValue = null;

  final PokemonExternalSingleQueryKind kind;

  /// Fragment brut après nettoyage local de son entrée de liste éventuelle.
  final String rawValue;

  /// Valeur textuelle normalisée pour une requête d'espèce.
  ///
  /// Toujours en minuscules, avec espaces parasites supprimés.
  final String? normalizedValue;

  /// Numéro dex normalisé pour une requête numérique.
  final int? nationalDex;

  /// Clé stable de déduplication.
  ///
  /// La déduplication du lot 1 ne repose pas sur le texte brut saisi, mais sur
  /// l'intention canonique :
  /// - `001` et `1` doivent être vus comme la même cible ;
  /// - `Pikachu` et `pikachu` aussi.
  String get deduplicationKey => switch (kind) {
        PokemonExternalSingleQueryKind.species => 'species:$normalizedValue',
        PokemonExternalSingleQueryKind.nationalDex => 'dex:$nationalDex',
      };
}

/// Base commune de toutes les résolutions.
///
/// Toute résolution conserve :
/// - la saisie brute ;
/// - la saisie normalisée au niveau global ;
/// - le type de résolution obtenu.
sealed class PokemonExternalQueryResolution {
  const PokemonExternalQueryResolution({
    required this.rawQuery,
    required this.normalizedQuery,
  });

  final String rawQuery;
  final String normalizedQuery;

  PokemonExternalQueryResolutionKind get kind;
}

/// Résolution vers une seule cible.
final class PokemonExternalSingleQueryResolution
    extends PokemonExternalQueryResolution {
  const PokemonExternalSingleQueryResolution({
    required super.rawQuery,
    required super.normalizedQuery,
    required this.query,
  });

  final PokemonExternalSingleQuery query;

  @override
  PokemonExternalQueryResolutionKind get kind =>
      PokemonExternalQueryResolutionKind.singleQuery;
}

/// Résolution vers une liste explicite séparée par virgules.
final class PokemonExternalExplicitListQueryResolution
    extends PokemonExternalQueryResolution {
  PokemonExternalExplicitListQueryResolution({
    required super.rawQuery,
    required super.normalizedQuery,
    required List<PokemonExternalSingleQuery> queries,
  }) : queries = List<PokemonExternalSingleQuery>.unmodifiable(queries);

  /// Liste finale dédupliquée, dans l'ordre utilisateur stable.
  final List<PokemonExternalSingleQuery> queries;

  @override
  PokemonExternalQueryResolutionKind get kind =>
      PokemonExternalQueryResolutionKind.explicitList;
}

/// Résolution vers une plage dex.
final class PokemonExternalNationalDexRangeQueryResolution
    extends PokemonExternalQueryResolution {
  const PokemonExternalNationalDexRangeQueryResolution({
    required super.rawQuery,
    required super.normalizedQuery,
    required this.startNationalDex,
    required this.endNationalDex,
  });

  final int startNationalDex;
  final int endNationalDex;

  @override
  PokemonExternalQueryResolutionKind get kind =>
      PokemonExternalQueryResolutionKind.nationalDexRange;
}

/// Résolution vers une génération entière.
final class PokemonExternalGenerationQueryResolution
    extends PokemonExternalQueryResolution {
  const PokemonExternalGenerationQueryResolution({
    required super.rawQuery,
    required super.normalizedQuery,
    required this.generation,
  });

  final int generation;

  @override
  PokemonExternalQueryResolutionKind get kind =>
      PokemonExternalQueryResolutionKind.generation;
}

/// Résolution invalide ou ambiguë.
///
/// Ce type existe pour une raison de produit :
/// le lot 1 ne doit pas "deviner" silencieusement ce que l'utilisateur voulait
/// dire si la saisie est ambiguë. Il doit au contraire l'exprimer clairement.
final class PokemonExternalInvalidQueryResolution
    extends PokemonExternalQueryResolution {
  const PokemonExternalInvalidQueryResolution({
    required super.rawQuery,
    required super.normalizedQuery,
    required this.code,
    required this.message,
  });

  final PokemonExternalInvalidQueryCode code;
  final String message;

  @override
  PokemonExternalQueryResolutionKind get kind =>
      PokemonExternalQueryResolutionKind.invalid;
}
