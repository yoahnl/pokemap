// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'geometry.dart';
import 'map_entity_editor_visual.dart';
import 'map_entity_payloads.dart';
import 'map_entity_field_obstacle.dart';
import 'map_entity_interactive_encounter.dart';
import 'map_entity_healing_display.dart';
import 'map_entity_presentation.dart';
import 'map_event_definition.dart';
import 'map_gameplay_zone_payloads.dart';
import 'map_layer.dart';
import 'map_metadata.dart';
import 'moving_platform.dart';
import 'moving_prop.dart';
import 'map_visual_stack_config.dart';
import 'map_spatial_scene.dart';
import 'smart_tile_gameplay_zone_provenance.dart';
import 'smart_tile.dart';
import 'narrative_map_view.dart';

import '../compatibility/environment_single_area_migration.dart';

part 'map_data.freezed.dart';
part 'map_data.g.dart';

@Freezed(fromJson: true, toJson: true)
abstract class MapData with _$MapData implements NarrativeMapView {
  @JsonSerializable(explicitToJson: true)
  const factory MapData({
    required String id,
    required String name,
    required GridSize size,
    @Default(ProjectVersion.v8) ProjectVersion version,
    @JsonKey(includeIfNull: false) MapSpatialScene? spatialScene,
    @JsonKey(includeIfNull: false) MapVisualStackConfig? visualStack,
    @Default('') String tilesetId,
    @Default([]) List<MapLayer> layers,
    @Default([]) List<MapPlacedElement> placedElements,
    @Default([]) List<MovingPlatformDefinition> movingPlatforms,
    @Default([]) List<MovingPropDefinition> movingProps,
    @Default([]) List<MapEntity> entities,
    @Default([]) List<MapConnection> connections,
    @Default([]) List<MapWarp> warps,
    @Default([]) List<MapTrigger> triggers,

    /// Zones gameplay (rencontres, déplacement, dangers, etc.).
    /// Séparées des triggers (logiques scriptées) et des layers visuelles.
    @Default([]) List<MapGameplayZone> gameplayZones,
    @Default(MapMetadata()) MapMetadata mapMetadata,
    @Default({}) Map<String, dynamic> properties,
    @Default([]) List<MapEventDefinition> events,
  }) = _MapData;

  factory MapData.fromJson(Map<String, dynamic> json) {
    if (json['version'] == 'v9') {
      _preflightSmartTileMapJson(json);
      final map = _$MapDataFromJson(json);
      validateSpatialMapStructure(map);
      return map;
    }
    if (json.containsKey('spatialScene')) {
      throw const FormatException('Spatial scenes require map version v9.');
    }
    _preflightSmartTileMapJson(json);
    final canonical = migrateEnvironmentSingleAreaMapJson(
      _migrateLegacyTileLayers(json),
    );
    if (canonical.containsKey('visualStack')) {
      final visualStack = canonical['visualStack'];
      if (visualStack is! Map<String, dynamic>) {
        throw const FormatException(r'$.visualStack: expected an object');
      }
    }
    final map = _$MapDataFromJson(canonical);
    if (map.visualStack != null && map.version != ProjectVersion.v8) {
      throw const FormatException(
        r'$.version: visualStack requires ProjectVersion.v8',
      );
    }
    if (map.version != ProjectVersion.v8) {
      final smartTileIndex = map.layers.indexWhere(
        (layer) => layer is SmartTileLayer,
      );
      if (smartTileIndex >= 0) {
        throw FormatException(
          r'$.layers['
          '$smartTileIndex].runtimeType: Smart Tile layers require '
          'ProjectVersion.v8',
        );
      }
    }
    return map;
  }
}

