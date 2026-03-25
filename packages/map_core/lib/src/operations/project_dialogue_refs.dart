import '../models/map_data.dart';
import '../models/enums.dart';
import '../models/map_entity_payloads.dart';

/// Collecte les [DialogueRef.dialogueId] non vides utilisés sur une carte (NPC + panneaux).
Set<String> collectDialogueIdsReferencedOnMap(MapData map) {
  final ids = <String>{};
  for (final e in map.entities) {
    switch (e.kind) {
      case MapEntityKind.npc:
        final id = e.npc?.dialogue?.dialogueId.trim();
        if (id != null && id.isNotEmpty) ids.add(id);
        break;
      case MapEntityKind.sign:
        final id = e.sign?.dialogue?.dialogueId.trim();
        if (id != null && id.isNotEmpty) ids.add(id);
        break;
      default:
        break;
    }
  }
  return ids;
}

/// Fusionne les références de plusieurs cartes.
Set<String> collectDialogueIdsReferencedOnMaps(Iterable<MapData> maps) {
  final all = <String>{};
  for (final m in maps) {
    all.addAll(collectDialogueIdsReferencedOnMap(m));
  }
  return all;
}
