import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'geometry.dart';
import 'narrative_event_progress.dart';
import 'narrative_fact_runtime_state.dart';

part 'save_data.freezed.dart';
part 'save_data.g.dart';

/// Semantic pronoun choice persisted independently from the active locale.
///
/// Runtime dialogue projections translate the set when a session starts,
/// keeping save data stable when the player changes language.
enum PlayerPronounSet {
  neutral,
  feminine,
  masculine,
}

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

const _legacyPlayerPokemonNatureId = 'hardy';
const _legacyPlayerPokemonAbilityId = 'unknown';

Map<String, dynamic> _migrateLegacyPlayerPokemonJson(
  Map<String, dynamic> json,
) {
  final hasLegacyMarkers = json['id'] is String ||
      json.containsKey('nickname') ||
      json.containsKey('isFainted');
  if (!hasLegacyMarkers) {
    return json;
  }
  final migrated = Map<String, dynamic>.from(json);
  final natureId = migrated['natureId'];
  if (natureId == null) {
    migrated['natureId'] = _legacyPlayerPokemonNatureId;
  }
  final abilityId = migrated['abilityId'];
  if (abilityId == null) {
    migrated['abilityId'] = _legacyPlayerPokemonAbilityId;
  }
  final currentHp = migrated['currentHp'];
  if (currentHp == null && migrated['isFainted'] is bool) {
    migrated['currentHp'] = (migrated['isFainted'] as bool) ? 0 : 1;
  }
  return migrated;
}

@freezed
abstract class PokemonStatSpread with _$PokemonStatSpread {
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

enum PlayerPokemonOriginKind {
  unknown,
  captured,
  gift,
  starter,
  trade,
  scripted,
}

@freezed
abstract class PlayerPokemonProvenance with _$PlayerPokemonProvenance {
  const PlayerPokemonProvenance._();

  const factory PlayerPokemonProvenance({
    @Default(PlayerPokemonOriginKind.unknown) PlayerPokemonOriginKind kind,
    @Default('') String mapId,
    @Default('') String sourceId,
    @Default('') String ballItemId,
    int? metLevel,
  }) = _PlayerPokemonProvenance;

  factory PlayerPokemonProvenance.fromJson(Map<String, dynamic> json) =>
      _$PlayerPokemonProvenanceFromJson(json);

  PlayerPokemonProvenance normalized() {
    if (metLevel != null && (metLevel! < 1 || metLevel! > 100)) {
      throw StateError(
        'PlayerPokemonProvenance metLevel must be between 1 and 100',
      );
    }
    return copyWith(
      mapId: mapId.trim(),
      sourceId: sourceId.trim(),
      ballItemId: ballItemId.trim(),
    );
  }
}

@freezed
abstract class PlayerPokemon with _$PlayerPokemon {
  const PlayerPokemon._();

  @JsonSerializable(explicitToJson: true)
  const factory PlayerPokemon({
    required String speciesId,
    required String natureId,
    required String abilityId,
    String? gender,
    @Default(1) int level,
    @Default(PokemonStatSpread()) PokemonStatSpread ivs,
    @Default(PokemonStatSpread()) PokemonStatSpread evs,
    @Default([]) List<String> knownMoveIds,

    /// Total cumulative experience.
    ///
    /// `null` is deliberately preserved for saves created before FG-021. It
    /// must not be interpreted as zero because that would silently regress a
    /// legacy levelled Pokemon to the level-one experience floor.
    int? experience,

    /// Current PP indexed by canonical move id.
    ///
    /// `null` is the legacy migration sentinel. An empty non-null map is a
    /// fully hydrated Pokemon with no known moves; max PP stays catalogue
    /// derived and therefore does not belong in this persistence contract.
    Map<String, int>? currentPpByMoveId,
    @Default(1) int currentHp,
    @Default('') String statusId,
    @Default(false) bool isShiny,
    @Default('') String heldItemId,
    @Default('') String nickname,
    @Default(0) int friendship,
    PlayerPokemonProvenance? provenance,
  }) = _PlayerPokemon;