void validateSpatialMapStructure(MapData map) {
  final scene = map.spatialScene;
  if (map.version != ProjectVersion.v9 ||
      scene == null ||
      scene.width != map.size.width ||
      scene.depth != map.size.height ||
      map.layers.any(
        (layer) => switch (layer) {
          CollisionLayer() =>
            layer.collisions.length != map.size.width * map.size.height,
          SmartTileLayer() =>
            layer.usage != SmartTileUsage.terrain &&
                layer.usage != SmartTileUsage.path,
          EnvironmentLayer() =>
            layer.content.targetTileLayerId != null ||
                (!layer.content.targetsSpatialTerrain &&
                    layer.content.areas.isNotEmpty),
          BorderLayer() => layer.content.features.any(
            (feature) =>
                feature.materialization != null &&
                !feature.materialization!.targetsSpatialScene,
          ),
          _ => true,
        },
      ) ||
      map.placedElements.isNotEmpty ||
      map.tilesetId.isNotEmpty ||
      map.visualStack != null) {
    throw const FormatException(
      'A v9 map requires a 3D scene, spatial Environment layers, Smart Tile ground/path surfaces and collision layers.',
    );
  }
  validateSpatialEntityModelBindings(map);
  final instanceIds = scene.instances.map((instance) => instance.id).toSet();
  final ownedIds = <String>{};
  for (final layer in map.layers.whereType<EnvironmentLayer>()) {
    for (final area in layer.content.areas) {
      for (final id in area.generatedPlacementIds) {
        if (!instanceIds.contains(id) || !ownedIds.add(id)) {
          throw const FormatException(
            'A spatial Environment placement requires one existing instance and one owning area.',
          );
        }
      }
    }
  }
  for (final layer in map.layers.whereType<BorderLayer>()) {
    for (final feature in layer.content.features) {
      for (final id in feature.generatedPlacementIds) {
        if (!instanceIds.contains(id) || !ownedIds.add(id)) {
          throw const FormatException(
            'A spatial Border placement requires one existing instance and one owning feature.',
          );
        }
      }
    }
  }
}

Map<String, dynamic> _migrateLegacyTileLayers(Map<String, dynamic> json) {
  final rawLayers = json['layers'];
  if (rawLayers is! List) return json;
  final fallback = json['tilesetId'];
  if (fallback != null && fallback is! String) return json;
  var changed = false;
  final layers = <Object?>[];
  for (final rawLayer in rawLayers) {
    if (rawLayer is! Map || rawLayer.keys.any((key) => key is! String)) {
      layers.add(rawLayer);
      continue;
    }
    final source = Map<String, dynamic>.from(rawLayer);
    final migrated = migrateLegacyTileLayerJson(
      source,
      fallbackTilesetId: fallback as String?,
    );
    changed = changed || !identical(migrated, source);
    layers.add(migrated);
  }
  if (!changed) return json;
  return <String, dynamic>{...json, 'layers': layers};
}

void _preflightSmartTileMapJson(Map<String, dynamic> json) {
  final version = json['version'];
  if (version != 'v8' && version != 'v9') {
    throw FormatException(
      r'$.version: map_version_unsupported '
      '(expected=v8, actual=$version)',
    );
  }
  final layers = json['layers'];
  if (layers is! List) {
    return;
  }
  for (var index = 0; index < layers.length; index++) {
    final rawLayer = layers[index];
    if (rawLayer is! Map) {
      continue;
    }
    final runtimeType = rawLayer['runtimeType'];
    if (runtimeType == 'smart_tile' &&
        const <String>{
          'materialCells',
          'horizontalEdges',
          'verticalEdges',
          'corners',
        }.any(rawLayer.containsKey)) {
      throw FormatException(
        r'$.layers['
        '$index]: smart_tile_v6_legacy_payload_unsupported '
        '(version=$version, variant=smart_tile)',
      );
    }
    if (runtimeType == 'terrain' ||
        runtimeType == 'path' ||
        runtimeType == 'surface') {
      throw FormatException(
        r'$.layers['
        '$index].runtimeType: smart_tile_v6_legacy_layer_unsupported '
        '(version=$version, variant=$runtimeType)',
      );
    }
    if (runtimeType == 'smart_tile' && rawLayer['field'] is! Map) {
      throw FormatException(
        r'$.layers['
        '$index].field: smart_tile_v6_field_required '
        '(version=$version, variant=smart_tile)',
      );
    }
  }
}

// ---------------------------------------------------------------------------
// MapGameplayZone
// ---------------------------------------------------------------------------

