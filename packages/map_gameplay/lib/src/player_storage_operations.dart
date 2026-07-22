import 'package:map_core/map_core.dart';

enum PlayerStorageFailure {
  invalidRequest,
  invalidPartyIndex,
  invalidBoxId,
  invalidBoxIndex,
  partyFull,
  boxFull,
  storageFull,
  lastUsablePokemon,
}

final class PlayerStorageSlot {
  const PlayerStorageSlot({
    required this.boxId,
    required this.boxIndex,
  });

  final String boxId;
  final int boxIndex;
}

final class PlayerStorageOperationResult {
  const PlayerStorageOperationResult._({
    required this.state,
    this.failure,
    this.partyIndex,
    this.storageSlot,
  });

  const PlayerStorageOperationResult.success({
    required GameState state,
    int? partyIndex,
    PlayerStorageSlot? storageSlot,
  }) : this._(
          state: state,
          partyIndex: partyIndex,
          storageSlot: storageSlot,
        );

  const PlayerStorageOperationResult.failed({
    required GameState state,
    required PlayerStorageFailure failure,
  }) : this._(state: state, failure: failure);

  final GameState state;
  final PlayerStorageFailure? failure;
  final int? partyIndex;
  final PlayerStorageSlot? storageSlot;

  bool get isSuccess => failure == null;
}

final class PlayerStorageOperations {
  const PlayerStorageOperations();

  PlayerStorageSlot? findFirstAvailableSlot(PokemonStorage storage) {
    final boxes = storage.normalized().boxes;
    for (final box in boxes) {
      if (box.pokemon.length < box.capacity) {
        return PlayerStorageSlot(
          boxId: box.id,
          boxIndex: box.pokemon.length,
        );
      }
    }
    return null;
  }

  PlayerStorageOperationResult deposit({
    required GameState state,
    required int partyIndex,
    String? boxId,
    bool requireUsablePartyMember = true,
  }) {
    if (partyIndex < 0 || partyIndex >= state.party.members.length) {
      return _failure(state, PlayerStorageFailure.invalidPartyIndex);
    }
    final boxes = state.pokemonStorage.normalized().boxes;
    final targetBoxIndex = boxId == null
        ? _firstAvailableBoxIndex(boxes)
        : boxes.indexWhere((box) => box.id == boxId.trim());
    if (targetBoxIndex < 0) {
      return _failure(
        state,
        boxId == null
            ? PlayerStorageFailure.storageFull
            : PlayerStorageFailure.invalidBoxId,
      );
    }
    final targetBox = boxes[targetBoxIndex];
    if (targetBox.pokemon.length >= targetBox.capacity) {
      return _failure(state, PlayerStorageFailure.boxFull);
    }
    if (requireUsablePartyMember) {
      final usableAfterDeposit = state.party.members
          .asMap()
          .entries
          .where((entry) => entry.key != partyIndex)
          .any((entry) => !entry.value.isFainted);
      if (!usableAfterDeposit) {
        return _failure(state, PlayerStorageFailure.lastUsablePokemon);
      }
    }

    final pokemon = state.party.members[partyIndex];
    final nextParty = [...state.party.members]..removeAt(partyIndex);
    final nextBoxes = [...boxes];
    nextBoxes[targetBoxIndex] = targetBox.copyWith(
      pokemon: <PlayerPokemon>[...targetBox.pokemon, pokemon],
    );
    return PlayerStorageOperationResult.success(
      state: _withRoster(state, party: nextParty, boxes: nextBoxes),
      storageSlot: PlayerStorageSlot(
        boxId: targetBox.id,
        boxIndex: targetBox.pokemon.length,
      ),
    );
  }

