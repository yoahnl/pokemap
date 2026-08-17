import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

/// Fiche Pokémon canonique partagée par l'Équipe et le PC.
///
/// Les deux surfaces construisaient leur propre projection : l'Équipe
/// localisait les noms d'espèces, le PC affichait des identifiants bruts, et
/// aucune des deux ne montrait l'expérience ni les stats. Toute donnée
/// affichable est résolue ici une fois, pour que « la même fiche » soit une
/// propriété du modèle et non une discipline d'écriture d'UI.
final class RuntimePokemonSummarySnapshot {
  RuntimePokemonSummarySnapshot({
    required this.targetId,
    required this.individualId,
    required this.speciesLabel,
    required this.nickname,
    required this.level,
    required this.currentHp,
    required this.maxHp,
    required this.natureLabel,
    required this.abilityLabel,
    required this.friendship,
    this.formLabel,
    this.experience,
    this.stats,
    this.genderLabel,
    this.isShiny = false,
    this.heldItemLabel,
    this.statusLabel,
    List<RuntimePokemonMoveSummarySnapshot> moves =
        const <RuntimePokemonMoveSummarySnapshot>[],
    this.provenance,
  })  : moves = List<RuntimePokemonMoveSummarySnapshot>.unmodifiable(moves),
        assert(targetId != ''),
        assert(speciesLabel != ''),
        assert(level > 0),
        assert(currentHp >= 0),
        assert(maxHp > 0),
        assert(friendship >= 0 && friendship <= 255);

  /// Cible opaque échangée avec l'UI. Seul le runtime l'interprète.
  final String targetId;

  /// Vide pour une sauvegarde antérieure à l'attribution des identités.
  ///
  /// Un transfert Équipe/PC ne conserve la fiche que si cette identité existe :
  /// sans elle, la cible retombe sur une position, qui change au dépôt.
  final String individualId;

  final String speciesLabel;
  final String nickname;
  final String? formLabel;
  final int level;
  final int? experience;
  final int currentHp;
  final int maxHp;
  final RuntimePokemonStatsSummarySnapshot? stats;
  final String natureLabel;
  final String abilityLabel;
  final String? genderLabel;
  final bool isShiny;
  final String? heldItemLabel;
  final String? statusLabel;
  final int friendship;
  final List<RuntimePokemonMoveSummarySnapshot> moves;
  final RuntimePokemonProvenanceSummarySnapshot? provenance;

  String get displayLabel => nickname.isEmpty ? speciesLabel : nickname;

  bool get hasStableIdentity => individualId.isNotEmpty;

  bool get isFainted => currentHp <= 0;

  double get hpRatio {
    final ratio = currentHp / maxHp;
    return ratio < 0 ? 0 : (ratio > 1 ? 1 : ratio);
  }
}

final class RuntimePokemonStatsSummarySnapshot {
  const RuntimePokemonStatsSummarySnapshot({
    required this.attack,
    required this.defense,
    required this.specialAttack,
    required this.specialDefense,
    required this.speed,
  });

  final int attack;
  final int defense;
  final int specialAttack;
  final int specialDefense;
  final int speed;
}

final class RuntimePokemonMoveSummarySnapshot {
  const RuntimePokemonMoveSummarySnapshot({
    required this.moveId,
    required this.label,
    this.typeLabel,
    this.currentPp,
    this.maxPp,
  });

  final String moveId;
  final String label;
  final String? typeLabel;

  /// `null` quand la sauvegarde précède le suivi des PP : afficher « — »
  /// plutôt que zéro, qui se lirait comme une capacité épuisée.
  final int? currentPp;
  final int? maxPp;

  bool get hasPpTracking => currentPp != null && maxPp != null;
}

final class RuntimePokemonProvenanceSummarySnapshot {
  const RuntimePokemonProvenanceSummarySnapshot({
    required this.originLabel,
    this.metMapLabel,
    this.metSourceLabel,
    this.metLevel,
    this.ballLabel,
  });