/// Zone gameplay rectangulaire sur une map.
///
/// Sépare le **comportement gameplay** (rencontres, déplacement, danger)
/// du **visuel** ([PathSurfaceKind] / [TerrainType]).
///
/// Chaque [kind] dispose d'un payload typé :
/// - [encounter] → [EncounterZonePayload]
/// - [movement]  → [MovementZonePayload]
/// - [movementEffect] → [MovementEffectZonePayload]
/// - [hazard]    → [HazardZonePayload]
/// - [special] / [custom] → [SpecialZonePayload]
///
/// Le runtime peut lire ces zones pour décider : tirer une rencontre,
/// appliquer un effet de déplacement, déclencher un script, etc.
@freezed
abstract class MapGameplayZone with _$MapGameplayZone {
  @JsonSerializable(explicitToJson: true)
  const factory MapGameplayZone({
    required String id,
    @Default('') String name,
    required GameplayZoneKind kind,
    required MapRect area,
    @JsonKey(includeIfNull: false) List<GridPos>? cellMask,

    /// Priorité de résolution si plusieurs zones se superposent (plus haut = prioritaire).
    @Default(0) int priority,

    /// Payload pour [GameplayZoneKind.encounter].
    EncounterZonePayload? encounter,

    /// Payload pour [GameplayZoneKind.movement].
    MovementZonePayload? movement,

    /// Payload pour [GameplayZoneKind.movementEffect].
    MovementEffectZonePayload? movementEffect,

    /// Payload pour [GameplayZoneKind.hazard].
    HazardZonePayload? hazard,
    @JsonKey(includeIfNull: false) FieldActionZonePayload? fieldAction,

    /// Payload pour [GameplayZoneKind.special] et [GameplayZoneKind.custom].
    SpecialZonePayload? special,
    @JsonKey(includeIfNull: false)
    SmartTileGameplayZoneProvenance? smartTileProvenance,
  }) = _MapGameplayZone;

  factory MapGameplayZone.fromJson(Map<String, dynamic> json) =>
      _$MapGameplayZoneFromJson(_checkedGameplayZoneJson(json));
}

Map<String, dynamic> _checkedGameplayZoneJson(Map<String, dynamic> json) {
  if (json['kind'] == 'fieldAction' || json['fieldAction'] != null) {
    const fields = {
      'id',
      'name',
      'kind',
      'area',
      'cellMask',
      'priority',
      'encounter',
      'movement',
      'movementEffect',
      'hazard',
      'special',
      'fieldAction',
      'smartTileProvenance',
    };
    if (json.keys.any((key) => !fields.contains(key)) ||
        json['kind'] != 'fieldAction' ||
        json['fieldAction'] is! Map ||
        [
          'encounter',
          'movement',
          'movementEffect',
          'hazard',
          'special',
          'cellMask',
          'smartTileProvenance',
        ].any((key) => json[key] != null)) {
      throw const FormatException(
        'A field-action zone requires its exclusive typed payload.',
      );
    }
    return json;
  }
  final effect = json['movementEffect'];
  if (effect is Map && effect['effectKind'] == 'directedJump') {
    const fields = {
      'id',
      'name',
      'kind',
      'area',
      'cellMask',
      'priority',
      'encounter',
      'movement',
      'movementEffect',
      'hazard',
      'special',
      'smartTileProvenance',
    };
    if (json.keys.any((key) => !fields.contains(key))) {
      throw const FormatException('Directed jump zone has unknown fields');
    }
  }
  return migrateMapGameplayZoneJson(json);
}

int _mapPlacedElementQuarterTurnsFromJson(Object? value) {
  if (value == null) return 0;
  if (value is num &&
      value.isFinite &&
      (value is int || value == value.truncateToDouble())) {
    return value.toInt();
  }
  throw FormatException(
    'MapPlacedElement.quarterTurns must be a finite integer',
    value,
  );
}

@freezed
abstract class MapPlacedElement with _$MapPlacedElement {
  @JsonSerializable(explicitToJson: true)
  const factory MapPlacedElement({
    required String id,
    required String layerId,
    required String elementId,
    required GridPos pos,
    @Default(PixelOffset(x: 0, y: 0)) PixelOffset pixelOffset,
    @JsonKey(includeIfNull: false) PixelSize? pixelSize,
    @JsonKey(fromJson: _mapPlacedElementVisualOrderFromJson)
    @Default(0)
    int visualOrder,
    @JsonKey(fromJson: _mapPlacedElementQuarterTurnsFromJson)
    @Default(0)
    int quarterTurns,
    @Default(true) bool applyCollision,
    @Default(1.0) double opacity,
    MapPlacedElementAnimation? animation,
    @Default([]) List<MapPlacedElementBehavior> behaviors,
    @Default({}) Map<String, String> properties,
  }) = _MapPlacedElement;

