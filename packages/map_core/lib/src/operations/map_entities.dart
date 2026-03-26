import '../exceptions/map_exceptions.dart';
import '../models/enums.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_entity_editor_visual.dart';
import '../models/map_entity_payloads.dart';
import '../models/project_manifest.dart';
import '../validation/dialogue_validation.dart';

/// Valeur sentinelle pour [updateEntityOnMap] : ne pas modifier le bloc typé existant.
///
/// `null` signifie « effacer / remplacer par null » avant coercition ; omettre avec cette
/// constante signifie « conserver la valeur courante sur l’entité ».
const Object mapEntityTypedPayloadUnset = Object();

MapEntity? findEntityById(
  MapData map,
  String entityId,
) {
  final normalizedEntityId = entityId.trim();
  if (normalizedEntityId.isEmpty) {
    return null;
  }
  for (final entity in map.entities) {
    if (entity.id == normalizedEntityId) {
      return entity;
    }
  }
  return null;
}

MapEntity? findEntityAtPos(
  MapData map,
  GridPos pos,
) {
  for (var index = map.entities.length - 1; index >= 0; index--) {
    final entity = map.entities[index];
    if (_containsPos(entity, pos)) {
      return entity;
    }
  }
  return null;
}

MapData addEntityToMap(
  MapData map, {
  required MapEntity entity,
}) {
  final normalizedEntity = _normalizeEntity(entity);
  _validateEntity(
    map,
    normalizedEntity,
    duplicateIdLabel: 'Entity ID already exists',
  );
  return map.copyWith(
    entities: [...map.entities, normalizedEntity],
  );
}

MapData updateEntityOnMap(
  MapData map, {
  required String entityId,
  String? id,
  String? name,
  MapEntityKind? kind,
  GridPos? pos,
  GridSize? size,
  Map<String, String>? properties,
  Object? npc = mapEntityTypedPayloadUnset,
  Object? sign = mapEntityTypedPayloadUnset,
  Object? item = mapEntityTypedPayloadUnset,
  Object? spawn = mapEntityTypedPayloadUnset,
  Object? editorVisual = mapEntityTypedPayloadUnset,
}) {
  final index = map.entities.indexWhere((entity) => entity.id == entityId);
  if (index < 0) {
    throw ValidationException('Entity not found: $entityId');
  }
  final current = map.entities[index];
  var draft = current.copyWith(
    id: id?.trim() ?? current.id,
    name: name?.trim() ?? current.name,
    kind: kind ?? current.kind,
    pos: pos ?? current.pos,
    size: size ?? current.size,
    properties: properties == null
        ? current.properties
        : _normalizeProperties(properties),
  );
  if (!identical(npc, mapEntityTypedPayloadUnset)) {
    draft = draft.copyWith(npc: npc as MapEntityNpcData?);
  }
  if (!identical(sign, mapEntityTypedPayloadUnset)) {
    draft = draft.copyWith(sign: sign as MapEntitySignData?);
  }
  if (!identical(item, mapEntityTypedPayloadUnset)) {
    draft = draft.copyWith(item: item as MapEntityItemData?);
  }
  if (!identical(spawn, mapEntityTypedPayloadUnset)) {
    draft = draft.copyWith(spawn: spawn as MapEntitySpawnData?);
  }
  if (!identical(editorVisual, mapEntityTypedPayloadUnset)) {
    draft = draft.copyWith(editorVisual: editorVisual as MapEntityEditorVisual?);
  }
  final next = _normalizeEntity(draft);
  _validateEntity(
    map,
    next,
    excludedEntityId: current.id,
    duplicateIdLabel: 'Entity ID already exists',
  );
  final updated = List<MapEntity>.from(map.entities, growable: false);
  updated[index] = next;
  return map.copyWith(entities: updated);
}

MapData moveEntityOnMap(
  MapData map, {
  required String entityId,
  required GridPos pos,
}) {
  final entity = findEntityById(map, entityId);
  if (entity == null) {
    throw ValidationException('Entity not found: $entityId');
  }
  return updateEntityOnMap(
    map,
    entityId: entityId,
    pos: pos,
  );
}

MapData resizeEntityOnMap(
  MapData map, {
  required String entityId,
  required GridSize size,
}) {
  final entity = findEntityById(map, entityId);
  if (entity == null) {
    throw ValidationException('Entity not found: $entityId');
  }
  return updateEntityOnMap(
    map,
    entityId: entityId,
    size: size,
  );
}

MapData removeEntityFromMap(
  MapData map, {
  required String entityId,
}) {
  final index = map.entities.indexWhere((entity) => entity.id == entityId);
  if (index < 0) {
    throw ValidationException('Entity not found: $entityId');
  }
  final updated = List<MapEntity>.from(map.entities, growable: true)
    ..removeAt(index);
  return map.copyWith(entities: updated);
}