  final String originLabel;
  final String? metMapLabel;
  final String? metSourceLabel;
  final int? metLevel;
  final String? ballLabel;
}

/// Résolveurs fournis par l'appelant.
///
/// Le builder ne connaît ni les chargeurs ni les caches : l'Équipe et le PC
/// n'exposent pas les mêmes catalogues, et c'est précisément la raison pour
/// laquelle ils avaient divergé.
final class RuntimePokemonSummaryResolvers {
  const RuntimePokemonSummaryResolvers({
    required this.speciesLabelFor,
    this.calculatedStatsFor,
    this.itemLabelFor,
    this.moveFor,
  });

  final String Function(String speciesId) speciesLabelFor;
  final PokemonCalculatedStats? Function(PlayerPokemon pokemon)?
      calculatedStatsFor;
  final String? Function(String itemId)? itemLabelFor;
  final PokemonMove? Function(String moveId)? moveFor;
}

final class RuntimePokemonSummaryBuilder {
  const RuntimePokemonSummaryBuilder({
    required this.locale,
    required this.resolvers,
  });

  final String locale;
  final RuntimePokemonSummaryResolvers resolvers;

  bool get _isFrench => locale.toLowerCase().startsWith('fr');

  RuntimePokemonSummarySnapshot build(
    PlayerPokemon pokemon, {
    required String targetId,
  }) {
    final calculated = resolvers.calculatedStatsFor?.call(pokemon);
    // Une sauvegarde peut porter des PV supérieurs au maximum calculable
    // lorsque l'espèce n'expose pas de stats de base. Le plancher évite une
    // barre de vie négative et un maxHp nul.
    final persistedFloor = pokemon.currentHp > 0 ? pokemon.currentHp : 1;
    final resolvedMaxHp = calculated?.maxHp;
    final maxHp = resolvedMaxHp == null || resolvedMaxHp < persistedFloor
        ? persistedFloor
        : resolvedMaxHp;
    final heldItemId = pokemon.heldItemId.trim();
    final statusId = pokemon.statusId.trim();
    final formId = pokemon.formId.trim();

    return RuntimePokemonSummarySnapshot(
      targetId: targetId,
      individualId: pokemon.individualId.trim(),
      speciesLabel: resolvers.speciesLabelFor(pokemon.speciesId),
      nickname: pokemon.nickname.trim(),
      formLabel: formId.isEmpty ? null : runtimePokemonHumanizeId(formId),
      level: pokemon.level,
      experience: pokemon.experience,
      currentHp: pokemon.currentHp.clamp(0, maxHp),
      maxHp: maxHp,
      stats: calculated == null
          ? null
          : RuntimePokemonStatsSummarySnapshot(
              attack: calculated.attack,
              defense: calculated.defense,
              specialAttack: calculated.specialAttack,
              specialDefense: calculated.specialDefense,
              speed: calculated.speed,
            ),
      natureLabel: runtimePokemonHumanizeId(pokemon.natureId),
      abilityLabel: runtimePokemonHumanizeId(pokemon.abilityId),
      genderLabel: _genderLabel(pokemon.gender),
      isShiny: pokemon.isShiny,
      heldItemLabel: heldItemId.isEmpty
          ? null
          : resolvers.itemLabelFor?.call(heldItemId) ??
              runtimePokemonHumanizeId(heldItemId),
      statusLabel:
          statusId.isEmpty ? null : runtimePokemonHumanizeId(statusId),
      friendship: pokemon.friendship,
      moves: _buildMoves(pokemon),
      provenance: _buildProvenance(pokemon.provenance),
    );
  }

  List<RuntimePokemonMoveSummarySnapshot> _buildMoves(PlayerPokemon pokemon) {
    final currentPpByMoveId = pokemon.currentPpByMoveId;
    return <RuntimePokemonMoveSummarySnapshot>[
      for (final moveId in pokemon.knownMoveIds)
        () {
          final move = resolvers.moveFor?.call(moveId);
          final maxPp = move != null && move.pp > 0 ? move.pp : null;
          final currentPp = currentPpByMoveId?[moveId];
          return RuntimePokemonMoveSummarySnapshot(
            moveId: moveId,
            label: move?.displayName(locale) ??
                runtimePokemonHumanizeId(moveId),
            typeLabel: move == null
                ? null
                : runtimePokemonHumanizeId(move.type),
            currentPp: maxPp == null || currentPp == null
                ? null
                : currentPp.clamp(0, maxPp),
            maxPp: maxPp,
          );
        }(),
    ];
  }

