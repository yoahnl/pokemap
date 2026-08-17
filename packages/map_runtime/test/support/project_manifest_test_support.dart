import 'package:map_core/map_core.dart';

/// Ajoute le ruleset Pokémon canonique à un JSON de projet construit en test.
///
/// `ProjectManifest.fromJson` exige un `pokemon.ruleset` explicite : un projet
/// ne doit pas pouvoir se charger avec des règles implicites. Les fixtures
/// générées en code testent le chargement de cartes, d'éléments ou de
/// scénarios et n'ont aucune raison de décrire un ruleset ; leur en donner un
/// ici les garde alignées sur ce que porte un vrai projet, sans recopier
/// dix-neuf lignes dans chaque fichier de test.
///
/// À utiliser uniquement pour les fixtures qui traversent le vrai chargeur.
/// Un test qui vérifie précisément le refus d'un projet sans ruleset doit
/// évidemment écrire son JSON sans passer par ici.
Map<String, dynamic> withPokeMapBetaPokemonRuleset(
  Map<String, dynamic> projectJson,
) {
  final result = Map<String, dynamic>.from(projectJson);
  final pokemon = result['pokemon'];
  result['pokemon'] = <String, dynamic>{
    if (pokemon is Map) ...Map<String, dynamic>.from(pokemon),
    'ruleset': PokemonRulesetProfile.pokeMapBetaV1.toJson(),
  };
  return result;
}
