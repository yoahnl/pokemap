import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'geometry.dart';

part 'map_entity_payloads.freezed.dart';
part 'map_entity_payloads.g.dart';

/// Référence à un dialogue : id métier aligné sur [ProjectDialogueEntry] si le chemin ci-dessous est vide ; sinon chemin legacy / override.
///
/// Sans dépendance Yarn ou autre moteur dans `map_core`.
@freezed
abstract class DialogueRef with _$DialogueRef {
  @JsonSerializable(explicitToJson: true)
  const factory DialogueRef({
    /// Identifiant stable : typiquement [ProjectDialogueEntry.id] lorsque [scriptPathRelative] est vide.
    required String dialogueId,

    /// Vide = résolution via le registre projet ; non vide = script explicite (legacy ou override).
    @Default('') String scriptPathRelative,

    /// Nœud d’entrée optionnel (ex. titre de nœud Yarn).
    String? startNode,
  }) = _DialogueRef;

  factory DialogueRef.fromJson(Map<String, dynamic> json) =>
      _$DialogueRefFromJson(json);
}

// ---------------------------------------------------------------------------
// Règles runtime PNJ (visibilité + dialogues conditionnels) — authoring JSON
// ---------------------------------------------------------------------------
//
// Ces types sont consommés par map_runtime (évaluation) et map_editor (UI
// dropdowns). Les libellés UI restent côté éditeur ; ici seulement noms
// stables pour la sérialisation projet.

/// Comment interpréter la [MapEntityRuntimePredicate] pour la **visibilité**.
enum MapEntityNpcVisibilityMode {
  /// PNJ toujours affiché (ignore [MapEntityNpcVisibilityRule.predicate]).
  @JsonValue('always')
  always,

  /// Visible uniquement lorsque la prédicat est vrai.
  @JsonValue('visibleWhen')
  visibleWhen,

  /// Masqué lorsque la prédicat est vrai (visible sinon).
  @JsonValue('hiddenWhen')
  hiddenWhen,
}

/// Condition réutilisable (visibilité ou variante de dialogue).
enum MapEntityRuntimePredicateKind {
  @JsonValue('storyFlagSet')
  storyFlagSet,
  @JsonValue('storyFlagUnset')
  storyFlagUnset,
  @JsonValue('stepCompleted')
  stepCompleted,
  @JsonValue('stepNotCompleted')
  stepNotCompleted,
  @JsonValue('chapterCompleted')
  chapterCompleted,
  @JsonValue('chapterNotCompleted')
  chapterNotCompleted,
  @JsonValue('cutsceneCompleted')
  cutsceneCompleted,
  @JsonValue('cutsceneNotCompleted')
  cutsceneNotCompleted,
  @JsonValue('badgeOwned')
  badgeOwned,
  @JsonValue('badgeNotOwned')
  badgeNotOwned,
}

@freezed
abstract class MapEntityRuntimePredicate with _$MapEntityRuntimePredicate {
  @JsonSerializable(explicitToJson: true)
  const factory MapEntityRuntimePredicate({
    required MapEntityRuntimePredicateKind kind,

    /// Id métier selon [kind] : nom de flag, id de step, id de chapitre,
    /// id de scénario local (cutscene).
    @Default('') String refId,
  }) = _MapEntityRuntimePredicate;

  factory MapEntityRuntimePredicate.fromJson(Map<String, dynamic> json) =>
      _$MapEntityRuntimePredicateFromJson(json);
}

@freezed
abstract class MapEntityNpcVisibilityRule with _$MapEntityNpcVisibilityRule {
  @JsonSerializable(explicitToJson: true)
  const factory MapEntityNpcVisibilityRule({
    required MapEntityNpcVisibilityMode mode,
    MapEntityRuntimePredicate? predicate,
  }) = _MapEntityNpcVisibilityRule;

  factory MapEntityNpcVisibilityRule.fromJson(Map<String, dynamic> json) =>
      _$MapEntityNpcVisibilityRuleFromJson(json);
}

/// Une ligne de la chaîne « premier match gagne » pour le dialogue PNJ.
@freezed
abstract class MapEntityConditionalDialogue with _$MapEntityConditionalDialogue {
  @JsonSerializable(explicitToJson: true)
  const factory MapEntityConditionalDialogue({
    required MapEntityRuntimePredicate when,
    required DialogueRef dialogue,
  }) = _MapEntityConditionalDialogue;

  factory MapEntityConditionalDialogue.fromJson(Map<String, dynamic> json) =>
      _$MapEntityConditionalDialogueFromJson(json);
}