  PlayerStorageOperationResult withdraw({
    required GameState state,
    required String boxId,
    required int boxIndex,
  }) {
    if (state.party.members.length >= maxPlayerPartySize) {
      return _failure(state, PlayerStorageFailure.partyFull);
    }
    final boxes = state.pokemonStorage.normalized().boxes;
    final resolved = _resolveBox(boxes, boxId);
    if (resolved == null) {
      return _failure(state, PlayerStorageFailure.invalidBoxId);
    }
    final (resolvedIndex, box) = resolved;
    if (boxIndex < 0 || boxIndex >= box.pokemon.length) {
      return _failure(state, PlayerStorageFailure.invalidBoxIndex);
    }
    final pokemon = box.pokemon[boxIndex];
    final nextPokemon = [...box.pokemon]..removeAt(boxIndex);
    final nextBoxes = [...boxes];
    nextBoxes[resolvedIndex] = box.copyWith(pokemon: nextPokemon);
    final partyIndex = state.party.members.length;
    return PlayerStorageOperationResult.success(
      state: _withRoster(
        state,
        party: <PlayerPokemon>[...state.party.members, pokemon],
        boxes: nextBoxes,
      ),
      partyIndex: partyIndex,
    );
  }

  PlayerStorageOperationResult swapPartyWithBox({
    required GameState state,
    required int partyIndex,
    required String boxId,
    required int boxIndex,
  }) {
    if (partyIndex < 0 || partyIndex >= state.party.members.length) {
      return _failure(state, PlayerStorageFailure.invalidPartyIndex);
    }
    final boxes = state.pokemonStorage.normalized().boxes;
    final resolved = _resolveBox(boxes, boxId);
    if (resolved == null) {
      return _failure(state, PlayerStorageFailure.invalidBoxId);
    }
    final (resolvedIndex, box) = resolved;
    if (boxIndex < 0 || boxIndex >= box.pokemon.length) {
      return _failure(state, PlayerStorageFailure.invalidBoxIndex);
    }
    final nextParty = [...state.party.members];
    final nextBoxPokemon = [...box.pokemon];
    final partyPokemon = nextParty[partyIndex];
    nextParty[partyIndex] = nextBoxPokemon[boxIndex];
    nextBoxPokemon[boxIndex] = partyPokemon;
    if (!nextParty.any((pokemon) => !pokemon.isFainted)) {
      return _failure(state, PlayerStorageFailure.lastUsablePokemon);
    }
    final nextBoxes = [...boxes];
    nextBoxes[resolvedIndex] = box.copyWith(pokemon: nextBoxPokemon);
    return PlayerStorageOperationResult.success(
      state: _withRoster(state, party: nextParty, boxes: nextBoxes),
      partyIndex: partyIndex,
      storageSlot: PlayerStorageSlot(boxId: box.id, boxIndex: boxIndex),
    );
  }

  PlayerStorageOperationResult moveWithinBox({
    required GameState state,
    required String boxId,
    required int fromIndex,
    required int toIndex,
  }) {
    final boxes = state.pokemonStorage.normalized().boxes;
    final resolved = _resolveBox(boxes, boxId);
    if (resolved == null) {
      return _failure(state, PlayerStorageFailure.invalidBoxId);
    }
    final (resolvedIndex, box) = resolved;
    if (fromIndex < 0 ||
        fromIndex >= box.pokemon.length ||
        toIndex < 0 ||
        toIndex >= box.pokemon.length) {
      return _failure(state, PlayerStorageFailure.invalidBoxIndex);
    }
    if (fromIndex == toIndex) {
      return PlayerStorageOperationResult.success(state: state);
    }
    final nextPokemon = [...box.pokemon];
    final pokemon = nextPokemon.removeAt(fromIndex);
    nextPokemon.insert(toIndex, pokemon);
    final nextBoxes = [...boxes];
    nextBoxes[resolvedIndex] = box.copyWith(pokemon: nextPokemon);
    return PlayerStorageOperationResult.success(
      state: _withRoster(
        state,
        party: state.party.members,
        boxes: nextBoxes,
      ),
      storageSlot: PlayerStorageSlot(boxId: box.id, boxIndex: toIndex),
    );
  }

