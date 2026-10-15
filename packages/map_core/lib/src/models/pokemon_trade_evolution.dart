enum PokemonPassiveHeldEffect {
  preventEvolution;

  String get id => switch (this) {
    PokemonPassiveHeldEffect.preventEvolution => 'prevent_evolution',
  };

  static PokemonPassiveHeldEffect? fromId(String? id) => switch (id) {
    'prevent_evolution' => PokemonPassiveHeldEffect.preventEvolution,
    _ => null,
  };
}

final class PokemonTradeEvolutionRequirements {
  const PokemonTradeEvolutionRequirements({
    this.requiredHeldItemId,
    this.requiredPartnerSpeciesId,
  });

  final String? requiredHeldItemId;
  final String? requiredPartnerSpeciesId;

  factory PokemonTradeEvolutionRequirements.fromJson(
    Map<String, dynamic> json,
  ) {
    if (json.keys.any(
      (key) => !const {
        'requiredHeldItemId',
        'requiredPartnerSpeciesId',
      }.contains(key),
    )) {
      throw const FormatException(
        'Unknown native trade evolution requirement.',
      );
    }
    final item = json['requiredHeldItemId'];
    final partner = json['requiredPartnerSpeciesId'];
    if ((item != null && item is! String) ||
        (partner != null && partner is! String)) {
      throw const FormatException(
        'Native trade evolution ids must be strings.',
      );
    }
    return PokemonTradeEvolutionRequirements(
      requiredHeldItemId: item as String?,
      requiredPartnerSpeciesId: partner as String?,
    ).validated();
  }

  PokemonTradeEvolutionRequirements validated() {
    for (final id in [requiredHeldItemId, requiredPartnerSpeciesId]) {
      if (id != null && !RegExp(r'^[a-z0-9][a-z0-9_-]*$').hasMatch(id)) {
        throw const FormatException('Invalid native trade evolution id.');
      }
    }
    return this;
  }

  Map<String, Object?> toJson() => {
    if (requiredHeldItemId != null) 'requiredHeldItemId': requiredHeldItemId,
    if (requiredPartnerSpeciesId != null)
      'requiredPartnerSpeciesId': requiredPartnerSpeciesId,
  };
}
