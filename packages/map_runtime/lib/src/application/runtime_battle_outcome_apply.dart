import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'battle_start_request.dart';
import 'runtime_battle_combatant_seed_builder.dart';
import 'runtime_battle_status_bridge.dart';
import 'story_flags_manager.dart';

/// Contexte runtime strictement nécessaire pour faire le write-back post-combat.
///
/// Invariant critique :
/// - [playerPartyIndex] est l'index exact du slot utilisé au moment du handoff
///   vers le combat ;
/// - il reste utile pour la compatibilité historique mono-slot et pour le
///   whiteout-lite ;
/// - BE10 ajoute en plus [playerPartySlotIndicesByLineupIndex] pour couvrir
///   honnêtement les combats où plusieurs membres sont réellement engagés.
///
/// Cette structure reste volontairement petite :
/// - la requête d'origine pour savoir si le combat était wild ou trainer ;
/// - l'index du slot joueur initial ;
/// - le mapping lineup battle -> slots runtime quand BE10 l'exige ;
/// - rien de plus.
class RuntimeActiveBattleContext {
  const RuntimeActiveBattleContext({
    required this.request,
    required this.playerPartyIndex,
  }) : playerPartySlotIndicesByLineupIndex = const <int>[];

  factory RuntimeActiveBattleContext.withLineupMapping({
    required BattleStartRequest request,
    required int playerPartyIndex,
    required Iterable<int> playerPartySlotIndicesByLineupIndex,
  }) {
    return RuntimeActiveBattleContext._(
      request: request,
      playerPartyIndex: playerPartyIndex,
      playerPartySlotIndicesByLineupIndex: List<int>.unmodifiable(
        playerPartySlotIndicesByLineupIndex,
      ),
    );
  }

  const RuntimeActiveBattleContext._({
    required this.request,
    required this.playerPartyIndex,
    required this.playerPartySlotIndicesByLineupIndex,
  });

  final BattleStartRequest request;
  final int playerPartyIndex;

  /// Mapping stable lineup battle joueur -> slots de party runtime.
  ///
  /// BE10 ajoute ce seam parce que le joueur peut désormais switcher pendant
  /// le combat :
  /// - `playerPartyIndex` seul ne suffit plus pour réécrire honnêtement les
  ///   PV de plusieurs membres engagés ;
  /// - le runtime mémorise donc l'ordre exact actif + réserves injecté dans
  ///   `BattleSetup` ;
  /// - `map_battle` garde ensuite une identité de lineup stable malgré les
  ///   switches, et le write-back peut retrouver les bons slots sans rejouer
  ///   l'historique du combat.
  ///
  /// Compatibilité volontaire :
  /// - l'ancien chemin mono-slot peut laisser cette liste vide ;
  /// - mais ce fallback n'est honnête que tant que le combat n'a réellement
  ///   engagé qu'un seul membre joueur ;
  /// - dès qu'un `BattleOutcome.finalState` BE10 transporte une vraie réserve
  ///   joueur, ce mapping devient obligatoire pour éviter d'écrire les PV sur
  ///   un slot runtime arbitraire.
  final List<int> playerPartySlotIndicesByLineupIndex;
}

/// Typed successful-attempt identity extracted from an engine result.
final class _RuntimeBattleEngineCaptureAttempt {
  const _RuntimeBattleEngineCaptureAttempt({
    required this.attemptId,
    required this.itemId,
  });

  final String attemptId;
  final String itemId;
}

/// Extracts a successful capture only when legacy outcome and turn trace agree.
_RuntimeBattleEngineCaptureAttempt? _extractLegacyBattleCaptureAttempt(
  BattleSession session,
) {
  final outcome = session.state.outcome;
  if (outcome?.type != BattleOutcomeType.captured) {
    return null;
  }
  final attemptId = outcome!.captureAttemptId;
  final itemId = outcome.captureItemId;
  final matchingEvents = session.state.currentTurn?.captureAttemptEvents.where(
        (event) =>
            event.caught &&
            event.attemptId == attemptId &&
            event.ballId == itemId,
      ) ??
      const Iterable<BattleCaptureAttemptEvent>.empty();
  if (attemptId == null ||
      itemId == null ||
      attemptId.isEmpty ||
      matchingEvents.length != 1) {
    throw StateError(
      'Legacy captured outcome does not match exactly one successful attempt.',
    );
  }
  return _RuntimeBattleEngineCaptureAttempt(
    attemptId: attemptId,
    itemId: itemId,
  );
}