@freezed
abstract class MapEntityNpcData with _$MapEntityNpcData {
  @JsonSerializable(explicitToJson: true)
  const factory MapEntityNpcData({
    @Default('') String displayName,
    DialogueRef? dialogue,
    @Default(EntityFacing.south) EntityFacing facing,
    @Default('') String visualElementId,
    String? trainerId,
    @Default(0) int lineOfSightRange,
    @Default(<EntityFacing>[]) List<EntityFacing> counterInteractionSides,
    DialogueRef? defeatDialogueRef,
    String? characterId,
    @Default(MapEntityNpcMovementConfig()) MapEntityNpcMovementConfig movement,

    /// `null` ou mode [MapEntityNpcVisibilityMode.always] = toujours visible.
    MapEntityNpcVisibilityRule? visibilityRule,

    /// Variantes testées **dans l’ordre** avant [dialogue] par défaut.
    @Default(<MapEntityConditionalDialogue>[])
    List<MapEntityConditionalDialogue> conditionalDialogues,
  }) = _MapEntityNpcData;

  factory MapEntityNpcData.fromJson(Map<String, dynamic> json) =>
      _$MapEntityNpcDataFromJson(json);
}

enum MapEntityNpcMovementMode {
  @JsonValue('idle')
  idle,
  @JsonValue('patrol')
  patrol,
  @JsonValue('scriptedOnly')
  scriptedOnly,
  @JsonValue('fixedRoute')
  fixedRoute,
}

enum MapEntityNpcRouteStepKind { move, face, randomFacing }

@immutable
sealed class MapEntityNpcRouteStep {
  const MapEntityNpcRouteStep();

  const factory MapEntityNpcRouteStep.move({required EntityFacing direction}) =
      MapEntityNpcMoveStep;
  const factory MapEntityNpcRouteStep.face({required EntityFacing direction}) =
      MapEntityNpcFaceStep;
  const factory MapEntityNpcRouteStep.randomFacing() =
      MapEntityNpcRandomFacingStep;

  factory MapEntityNpcRouteStep.fromJson(Map<String, dynamic> json) {
    final kind = json['kind'];
    final fields = kind == 'randomFacing'
        ? const {'kind'}
        : const {'kind', 'direction'};
    if (json.length != fields.length || !json.keys.every(fields.contains)) {
      throw const FormatException(
        'An autonomous NPC step has unexpected fields.',
      );
    }
    if (kind == 'randomFacing') {
      return const MapEntityNpcRouteStep.randomFacing();
    }
    final rawDirection = json['direction'];
    if (rawDirection is! String ||
        !EntityFacing.values.any(
          (direction) => direction.name == rawDirection,
        )) {
      throw const FormatException(
        'An autonomous NPC step requires a cardinal direction.',
      );
    }
    final direction = EntityFacing.values.byName(rawDirection);
    return switch (kind) {
      'move' => MapEntityNpcRouteStep.move(direction: direction),
      'face' => MapEntityNpcRouteStep.face(direction: direction),
      _ => throw const FormatException('Unsupported autonomous NPC step.'),
    };
  }

  MapEntityNpcRouteStepKind get kind;
  Map<String, dynamic> toJson();
}

@immutable
final class MapEntityNpcMoveStep extends MapEntityNpcRouteStep {
  const MapEntityNpcMoveStep({required this.direction});
  final EntityFacing direction;
  @override
  MapEntityNpcRouteStepKind get kind => MapEntityNpcRouteStepKind.move;
  @override
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'direction': direction.name,
  };
  @override
  bool operator ==(Object other) =>
      other is MapEntityNpcMoveStep && direction == other.direction;
  @override
  int get hashCode => Object.hash(kind, direction);
}

@immutable
final class MapEntityNpcFaceStep extends MapEntityNpcRouteStep {
  const MapEntityNpcFaceStep({required this.direction});
  final EntityFacing direction;
  @override
  MapEntityNpcRouteStepKind get kind => MapEntityNpcRouteStepKind.face;
  @override
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'direction': direction.name,
  };
  @override
  bool operator ==(Object other) =>
      other is MapEntityNpcFaceStep && direction == other.direction;
  @override
  int get hashCode => Object.hash(kind, direction);
}

@immutable
final class MapEntityNpcRandomFacingStep extends MapEntityNpcRouteStep {
  const MapEntityNpcRandomFacingStep();
  @override
  MapEntityNpcRouteStepKind get kind => MapEntityNpcRouteStepKind.randomFacing;
  @override
  Map<String, dynamic> toJson() => {'kind': kind.name};
  @override
  bool operator ==(Object other) => other is MapEntityNpcRandomFacingStep;
  @override
  int get hashCode => kind.hashCode;
}

@immutable
final class MapEntityNpcRouteInstanceBoolean {
  MapEntityNpcRouteInstanceBoolean({required String key, this.value = true})
      : key = _npcRouteInstanceKey(key);

  final String key;
  final bool value;

