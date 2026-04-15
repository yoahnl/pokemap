// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pokemon_move.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PokemonMoveSourceRefsImpl _$$PokemonMoveSourceRefsImplFromJson(
        Map<String, dynamic> json) =>
    _$PokemonMoveSourceRefsImpl(
      showdownMoveId: json['showdownMoveId'] as String?,
      showdownHooksPresent: (json['showdownHooksPresent'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$$PokemonMoveSourceRefsImplToJson(
        _$PokemonMoveSourceRefsImpl instance) =>
    <String, dynamic>{
      'showdownMoveId': instance.showdownMoveId,
      'showdownHooksPresent': instance.showdownHooksPresent,
    };

_$PokemonMoveImpl _$$PokemonMoveImplFromJson(Map<String, dynamic> json) =>
    _$PokemonMoveImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      names: (json['names'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const <String, String>{},
      generation: (json['generation'] as num?)?.toInt(),
      source: json['source'] as String? ?? '',
      type: json['type'] as String,
      category: $enumDecode(_$PokemonMoveCategoryEnumMap, json['category']),
      target: $enumDecodeNullable(_$PokemonMoveTargetEnumMap, json['target']) ??
          PokemonMoveTarget.normal,
      basePower: (json['basePower'] as num?)?.toInt() ?? 0,
      accuracy: PokemonMoveAccuracy.fromJson(
          json['accuracy'] as Map<String, dynamic>),
      pp: (json['pp'] as num?)?.toInt() ?? 0,
      noPpBoosts: json['noPpBoosts'] as bool? ?? false,
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      critRatio: (json['critRatio'] as num?)?.toInt() ?? 1,
      flags: (json['flags'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$PokemonMoveFlagEnumMap, e))
              .toList() ??
          const <PokemonMoveFlag>[],
      effects: (json['effects'] as List<dynamic>?)
              ?.map(
                  (e) => PokemonMoveEffect.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <PokemonMoveEffect>[],
      shortDescription: json['shortDescription'] as String? ?? '',
      description: json['description'] as String? ?? '',
      engineSupportLevel: $enumDecodeNullable(
              _$PokemonMoveEngineSupportLevelEnumMap,
              json['engineSupportLevel']) ??
          PokemonMoveEngineSupportLevel.catalogOnly,
      unsupportedReasons: (json['unsupportedReasons'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      sourceRefs: json['sourceRefs'] == null
          ? const PokemonMoveSourceRefs()
          : PokemonMoveSourceRefs.fromJson(
              json['sourceRefs'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$PokemonMoveImplToJson(_$PokemonMoveImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'names': instance.names,
      'generation': instance.generation,
      'source': instance.source,
      'type': instance.type,
      'category': _$PokemonMoveCategoryEnumMap[instance.category]!,
      'target': _$PokemonMoveTargetEnumMap[instance.target]!,
      'basePower': instance.basePower,
      'accuracy': instance.accuracy.toJson(),
      'pp': instance.pp,
      'noPpBoosts': instance.noPpBoosts,
      'priority': instance.priority,
      'critRatio': instance.critRatio,
      'flags': instance.flags.map((e) => _$PokemonMoveFlagEnumMap[e]!).toList(),
      'effects': instance.effects.map((e) => e.toJson()).toList(),
      'shortDescription': instance.shortDescription,
      'description': instance.description,
      'engineSupportLevel':
          _$PokemonMoveEngineSupportLevelEnumMap[instance.engineSupportLevel]!,
      'unsupportedReasons': instance.unsupportedReasons,
      'sourceRefs': instance.sourceRefs.toJson(),
    };

const _$PokemonMoveCategoryEnumMap = {
  PokemonMoveCategory.physical: 'physical',
  PokemonMoveCategory.special: 'special',
  PokemonMoveCategory.status: 'status',
};

const _$PokemonMoveTargetEnumMap = {
  PokemonMoveTarget.adjacentAlly: 'adjacentAlly',
  PokemonMoveTarget.adjacentAllyOrSelf: 'adjacentAllyOrSelf',
  PokemonMoveTarget.adjacentFoe: 'adjacentFoe',
  PokemonMoveTarget.all: 'all',
  PokemonMoveTarget.allAdjacent: 'allAdjacent',
  PokemonMoveTarget.allAdjacentFoes: 'allAdjacentFoes',
  PokemonMoveTarget.allies: 'allies',
  PokemonMoveTarget.allySide: 'allySide',
  PokemonMoveTarget.allyTeam: 'allyTeam',
  PokemonMoveTarget.any: 'any',
  PokemonMoveTarget.foeSide: 'foeSide',
  PokemonMoveTarget.normal: 'normal',
  PokemonMoveTarget.randomNormal: 'randomNormal',
  PokemonMoveTarget.scripted: 'scripted',
  PokemonMoveTarget.self: 'self',
};

const _$PokemonMoveFlagEnumMap = {
  PokemonMoveFlag.allyAnim: 'allyanim',
  PokemonMoveFlag.bypassSubstitute: 'bypasssub',
  PokemonMoveFlag.bite: 'bite',
  PokemonMoveFlag.bullet: 'bullet',
  PokemonMoveFlag.cantUseTwice: 'cantusetwice',
  PokemonMoveFlag.charge: 'charge',
  PokemonMoveFlag.contact: 'contact',
  PokemonMoveFlag.dance: 'dance',
  PokemonMoveFlag.defrost: 'defrost',
  PokemonMoveFlag.distance: 'distance',
  PokemonMoveFlag.failCopycat: 'failcopycat',
  PokemonMoveFlag.failEncore: 'failencore',
  PokemonMoveFlag.failInstruct: 'failinstruct',
  PokemonMoveFlag.failMeFirst: 'failmefirst',
  PokemonMoveFlag.failMimic: 'failmimic',
  PokemonMoveFlag.futureMove: 'futuremove',
  PokemonMoveFlag.gravity: 'gravity',
  PokemonMoveFlag.heal: 'heal',
  PokemonMoveFlag.metronome: 'metronome',
  PokemonMoveFlag.minimize: 'minimize',
  PokemonMoveFlag.mirror: 'mirror',
  PokemonMoveFlag.mustPressure: 'mustpressure',
  PokemonMoveFlag.noAssist: 'noassist',
  PokemonMoveFlag.nonSky: 'nonsky',
  PokemonMoveFlag.noParentalBond: 'noparentalbond',
  PokemonMoveFlag.noSketch: 'nosketch',
  PokemonMoveFlag.noSleepTalk: 'nosleeptalk',
  PokemonMoveFlag.pledgeCombo: 'pledgecombo',
  PokemonMoveFlag.powder: 'powder',
  PokemonMoveFlag.protect: 'protect',
  PokemonMoveFlag.pulse: 'pulse',
  PokemonMoveFlag.punch: 'punch',
  PokemonMoveFlag.recharge: 'recharge',
  PokemonMoveFlag.reflectable: 'reflectable',
  PokemonMoveFlag.slicing: 'slicing',
  PokemonMoveFlag.snatch: 'snatch',
  PokemonMoveFlag.sound: 'sound',
  PokemonMoveFlag.wind: 'wind',
};

const _$PokemonMoveEngineSupportLevelEnumMap = {
  PokemonMoveEngineSupportLevel.catalogOnly: 'catalog_only',
  PokemonMoveEngineSupportLevel.structuredPartial: 'structured_partial',
  PokemonMoveEngineSupportLevel.structuredSupported: 'structured_supported',
};
