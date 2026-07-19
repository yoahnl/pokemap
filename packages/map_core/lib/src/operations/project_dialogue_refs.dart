import '../models/map_data.dart';
import '../models/enums.dart';
import '../read_models/narrative_dependency_index.dart';

/// Collecte les identifiants de dialogue référencés directement par les
/// données de [map]. Les identifiants vides sont ignorés et les doublons
/// éliminés.
///
/// Sans [dependencyIndex], conserve le scan historique borné aux dialogues
/// principaux des PNJ et des panneaux.
///
/// Avec [dependencyIndex], l'index est la source de vérité et doit avoir été
/// construit avec la version courante de [map]. Sont alors inclus les
/// dialogues principaux, de défaite et conditionnels des PNJ, les panneaux et
/// les effets de dialogue des éléments placés. Aucun fallback ni fusion avec
/// le scan historique n'est effectué.
///
/// Les références appartenant à un autre asset, même s'il cible cette carte,
/// ne sont pas incluses.
Set<String> collectDialogueIdsReferencedOnMap(
  MapData map, {
  NarrativeDependencyIndex? dependencyIndex,
}) {
  if (dependencyIndex != null) {
    return <String>{
      for (final usage in dependencyIndex.usages)
        if (usage.target.kind == NarrativeDependencyTargetKind.dialogue &&
            usage.owner.physicalMapId == map.id)
          usage.target.id,
    };
  }
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
Set<String> collectDialogueIdsReferencedOnMaps(
  Iterable<MapData> maps, {
  NarrativeDependencyIndex? dependencyIndex,
}) {
  final all = <String>{};
  for (final m in maps) {
    all.addAll(
      collectDialogueIdsReferencedOnMap(
        m,
        dependencyIndex: dependencyIndex,
      ),
    );
  }
  return all;
}
