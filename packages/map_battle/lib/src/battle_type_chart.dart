import 'battle_typing.dart';

/// Type chart minimal mais canonique consommé par le moteur battle.
///
/// BE5 garde ce seam dans `map_battle` pour une raison simple :
/// - le runtime résout les types défensifs depuis les données projet ;
/// - le moteur battle, lui, décide des multiplicateurs de dégâts ;
/// - on évite ainsi de disperser la logique de type dans le runtime ou de
///   réintroduire une lecture JSON projet au mauvais endroit.
///
/// Décision de design :
/// - seules les interactions non neutres sont listées ;
/// - l'absence d'entrée vaut multiplicateur neutre `1.0` ;
/// - l'immunité est représentée par `0.0` ;
/// - on couvre le chart standard des 18 types, sans abilities, sans objets,
///   sans weather, sans effets spéciaux.
abstract final class BattleTypeChart {
  static const Set<String> supportedTypes = <String>{
    'normal',
    'fire',
    'water',
    'electric',
    'grass',
    'ice',
    'fighting',
    'poison',
    'ground',
    'flying',
    'psychic',
    'bug',
    'rock',
    'ghost',
    'dragon',
    'dark',
    'steel',
    'fairy',
  };

  static const Map<String, Map<String, double>> _chart =
      <String, Map<String, double>>{
    'normal': <String, double>{
      'rock': 0.5,
      'ghost': 0.0,
      'steel': 0.5,
    },
    'fire': <String, double>{
      'fire': 0.5,
      'water': 0.5,
      'grass': 2.0,
      'ice': 2.0,
      'bug': 2.0,
      'rock': 0.5,
      'dragon': 0.5,
      'steel': 2.0,
    },
    'water': <String, double>{
      'fire': 2.0,
      'water': 0.5,
      'grass': 0.5,
      'ground': 2.0,
      'rock': 2.0,
      'dragon': 0.5,
    },
    'electric': <String, double>{
      'water': 2.0,
      'electric': 0.5,
      'grass': 0.5,
      'ground': 0.0,
      'flying': 2.0,
      'dragon': 0.5,
    },
    'grass': <String, double>{
      'fire': 0.5,
      'water': 2.0,
      'grass': 0.5,
      'poison': 0.5,
      'ground': 2.0,
      'flying': 0.5,
      'bug': 0.5,
      'rock': 2.0,
      'dragon': 0.5,
      'steel': 0.5,
    },
    'ice': <String, double>{
      'fire': 0.5,
      'water': 0.5,
      'grass': 2.0,
      'ice': 0.5,
      'ground': 2.0,
      'flying': 2.0,
      'dragon': 2.0,
      'steel': 0.5,
    },
    'fighting': <String, double>{
      'normal': 2.0,
      'ice': 2.0,
      'poison': 0.5,
      'flying': 0.5,
      'psychic': 0.5,
      'bug': 0.5,
      'rock': 2.0,
      'ghost': 0.0,
      'dark': 2.0,
      'steel': 2.0,
      'fairy': 0.5,
    },
    'poison': <String, double>{
      'grass': 2.0,
      'poison': 0.5,
      'ground': 0.5,
      'rock': 0.5,
      'ghost': 0.5,
      'steel': 0.0,
      'fairy': 2.0,
    },
    'ground': <String, double>{
      'fire': 2.0,
      'electric': 2.0,
      'grass': 0.5,
      'poison': 2.0,
      'flying': 0.0,
      'bug': 0.5,
      'rock': 2.0,
      'steel': 2.0,
    },
    'flying': <String, double>{
      'electric': 0.5,
      'grass': 2.0,
      'fighting': 2.0,
      'bug': 2.0,
      'rock': 0.5,
      'steel': 0.5,
    },
    'psychic': <String, double>{
      'fighting': 2.0,
      'poison': 2.0,
      'psychic': 0.5,
      'dark': 0.0,
      'steel': 0.5,
    },
    'bug': <String, double>{
      'fire': 0.5,
      'grass': 2.0,
      'fighting': 0.5,
      'poison': 0.5,
      'flying': 0.5,
      'psychic': 2.0,
      'ghost': 0.5,
      'dark': 2.0,
      'steel': 0.5,
      'fairy': 0.5,
    },
    'rock': <String, double>{
      'fire': 2.0,
      'ice': 2.0,
      'fighting': 0.5,
      'ground': 0.5,
      'flying': 2.0,
      'bug': 2.0,
      'steel': 0.5,
    },
    'ghost': <String, double>{
      'normal': 0.0,
      'psychic': 2.0,
      'ghost': 2.0,
      'dark': 0.5,
    },
    'dragon': <String, double>{
      'dragon': 2.0,
      'steel': 0.5,
      'fairy': 0.0,
    },
    'dark': <String, double>{
      'fighting': 0.5,
      'psychic': 2.0,
      'ghost': 2.0,
      'dark': 0.5,
      'fairy': 0.5,
    },
    'steel': <String, double>{
      'fire': 0.5,
      'water': 0.5,
      'electric': 0.5,
      'ice': 2.0,
      'rock': 2.0,
      'steel': 0.5,
      'fairy': 2.0,
    },
    'fairy': <String, double>{
      'fire': 0.5,
      'fighting': 2.0,
      'poison': 0.5,
      'dragon': 2.0,
      'dark': 2.0,
      'steel': 0.5,
    },
  };

  static double resolveStabMultiplier({
    required String moveType,
    required BattleTypingSnapshot? attackerTyping,
  }) {
    final normalizedMoveType = moveType.trim().toLowerCase();
    if (normalizedMoveType.isEmpty ||
        normalizedMoveType == 'unknown' ||
        attackerTyping == null) {
      // Compatibilité volontaire avec les anciens call sites `map_battle`
      // qui construisent encore des setups pauvres à la main :
      // - si le typing n'est pas fourni, on n'invente pas un STAB ;
      // - le vrai chemin runtime -> battle, lui, doit fournir un typing
      //   explicite et ne passe pas par cette neutralisation.
      return 1.0;
    }

    _ensureSupportedType(
      normalizedMoveType,
      context: 'move type',
    );

    return attackerTyping.hasType(normalizedMoveType) ? 1.5 : 1.0;
  }

  static double resolveEffectivenessMultiplier({
    required String moveType,
    required BattleTypingSnapshot? defenderTyping,
  }) {
    final normalizedMoveType = moveType.trim().toLowerCase();
    if (normalizedMoveType.isEmpty ||
        normalizedMoveType == 'unknown' ||
        defenderTyping == null) {
      // Même dette de compatibilité que pour STAB :
      // - les setups battle directs historiques peuvent omettre le typing ;
      // - BE5 choisit alors la neutralité au lieu d'un faux typing inventé ;
      // - le runtime principal doit, lui, fournir un typing strict.
      return 1.0;
    }

    _ensureSupportedType(
      normalizedMoveType,
      context: 'move type',
    );

    var multiplier = 1.0;
    for (final defendingType in defenderTyping.types) {
      final normalizedDefendingType = defendingType.trim().toLowerCase();
      _ensureSupportedType(
        normalizedDefendingType,
        context: 'defender type',
      );
      multiplier *= _chart[normalizedMoveType]?[normalizedDefendingType] ?? 1.0;
    }
    return multiplier;
  }

  static void _ensureSupportedType(
    String normalizedType, {
    required String context,
  }) {
    if (supportedTypes.contains(normalizedType)) {
      return;
    }
    throw StateError(
      'Unsupported $context for BE5 type-aware damage: "$normalizedType".',
    );
  }
}