/// Extracts a successful capture only when PSDK outcome and timeline agree.
_RuntimeBattleEngineCaptureAttempt? _extractPsdkBattleCaptureAttempt(
  BattleEngineTurnResult result,
) {
  final outcome = result.outcome;
  if (outcome?.kind != BattleEngineOutcomeKind.captured) {
    return null;
  }
  final attemptId = outcome!.captureAttemptId;
  final matchingEvents = result.timeline.events
      .whereType<BattleCaptureAttemptTimelineEvent>()
      .where((event) => event.caught && event.attemptId == attemptId)
      .toList(growable: false);
  if (attemptId == null || attemptId.isEmpty || matchingEvents.length != 1) {
    throw StateError(
      'PSDK captured outcome does not match exactly one successful attempt.',
    );
  }
  return _RuntimeBattleEngineCaptureAttempt(
    attemptId: attemptId,
    itemId: matchingEvents.single.ballId,
  );
}

/// One-shot proof that the runtime charged one exact successful attempt.
final class RuntimeBattleCaptureAttemptReceipt {
  RuntimeBattleCaptureAttemptReceipt._({
    required this.requestId,
    required this.itemId,
    required this.attemptId,
  });

  final String requestId;
  final String itemId;
  final String attemptId;
  bool _isClaimed = false;

  void _claim() {
    if (_isClaimed) {
      throw StateError('Capture attempt receipt was already claimed.');
    }
    _isClaimed = true;
  }
}

/// Atomic result returned only after the engine accepted a capture attempt.
final class RuntimeBattleCaptureAttemptSubmission<T> {
  const RuntimeBattleCaptureAttemptSubmission({
    required this.updatedGameState,
    required this.engineResult,
    required this.receipt,
    required this.consumptionReceipt,
  });

  final GameState updatedGameState;
  final T engineResult;
  final RuntimeBattleCaptureAttemptReceipt? receipt;
  final ItemConsumptionReceipt consumptionReceipt;
}

/// Charges exactly one selected capture item iff [submitToEngine] completes.
///
/// The input [GameState] is immutable. The charged state is returned only
/// after engine submission succeeds, so a thrown engine/application error
/// leaves the caller with its original, uncharged state.
RuntimeBattleCaptureAttemptSubmission<T> submitRuntimeBattleCaptureAttempt<T>({
  required GameState gameState,
  required RuntimeActiveBattleContext context,
  required bool captureAllowed,
  required String itemId,
  required ItemCatalogSnapshot itemCatalog,
  required T Function() submitToEngine,
}) {
  final request = context.request;
  if (request is! WildBattleStartRequest || !captureAllowed) {
    throw StateError('Capture is not allowed for this battle.');
  }
  if (gameState.party.members.length >= maxPlayerPartySize &&
      const PlayerStorageOperations()
              .findFirstAvailableSlot(gameState.pokemonStorage) ==
          null) {
    throw StateError('Pokemon storage is full. Capture cannot be attempted.');
  }
  final definition = itemCatalog.definitionFor(itemId);
  final capture = definition?.capture;
  if (definition == null ||
      capture == null ||
      !capture.allowedEncounterKinds.contains(request.encounterKind)) {
    throw StateError('The selected item cannot capture this encounter.');
  }
  final consumption = const BagOperations().consume(
    BagConsumeRequest(
      bag: gameState.bag,
      itemId: itemId,
      quantity: 1,
      itemTags: definition.tags,
      reason: ItemConsumptionReason.captureAttempt,
    ),
  );
  final consumptionReceipt = consumption.consumptionReceipt;
  if (!consumption.isSuccess || consumptionReceipt == null) {
    throw StateError('The selected capture item is unavailable.');
  }
  final result = submitToEngine();
  final captureAttempt = switch (result) {
    BattleSession session => _extractLegacyBattleCaptureAttempt(session),
    BattleEngineTurnResult turnResult =>
      _extractPsdkBattleCaptureAttempt(turnResult),
    _ => throw StateError(
        'Capture submission requires a typed legacy or PSDK engine result.',
      ),
  };
  if (captureAttempt != null &&
      (captureAttempt.attemptId.trim().isEmpty ||
          captureAttempt.itemId != itemId)) {
    throw StateError('The engine returned an invalid capture attempt proof.');
  }
  return RuntimeBattleCaptureAttemptSubmission<T>(
    updatedGameState: gameState.copyWith(bag: consumption.bag),
    engineResult: result,
    consumptionReceipt: consumptionReceipt,
    receipt: captureAttempt == null
        ? null
        : RuntimeBattleCaptureAttemptReceipt._(
            requestId: context.request.requestId,
            itemId: captureAttempt.itemId,
            attemptId: captureAttempt.attemptId,
          ),
  );
}

