import 'pokemon_external_query_resolution.dart';

/// Résultat structuré de la sélection batch externe.
///
/// Ce modèle existe pour un besoin produit précis du lot 3 :
/// - l'auteur peut saisir une requête batch ;
/// - l'application doit la comprendre et la résoudre en vraies cibles ;
/// - l'UI doit afficher cette résolution sans réinterpréter la requête.
///
/// Important :
/// - ce modèle ne représente pas encore un import réel ;
/// - ce modèle ne représente pas non plus le résultat du dry-run ;
/// - il ne fait qu'exprimer la sélection batch comprise par l'application.
enum PokemonExternalBatchSelectionResultKind {
  empty,
  resolved,
  invalidQuery,
  outOfScopeQuery,
  noResults,
  error,
}

/// Cible finale résolue pour une requête batch.
///
/// Une cible regroupe :
/// - l'espèce réellement ciblée ;
/// - ses informations utiles pour l'UI ;
/// - les entrées utilisateur qui ont conduit à cette cible.
///
/// Ce dernier point est important pour garder un dry-run honnête :
/// si `25, pikachu` résolvent tous deux vers `pikachu`, l'UI doit pouvoir le
/// montrer explicitement au lieu de faire disparaître le doublon sans trace.
class PokemonExternalBatchSelectionTarget {
  PokemonExternalBatchSelectionTarget({
    required this.speciesId,
    required this.primaryName,
    required this.nationalDex,
    required List<String> requestedInputs,
    this.generation,
  }) : requestedInputs = List<String>.unmodifiable(requestedInputs);

  final String speciesId;
  final String primaryName;
  final int nationalDex;
  final int? generation;
  final List<String> requestedInputs;
}

/// Sélection batch structurée et déjà résolue autant que possible.
///
/// Le contrat reste volontairement explicite :
/// - `empty` : rien à interpréter ;
/// - `resolved` : la liste finale de cibles est exploitable ;
/// - `invalidQuery` : la requête est syntaxiquement ou sémantiquement refusée ;
/// - `outOfScopeQuery` : la requête relève d'un autre mode (mono-espèce) ;
/// - `noResults` : la forme est valide, mais aucune espèce cible n'est sortie ;
/// - `error` : l'infrastructure de résolution n'a pas pu répondre.
class PokemonExternalBatchSelectionResult {
  PokemonExternalBatchSelectionResult._({
    required this.kind,
    required this.rawQuery,
    required this.normalizedQuery,
    this.resolution,
    List<PokemonExternalBatchSelectionTarget> targets =
        const <PokemonExternalBatchSelectionTarget>[],
    this.message,
  }) : targets =
            List<PokemonExternalBatchSelectionTarget>.unmodifiable(targets);

  factory PokemonExternalBatchSelectionResult.empty({
    required String rawQuery,
    required String normalizedQuery,
  }) {
    return PokemonExternalBatchSelectionResult._(
      kind: PokemonExternalBatchSelectionResultKind.empty,
      rawQuery: rawQuery,
      normalizedQuery: normalizedQuery,
    );
  }

  factory PokemonExternalBatchSelectionResult.resolved({
    required String rawQuery,
    required String normalizedQuery,
    required PokemonExternalQueryResolution resolution,
    required List<PokemonExternalBatchSelectionTarget> targets,
  }) {
    return PokemonExternalBatchSelectionResult._(
      kind: PokemonExternalBatchSelectionResultKind.resolved,
      rawQuery: rawQuery,
      normalizedQuery: normalizedQuery,
      resolution: resolution,
      targets: targets,
    );
  }

  factory PokemonExternalBatchSelectionResult.invalidQuery({
    required String rawQuery,
    required String normalizedQuery,
    required PokemonExternalQueryResolution resolution,
    required String message,
    List<PokemonExternalBatchSelectionTarget> targets =
        const <PokemonExternalBatchSelectionTarget>[],
  }) {
    return PokemonExternalBatchSelectionResult._(
      kind: PokemonExternalBatchSelectionResultKind.invalidQuery,
      rawQuery: rawQuery,
      normalizedQuery: normalizedQuery,
      resolution: resolution,
      targets: targets,
      message: message,
    );
  }

  factory PokemonExternalBatchSelectionResult.outOfScopeQuery({
    required String rawQuery,
    required String normalizedQuery,
    required PokemonExternalQueryResolution resolution,
    required String message,
  }) {
    return PokemonExternalBatchSelectionResult._(
      kind: PokemonExternalBatchSelectionResultKind.outOfScopeQuery,
      rawQuery: rawQuery,
      normalizedQuery: normalizedQuery,
      resolution: resolution,
      message: message,
    );
  }

  factory PokemonExternalBatchSelectionResult.noResults({
    required String rawQuery,
    required String normalizedQuery,
    required PokemonExternalQueryResolution resolution,
    required String message,
  }) {
    return PokemonExternalBatchSelectionResult._(
      kind: PokemonExternalBatchSelectionResultKind.noResults,
      rawQuery: rawQuery,
      normalizedQuery: normalizedQuery,
      resolution: resolution,
      message: message,
    );
  }

  factory PokemonExternalBatchSelectionResult.error({
    required String rawQuery,
    required String normalizedQuery,
    required PokemonExternalQueryResolution resolution,
    required String message,
  }) {
    return PokemonExternalBatchSelectionResult._(
      kind: PokemonExternalBatchSelectionResultKind.error,
      rawQuery: rawQuery,
      normalizedQuery: normalizedQuery,
      resolution: resolution,
      message: message,
    );
  }

  final PokemonExternalBatchSelectionResultKind kind;
  final String rawQuery;
  final String normalizedQuery;
  final PokemonExternalQueryResolution? resolution;
  final List<PokemonExternalBatchSelectionTarget> targets;
  final String? message;

  /// Le dry-run ne doit être déclenché que sur une sélection réellement
  /// exploitable : type `resolved` + au moins une cible.
  bool get canDryRun =>
      kind == PokemonExternalBatchSelectionResultKind.resolved &&
      targets.isNotEmpty;

  bool get hasTargets => targets.isNotEmpty;

  /// Liste stable des espèces réellement ciblées.
  ///
  /// Cette liste sert ensuite directement au batch applicatif existant,
  /// toujours sans réinterprétation UI de la requête.
  List<String> get resolvedSpeciesIds =>
      targets.map((target) => target.speciesId).toList(growable: false);

  /// Nombre total d'entrées utilisateur agrégées dans les cibles finales.
  int get requestedInputCount => targets.fold<int>(
        0,
        (count, target) => count + target.requestedInputs.length,
      );
}