  factory MapPlacedElement.fromJson(Map<String, dynamic> json) =>
      _$MapPlacedElementFromJson(migrateMapPlacedElementJson(json));
}

int _mapPlacedElementVisualOrderFromJson(Object? value) {
  if (value == null) return 0;
  if (value is int) return value;
  throw FormatException(
    'MapPlacedElement.visualOrder must be an integer',
    value,
  );
}

enum MapPlacedElementTriggerType {
  @JsonValue('on_action')
  onAction,
  @JsonValue('on_enter')
  onEnter,
  @JsonValue('on_bump')
  onBump,
  @JsonValue('on_exit')
  onExit,
  @JsonValue('on_near')
  onNear,
}

enum MapPlacedElementTriggerScope {
  @JsonValue('default')
  defaultScope,
  @JsonValue('once_per_enter')
  oncePerEnter,
  @JsonValue('while_inside_single_shot')
  whileInsideSingleShot,
  @JsonValue('facing_only')
  facingOnly,
  @JsonValue('near_cardinal_only')
  nearCardinalOnly,
}

@freezed
abstract class MapPlacedElementBehavior with _$MapPlacedElementBehavior {
  @JsonSerializable(explicitToJson: true)
  const factory MapPlacedElementBehavior({
    @Default('') String id,
    @Default(true) bool enabled,
    @Default(MapPlacedElementTriggerScope.defaultScope)
    MapPlacedElementTriggerScope triggerScope,
    int? cooldownMs,
    @Default(MapPlacedElementTriggerType.onAction)
    MapPlacedElementTriggerType trigger,
    required MapPlacedElementEffect effect,
  }) = _MapPlacedElementBehavior;

  factory MapPlacedElementBehavior.fromJson(Map<String, dynamic> json) =>
      _$MapPlacedElementBehaviorFromJson(json);
}

enum MapPlacedElementEffectType {
  @JsonValue('show_message')
  showMessage,
  @JsonValue('open_dialogue')
  openDialogue,
  @JsonValue('set_animation_enabled')
  setAnimationEnabled,
  @JsonValue('play_animation_once')
  playAnimationOnce,
  @JsonValue('traverse_warp')
  traverseWarp,
}

@freezed
abstract class MapPlacedElementEffect with _$MapPlacedElementEffect {
  @JsonSerializable(explicitToJson: true)
  const factory MapPlacedElementEffect({
    required MapPlacedElementEffectType type,
    String? message,
    DialogueRef? dialogue,
    bool? animationEnabled,
    String? targetMapId,
    GridPos? targetPos,
  }) = _MapPlacedElementEffect;

  factory MapPlacedElementEffect.fromJson(Map<String, dynamic> json) =>
      _$MapPlacedElementEffectFromJson(json);
}

@freezed
abstract class MapPlacedElementAnimation with _$MapPlacedElementAnimation {
  @JsonSerializable(explicitToJson: true)
  const factory MapPlacedElementAnimation({
    @Default(false) bool enabled,
    @Default(MapPlacedElementAnimationMode.none)
    MapPlacedElementAnimationMode mode,
    @Default(true) bool autoplay,
    @Default(1.0) double speed,
    double? startOffsetMs,
    @Default(false) bool randomStart,
  }) = _MapPlacedElementAnimation;

  factory MapPlacedElementAnimation.fromJson(Map<String, dynamic> json) =>
      _$MapPlacedElementAnimationFromJson(json);
}