/// Claims the exact successful capture proof at the publication boundary.
///
/// Building or replaying a post-battle transaction must stay side-effect free:
/// only the caller that publishes its final [GameState] may consume the
/// receipt. A second commit with the same proof is rejected.
void commitRuntimeBattleCaptureAttemptReceipt({
  required RuntimeActiveBattleContext context,
  required BattleOutcome outcome,
  required RuntimeBattleCaptureAttemptReceipt? receipt,
}) {
  if (!outcome.isCaptured) return;
  _validatedCaptureReceipt(
    context: context,
    outcome: outcome,
    receipt: receipt,
  )._claim();
}

/// Applique le strict minimum de reprise après une vraie défaite joueur.
///
/// Pourquoi ce helper existe :
/// - le lot 10 écrit honnêtement les PV finaux du combat, y compris `0` ;
/// - le lot 15 doit éviter l'état absurde "retour overworld + toute la party K.O.
///   + aucun moyen de rejouer" ;
/// - on ne veut pourtant pas ouvrir un vrai centre Pokémon, ni un système de
///   whiteout complet, ni une logique multi-Pokémon.
///
/// Contrat volontairement petit :
/// - si au moins un Pokémon de la party est encore jouable, on ne soigne rien ;
/// - si toute la party est K.O., on relève uniquement le slot exact qui a servi
///   au combat à `1 HP` ;
/// - on garde ainsi la mémoire fidèle du write-back lot 10 sur tous les autres
///   slots, tout en garantissant qu'un prochain handoff runtime->battle restera
///   possible sans inventer un heal global.
///
/// Ce helper reste pur :
/// - il ne téléporte pas ;
/// - il ne touche ni au bag, ni aux flags trainer, ni à seen/caught ;
/// - le repositionnement runtime "whiteout-lite" reste géré par `PlayableMapGame`,
///   car lui seul connaît la carte réellement chargée et les seams de respawn.
GameState applyRuntimeDefeatRecoveryToGameState({
  required GameState gameState,
  required int playerPartyIndex,
  int? activePlayerLineupIndex,
  List<int> playerPartySlotIndicesByLineupIndex = const <int>[],
}) {
  if (gameState.party.members.any((member) => !member.isFainted)) {
    return gameState;
  }

  final members = gameState.party.members;
  final revivePartySlotIndex = _resolveDefeatRecoveryPartySlotIndex(
    partyLength: members.length,
    playerPartyIndex: playerPartyIndex,
    activePlayerLineupIndex: activePlayerLineupIndex,
    playerPartySlotIndicesByLineupIndex: playerPartySlotIndicesByLineupIndex,
  );

  if (revivePartySlotIndex < 0 || revivePartySlotIndex >= members.length) {
    throw StateError(
      'Le whiteout-lite runtime pointe vers un slot party invalide: '
      'index=$revivePartySlotIndex, partyLength=${members.length}',
    );
  }

  final nextMembers = List<PlayerPokemon>.of(members, growable: false);
  final defeatedMember = nextMembers[revivePartySlotIndex];

  // Whiteout-lite lot 15 :
  // - on évite le softlock total après défaite ;
  // - on ne réanime qu'un seul Pokémon, sur le slot exact qui était encore
  //   actif au moment de la défaite ;
  // - BE10 impose ce détail : après un switch, l'ancien slot initial ne doit
  //   plus être "magiquement" réanimé à la place du vrai Pokémon tombé ;
  // - on ne transforme pas ce lot en heal center ou en reset complet de party.
  nextMembers[revivePartySlotIndex] = defeatedMember.copyWith(currentHp: 1);

  return gameState.copyWith(
    party: gameState.party.copyWith(members: nextMembers),
  );
}