  PlayerStorageOperationResult moveBetweenBoxes({
    required GameState state,
    required String sourceBoxId,
    required int sourceIndex,
    required String targetBoxId,
    int? targetIndex,
  }) {
    if (sourceBoxId.trim() == targetBoxId.trim()) {
      return moveWithinBox(
        state: state,
        boxId: sourceBoxId,
        fromIndex: sourceIndex,
        toIndex: targetIndex ?? sourceIndex,
      );
    }
    final boxes = state.pokemonStorage.normalized().boxes;
    final source = _resolveBox(boxes, sourceBoxId);
    final target = _resolveBox(boxes, targetBoxId);
    if (source == null || target == null) {
      return _failure(state, PlayerStorageFailure.invalidBoxId);
    }
    final (sourceListIndex, sourceBox) = source;
    final (targetListIndex, targetBox) = target;
    if (sourceIndex < 0 || sourceIndex >= sourceBox.pokemon.length) {
      return _failure(state, PlayerStorageFailure.invalidBoxIndex);
    }
    if (targetBox.pokemon.length >= targetBox.capacity) {
      return _failure(state, PlayerStorageFailure.boxFull);
    }
    final insertionIndex = targetIndex ?? targetBox.pokemon.length;
    if (insertionIndex < 0 || insertionIndex > targetBox.pokemon.length) {
      return _failure(state, PlayerStorageFailure.invalidBoxIndex);
    }
    final sourcePokemon = [...sourceBox.pokemon];
    final pokemon = sourcePokemon.removeAt(sourceIndex);
    final targetPokemon = [...targetBox.pokemon]
      ..insert(insertionIndex, pokemon);
    final nextBoxes = [...boxes];
    nextBoxes[sourceListIndex] = sourceBox.copyWith(pokemon: sourcePokemon);
    nextBoxes[targetListIndex] = targetBox.copyWith(pokemon: targetPokemon);
    return PlayerStorageOperationResult.success(
      state: _withRoster(
        state,
        party: state.party.members,
        boxes: nextBoxes,
      ),
      storageSlot: PlayerStorageSlot(
        boxId: targetBox.id,
        boxIndex: insertionIndex,
      ),
    );
  }

  PlayerStorageOperationResult swapPartyMembers({
    required GameState state,
    required int firstIndex,
    required int secondIndex,
  }) {
    if (!_isPartyIndex(state, firstIndex) ||
        !_isPartyIndex(state, secondIndex)) {
      return _failure(state, PlayerStorageFailure.invalidPartyIndex);
    }
    if (firstIndex == secondIndex) {
      return PlayerStorageOperationResult.success(state: state);
    }
    final nextParty = [...state.party.members];
    final first = nextParty[firstIndex];
    nextParty[firstIndex] = nextParty[secondIndex];
    nextParty[secondIndex] = first;
    return PlayerStorageOperationResult.success(
      state: _withRoster(
        state,
        party: nextParty,
        boxes: state.pokemonStorage.normalized().boxes,
      ),
    );
  }

  PlayerStorageOperationResult setLead({
    required GameState state,
    required int partyIndex,
  }) {
    if (!_isPartyIndex(state, partyIndex)) {
      return _failure(state, PlayerStorageFailure.invalidPartyIndex);
    }
    if (partyIndex == 0) {
      return PlayerStorageOperationResult.success(
        state: state,
        partyIndex: 0,
      );
    }
    final nextParty = [...state.party.members];
    final lead = nextParty.removeAt(partyIndex);
    nextParty.insert(0, lead);
    return PlayerStorageOperationResult.success(
      state: _withRoster(
        state,
        party: nextParty,
        boxes: state.pokemonStorage.normalized().boxes,
      ),
      partyIndex: 0,
    );
  }
}

PlayerStorageOperationResult _failure(
  GameState state,
  PlayerStorageFailure failure,
) =>
    PlayerStorageOperationResult.failed(state: state, failure: failure);

bool _isPartyIndex(GameState state, int index) =>
    index >= 0 && index < state.party.members.length;

int _firstAvailableBoxIndex(List<PokemonBox> boxes) =>
    boxes.indexWhere((box) => box.pokemon.length < box.capacity);

(int, PokemonBox)? _resolveBox(List<PokemonBox> boxes, String boxId) {
  final normalizedId = boxId.trim();
  if (normalizedId.isEmpty) return null;
  final index = boxes.indexWhere((box) => box.id == normalizedId);
  return index < 0 ? null : (index, boxes[index]);
}

GameState _withRoster(
  GameState state, {
  required List<PlayerPokemon> party,
  required List<PokemonBox> boxes,
}) {
  return state.copyWith(
    party: PlayerParty(members: party).normalized(),
    pokemonStorage: PokemonStorage(boxes: boxes).normalized(),
  );
}