  RuntimePokemonProvenanceSummarySnapshot? _buildProvenance(
    PlayerPokemonProvenance? provenance,
  ) {
    if (provenance == null) {
      return null;
    }
    final mapId = provenance.mapId.trim();
    final sourceId = provenance.sourceId.trim();
    final ballItemId = provenance.ballItemId.trim();
    return RuntimePokemonProvenanceSummarySnapshot(
      originLabel: runtimePokemonOriginLabel(
        provenance.kind,
        isFrench: _isFrench,
      ),
      metMapLabel: mapId.isEmpty ? null : runtimePokemonHumanizeId(mapId),
      metSourceLabel:
          sourceId.isEmpty ? null : runtimePokemonHumanizeId(sourceId),
      metLevel: provenance.metLevel,
      ballLabel: ballItemId.isEmpty
          ? null
          : resolvers.itemLabelFor?.call(ballItemId) ??
              runtimePokemonHumanizeId(ballItemId),
    );
  }

  String? _genderLabel(String? gender) {
    final normalized = gender?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return switch (normalized) {
      'male' || 'm' => _isFrench ? 'Mâle' : 'Male',
      'female' || 'f' => _isFrench ? 'Femelle' : 'Female',
      'genderless' || 'none' || 'n' =>
        _isFrench ? 'Asexué' : 'Genderless',
      _ => runtimePokemonHumanizeId(normalized),
    };
  }
}

/// Raccourci pour les deux appelants réels, qui fournissent tous les mêmes
/// résolveurs sous des formes légèrement différentes.
RuntimePokemonSummaryBuilder runtimePokemonSummaryBuilderFor({
  required String locale,
  required String Function(String speciesId) speciesLabelFor,
  PokemonCalculatedStats? Function(PlayerPokemon pokemon)? calculatedStatsFor,
  String? Function(String itemId)? itemLabelFor,
  PokemonMove? Function(String moveId)? moveFor,
}) =>
    RuntimePokemonSummaryBuilder(
      locale: locale,
      resolvers: RuntimePokemonSummaryResolvers(
        speciesLabelFor: speciesLabelFor,
        calculatedStatsFor: calculatedStatsFor,
        itemLabelFor: itemLabelFor,
        moveFor: moveFor,
      ),
    );

String runtimePokemonHumanizeId(String identifier) {
  final words = identifier
      .trim()
      .replaceAll(RegExp('[-_]'), ' ')
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty);
  if (words.isEmpty) {
    return identifier.trim();
  }
  return words
      .map(
        (word) => '${word.substring(0, 1).toUpperCase()}'
            '${word.substring(1).toLowerCase()}',
      )
      .join(' ');
}

/// Libellés reproduits à l'identique depuis les deux surfaces, où ils
/// étaient déjà dupliqués mot pour mot. Cette copie est la seule qui reste.
String runtimePokemonOriginLabel(
  PlayerPokemonOriginKind kind, {
  required bool isFrench,
}) =>
    switch (kind) {
      PlayerPokemonOriginKind.captured => isFrench ? 'Capturé' : 'Captured',
      PlayerPokemonOriginKind.gift => isFrench ? 'Cadeau' : 'Gift',
      PlayerPokemonOriginKind.starter => 'Starter',
      PlayerPokemonOriginKind.trade => isFrench ? 'Échange' : 'Trade',
      PlayerPokemonOriginKind.scripted => isFrench ? 'Événement' : 'Event',
      PlayerPokemonOriginKind.unknown => isFrench ? 'Inconnue' : 'Unknown',
    };