int _resolveDefeatRecoveryPartySlotIndex({
  required int partyLength,
  required int playerPartyIndex,
  required int? activePlayerLineupIndex,
  required List<int> playerPartySlotIndicesByLineupIndex,
}) {
  // Compatibilité volontaire :
  // - les anciens call sites mono-slot ne connaissent que playerPartyIndex ;
  // - BE10 ajoute un mapping lineup -> slots runtime pour éviter de réanimer
  //   le mauvais membre après un switch ;
  // - on ne force donc le nouveau chemin que quand les deux informations
  //   modernes sont réellement disponibles.
  if (playerPartySlotIndicesByLineupIndex.isEmpty ||
      activePlayerLineupIndex == null) {
    return playerPartyIndex;
  }

  if (activePlayerLineupIndex < 0 ||
      activePlayerLineupIndex >= playerPartySlotIndicesByLineupIndex.length) {
    throw StateError(
      'Le whiteout-lite runtime a reçu un lineupIndex joueur invalide: '
      'lineupIndex=$activePlayerLineupIndex, '
      'lineupLength=${playerPartySlotIndicesByLineupIndex.length}',
    );
  }

  final mappedPartyIndex =
      playerPartySlotIndicesByLineupIndex[activePlayerLineupIndex];
  if (mappedPartyIndex < 0 || mappedPartyIndex >= partyLength) {
    throw StateError(
      'Le whiteout-lite runtime a reçu un mapping lineup->party invalide: '
      'lineupIndex=$activePlayerLineupIndex, '
      'partyIndex=$mappedPartyIndex, partyLength=$partyLength',
    );
  }

  return mappedPartyIndex;
}

/// Résultat atomique du write-back de base, avant récompenses de victoire.
final class RuntimeBattleOutcomeTransactionBase {
  const RuntimeBattleOutcomeTransactionBase({
    required this.state,
    required this.captureDestination,
  });

  final GameState state;
  final CaptureDestinationResult? captureDestination;
}

/// Calcule le write-back HP/PP/status et, le cas échéant, la capture exacte.
///
/// Ce seam ne marque volontairement jamais un dresseur vaincu : le
/// coordinateur post-combat doit d'abord terminer XP, décisions et rewards.
RuntimeBattleOutcomeTransactionBase applyRuntimeBattleOutcomeTransactionBase({
  required GameState gameState,
  required RuntimeActiveBattleContext context,
  required BattleOutcome outcome,
  RuntimeBattleCaptureAttemptReceipt? captureAttemptReceipt,
}) {
  if (context.request is TrainerBattleStartRequest && outcome.isRunaway) {
    throw StateError('BattleOutcomeType.runaway est interdit en combat trainer.');
  }
  final stateWithPlayerHp = writePlayerBattleLineupBackToPartySlots(
    gameState: gameState,
    context: context,
    battleState: outcome.finalState,
  );

  if (!outcome.isCaptured) {
    return RuntimeBattleOutcomeTransactionBase(
      state: stateWithPlayerHp,
      captureDestination: null,
    );
  }
  final captureReceipt = _validatedCaptureReceipt(
    context: context,
    outcome: outcome,
    receipt: captureAttemptReceipt,
  );
  final capturedPokemon = _buildCapturedWildPlayerPokemon(
    enemy: outcome.finalState.enemy,
    request: context.request as WildBattleStartRequest,
    ballItemId: captureReceipt.itemId,
  );
  final captureResult = const GameStateMutations().applyCapturedPokemon(
    stateWithPlayerHp,
    pokemon: capturedPokemon,
  );
  return RuntimeBattleOutcomeTransactionBase(
    state: captureResult.state,
    captureDestination: captureResult,
  );
}

