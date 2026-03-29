// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MapDataImpl _$$MapDataImplFromJson(Map<String, dynamic> json) =>
    _$MapDataImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      size: GridSize.fromJson(json['size'] as Map<String, dynamic>),
      version: $enumDecodeNullable(_$ProjectVersionEnumMap, json['version']) ??
          ProjectVersion.v1,
      tilesetId: json['tilesetId'] as String? ?? '',
      layers: (json['layers'] as List<dynamic>?)
              ?.map((e) => MapLayer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      placedElements: (json['placedElements'] as List<dynamic>?)
              ?.map((e) => MapPlacedElement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      entities: (json['entities'] as List<dynamic>?)
              ?.map((e) => MapEntity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      connections: (json['connections'] as List<dynamic>?)
              ?.map((e) => MapConnection.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      warps: (json['warps'] as List<dynamic>?)
              ?.map((e) => MapWarp.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      triggers: (json['triggers'] as List<dynamic>?)
              ?.map((e) => MapTrigger.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      gameplayZones: (json['gameplayZones'] as List<dynamic>?)
              ?.map((e) => MapGameplayZone.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      mapMetadata: json['mapMetadata'] == null
          ? const MapMetadata()
          : MapMetadata.fromJson(json['mapMetadata'] as Map<String, dynamic>),
      properties: json['properties'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$$MapDataImplToJson(_$MapDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'size': instance.size.toJson(),
      'version': _$ProjectVersionEnumMap[instance.version]!,
      'tilesetId': instance.tilesetId,
      'layers': instance.layers.map((e) => e.toJson()).toList(),
      'placedElements': instance.placedElements.map((e) => e.toJson()).toList(),
      'entities': instance.entities.map((e) => e.toJson()).toList(),
      'connections': instance.connections.map((e) => e.toJson()).toList(),
      'warps': instance.warps.map((e) => e.toJson()).toList(),
      'triggers': instance.triggers.map((e) => e.toJson()).toList(),
      'gameplayZones': instance.gameplayZones.map((e) => e.toJson()).toList(),
      'mapMetadata': instance.mapMetadata.toJson(),
      'properties': instance.properties,
    };

const _$ProjectVersionEnumMap = {
  ProjectVersion.v1: 'v1',
};

_$MapGameplayZoneImpl _$$MapGameplayZoneImplFromJson(
        Map<String, dynamic> json) =>
    _$MapGameplayZoneImpl(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      kind: $enumDecode(_$GameplayZoneKindEnumMap, json['kind']),
      area: MapRect.fromJson(json['area'] as Map<String, dynamic>),
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      encounter: json['encounter'] == null
          ? null
          : EncounterZonePayload.fromJson(
              json['encounter'] as Map<String, dynamic>),
      movement: json['movement'] == null
          ? null
          : MovementZonePayload.fromJson(
              json['movement'] as Map<String, dynamic>),
      hazard: json['hazard'] == null
          ? null
          : HazardZonePayload.fromJson(json['hazard'] as Map<String, dynamic>),
      special: json['special'] == null
          ? null
          : SpecialZonePayload.fromJson(
              json['special'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$MapGameplayZoneImplToJson(
        _$MapGameplayZoneImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'kind': _$GameplayZoneKindEnumMap[instance.kind]!,
      'area': instance.area.toJson(),
      'priority': instance.priority,
      'encounter': instance.encounter?.toJson(),
      'movement': instance.movement?.toJson(),
      'hazard': instance.hazard?.toJson(),
      'special': instance.special?.toJson(),
    };

const _$GameplayZoneKindEnumMap = {
  GameplayZoneKind.encounter: 'encounter',
  GameplayZoneKind.movement: 'movement',
  GameplayZoneKind.hazard: 'hazard',
  GameplayZoneKind.special: 'special',
  GameplayZoneKind.custom: 'custom',
};

_$MapPlacedElementImpl _$$MapPlacedElementImplFromJson(
        Map<String, dynamic> json) =>
    _$MapPlacedElementImpl(
      id: json['id'] as String,
      layerId: json['layerId'] as String,
      elementId: json['elementId'] as String,
      pos: GridPos.fromJson(json['pos'] as Map<String, dynamic>),
      applyCollision: json['applyCollision'] as bool? ?? true,
      animation: json['animation'] == null
          ? null
          : MapPlacedElementAnimation.fromJson(
              json['animation'] as Map<String, dynamic>),
      behaviors: (json['behaviors'] as List<dynamic>?)
              ?.map((e) =>
                  MapPlacedElementBehavior.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      properties: (json['properties'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$$MapPlacedElementImplToJson(
        _$MapPlacedElementImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'layerId': instance.layerId,
      'elementId': instance.elementId,
      'pos': instance.pos.toJson(),
      'applyCollision': instance.applyCollision,
      'animation': instance.animation?.toJson(),
      'behaviors': instance.behaviors.map((e) => e.toJson()).toList(),
      'properties': instance.properties,
    };

_$MapPlacedElementBehaviorImpl _$$MapPlacedElementBehaviorImplFromJson(
        Map<String, dynamic> json) =>
    _$MapPlacedElementBehaviorImpl(
      enabled: json['enabled'] as bool? ?? true,
      trigger: $enumDecodeNullable(
              _$MapPlacedElementTriggerTypeEnumMap, json['trigger']) ??
          MapPlacedElementTriggerType.onAction,
      effect: MapPlacedElementEffect.fromJson(
          json['effect'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$MapPlacedElementBehaviorImplToJson(
        _$MapPlacedElementBehaviorImpl instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'trigger': _$MapPlacedElementTriggerTypeEnumMap[instance.trigger]!,
      'effect': instance.effect.toJson(),
    };

const _$MapPlacedElementTriggerTypeEnumMap = {
  MapPlacedElementTriggerType.onAction: 'on_action',
  MapPlacedElementTriggerType.onEnter: 'on_enter',
  MapPlacedElementTriggerType.onBump: 'on_bump',
  MapPlacedElementTriggerType.onExit: 'on_exit',
  MapPlacedElementTriggerType.onNear: 'on_near',
};

_$MapPlacedElementEffectImpl _$$MapPlacedElementEffectImplFromJson(
        Map<String, dynamic> json) =>
    _$MapPlacedElementEffectImpl(
      type: $enumDecode(_$MapPlacedElementEffectTypeEnumMap, json['type']),
      message: json['message'] as String?,
      dialogue: json['dialogue'] == null
          ? null
          : DialogueRef.fromJson(json['dialogue'] as Map<String, dynamic>),
      animationEnabled: json['animationEnabled'] as bool?,
    );

Map<String, dynamic> _$$MapPlacedElementEffectImplToJson(
        _$MapPlacedElementEffectImpl instance) =>
    <String, dynamic>{
      'type': _$MapPlacedElementEffectTypeEnumMap[instance.type]!,
      'message': instance.message,
      'dialogue': instance.dialogue?.toJson(),
      'animationEnabled': instance.animationEnabled,
    };

const _$MapPlacedElementEffectTypeEnumMap = {
  MapPlacedElementEffectType.showMessage: 'show_message',
  MapPlacedElementEffectType.openDialogue: 'open_dialogue',
  MapPlacedElementEffectType.setAnimationEnabled: 'set_animation_enabled',
  MapPlacedElementEffectType.playAnimationOnce: 'play_animation_once',
};

_$MapPlacedElementAnimationImpl _$$MapPlacedElementAnimationImplFromJson(
        Map<String, dynamic> json) =>
    _$MapPlacedElementAnimationImpl(
      enabled: json['enabled'] as bool? ?? false,
      mode: $enumDecodeNullable(
              _$MapPlacedElementAnimationModeEnumMap, json['mode']) ??
          MapPlacedElementAnimationMode.none,
      autoplay: json['autoplay'] as bool? ?? true,
      speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
      startOffsetMs: (json['startOffsetMs'] as num?)?.toDouble(),
      randomStart: json['randomStart'] as bool? ?? false,
    );

Map<String, dynamic> _$$MapPlacedElementAnimationImplToJson(
        _$MapPlacedElementAnimationImpl instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'mode': _$MapPlacedElementAnimationModeEnumMap[instance.mode]!,
      'autoplay': instance.autoplay,
      'speed': instance.speed,
      'startOffsetMs': instance.startOffsetMs,
      'randomStart': instance.randomStart,
    };

const _$MapPlacedElementAnimationModeEnumMap = {
  MapPlacedElementAnimationMode.none: 'none',
  MapPlacedElementAnimationMode.loop: 'loop',
  MapPlacedElementAnimationMode.pingPong: 'ping_pong',
};

_$MapEntityImpl _$$MapEntityImplFromJson(Map<String, dynamic> json) =>
    _$MapEntityImpl(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      kind: $enumDecode(_$MapEntityKindEnumMap, json['kind']),
      pos: GridPos.fromJson(json['pos'] as Map<String, dynamic>),
      size: json['size'] == null
          ? const GridSize(width: 1, height: 1)
          : GridSize.fromJson(json['size'] as Map<String, dynamic>),
      npc: json['npc'] == null
          ? null
          : MapEntityNpcData.fromJson(json['npc'] as Map<String, dynamic>),
      sign: json['sign'] == null
          ? null
          : MapEntitySignData.fromJson(json['sign'] as Map<String, dynamic>),
      item: json['item'] == null
          ? null
          : MapEntityItemData.fromJson(json['item'] as Map<String, dynamic>),
      spawn: json['spawn'] == null
          ? null
          : MapEntitySpawnData.fromJson(json['spawn'] as Map<String, dynamic>),
      editorVisual: json['editorVisual'] == null
          ? null
          : MapEntityEditorVisual.fromJson(
              json['editorVisual'] as Map<String, dynamic>),
      blocksMovement: json['blocksMovement'] as bool? ?? true,
      properties: (json['properties'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$$MapEntityImplToJson(_$MapEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'kind': _$MapEntityKindEnumMap[instance.kind]!,
      'pos': instance.pos.toJson(),
      'size': instance.size.toJson(),
      'npc': instance.npc?.toJson(),
      'sign': instance.sign?.toJson(),
      'item': instance.item?.toJson(),
      'spawn': instance.spawn?.toJson(),
      'editorVisual': instance.editorVisual?.toJson(),
      'blocksMovement': instance.blocksMovement,
      'properties': instance.properties,
    };

const _$MapEntityKindEnumMap = {
  MapEntityKind.npc: 'npc',
  MapEntityKind.sign: 'sign',
  MapEntityKind.item: 'item',
  MapEntityKind.spawn: 'spawn',
  MapEntityKind.custom: 'custom',
};

_$MapWarpImpl _$$MapWarpImplFromJson(Map<String, dynamic> json) =>
    _$MapWarpImpl(
      id: json['id'] as String,
      pos: GridPos.fromJson(json['pos'] as Map<String, dynamic>),
      targetMapId: json['targetMapId'] as String,
      targetPos: GridPos.fromJson(json['targetPos'] as Map<String, dynamic>),
      triggerMode: $enumDecodeNullable(
              _$MapWarpTriggerModeEnumMap, json['triggerMode']) ??
          MapWarpTriggerMode.onEnter,
      allowedApproachFacings: (json['allowedApproachFacings'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$EntityFacingEnumMap, e))
              .toList() ??
          const [],
      triggerPadding: json['triggerPadding'] == null
          ? const WarpTriggerPadding()
          : WarpTriggerPadding.fromJson(
              json['triggerPadding'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$MapWarpImplToJson(_$MapWarpImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pos': instance.pos.toJson(),
      'targetMapId': instance.targetMapId,
      'targetPos': instance.targetPos.toJson(),
      'triggerMode': _$MapWarpTriggerModeEnumMap[instance.triggerMode]!,
      'allowedApproachFacings': instance.allowedApproachFacings
          .map((e) => _$EntityFacingEnumMap[e]!)
          .toList(),
      'triggerPadding': instance.triggerPadding.toJson(),
    };

const _$MapWarpTriggerModeEnumMap = {
  MapWarpTriggerMode.onEnter: 'on_enter',
  MapWarpTriggerMode.onBump: 'on_bump',
};

const _$EntityFacingEnumMap = {
  EntityFacing.north: 'north',
  EntityFacing.south: 'south',
  EntityFacing.east: 'east',
  EntityFacing.west: 'west',
};

_$WarpTriggerPaddingImpl _$$WarpTriggerPaddingImplFromJson(
        Map<String, dynamic> json) =>
    _$WarpTriggerPaddingImpl(
      top: (json['top'] as num?)?.toInt() ?? 0,
      right: (json['right'] as num?)?.toInt() ?? 0,
      bottom: (json['bottom'] as num?)?.toInt() ?? 0,
      left: (json['left'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$WarpTriggerPaddingImplToJson(
        _$WarpTriggerPaddingImpl instance) =>
    <String, dynamic>{
      'top': instance.top,
      'right': instance.right,
      'bottom': instance.bottom,
      'left': instance.left,
    };

_$MapConnectionImpl _$$MapConnectionImplFromJson(Map<String, dynamic> json) =>
    _$MapConnectionImpl(
      direction:
          $enumDecode(_$MapConnectionDirectionEnumMap, json['direction']),
      targetMapId: json['targetMapId'] as String,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$MapConnectionImplToJson(_$MapConnectionImpl instance) =>
    <String, dynamic>{
      'direction': _$MapConnectionDirectionEnumMap[instance.direction]!,
      'targetMapId': instance.targetMapId,
      'offset': instance.offset,
    };

const _$MapConnectionDirectionEnumMap = {
  MapConnectionDirection.north: 'north',
  MapConnectionDirection.south: 'south',
  MapConnectionDirection.east: 'east',
  MapConnectionDirection.west: 'west',
};

_$MapTriggerImpl _$$MapTriggerImplFromJson(Map<String, dynamic> json) =>
    _$MapTriggerImpl(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      type: $enumDecode(_$TriggerTypeEnumMap, json['type']),
      area: MapRect.fromJson(json['area'] as Map<String, dynamic>),
      properties: (json['properties'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$$MapTriggerImplToJson(_$MapTriggerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$TriggerTypeEnumMap[instance.type]!,
      'area': instance.area.toJson(),
      'properties': instance.properties,
    };

const _$TriggerTypeEnumMap = {
  TriggerType.warp: 'warp',
  TriggerType.message: 'message',
  TriggerType.interaction: 'interaction',
  TriggerType.event: 'event',
  TriggerType.spawn: 'spawn',
  TriggerType.camera: 'camera',
  TriggerType.custom: 'custom',
};
