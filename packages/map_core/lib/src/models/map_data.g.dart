// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MapData _$MapDataFromJson(Map<String, dynamic> json) => _MapData(
  id: json['id'] as String,
  name: json['name'] as String,
  size: GridSize.fromJson(json['size'] as Map<String, dynamic>),
  version:
      $enumDecodeNullable(_$ProjectVersionEnumMap, json['version']) ??
      ProjectVersion.v6,
  visualStack: json['visualStack'] == null
      ? null
      : MapVisualStackConfig.fromJson(
          json['visualStack'] as Map<String, dynamic>,
        ),
  tilesetId: json['tilesetId'] as String? ?? '',
  layers:
      (json['layers'] as List<dynamic>?)
          ?.map((e) => MapLayer.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  placedElements:
      (json['placedElements'] as List<dynamic>?)
          ?.map((e) => MapPlacedElement.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  entities:
      (json['entities'] as List<dynamic>?)
          ?.map((e) => MapEntity.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  connections:
      (json['connections'] as List<dynamic>?)
          ?.map((e) => MapConnection.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  warps:
      (json['warps'] as List<dynamic>?)
          ?.map((e) => MapWarp.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  triggers:
      (json['triggers'] as List<dynamic>?)
          ?.map((e) => MapTrigger.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  gameplayZones:
      (json['gameplayZones'] as List<dynamic>?)
          ?.map((e) => MapGameplayZone.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  mapMetadata: json['mapMetadata'] == null
      ? const MapMetadata()
      : MapMetadata.fromJson(json['mapMetadata'] as Map<String, dynamic>),
  properties: json['properties'] as Map<String, dynamic>? ?? const {},
  events:
      (json['events'] as List<dynamic>?)
          ?.map((e) => MapEventDefinition.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$MapDataToJson(_MapData instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'size': instance.size.toJson(),
  'version': _$ProjectVersionEnumMap[instance.version]!,
  'visualStack': ?instance.visualStack?.toJson(),
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
  'events': instance.events.map((e) => e.toJson()).toList(),
};

const _$ProjectVersionEnumMap = {
  ProjectVersion.v1: 'v1',
  ProjectVersion.v2: 'v2',
  ProjectVersion.v3: 'v3',
  ProjectVersion.v4: 'v4',
  ProjectVersion.v5: 'v5',
  ProjectVersion.v6: 'v6',
  ProjectVersion.v7: 'v7',
};

_MapGameplayZone _$MapGameplayZoneFromJson(
  Map<String, dynamic> json,
) => _MapGameplayZone(
  id: json['id'] as String,
  name: json['name'] as String? ?? '',
  kind: $enumDecode(_$GameplayZoneKindEnumMap, json['kind']),
  area: MapRect.fromJson(json['area'] as Map<String, dynamic>),
  priority: (json['priority'] as num?)?.toInt() ?? 0,
  encounter: json['encounter'] == null
      ? null
      : EncounterZonePayload.fromJson(
          json['encounter'] as Map<String, dynamic>,
        ),
  movement: json['movement'] == null
      ? null
      : MovementZonePayload.fromJson(json['movement'] as Map<String, dynamic>),
  movementEffect: json['movementEffect'] == null
      ? null
      : MovementEffectZonePayload.fromJson(
          json['movementEffect'] as Map<String, dynamic>,
        ),
  hazard: json['hazard'] == null
      ? null
      : HazardZonePayload.fromJson(json['hazard'] as Map<String, dynamic>),
  special: json['special'] == null
      ? null
      : SpecialZonePayload.fromJson(json['special'] as Map<String, dynamic>),
  smartTileProvenance: json['smartTileProvenance'] == null
      ? null
      : SmartTileGameplayZoneProvenance.fromJson(
          json['smartTileProvenance'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$MapGameplayZoneToJson(_MapGameplayZone instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'kind': _$GameplayZoneKindEnumMap[instance.kind]!,
      'area': instance.area.toJson(),
      'priority': instance.priority,
      'encounter': instance.encounter?.toJson(),
      'movement': instance.movement?.toJson(),
      'movementEffect': instance.movementEffect?.toJson(),
      'hazard': instance.hazard?.toJson(),
      'special': instance.special?.toJson(),
      'smartTileProvenance': ?instance.smartTileProvenance?.toJson(),
    };

const _$GameplayZoneKindEnumMap = {
  GameplayZoneKind.encounter: 'encounter',
  GameplayZoneKind.movement: 'movement',
  GameplayZoneKind.movementEffect: 'movementEffect',
  GameplayZoneKind.hazard: 'hazard',
  GameplayZoneKind.special: 'special',
  GameplayZoneKind.custom: 'custom',
};

_MapPlacedElement _$MapPlacedElementFromJson(Map<String, dynamic> json) =>
    _MapPlacedElement(
      id: json['id'] as String,
      layerId: json['layerId'] as String,
      elementId: json['elementId'] as String,
      pos: GridPos.fromJson(json['pos'] as Map<String, dynamic>),
      quarterTurns: json['quarterTurns'] == null
          ? 0
          : _mapPlacedElementQuarterTurnsFromJson(json['quarterTurns']),
      applyCollision: json['applyCollision'] as bool? ?? true,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      animation: json['animation'] == null
          ? null
          : MapPlacedElementAnimation.fromJson(
              json['animation'] as Map<String, dynamic>,
            ),
      shadowOverride: const MapPlacedElementShadowOverrideJsonConverter()
          .fromJson(json['shadowOverride']),
      behaviors:
          (json['behaviors'] as List<dynamic>?)
              ?.map(
                (e) => MapPlacedElementBehavior.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
      properties:
          (json['properties'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const {},
    );

Map<String, dynamic> _$MapPlacedElementToJson(_MapPlacedElement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'layerId': instance.layerId,
      'elementId': instance.elementId,
      'pos': instance.pos.toJson(),
      'quarterTurns': instance.quarterTurns,
      'applyCollision': instance.applyCollision,
      'opacity': instance.opacity,
      'animation': instance.animation?.toJson(),
      'shadowOverride': const MapPlacedElementShadowOverrideJsonConverter()
          .toJson(instance.shadowOverride),
      'behaviors': instance.behaviors.map((e) => e.toJson()).toList(),
      'properties': instance.properties,
    };

_MapPlacedElementBehavior _$MapPlacedElementBehaviorFromJson(
  Map<String, dynamic> json,
) => _MapPlacedElementBehavior(
  id: json['id'] as String? ?? '',
  enabled: json['enabled'] as bool? ?? true,
  triggerScope:
      $enumDecodeNullable(
        _$MapPlacedElementTriggerScopeEnumMap,
        json['triggerScope'],
      ) ??
      MapPlacedElementTriggerScope.defaultScope,
  cooldownMs: (json['cooldownMs'] as num?)?.toInt(),
  trigger:
      $enumDecodeNullable(
        _$MapPlacedElementTriggerTypeEnumMap,
        json['trigger'],
      ) ??
      MapPlacedElementTriggerType.onAction,
  effect: MapPlacedElementEffect.fromJson(
    json['effect'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$MapPlacedElementBehaviorToJson(
  _MapPlacedElementBehavior instance,
) => <String, dynamic>{
  'id': instance.id,
  'enabled': instance.enabled,
  'triggerScope': _$MapPlacedElementTriggerScopeEnumMap[instance.triggerScope]!,
  'cooldownMs': instance.cooldownMs,
  'trigger': _$MapPlacedElementTriggerTypeEnumMap[instance.trigger]!,
  'effect': instance.effect.toJson(),
};

const _$MapPlacedElementTriggerScopeEnumMap = {
  MapPlacedElementTriggerScope.defaultScope: 'default',
  MapPlacedElementTriggerScope.oncePerEnter: 'once_per_enter',
  MapPlacedElementTriggerScope.whileInsideSingleShot:
      'while_inside_single_shot',
  MapPlacedElementTriggerScope.facingOnly: 'facing_only',
  MapPlacedElementTriggerScope.nearCardinalOnly: 'near_cardinal_only',
};

const _$MapPlacedElementTriggerTypeEnumMap = {
  MapPlacedElementTriggerType.onAction: 'on_action',
  MapPlacedElementTriggerType.onEnter: 'on_enter',
  MapPlacedElementTriggerType.onBump: 'on_bump',
  MapPlacedElementTriggerType.onExit: 'on_exit',
  MapPlacedElementTriggerType.onNear: 'on_near',
};

_MapPlacedElementEffect _$MapPlacedElementEffectFromJson(
  Map<String, dynamic> json,
) => _MapPlacedElementEffect(
  type: $enumDecode(_$MapPlacedElementEffectTypeEnumMap, json['type']),
  message: json['message'] as String?,
  dialogue: json['dialogue'] == null
      ? null
      : DialogueRef.fromJson(json['dialogue'] as Map<String, dynamic>),
  animationEnabled: json['animationEnabled'] as bool?,
  targetMapId: json['targetMapId'] as String?,
  targetPos: json['targetPos'] == null
      ? null
      : GridPos.fromJson(json['targetPos'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MapPlacedElementEffectToJson(
  _MapPlacedElementEffect instance,
) => <String, dynamic>{
  'type': _$MapPlacedElementEffectTypeEnumMap[instance.type]!,
  'message': instance.message,
  'dialogue': instance.dialogue?.toJson(),
  'animationEnabled': instance.animationEnabled,
  'targetMapId': instance.targetMapId,
  'targetPos': instance.targetPos?.toJson(),
};

const _$MapPlacedElementEffectTypeEnumMap = {
  MapPlacedElementEffectType.showMessage: 'show_message',
  MapPlacedElementEffectType.openDialogue: 'open_dialogue',
  MapPlacedElementEffectType.setAnimationEnabled: 'set_animation_enabled',
  MapPlacedElementEffectType.playAnimationOnce: 'play_animation_once',
  MapPlacedElementEffectType.traverseWarp: 'traverse_warp',
};

_MapPlacedElementAnimation _$MapPlacedElementAnimationFromJson(
  Map<String, dynamic> json,
) => _MapPlacedElementAnimation(
  enabled: json['enabled'] as bool? ?? false,
  mode:
      $enumDecodeNullable(
        _$MapPlacedElementAnimationModeEnumMap,
        json['mode'],
      ) ??
      MapPlacedElementAnimationMode.none,
  autoplay: json['autoplay'] as bool? ?? true,
  speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
  startOffsetMs: (json['startOffsetMs'] as num?)?.toDouble(),
  randomStart: json['randomStart'] as bool? ?? false,
);

Map<String, dynamic> _$MapPlacedElementAnimationToJson(
  _MapPlacedElementAnimation instance,
) => <String, dynamic>{
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

_MapEntity _$MapEntityFromJson(Map<String, dynamic> json) => _MapEntity(
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
          json['editorVisual'] as Map<String, dynamic>,
        ),
  blocksMovement: json['blocksMovement'] as bool? ?? true,
  properties:
      (json['properties'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const {},
);

Map<String, dynamic> _$MapEntityToJson(_MapEntity instance) =>
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

_MapWarp _$MapWarpFromJson(Map<String, dynamic> json) => _MapWarp(
  id: json['id'] as String,
  pos: GridPos.fromJson(json['pos'] as Map<String, dynamic>),
  targetMapId: json['targetMapId'] as String,
  targetPos: GridPos.fromJson(json['targetPos'] as Map<String, dynamic>),
  triggerMode:
      $enumDecodeNullable(_$MapWarpTriggerModeEnumMap, json['triggerMode']) ??
      MapWarpTriggerMode.onEnter,
  allowedApproachFacings:
      (json['allowedApproachFacings'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$EntityFacingEnumMap, e))
          .toList() ??
      const [],
  triggerPadding: json['triggerPadding'] == null
      ? const WarpTriggerPadding()
      : WarpTriggerPadding.fromJson(
          json['triggerPadding'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$MapWarpToJson(_MapWarp instance) => <String, dynamic>{
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

_WarpTriggerPadding _$WarpTriggerPaddingFromJson(Map<String, dynamic> json) =>
    _WarpTriggerPadding(
      top: (json['top'] as num?)?.toInt() ?? 0,
      right: (json['right'] as num?)?.toInt() ?? 0,
      bottom: (json['bottom'] as num?)?.toInt() ?? 0,
      left: (json['left'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$WarpTriggerPaddingToJson(_WarpTriggerPadding instance) =>
    <String, dynamic>{
      'top': instance.top,
      'right': instance.right,
      'bottom': instance.bottom,
      'left': instance.left,
    };

_MapConnection _$MapConnectionFromJson(Map<String, dynamic> json) =>
    _MapConnection(
      direction: $enumDecode(
        _$MapConnectionDirectionEnumMap,
        json['direction'],
      ),
      targetMapId: json['targetMapId'] as String,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$MapConnectionToJson(_MapConnection instance) =>
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

_MapTrigger _$MapTriggerFromJson(Map<String, dynamic> json) => _MapTrigger(
  id: json['id'] as String,
  name: json['name'] as String? ?? '',
  type: $enumDecode(_$TriggerTypeEnumMap, json['type']),
  area: MapRect.fromJson(json['area'] as Map<String, dynamic>),
  properties:
      (json['properties'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const {},
);

Map<String, dynamic> _$MapTriggerToJson(_MapTrigger instance) =>
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