@freezed
abstract class MapEntity with _$MapEntity {
  @JsonSerializable(explicitToJson: true)
  const factory MapEntity({
    required String id,
    @Default('') String name,
    required MapEntityKind kind,
    required GridPos pos,
    @Default(GridSize(width: 1, height: 1)) GridSize size,
    MapEntityNpcData? npc,
    MapEntitySignData? sign,
    MapEntityItemData? item,
    MapEntitySpawnData? spawn,
    @JsonKey(includeIfNull: false) MapEntityFieldObstacleData? fieldObstacle,
    @JsonKey(includeIfNull: false) MapEntityHealingDisplayData? healingDisplay,
    @JsonKey(includeIfNull: false) MapEntityInteractiveEncounterData? interactiveEncounter,
    @JsonKey(includeIfNull: false) MapEntityPresentation? presentation,
    @Default(<EntityFacing>[]) List<EntityFacing> counterInteractionSides,
    @Default(MapEntityInteractionMode.front) MapEntityInteractionMode interactionMode,
    MapEntityEditorVisual? editorVisual,
    @Default(true) bool blocksMovement,
    @Default({}) Map<String, String> properties,
  }) = _MapEntity;

  factory MapEntity.fromJson(Map<String, dynamic> json) => _$MapEntityFromJson(
    _checkedEntityPresentationJson(_checkedHealingDisplayEntityJson(
      _checkedInteractiveEncounterEntityJson(_checkedFieldObstacleEntityJson(migrateMapEntityJson(json))),
    )),
  );
}

Map<String, dynamic> _checkedEntityPresentationJson(Map<String, dynamic> json) {
  if (json['presentation'] == null) return json;
  final raw = json['presentation'];
  if (raw is! Map || raw.keys.any((key) => key is! String) ||
      !const ['npc', 'custom'].contains(json['kind']) ||
      const ['sign', 'item', 'spawn', 'fieldObstacle', 'healingDisplay', 'interactiveEncounter']
        .any((key) => json[key] != null)) {
    throw const FormatException('Presentation requires a native NPC or custom event owner.');
  }
  MapEntityPresentation.fromJson(Map<String, dynamic>.from(raw));
  return json;
}

Map<String, dynamic> _checkedInteractiveEncounterEntityJson(Map<String, dynamic> json) {
  final raw = json['interactiveEncounter'];
  if (raw == null) return json;
  if (raw is! Map || raw.keys.any((key) => key is! String)) throw const FormatException('Interactive encounter must be a typed object.');
  final payload = MapEntityInteractiveEncounterData.fromJson(Map<String,dynamic>.from(raw));
  final size = json['size'];
  final obstacle = json['fieldObstacle'];
  final validObstacle = payload.trigger == InteractiveEncounterTrigger.afterRockSmash
    ? obstacle is Map && obstacle['kind'] == 'rockSmashRock'
    : obstacle == null;
  if (json['kind'] != 'custom' || json['blocksMovement'] == false ||
      (size != null && (size is! Map || size['width'] != 1 || size['height'] != 1)) ||
      json['npc'] != null || json['sign'] != null || json['item'] != null || json['spawn'] != null ||
      json['healingDisplay'] != null || !validObstacle) {
    throw const FormatException('Interactive encounters require one blocking custom cell and a matching obstacle.');
  }
  return json;
}

Map<String, dynamic> _checkedFieldObstacleEntityJson(
  Map<String, dynamic> json,
) {
  final raw = json['fieldObstacle'];
  if (raw == null) return json;
  if (raw is! Map || raw.keys.any((key) => key is! String)) {
    throw const FormatException('The field obstacle must be a typed object.');
  }
  MapEntityFieldObstacleData.fromJson(Map<String, dynamic>.from(raw));
  final size = json['size'];
  if (json['kind'] != 'custom' ||
      (json['blocksMovement'] != null && json['blocksMovement'] != true) ||
      (size != null &&
          (size is! Map || size['width'] != 1 || size['height'] != 1)) ||
      json['npc'] != null ||
      json['sign'] != null ||
      json['item'] != null ||
      json['spawn'] != null ||
      json['healingDisplay'] != null) {
    throw const FormatException(
      'A field obstacle requires one blocking custom cell without another typed payload.',
    );
  }
  return json;
}