  factory PlayerPokemon.fromJson(Map<String, dynamic> json) =>
      _$PlayerPokemonFromJson(_migrateLegacyPlayerPokemonJson(json));

  bool get isFainted => currentHp <= 0;

  PlayerPokemon normalized() {
    final normalizedSpeciesId = speciesId.trim();
    final normalizedNatureId = natureId.trim();
    final normalizedAbilityId = abilityId.trim();
    final normalizedGender = gender?.trim().toLowerCase();
    if (knownMoveIds.any((moveId) => moveId.trim().isEmpty)) {
      throw StateError(
          'PlayerPokemon knownMoveIds must not contain empty values');
    }
    final normalizedMoveIds =
        _normalizeUniqueStringsPreserveOrder(knownMoveIds);
    if (experience != null && experience! < 0) {
      throw StateError('PlayerPokemon experience must be non-negative');
    }
    final currentPp = currentPpByMoveId;
    Map<String, int>? normalizedCurrentPpByMoveId;
    if (currentPp != null) {
      final normalizedEntries = <MapEntry<String, int>>[];
      final seenMoveIds = <String>{};
      for (final entry in currentPp.entries) {
        final moveId = entry.key.trim();
        if (moveId.isEmpty) {
          throw StateError(
            'PlayerPokemon currentPpByMoveId keys must not be empty',
          );
        }
        if (entry.value < 0) {
          throw StateError(
            'PlayerPokemon currentPpByMoveId values must be non-negative',
          );
        }
        if (!seenMoveIds.add(moveId)) {
          throw StateError(
            'PlayerPokemon currentPpByMoveId must not contain duplicate '
            'normalized move ids',
          );
        }
        normalizedEntries.add(MapEntry(moveId, entry.value));
      }
      normalizedEntries.sort((left, right) => left.key.compareTo(right.key));
      normalizedCurrentPpByMoveId =
          Map<String, int>.unmodifiable(Map.fromEntries(normalizedEntries));
    }
    final normalizedStatusId = statusId.trim();
    final normalizedHeldItemId = heldItemId.trim();
    final normalizedNickname = nickname.trim();

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
    if (friendship < 0 || friendship > 255) {
      throw StateError('PlayerPokemon friendship must be between 0 and 255');
    }
    if (normalizedMoveIds.length > 4) {
      throw StateError(
          'PlayerPokemon knownMoveIds must contain at most 4 moves');
    }

    ivs.normalized();
    evs.normalized();
    final normalizedProvenance = provenance?.normalized();

    return copyWith(
      speciesId: normalizedSpeciesId,
      natureId: normalizedNatureId,
      abilityId: normalizedAbilityId,
      gender: normalizedGender == null || normalizedGender.isEmpty
          ? null
          : normalizedGender,
      ivs: ivs.normalized(),
      evs: evs.normalized(),
      knownMoveIds: normalizedMoveIds,
      currentPpByMoveId: normalizedCurrentPpByMoveId,
      statusId: normalizedStatusId,
      heldItemId: normalizedHeldItemId,
      nickname: normalizedNickname,
      provenance: normalizedProvenance,
    );
  }
}

@freezed
abstract class PlayerParty with _$PlayerParty {
  const PlayerParty._();

  @JsonSerializable(explicitToJson: true)
  const factory PlayerParty({
    @Default([]) List<PlayerPokemon> members,
  }) = _PlayerParty;

  factory PlayerParty.fromJson(Map<String, dynamic> json) =>
      _$PlayerPartyFromJson(json);

  PlayerParty normalized() {
    if (members.length > maxPlayerPartySize) {
      throw StateError(
        'PlayerParty members must contain at most $maxPlayerPartySize Pokemon',
      );
    }
    return copyWith(
      members:
          members.map((member) => member.normalized()).toList(growable: false),
    );
  }
}

const int maxPlayerPartySize = 6;
const int pokemonBoxCapacity = 30;
const int defaultPokemonBoxCount = 8;

@freezed
abstract class PokemonBox with _$PokemonBox {
  const PokemonBox._();