  factory MapEntityNpcRouteInstanceBoolean.fromJson(Map<String,dynamic> json) {
    if (json.length != 2 || !json.keys.every(const {'key','value'}.contains) ||
        json['key'] is! String || json['value'] is! bool) {
      throw const FormatException('A route suspension requires one instance boolean key and value.');
    }
    try {
      return MapEntityNpcRouteInstanceBoolean(key: json['key'] as String, value: json['value'] as bool);
    } on ArgumentError {
      throw const FormatException('A route suspension requires a bounded canonical instance boolean key.');
    }
  }

  Map<String,dynamic> toJson() => {'key':key,'value':value};
  @override
  bool operator ==(Object other) => other is MapEntityNpcRouteInstanceBoolean && key == other.key && value == other.value;
  @override
  int get hashCode => Object.hash(key,value);
}

String _npcRouteInstanceKey(String key) {
  if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_.:-]{0,127}$').hasMatch(key)) {
    throw ArgumentError.value(key, 'key', 'Must be a bounded canonical instance boolean identity.');
  }
  return key;
}

@freezed
abstract class MapEntityNpcMovementConfig with _$MapEntityNpcMovementConfig {
  @JsonSerializable(explicitToJson: true)
  const factory MapEntityNpcMovementConfig({
    @Default(MapEntityNpcMovementMode.idle) MapEntityNpcMovementMode mode,
    @Default(<GridPos>[]) List<GridPos> waypoints,
    @Default(<MapEntityNpcRouteStep>[]) List<MapEntityNpcRouteStep> routeSteps,
    MapEntityNpcRouteInstanceBoolean? suspendWhenInstanceBoolean,
    @Default(true) bool loop,
    @Default(0) int pauseDurationMs,
    @Default(200) int stepDurationMs,
  }) = _MapEntityNpcMovementConfig;

  factory MapEntityNpcMovementConfig.fromJson(Map<String, dynamic> json) =>
      _$MapEntityNpcMovementConfigFromJson(json);
}

@freezed
abstract class MapEntitySignData with _$MapEntitySignData {
  @JsonSerializable(explicitToJson: true)
  const factory MapEntitySignData({
    @Default('') String title,
    DialogueRef? dialogue,

    /// Texte affiché si pas de dialogue scripté (panneau simple).
    @Default('') String plainText,
  }) = _MapEntitySignData;

  factory MapEntitySignData.fromJson(Map<String, dynamic> json) =>
      _$MapEntitySignDataFromJson(json);
}

@freezed
abstract class MapEntityItemData with _$MapEntityItemData {
  @JsonSerializable(explicitToJson: true)
  const factory MapEntityItemData({
    @Default('') String gameItemId,
    @Default(1) int quantity,
    @Default(ItemPickupMode.once) ItemPickupMode pickupMode,
    @Default(ItemRespawnPolicy.none) ItemRespawnPolicy respawnPolicy,
    @Default(MapEntityItemVisibility.visible)
    MapEntityItemVisibility visibility,
  }) = _MapEntityItemData;

  factory MapEntityItemData.fromJson(Map<String, dynamic> json) =>
      _$MapEntityItemDataFromJson(json);
}

@freezed
abstract class MapEntitySpawnData with _$MapEntitySpawnData {
  @JsonSerializable(explicitToJson: true)
  const factory MapEntitySpawnData({
    @Default('') String spawnKey,
    @Default(EntitySpawnRole.playerStart) EntitySpawnRole role,
    @Default(EntityFacing.south) EntityFacing facing,
    @Default('') String categoryTag,
  }) = _MapEntitySpawnData;

  factory MapEntitySpawnData.fromJson(Map<String, dynamic> json) =>
      _$MapEntitySpawnDataFromJson(json);
}

