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
  /// Note : Cette mutation est basique.
  /// Un système d'inventaire complet serait à implémenter séparément.
  GameState giveItem(
    GameState state,
    String itemId,
    int quantity,
  ) {
    // Pour l'instant, on utilise les metadata comme storage basique.
    // Un vrai système d'inventaire serait dans un futur lot.
    final key = 'item_$itemId';
    final currentQty = state.metadata[key];
    final newQty = (currentQty != null ? int.parse(currentQty) : 0) + quantity;

    final newMetadata = Map<String, String>.from(state.metadata)
      ..[key] = newQty.toString();

    return state.copyWith(metadata: newMetadata);
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