/// Applique le résultat final du combat à l'état runtime.
///
/// Ce helper porte le write-back lot 10 dans un seul chemin explicite :
/// 1. écrire les PV, PP et statuts finaux du lineup joueur sur les slots exacts ;
/// 2. marquer le trainer battu uniquement en cas de victoire trainer ;
/// 3. laisser intact tout ce qui appartient aux lots 11+.
///
/// Important :
/// - on ne soigne jamais implicitement le joueur ;
/// - on ne téléporte jamais ;
/// - FG-049 ne gère que la Poké Ball canonique ;
/// - chaque tentative acceptée consomme sa Ball à la soumission, jamais ici ;
/// - aucun bag UI, aucune récompense, aucun switch n'est ouvert ici ;
/// - on ne recalculera jamais naïvement le slot actif après le combat.
GameState applyRuntimeBattleOutcomeToGameState({
  required GameState gameState,
  required RuntimeActiveBattleContext context,
  required BattleOutcome outcome,
  RuntimeBattleCaptureAttemptReceipt? captureAttemptReceipt,
  StoryFlagsManager storyFlagsManager = const StoryFlagsManager(),
}) {
  final transactionBase = applyRuntimeBattleOutcomeTransactionBase(
    gameState: gameState,
    context: context,
    outcome: outcome,
    captureAttemptReceipt: captureAttemptReceipt,
  );
  final stateWithPlayerHp = transactionBase.state;
  final request = context.request;
  if (outcome.isCaptured) {
    commitRuntimeBattleCaptureAttemptReceipt(
      context: context,
      outcome: outcome,
      receipt: captureAttemptReceipt,
    );
    return stateWithPlayerHp;
  }

  if (outcome.isVictory && request is TrainerBattleStartRequest) {
    return storyFlagsManager.markTrainerDefeated(
      stateWithPlayerHp,
      request.trainerId,
    );
  }

  return stateWithPlayerHp;
}

RuntimeBattleCaptureAttemptReceipt _validatedCaptureReceipt({
  required RuntimeActiveBattleContext context,
  required BattleOutcome outcome,
  required RuntimeBattleCaptureAttemptReceipt? receipt,
}) {
  final request = context.request;
  if (request is! WildBattleStartRequest) {
    throw StateError(
      'BattleOutcomeType.captured est interdit hors combat sauvage.',
    );
  }
  if (receipt == null ||
      receipt._isClaimed ||
      receipt.requestId != request.requestId ||
      receipt.itemId.trim().isEmpty ||
      receipt.itemId != outcome.captureItemId ||
      receipt.attemptId != outcome.captureAttemptId) {
    throw StateError(
      'BattleOutcomeType.captured requires a matching charged capture attempt receipt.',
    );
  }
  return receipt;
}

const _capturedPokemonDefaultNatureId = 'hardy';
const _capturedPokemonFallbackAbilityId = 'unknown';

