// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PokemonStatSpread _$PokemonStatSpreadFromJson(Map<String, dynamic> json) =>
    _PokemonStatSpread(
      hp: (json['hp'] as num?)?.toInt() ?? 0,
      attack: (json['attack'] as num?)?.toInt() ?? 0,
      defense: (json['defense'] as num?)?.toInt() ?? 0,
      specialAttack: (json['specialAttack'] as num?)?.toInt() ?? 0,
      specialDefense: (json['specialDefense'] as num?)?.toInt() ?? 0,
      speed: (json['speed'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$PokemonStatSpreadToJson(_PokemonStatSpread instance) =>
    <String, dynamic>{
      'hp': instance.hp,
      'attack': instance.attack,
      'defense': instance.defense,
      'specialAttack': instance.specialAttack,
      'specialDefense': instance.specialDefense,
      'speed': instance.speed,
    };

_PlayerPokemonProvenance _$PlayerPokemonProvenanceFromJson(
  Map<String, dynamic> json,
) => _PlayerPokemonProvenance(
  kind:
      $enumDecodeNullable(_$PlayerPokemonOriginKindEnumMap, json['kind']) ??
      PlayerPokemonOriginKind.unknown,
  mapId: json['mapId'] as String? ?? '',
  sourceId: json['sourceId'] as String? ?? '',
  ballItemId: json['ballItemId'] as String? ?? '',
  metLevel: (json['metLevel'] as num?)?.toInt(),
);

Map<String, dynamic> _$PlayerPokemonProvenanceToJson(
  _PlayerPokemonProvenance instance,
) => <String, dynamic>{
  'kind': _$PlayerPokemonOriginKindEnumMap[instance.kind]!,
  'mapId': instance.mapId,
  'sourceId': instance.sourceId,
  'ballItemId': instance.ballItemId,
  'metLevel': instance.metLevel,
};

const _$PlayerPokemonOriginKindEnumMap = {
  PlayerPokemonOriginKind.unknown: 'unknown',
  PlayerPokemonOriginKind.captured: 'captured',
  PlayerPokemonOriginKind.gift: 'gift',
  PlayerPokemonOriginKind.starter: 'starter',
  PlayerPokemonOriginKind.trade: 'trade',
  PlayerPokemonOriginKind.scripted: 'scripted',
};

_PlayerPokemon _$PlayerPokemonFromJson(Map<String, dynamic> json) =>
    _PlayerPokemon(
      individualId: json['individualId'] as String? ?? '',
      speciesId: json['speciesId'] as String,
      formId: json['formId'] as String? ?? '',
      natureId: json['natureId'] as String,
      abilityId: json['abilityId'] as String,
      gender: json['gender'] as String?,
      level: (json['level'] as num?)?.toInt() ?? 1,
      ivs: json['ivs'] == null
          ? const PokemonStatSpread()
          : PokemonStatSpread.fromJson(json['ivs'] as Map<String, dynamic>),
      evs: json['evs'] == null
          ? const PokemonStatSpread()
          : PokemonStatSpread.fromJson(json['evs'] as Map<String, dynamic>),
      knownMoveIds:
          (json['knownMoveIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      experience: (json['experience'] as num?)?.toInt(),
      currentPpByMoveId: (json['currentPpByMoveId'] as Map<String, dynamic>?)
          ?.map((k, e) => MapEntry(k, (e as num).toInt())),
      currentHp: (json['currentHp'] as num?)?.toInt() ?? 1,
      statusId: json['statusId'] as String? ?? '',
      isShiny: json['isShiny'] as bool? ?? false,
      heldItemId: json['heldItemId'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      friendship: (json['friendship'] as num?)?.toInt() ?? 0,
      provenance: json['provenance'] == null
          ? null
          : PlayerPokemonProvenance.fromJson(
              json['provenance'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$PlayerPokemonToJson(_PlayerPokemon instance) =>
    <String, dynamic>{
      'individualId': instance.individualId,
      'speciesId': instance.speciesId,
      'formId': instance.formId,
      'natureId': instance.natureId,
      'abilityId': instance.abilityId,
      'gender': instance.gender,
      'level': instance.level,
      'ivs': instance.ivs.toJson(),
      'evs': instance.evs.toJson(),
      'knownMoveIds': instance.knownMoveIds,
      'experience': instance.experience,
      'currentPpByMoveId': instance.currentPpByMoveId,
      'currentHp': instance.currentHp,
      'statusId': instance.statusId,
      'isShiny': instance.isShiny,
      'heldItemId': instance.heldItemId,
      'nickname': instance.nickname,
      'friendship': instance.friendship,
      'provenance': instance.provenance?.toJson(),
    };

_PlayerParty _$PlayerPartyFromJson(Map<String, dynamic> json) => _PlayerParty(
  members:
      (json['members'] as List<dynamic>?)
          ?.map((e) => PlayerPokemon.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$PlayerPartyToJson(_PlayerParty instance) =>
    <String, dynamic>{
      'members': instance.members.map((e) => e.toJson()).toList(),
    };

_PokemonBox _$PokemonBoxFromJson(Map<String, dynamic> json) => _PokemonBox(
  id: json['id'] as String,
  label: json['label'] as String,
  capacity: (json['capacity'] as num?)?.toInt() ?? pokemonBoxCapacity,
  pokemon:
      (json['pokemon'] as List<dynamic>?)
          ?.map((e) => PlayerPokemon.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$PokemonBoxToJson(_PokemonBox instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'capacity': instance.capacity,
      'pokemon': instance.pokemon.map((e) => e.toJson()).toList(),
    };

_PlayerProgression _$PlayerProgressionFromJson(Map<String, dynamic> json) =>
    _PlayerProgression(
      unlockedFieldAbilities:
          (json['unlockedFieldAbilities'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$FieldAbilityEnumMap, e))
              .toList() ??
          const [],
      storyFlags:
          (json['storyFlags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      shopPurchaseCounts:
          (json['shopPurchaseCounts'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
      completedStepIds:
          (json['completedStepIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      completedCutsceneIds:
          (json['completedCutsceneIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      seenSpeciesIds:
          (json['seenSpeciesIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      caughtSpeciesIds:
          (json['caughtSpeciesIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$PlayerProgressionToJson(_PlayerProgression instance) =>
    <String, dynamic>{
      'unlockedFieldAbilities': instance.unlockedFieldAbilities
          .map((e) => _$FieldAbilityEnumMap[e]!)
          .toList(),
      'storyFlags': instance.storyFlags,
      'shopPurchaseCounts': instance.shopPurchaseCounts,
      'completedStepIds': instance.completedStepIds,
      'completedCutsceneIds': instance.completedCutsceneIds,
      'seenSpeciesIds': instance.seenSpeciesIds,
      'caughtSpeciesIds': instance.caughtSpeciesIds,
    };

const _$FieldAbilityEnumMap = {
  FieldAbility.surf: 'surf',
  FieldAbility.cut: 'cut',
  FieldAbility.strength: 'strength',
  FieldAbility.flash: 'flash',
  FieldAbility.rockSmash: 'rock_smash',
  FieldAbility.waterfall: 'waterfall',
  FieldAbility.dive: 'dive',
};

_TrainerProfile _$TrainerProfileFromJson(Map<String, dynamic> json) =>
    _TrainerProfile(
      name: json['name'] as String,
      avatarCharacterId: json['avatarCharacterId'] as String?,
      pronounSet:
          $enumDecodeNullable(_$PlayerPronounSetEnumMap, json['pronounSet']) ??
          PlayerPronounSet.neutral,
      badgeIds:
          (json['badgeIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      money: (json['money'] as num?)?.toInt() ?? 0,
      playtimeSeconds: (json['playtimeSeconds'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$TrainerProfileToJson(_TrainerProfile instance) =>
    <String, dynamic>{
      'name': instance.name,
      'avatarCharacterId': instance.avatarCharacterId,
      'pronounSet': _$PlayerPronounSetEnumMap[instance.pronounSet]!,
      'badgeIds': instance.badgeIds,
      'money': instance.money,
      'playtimeSeconds': instance.playtimeSeconds,
    };

const _$PlayerPronounSetEnumMap = {
  PlayerPronounSet.neutral: 'neutral',
  PlayerPronounSet.feminine: 'feminine',
  PlayerPronounSet.masculine: 'masculine',
};

_BagEntry _$BagEntryFromJson(Map<String, dynamic> json) => _BagEntry(
  itemId: json['itemId'] as String,
  quantity: (json['quantity'] as num).toInt(),
);

Map<String, dynamic> _$BagEntryToJson(_BagEntry instance) => <String, dynamic>{
  'itemId': instance.itemId,
  'quantity': instance.quantity,
};

_Bag _$BagFromJson(Map<String, dynamic> json) => _Bag(
  entries:
      (json['entries'] as List<dynamic>?)
          ?.map((e) => BagEntry.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$BagToJson(_Bag instance) => <String, dynamic>{
  'entries': instance.entries.map((e) => e.toJson()).toList(),
};

_SaveData _$SaveDataFromJson(Map<String, dynamic> json) => _SaveData(
  saveId: json['saveId'] as String,
  itemSystemSchemaVersion:
      (json['itemSystemSchemaVersion'] as num?)?.toInt() ??
      currentItemSystemSaveSchemaVersion,
  currentMapId: json['currentMapId'] as String? ?? '',
  playerPosition: json['playerPosition'] == null
      ? const GridPos(x: 0, y: 0)
      : GridPos.fromJson(json['playerPosition'] as Map<String, dynamic>),
  playerFacing:
      $enumDecodeNullable(_$EntityFacingEnumMap, json['playerFacing']) ??
      EntityFacing.south,
  playerMovementMode:
      $enumDecodeNullable(_$MovementModeEnumMap, json['playerMovementMode']) ??
      MovementMode.walk,
  party: json['party'] == null
      ? const PlayerParty()
      : PlayerParty.fromJson(json['party'] as Map<String, dynamic>),
  pokemonStorage: json['pokemonStorage'] == null
      ? const PokemonStorage()
      : PokemonStorage.fromJson(json['pokemonStorage'] as Map<String, dynamic>),
  trainerProfile: json['trainerProfile'] == null
      ? const TrainerProfile(name: 'Player')
      : TrainerProfile.fromJson(json['trainerProfile'] as Map<String, dynamic>),
  bag: json['bag'] == null
      ? const Bag()
      : Bag.fromJson(json['bag'] as Map<String, dynamic>),
  progression: json['progression'] == null
      ? const PlayerProgression()
      : PlayerProgression.fromJson(json['progression'] as Map<String, dynamic>),
  narrativeFactRuntimeState:
      readNarrativeFactRuntimeStateJson(json, 'narrativeFactRuntimeState') ==
          null
      ? const NarrativeFactRuntimeState.empty()
      : NarrativeFactRuntimeState.fromJson(
          readNarrativeFactRuntimeStateJson(json, 'narrativeFactRuntimeState')
              as Map<String, dynamic>,
        ),
  narrativeEventProgress:
      readNarrativeEventProgressJson(json, 'narrativeEventProgress') == null
      ? const NarrativeEventProgress.empty()
      : NarrativeEventProgress.fromJson(
          readNarrativeEventProgressJson(json, 'narrativeEventProgress'),
        ),
  pauseMenuState: json['pauseMenuState'] == null
      ? const PlayerPauseMenuState.empty()
      : PlayerPauseMenuState.fromJson(
          json['pauseMenuState'] as Map<String, dynamic>,
        ),
  completedBattleRequestIds:
      (json['completedBattleRequestIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toSet() ??
      const {},
  appliedPokemonGrantOperationIds:
      (json['appliedPokemonGrantOperationIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toSet() ??
      const {},
  properties:
      (json['properties'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const {},
);

Map<String, dynamic> _$SaveDataToJson(_SaveData instance) => <String, dynamic>{
  'saveId': instance.saveId,
  'itemSystemSchemaVersion': instance.itemSystemSchemaVersion,
  'currentMapId': instance.currentMapId,
  'playerPosition': instance.playerPosition.toJson(),
  'playerFacing': _$EntityFacingEnumMap[instance.playerFacing]!,
  'playerMovementMode': _$MovementModeEnumMap[instance.playerMovementMode]!,
  'party': instance.party.toJson(),
  'pokemonStorage': instance.pokemonStorage.toJson(),
  'trainerProfile': instance.trainerProfile.toJson(),
  'bag': instance.bag.toJson(),
  'progression': instance.progression.toJson(),
  'narrativeFactRuntimeState': instance.narrativeFactRuntimeState.toJson(),
  'narrativeEventProgress': narrativeEventProgressToJson(
    instance.narrativeEventProgress,
  ),
  'pauseMenuState': instance.pauseMenuState.toJson(),
  'completedBattleRequestIds': instance.completedBattleRequestIds.toList(),
  'appliedPokemonGrantOperationIds': instance.appliedPokemonGrantOperationIds
      .toList(),
  'properties': instance.properties,
};

const _$EntityFacingEnumMap = {
  EntityFacing.north: 'north',
  EntityFacing.south: 'south',
  EntityFacing.east: 'east',
  EntityFacing.west: 'west',
};

const _$MovementModeEnumMap = {
  MovementMode.walk: 'walk',
  MovementMode.surf: 'surf',
  MovementMode.fly: 'fly',
  MovementMode.cut: 'cut',
  MovementMode.strength: 'strength',
  MovementMode.rockSmash: 'rock_smash',
};
