import 'package:map_core/map_core_domain.dart';

const pokemonTrainerMoveLimit = 4;

const pokemonTrainerMoveLimitRefusal =
    'Un Pokémon de dresseur a au maximum $pokemonTrainerMoveLimit attaques : retirez-en une avant d’en ajouter une autre.';

bool pokemonTrainerCanAddMove(ProjectTrainerPokemonEntry member) =>
    member.moves.length < pokemonTrainerMoveLimit;

bool pokemonTrainerMoveCountRefused(int before, int after) =>
    after > pokemonTrainerMoveLimit && after > before;

String pokemonTrainerMoveLimitProblem(String speciesId, int count) =>
    'Le Pokémon $speciesId du dresseur a $count attaques : un Pokémon de dresseur en a au maximum $pokemonTrainerMoveLimit.';