Map<String, dynamic> _checkedHealingDisplayEntityJson(
  Map<String, dynamic> json,
) {
  final raw = json['healingDisplay'];
  if (raw == null) return json;
  if (raw is! Map || raw.keys.any((key) => key is! String)) {
    throw const FormatException('The healing display must be a typed object.');
  }
  MapEntityHealingDisplayData.fromJson(Map<String, dynamic>.from(raw));
  final size = json['size'];
  if (json['kind'] != 'custom' ||
      json['blocksMovement'] != false ||
      (size != null &&
          (size is! Map || size['width'] != 1 || size['height'] != 1)) ||
      json['npc'] != null ||
      json['sign'] != null ||
      json['item'] != null ||
      json['spawn'] != null ||
      json['fieldObstacle'] != null ||
      json['editorVisual'] != null) {
    throw const FormatException(
      'A healing display requires one nonblocking custom cell without another payload.',
    );
  }
  final properties = json['properties'];
  if (properties is Map &&
      properties.keys.any(
        (key) =>
            key is String &&
            (key.startsWith('collision.') ||
                const {
                  'collisionWidth',
                  'collisionHeight',
                  'collisionOffsetX',
                  'collisionOffsetY',
                }.contains(key)),
      )) {
    throw const FormatException('A healing display cannot override collision.');
  }
  return json;
}

extension MapEntityDisplayX on MapEntity {
  /// Libellé court pour listes / canvas (hors [id] technique).
  String get inspectorHeadline {
    switch (kind) {
      case MapEntityKind.npc:
        final d = npc?.displayName.trim();
        if (d != null && d.isNotEmpty) return d;
        break;
      case MapEntityKind.sign:
        final t = sign?.title.trim();
        if (t != null && t.isNotEmpty) return t;
        break;
      case MapEntityKind.item:
        final id = item?.gameItemId.trim();
        if (id != null && id.isNotEmpty) return id;
        break;
      case MapEntityKind.spawn:
        final k = spawn?.spawnKey.trim();
        if (k != null && k.isNotEmpty) return k;
        break;
      case MapEntityKind.custom:
        break;
    }
    final n = name.trim();
    return n.isNotEmpty ? n : id;
  }
}

extension MapEntityProjectElementVisualX on MapEntity {
  String? get canonicalEditorVisualProjectElementId {
    final id = editorVisual?.elementId.trim();
    if (id == null || id.isEmpty) {
      return null;
    }
    return id;
  }

  String? get legacyNpcVisualProjectElementId {
    if (kind != MapEntityKind.npc) {
      return null;
    }
    final leg = npc?.visualElementId.trim() ?? '';
    if (leg.isEmpty) {
      return null;
    }
    return leg;
  }

  String? get resolvedProjectElementIdForEditor {
    return canonicalEditorVisualProjectElementId ??
        legacyNpcVisualProjectElementId;
  }

  bool get shouldRenderProjectElementInForeground {
    return editorVisual?.renderInForeground ?? false;
  }
}

@Freezed(fromJson: true, toJson: true)
abstract class MapWarp with _$MapWarp {
  @JsonSerializable(explicitToJson: true)
  const factory MapWarp({
    required String id,
    required GridPos pos,
    required String targetMapId,
    required GridPos targetPos,
    @Default(MapWarpTriggerMode.onEnter) MapWarpTriggerMode triggerMode,
    @Default([]) List<EntityFacing> allowedApproachFacings,
    @Default(WarpTriggerPadding()) WarpTriggerPadding triggerPadding,
    @JsonKey(includeIfNull: false) MapWarpDoor? door,
    @Default(MapWarpTransition()) MapWarpTransition transition,
  }) = _MapWarp;

  factory MapWarp.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('transition') && json['transition'] is! Map<String, dynamic>) {
      throw const FormatException('Warp transition must be an object.');
    }
    return _$MapWarpFromJson(json);
  }
}

@freezed
abstract class MapWarpDoor with _$MapWarpDoor {
  @JsonSerializable(explicitToJson: true, disallowUnrecognizedKeys: true)
  const factory MapWarpDoor({
    required String instanceId,
    required int openAnimationIndex,
    required int closeAnimationIndex,
    required GridPos exitPos,
  }) = _MapWarpDoor;

  factory MapWarpDoor.fromJson(Map<String, dynamic> json) =>
      _$MapWarpDoorFromJson(json);
}

enum MapWarpTransitionType { fade, hgss, none }

final class MapWarpTransition {
  const MapWarpTransition({
    this.type = MapWarpTransitionType.fade,
    this.durationSeconds = .2,
  }) : assert(durationSeconds > 0 && durationSeconds <= 5);

