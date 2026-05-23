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
