enum PokemonEvolutionRuleKind {
  level,
  friendship,
  knownMove,
  item,
  trade,
  unsupported,
}

final class PokemonEvolutionRule {
  const PokemonEvolutionRule(
    this.kind,
    this.sentence, {
    required this.executable,
  });

  final PokemonEvolutionRuleKind kind;
  final String sentence;
  final bool executable;
}

const pokemonGuidedEvolutionMethods = {
  'level_up': 'Montée de niveau',
  'friendship': 'Montée de niveau avec amitié',
  'known_move': 'Montée de niveau avec une attaque connue',
  'use_item': 'Utilisation d’un objet',
};

String pokemonEvolutionMethodLabel(String method) => switch (method) {
  final known when pokemonGuidedEvolutionMethods.containsKey(known) =>
    pokemonGuidedEvolutionMethods[known]!,
  'item' => 'Utilisation d’un objet · item',
  'trade' => 'Échange',
  '' => 'Aucune méthode',
  _ => 'Non prise en charge · $method',
};

PokemonEvolutionRuleKind pokemonEvolutionRuleKind(Map<String, dynamic> entry) {
  final method = '${entry['method'] ?? ''}'.trim();
  final move = '${entry['requiredMoveId'] ?? ''}'.trim();
  return switch (method) {
    'trade' => PokemonEvolutionRuleKind.trade,
    'level_up' when entry['minFriendship'] != null =>
      PokemonEvolutionRuleKind.friendship,
    'friendship' => PokemonEvolutionRuleKind.friendship,
    'level_up' when move.isNotEmpty => PokemonEvolutionRuleKind.knownMove,
    'known_move' => PokemonEvolutionRuleKind.knownMove,
    'level_up' => PokemonEvolutionRuleKind.level,
    'use_item' || 'item' => PokemonEvolutionRuleKind.item,
    _ => PokemonEvolutionRuleKind.unsupported,
  };
}

PokemonEvolutionRule pokemonEvolutionRule(
  Map<String, dynamic> entry, {
  String Function(String id)? itemName,
  String Function(String id)? moveName,
}) {
  final kind = pokemonEvolutionRuleKind(entry);
  final method = '${entry['method'] ?? ''}'.trim();
  PokemonEvolutionRule refused(String sentence) =>
      PokemonEvolutionRule(kind, sentence, executable: false);
  PokemonEvolutionRule runs(String sentence) =>
      PokemonEvolutionRule(kind, sentence, executable: true);
  final rawLevel = entry['minLevel'];
  final minimumLevel = kind == PokemonEvolutionRuleKind.item ? 1 : 2;
  final level =
      rawLevel ??
      (kind == PokemonEvolutionRuleKind.level ? null : minimumLevel);
  String? levelProblem() {
    if (level == null) {
      return 'Règle incomplète : indiquez un niveau minimum, sinon le jeu refusera de charger cette évolution.';
    }
    if (level is! int || level < minimumLevel || level > 100) {
      return 'Règle invalide : le niveau minimum doit être compris entre $minimumLevel et 100, sinon le jeu refusera de charger cette évolution.';
    }
    return null;
  }

  switch (kind) {
    case PokemonEvolutionRuleKind.unsupported:
      return refused(
        method.isEmpty
            ? 'Méthode absente : le jeu refusera de charger cette évolution.'
            : 'Méthode non prise en charge par le jeu : « $method ». Elle ne s’exécute pas et reste conservée sans changement.',
      );
    case PokemonEvolutionRuleKind.trade:
      return runs(
        'Le jeu le fait évoluer lors d’un échange avec un personnage. Ses exigences d’échange sont conservées et ne se modifient pas dans cette fiche.',
      );
    case PokemonEvolutionRuleKind.level:
      if (levelProblem() case final problem?) return refused(problem);
      return runs(
        'Le jeu le fait évoluer en montant au niveau $level ou plus.',
      );
    case PokemonEvolutionRuleKind.friendship:
      final friendship = entry['minFriendship'];
      if (friendship is! int || friendship < 1 || friendship > 255) {
        return refused(
          'Règle incomplète : indiquez une amitié minimum entre 1 et 255, sinon le jeu refusera de charger cette évolution.',
        );
      }
      if (levelProblem() case final problem?) return refused(problem);
      return runs(
        'Le jeu le fait évoluer en montant de niveau avec une amitié d’au moins $friendship, dès le niveau $level.',
      );
    case PokemonEvolutionRuleKind.knownMove:
      final move = '${entry['requiredMoveId'] ?? ''}'.trim();
      if (move.isEmpty) {
        return refused(
          'Règle incomplète : choisissez l’attaque requise, sinon le jeu refusera de charger cette évolution.',
        );
      }
      if (levelProblem() case final problem?) return refused(problem);
      return runs(
        'Le jeu le fait évoluer en montant de niveau s’il connaît ${moveName?.call(move) ?? move}, dès le niveau $level.',
      );
    case PokemonEvolutionRuleKind.item:
      final item = '${entry['itemId'] ?? ''}'.trim();
      if (item.isEmpty) {
        return refused(
          'Règle incomplète : choisissez l’objet à utiliser, sinon le jeu refusera de charger cette évolution.',
        );
      }
      if (levelProblem() case final problem?) return refused(problem);
      return runs(
        'Le jeu le fait évoluer quand on utilise ${itemName?.call(item) ?? item} sur lui, dès le niveau $level.',
      );
  }
}
