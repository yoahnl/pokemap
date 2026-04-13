// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PokemonStatSpreadImpl _$$PokemonStatSpreadImplFromJson(
        Map<String, dynamic> json) =>
    _$PokemonStatSpreadImpl(
      hp: (json['hp'] as num?)?.toInt() ?? 0,
      attack: (json['attack'] as num?)?.toInt() ?? 0,
      defense: (json['defense'] as num?)?.toInt() ?? 0,
      specialAttack: (json['specialAttack'] as num?)?.toInt() ?? 0,
      specialDefense: (json['specialDefense'] as num?)?.toInt() ?? 0,
      speed: (json['speed'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$PokemonStatSpreadImplToJson(
        _$PokemonStatSpreadImpl instance) =>
    <String, dynamic>{
      'hp': instance.hp,
      'attack': instance.attack,
      'defense': instance.defense,
      'specialAttack': instance.specialAttack,
      'specialDefense': instance.specialDefense,
      'speed': instance.speed,
    };

_$PlayerPokemonImpl _$$PlayerPokemonImplFromJson(Map<String, dynamic> json) =>
    _$PlayerPokemonImpl(
      speciesId: json['speciesId'] as String,
      natureId: json['natureId'] as String,
      abilityId: json['abilityId'] as String,
      level: (json['level'] as num?)?.toInt() ?? 1,
      ivs: json['ivs'] == null
          ? const PokemonStatSpread()
          : PokemonStatSpread.fromJson(json['ivs'] as Map<String, dynamic>),
      evs: json['evs'] == null
          ? const PokemonStatSpread()
          : PokemonStatSpread.fromJson(json['evs'] as Map<String, dynamic>),
      knownMoveIds: (json['knownMoveIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      currentHp: (json['currentHp'] as num?)?.toInt() ?? 1,
      statusId: json['statusId'] as String? ?? '',
      isShiny: json['isShiny'] as bool? ?? false,
      heldItemId: json['heldItemId'] as String? ?? '',
    );

Map<String, dynamic> _$$PlayerPokemonImplToJson(_$PlayerPokemonImpl instance) =>
    <String, dynamic>{
      'speciesId': instance.speciesId,
      'natureId': instance.natureId,
      'abilityId': instance.abilityId,
      'level': instance.level,
      'ivs': instance.ivs.toJson(),
      'evs': instance.evs.toJson(),
      'knownMoveIds': instance.knownMoveIds,
      'currentHp': instance.currentHp,
      'statusId': instance.statusId,
      'isShiny': instance.isShiny,
      'heldItemId': instance.heldItemId,
    };

_$PlayerPartyImpl _$$PlayerPartyImplFromJson(Map<String, dynamic> json) =>
    _$PlayerPartyImpl(
      members: (json['members'] as List<dynamic>?)
              ?.map((e) => PlayerPokemon.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$PlayerPartyImplToJson(_$PlayerPartyImpl instance) =>
    <String, dynamic>{
      'members': instance.members.map((e) => e.toJson()).toList(),
    };

_$PlayerProgressionImpl _$$PlayerProgressionImplFromJson(
        Map<String, dynamic> json) =>
    _$PlayerProgressionImpl(
      unlockedFieldAbilities: (json['unlockedFieldAbilities'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$FieldAbilityEnumMap, e))
              .toList() ??
          const [],
      storyFlags: (json['storyFlags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      completedStepIds: (json['completedStepIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      completedCutsceneIds: (json['completedCutsceneIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      seenSpeciesIds: (json['seenSpeciesIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      caughtSpeciesIds: (json['caughtSpeciesIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$PlayerProgressionImplToJson(
        _$PlayerProgressionImpl instance) =>
    <String, dynamic>{
      'unlockedFieldAbilities': instance.unlockedFieldAbilities
          .map((e) => _$FieldAbilityEnumMap[e]!)
          .toList(),
      'storyFlags': instance.storyFlags,
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

_$TrainerProfileImpl _$$TrainerProfileImplFromJson(Map<String, dynamic> json) =>
    _$TrainerProfileImpl(
      name: json['name'] as String,
      badgeIds: (json['badgeIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      money: (json['money'] as num?)?.toInt() ?? 0,
      playtimeSeconds: (json['playtimeSeconds'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$TrainerProfileImplToJson(
        _$TrainerProfileImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'badgeIds': instance.badgeIds,
      'money': instance.money,
      'playtimeSeconds': instance.playtimeSeconds,
    };

_$BagEntryImpl _$$BagEntryImplFromJson(Map<String, dynamic> json) =>
    _$BagEntryImpl(
      itemId: json['itemId'] as String,
      categoryId: json['categoryId'] as String,
      quantity: (json['quantity'] as num).toInt(),
    );

Map<String, dynamic> _$$BagEntryImplToJson(_$BagEntryImpl instance) =>
    <String, dynamic>{
      'itemId': instance.itemId,
      'categoryId': instance.categoryId,
      'quantity': instance.quantity,
    };

_$BagImpl _$$BagImplFromJson(Map<String, dynamic> json) => _$BagImpl(
      entries: (json['entries'] as List<dynamic>?)
              ?.map((e) => BagEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$BagImplToJson(_$BagImpl instance) => <String, dynamic>{
      'entries': instance.entries.map((e) => e.toJson()).toList(),
    };

_$SaveDataImpl _$$SaveDataImplFromJson(Map<String, dynamic> json) =>
    _$SaveDataImpl(
      saveId: json['saveId'] as String,
      currentMapId: json['currentMapId'] as String? ?? '',
      playerPosition: json['playerPosition'] == null
          ? const GridPos(x: 0, y: 0)
          : GridPos.fromJson(json['playerPosition'] as Map<String, dynamic>),
      playerFacing:
          $enumDecodeNullable(_$EntityFacingEnumMap, json['playerFacing']) ??
              EntityFacing.south,
      party: json['party'] == null
          ? const PlayerParty()
          : PlayerParty.fromJson(json['party'] as Map<String, dynamic>),
      trainerProfile: json['trainerProfile'] == null
          ? const TrainerProfile(name: 'Player')
          : TrainerProfile.fromJson(
              json['trainerProfile'] as Map<String, dynamic>),
      bag: json['bag'] == null
          ? const Bag()
          : Bag.fromJson(json['bag'] as Map<String, dynamic>),
      progression: json['progression'] == null
          ? const PlayerProgression()
          : PlayerProgression.fromJson(
              json['progression'] as Map<String, dynamic>),
      properties: (json['properties'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$$SaveDataImplToJson(_$SaveDataImpl instance) =>
    <String, dynamic>{
      'saveId': instance.saveId,
      'currentMapId': instance.currentMapId,
      'playerPosition': instance.playerPosition.toJson(),
      'playerFacing': _$EntityFacingEnumMap[instance.playerFacing]!,
      'party': instance.party.toJson(),
      'trainerProfile': instance.trainerProfile.toJson(),
      'bag': instance.bag.toJson(),
      'progression': instance.progression.toJson(),
      'properties': instance.properties,
    };

const _$EntityFacingEnumMap = {
  EntityFacing.north: 'north',
  EntityFacing.south: 'south',
  EntityFacing.east: 'east',
  EntityFacing.west: 'west',
};
