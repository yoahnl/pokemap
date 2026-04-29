// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'geometry.dart';
import 'map_entity_editor_visual.dart';
import 'map_entity_payloads.dart';
import 'map_event_definition.dart';
import 'map_gameplay_zone_payloads.dart';
import 'map_layer.dart';
import 'map_metadata.dart';

part 'map_data.freezed.dart';
part 'map_data.g.dart';

@freezed
class MapData with _$MapData {
  @JsonSerializable(explicitToJson: true)
  const factory MapData({
    required String id,
    required String name,
    required GridSize size,
    @Default(ProjectVersion.v1) ProjectVersion version,
    @Default('') String tilesetId,
    @Default([]) List<MapLayer> layers,
    @Default([]) List<MapPlacedElement> placedElements,
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

  factory MapData.fromJson(Map<String, dynamic> json) =>
      _$MapDataFromJson(json);
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
class MapGameplayZone with _$MapGameplayZone {
  @JsonSerializable(explicitToJson: true)
  const factory MapGameplayZone({
    required String id,
    @Default('') String name,
    required GameplayZoneKind kind,
    required MapRect area,

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

    /// Payload pour [GameplayZoneKind.special] et [GameplayZoneKind.custom].
    SpecialZonePayload? special,
  }) = _MapGameplayZone;

  factory MapGameplayZone.fromJson(Map<String, dynamic> json) =>
      _$MapGameplayZoneFromJson(migrateMapGameplayZoneJson(json));
}

@freezed
class MapPlacedElement with _$MapPlacedElement {
  @JsonSerializable(explicitToJson: true)
  const factory MapPlacedElement({
    required String id,
    required String layerId,
    required String elementId,
    required GridPos pos,
    @Default(true) bool applyCollision,
    MapPlacedElementAnimation? animation,
    @Default([]) List<MapPlacedElementBehavior> behaviors,
    @Default({}) Map<String, String> properties,
  }) = _MapPlacedElement;

  factory MapPlacedElement.fromJson(Map<String, dynamic> json) =>
      _$MapPlacedElementFromJson(migrateMapPlacedElementJson(json));
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
class MapPlacedElementBehavior with _$MapPlacedElementBehavior {
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
}

@freezed
class MapPlacedElementEffect with _$MapPlacedElementEffect {
  @JsonSerializable(explicitToJson: true)
  const factory MapPlacedElementEffect({
    required MapPlacedElementEffectType type,
    String? message,
    DialogueRef? dialogue,
    bool? animationEnabled,
  }) = _MapPlacedElementEffect;

  factory MapPlacedElementEffect.fromJson(Map<String, dynamic> json) =>
      _$MapPlacedElementEffectFromJson(json);
}

@freezed
class MapPlacedElementAnimation with _$MapPlacedElementAnimation {
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
class MapEntity with _$MapEntity {
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
    MapEntityEditorVisual? editorVisual,
    @Default(true) bool blocksMovement,
    @Default({}) Map<String, String> properties,
  }) = _MapEntity;

  factory MapEntity.fromJson(Map<String, dynamic> json) =>
      _$MapEntityFromJson(migrateMapEntityJson(json));
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

@freezed
class MapWarp with _$MapWarp {
  @JsonSerializable(explicitToJson: true)
  const factory MapWarp({
    required String id,
    required GridPos pos,
    required String targetMapId,
    required GridPos targetPos,
    @Default(MapWarpTriggerMode.onEnter) MapWarpTriggerMode triggerMode,
    @Default([]) List<EntityFacing> allowedApproachFacings,
    @Default(WarpTriggerPadding()) WarpTriggerPadding triggerPadding,
  }) = _MapWarp;

  factory MapWarp.fromJson(Map<String, dynamic> json) =>
      _$MapWarpFromJson(json);
}

enum MapWarpTriggerMode {
  @JsonValue('on_enter')
  onEnter,
  @JsonValue('on_bump')
  onBump,
}

@freezed
class WarpTriggerPadding with _$WarpTriggerPadding {
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
class MapConnection with _$MapConnection {
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
class MapTrigger with _$MapTrigger {
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
  final interaction =
      Map<String, dynamic>.from(interactionRaw.cast<Object?, Object?>());
  final enabled = interaction['enabled'] == true;
  final modeRaw = (interaction['mode'] as String?)?.trim().toLowerCase();
  Map<String, dynamic>? behavior;
  if (modeRaw == 'message') {
    final message = (interaction['message'] as String?)?.trim() ?? '';
    if (message.isNotEmpty) {
      behavior = <String, dynamic>{
        'enabled': enabled,
        'trigger': 'on_action',
        'effect': <String, dynamic>{
          'type': 'show_message',
          'message': message,
        },
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
  final base =
      instanceId.isEmpty ? 'placed_element' : Uri.encodeComponent(instanceId);
  return '$base::behavior::$ordinal';
}
