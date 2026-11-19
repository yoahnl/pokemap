import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import 'runtime_map_bundle.dart';
import 'runtime_pokemon_species_loader.dart';

Future<Map<String, String>> loadRuntimeBattleSpeciesDisplayNames({
  required RuntimeMapBundle bundle,
  required RuntimePokemonSpeciesLoader speciesLoader,
  required BattleSession session,
  required RuntimeBattlePresentation? presentation,
  required String locale,
}) async {
  final species = await loadRuntimeBattleSpecies(
    bundle: bundle,
    speciesLoader: speciesLoader,
    session: session,
    presentation: presentation,
  );
  return Map.unmodifiable({
    for (final entry in species.values) entry.id: entry.displayName(locale),
  });
}

Future<Map<String, RuntimePokemonSpecies>> loadRuntimeBattleSpecies({
  required RuntimeMapBundle bundle,
  required RuntimePokemonSpeciesLoader speciesLoader,
  required BattleSession session,
  required RuntimeBattlePresentation? presentation,
}) async {
  final state = session.state;
  final speciesIds = <String>{
    ...?presentation?.activeCombatants.map(
      (active) => active.combatant.speciesId,
    ),
    state.player.speciesId,
    state.enemy.speciesId,
    for (final combatant in state.playerReserve) combatant.speciesId,
    for (final combatant in state.enemyReserve) combatant.speciesId,
  };
  final species = await Future.wait(
    speciesIds.map(
      (id) => speciesLoader.loadById(
        projectRootDirectory: bundle.projectRootDirectory,
        pokemonConfig: bundle.manifest.pokemon,
        speciesId: id,
      ),
    ),
  );
  return Map.unmodifiable({for (final entry in species) entry.id: entry});
}

String? runtimeBattlePlayerNickname(
  GameState state,
  List<int> lineupPartyIndices,
  int lineupIndex,
) {
  if (lineupIndex < 0 || lineupIndex >= lineupPartyIndices.length) {
    return null;
  }
  final partyIndex = lineupPartyIndices[lineupIndex];
  if (partyIndex < 0 || partyIndex >= state.party.members.length) {
    return null;
  }
  final nickname = state.party.members[partyIndex].nickname.trim();
  return nickname.isEmpty ? null : nickname;
}

enum RuntimeBattleVisualIdentityUnavailableReason {
  unknownSource,
  transformed,
  illusion,
  appearanceChanged,
}

final class RuntimeBattleVisualIdentity {
  const RuntimeBattleVisualIdentity({
    required this.speciesId,
    required this.formId,
    required this.genderId,
    required this.isShiny,
  });

  final String speciesId;
  final String? formId;
  final String? genderId;
  final bool? isShiny;
}

final class RuntimeBattleActiveCombatantProjection {
  const RuntimeBattleActiveCombatantProjection({
    required this.slot,
    required this.combatantId,
    required this.lineupIndex,
    required this.combatant,
    this.initialVisualIdentity,
    this.currentVisualIdentity,
    this.visualIdentityUnavailableReason =
        RuntimeBattleVisualIdentityUnavailableReason.unknownSource,
  });

  final BattleSlotRef slot;
  final String combatantId;
  final int lineupIndex;
  final BattleCombatant combatant;
  final RuntimeBattleVisualIdentity? initialVisualIdentity;
  final RuntimeBattleVisualIdentity? currentVisualIdentity;
  final RuntimeBattleVisualIdentityUnavailableReason?
  visualIdentityUnavailableReason;
}

final class RuntimeBattlePresentation {
  RuntimeBattlePresentation({
    required Iterable<RuntimeBattleActiveCombatantProjection> activeCombatants,
    required Iterable<BattleCombatant> playerParty,
    required this.request,
    required this.isDoubles,
  }) : activeCombatants = List.unmodifiable(activeCombatants),
       playerParty = List.unmodifiable(playerParty);

  final List<RuntimeBattleActiveCombatantProjection> activeCombatants;
  final List<BattleCombatant> playerParty;
  final BattleEngineDecisionRequest request;
  final bool isDoubles;

  Map<BattleSlotRef, BattleCombatant> get combatantsBySlot => Map.unmodifiable({
    for (final active in activeCombatants) active.slot: active.combatant,
  });

  RuntimeBattleActiveCombatantProjection? combatantAt(BattleSlotRef slot) =>
      activeCombatants.where((active) => active.slot == slot).firstOrNull;
}

BattleSlotRef runtimeBattleSlot(PsdkBattleSlotRef slot) => BattleSlotRef(
  side: switch (slot.bank) {
    0 => BattleSideId.player,
    1 => BattleSideId.enemy,
    _ => throw ArgumentError.value(slot.bank, 'bank'),
  },
  slotIndex: slot.position,
);

PsdkBattleSlotRef runtimePsdkBattleSlot(BattleSlotRef slot) =>
    PsdkBattleSlotRef(
      bank: slot.side == BattleSideId.player ? 0 : 1,
      position: slot.slotIndex,
    );