  @JsonSerializable(explicitToJson: true)
  const factory PokemonBox({
    required String id,
    required String label,
    @Default(pokemonBoxCapacity) int capacity,
    @Default([]) List<PlayerPokemon> pokemon,
  }) = _PokemonBox;

  factory PokemonBox.fromJson(Map<String, dynamic> json) =>
      _$PokemonBoxFromJson(json).normalized();

  PokemonBox normalized() {
    final normalizedId = id.trim();
    final normalizedLabel = label.trim();
    if (normalizedId.isEmpty) {
      throw StateError('PokemonBox id must not be empty');
    }
    if (normalizedLabel.isEmpty) {
      throw StateError('PokemonBox label must not be empty');
    }
    if (capacity <= 0) {
      throw StateError('PokemonBox capacity must be positive');
    }
    if (pokemon.length > capacity) {
      throw StateError('PokemonBox pokemon must not exceed capacity');
    }
    return copyWith(
      id: normalizedId,
      label: normalizedLabel,
      pokemon:
          pokemon.map((member) => member.normalized()).toList(growable: false),
    );
  }
}

/// Persistent PC storage with stable, ordered boxes.
///
/// [storedPokemon] remains as a source-compatible bridge for callers created
/// before FG-022. JSON output is canonical and only writes [boxes].
class PokemonStorage {
  const PokemonStorage({
    this.boxes = const <PokemonBox>[],
    List<PlayerPokemon> storedPokemon = const <PlayerPokemon>[],
  }) : _legacyStoredPokemon = storedPokemon;

  factory PokemonStorage.fromJson(Map<String, dynamic> json) {
    final rawBoxes = json['boxes'];
    if (rawBoxes != null) {
      if (rawBoxes is! List) {
        throw const FormatException('PokemonStorage.boxes must be a list');
      }
      return PokemonStorage(
        boxes: rawBoxes.map((rawBox) {
          if (rawBox is! Map) {
            throw const FormatException(
              'PokemonStorage boxes must be objects',
            );
          }
          return PokemonBox.fromJson(Map<String, dynamic>.from(rawBox));
        }).toList(growable: false),
      ).normalized();
    }

    final rawStoredPokemon = json['storedPokemon'];
    if (rawStoredPokemon != null && rawStoredPokemon is! List) {
      throw const FormatException(
        'PokemonStorage.storedPokemon must be a list',
      );
    }
    return PokemonStorage(
      storedPokemon:
          (rawStoredPokemon as List? ?? const <Object?>[]).map((rawPokemon) {
        if (rawPokemon is! Map) {
          throw const FormatException(
            'PokemonStorage storedPokemon must contain objects',
          );
        }
        return PlayerPokemon.fromJson(
          Map<String, dynamic>.from(rawPokemon),
        );
      }).toList(growable: false),
    ).normalized();
  }

  final List<PokemonBox> boxes;
  final List<PlayerPokemon> _legacyStoredPokemon;

  List<PlayerPokemon> get storedPokemon => boxes.isEmpty
      ? List<PlayerPokemon>.unmodifiable(_legacyStoredPokemon)
      : List<PlayerPokemon>.unmodifiable(
          boxes.expand((box) => box.pokemon),
        );

  PokemonStorage normalized() {
    final sourceBoxes = boxes.isEmpty
        ? _boxesFromLegacyPokemon(_legacyStoredPokemon)
        : boxes.map((box) => box.normalized()).toList(growable: false);
    final ids = <String>{};
    for (final box in sourceBoxes) {
      if (!ids.add(box.id)) {
        throw StateError('PokemonStorage box ids must be unique');
      }
    }
    return PokemonStorage(
      boxes: List<PokemonBox>.unmodifiable(sourceBoxes),
    );
  }

