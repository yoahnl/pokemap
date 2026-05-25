import 'package:map_core/map_core.dart';

/// Mutations pures de l'état de partie.
///
/// Chaque fonction prend un [GameState] et retourne un nouveau [GameState]
/// avec la mutation appliquée.
///
/// Ne contient aucun effet de bord.
/// Totalement testable et déterministe.
class GameStateMutations {
  const GameStateMutations();

  /// Définit un flag narratif à true.
  GameState setFlag(GameState state, String flagName) {
    final normalized = flagName.trim();
    if (normalized.isEmpty) return state;

    final newFlags = Set<String>.from(state.storyFlags.activeFlags)
      ..add(normalized);

    return state.copyWith(
      storyFlags: state.storyFlags.copyWith(activeFlags: newFlags),
    );
  }

  /// Définit un flag narratif à false.
  GameState clearFlag(GameState state, String flagName) {
    final normalized = flagName.trim();
    if (normalized.isEmpty) return state;

    final newFlags = Set<String>.from(state.storyFlags.activeFlags)
      ..remove(normalized);

    return state.copyWith(
      storyFlags: state.storyFlags.copyWith(activeFlags: newFlags),
    );
  }

  /// Définit une variable de script.
  GameState setVariable(
    GameState state,
    String variableName,
    ScriptVariableValue value,
  ) {
    final normalized = variableName.trim();
    if (normalized.isEmpty) return state;

    final newValues = Map<String, ScriptVariableValue>.from(
      state.scriptVariables.values,
    )..[normalized] = value;

    return state.copyWith(
      scriptVariables: state.scriptVariables.copyWith(values: newValues),
    );
  }

  /// Incrémente une variable numérique.
  ///
  /// Si la variable n'existe pas, elle est créée avec la valeur 0.
  /// Si la variable n'est pas un int, elle est ignorée.
  GameState incrementVariable(GameState state, String variableName, int delta) {
    final normalized = variableName.trim();
    if (normalized.isEmpty) return state;

    final currentValue = state.scriptVariables.values[normalized];
    int newValue = 0;

    if (currentValue != null) {
      newValue = currentValue.map(
        bool: (_) => 0,
        int: (i) => i.value + delta,
        string: (_) => 0,
      );
    } else {
      newValue = delta;
    }

    return setVariable(
      state,
      normalized,
      ScriptVariableValue.int(newValue),
    );
  }

  /// Débloque une field ability.
  GameState unlockFieldAbility(GameState state, FieldAbility ability) {
    if (state.progression.unlockedFieldAbilities.contains(ability)) {
      return state;
    }

    final newAbilities = List<FieldAbility>.from(
      state.progression.unlockedFieldAbilities,
    )..add(ability);

    return state.copyWith(
      progression: state.progression.copyWith(
        unlockedFieldAbilities: newAbilities,
      ),
    );
  }

  /// Marque un événement comme consommé.
  GameState markEventConsumed(GameState state, String eventId) {
    final normalized = eventId.trim();
    if (normalized.isEmpty) return state;

    final newConsumed = Set<String>.from(state.consumedEventIds)
      ..add(normalized);

    return state.copyWith(consumedEventIds: newConsumed);
  }

  /// Téléporte le joueur.
  GameState warpPlayer(
    GameState state,
    String mapId,
    int x,
    int y, {
    EntityFacing? facing,
  }) {
    return state.copyWith(
      currentMapId: mapId.trim().isEmpty ? state.currentMapId : mapId.trim(),
      playerPosition: GridPos(x: x, y: y),
      playerFacing: facing ?? state.playerFacing,
    );
  }

  /// Définit le mode de déplacement du joueur.
  GameState setPlayerMovementMode(GameState state, MovementMode mode) {
    return state.copyWith(playerMovementMode: mode);
  }

  /// Donne un item au joueur.
  ///
  /// L'item est ajouté dans [GameState.bag]. Si l'item existe déjà,
  /// la quantité est additionnée.
  GameState giveItem(
    GameState state,
    String itemId,
    int quantity,
  ) {
    final normalizedItemId = itemId.trim();
    if (normalizedItemId.isEmpty || quantity <= 0) {
      return state;
    }

    String categoryId = 'items';
    bool found = false;
    for (final entry in state.bag.entries) {
      if (entry.itemId.trim() == normalizedItemId) {
        categoryId = entry.categoryId;
        found = true;
        break;
      }
    }

    if (!found) {
      final lower = normalizedItemId.toLowerCase();
      if (lower == 'potion' ||
          lower == 'super-potion' ||
          lower == 'hyper-potion' ||
          lower == 'max-potion' ||
          lower == 'antidote') {
        categoryId = 'medicine';
      }
    }

    final newEntry = BagEntry(
      itemId: normalizedItemId,
      categoryId: categoryId,
      quantity: quantity,
    );

    final newEntries = [...state.bag.entries, newEntry];
    final updatedBag = Bag(entries: newEntries).normalized();

    return state.copyWith(bag: updatedBag);
  }