PlayerPokemon _buildCapturedWildPlayerPokemon({
  required BattleCombatant enemy,
  required WildBattleStartRequest request,
  required String ballItemId,
}) {
  final generatedPokemon = request.generatedPokemon;
  final normalizedAbilityId = enemy.writeBackAbilityId.trim().isEmpty
      ? generatedPokemon?.abilityId ?? _capturedPokemonFallbackAbilityId
      : enemy.writeBackAbilityId.trim();
  final normalizedMoveIds = enemy.writeBackMoves
      .map((move) => move.id.trim())
      .where((moveId) => moveId.isNotEmpty)
      .toSet()
      .toList(growable: false);

  final provenance = generatedPokemon?.provenance;
  return PlayerPokemon(
    speciesId: enemy.writeBackSpeciesId.trim(),
    natureId: generatedPokemon?.natureId ?? _capturedPokemonDefaultNatureId,
    abilityId: normalizedAbilityId,
    gender: generatedPokemon?.gender,
    level: enemy.level,
    ivs: generatedPokemon?.ivs ?? const PokemonStatSpread(),
    evs: generatedPokemon?.evs ?? const PokemonStatSpread(),
    knownMoveIds: normalizedMoveIds,
    experience: generatedPokemon?.experience,
    currentPpByMoveId: Map<String, int>.unmodifiable(
      <String, int>{
        for (final move in enemy.writeBackMoves) move.id.trim(): move.currentPp,
      }..remove(''),
    ),
    currentHp: enemy.currentHp <= 0 ? 1 : enemy.currentHp,
    statusId: switch (enemy.majorStatus?.id) {
      BattleMajorStatusId.par => 'par',
      BattleMajorStatusId.brn => 'brn',
      BattleMajorStatusId.psn => 'psn',
      BattleMajorStatusId.tox => 'tox',
      BattleMajorStatusId.slp => 'slp',
      BattleMajorStatusId.frz => 'frz',
      null => '',
    },
    isShiny: generatedPokemon?.isShiny ?? false,
    heldItemId: generatedPokemon?.heldItemId ?? '',
    nickname: generatedPokemon?.nickname ?? '',
    friendship: generatedPokemon?.friendship ?? 0,
    provenance: PlayerPokemonProvenance(
      kind: PlayerPokemonOriginKind.captured,
      mapId: provenance?.mapId ?? request.mapId,
      sourceId: provenance?.sourceId ?? request.tableId,
      ballItemId: ballItemId,
      metLevel: enemy.level,
    ),
  );
}