  PokemonStorage copyWith({
    List<PokemonBox>? boxes,
    List<PlayerPokemon>? storedPokemon,
  }) {
    if (storedPokemon != null) {
      return PokemonStorage(storedPokemon: storedPokemon);
    }
    return PokemonStorage(boxes: boxes ?? this.boxes);
  }

  Map<String, dynamic> toJson() {
    final canonical = normalized();
    return <String, dynamic>{
      'boxes':
          canonical.boxes.map((box) => box.toJson()).toList(growable: false),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PokemonStorage &&
          _listsEqual(normalized().boxes, other.normalized().boxes);

  @override
  int get hashCode => Object.hashAll(normalized().boxes);

  @override
  String toString() => 'PokemonStorage(boxes: $boxes)';
}

List<PokemonBox> _boxesFromLegacyPokemon(List<PlayerPokemon> pokemon) {
  final normalizedPokemon =
      pokemon.map((member) => member.normalized()).toList(growable: false);
  final requiredBoxCount = normalizedPokemon.isEmpty
      ? defaultPokemonBoxCount
      : (normalizedPokemon.length / pokemonBoxCapacity)
          .ceil()
          .clamp(defaultPokemonBoxCount, 999);
  return List<PokemonBox>.generate(requiredBoxCount, (index) {
    final start = index * pokemonBoxCapacity;
    final end = start + pokemonBoxCapacity < normalizedPokemon.length
        ? start + pokemonBoxCapacity
        : normalizedPokemon.length;
    return PokemonBox(
      id: 'box-${(index + 1).toString().padLeft(2, '0')}',
      label: 'Box ${index + 1}',
      pokemon: start < normalizedPokemon.length
          ? normalizedPokemon.sublist(start, end)
          : const <PlayerPokemon>[],
    );
  }, growable: false);
}

bool _listsEqual<T>(List<T> left, List<T> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

@freezed
abstract class PlayerProgression with _$PlayerProgression {
  const PlayerProgression._();

  @JsonSerializable(explicitToJson: true)
  const factory PlayerProgression({
    @Default([]) List<FieldAbility> unlockedFieldAbilities,
    @Default([]) List<String> storyFlags,
    @Default({}) Map<String, int> shopPurchaseCounts,
    @Default([]) List<String> completedStepIds,
    @Default([]) List<String> completedCutsceneIds,
    @Default([]) List<String> seenSpeciesIds,
    @Default([]) List<String> caughtSpeciesIds,
  }) = _PlayerProgression;

  factory PlayerProgression.fromJson(Map<String, dynamic> json) =>
      _$PlayerProgressionFromJson(json);

  PlayerProgression normalized() {
    final normalizedShopPurchaseCounts = <String, int>{};
    final sortedShopKeys = shopPurchaseCounts.keys.toList(growable: false)
      ..sort();
    for (final rawKey in sortedShopKeys) {
      final key = rawKey.trim();
      final count = shopPurchaseCounts[rawKey]!;
      if (key.isEmpty) {
        throw StateError(
          'PlayerProgression shopPurchaseCounts keys must not be empty',
        );
      }
      if (count < 0) {
        throw StateError(
          'PlayerProgression shopPurchaseCounts values must be non-negative',
        );
      }
      if (normalizedShopPurchaseCounts.containsKey(key)) {
        throw StateError(
          'PlayerProgression shopPurchaseCounts contains duplicate normalized keys',
        );
      }
      normalizedShopPurchaseCounts[key] = count;
    }
    final normalizedCaughtSpeciesIds =
        _normalizeUniqueStringsSorted(caughtSpeciesIds);
    final normalizedSeenSpeciesIds = _normalizeUniqueStringsSorted(
      <String>[
        ...seenSpeciesIds,
        ...normalizedCaughtSpeciesIds,
      ],
    );

    return copyWith(
      storyFlags: _normalizeUniqueStringsSorted(storyFlags),
      shopPurchaseCounts: Map<String, int>.unmodifiable(
        normalizedShopPurchaseCounts,
      ),
      completedStepIds: _normalizeUniqueStringsPreserveOrder(completedStepIds),
      completedCutsceneIds:
          _normalizeUniqueStringsPreserveOrder(completedCutsceneIds),
      seenSpeciesIds: normalizedSeenSpeciesIds,
      caughtSpeciesIds: normalizedCaughtSpeciesIds,
    );
  }
}

@freezed
abstract class TrainerProfile with _$TrainerProfile {
  const TrainerProfile._();

  @JsonSerializable(explicitToJson: true)
  const factory TrainerProfile({
    required String name,
    String? avatarCharacterId,
    @Default(PlayerPronounSet.neutral) PlayerPronounSet pronounSet,
    @Default([]) List<String> badgeIds,
    @Default(0) int money,
    @Default(0) int playtimeSeconds,
  }) = _TrainerProfile;

  factory TrainerProfile.fromJson(Map<String, dynamic> json) =>
      _$TrainerProfileFromJson(json);

  TrainerProfile normalized() {
    final normalizedName = name.trim();
    final normalizedAvatarCharacterId = avatarCharacterId?.trim();
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
      avatarCharacterId: normalizedAvatarCharacterId == null ||
              normalizedAvatarCharacterId.isEmpty
          ? null
          : normalizedAvatarCharacterId,
      badgeIds: normalizedBadgeIds,
    );
  }
}

const currentItemSystemSaveSchemaVersion = 1;
const maximumBagEntryQuantity = 0x7fffffffffffffff;
const _bagEntryJsonKeys = <String>{'itemId', 'quantity'};

final class UnsupportedSaveSchema implements Exception {
  const UnsupportedSaveSchema({
    required this.schemaVersion,
    required this.expectedSchemaVersion,
    required this.path,
  });

  final Object? schemaVersion;
  final int expectedSchemaVersion;
  final String path;

  String get code => 'UnsupportedSaveSchema';

  @override
  String toString() {
    return 'UnsupportedSaveSchema(schemaVersion: $schemaVersion, '
        'expectedSchemaVersion: $expectedSchemaVersion, path: $path)';
  }
}

@freezed
abstract class BagEntry with _$BagEntry {
  const BagEntry._();

  @JsonSerializable(explicitToJson: true)
  const factory BagEntry({
    required String itemId,
    required int quantity,
  }) = _BagEntry;

  factory BagEntry.fromJson(Map<String, dynamic> json) =>
      _$BagEntryFromJson(json);

  BagEntry normalized() {
    final normalizedItemId = itemId.trim();

    if (normalizedItemId.isEmpty) {
      throw StateError('BagEntry itemId must not be empty');
    }
    if (quantity <= 0) {
      throw StateError('BagEntry quantity must be positive');
    }
    if (quantity > maximumBagEntryQuantity) {
      throw StateError(
        'BagEntry quantity exceeds $maximumBagEntryQuantity',
      );
    }

    return copyWith(itemId: normalizedItemId);
  }
}

List<BagEntry> _normalizeBagEntries(List<BagEntry> entries) {
  final merged = <String, BagEntry>{};
  for (final entry in entries.map((entry) => entry.normalized())) {
    final current = merged[entry.itemId];
    if (current != null &&
        current.quantity > maximumBagEntryQuantity - entry.quantity) {
      throw StateError(
        'BagEntry quantity for ${entry.itemId} exceeds '
        '$maximumBagEntryQuantity',
      );
    }
    merged[entry.itemId] = current == null
        ? entry
        : current.copyWith(quantity: current.quantity + entry.quantity);
  }
  final normalized = merged.values.toList(growable: false)
    ..sort((a, b) => a.itemId.compareTo(b.itemId));
  return List.unmodifiable(normalized);
}

@freezed
abstract class Bag with _$Bag {
  const Bag._();

  @JsonSerializable(explicitToJson: true)
  const factory Bag({
    @Default([]) List<BagEntry> entries,
  }) = _Bag;

  factory Bag.fromJson(Map<String, dynamic> json) => _$BagFromJson(json);

  Bag normalized() => copyWith(entries: _normalizeBagEntries(entries));
}

@freezed
abstract class SaveData with _$SaveData {
  const SaveData._();

  @JsonSerializable(explicitToJson: true)
  const factory SaveData({
    required String saveId,
    @Default(currentItemSystemSaveSchemaVersion)
    int itemSystemSchemaVersion,
    @Default('') String currentMapId,
    @Default(GridPos(x: 0, y: 0)) GridPos playerPosition,
    @Default(EntityFacing.south) EntityFacing playerFacing,
    @Default(PlayerParty()) PlayerParty party,
    @Default(PokemonStorage()) PokemonStorage pokemonStorage,
    @Default(TrainerProfile(name: 'Player')) TrainerProfile trainerProfile,
    @Default(Bag()) Bag bag,
    @Default(PlayerProgression()) PlayerProgression progression,
    @JsonKey(readValue: readNarrativeFactRuntimeStateJson)
    @Default(NarrativeFactRuntimeState.empty())
    NarrativeFactRuntimeState narrativeFactRuntimeState,
    @JsonKey(
      readValue: readNarrativeEventProgressJson,
      toJson: narrativeEventProgressToJson,
    )
    @Default(NarrativeEventProgress.empty())
    NarrativeEventProgress narrativeEventProgress,
    @Default({}) Map<String, String> properties,
  }) = _SaveData;

  factory SaveData.fromJson(Map<String, dynamic> json) => _decodeSaveData(json);

  SaveData normalized() {
    final normalizedSaveId = saveId.trim();
    final normalizedCurrentMapId = currentMapId.trim();

    if (normalizedSaveId.isEmpty) {
      throw StateError('SaveData saveId must not be empty');
    }
    if (itemSystemSchemaVersion != currentItemSystemSaveSchemaVersion) {
      throw UnsupportedSaveSchema(
        schemaVersion: itemSystemSchemaVersion,
        expectedSchemaVersion: currentItemSystemSaveSchemaVersion,
        path: r'$.itemSystemSchemaVersion',
      );
    }

    return copyWith(
      saveId: normalizedSaveId,
      currentMapId: normalizedCurrentMapId,
      party: party.normalized(),
      pokemonStorage: pokemonStorage.normalized(),
      trainerProfile: trainerProfile.normalized(),
      bag: bag.normalized(),
      progression: progression.normalized(),
      narrativeFactRuntimeState: narrativeFactRuntimeState,
      narrativeEventProgress: narrativeEventProgress,
      properties: _normalizeStringMap(properties),
    );
  }
}

void _validateItemSystemSaveSchema(Map<String, dynamic> json) {
  final schemaVersion = json['itemSystemSchemaVersion'];
  if (schemaVersion != currentItemSystemSaveSchemaVersion) {
    throw UnsupportedSaveSchema(
      schemaVersion: schemaVersion,
      expectedSchemaVersion: currentItemSystemSaveSchemaVersion,
      path: r'$.itemSystemSchemaVersion',
    );
  }

  final bag = json['bag'];
  if (bag is! Map<String, dynamic>) {
    return;
  }
  final entries = bag['entries'];
  if (entries is! List<Object?>) {
    return;
  }
  for (var index = 0; index < entries.length; index += 1) {
    final entry = entries[index];
    if (entry is! Map<String, dynamic>) {
      continue;
    }
    final unknownKeys =
        entry.keys
            .where((key) => !_bagEntryJsonKeys.contains(key))
            .toList(growable: false)
          ..sort();
    if (unknownKeys.isEmpty) {
      continue;
    }
    throw UnsupportedSaveSchema(
      schemaVersion: schemaVersion,
      expectedSchemaVersion: currentItemSystemSaveSchemaVersion,
      path: '\$.bag.entries[$index].${unknownKeys.first}',
    );
  }
}

SaveData _decodeSaveData(Map<String, dynamic> json) {
  _validateItemSystemSaveSchema(json);
  return _$SaveDataFromJson(json);
}
