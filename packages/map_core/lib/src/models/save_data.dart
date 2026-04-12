import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'geometry.dart';

part 'save_data.freezed.dart';
part 'save_data.g.dart';

List<String> _normalizeUniqueStringsPreserveOrder(List<String> values) {
  final normalized = <String>[];
  final seen = <String>{};
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || !seen.add(trimmed)) {
      continue;
    }
    normalized.add(trimmed);
  }
  return List.unmodifiable(normalized);
}

List<String> _normalizeUniqueStringsSorted(List<String> values) {
  final normalized = _normalizeUniqueStringsPreserveOrder(values).toList()
    ..sort();
  return List.unmodifiable(normalized);
}

Map<String, String> _normalizeStringMap(Map<String, String> values) {
  final normalizedEntries = values.entries
      .map(
        (entry) => MapEntry(entry.key.trim(), entry.value.trim()),
      )
      .where((entry) => entry.key.isNotEmpty)
      .toList(growable: false)
    ..sort((a, b) => a.key.compareTo(b.key));
  return Map<String, String>.fromEntries(normalizedEntries);
}

@freezed
class PokemonStatSpread with _$PokemonStatSpread {
  const PokemonStatSpread._();

  @JsonSerializable(explicitToJson: true)
  const factory PokemonStatSpread({
    @Default(0) int hp,
    @Default(0) int attack,
    @Default(0) int defense,
    @Default(0) int specialAttack,
    @Default(0) int specialDefense,
    @Default(0) int speed,
  }) = _PokemonStatSpread;

  factory PokemonStatSpread.fromJson(Map<String, dynamic> json) =>
      _$PokemonStatSpreadFromJson(json);

  PokemonStatSpread normalized() {
    if (hp < 0 ||
        attack < 0 ||
        defense < 0 ||
        specialAttack < 0 ||
        specialDefense < 0 ||
        speed < 0) {
      throw StateError('Pokemon stat values must be non-negative');
    }
    return this;
  }
}

/// Un Pokémon possédé par le joueur — modèle minimal pour raisonner
/// sur les field moves et l'état de l'équipe.
@freezed
class PlayerPokemon with _$PlayerPokemon {
  const PlayerPokemon._();

  @JsonSerializable(explicitToJson: true)
  const factory PlayerPokemon({
    required String speciesId,
    required String natureId,
    required String abilityId,
    @Default(1) int level,
    @Default(PokemonStatSpread()) PokemonStatSpread ivs,
    @Default(PokemonStatSpread()) PokemonStatSpread evs,
    @Default([]) List<String> knownMoveIds,
    @Default(1) int currentHp,
    @Default('') String statusId,
    @Default(false) bool isShiny,
    @Default('') String heldItemId,
  }) = _PlayerPokemon;

  factory PlayerPokemon.fromJson(Map<String, dynamic> json) =>
      _$PlayerPokemonFromJson(json);

  bool get isFainted => currentHp <= 0;

  PlayerPokemon normalized() {
    final normalizedSpeciesId = speciesId.trim();
    final normalizedNatureId = natureId.trim();
    final normalizedAbilityId = abilityId.trim();
    if (knownMoveIds.any((moveId) => moveId.trim().isEmpty)) {
      throw StateError(
          'PlayerPokemon knownMoveIds must not contain empty values');
    }
    final normalizedMoveIds =
        _normalizeUniqueStringsPreserveOrder(knownMoveIds);
    final normalizedStatusId = statusId.trim();
    final normalizedHeldItemId = heldItemId.trim();

    if (normalizedSpeciesId.isEmpty) {
      throw StateError('PlayerPokemon speciesId must not be empty');
    }
    if (normalizedNatureId.isEmpty) {
      throw StateError('PlayerPokemon natureId must not be empty');
    }
    if (normalizedAbilityId.isEmpty) {
      throw StateError('PlayerPokemon abilityId must not be empty');
    }
    if (level <= 0 || level > 100) {
      throw StateError('PlayerPokemon level must be between 1 and 100');
    }
    if (currentHp < 0) {
      throw StateError('PlayerPokemon currentHp must be non-negative');
    }
    if (normalizedMoveIds.length > 4) {
      throw StateError(
          'PlayerPokemon knownMoveIds must contain at most 4 moves');
    }

    ivs.normalized();
    evs.normalized();

    return copyWith(
      speciesId: normalizedSpeciesId,
      natureId: normalizedNatureId,
      abilityId: normalizedAbilityId,
      ivs: ivs.normalized(),
      evs: evs.normalized(),
      knownMoveIds: normalizedMoveIds,
      statusId: normalizedStatusId,
      heldItemId: normalizedHeldItemId,
    );
  }
}