/// Réécrit les PV des combattants joueur réellement engagés dans la vraie party.
///
/// BE10 remplace l'ancien write-back mono-slot par une projection minimale
/// mais honnête du lineup battle joueur :
/// - l'actif final et les réserves finales portent tous un `lineupIndex`
///   battle stable ;
/// - le contexte runtime connaît la correspondance lineup -> slots de party ;
/// - on réécrit donc chaque membre réellement engagé sur le bon slot save,
///   sans recalculer l'historique des switches.
///
/// Frontière volontairement bornée :
/// - on écrit les PV, le statut majeur et les PP du snapshot `writeBackMoves`
///   fourni par le moteur, jamais ceux d'une forme ou d'un move temporaire ;
/// - l'identité initiale des slots battle permet à Sketch de remplacer son
///   move exact sans supprimer un move connu qui n'avait pas été injecté ;
/// - pour un ancien Pokémon sans moves persistés, ce même snapshot permet de
///   figer une seule fois le moveset original réellement seedé ;
/// - les membres de party non engagés dans ce combat restent inchangés.
GameState writePlayerBattleLineupBackToPartySlots({
  required GameState gameState,
  required RuntimeActiveBattleContext context,
  required BattleState battleState,
}) {
  const statusBridge = RuntimeBattleStatusBridge();
  final playerLineup = <BattleCombatant>[
    battleState.player,
    ...battleState.playerReserve,
  ];
  final hasExplicitLineupMapping =
      context.playerPartySlotIndicesByLineupIndex.isNotEmpty;

  // BE10A durcit ici un seam devenu ambigu après l'ouverture du switch
  // pipeline :
  // - le vieux fallback mono-slot sur `playerPartyIndex` reste acceptable pour
  //   les combats historiques où un seul membre joueur a réellement été engagé ;
  // - en revanche, dès que `finalState` porte une vraie réserve BE10, ce
  //   fallback n'est plus honnête : on ne sait plus quel slot runtime doit
  //   recevoir quel combattant battle ;
  // - on préfère donc un échec explicite et testable à une écriture silencieuse
  //   sur le mauvais membre de la party.
  if (!hasExplicitLineupMapping &&
      (playerLineup.length > 1 || battleState.player.lineupIndex != 0)) {
    throw StateError(
      'Le write-back runtime BE10 exige RuntimeActiveBattleContext.'
      'playerPartySlotIndicesByLineupIndex quand BattleOutcome.finalState '
      'porte une lineup joueur multi-membre ou non triviale '
      '(lineupLength=${playerLineup.length}, '
      'activeLineupIndex=${battleState.player.lineupIndex}).',
    );
  }

  final lineupToParty = hasExplicitLineupMapping
      ? context.playerPartySlotIndicesByLineupIndex
      : <int>[context.playerPartyIndex];

  if (playerLineup.length != lineupToParty.length) {
    throw StateError(
      'Le write-back runtime ne peut pas réconcilier une lineup battle et un mapping de party de tailles différentes: '
      'lineupLength=${playerLineup.length}, partyMappingLength=${lineupToParty.length}',
    );
  }

  final members = gameState.party.members;
  final nextMembers = List<PlayerPokemon>.of(members, growable: false);
  final seenLineupIndices = <int>{};

  for (final combatant in playerLineup) {
    final lineupIndex = combatant.lineupIndex;
    if (lineupIndex < 0 || lineupIndex >= lineupToParty.length) {
      throw StateError(
        'Le write-back runtime pointe vers un lineupIndex battle invalide: '
        'lineupIndex=$lineupIndex, mappingLength=${lineupToParty.length}',
      );
    }
    if (!seenLineupIndices.add(lineupIndex)) {
      throw StateError(
        'Le write-back runtime a rencontré deux combattants avec le même lineupIndex=$lineupIndex.',
      );
    }

    final partyIndex = lineupToParty[lineupIndex];
    if (partyIndex < 0 || partyIndex >= members.length) {
      throw StateError(
        'RuntimeActiveBattleContext pointe vers un slot party invalide: '
        'index=$partyIndex, partyLength=${members.length}',
      );
    }

    final currentMember = nextMembers[partyIndex];
    final persistedMoveIds = currentMember.knownMoveIds.isEmpty
        ? _persistentWriteBackMoves(combatant.writeBackMoves)
            .map((move) => move.id.trim())
            .toList(growable: false)
        : currentMember.knownMoveIds.map((moveId) => moveId.trim()).toList();
    final nextCurrentPpByMoveId = <String, int>{
      ...?currentMember.currentPpByMoveId,
    };
    if (currentMember.knownMoveIds.isEmpty) {
      for (final move in _persistentWriteBackMoves(
        combatant.writeBackMoves,
      )) {
        nextCurrentPpByMoveId[move.id.trim()] = move.currentPp;
      }
    } else {
      final slotCount = combatant.writeBackMoves.length <
              combatant.writeBackMoveIdsAtBattleStart.length
          ? combatant.writeBackMoves.length
          : combatant.writeBackMoveIdsAtBattleStart.length;
      for (var index = 0; index < slotCount; index += 1) {
        final sourceMoveId =
            combatant.writeBackMoveIdsAtBattleStart[index].trim();
        final persistentMove = combatant.writeBackMoves[index];
        final persistentMoveId = persistentMove.id.trim();
        if (sourceMoveId.isEmpty || persistentMoveId.isEmpty) {
          continue;
        }
        final partyMoveSlot = persistedMoveIds.indexOf(sourceMoveId);
        if (partyMoveSlot < 0) {
          // This snapshot slot cannot be reconciled with the current save.
          // Preserve the save instead of deleting an uninjected move.
          continue;
        }
        persistedMoveIds[partyMoveSlot] = persistentMoveId;
        if (persistentMoveId != sourceMoveId) {
          nextCurrentPpByMoveId.remove(sourceMoveId);
        }
        nextCurrentPpByMoveId[persistentMoveId] = persistentMove.currentPp;
      }
    }
    nextMembers[partyIndex] = currentMember.copyWith(
      currentHp: combatant.currentHp < 0 ? 0 : combatant.currentHp,
      knownMoveIds: persistedMoveIds,
      currentPpByMoveId: nextCurrentPpByMoveId,
      statusId: statusBridge.fromLegacyBattleStatus(combatant.majorStatus),
    );
  }

  return gameState.copyWith(
    party: gameState.party.copyWith(members: nextMembers),
  );
}