  final MapWarpTransitionType type;
  final double durationSeconds;

  factory MapWarpTransition.fromJson(Map<String, dynamic> json) {
    if (json.keys.any((key) => key != 'type' && key != 'durationSeconds')) {
      throw const FormatException('Unexpected warp transition field.');
    }
    final rawType = json['type'];
    final rawDuration = json['durationSeconds'];
    final type = MapWarpTransitionType.values
        .where((value) => value.name == rawType).firstOrNull;
    if (type == null || rawDuration is! num || !rawDuration.isFinite ||
        rawDuration <= 0 || rawDuration > 5) {
      throw const FormatException('Invalid warp transition type or duration.');
    }
    return MapWarpTransition(type: type, durationSeconds: rawDuration.toDouble());
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'durationSeconds': durationSeconds,
  };

  MapWarpTransition copyWith({MapWarpTransitionType? type, double? durationSeconds}) =>
      MapWarpTransition(type: type ?? this.type,
          durationSeconds: durationSeconds ?? this.durationSeconds);

  @override
  bool operator ==(Object other) => other is MapWarpTransition &&
      type == other.type && durationSeconds == other.durationSeconds;

  @override
  int get hashCode => Object.hash(type, durationSeconds);
}

enum MapWarpTriggerMode {
  @JsonValue('on_enter')
  onEnter,
  @JsonValue('on_bump')
  onBump,
  @JsonValue('scene_only')
  sceneOnly,
}

@freezed
abstract class WarpTriggerPadding with _$WarpTriggerPadding {
  @JsonSerializable(explicitToJson: true)
  const factory WarpTriggerPadding({
    @Default(0) int top,
    @Default(0) int right,
    @Default(0) int bottom,
    @Default(0) int left,
  }) = _WarpTriggerPadding;

  factory WarpTriggerPadding.fromJson(Map<String, dynamic> json) =>
      _$WarpTriggerPaddingFromJson(json);
}

@freezed
abstract class MapConnection with _$MapConnection {
  @JsonSerializable(explicitToJson: true)
  const factory MapConnection({
    required MapConnectionDirection direction,
    required String targetMapId,
    @Default(0) int offset,
  }) = _MapConnection;

  factory MapConnection.fromJson(Map<String, dynamic> json) =>
      _$MapConnectionFromJson(json);
}

@freezed
abstract class MapTrigger with _$MapTrigger {
  @JsonSerializable(explicitToJson: true)
  const factory MapTrigger({
    required String id,
    @Default('') String name,
    required TriggerType type,
    required MapRect area,
    @Default({}) Map<String, String> properties,
  }) = _MapTrigger;

  factory MapTrigger.fromJson(Map<String, dynamic> json) =>
      _$MapTriggerFromJson(json);
}

Map<String, dynamic> migrateMapPlacedElementJson(Map<String, dynamic> json) {
  final out = Map<String, dynamic>.from(json);
  out.putIfAbsent('quarterTurns', () => 0);
  final instanceId = (out['id'] as String?)?.trim() ?? '';
  final existingBehaviorsRaw = out['behaviors'];
  final hasBehaviorList =
      existingBehaviorsRaw is List && existingBehaviorsRaw.isNotEmpty;
  if (hasBehaviorList) {
    out['behaviors'] = _migratePlacedElementBehaviorListJson(
      existingBehaviorsRaw,
      instanceId: instanceId,
    );
    out.remove('interaction');
    return out;
  }

  final interactionRaw = out['interaction'];
  if (interactionRaw is! Map) {
    out.remove('interaction');
    return out;
  }
  final interaction = Map<String, dynamic>.from(
    interactionRaw.cast<Object?, Object?>(),
  );
  final enabled = interaction['enabled'] == true;
  final modeRaw = (interaction['mode'] as String?)?.trim().toLowerCase();
  Map<String, dynamic>? behavior;
  if (modeRaw == 'message') {
    final message = (interaction['message'] as String?)?.trim() ?? '';
    if (message.isNotEmpty) {
      behavior = <String, dynamic>{
        'enabled': enabled,
        'trigger': 'on_action',
        'effect': <String, dynamic>{'type': 'show_message', 'message': message},
      };
    }
  } else if (modeRaw == 'dialogue') {
    final dialogueRaw = interaction['dialogue'];
    if (dialogueRaw is Map) {
      final dialogue = Map<String, dynamic>.from(
        dialogueRaw.cast<Object?, Object?>(),
      );
      final dialogueId = (dialogue['dialogueId'] as String?)?.trim() ?? '';
      if (dialogueId.isNotEmpty) {
        behavior = <String, dynamic>{
          'enabled': enabled,
          'trigger': 'on_action',
          'effect': <String, dynamic>{
            'type': 'open_dialogue',
            'dialogue': <String, dynamic>{
              'dialogueId': dialogueId,
              'scriptPathRelative':
                  (dialogue['scriptPathRelative'] as String?) ?? '',
              if ((dialogue['startNode'] as String?)?.trim().isNotEmpty == true)
                'startNode': (dialogue['startNode'] as String).trim(),
            },
          },
        };
      }
    }
  }
  if (behavior != null) {
    out['behaviors'] = <Map<String, dynamic>>[behavior];
  }
  final migratedBehaviorsRaw = out['behaviors'];
  if (migratedBehaviorsRaw is List) {
    out['behaviors'] = _migratePlacedElementBehaviorListJson(
      migratedBehaviorsRaw,
      instanceId: instanceId,
    );
  }
  out.remove('interaction');
  return out;
}