/// Équipe active du joueur (max 6 en pratique, non contraint ici).
@freezed
class PlayerParty with _$PlayerParty {
  const PlayerParty._();

  @JsonSerializable(explicitToJson: true)
  const factory PlayerParty({
    @Default([]) List<PlayerPokemon> members,
  }) = _PlayerParty;

  factory PlayerParty.fromJson(Map<String, dynamic> json) =>
      _$PlayerPartyFromJson(json);

  PlayerParty normalized() => copyWith(
        members: members
            .map((member) => member.normalized())
            .toList(growable: false),
      );
}

/// Progression du joueur — field abilities débloquées, flags scénaristiques.
///
/// [completedStepIds] : identifiants des steps **Step Studio** déjà terminées
/// côté runtime (ex. completion `whenCutsceneEnds`). Persistance save/load
/// via [SaveData.progression] ; distinct des flags narratifs génériques.
@freezed
class PlayerProgression with _$PlayerProgression {
  const PlayerProgression._();

  @JsonSerializable(explicitToJson: true)
  const factory PlayerProgression({
    @Default([]) List<FieldAbility> unlockedFieldAbilities,
    @Default([]) List<String> storyFlags,

    /// Steps du document `authoring.stepStudioDocument` marquées comme
    /// complétées (ordre stable = ordre d’insertion ; dédoublonnage à l’écriture).
    @Default([]) List<String> completedStepIds,

    /// Scénarios **locaux** (cutscenes) dont le graphe a atteint un nœud `end`
    /// au moins une fois dans cette partie — utilisé pour prédicats
    /// `cutsceneCompleted` sur les PNJ (ids = [ScenarioAsset.id]).
    @Default([]) List<String> completedCutsceneIds,
  }) = _PlayerProgression;

  factory PlayerProgression.fromJson(Map<String, dynamic> json) =>
      _$PlayerProgressionFromJson(json);

  PlayerProgression normalized() => copyWith(
        storyFlags: _normalizeUniqueStringsSorted(storyFlags),
        completedStepIds:
            _normalizeUniqueStringsPreserveOrder(completedStepIds),
        completedCutsceneIds:
            _normalizeUniqueStringsPreserveOrder(completedCutsceneIds),
      );
}

@freezed
class TrainerProfile with _$TrainerProfile {
  const TrainerProfile._();

  @JsonSerializable(explicitToJson: true)
  const factory TrainerProfile({
    required String name,
    @Default([]) List<String> badgeIds,
    @Default(0) int money,
    @Default(0) int playtimeSeconds,
  }) = _TrainerProfile;

  factory TrainerProfile.fromJson(Map<String, dynamic> json) =>
      _$TrainerProfileFromJson(json);

  TrainerProfile normalized() {
    final normalizedName = name.trim();
    if (badgeIds.any((badgeId) => badgeId.trim().isEmpty)) {
      throw StateError('TrainerProfile badgeIds must not contain empty values');
    }
    final normalizedBadgeIds = _normalizeUniqueStringsSorted(badgeIds);

    if (normalizedName.isEmpty) {
      throw StateError('TrainerProfile name must not be empty');
    }
    if (money < 0) {
      throw StateError('TrainerProfile money must be non-negative');
    }
    if (playtimeSeconds < 0) {
      throw StateError('TrainerProfile playtimeSeconds must be non-negative');
    }

    return copyWith(
      name: normalizedName,
      badgeIds: normalizedBadgeIds,
    );
  }
}