  /// Consomme une quantité d'item depuis le sac.
  ///
  /// No-op sûr si l'id est vide, la quantité invalide, l'item absent ou la
  /// quantité disponible insuffisante.
  GameState consumeItem(
    GameState state,
    String itemId,
    int quantity,
  ) {
    final normalizedItemId = itemId.trim();
    if (normalizedItemId.isEmpty || quantity <= 0) {
      return state;
    }

    final nextEntries = <BagEntry>[];
    var consumed = false;

    for (final entry in state.bag.normalized().entries) {
      final isRequestedItem =
          !consumed && entry.itemId.trim() == normalizedItemId;
      if (!isRequestedItem) {
        nextEntries.add(entry);
        continue;
      }

      if (entry.quantity < quantity) {
        return state;
      }

      consumed = true;
      final nextQuantity = entry.quantity - quantity;
      if (nextQuantity > 0) {
        nextEntries.add(entry.copyWith(quantity: nextQuantity));
      }
    }

    if (!consumed) {
      return state;
    }

    return state.copyWith(
      bag: Bag(entries: nextEntries).normalized(),
    );
  }

  /// Applique un soin HP hors combat à un membre de party.
  ///
  /// Le cap HP est fourni par l'appelant car [PlayerPokemon] ne persiste pas de
  /// maxHp. Cette mutation ne contient donc aucune table d'items ou de stats.
  GameState applyHpMedicineToPartyMember(
    GameState state, {
    required int partyIndex,
    required String itemId,
    required int healAmount,
    required int maxHp,
  }) {
    final normalizedItemId = itemId.trim();
    if (partyIndex < 0 ||
        partyIndex >= state.party.members.length ||
        normalizedItemId.isEmpty ||
        healAmount <= 0 ||
        maxHp <= 0) {
      return state;
    }

    final target = state.party.members[partyIndex];
    final currentHp = target.currentHp < 0 ? 0 : target.currentHp;
    if (currentHp >= maxHp) {
      return state;
    }

    final hasItem = state.bag.normalized().entries.any(
          (entry) =>
              entry.itemId.trim() == normalizedItemId && entry.quantity > 0,
        );
    if (!hasItem) {
      return state;
    }

    final consumedState = consumeItem(state, normalizedItemId, 1);
    final healedHp = currentHp + healAmount;
    final cappedHp = healedHp > maxHp ? maxHp : healedHp;
    final nextMembers = [...consumedState.party.members];
    nextMembers[partyIndex] = nextMembers[partyIndex].copyWith(
      currentHp: cappedHp,
    );

    return consumedState.copyWith(
      party: consumedState.party.copyWith(members: nextMembers),
    );
  }

  /// Restaure la party à partir de caps HP explicites par index.
  ///
  /// Représente un recovery point minimal sans UI ni Pokemon Center persistant.
  GameState recoverParty(
    GameState state, {
    required Map<int, int> maxHpByPartyIndex,
    bool clearStatus = true,
  }) {
    if (state.party.members.isEmpty || maxHpByPartyIndex.isEmpty) {
      return state;
    }

    final nextMembers = <PlayerPokemon>[];
    var changed = false;

    for (var index = 0; index < state.party.members.length; index++) {
      final member = state.party.members[index];
      final maxHp = maxHpByPartyIndex[index];
      if (maxHp == null || maxHp <= 0) {
        nextMembers.add(member);
        continue;
      }

      final nextStatusId = clearStatus ? '' : member.statusId;
      final nextMember = member.copyWith(
        currentHp: maxHp,
        statusId: nextStatusId,
      );
      changed = changed || nextMember != member;
      nextMembers.add(nextMember);
    }

    if (!changed) {
      return state;
    }

    return state.copyWith(
      party: state.party.copyWith(members: nextMembers),
    );
  }