MapEntity _normalizeEntity(MapEntity entity) {
  final trimmed = entity.copyWith(
    id: entity.id.trim(),
    name: entity.name.trim(),
    properties: _normalizeProperties(entity.properties),
    npc: entity.npc != null ? _normalizeNpc(entity.npc!) : null,
    sign: entity.sign != null ? _normalizeSign(entity.sign!) : null,
    item: entity.item,
    spawn: entity.spawn != null ? _normalizeSpawn(entity.spawn!) : null,
    editorVisual: _normalizeEditorVisual(entity.editorVisual),
  );
  return _coercePayloadsToKind(trimmed);
}

MapEntityEditorVisual? _normalizeEditorVisual(MapEntityEditorVisual? v) {
  if (v == null) {
    return null;
  }
  final id = v.elementId.trim();
  if (id.isEmpty) {
    return null;
  }
  return MapEntityEditorVisual(elementId: id);
}

MapEntityNpcData _normalizeNpc(MapEntityNpcData n) {
  final d = n.dialogue;
  return n.copyWith(
    displayName: n.displayName.trim(),
    visualElementId: n.visualElementId.trim(),
    dialogue: d == null
        ? null
        : DialogueRef(
            dialogueId: d.dialogueId.trim(),
            scriptPathRelative: d.scriptPathRelative.trim(),
            startNode: d.startNode?.trim().isEmpty == true ? null : d.startNode?.trim(),
          ),
  );
}

MapEntitySignData _normalizeSign(MapEntitySignData s) {
  final d = s.dialogue;
  return s.copyWith(
    title: s.title.trim(),
    plainText: s.plainText.trim(),
    dialogue: d == null
        ? null
        : DialogueRef(
            dialogueId: d.dialogueId.trim(),
            scriptPathRelative: d.scriptPathRelative.trim(),
            startNode: d.startNode?.trim().isEmpty == true ? null : d.startNode?.trim(),
          ),
  );
}

MapEntitySpawnData _normalizeSpawn(MapEntitySpawnData s) {
  return s.copyWith(
    spawnKey: s.spawnKey.trim(),
    categoryTag: s.categoryTag.trim(),
  );
}

/// Une seule charge utile typée selon [MapEntity.kind] ; défauts pour les kinds structurés.
MapEntity _coercePayloadsToKind(MapEntity e) {
  return switch (e.kind) {
    MapEntityKind.npc => e.copyWith(
        npc: e.npc ?? const MapEntityNpcData(),
        sign: null,
        item: null,
        spawn: null,
      ),
    MapEntityKind.sign => e.copyWith(
        sign: e.sign ?? const MapEntitySignData(),
        npc: null,
        item: null,
        spawn: null,
      ),
    MapEntityKind.item => e.copyWith(
        item: e.item ?? const MapEntityItemData(),
        npc: null,
        sign: null,
        spawn: null,
      ),
    MapEntityKind.spawn => e.copyWith(
        spawn: e.spawn ?? const MapEntitySpawnData(),
        npc: null,
        sign: null,
        item: null,
      ),
    MapEntityKind.custom => e.copyWith(
        npc: null,
        sign: null,
        item: null,
        spawn: null,
      ),
  };
}

Map<String, String> _normalizeProperties(Map<String, String> properties) {
  return Map<String, String>.unmodifiable({
    for (final entry in properties.entries)
      entry.key.trim(): entry.value.trim(),
  });
}

void _validateEntity(
  MapData map,
  MapEntity entity, {
  String? excludedEntityId,
  required String duplicateIdLabel,
}) {
  final id = entity.id.trim();
  if (id.isEmpty) {
    throw const ValidationException('Entity ID cannot be empty');
  }
  if (map.entities.any(
    (entry) => entry.id == id && entry.id != excludedEntityId,
  )) {
    throw ValidationException('$duplicateIdLabel: $id');
  }
  if (entity.size.width <= 0 || entity.size.height <= 0) {
    throw ValidationException(
      'Entity $id has invalid size: (${entity.size.width}x${entity.size.height})',
    );
  }
  if (entity.pos.x < 0 ||
      entity.pos.y < 0 ||
      entity.pos.x + entity.size.width > map.size.width ||
      entity.pos.y + entity.size.height > map.size.height) {
    throw ValidationException(
      'Entity $id is out of map bounds at (${entity.pos.x}, ${entity.pos.y}) with size (${entity.size.width}x${entity.size.height})',
    );
  }
  for (final key in entity.properties.keys) {
    if (key.trim().isEmpty) {
      throw ValidationException('Entity $id has an empty property key');
    }
  }
  assertValidMapEntityTypedPayloads(entity);
}