/// Réconcilie le cycle de vie des objets tenus PSDK avec les slots save.
///
/// L'ID save original est conservé tant que l'effet moteur n'a pas changé.
/// Une consommation ou un retrait vide le slot ; un objet reçu ou volé est
/// reconverti vers l'unique itemId canonique qui porte cet effet.
GameState writePlayerPsdkHeldItemsBackToPartySlots({
  required GameState gameState,
  required RuntimeActiveBattleContext context,
  required PsdkBattleState psdkState,
  required ItemCatalogSnapshot itemCatalog,
}) {
  final lineup = psdkState.partyForBank(psdkPlayerSlot.bank);
  final mapping = context.playerPartySlotIndicesByLineupIndex;
  if (lineup.length != mapping.length) {
    throw StateError(
      'Le write-back held-item ne peut pas réconcilier la lineup PSDK et la '
      'party runtime: lineupLength=${lineup.length}, '
      'partyMappingLength=${mapping.length}.',
    );
  }

  final members = List<PlayerPokemon>.of(
    gameState.party.members,
    growable: false,
  );
  for (var lineupIndex = 0; lineupIndex < lineup.length; lineupIndex += 1) {
    final partyIndex = mapping[lineupIndex];
    if (partyIndex < 0 || partyIndex >= members.length) {
      throw StateError(
        'Le write-back held-item pointe vers un slot party invalide: '
        'lineupIndex=$lineupIndex, partyIndex=$partyIndex, '
        'partyLength=${members.length}.',
      );
    }
    final battler = lineup[lineupIndex];
    final saved = members[partyIndex];
    final finalEngineItemId = battler.itemConsumed
        ? null
        : _normalizePsdkHeldItemId(battler.heldItemId);
    final savedItemId = saved.heldItemId.trim();
    final savedResolution = savedItemId.isEmpty
        ? null
        : resolveRuntimeHeldItemEffect(
            itemCatalog: itemCatalog,
            itemId: savedItemId,
          );
    final nextSavedItemId = finalEngineItemId == null
        ? ''
        : savedResolution?.status == RuntimeHeldItemSupportStatus.supported &&
                savedResolution?.heldEffectId == finalEngineItemId
            ? savedItemId
            : _canonicalItemIdForHeldEffect(
                itemCatalog: itemCatalog,
                heldEffectId: finalEngineItemId,
              );
    members[partyIndex] = saved.copyWith(heldItemId: nextSavedItemId);
  }

  return gameState.copyWith(
    party: gameState.party.copyWith(members: members),
  );
}

String _canonicalItemIdForHeldEffect({
  required ItemCatalogSnapshot itemCatalog,
  required String heldEffectId,
}) {
  final matches = itemCatalog.definitions
      .map(
        (definition) => resolveRuntimeHeldItemEffect(
          itemCatalog: itemCatalog,
          itemId: definition.id,
        ),
      )
      .where(
        (resolution) =>
            resolution.status == RuntimeHeldItemSupportStatus.supported &&
            resolution.heldEffectId == heldEffectId,
      )
      .toList(growable: false);
  if (matches.length != 1) {
    throw StateError(
      'Le write-back held-item exige une définition canonique unique pour '
      'heldEffectId=$heldEffectId, matches=${matches.length}.',
    );
  }
  return matches.single.itemId;
}

String? _normalizePsdkHeldItemId(String? itemId) {
  final trimmed = itemId?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed.toLowerCase().replaceAll('-', '_');
}

List<BattleMove> _persistentWriteBackMoves(List<BattleMove> battleMoves) {
  final persistentMoves = <BattleMove>[];
  final seenMoveIds = <String>{};
  for (final move in battleMoves) {
    final moveId = move.id.trim();
    if (moveId.isEmpty || !seenMoveIds.add(moveId)) {
      continue;
    }
    persistentMoves.add(move);
    if (persistentMoves.length == 4) {
      break;
    }
  }
  return List<BattleMove>.unmodifiable(persistentMoves);
}
