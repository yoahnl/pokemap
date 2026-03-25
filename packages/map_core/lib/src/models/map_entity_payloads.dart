import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'map_entity_payloads.freezed.dart';
part 'map_entity_payloads.g.dart';

/// Référence à un dialogue : id métier aligné sur [ProjectDialogueEntry] si le chemin ci-dessous est vide ; sinon chemin legacy / override.
///
/// Sans dépendance Yarn ou autre moteur dans `map_core`.
@freezed
class DialogueRef with _$DialogueRef {
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

@freezed
class MapEntityNpcData with _$MapEntityNpcData {
  @JsonSerializable(explicitToJson: true)
  const factory MapEntityNpcData({
    @Default('') String displayName,
    DialogueRef? dialogue,
    @Default(EntityFacing.south) EntityFacing facing,
    @Default('') String visualElementId,
  }) = _MapEntityNpcData;

  factory MapEntityNpcData.fromJson(Map<String, dynamic> json) =>
      _$MapEntityNpcDataFromJson(json);
}

@freezed
class MapEntitySignData with _$MapEntitySignData {
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
class MapEntityItemData with _$MapEntityItemData {
  @JsonSerializable(explicitToJson: true)
  const factory MapEntityItemData({
    @Default('') String gameItemId,
    @Default(1) int quantity,
    @Default(ItemPickupMode.once) ItemPickupMode pickupMode,
    @Default(ItemRespawnPolicy.none) ItemRespawnPolicy respawnPolicy,
  }) = _MapEntityItemData;

  factory MapEntityItemData.fromJson(Map<String, dynamic> json) =>
      _$MapEntityItemDataFromJson(json);
}

@freezed
class MapEntitySpawnData with _$MapEntitySpawnData {
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
    final path = takeProp(['dialogueScript', 'scriptPath', 'scriptPathRelative']);
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
        takePropsIntoDialogue(
            ['dialogueId', 'dialogue', 'yarnNode'], npc);
        final facing = takeProp(['facing', 'direction', 'face']);
        if (facing != null) {
          final f = _parseFacing(facing);
          if (f != null) npc['facing'] = f;
        }
        final vid = takeProp(['visualElementId', 'elementRef', 'sprite', 'spriteRef']);
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