@freezed
class BagEntry with _$BagEntry {
  const BagEntry._();

  @JsonSerializable(explicitToJson: true)
  const factory BagEntry({
    required String itemId,
    required String categoryId,
    required int quantity,
  }) = _BagEntry;

  factory BagEntry.fromJson(Map<String, dynamic> json) =>
      _$BagEntryFromJson(json);

  BagEntry normalized() {
    final normalizedItemId = itemId.trim();
    final normalizedCategoryId = categoryId.trim();

    if (normalizedItemId.isEmpty) {
      throw StateError('BagEntry itemId must not be empty');
    }
    if (normalizedCategoryId.isEmpty) {
      throw StateError('BagEntry categoryId must not be empty');
    }
    if (quantity <= 0) {
      throw StateError('BagEntry quantity must be positive');
    }

    return copyWith(
      itemId: normalizedItemId,
      categoryId: normalizedCategoryId,
    );
  }
}

List<BagEntry> _normalizeBagEntries(List<BagEntry> entries) {
  final merged = <String, BagEntry>{};
  for (final entry in entries.map((entry) => entry.normalized())) {
    final key = '${entry.categoryId}\u0000${entry.itemId}';
    final current = merged[key];
    merged[key] = current == null
        ? entry
        : current.copyWith(quantity: current.quantity + entry.quantity);
  }
  final normalized = merged.values.toList(growable: false)
    ..sort((a, b) {
      final byCategory = a.categoryId.compareTo(b.categoryId);
      if (byCategory != 0) {
        return byCategory;
      }
      return a.itemId.compareTo(b.itemId);
    });
  return List.unmodifiable(normalized);
}

@freezed
class Bag with _$Bag {
  const Bag._();

  @JsonSerializable(explicitToJson: true)
  const factory Bag({
    @Default([]) List<BagEntry> entries,
  }) = _Bag;

  factory Bag.fromJson(Map<String, dynamic> json) => _$BagFromJson(json);

  Bag normalized() => copyWith(entries: _normalizeBagEntries(entries));
}

/// Racine de l'état persistant de la partie.
///
/// Sérialisable JSON, immutable, indépendant du runtime.
/// Pensé pour évoluer vers une vraie sauvegarde disque.
@freezed
class SaveData with _$SaveData {
  const SaveData._();

  @JsonSerializable(explicitToJson: true)
  const factory SaveData({
    required String saveId,
    @Default('') String currentMapId,
    @Default(GridPos(x: 0, y: 0)) GridPos playerPosition,
    @Default(EntityFacing.south) EntityFacing playerFacing,
    @Default(PlayerParty()) PlayerParty party,
    @Default(TrainerProfile(name: 'Player')) TrainerProfile trainerProfile,
    @Default(Bag()) Bag bag,
    @Default(PlayerProgression()) PlayerProgression progression,
    @Default({}) Map<String, String> properties,
  }) = _SaveData;

  factory SaveData.fromJson(Map<String, dynamic> json) =>
      _$SaveDataFromJson(json);

  SaveData normalized() {
    final normalizedSaveId = saveId.trim();
    final normalizedCurrentMapId = currentMapId.trim();

    if (normalizedSaveId.isEmpty) {
      throw StateError('SaveData saveId must not be empty');
    }

    return copyWith(
      saveId: normalizedSaveId,
      currentMapId: normalizedCurrentMapId,
      party: party.normalized(),
      trainerProfile: trainerProfile.normalized(),
      bag: bag.normalized(),
      progression: progression.normalized(),
      properties: _normalizeStringMap(properties),
    );
  }
}