/// Migre JSON d’entité legacy (tout dans [properties]) vers champs structurés.
Map<String, dynamic> migrateMapEntityJson(Map<String, dynamic> json) {
  final out = Map<String, dynamic>.from(json);
  final kind = out['kind'] as String? ?? 'custom';
  final propsRaw = out['properties'];
  final props = <String, String>{};
  if (propsRaw is Map) {
    for (final e in propsRaw.entries) {
      props[e.key.toString()] = e.value?.toString() ?? '';
    }
  }

  String? takeProp(List<String> keys) {
    for (final k in keys) {
      final v = props[k]?.trim();
      if (v != null && v.isNotEmpty) {
        props.remove(k);
        return v;
      }
    }
    return null;
  }

  void takePropsIntoDialogue(List<String> idKeys, Map<String, dynamic> target) {
    final id = takeProp(idKeys);
    final path =
        takeProp(['dialogueScript', 'scriptPath', 'scriptPathRelative']);
    final node = takeProp(['startNode', 'dialogueStartNode', 'yarnStart']);
    if (id != null && id.isNotEmpty) {
      target['dialogue'] = <String, dynamic>{
        'dialogueId': id,
        'scriptPathRelative': path ?? '',
        if (node != null && node.isNotEmpty) 'startNode': node,
      };
    }
  }

  switch (kind) {
    case 'npc':
      if (out['npc'] == null) {
        final npc = <String, dynamic>{};
        final dn = takeProp(['displayName', 'npcName', 'characterName']);
        if (dn != null) npc['displayName'] = dn;
        takePropsIntoDialogue(['dialogueId', 'dialogue', 'yarnNode'], npc);
        final facing = takeProp(['facing', 'direction', 'face']);
        if (facing != null) {
          final f = _parseFacing(facing);
          if (f != null) npc['facing'] = f;
        }
        final charId = takeProp([
          'characterId',
          'overworldCharacterId',
          'characterRef',
          'spriteCharacterId',
        ]);
        if (charId != null) npc['characterId'] = charId;
        final trainerId = takeProp(['trainerId', 'trainerRef']);
        if (trainerId != null) npc['trainerId'] = trainerId;
        final vid =
            takeProp(['visualElementId', 'elementRef', 'sprite', 'spriteRef']);
        if (vid != null) npc['visualElementId'] = vid;
        if (npc.isNotEmpty) {
          out['npc'] = npc;
        }
      }
      break;
    case 'sign':
      if (out['sign'] == null) {
        final sign = <String, dynamic>{};
        final title = takeProp(['title', 'signTitle']);
        if (title != null) sign['title'] = title;
        takePropsIntoDialogue(['dialogueId', 'dialogue'], sign);
        final text = takeProp(['text', 'message', 'plainText', 'body']);
        if (text != null) sign['plainText'] = text;
        if (sign.isNotEmpty) {
          out['sign'] = sign;
        }
      }
      break;
    case 'item':
      if (out['item'] == null) {
        final item = <String, dynamic>{};
        final gid = takeProp(['itemId', 'gameItemId', 'item']);
        if (gid != null) item['gameItemId'] = gid;
        final q = takeProp(['quantity', 'qty', 'count']);
        if (q != null) {
          final n = int.tryParse(q);
          if (n != null && n > 0) item['quantity'] = n;
        }
        final pickup = takeProp(['pickupMode', 'pickup']);
        if (pickup != null) {
          final m = _parsePickupMode(pickup);
          if (m != null) item['pickupMode'] = m;
        }
        final resp = takeProp(['respawnPolicy', 'respawn']);
        if (resp != null) {
          final r = _parseRespawnPolicy(resp);
          if (r != null) item['respawnPolicy'] = r;
        }
        if (item.isNotEmpty) {
          out['item'] = item;
        }
      }
      break;
    case 'spawn':
      if (out['spawn'] == null) {
        final spawn = <String, dynamic>{};
        final key = takeProp(['spawnKey', 'spawnId', 'idTag']);
        if (key != null) spawn['spawnKey'] = key;
        final role = takeProp(['spawnRole', 'role']);
        if (role != null) {
          final r = _parseSpawnRole(role);
          if (r != null) spawn['role'] = r;
        }
        final facing = takeProp(['facing', 'direction']);
        if (facing != null) {
          final f = _parseFacing(facing);
          if (f != null) spawn['facing'] = f;
        }
        final cat = takeProp(['categoryTag', 'category', 'spawnType']);
        if (cat != null) spawn['categoryTag'] = cat;
        if (spawn.isNotEmpty) {
          out['spawn'] = spawn;
        }
      }
      break;
    default:
      break;
  }

  out['properties'] = props;
  return out;
}

String? _parseFacing(String raw) {
  switch (raw.toLowerCase()) {
    case 'n':
    case 'north':
      return 'north';
    case 's':
    case 'south':
      return 'south';
    case 'e':
    case 'east':
      return 'east';
    case 'w':
    case 'west':
      return 'west';
    default:
      return null;
  }
}

String? _parsePickupMode(String raw) {
  switch (raw.toLowerCase()) {
    case 'once':
    case 'single':
      return 'once';
    case 'always':
    case 'repeat':
      return 'always';
    case 'quest_gated':
    case 'quest':
      return 'quest_gated';
    default:
      return null;
  }
}

String? _parseRespawnPolicy(String raw) {
  switch (raw.toLowerCase()) {
    case 'none':
      return 'none';
    case 'on_map_reload':
    case 'reload':
      return 'on_map_reload';
    case 'timed':
      return 'timed';
    default:
      return null;
  }
}

String? _parseSpawnRole(String raw) {
  switch (raw.toLowerCase()) {
    case 'player_start':
    case 'player':
    case 'start':
      return 'player_start';
    case 'event':
      return 'event';
    case 'npc_spawn':
    case 'npc':
      return 'npc_spawn';
    case 'debug':
      return 'debug';
    case 'other':
      return 'other';
    default:
      return null;
  }
}