  /// Ajoute de l'argent au profil joueur.
  ///
  /// No-op sûr si [amount] est nul ou négatif. Cette mutation reste un reward
  /// minimal : elle ne crée ni shop, ni moteur économique.
  GameState addMoney(GameState state, int amount) {
    if (amount <= 0) {
      return state;
    }

    return state.copyWith(
      trainerProfile: state.trainerProfile.copyWith(
        money: state.trainerProfile.money + amount,
      ),
    );
  }

  /// Applique les récompenses minimales d'une victoire de combat.
  ///
  /// `PlayerPokemon` ne persiste pas encore d'XP courante. Le chemin V0 expose
  /// donc uniquement un level-up direct et déterministe fourni par l'appelant.
  /// La policy `trainer_defeated:{trainerId}` reste portée par le runtime.
  GameState applyBattleRewards(
    GameState state, {
    int moneyReward = 0,
    Map<int, int> levelUpsByPartyIndex = const {},
  }) {
    var nextState = addMoney(state, moneyReward);

    if (levelUpsByPartyIndex.isEmpty || nextState.party.members.isEmpty) {
      return nextState;
    }

    final nextMembers = List<PlayerPokemon>.of(
      nextState.party.members,
      growable: false,
    );
    var changed = false;

    for (final entry in levelUpsByPartyIndex.entries) {
      final partyIndex = entry.key;
      final levelIncrement = entry.value;
      if (partyIndex < 0 ||
          partyIndex >= nextMembers.length ||
          levelIncrement <= 0) {
        continue;
      }

      final member = nextMembers[partyIndex];
      final nextLevel = member.level + levelIncrement;
      final cappedLevel = nextLevel > 100 ? 100 : nextLevel;
      if (cappedLevel == member.level) {
        continue;
      }

      nextMembers[partyIndex] = member.copyWith(level: cappedLevel);
      changed = true;
    }

    if (!changed) {
      return nextState;
    }

    return nextState.copyWith(
      party: nextState.party.copyWith(members: nextMembers),
    );
  }

  /// Donne un Pokémon au joueur.
  ///
  /// Le [PlayerPokemon] doit être construit par l'appelant (authoring, script,
  /// scénario). Cette mutation ne calcule pas les stats, moves ou HP : elle
  /// ajoute un Pokémon déjà valide à la party.
  ///
  /// Si [preventDuplicateSpecies] est `true`, la mutation est un no-op si la
  /// party contient déjà un Pokémon du même [PlayerPokemon.speciesId].
  ///
  /// Invariant mechanics-first : aucun speciesId n'est hardcodé ici.
  /// Le Pokémon est fourni par l'appelant, pas décidé par la mutation.
  GameState givePokemon(
    GameState state, {
    required PlayerPokemon pokemon,
    bool preventDuplicateSpecies = false,
  }) {
    final normalizedSpeciesId = pokemon.speciesId.trim();
    if (normalizedSpeciesId.isEmpty) {
      // speciesId vide/blank = Pokémon invalide, no-op sûr.
      return state;
    }

    if (preventDuplicateSpecies) {
      final alreadyOwned = state.party.members.any(
        (m) => m.speciesId.trim() == normalizedSpeciesId,
      );
      if (alreadyOwned) {
        return state;
      }
    }

    final normalizedPokemon = pokemon.copyWith(
      speciesId: normalizedSpeciesId,
    );

    final newMembers = [...state.party.members, normalizedPokemon];

    return state.copyWith(
      party: state.party.copyWith(members: newMembers),
    );
  }

  /// Marque une étape narrative comme complétée.
  ///
  /// L'opération est **idempotente** : compléter deux fois la même step
  /// ne crée pas de doublon dans [PlayerProgression.completedStepIds].
  ///
  /// Si [stepId] est vide ou blanc, retourne le state inchangé (no-op sûr).
  ///
  /// Invariant mechanics-first : aucun stepId n'est hardcodé ici.
  /// L'appelant (scénario, script, éditeur) choisit l'id.
  GameState completeStep(GameState state, String stepId) {
    final normalized = stepId.trim();
    if (normalized.isEmpty) return state;

    final existing = state.progression.completedStepIds;
    if (existing.contains(normalized)) {
      // Idempotent : step déjà complétée, pas de doublon.
      return state;
    }

    final newStepIds = [...existing, normalized];
    return state.copyWith(
      progression: state.progression.copyWith(
        completedStepIds: newStepIds,
      ),
    );
  }

  /// Applique un lot de mutations atomiquement.
  GameState applyAll(
    GameState state,
    List<GameState Function(GameState)> mutations,
  ) {
    var result = state;
    for (final mutation in mutations) {
      result = mutation(result);
    }
    return result;
  }
}