List<Map<String, dynamic>> _migratePlacedElementBehaviorListJson(
  List<dynamic> rawBehaviors, {
  required String instanceId,
}) {
  final out = <Map<String, dynamic>>[];
  final seenIds = <String>{};
  var nextOrdinal = 0;
  for (var i = 0; i < rawBehaviors.length; i++) {
    final raw = rawBehaviors[i];
    if (raw is! Map) {
      continue;
    }
    final behavior = Map<String, dynamic>.from(raw.cast<Object?, Object?>());
    var id = (behavior['id'] as String?)?.trim() ?? '';
    if (id.isEmpty || seenIds.contains(id)) {
      do {
        id = _buildMigratedPlacedElementBehaviorId(
          instanceId: instanceId,
          ordinal: nextOrdinal,
        );
        nextOrdinal += 1;
      } while (seenIds.contains(id));
    }
    behavior['id'] = id;
    seenIds.add(id);
    out.add(behavior);
  }
  return out;
}

String _buildMigratedPlacedElementBehaviorId({
  required String instanceId,
  required int ordinal,
}) {
  final base = instanceId.isEmpty
      ? 'placed_element'
      : Uri.encodeComponent(instanceId);
  return '$base::behavior::$ordinal';
}

void validateSpatialEntityModelBindings(MapData map) {
  final bound = <String>{};
  final generatedIds = <String>{
    for (final layer in map.layers.whereType<EnvironmentLayer>())
      for (final area in layer.content.areas) ...area.generatedPlacementIds,
    for (final layer in map.layers.whereType<BorderLayer>())
      for (final feature in layer.content.features)
        ...feature.generatedPlacementIds,
  };
  for (final instance
      in map.spatialScene?.instances ?? const <SpatialModelInstance>[]) {
    final id = instance.entityId;
    if (id == null) continue;
    if (instance.id.startsWith('smt_') || generatedIds.contains(instance.id)) {
      throw const FormatException(
        'A generated terrain or environment instance cannot own a game entity.',
      );
    }
    final entity = map.entities.where((entity) => entity.id == id).firstOrNull;
    if (entity == null || entity.kind == MapEntityKind.npc || !bound.add(id)) {
      throw const FormatException(
        'A 3D entity model requires one existing non-NPC entity and a unique binding.',
      );
    }
    if (entity.pos.x != instance.supportPosition.x.floor() ||
        entity.pos.y != instance.supportPosition.z.floor()) {
      throw const FormatException(
        'A bound entity must follow its 3D model anchor. Move the model instead.',
      );
    }
    final item = entity.item;
    if (item != null &&
        (item.pickupMode != ItemPickupMode.once ||
            item.respawnPolicy != ItemRespawnPolicy.none)) {
      throw const FormatException(
        'Native 3D pickups require a once-only item without respawn.',
      );
    }
  }
}