/// Règles métier sur les champs typés (également utilisées par [MapValidator]).
void assertValidMapEntityTypedPayloads(MapEntity entity) {
  switch (entity.kind) {
    case MapEntityKind.npc:
      final n = entity.npc ?? const MapEntityNpcData();
      final d = n.dialogue;
      if (d != null && d.dialogueId.trim().isEmpty) {
        throw ValidationException(
          'Entity ${entity.id} has an NPC dialogue reference without dialogueId',
        );
      }
      if (d != null) {
        _assertDialogueScriptPath(d.scriptPathRelative, entity.id);
        assertValidDialogueStartNode(
          d.startNode,
          contextLabel: 'Entity ${entity.id} (NPC dialogue)',
        );
      }
      if (n.lineOfSightRange < 0) {
        throw ValidationException(
          'Entity ${entity.id} lineOfSightRange must be >= 0',
        );
      }
      final dd = n.defeatDialogueRef;
      if (dd != null && dd.dialogueId.trim().isEmpty) {
        throw ValidationException(
          'Entity ${entity.id} has a defeatDialogueRef without dialogueId',
        );
      }
      if (dd != null) {
        _assertDialogueScriptPath(dd.scriptPathRelative, entity.id);
        assertValidDialogueStartNode(
          dd.startNode,
          contextLabel: 'Entity ${entity.id} (defeat dialogue)',
        );
      }
      break;
    case MapEntityKind.sign:
      final s = entity.sign ?? const MapEntitySignData();
      final d = s.dialogue;
      if (d != null && d.dialogueId.trim().isEmpty) {
        throw ValidationException(
          'Entity ${entity.id} has a sign dialogue reference without dialogueId',
        );
      }
      if (d != null) {
        _assertDialogueScriptPath(d.scriptPathRelative, entity.id);
        assertValidDialogueStartNode(
          d.startNode,
          contextLabel: 'Entity ${entity.id} (sign dialogue)',
        );
      }
      break;
    case MapEntityKind.item:
      final it = entity.item ?? const MapEntityItemData();
      if (it.quantity <= 0) {
        throw ValidationException(
          'Entity ${entity.id} has invalid item quantity: ${it.quantity}',
        );
      }
      break;
    case MapEntityKind.spawn:
    case MapEntityKind.custom:
      break;
  }
}

void _assertDialogueScriptPath(String path, String entityId) {
  final p = path.trim();
  if (p.isEmpty) return;
  if (p.startsWith('/') || p.startsWith('\\')) {
    throw ValidationException(
      'Entity $entityId dialogue scriptPathRelative must be relative',
    );
  }
  if (p.contains('..')) {
    throw ValidationException(
      'Entity $entityId dialogue scriptPathRelative must not escape the project',
    );
  }
}

/// Si [manifest] est fourni et que la référence n’utilise pas de chemin legacy
/// ([DialogueRef.scriptPathRelative] vide), vérifie que [dialogueId] existe dans le registre projet.
void assertEntityDialogueRefsAgainstProject(
  MapEntity entity,
  ProjectManifest manifest,
) {
  switch (entity.kind) {
    case MapEntityKind.npc:
      _assertDialogueRefAgainstRegistry(
        entity.npc?.dialogue,
        entity.id,
        manifest,
      );
      _assertDialogueRefAgainstRegistry(
        entity.npc?.defeatDialogueRef,
        entity.id,
        manifest,
      );
      break;
    case MapEntityKind.sign:
      _assertDialogueRefAgainstRegistry(
        entity.sign?.dialogue,
        entity.id,
        manifest,
      );
      break;
    default:
      break;
  }
}

void _assertDialogueRefAgainstRegistry(
  DialogueRef? d,
  String entityId,
  ProjectManifest manifest,
) {
  if (d == null) return;
  final path = d.scriptPathRelative.trim();
  if (path.isNotEmpty) {
    return;
  }
  final id = d.dialogueId.trim();
  if (id.isEmpty) return;
  final exists = manifest.dialogues.any((e) => e.id == id);
  if (!exists) {
    throw ValidationException(
      'Entity $entityId references unknown dialogue id "$id" (add it to Project dialogues or set a script path)',
    );
  }
}

/// Vérifie que [MapEntityNpcData.trainerId] référence un dresseur connu dans [manifest].
void assertEntityTrainerRefsAgainstProject(
  MapEntity entity,
  ProjectManifest manifest,
) {
  if (entity.kind != MapEntityKind.npc) return;
  final tid = entity.npc?.trainerId?.trim();
  if (tid == null || tid.isEmpty) return;
  final exists = manifest.trainers.any((t) => t.id == tid);
  if (!exists) {
    throw ValidationException(
      'Entity ${entity.id} references unknown trainer id "$tid" (add it to Project trainers)',
    );
  }
}

bool _containsPos(
  MapEntity entity,
  GridPos pos,
) {
  return pos.x >= entity.pos.x &&
      pos.y >= entity.pos.y &&
      pos.x < entity.pos.x + entity.size.width &&
      pos.y < entity.pos.y + entity.size.height;
}
